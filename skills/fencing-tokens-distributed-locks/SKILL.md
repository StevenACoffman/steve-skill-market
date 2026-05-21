---
allowed-tools: Bash, Read, Edit
name: fencing-tokens-distributed-locks
description: |
  Use this skill when designing or reviewing any system that uses a distributed lock, lease, or mutex to protect a shared resource from concurrent access.

  Invoke when:
  - A service acquires a lock (Redis SETNX, ZooKeeper, etcd lease) and then writes to storage, calls an external API, or coordinates a job
  - A process holds a lock with a TTL and performs any operation that must not run concurrently
  - A post-mortem reveals duplicate writes, double job execution, or split-brain data corruption despite correct lock usage
  - Designing distributed job schedulers, leader election, or exclusive-access file/record modification

  Do NOT invoke when:
  - The locking mechanism is a database row lock within a single ACID transaction (the database handles this)
  - The resource being protected is append-only and duplicate writes are harmless
  - The coordination problem only involves nodes you control, and you can guarantee no GC pauses or network delays exceed the lease TTL (this is never safe to assume)

  Key signals: "we use Redis/ZooKeeper/etcd for distributed locking," "only one instance should run at a time," "we saw duplicate processing," "our lease expired and we're not sure what happened"
source_book: "Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini"
source_chapter: "Chapter 9: The Trouble with Distributed Systems"
tags: [distributed-systems, locking, leases, fencing, process-pauses, correctness]
related_skills: [distributed-fault-taxonomy, consistency-model-selection, clock-skew-ordering-hazard, end-to-end-idempotence-request-ids]
---

# Fencing Tokens for Distributed Lock Safety

## Current State

