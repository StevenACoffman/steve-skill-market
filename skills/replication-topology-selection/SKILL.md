---
name: replication-topology-selection
description: |
  Invoke this skill when designing or evaluating a database replication strategy — specifically when choosing between single-leader, multi-leader, and leaderless topologies, or when an existing topology is producing availability, consistency, or conflict problems.

  Specific trigger situations:
  - A system needs writes to be accepted in multiple geographic regions simultaneously with low latency.
  - A post-mortem attributes data loss or corruption to failover behavior (split-brain, stale follower promoted, LWW silently discarding writes).
  - A team argues that Cassandra quorum reads provide "strong consistency" and is designing correctness-critical logic on that assumption.
  - A system experiences write conflicts and needs a conflict resolution strategy.
  - A new architecture is being designed and "how many leaders" has not been explicitly decided.
tags: [replication, single-leader, multi-leader, leaderless, conflict-resolution, consistency, availability]
allowed-tools: Bash, Read, Edit
---

# Replication Topology Selection

## Current State

Database connection configuration:
!`grep -rn 'dsn\|DSN\|DATABASE_URL\|postgres\|Postgres\|datastore\|Datastore' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Multi-region or replica endpoint references:
!`grep -rn 'region\|replica\|primary\|secondary\|failover\|ReadReplica' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Cloud Datastore usage (managed replication):
!`grep -rln 'cloud\.google\.com/go/datastore' --include='*.go' . 2>/dev/null | head -5`

## R — Original Text (Reading)

> We will discuss three families of algorithms for replicating changes between nodes: single-leader, multi-leader, and leaderless replication. Almost all distributed databases use one of these three approaches. Each has pros and cons, which we will examine in detail.
>
> There are many trade-offs to consider with replication—for example, whether to use synchronous or asynchronous replication, and how to handle failed replicas. Those are often configuration options in databases, and although the details vary by database, the general principles are similar across many implementations.
>
> The idea [of leaderless replication] was mostly forgotten during the era of dominance of relational databases. It once again became a fashionable architecture for databases after Amazon used it for its in-house Dynamo system in 2007. Riak, Cassandra, and ScyllaDB are open source datastores with leaderless replication models inspired by Dynamo.
>
> — Kleppmann & Riccomini, Chapter 6: Replication

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The framework selects a replication topology by mapping each topology's consistency/availability/conflict trade-off to the application's requirements. Three topologies exist on a continuum from simplest to most complex:

**Single-leader**: All writes go to one designated leader, which replicates to followers. Followers serve reads. Provides the strongest consistency guarantees (no write conflicts possible). Limitation: leader is a write bottleneck; cross-region write latency is high if the leader is remote. Default choice unless a specific bottleneck makes it unacceptable.

**Multi-leader**: Multiple nodes accept writes simultaneously. Enables low-latency writes in multiple regions. Mandatory cost: write conflicts are inevitable when the same record is modified concurrently on different leaders. Conflict resolution is required (last-write-wins, application-level merge, or CRDTs). The book labels multi-leader for shared data "dangerous territory" — it should be chosen only after demonstrating that the single-leader write latency is an actual, measured problem.

**Leaderless (Dynamo-style)**: Any replica accepts reads and writes. Quorum reads+writes (w + r > n) increase the probability of reading recent data, but do NOT guarantee linearizability due to variable network delays and LWW with clock skew. Leaderless is optimized for availability during network partitions at the cost of conflict complexity.

The key non-obvious insight: leaderless replication with quorum does not provide strong consistency. Engineers who believe w + r > n guarantees linearizability are wrong — clock skew in LWW and variable network delays permit stale reads even when quorum conditions are met mathematically.

Decision sequence: start with single-leader; switch to multi-leader only if cross-region write latency is a demonstrated, measured problem; choose leaderless only if availability during partition (shopping cart model) is the explicit requirement and conflict resolution complexity is accepted.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Amazon Dynamo — Leaderless for Shopping Cart Availability

