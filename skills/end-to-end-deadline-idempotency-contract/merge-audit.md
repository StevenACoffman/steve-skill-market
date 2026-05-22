# Merge Audit — End-to-End-Deadline-Idempotency-Contract

## Source Skills

- A: `kleppmann/end-to-end-idempotence-request-ids` (Kleppmann & Riccomini, 2nd ed.)
- B: `grpc-up-and-running/grpc-deadline-propagation` (Indrasiri & Kuruppu, 2020)

## Phase 1 Verdict

ADVANCE — all four gates passed.

## RIA++ Section Audit

### R

Both quotes are verbatim from verified source locations:

- Kleppmann quote: verified verbatim at DDIA 2nd ed. line 23121 and adjacent lines (Chapter 13).
- Indrasiri/Kuruppu quote: verified verbatim at gRPC_up_and_running_book.md lines 3833–3844 (Ch. 5).
- Convergence note: one sentence. States shared principle (end-to-end propagation of a set-once value from originating client) and each source's unique contribution (Kleppmann = idempotency key prevents duplicate state application; Indrasiri = absolute deadline prevents unbounded chain execution). ✓

### I

Single unified framework. No "Kleppmann says / Indrasiri says" framing. Two contracts named and explained separately. Cross-layer interaction failure (synthesis) gets its own subsection with the complete failure sequence. The sequencing rule (deadline → idempotency → retry within budget) is stated as a complete contract, readable without either source. ✓

### A1

- Case A (payment double-charge, Kleppmann): HTTP → database → stream processor, financial correctness. Shows idempotency key composing across layers.
- Case B (three-hop gRPC chain, Indrasiri): gRPC service chain, resource efficiency. Shows absolute deadline consuming from remaining budget at each hop.
- Case C (combined failure, synthesis): cross-layer, financial system with gRPC chain. Shows committed-operation-unknown-to-client produced by combining deadline reset bug with client compensating action. Case C is absent from both source skills.
- Cross-case pattern: all three cases demonstrate silent failure produced by intermediate service violating the end-to-end contract. ✓

### A2

Sharper than union of source A2s. Six specific triggers. The cross-contract trigger — "the client got DEADLINE_EXCEEDED but the downstream service logged a successful completion, and the downstream operation has no idempotency key" — combines both failure modes and is absent from both source A2s. The rule about treating a post-deadline retry as a new user action with a new key is absent from both source A2s. ✓

### E

7-step sequence: steps 1 and 3–4 from Indrasiri (deadline at client, propagate ctx, check before expensive work), steps 2 and 5 from Kleppmann (idempotency key at client, deduplication at state store), step 6 is the synthesis (retry within budget; post-deadline retry as new user action), step 7 is verification including the cross-contract test. Not longer than the longer source E (Kleppmann is 5 steps; merged is 7, justified by combined domain). ✓

### B

Three subsections:

1. Source A failures (Kleppmann): 4 failure modes — missing key, key dropped/regenerated per hop, key at server, at-most-once wrong fix.
2. Source B failures (Indrasiri): 4 failure modes — context.Background(), no ctx.Err() check, no ctx.Done() on non-cancellable I/O, deadline extension vs. reduction.
3. Synthesis-specific failure mode: deadline reset + client compensating action → committed operation client does not know about — absent from both source B sections. ✓
   Explicit statement of what idempotency keys do not protect against (client acting on incorrect state). ✓

## Divergence Encoding

- The sources address different hazards of multi-hop communication: duplicate state application (idempotency key) and unbounded resource consumption (deadline propagation).
- Divergence encoded as the interaction: the deadline reset bug can cause a retry to succeed after the client has received DEADLINE_EXCEEDED and moved on, producing a committed operation the idempotency key correctly stores but the client does not know about.
- Resolution (from Phase 1 E-Reconciliation): both contracts must hold simultaneously; retry is only valid within the remaining deadline budget; post-deadline retries are new user actions with new keys and new deadlines.

## Quote Accuracy

| Quote                       | Source                                      | Verified   |
| --------------------------- | ------------------------------------------- | ---------- |
| Kleppmann idempotency quote | DDIA 2nd ed. line 23121+                    | ✓ verbatim |
| Indrasiri deadline quote    | gRPC_up_and_running_book.md lines 3833–3844 | ✓ verbatim |

## Gate Summary

| Gate                         | Verdict                                                                                                                                                                                                                                  |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1 — Independent convergence | PASS: Kleppmann 2 contexts (payment Ch13 + stream processing Ch13); Indrasiri 2 contexts (Ch5 three-tier chain + explicit generalization beyond gRPC)                                                                                    |
| V2 — Novel question          | PASS: "Client got DEADLINE_EXCEEDED on a payment call; intermediate Order service has context.Background() bug; what committed?" answered only by the merge                                                                              |
| V3 — Non-obvious synthesis   | PASS: Interaction between deadline reset bug and client compensating action producing committed-operation-unknown-to-client is not standard distributed systems curriculum; engineers treat retries vs. timeouts as independent problems |
| V4 — Sharper A2              | PASS: Cross-contract trigger (deadline reset + idempotency key interaction) and post-deadline-retry-as-new-action rule are both absent from source A2s                                                                                   |
