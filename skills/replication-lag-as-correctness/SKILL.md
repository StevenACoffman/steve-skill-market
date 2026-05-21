---
allowed-tools: Bash, Read, Edit
name: replication-lag-as-correctness
description: |
  Invoke this skill when replication lag is producing incorrect or confusing behavior for users, not merely slow or stale behavior. The specific trigger is when a system uses read replicas and users experience one of three named violations: they submit a change and immediately see the old value (read-your-writes violation); they see data move backward in time on refresh (monotonic reads violation); or they observe causally-inconsistent sequences like a reply appearing before its question (consistent prefix violation).

  Specific trigger situations:
  - A user submits a form update (address, profile, setting) and immediately loads a page served from a replica that shows the old value.
  - A user refreshes a feed and sees fewer items than they saw a moment ago (reading from a lagging replica on the second request).
  - Sequence-dependent data (comment threads, order-then-confirmation) appears in wrong causal order to some users.
  - An engineering team treats replication lag as a performance tuning problem ("it'll catch up") rather than a correctness problem.
  - A post-mortem attributes a user-visible bug to "replication delay" and the fix proposed is "reduce lag" rather than routing logic.

  Do NOT invoke when:
  - The root problem is which replication topology to use (use `replication-topology-selection`).
  - The lag is in a batch analytics pipeline where staleness by minutes or hours is acceptable.
  - The question is about write conflicts between concurrent writers (use `transaction-isolation-level-selection`).

  Key signals: "user sees old data after update," "eventual consistency is fine," "it'll catch up," "read replica routing," "monotonic reads," "read-your-writes."
source_book: "Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini"
source_chapter: "Chapter 6: Replication"
tags: [replication, replication-lag, read-your-writes, monotonic-reads, consistent-prefix, consistency, correctness]
related_skills: [replication-topology-selection, transaction-isolation-level-selection, timeliness-vs-integrity-distinction]
---

# Replication Lag as Consistency and Correctness Concern

## Current State