- **Question:** Amazon needed shopping cart writes to succeed during network partitions, even if some replicas were unreachable. What topology enables this?
- **Use of Methodology:** The framework identifies this as a case where availability during partition outweighs strong consistency. Leaderless replication (Dynamo-style) allows writes to be accepted by any available replica. The cost is conflict resolution: when partitions heal, writes from disconnected replicas must be reconciled. For a shopping cart (where adding items can be merged), this is an acceptable trade-off.
- **Conclusion:** Leaderless replication with application-level conflict merge (vector clocks or CRDTs) is appropriate when availability during partition is the primary requirement and the data is naturally mergeable.
- **Result:** Amazon Dynamo achieved its availability goal. The conflict complexity was accepted as a known, engineered cost. The case also shows that DynamoDB (the public product) uses single-leader consensus — the availability-vs-consistency choice was revisited when the operational complexity of conflict resolution was weighed against latency requirements.

### Case 2: GitHub MySQL Follower Promotion — Stale Follower with Stale ID Counter

- **Question:** After a leader failure, GitHub promoted a MySQL follower that had not replicated all of the leader's writes. What went wrong?
- **Use of Methodology:** The framework predicts this failure: asynchronous replication creates a durability window. A follower promoted while behind the leader generates autoincrement IDs that were already used by the now-discarded leader writes. Those IDs were referenced in Redis, causing cross-system data corruption.
- **Conclusion:** The topology choice (single-leader with fully asynchronous replication and no fencing) created the durability window. Semi-synchronous replication or requiring follower catch-up before promotion would have prevented the primary key collision.
- **Result:** Cross-system data corruption at GitHub (2012). The methodology prescribes: when external systems reference primary keys, asynchronous replication failover without fencing is unsafe.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A global e-commerce platform wants both US and EU data centers to accept writes without cross-ocean latency. The team is considering multi-leader replication.
2. A team is using Cassandra with QUORUM reads and writes and believes this provides "strong consistency" for an inventory count enforcement decision.
3. A post-mortem shows that after a leader failure, two nodes both believed they were the primary and accepted writes simultaneously (split-brain), resulting in conflicting order records.
4. A leaderless database deployment uses LWW (last-write-wins) with wall-clock timestamps for conflict resolution. Users report that recent writes occasionally disappear.
5. An engineering team needs to decide whether to use CockroachDB (consensus-based single-leader per shard) or Cassandra (leaderless) for a financial transaction system.

### Language Signals

- "We need writes to work in both regions"
- "Cassandra quorum gives us strong consistency"
- "Two nodes both think they are the primary"
- "LWW means the latest write wins, right?"
- "We want high availability — can we use leaderless?"

### Distinguishing from Adjacent Skills

- Difference from `replication-lag-as-correctness`: topology selection determines the fundamental consistency model (which conflicts are possible, how they are resolved); lag-as-correctness addresses the specific user-visible problem of stale reads from followers in an already-chosen single-leader topology.
- Difference from `consistency-model-selection`: topology selection is the implementation mechanism; consistency model selection is the requirements analysis that precedes it — you determine whether you need linearizability, then select a topology that can provide it (single-leader or consensus, not leaderless).

______________________________________________________________________

## E — Execution Steps

1. **Define the write availability requirement**

   - Must writes succeed during a network partition between regions/nodes? If yes, multi-leader or leaderless are in scope. If no (writes can wait for leader recovery), single-leader is sufficient.
   - Completion criteria: A written statement: "We can/cannot tolerate write unavailability during partition for [duration] for [data types]."

2. **Identify the consistency requirement for reads**

   - Must reads be linearizable (always see the most recent write)? If yes, only single-leader with synchronous replication or consensus-based replication qualifies. If eventual consistency is acceptable for reads, leaderless becomes viable.
   - Completion criteria: A written statement: "Reads of [data type] must be [linearizable / monotonically consistent / eventually consistent]."
   - Stop condition: If linearizability is required AND multi-region write availability is required, this is the CAP impossibility — no topology solves both. Document the explicit trade-off and choose which constraint is primary.

