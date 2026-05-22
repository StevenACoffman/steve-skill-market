# Merge Audit — Persistence-Interface-Domain-Contract

## Source Skills

- A: `grpc-go-for-professionals/grpc-db-interface-decoupling` (Clément Jean, 2023)
- B: `ddd-golang/repository-interface-in-domain-package` (Matthew Boyle, 2022)

## Phase 1 Verdict

ADVANCE — all four gates passed.

## RIA++ Section Audit

### R

Both quotes are verbatim from verified source locations:

- Jean quote: verified at lines 3527–3528 of `gRPC_go_for_professionals_book.md` (Ch5 + Ch9).
- Boyle quote: verified at line 2172 of `domain_driven_design_with_golang_book.md` (Chapter 4).
- Convergence note: one sentence. States shared principle (interface expressed in the owner's type vocabulary) and each source's unique contribution (Jean = type vocabulary / proto churn; Boyle = package placement / import direction). ✓

### I

Single unified framework. No "Jean says / Boyle says" framing. Two perpendicular axes named and explained independently. Decision procedure for gRPC+DDD projects states which rule to apply when they interact. Pure gRPC and pure DDD conditionals preserved. ✓

### A1

- Case A (TODO service, Jean): gRPC-only, no DDD aggregates. Shows type vocabulary rule. Different technology stack and domain from Case B.
- Case B (CoffeeCo, Boyle): DDD monolith, no gRPC. Shows package placement rule. Different technology stack and domain from Case A.
- Cross-case pattern: same underlying principle (interface in owner's type vocabulary) demonstrated from independent directions. ✓

### A2

Sharper than union of source A2s. Added: "Instead of applying only Jean's type rule (leaves package placement undefined) or only Boyle's placement rule (leaves proto-type contamination unaddressed), use this when: [6 specific conditions]." The cross-cutting trigger — "defining a storage interface for a gRPC service with a DDD domain layer" — is absent from both source A2s. ✓

### E

7-step sequence combining both sources without conflict. Key reconciliation: step 1 applies Boyle (domain package placement); step 2 applies Jean (type vocabulary); step 3 is the gRPC handler as the sole adapter (synthesis); steps 4–6 complete with infrastructure wiring; step 7 is the schema-churn verification test (synthesis). Not longer than the longer source E (Boyle is 6 steps; merged is 7). ✓

### B

Three subsections:

1. Source A failures (Jean): 3 failure modes — proto type in signature, FakeDb imports pb, interface in generated package.
2. Source B failures (Boyle): 4 failure modes — wrong package, CRUD verb naming, wrong scope, no enforcement.
3. Synthesis-specific failure mode: partial application in gRPC+DDD (satisfying one axis while violating the other) — absent from both source B sections. ✓
   Contradiction (Jean's server-layer placement vs. Boyle's domain-package placement) surfaced explicitly with conditional resolution. ✓

## Divergence Encoding

- Jean: transport-side / type vocabulary axis (proto churn propagates to storage).
- Boyle: domain-side / package placement axis (import direction).
- The two rules address perpendicular axes and compose without conflict.
- For pure gRPC without DDD: Jean's server-layer placement acceptable.
- For gRPC + DDD: both rules apply simultaneously; domain package placement overrides Jean's server-layer default.

## Quote Accuracy

| Quote                      | Source                                             | Verified |
| -------------------------- | -------------------------------------------------- | -------- |
| Jean type decoupling quote | gRPC_go_for_professionals_book.md lines 3527–3528  | ✓        |
| Boyle placement quote      | domain_driven_design_with_golang_book.md line 2172 | ✓        |

## Gate Summary

| Gate                         | Verdict                                                                                                                                             |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1 — Independent convergence | PASS: Jean 4+ db interface evolutions Ch5–Ch9; Boyle 2 aggregate interfaces (purchase + store)                                                      |
| V2 — Novel question          | PASS: "Building gRPC service with DDD — where does storage interface go and what types can it use?" answered only by the merge                      |
| V3 — Non-obvious synthesis   | PASS: Handler as sole proto-absorbing adapter, applied to domain-package interface, is not standard curriculum for either gRPC or DDD practitioners |
| V4 — Sharper A2              | PASS: Merged A2 adds the cross-cutting gRPC+DDD scenario and the compile-error-confinement verification step, both absent from source A2s           |
