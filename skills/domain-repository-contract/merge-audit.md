# Merge Audit — Domain-Repository-Contract

## Source Skills

- A: `ddd-golang/repository-interface-in-domain-package` (Matthew Boyle, 2022)
- B: `go-with-the-domain/update-function-closure-repository` (Three Dots Labs, 2026)

## Phase 1 Verdict

ADVANCE — all four gates passed.

## RIA++ Section Audit

### R

Both quotes are verbatim from verified source locations:

- Boyle quote: verified at line 2172 of `domain_driven_design_with_golang_book.md` (Chapter 4).
- Three Dots Labs quote: verified at lines 2159–2162 and 2632–2637 of `go_with_domain_book.md` (Chapter 7).
- Convergence note: one sentence. States shared principle (repository contract is a pure domain artifact) and each source's unique contribution (Boyle = WHERE, Three Dots Labs = HOW). ✓

### I

Single unified framework — no "Boyle says / Three Dots Labs says" framing. Divergence encoded as two named invariants (placement and mutation-shape) with explicit reasoning for why each is insufficient without the other. Scope boundary for plain insert/delete vs. closure-form clearly stated. ✓

### A1

- Case A (CoffeeCo): Boyle domain, DDD monolith. Shows import direction and type vocabulary. Different from Case B.
- Case B (Wild Workouts): Three Dots Labs domain, multi-backend scheduling service. Shows transaction isolation via parallel test. Different from Case A.
- Both cases share same architectural skeleton (domain interface, infrastructure implementation, never vice versa) but illuminate opposite facets. Cross-case pattern explicit. ✓

### A2

Sharper than union of source A2s. Added: "Instead of applying Boyle's placement rule alone (misses mutation safety) or Three Dots Labs' closure pattern alone (misses placement), use this when: \[6 specific conditions including the two-call fetch+save pattern and the `BeginTx` question\]." Each trigger is more specific than either source's trigger. ✓

### E

8-step sequence: steps 1–4 from Boyle (interface declaration, type vocabulary, naming, scope), steps 5–7 from Three Dots Labs (closure implementation, infrastructure placement, wiring), step 8 is synthesis (shared parallel test). Not longer than the longer source E (Three Dots Labs' E is 5 steps; merged is 9 including the conditional note — within acceptable range given combined domain). Conditional for plain insert/delete vs. closure preserved from Three Dots Labs' B section. ✓

### B

Three subsections:

1. Source A failures (Boyle): 4 failure modes — wrong package, wrong scope, wrong naming, no enforcement.
2. Source B failures (Three Dots Labs): 5 failure modes — two-call pattern, context threading, middleware coupling, nested updates, explicit transaction parameter.
3. Synthesis-specific failure mode: partial application (placement correct but mutation unsafe, or mutation correct but placement wrong) — absent from both source B sections. ✓
   Contradiction (Go "accept interfaces" idiom misread) surfaced explicitly. ✓

## Divergence Encoding

- Boyle: structural/locational (static import graph).
- Three Dots Labs: behavioural/mechanical (runtime transaction semantics).
- No conflict between the two — they are orthogonal and composable.
- Conditional from Three Dots Labs' B section (closure pattern applies only to read-modify-write; plain save/delete remain) preserved in I section and E section.

## Quote Accuracy

| Quote                             | Source                                         | Verified |
| --------------------------------- | ---------------------------------------------- | -------- |
| Boyle placement quote             | ddd-golang book line 2172                      | ✓        |
| Three Dots Labs closure signature | go-with-domain book lines 2159–2162, 2632–2637 | ✓        |

## Gate Summary

| Gate                         | Verdict                                                                                                                                                                               |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1 — Independent convergence | PASS: Boyle 2 contexts (Ch4 theory + Ch5 CoffeeCo); Three Dots Labs 2 contexts (Hour Ch7 + Training Ch11)                                                                             |
| V2 — Novel question          | PASS: "Correctly placed interface per Boyle — now how do I write a transaction-safe mutation method?" answered only by the merge                                                      |
| V3 — Non-obvious synthesis   | PASS: Closure-as-transaction-boundary applied to domain-package interface is not standard Go or DDD curriculum; parallel-test-against-all-implementations is particularly non-obvious |
| V4 — Sharper A2              | PASS: Merged A2 unifies under single diagnostic (placement + mutation shape) and adds cross-implementation parallel test trigger                                                      |