3. **Evaluate conflict resolution requirements for multi-leader or leaderless**

   - If multi-leader or leaderless is in scope: enumerate what happens when two concurrent writes modify the same record. Is LWW acceptable (data loss is tolerable)? Is application-level merge possible? Are the data types CRDT-friendly (sets, counters)?
   - Completion criteria: Every writable data type has an explicit conflict resolution policy. LWW chosen only where silent data loss is documented as acceptable.

4. **Select topology and configure failover safety**

   - Single-leader: configure semi-synchronous replication or require follower catch-up before promotion; implement fencing tokens to prevent split-brain.
   - Multi-leader: implement conflict detection and resolution at the application layer before deployment.
   - Leaderless: document that quorum does not provide linearizability; identify which operations cannot use leaderless (uniqueness checks, financial totals).
   - Completion criteria: Configuration is documented with explicit rationale. Fencing mechanism (STONITH, epoch tokens, or Raft leadership term) is configured for single-leader.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The data volume requires distributing data across nodes — that is sharding, not replication. Replication copies the same data to multiple nodes; sharding splits different data across nodes. Use `sharding-strategy-selection` for that decision.
- The question is whether a specific operation (distributed lock, rate limiter) requires linearizability — that is a consistency model selection question, not a topology question.
- The system is a single-node database with no replication; failover behavior is not in scope.

### Failure Patterns from the Book

- **ce09 — Async Replication Data Loss on Failover**: Leader acknowledges write to client; crashes before replication. Follower is promoted. Writes are discarded. Client believes data was saved. This is inherent to async single-leader; semi-sync is required if durability guarantees must survive failover.
- **ce10 — Split Brain**: Timeout-based failure detection promotes a new leader while the old leader is still reachable by some clients. Both accept writes. No reconciliation algorithm exists. The fix is explicit fencing (STONITH, epoch tokens) so the old leader is prevented from accepting writes.
- **ce11 — LWW Silent Data Loss**: Two concurrent writes in Cassandra. Both clients receive success. LWW discards one write silently based on wall-clock comparison. No error is raised. The client whose write was discarded has no way to know.
- **ce20 — Clock Skew with LWW**: A node with a clock 10ms ahead generates timestamps that make causally-later writes appear older. LWW discards the causally-later write. Quorum settings do not help.

### Author's Blind Spots / Era Limitations

- The single-region assumption: most of the replication discussion assumes low-latency, single-datacenter networks. Global distribution with geo-replication involves latency constraints that make the single-leader default less obviously correct — the cross-ocean write latency may be 100ms, which is unacceptable for interactive applications. The book acknowledges this but does not provide deep guidance on CRDT-based sync engines or geo-distributed consensus.
- Operational complexity of multi-leader is underweighted: the book describes the theoretical trade-offs of multi-leader well but underspecifies how difficult conflict resolution is to implement correctly in practice, especially for complex domain objects.

### Easily Confused Adjacent Methodology

- **Quorum = strong consistency**: Engineers frequently believe that Dynamo-style quorum (w + r > n) provides linearizability. It does not. Cassandra LWW with clock skew can produce non-linearizable results even when quorum conditions are mathematically satisfied. The correct tool for linearizability is single-leader replication or a consensus protocol (Raft, Paxos), not tuned quorum parameters.

______________________________________________________________________

## Related Skills

- **contrasts_with**: replication-lag-as-correctness — topology selection decides how many leaders exist; lag-as-correctness addresses read-routing within an already-chosen single-leader topology.
- **contrasts_with**: sharding-strategy-selection — replication copies the same data to multiple nodes for fault tolerance; sharding splits different data across nodes for write scalability; both are often combined but address orthogonal problems.
- **composes_with**: consistency-model-selection — topology is the implementation mechanism; consistency model selection is the requirements analysis that determines whether the chosen topology is sufficient.
- **composes_with**: fencing-tokens-distributed-locks — single-leader topologies require fencing tokens (epoch tokens, STONITH) to prevent a demoted leader from continuing to accept writes after failover.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini — Chapter 6: Replication
