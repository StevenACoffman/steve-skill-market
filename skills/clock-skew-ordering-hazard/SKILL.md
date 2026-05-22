---
allowed-tools: Bash, Read, Edit
name: clock-skew-ordering-hazard
description: |
  Use this skill when reviewing any distributed system that uses wall-clock timestamps (System.currentTimeMillis(), time.time(), CLOCK_REALTIME) to order events, resolve conflicts, or enforce ordering guarantees across multiple nodes.

  Invoke when:
  - A system uses timestamps from application nodes as the tiebreaker in conflict resolution (LWW — last write wins)
  - An audit log, event stream, or financial ledger sorts events by wall-clock timestamp from multiple machines
  - Engineers claim "our NTP is good enough" to justify using timestamps for ordering
  - A Cassandra, ScyllaDB, or similar leaderless database uses its default LWW conflict resolution
  - Events timestamped on different nodes are being compared, sorted, or deduplicated by timestamp

  Do NOT invoke when:
  - Timestamps are used only for human display (showing a user "updated at 3:02pm") and not for ordering or conflict resolution
  - A single authoritative node assigns all timestamps (single-leader clock assignment eliminates the skew problem)
  - The system uses Spanner TrueTime with commit wait, which explicitly bounds and waits out clock uncertainty
  - You need to measure elapsed time on a single machine using CLOCK_MONOTONIC (monotonic clocks are safe for duration measurement)

  Key signals: "we sort events by timestamp," "LWW is our conflict strategy," "our NTP sync is under 5ms," "we use wall-clock time for causality"
source_book: Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini
source_chapter: 'Chapter 9: The Trouble with Distributed Systems'
tags: [distributed-systems, clocks, ntp, ordering, causality, lww, consistency]
related_skills: [distributed-fault-taxonomy, consistency-model-selection, fencing-tokens-distributed-locks]
---

# Do Not Use Wall-Clock Timestamps for Distributed Event Ordering

## Current State

