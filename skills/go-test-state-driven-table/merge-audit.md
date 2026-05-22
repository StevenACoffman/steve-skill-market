# Merge Audit — Go-Test-State-Driven-Table

## Source Skills

| Field        | Source A                            | Source B                           |
| ------------ | ----------------------------------- | ---------------------------------- |
| Slug         | rednafi/test-state-not-interactions | hashimoto/table-driven-named-cases |
| Book         | Go Advice                           | Advanced Testing with Go           |
| Author       | Redowan Delowar (rednafi)           | Mitchell Hashimoto                 |
| Phase 1 file | candidates/pair-029-phase1.md       | —                                  |

## Phase 1 Verdict

ADVANCE — all four validation gates passed (V2 and V3 with moderate confidence).

| Gate                          | Verdict       | Reasoning                                                                                                                                                                                                                                                                                                               |
| ----------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1 (genuine convergence)      | PASS          | Two independent authors from different contexts independently concluded that test structure must communicate intent without requiring the reader to trace implementation code. rednafi (correctness argument); Hashimoto (diagnostic efficiency argument).                                                              |
| V2 (novel questions answered) | MARGINAL PASS | "How do I write a Go test for a function with external dependencies AND multiple input cases?" requires both skills. The map-keyed table + FakeDB state assertions pattern does not appear in either source.                                                                                                            |
| V3 (non-obvious synthesis)    | MARGINAL PASS | The specific insight — that the map key names the behavioral scenario the fake is set up to test, and that state assertions in each table case make the test both legible and correct — is not articulated in either source. Moderate confidence: experienced developers might derive it by applying both sequentially. |
| V4 (sharper A2)               | PASS          | Merged A2 adds the composite trigger: "stateful dependencies + multiple input cases + failures that are immediately identifiable + correctness detection for swallowed errors." Neither source alone answers this combination.                                                                                          |

## Synthesis Decisions

### R Section

- Both sources quoted with attribution. Quotes verified against sources in pair-029-phase1.md §Phase 1.5.
- rednafi quote: verified verbatim at bookSource/rednafi/test_state_not_interactions.md lines 43–45.
- Hashimoto quote: verified verbatim at bookSource/hashimoto/Advanced_testing_with_go.md lines 64–66.
- Convergence note explicitly names what is shared (test output must identify failure without tracing implementation) and what each adds uniquely (correctness stake vs. DX stake).

### I Section

- Unified framework with the two axes named explicitly (Axis 1 — what you assert; Axis 2 — how you organize cases) to clarify that they are orthogonal.
- The composition paragraph is the key synthesis: neither source describes the combined pattern; it emerges from applying both simultaneously.
- "When to apply" box resolves the conditional for pure functions (no fake needed — use map table with direct value assertions).

### A1 Section

- Two cases in genuinely different domains: CreateUser (correctness failure from swallowed error, rednafi) and Terraform index 3014 (diagnostic failure from unnamed cases, Hashimoto).
- Cross-case observation noted in phase1.md (rednafi's FakeDB uses `seen map[string]struct{}` — the same data structure Hashimoto recommends for test tables) is surfaced in the convergence note rather than A1, to keep A1 focused on concrete cases.

### A2 Section

- Five triggers; Trigger 1 is the composite case requiring both skills.
- Trigger 5 (LLM-generated mocks) is included from rednafi — it is an increasingly common scenario and the merged pattern is the direct antidote.
- Do-not-use section distinguishes pure functions (use map table without fake), complex dependencies (use testcontainers), sequential integration tests (not parallel cases), and gRPC servers (generated mocks are genuinely ergonomic).

### E Section

- 7 steps total. Longer source E (rednafi: 6 steps) extended to 7 to include Hashimoto's map-key mechanics explicitly.
- Step 4 shows the complete map table declaration with `setupFake` function field — this is the synthesis pattern not present in either source.
- Step 5 shows the complete test loop with `t.Run(name, ...)`, `require.ErrorIs`, and `assert.Equal` on fake state — the composed pattern.
- `t.Run()` is noted as the modern Go-idiomatic upgrade to both sources (Hashimoto's talk predates Go 1.7; rednafi does not address table structure explicitly).

### B Section

- Three-part structure: Source A failures (rednafi), Source B failures (Hashimoto), synthesis-specific failure mode.
- Synthesis failure mode: map-keyed table with generated mocks — gives DX benefits (named cases) but not correctness benefits (state assertions). This failure mode only exists in the merged context.
- Large interface drift added as an honest limitation of rednafi's position (acknowledged by rednafi himself in his B section).

## Quote Verification Status

- rednafi "general theme when writing unit tests" quote: verified verbatim (pair-029-phase1.md §Phase 1.5, bookSource lines 43–45)
- rednafi "interaction tests" terminology: verified at bookSource line 34
- rednafi "if an error is accidentally swallowed" causal chain: verified as present in source article
- Hashimoto "Consider naming cases" quote: verified verbatim (pair-029-phase1.md §Phase 1.5, bookSource lines 64–66)
- Hashimoto `map[string]struct{A, B, Expected int}` code block: verified at bookSource lines 70–73

## Divergences Encoded as Conditionals

| Divergence                                                                         | Encoding                                                                                                             |
| ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| rednafi has correctness stake; Hashimoto has only DX stake                         | Named explicitly in I section ("The correctness stake" paragraph) and in B section separation                        |
| rednafi covers lifecycle scope (TestMain, grouped subtests); Hashimoto does not    | Step 7 of E section covers lifecycle scope from rednafi; not attributed but correctly attributed to rednafi's source |
| Hashimoto applies to pure functions; rednafi applies only to stateful dependencies | "When to apply" box in I section and Do-not-use in A2                                                                |

## Files Written

- `SKILL.md` — merged skill (this document's counterpart)
- `merge-audit.md` — this file

## Merge Date

2026-05-05