Distributed lock or mutex usage:
!`grep -rn 'sync\.Mutex\|sync\.RWMutex\|lock\|Lock\|distributed' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Optimistic concurrency / version checks:
!`grep -rn 'compare.*swap\|CAS\|version\|etag\|ETag\|revision' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Leader election or singleton job guards:
!`grep -rn 'leader\|election\|singleton\|once\|Once' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Original Text (Reading)

> Let's assume that every time the lock service grants a lock or lease, it also returns
> a fencing token, which is a number that increases every time a lock is granted (e.g.,
> incremented by the lock service). We can then require that every time a client sends a
> write request to the storage service, it must include its current fencing token.
>
> In Figure 9-6, client 1 acquires the lease with a token of 33, but then it goes into a
> long pause and the lease expires. Client 2 acquires the lease with a token of 34 (the
> number always increases) and sends its write request to the storage service, including
> the token. Later, client 1 comes back to life and sends its write to the storage service,
> including its token value, 33. However, the storage service remembers that it has
> already processed a write with a higher token number (34), so it rejects the request
> with token 33.
>
> — Kleppmann & Riccomini, Chapter 9

---

## I — Methodological Framework (Interpretation)

A distributed lock granted by a lock service (Redis, ZooKeeper, etcd) with a TTL does not actually guarantee that only one process writes at any given moment. A process can acquire a lock, pause for longer than the TTL (due to garbage collection, VM suspension, OS scheduling, or network delay), and then resume — still believing it holds the lock, when in fact the lock has expired and been granted to another process. This creates a "zombie" leaseholder that corrupts shared state despite never seeing an error.

TTL-based locks cannot be made safe by shortening the TTL, because there is no lower bound on how long a GC pause or network delay can last. The lock expiry mechanism is inherently unreliable as a mutual exclusion guarantee.

The correct fix is to move enforcement responsibility from the lock holder to the storage target:

1. The lock service issues a monotonically increasing integer (fencing token) with each grant. Each successive grant always has a higher token than any previous grant.
2. The lock holder passes this token with every write to the protected storage service.
3. The storage service tracks the highest token it has ever seen and rejects any write carrying a token lower than that value.

This means a zombie leaseholder's delayed or resumed writes arrive with a stale (lower-numbered) token and are rejected — even if the zombie does not know its lease expired. The invariant is maintained by the storage target, which is the only component that can enforce it correctly.

For lock services: ZooKeeper's `zxid`, etcd's revision number, and Hazelcast's `FencedLock` API all produce usable fencing tokens. For storage targets: S3 conditional writes, Azure conditional headers, and GCS request preconditions implement compatible semantics.

---

## A1 — Past Application (From the Book)

### Case 1: HBase Distributed Lock Corruption (Chapter 9)

- **Question:** How can a client corrupt a file in shared storage despite using a lock service that implements TTL-based leases correctly?
- **Use of Methodology:** The book traces the HBase bug: a client holds a lease, undergoes a GC pause longer than the lease TTL, the lease expires, a second client acquires the lease and writes to the file, and then the paused client resumes and also writes. Both clients had "valid" leases at the time they checked. The methodology diagnoses this as the zombie problem — no TTL-based lock can prevent it without fencing tokens.
- **Conclusion:** Fencing tokens prevent the zombie's write from succeeding at the storage layer, regardless of whether the zombie knows its lease expired.
- **Result:** With fencing tokens, the storage service rejects the stale token. Only the current leaseholder's writes proceed.

### Case 2: Distributed Lock with ZooKeeper (Chapter 9)

- **Question:** Given ZooKeeper as a lock service, how do you implement fencing that survives network delays and process pauses?
- **Use of Methodology:** The book prescribes using ZooKeeper's `zxid` or `cversion` as the fencing token. These are monotonically increasing values that ZooKeeper increments with each transaction. The protected storage service (not ZooKeeper) must track the highest `zxid` seen and reject writes with lower values.
- **Conclusion:** The fencing invariant does not require the lock service and storage service to be the same system — the token is the portable proof of lock generation, and the storage target enforces it independently.
- **Result:** The pattern generalizes: any system that issues monotonically increasing tokens (Kafka epoch numbers, Paxos ballot numbers, Raft term numbers) implements the same fencing guarantee.

---

## A2 — Trigger Scenario (Future Trigger) ★

1. A batch job runner uses Redis SETNX with a 30-second TTL to prevent duplicate job execution. A post-mortem shows the job ran twice. The Redis TTL was set correctly and both processes observed it. (Classic GC pause or network delay exceeds TTL; no fencing token was used.)

2. A microservice acquires a ZooKeeper lease before writing to an S3-compatible object store. The team wants to know whether the current implementation is safe if the service is paused by a Kubernetes preemption.

3. A leader-election system using etcd leases drives writes to a downstream database. The team is designing the write path and wants to know how to prevent a former leader from writing after losing its lease.

4. A distributed scheduler ensures only one worker processes each task at a time. Intermittent duplicate task completion is observed in production, with no errors logged by the lock service.

### Language Signals

- "we use Redis/etcd/ZooKeeper for distributed locking"
- "only one process should write at a time"
- "we saw duplicate processing despite the lock being held correctly"
- "our lease has a 10-second TTL, so we should be safe"
- "GC pause caused the service to miss its heartbeat"

### Distinguishing from Adjacent Skills

- Difference from `distributed-fault-taxonomy`: That skill classifies fault types (network delay, GC pause, Byzantine) at a conceptual level; this skill prescribes a specific mitigation (fencing tokens) for one class of fault (process pause causing stale leaseholder).
- Difference from `consistency-model-selection`: That skill is about choosing between linearizability and eventual consistency for a system's reads and writes; this skill assumes you have already decided to use a lock and focuses on making it safe against TTL expiry.

---

## E — Execution Steps

1. **Identify the lock service and the protected resource**
   - Completion criteria: You can name: (a) what service grants the lock, (b) what storage or API the lock protects, and (c) whether the protected resource supports conditional writes or a token-based rejection mechanism.

2. **Verify whether the lock service issues monotonically increasing tokens**
   - Check: ZooKeeper (`zxid`/`cversion`), etcd (revision number), Hazelcast (`FencedLock`), or custom (increment counter on each grant).
   - If using Redis SETNX: Redis does not natively issue fencing tokens. Either replace the lock service, or implement a Lua script that atomically increments a counter and returns it with the lock grant.
   - Completion criteria: Lock grants are paired with a monotonically increasing integer that the holder must pass to the protected resource.

3. **Modify the protected resource to enforce token ordering**
   - For SQL databases: add a `lock_token BIGINT` column to the protected record; use a `WHERE lock_token < :new_token` condition on all writes; update the stored token atomically with the write.
   - For object stores: use S3 conditional writes (If-None-Match / If-Match), Azure conditional headers, or GCS request preconditions.
   - For custom services: maintain a `max_seen_token` value in durable storage; reject writes where `incoming_token < max_seen_token`.
   - Completion criteria: The storage target rejects writes that carry a token lower than the highest token it has previously accepted, with an explicit error (not a silent discard).
   - Stop condition: If the protected resource cannot be modified to enforce token ordering and does not support conditional writes, the system cannot be made safe with TTL-based distributed locks alone. Consider using single-leader replication with the lock enforcement built into the leader's protocol.

4. **Test the fencing invariant under simulated GC pause**
   - Simulate: acquire lock, get token T, pause the process for longer than TTL, let another process acquire the lock and get token T+1, resume the first process, attempt a write with token T.
   - Completion criteria: The storage target rejects the write with token T with an explicit error; the write with token T+1 succeeds.

---

## B — Boundary ★

### Do Not Use This Skill When

- The "lock" is a single-node database row lock inside an ACID transaction. The database handles mutual exclusion atomically; GC pauses do not expire row locks, and there is no TTL involved.
- The protected resource is idempotent and duplicate writes are safe. Fencing tokens solve concurrent-write correctness; if the operation is idempotent, concurrency is not a correctness issue (though it may still be a performance concern).
- You are dealing with Byzantine faults (nodes that lie about their token). Fencing tokens assume honest nodes — a malicious process can forge a token. The book explicitly scopes out Byzantine fault tolerance.

### Failure Patterns from the Book

- **ce15 (Automatic Rebalancing Cascade)**: Analogous failure mode — a slow node triggers cluster rebalancing, which adds I/O load to the already-slow node, potentially causing the very failure being prevented. This illustrates that timeout-based detection (of node liveness) has the same root problem as TTL-based locking: it cannot distinguish "temporarily slow" from "dead." The fencing-token fix is the correct response to both.

### Author's Blind Spots / Era Limitations

- The book presents ZooKeeper and etcd as the natural lock services, but managing these systems in production carries significant operational cost that the book underweights. In practice, many teams use Redis because ZooKeeper/etcd are operationally complex — and then discover that Redis does not provide fencing tokens. The book's prescription (use ZooKeeper) is correct but does not engage with the operational realities that drive teams away from it.
- The book does not cover newer lock services such as Google Cloud Spanner's external lock API or distributed lock libraries built on top of PostgreSQL advisory locks, which may provide fencing token semantics without the operational overhead of ZooKeeper.

### Easily Confused Adjacent Methodology

- **STONITH (Shoot The Other Node In The Head)**: A different approach to zombie fencing — forcibly terminate the zombie process. The book notes this is less reliable because it does not protect against network delays (a delayed write from a terminated process can still arrive after the termination), and can cause cascading failures. Fencing tokens are more reliable because they enforce the invariant at the write target rather than trying to prevent the zombie from acting.

---

## Related Skills

- **depends_on**: distributed-fault-taxonomy — fencing tokens are the prescribed mitigation for the process-pause fault class; the taxonomy must be understood to know why TTL-based locks alone are insufficient.
- **contrasts_with**: consistency-model-selection — consistency model selection determines the read-visibility guarantee for a system's replicated data; fencing tokens make a distributed lock safe against TTL expiry and have no bearing on read recency.
- **composes_with**: clock-skew-ordering-hazard — fencing tokens use a monotonically increasing integer (not wall-clock time) as the ordering mechanism, which is exactly the correct alternative to clock-based ordering that clock-skew-ordering-hazard prescribes.
- **composes_with**: end-to-end-idempotence-request-ids — fencing tokens prevent concurrent zombie writes (multiple processes competing for the same lock); idempotency keys prevent duplicate retries from the same client; together they cover both concurrent-access and retry correctness.

---

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04
