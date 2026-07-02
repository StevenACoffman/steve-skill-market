---
name: timeliness-vs-integrity-distinction
description: |
  Use this skill when a system design decision involves relaxing consistency, accepting stale reads, or choosing between strong consistency and availability — and you need to determine whether the proposed relaxation is safe.

  Invoke when:
  - A product manager or engineer proposes "relaxing consistency to improve performance" and you need to evaluate whether that is safe for a specific operation
  - A team is deciding whether eventual consistency is acceptable for a given read or write path
  - A system uses async replication or a log-based data pipeline and you need to classify which operations can tolerate propagation delay and which cannot
  - Post-mortem investigation reveals data loss or permanent corruption (integrity violation) that was initially diagnosed as a stale-read problem (timeliness violation)
  - Designing a stream-processing or event-sourcing system where operations are applied asynchronously
tags: [distributed-systems, consistency, correctness, eventual-consistency, integrity, timeliness, stream-processing]
allowed-tools: Bash, Read, Edit
---

# Timeliness Violations Vs. Integrity Violations Are Not Equivalent

## Current State

Eventual consistency or async propagation patterns:
!`grep -rn 'async\|Async\|eventual\|background\|goroutine\|go func' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Integrity constraints (foreign keys, unique checks):
!`grep -rn 'UNIQUE\|FOREIGN KEY\|CHECK\|NOT NULL\|constraint\|Constraint' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Stale-read tolerance annotations or comments:
!`grep -rn 'stale\|eventual\|approximate\|best.effort\|best_effort' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Original Text (Reading)

> More generally, the term consistency conflates two requirements that are worth
> considering separately:
>
> **Timeliness** means ensuring that users observe the system in an up-to-date state.
> However, that inconsistency is temporary, and it will eventually be resolved simply
> by waiting and trying again.
>
> **Integrity** means absence of corruption—no data loss, and no contradictory or
> false data. If integrity is violated, the inconsistency is permanent; waiting and
> trying again is not going to fix database corruption in most cases. Instead, explicit
> checking and repair is needed.
>
> In slogan form: violations of timeliness are allowed under eventual consistency,
> whereas violations of integrity result in perpetual inconsistency. In most
> applications, integrity is much more important than timeliness. Violations of
> timeliness can be annoying and confusing, but violations of integrity can be
> catastrophic.
>
> — Kleppmann & Riccomini, Chapter 13

______________________________________________________________________

## I — Methodological Framework (Interpretation)

"Consistency" is an overloaded term that collapses two independent properties — timeliness and integrity — into a single dial. Treating them as one is the source of many incorrect trade-off decisions. This skill provides an analytical framework to separate them.

**Timeliness** is about whether reads are up-to-date. A timeliness violation means a user sees a stale value — data that exists and is correct, but has not yet propagated to the node serving the read. Timeliness violations are *self-healing*: given time and no further writes, all replicas converge to the same state. The CAP theorem's "consistency" (linearizability) is a strong form of timeliness guarantee.

**Integrity** is about whether data is correct and complete — no records lost, no invariants violated, no contradictions between related pieces of data. An integrity violation is *not self-healing*: it is permanent. A lost write, an oversold inventory count, a credit without a matching debit — these do not resolve themselves by waiting. Recovery requires explicit detection and repair.

The operational consequence: **you can safely relax timeliness for display; you cannot safely relax integrity for decisions or state mutations.**

The framework produces a decision procedure:

1. Is this operation a *read for display* (showing a user information)? If yes, timeliness relaxation (eventual consistency, stale reads from replicas) is likely acceptable.
2. Is this operation a *read that drives a decision or a write* (enforcing a constraint, decrementing inventory, checking a uniqueness condition, computing a balance)? If yes, timeliness violation may produce an integrity violation — the stale read produces a wrong decision that commits an incorrect state. Integrity requirements must be evaluated here.
3. Can a temporary violation of the constraint be corrected after the fact (compensating transaction, apology, refund)? If yes, the integrity constraint may be "loosely interpreted" — you may proceed optimistically and correct retroactively, accepting timeliness relaxation even on decision paths.
4. Can the constraint violation *not* be corrected after the fact (money that cannot be recovered, medical records that cannot be unwritten, regulatory violations)? These require synchronous enforcement — timeliness must be maintained (strong consistency, linearizable storage) for this specific path.

This decomposition resolves what appears to be a binary trade-off (consistency or performance) into a composable design: different operations in the same system can safely have different timeliness requirements, as long as integrity is preserved for all.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Credit Card Statement — Timeliness Vs. Integrity in Banking (Chapter 13)

- **Question:** A bank's credit card statement does not yet show a transaction made 3 hours ago. Is this a correctness problem?
- **Use of Methodology:** Apply the framework: showing a transaction on a statement is a *display read*. The 3-hour lag is a timeliness violation — the transaction exists and is correctly recorded; it simply has not propagated to the statement view yet. The integrity question is separate: is the statement balance equal to the sum of all settled transactions? Is the money debited from the payer and credited to the merchant correctly? If yes (integrity preserved), the stale display is acceptable. If the transaction appeared on the statement but the money was not credited to the merchant (or vice versa), that is an integrity violation — permanent, catastrophic, requiring repair.
- **Conclusion:** Banks explicitly accept timeliness violations in statement display (settlement may take 1–2 business days). They treat integrity violations as category-1 incidents requiring immediate reconciliation. The same underlying event can produce one acceptable and one unacceptable failure mode, depending on which property is violated.
- **Result:** The framework allows the bank to use asynchronous settlement (timeliness relaxed) while maintaining strict double-entry accounting (integrity enforced). These are implemented by different mechanisms in the same system.

### Case 2: Inventory Overselling — Timeliness Relaxation Causing Integrity Violation (Chapter 13)

- **Question:** A product manager proposes showing slightly stale inventory counts to improve performance. The engineering team is nervous. What is the correct analysis?
- **Use of Methodology:** The framework separates two operations: (a) *displaying* the inventory count to users ("10 units available") — this is a display read; timeliness relaxation is acceptable. (b) *Using* the inventory count to decide whether to allow a purchase — this is a decision read that drives a state mutation (decrement inventory, commit sale). If the decision read returns a stale count, two concurrent purchasers may each read "1 unit available," each decide "allow purchase," and each commit a sale — resulting in -1 inventory (oversold). This is an integrity violation: the constraint "sold ≤ stocked" is permanently violated.
- **Conclusion:** The correct design relaxes timeliness only for display (eventually consistent read replica serves the count for display). For purchase commitment, integrity must be maintained via a serializable or compare-and-swap operation on the actual inventory record.
- **Result:** The system achieves both the performance goal (stale read for display) and the correctness goal (exact inventory enforcement for purchase decisions) by applying the timeliness/integrity distinction operation-by-operation.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A team proposes using eventual consistency for a rate limiter ("it's just a counter, a few extra requests over quota are fine"). The rate limiter enforces security or billing constraints — overrun may have contractual or security consequences.

2. A product manager says: "users can tolerate seeing their balance be slightly stale on the dashboard." The engineering team needs to determine whether this relaxation also applies to the overdraft check at withdrawal time.

3. A stream-processing pipeline applies payment events asynchronously. A consumer processes a payment event after a service crash. The team is debating whether the re-application of the event (duplicate processing) is a timeliness issue or an integrity issue.

4. A post-mortem reveals that "data was inconsistent" during a network partition. The team needs to classify whether data was temporarily stale (timeliness) or permanently lost/corrupted (integrity) to determine the severity and remediation path.

### Language Signals

- "can we tolerate eventually consistent reads here"
- "does this need linearizability or is eventual consistency fine"
- "users won't notice a few seconds of staleness"
- "we relaxed consistency for performance and now data is wrong"
- "is this a temporary inconsistency or permanent corruption"
- "strong consistency everywhere is too expensive"

### Distinguishing from Adjacent Skills

- Difference from `consistency-model-selection`: That skill helps choose between linearizability and eventual consistency for a system's reads and writes; this skill provides the analytical framework to determine *which* operations actually require strong consistency (integrity-critical decisions) vs. which can safely use eventual consistency (display reads).
- Difference from `replication-lag-as-correctness`: That skill focuses on the specific mechanism of replication lag and its impact on read-your-writes and monotonic reads; this skill is the broader analytical framework that determines whether a lag-induced inconsistency is a timeliness violation (self-healing) or an integrity violation (permanent).
- Difference from `end-to-end-idempotence-request-ids`: That skill addresses integrity violations caused by duplicate operation application; this skill identifies whether a consistency relaxation will *cause* an integrity violation in the first place.

______________________________________________________________________

## E — Execution Steps

1. **List every read and write operation that is being considered for consistency relaxation**

   - Completion criteria: You have a concrete list of operations (e.g., "read inventory count for display," "read inventory count before committing a purchase," "read account balance for dashboard," "read account balance for overdraft check").

2. **Classify each operation as "display read," "decision read," or "state mutation"**

   - Display read: the result is shown to a user for informational purposes; no downstream write or decision is gated on it.
   - Decision read: the result determines whether a state mutation is allowed or what value a mutation uses.
   - State mutation: the operation writes or changes durable state.
   - Completion criteria: Every operation on the list is labeled. Note that a single user action often includes both a decision read and a state mutation (e.g., "check balance then debit").

3. **For each display read: timeliness relaxation is safe. Apply eventual consistency.**

   - No integrity risk: stale display data is self-healing.
   - Completion criteria: Display reads are routed to eventually consistent replicas, caches, or read-optimized views without integrity concern.

4. **For each decision read or state mutation: apply the compensating transaction test**

   - Ask: if a timeliness violation causes the wrong decision (e.g., overselling by 1 unit), can the error be corrected after the fact at acceptable cost?
   - If yes (e.g., airline oversell → offer compensation, refund a duplicate charge): the constraint is "loosely interpreted." Proceed optimistically with eventual consistency; implement a compensating transaction / apology workflow.
   - If no (e.g., regulatory violation, unrecoverable security breach, medical record corruption): the integrity requirement is hard. This operation requires synchronous enforcement — linearizable storage, serializable isolation, or a consensus-based CAS operation.
   - Completion criteria: Every decision read and state mutation is classified as "loosely interpreted constraint (async + compensation OK)" or "hard integrity requirement (synchronous enforcement required)."

5. **Implement different consistency mechanisms for different operation classes in the same system**

   - Display reads: eventual consistency (replicas, caches).
   - Loosely interpreted constraints: async pipeline + compensating transaction workflow.
   - Hard integrity requirements: linearizable storage or serializable transactions (scoped to the smallest possible operation, not applied globally).
   - Completion criteria: The system uses the minimum consistency strength required for each operation class; no operation has consistency stronger than it needs.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- All operations in the system clearly require hard integrity enforcement (e.g., a financial settlement system with regulatory auditability requirements and no tolerance for temporary overshooting). In this case, eventual consistency is not a viable option and the consistency model selection skill applies directly.
- The question is purely about *how to implement* the required consistency level (e.g., "how do I implement linearizable reads") — use `consistency-model-selection` for that.
- You are debugging a performance problem caused by synchronous coordination — the performance fix is to scope the strong consistency requirements using this skill, but the starting point is identifying which operations need it.

### Failure Patterns from the Book

- **ce19 (Retry After Timeout Executes Transaction Twice)**: A retry causes double application of a money transfer — an integrity violation. What initially looks like a "networking issue" or a "timeliness problem" is actually permanent: both transactions commit, both debits are applied. The framework classifies this as an integrity violation from the moment duplicate application occurs, not a timeliness issue.
- **ce11 (LWW Silent Data Loss)**: Two concurrent writes to the same key, one is silently discarded by LWW. This is an integrity violation (data permanently lost), not a timeliness violation — the data does not eventually appear; it is gone. Teams that accept LWW as "eventual consistency" may miscategorize this as timeliness-acceptable when it is integrity-catastrophic.

### Author's Blind Spots / Era Limitations

- The book presents the timeliness/integrity distinction primarily in the context of stream-processing and event-sourcing systems (Chapter 13). It does not systematically apply the framework to earlier chapters (replication, transactions), even though the distinction is equally useful there. Engineers may not recognize that this analytical tool applies to any system with async components, not just event-driven architectures.
- The "loosely interpreted constraints" section relies heavily on examples from retail (overbook airline seats, oversell warehouse inventory) where compensation is relatively cheap. The book does not provide guidance on how to evaluate compensation cost in domains where the apology may be expensive (financial penalties, regulatory fines, reputational harm). The decision to accept an integrity risk via compensation requires domain-specific judgment that the book does not provide.
- The 2026 edition does not address the interaction between this framework and regulatory audit requirements: some regulations (SOX, PCI-DSS) impose integrity requirements that cannot be met by compensating transactions, regardless of business acceptability.

### Easily Confused Adjacent Methodology

- **CAP theorem consistency vs. timeliness**: The CAP theorem's "C" refers specifically to linearizability (a strong timeliness guarantee). Engineers who equate "relaxing CAP C" with "accepting integrity violations" will under-engineer. CAP relaxation is a timeliness decision; integrity must be evaluated independently and is not governed by CAP.

______________________________________________________________________

## Related Skills

- **depends_on**: consistency-model-selection — TVI uses linearizability and eventual consistency as vocabulary; understanding what each model provides is prerequisite to classifying which operations require which guarantee.
- **contrasts_with**: replication-lag-as-correctness — lag-as-correctness addresses the mechanism (routing and LSN gating) for specific lag-induced violations; TVI provides the upstream classification that determines whether a lag violation is merely annoying (timeliness) or catastrophic (integrity).
- **composes_with**: end-to-end-idempotence-request-ids — TVI identifies that duplicate operation application is an integrity violation; idempotency keys are the mechanism that prevents that integrity violation from occurring.
- **composes_with**: transaction-isolation-level-selection — TVI determines which concurrency anomalies are integrity-critical (write skew in a quota system = permanent violation) vs. tolerable; this classification drives the minimum isolation level required.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini — Chapter 13: The Future of Data Systems
