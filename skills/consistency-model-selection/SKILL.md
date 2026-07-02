---
name: consistency-model-selection
description: |
  Invoke this skill when a system uses replicated storage and you must decide whether an operation requires linearizability (single-copy semantics) or whether eventual consistency is acceptable. Specific triggers: a uniqueness constraint, quota, rate limit, or distributed lock must be enforced across replicas; a counter is incremented by concurrent writers; a "check then act" pattern reads from a replica before making a decision; the team is debating whether to pay the performance cost of strong consistency.

  Do NOT invoke when: there is only one replica (single-node database, no replication); the question is about transaction isolation levels within a single database (see `transaction-isolation-level-selection`); the question is about which replication topology to use (see `replication-topology-selection`).
tags: [consistency, linearizability, eventual-consistency, distributed-systems, CAP-theorem, replication]
allowed-tools: Bash, Read, Edit
---

# Consistency Model Selection (Linearizability Vs. Eventual Consistency)

## Current State

Cache reads (potential stale-read sources):
!`grep -rn 'cache\|Cache\|memcache\|redis\|Redis' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Strong-consistency read paths (Datastore, SQL):
!`grep -rn 'datastore\|Datastore\|pgx\|sqlc\|sql\.DB' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Replica or read-replica references:
!`grep -rn 'replica\|readOnly\|read_only\|secondary' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Original Text (Reading)

> Linearizability is a recency guarantee. The basic idea is to make a system appear as if there is only one copy of the data, and all operations on it are atomic. With this guarantee, even though there may be multiple replicas in reality, the application does not need to worry about them. In a linearizable system, as soon as one client successfully completes a write, all clients reading from the database must be able to see the value just written.
>
> [On when linearizability is required:] Locking and leader election; constraints and uniqueness guarantees; cross-channel timing dependencies... If you want to ensure that the user name is unique, you need linearizable storage. If multiple nodes concurrently try to create the same user name, at most one of them should succeed.
>
> — Kleppmann & Riccomini, Chapter 10: Consistency and Consensus

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Linearizability means the replicated system behaves as if it has exactly one copy of the data. Once any client reads a new value, all subsequent reads — on any replica, by any client — must return that same new value or newer. This is the recency guarantee. It is strong and useful but has a real cost: achieving it under a network partition requires making the system unavailable (CAP theorem), and linearizable operations typically require coordination through a single leader or consensus protocol.

Eventual consistency means replicas will converge to the same value *eventually* — after writes stop propagating. It says nothing about when, and nothing about what reads return during normal operation with ongoing writes. It is not "slightly delayed strong consistency." Concurrent writes to different replicas may return different values for an indefinite period.

The framework's key insight is that most operations in most applications do not require linearizability. Reading a user's feed, fetching product descriptions, rendering a dashboard — all are tolerable with stale data. But a specific, narrow class of operations always requires linearizability:

- **Uniqueness constraints**: ensuring a username, email, or booking slot is not taken by two concurrent requests.
- **Distributed locks and leader election**: only one process may hold authority at a time.
- **Quotas and rate limits**: enforcing that a counter does not exceed a bound under concurrent increments.
- **Cross-channel coordination**: a write on one channel (e.g., upload a file) that must be visible before a notification on a different channel (e.g., send email with download link) proceeds.

The mistake engineers make is one of two: demanding linearizability everywhere (unnecessary latency and availability cost) or nowhere (silent correctness violations for the specific operations that require it). The framework's value is the precise enumeration.

The CAP theorem footnote: CAP's "C" means linearizability specifically. Partition tolerance is not a design choice — partitions happen. The choice is: during a partition, do you sacrifice linearizability or availability? This is a narrow impossibility result, not a general design framework; most system-level decisions require more nuanced reasoning than "pick two."

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Distributed Rate Limiter — Eventual Consistency Breaks Quota Enforcement

- **Question:** A distributed rate limiter stores request counts in a replicated counter with eventual consistency. Concurrent requests from the same user check "quota = 99 of 100 used" on different replicas, both approve, both increment — the user sends 101 requests against a 100-request quota. Is this acceptable?
- **Use of Methodology:** The framework classifies quota enforcement as a correctness requirement that needs linearizability. Both replicas returned stale count because eventual consistency provides no recency guarantee. The concurrent reads happened on different replica states. With eventual consistency, all read-then-decide patterns that enforce a bound are unsafe.
- **Conclusion:** Rate limiter enforcement decisions require a linearizable counter. Eventual consistency is acceptable for *observing* quota usage (dashboards, billing estimates) but not for *enforcing* it.
- **Result:** The correct implementation uses a single-leader counter, a consensus-based compare-and-swap (CAS) operation, or a strongly consistent atomic counter service. The per-instance shard can be eventually consistent for approximate metrics, but the enforcement gate requires linearizability.

### Case 2: Cassandra LWW + Quorum — Quorum Reads Do Not Guarantee Linearizability

- **Question:** A team configures Cassandra with QUORUM reads and QUORUM writes (w + r > n), believing this provides strong consistency. Post-mortem shows inconsistent reads after concurrent writes. Why?
- **Use of Methodology:** The framework applies the CAP insight: quorum overlap (w + r > n) guarantees that any read overlaps with any write quorum by at least one node. But if that overlapping node has not yet applied the write (due to variable network delay), it may return the stale value. LWW conflict resolution using wall-clock timestamps makes this worse: clock skew means the "most recent" clock timestamp is not necessarily the causally most recent write.
- **Conclusion:** Cassandra with LWW is explicitly nonlinearizable, even with QUORUM settings. Applications requiring linearizability cannot safely use LWW-based leaderless replication.
- **Result:** The team must switch to a single-leader system, use Cassandra's lightweight transactions (LWT, which add consensus overhead), or redesign to avoid the linearizability requirement. The configuration (QUORUM) is a necessary but not sufficient condition for linearizability in a system with network-delay variability.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A booking system allows users to reserve the last available appointment slot. Two users check simultaneously, both see "1 slot available," both proceed to book. The question is whether the slot check reads from a replica.
2. A distributed rate limiter must enforce a hard limit of 1,000 API calls per user per hour. The counter is stored in a replicated cache.
3. A payment system assigns invoice numbers and requires them to be globally unique. Invoice number generation reads the current maximum and increments by 1.
4. A notification service sends an email "your file is ready" immediately after a write completes. The file metadata is in a replicated database. The email link hits a different replica that has not yet received the write.
5. An architect says "we're fine with eventual consistency everywhere; the slight staleness is acceptable for our use case" and you need to determine whether any specific operations violate that assumption.

### Language Signals

- "Two requests got approved simultaneously but only one should have"
- "We're checking a value on the replica before making a decision"
- "Does quorum read give us strong consistency?"
- "The rate limiter is letting through more requests than the limit"
- "We need to enforce a unique constraint across the cluster"
- "Can we tolerate slightly stale reads here?"
- "Is eventual consistency safe for this feature?"

### Distinguishing from Adjacent Skills

- Difference from `transaction-isolation-level-selection`: Transaction isolation is about what concurrent transactions within a single database see from each other (read committed vs. snapshot vs. serializable). Consistency model selection is about what reads see relative to writes on other replicas in a distributed system. Both are about visibility, but at different layers — isolation is intra-database, consistency model is inter-replica.
- Difference from `replication-topology-selection`: Topology selection (single-leader vs. multi-leader vs. leaderless) determines which topology you use. Consistency model selection determines what guarantee you need from that topology. Topology selection is a prerequisite; this skill determines whether the selected topology is sufficient for each operation.
- Difference from `distributed-fault-taxonomy`: Fault taxonomy helps you design for partial failures (network delay, process pause). Consistency model selection is about the read-visibility guarantee under normal operation and during partitions. They interact — process pauses break distributed locks that rely on linearizability — but the questions are different.

______________________________________________________________________

## E — Execution Steps

1. **Enumerate the operations that involve a "check then act" pattern**

   - List all operations where the application reads a value from a replicated store and then makes a decision based on that value (approve/reject, increment/decrement, grant/deny).
   - Completion criteria: A list of read-then-decide operations exists. Each is tagged as "enforce a constraint" or "display information."

2. **Classify each operation: does a stale read cause a permanent correctness violation?**

   - For each operation: if the read returns a stale value and the action proceeds based on it, can the resulting state be corrected automatically (timeliness violation)? Or does it permanently violate an invariant (integrity violation)?
   - Completion criteria: Operations are classified as "linearizability required" (integrity violation possible from stale read) or "eventual consistency acceptable" (at most a timeliness violation, self-healing).
   - Rule of thumb: uniqueness constraints, quota enforcement, distributed locks, and leader election always require linearizability. Display operations (feeds, dashboards, non-critical reads) are almost always fine with eventual consistency.

3. **For operations requiring linearizability: verify the storage layer provides it**

   - Check whether the storage system in use actually provides linearizability for the operations in question. Do not assume "quorum = linearizable" in leaderless systems. Do not assume "serializable" means linearizable (these are orthogonal properties).
   - Completion criteria: The storage system documentation or test evidence explicitly confirms linearizability for the operation type (e.g., CAS, distributed lock, leader election). Leaderless systems with LWW are eliminated for these operations.

4. **For operations where linearizability is required but the current system cannot provide it: design alternatives**

   - Options: (a) route linearizability-required reads to the leader/primary; (b) use a consensus-based CAS operation; (c) use a separate linearizable service (etcd, ZooKeeper) for the constraint-enforcing operations while keeping eventual consistency for the rest.
   - Completion criteria: The linearizability-required operations are routed through a confirmed-linearizable path. The non-linearizability-required operations remain on the eventual consistency path.

5. **Document the consistency model per operation, not per system**

   - The system as a whole does not have one consistency model. Different operations in the same system can use different consistency levels. Document which operations require linearizability and why.
   - Completion criteria: An architectural decision record lists the operations requiring linearizability, the mechanism providing it, and the operations for which eventual consistency is acceptable and why.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- There is a single, non-replicated database. Consistency model selection applies to replicated systems; a single-node database already provides single-copy semantics trivially.
- The question is about concurrency control within a single database transaction. Use `transaction-isolation-level-selection` to determine whether serializable, snapshot, or read-committed isolation is needed.
- The only consistency concern is latency on a read-heavy workload. Read replicas introduce replication lag (see `replication-lag-as-correctness`), which is related but addressed by a different skill.

### Failure Patterns from the Book

- **ce22 — Linearizability vs. Serializability Confusion**: An architect chooses a "serializable" database expecting linearizable reads. Serializable (SSI) ensures transactions behave as if serial but may read from snapshots that predate recent writes. Lock implementations and uniqueness checks built on top silently receive stale reads. These are orthogonal properties: neither implies the other.
- **ce23 — Quorum Does Not Guarantee Linearizability**: Configuring Cassandra with QUORUM reads and writes satisfies w + r > n but does not provide linearizability when the overlapping replica has not yet applied the write due to network delay variability. The quorum condition is necessary but not sufficient.
- **ce24 — CAP Theorem Misapplication**: Teams "choose CA" (no partition tolerance) believing they can architect away network partitions with reliable hardware. Partitions happen in every networked system. The team has no documented behavior for partition scenarios and encounters undefined behavior under real partitions.

### Author's Blind Spots / Era Limitations

- The book treats linearizability as essentially binary in the user-facing decision: either you need it or you don't. The emerging space of causal consistency (stronger than eventual, weaker than linearizable) is mentioned but not given a decision procedure. CRDTs and causal consistency may be the right middle ground for collaborative applications, but the framework does not guide when to apply them.
- The CAP theorem discussion correctly identifies its limitations but does not provide a replacement framework (PACELC is mentioned but not developed into a decision procedure). Engineers left with "CAP is misleading" but without an alternative may fall back to CAP anyway.
- The book's examples are datacenter-centric with high-bandwidth, low-latency (within a datacenter) networks. Global distribution changes the consistency/availability trade-off dramatically; the framework's guidance becomes less actionable at multi-region scale.

### Easily Confused Adjacent Methodology

- **CAP theorem**: CAP is commonly cited as a design framework ("we chose availability over consistency"). The book argues CAP is a narrow impossibility result about linearizability under partitions, not a general trade-off framework. Using CAP as a design guide causes engineers to make binary choices (linearizable or available) when real systems exist on a spectrum.
- **ACID consistency**: ACID "consistency" refers to application-level invariants (e.g., "account balances must sum to zero"). Linearizability is a distributed systems property about read recency across replicas. These are unrelated. Engineers who conflate them misapply both.

______________________________________________________________________

## Related Skills

- **depends_on**: replication-topology-selection — consistency model selection determines the required guarantee; the topology must already be chosen (or be under selection) to evaluate whether it can deliver that guarantee.
- **contrasts_with**: transaction-isolation-level-selection — isolation levels (serializability) govern concurrent transaction ordering within one database; linearizability governs whether reads on any replica see the most recent write; neither implies the other.
- **composes_with**: distributed-fault-taxonomy — understanding which fault classes are possible (process pause, network delay) informs which consistency guarantees are achievable and why leaderless systems cannot provide linearizability.
- **composes_with**: timeliness-vs-integrity-distinction — TVI provides the decision rule for when linearizability is actually required (integrity-critical operations) vs. when eventual consistency is acceptable (display reads).

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini — Chapter 10: Consistency and Consensus