Wall-clock time usage (time.Now):
!`grep -rn 'time\.Now()' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Timestamp comparisons used for ordering or conflict detection:
!`grep -rn '\.Before(\|\.After(\|\.Unix()\|CreatedAt\|UpdatedAt\|LastModified' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Logical clocks or vector clocks:
!`grep -rn 'version\|Version\|etag\|ETag\|revision\|Revision' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Original Text (Reading)

> The write x = 1 has a timestamp of 42.004 seconds, but the write x = 2 has a
> timestamp of 42.003 seconds. In other words, the write by client B is causally later
> than the write by client A, but B's write has an earlier timestamp.
>
> Database writes can mysteriously disappear. A node with a lagging clock is
> unable to overwrite values previously written by a node with a faster clock
> until the clock skew between the nodes has elapsed. This scenario can cause
> arbitrary amounts of data to be silently dropped without any error being
> reported to the application.
>
> So-called logical clocks, which are based on incrementing counters rather than
> an oscillating quartz crystal, are a safer alternative for ordering events. Logical
> clocks do not measure the time of day or the number of seconds elapsed, only
> the relative ordering of events (whether one event happened before or after another).
>
> — Kleppmann & Riccomini, Chapter 9

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Wall-clock timestamps returned by system APIs (such as `gettimeofday()`, `System.currentTimeMillis()`, or `time.time()`) appear to provide microsecond precision but have accuracy bounded by NTP synchronization quality. NTP synchronization typically achieves accuracy of a few milliseconds on local networks and tens of milliseconds over the internet. NTP can also apply backward corrections — causing the clock to jump backward in time — which breaks monotonicity assumptions entirely.

The consequence in distributed systems: two events on different nodes where B causally follows A may produce timestamps where B's timestamp is *earlier* than A's. If a system uses these timestamps for conflict resolution (LWW) or sorting (audit logs, event streams), the causally later event may be silently discarded or incorrectly ordered. There is no error signal — the data loss is silent.

The failure has three components:

1. Clock drift: each node's quartz oscillator drifts independently; NTP corrects periodically, not continuously.
2. NTP accuracy ceiling: even well-synchronized NTP cannot guarantee sub-millisecond accuracy across machines.
3. NTP backward jumps: a correction that moves a clock backward breaks any assumption that timestamps are monotonically increasing.

The correct alternatives, in order of increasing strength:

- **Lamport timestamps** (logical clocks): a per-node counter, incremented on every event and on every message receive. Captures causal ordering (if A happened-before B, then L(A) < L(B)) without using wall-clock time. Does not capture wall-clock time at all.
- **Vector clocks / version vectors**: extend Lamport to capture concurrent vs. causal relationships — used when you need to detect and merge concurrent writes rather than simply ordering them.
- **Hybrid Logical Clocks (HLC)**: combines a logical counter with the physical clock to provide causal ordering that is also loosely correlated with real time. Used in CockroachDB.
- **Google Spanner TrueTime**: GPS + atomic clocks provide a confidence interval [earliest, latest]. Spanner waits out the interval (commit wait) before reporting a commit, ensuring no two transactions can have overlapping uncertainty windows. This is the only correct way to use wall-clock time for global ordering — and it requires specialized hardware.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Multi-Leader Replication LWW Data Loss (Chapter 9)

- **Question:** A multi-leader database uses wall-clock timestamps to resolve conflicts between concurrent writes with last-write-wins. A causally later write is silently dropped. How?
- **Use of Methodology:** The book shows Figure 9-3: client A writes x=1 on node 1 (timestamp 42.004s), the write replicates to node 3; client B increments x on node 3 (timestamp 42.003s). Node 3's clock is 1ms behind node 1's. When both writes arrive at node 2, LWW keeps the write with timestamp 42.004s (x=1) and discards x=2. The causally later increment is permanently lost, with no error.
- **Conclusion:** Even 1ms of clock skew — well within NTP accuracy bounds — causes LWW to discard causally later writes. This is not an edge case; it is the expected behavior of any LWW system using wall-clock timestamps under normal operating conditions.
- **Result:** The methodology prescribes: logical clocks (or version vectors) for causal ordering; wall-clock timestamps may be stored for display but must not be used as the LWW comparator.

### Case 2: Cassandra LWW with Clock Skew (Chapter 10 / Chapter 9)

- **Question:** A Cassandra cluster uses its default LWW conflict resolution with wall-clock timestamps from each node's system clock. Is quorum (w+r>n) sufficient to prevent this problem?
- **Use of Methodology:** The book addresses this directly: LWW conflict resolution based on time-of-day clocks (Cassandra's default) is "almost certainly nonlinearizable" because clock timestamps cannot be guaranteed to be consistent with actual event ordering due to clock skew. Even with quorum reads and writes, clock skew can cause a quorum read to return a stale value. The quorum condition enforces overlap but not recency when LWW is the comparator.
- **Conclusion:** Quorum does not save you from clock-skew-driven data loss in LWW systems. The conflict resolution mechanism — not the quorum parameters — is the problem.
- **Result:** Applications requiring causal consistency must either use a database that provides causal consistency natively (vector clocks, CRDTs) or use single-leader replication where ordering is enforced by the leader's write log.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A distributed audit log for a financial or medical system timestamps each event with `System.currentTimeMillis()` on the processing node and sorts events by timestamp for display to auditors or regulators. The system is distributed across multiple application servers.

2. A Cassandra-backed system stores user session data and uses the default LWW conflict resolution. Intermittent reports show that user settings "roll back" to previous values without explanation. No errors are logged.

3. A team is designing conflict resolution for a multi-leader database and proposes: "we just use the write with the highest timestamp." The team's NTP sync is described as "good" (typically under 10ms).

4. An event-sourcing system receives events from multiple producers (different microservices) and sorts the global event stream by producer-assigned timestamp before applying state changes.

### Language Signals

- "we use last-write-wins with timestamps"
- "our NTP is accurate enough for this"
- "events are sorted by timestamp to determine order"
- "we're seeing unexplained data loss with no errors"
- "Cassandra's default conflict resolution"
- "we need to know which write came last"

### Distinguishing from Adjacent Skills

- Difference from `distributed-fault-taxonomy`: That skill catalogs the classes of distributed faults (including clock skew as one entry); this skill digs into clock skew specifically and prescribes the correct alternative (logical clocks) for ordering problems.
- Difference from `fencing-tokens-distributed-locks`: Fencing tokens use a monotonic counter issued by a single lock service (not wall clocks) to prevent concurrent access — they are the correct solution to lock expiry, not to general event ordering across systems.
- Difference from `replication-topology-selection`: That skill guides topology choice; this skill is invoked when you are implementing conflict resolution *within* a chosen topology and must not use wall clocks for ordering.

______________________________________________________________________

## E — Execution Steps

1. **Identify every place in the system where events from multiple nodes are compared, sorted, or merged by timestamp**

   - Completion criteria: You have a list of: (a) conflict resolution points (LWW, merge logic), (b) sort-key fields used for event ordering, (c) audit/log systems that sort by event timestamp.

2. **Classify each timestamp use as "display only" or "ordering / conflict resolution"**

   - Display only (showing "modified at 3pm" to a user): wall-clock timestamp is acceptable.
   - Ordering / conflict resolution: wall-clock timestamp is not safe if any two compared events can originate from different nodes.
   - Completion criteria: Every timestamp use is labeled; all ordering/conflict-resolution uses are flagged for replacement.

3. **Select the appropriate logical clock for each flagged use**

   - Causal ordering only (no wall-clock correlation needed): use Lamport timestamps.
   - Concurrent write detection and merge: use vector clocks / version vectors.
   - Causal ordering + human-readable correlation with real time: use Hybrid Logical Clocks (HLC).
   - Global ordering with commit wait (specialized hardware available): Spanner TrueTime.
   - Stop condition: If the underlying database (Cassandra LWW) does not expose an API to supply your own conflict comparator, switching to logical clocks requires either changing the database or moving conflict resolution to the application layer (read-repair on all reads).
   - Completion criteria: Each flagged use has a named logical clock mechanism and a clear owner (database layer vs. application layer).

4. **Preserve wall-clock timestamps as metadata, not sort keys**

   - Add a `recorded_at` wall-clock timestamp field for human display and debugging.
   - Add a separate `logical_timestamp` or `version_vector` field that is used for ordering and conflict resolution.
   - Completion criteria: No query, index, or conflict resolution logic uses `recorded_at` as an ordering comparator.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- Timestamps are assigned by a **single authoritative sequencer** (the leader in single-leader replication, a global sequence service). When only one node assigns timestamps, there is no clock skew between competing timestampers. Single-leader replication resolves all conflicts through the leader's write ordering.
- You are measuring **elapsed time on a single machine** for performance metrics. Use `CLOCK_MONOTONIC` (not `CLOCK_REALTIME`); monotonic clocks do not jump backward and are safe for duration measurement on one node.
- The system uses **Spanner TrueTime with commit wait** implemented correctly. This is the one case where wall-clock time can be used for global ordering — but it requires GPS receivers, atomic clocks, and the TrueTime API, not standard NTP.

### Failure Patterns from the Book

- **ce20 (Clock Skew with LWW)**: Node A has a clock 10ms ahead of node B. Client writes key=1 to node A (timestamp T+10). A different client writes key=2 to node B (timestamp T). LWW retains key=1. The second write is silently discarded. No error. Data loss is permanent.
- **ce21 (NTP False Precision)**: `gettimeofday()` returns microsecond-resolution values but accuracy is bounded by NTP sync quality (typically 10–100ms). Engineers treat the microsecond resolution as meaningful precision. Backward NTP corrections break monotonicity. Elapsed time measurements and event orderings derived from these values are silently wrong.

### Author's Blind Spots / Era Limitations

- The book's practical alternatives (Lamport clocks, vector clocks) are well-established research from the 1970s–1990s. The book does not cover newer practical implementations such as Hybrid Logical Clocks (HLC) in CockroachDB or the Hlc library used in many distributed systems today. Engineers may need to look beyond the book for production-ready HLC implementations.
- The book presents Spanner TrueTime as the gold standard for physical-time ordering but gives little guidance on what to do if you cannot access GPS-synchronized atomic clocks (i.e., most teams). The practical takeaway — "use logical clocks instead" — is the correct advice but is stated more gently than warranted given how often engineers violate it.

### Easily Confused Adjacent Methodology

- **Monotonic clocks for single-node elapsed time**: `CLOCK_MONOTONIC` on Linux, `time.monotonic()` in Python, and `System.nanoTime()` in Java are safe for measuring duration on a single machine. They never jump backward. They are *not* safe for comparing timestamps across machines, because each machine's monotonic clock is an independent counter starting from an arbitrary epoch.

______________________________________________________________________

## Related Skills

- **depends_on**: distributed-fault-taxonomy — clock skew is one of the four fault classes in the distributed fault taxonomy; this skill provides the specific mitigation (logical clocks) for that class.
- **contrasts_with**: consistency-model-selection — logical clocks solve the ordering problem for conflict resolution within a topology; linearizability solves the read-recency problem across replicas; they are different solutions to different problems, though both are motivated by distributed correctness.
- **composes_with**: fencing-tokens-distributed-locks — fencing tokens implement the correct alternative to clock-based lock ordering (monotonically increasing counter vs. wall-clock timestamp), making the two skills complementary mitigations for clock-related distributed hazards.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04