Read-after-write patterns (user reads own data immediately after write):
!`grep -rn 'Get.*After\|read.*write\|ReadYour\|afterCreate\|afterUpdate' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Database read paths (potential replica reads):
!`grep -rn '\.Query\|\.QueryRow\|\.Get\|\.Select' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Replication lag handling or stale-read guards:
!`grep -rn 'lag\|stale\|consistency\|ReadConsistency\|StrongRead' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Original Text (Reading)

> In "Problems with Replication Lag" on page 209 we will get more precise about eventual consistency and discuss things like the read-your-writes and monotonic reads guarantees.
>
> If the same user makes a read request and that request is routed to a lagging follower, they may see outdated information. This could be upsetting to the user.
>
> This effect is known as eventual consistency: if you stop writing to the database and wait a while, the followers will eventually catch up and become consistent with the leader. The word "eventually" is a deliberately vague term: it doesn't say anything about how far a replica might fall behind. In normal operation, the lag might be only a fraction of a second, and there might be no noticeable effects in practice. However, if the system is operating near capacity or if there is a problem in the network, the lag can easily increase to several seconds or even minutes.
>
> — Kleppmann & Riccomini, Chapter 6: Replication

---

## I — Methodological Framework (Interpretation)

The framework reframes replication lag from a performance metric into a correctness classification. Lag is not just "data is slightly old" — it produces specific, named consistency violations that directly affect user-visible behavior and can cause incorrect application decisions.

Three consistency guarantees exist precisely because lag violates them by default:

**Read-your-writes** (also called read-own-writes): A user who just wrote data must see their own write on subsequent reads, even if served from a replica. Without this guarantee, a user submitting a form change immediately reads the old value from a lagging replica, appears to lose their update, and may resubmit — creating duplicate writes.

**Monotonic reads**: A user who reads a value at time T must not read an older value at time T+1. Without this, a user refreshing a page can see data disappear — an item visible on first load is absent on second load because the second request hit a more-lagging replica. The data has not been deleted; the user is reading from a different point in replication time.

**Consistent prefix reads**: If a sequence of writes has a causal ordering, any reader must see them in that order. Without this, a reply to a question can appear before the question itself — the reply was written on a faster-replicating shard than the original question.

The key non-obvious insight: these are correctness problems, not performance problems. "It'll catch up" is not a solution for read-your-writes violations because there is no guarantee about when, and in the meantime the user may act on stale data. The remedy is read routing logic, not lag reduction alone.

Implementation options for read-your-writes: route reads of recently-written data to the leader; or pass the write's replication position (log sequence number) to the client in the response, and require that the replica serving subsequent reads has caught up to at least that position before answering.

---

## A1 — Past Application (From the Book)

### Case 1: Address Update Visible to Customer but Not to Fulfillment

- **Question:** A user submits a delivery address change on an e-commerce site. They receive a success response. The order confirmation page is served from a read replica that has not yet replicated the write. They see the old address and panic that their order will ship to the wrong location.
- **Use of Methodology:** The framework classifies this as a read-your-writes violation: the read path (order confirmation, served from replica) does not guarantee that the user's own recent write is visible. The "it'll catch up" response is incorrect — the user acted (panic, possible resubmit) based on the stale read before catch-up occurred.
- **Conclusion:** The fix is not to reduce replication lag. The fix is: (a) route reads of the delivery address to the leader for a configurable window after the user writes it; or (b) pass the write's LSN to the client and gate the replica read until that LSN is passed.
- **Result:** Without the fix, users experience apparent data loss after successful writes. The duplicate-submit consequence creates actual data problems, not just a cosmetic annoyance.

### Case 2: Social Feed Monotonic Reads Violation

- **Question:** A user refreshes their social media feed. On first load they see 20 items. On second load (a few seconds later) they see only 17. Three items have "disappeared." No items were deleted.
- **Use of Methodology:** The framework classifies this as a monotonic reads violation. The two requests were routed to different replicas with different replication positions. The second replica was behind the first, so items that were visible on the first (more-current) replica are not yet present on the second.
- **Conclusion:** The fix is sticky routing: route a given user's reads to the same replica for the duration of their session. If that replica fails, routing can switch, accepting a one-time regression. Sticky routing does not require the replica to be current, only consistent with itself across a user's session.
- **Result:** Users experience a non-monotonic view of data — a causally impossible sequence (items appear, then vanish, then re-appear as lag catches up). This erodes trust in the system even though no data was lost.

---

## A2 — Trigger Scenario (Future Trigger) ★

1. A user submits a password change and immediately tries to log in with the new password. The login service reads from a replica that hasn't yet replicated the new credential hash. Login fails.
2. A user edits a blog post title and clicks "view post." The post page is served from a replica and shows the old title. The user edits again, creating a second version.
3. A comment system shows comment B (a reply) before comment A (the original question) to some users, because comment B was replicated from a shard that caught up faster.
4. A mobile app updates a profile avatar and immediately loads the profile page: old avatar appears. The user closes and reopens the app: new avatar appears. Engineering says "it's eventually consistent, not a bug."
5. An order management system reads order status from a replica for the fulfillment workflow. The workflow sees "payment pending" when the payment was confirmed 500ms ago on the leader.

### Language Signals

- "The user sees old data right after they update"
- "It'll catch up in a second"
- "We route reads to replicas for performance"
- "Eventual consistency is fine for this use case"
- "The user saw it, then it disappeared on refresh"

### Distinguishing from Adjacent Skills

- Difference from `replication-topology-selection`: lag-as-correctness operates within an already-chosen single-leader topology and addresses routing and position-tracking logic; topology selection decides how many leaders exist and how conflicts are resolved.
- Difference from `transaction-isolation-level-selection`: isolation levels govern concurrent transaction interference on the primary; replication lag governs what followers return relative to the primary — these are distinct layers of the correctness problem.

---

## E — Execution Steps

1. **Classify the lag violation type**
   - Identify which of the three guarantees is violated: read-your-writes (user reads their own recent write and sees old value), monotonic reads (user sees data go backward in time), or consistent prefix (causally-ordered sequence appears out of order).
   - Completion criteria: The violation is named. This determines which routing or gating mechanism is applicable.

2. **Identify the specific read paths that require the guarantee**
   - Not all reads require read-your-writes. A public profile page read by anyone does not; a user's own account settings page read immediately after editing does. Map each read path to its consistency requirement.
   - Completion criteria: A list of read paths tagged as requiring read-your-writes / monotonic reads / consistent prefix, with justification.

3. **Implement the appropriate routing or position-tracking mechanism**
   - **Read-your-writes**: Option A — route reads of recently-modified data to the leader for a time window (e.g., 1 minute after any write by this user). Option B — return the write LSN in the write response; gate subsequent reads until the follower's replication position equals or exceeds that LSN.
   - **Monotonic reads**: Implement session-sticky routing — route a user's reads to the same replica for the session. Store the selected replica ID in the session.
   - **Consistent prefix reads**: Ensure causally-related writes are sent to the same shard or replication stream so their ordering is preserved.
   - Completion criteria: Routing logic is implemented and the specific read path no longer exhibits the violation under simulated lag (test by artificially pausing a replica).

4. **Do not treat lag reduction as the fix**
   - Lag reduction (tuning network, adding replicas) is an operational improvement that reduces the probability window but does not eliminate the violation. A system with 10ms lag still violates read-your-writes for users who act within those 10ms. The fix must be structural (routing or gating), not operational (lag tuning).
   - Completion criteria: The architecture document states which paths are leader-routed or LSN-gated, not "we minimize lag."

---

## B — Boundary ★

### Do Not Use This Skill When

- The lag is in a batch analytical pipeline feeding a dashboard — minutes of lag is acceptable and expected; this is not a read-your-writes scenario.
- The stale read is from a cache (Redis, Memcached) that is invalidated on write — cache invalidation is a related but distinct problem with different mechanics.
- The question is about write conflicts between concurrent writers on the primary, not about reads from replicas — use `transaction-isolation-level-selection`.
- The lag is acceptable to the product and the team has documented this explicitly as a conscious trade-off. "Eventually consistent" is a valid choice; this skill is for when it is an accidental assumption.

### Failure Patterns from the Book

- **ce09 — Async Replication Data Loss on Failover**: When a leader fails and a lagging follower is promoted, unreplicated writes are lost. This is a durability consequence of lag, more severe than a read-your-writes violation — the data is permanently gone, not just temporarily invisible. Lag-as-correctness addresses the read-side problem; this counter-example addresses the write-side durability problem.
- **ce12 — GitHub MySQL Stale Follower Promoted**: A lagging follower promoted after leader failure had an autoincrement counter behind the leader's state, generating IDs already in use. The lag was not a read-correctness problem — it was a write-safety problem upon failover. This shows lag has multiple failure dimensions beyond user-visible staleness.

### Author's Blind Spots / Era Limitations

- The book correctly identifies the three named consistency guarantees but provides limited guidance on the implementation complexity of LSN-based read gating at scale. Passing and tracking replication positions across microservices boundaries (where the read service and write service are separate) is significantly more complex than the single-application model the book assumes.
- The book implies that eventual consistency is acceptable for many use cases but provides no empirical data on how often replication-lag bugs actually bite production systems. The boundary between "tolerable" and "harmful" lag is left to the reader's judgment.

### Easily Confused Adjacent Methodology

- **Lag reduction vs. lag routing**: The most common mistake is treating lag as a tuning problem. Engineers who see a read-your-writes violation attempt to reduce replication lag via hardware or configuration. This reduces the probability window but does not eliminate the guarantee violation. The correct methodology is routing-based: guarantee that specific reads go to the right source, regardless of lag level.

---

## Related Skills

- **depends_on**: replication-topology-selection — this skill operates within an already-chosen topology; the replication topology must be established before addressing lag-specific routing logic.
- **contrasts_with**: transaction-isolation-level-selection — isolation levels address concurrent transaction interference on the primary; replication lag addresses what followers return relative to the primary; they are distinct correctness layers.
- **composes_with**: timeliness-vs-integrity-distinction — lag violations are timeliness violations by default, but the TVI framework determines whether a specific lag-induced stale read can cascade into a permanent integrity violation requiring different treatment.

---

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04
