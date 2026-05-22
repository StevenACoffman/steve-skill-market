# Merge Audit — Go-Http-Service-Test-Strategy

## Source Skills

| Field        | Source A                       | Source B                                       |
| ------------ | ------------------------------ | ---------------------------------------------- |
| Slug         | lets-go/letsgo-layered-testing | matryer-http-services/matryer-run-e2e-testing  |
| Book         | Let's Go                       | How I Write HTTP Services in Go After 13 Years |
| Author       | Alex Edwards                   | Mat Ryer                                       |
| Phase 1 file | candidates/pair-028-phase1.md  | —                                              |

## Phase 1 Verdict

ADVANCE — all four validation gates passed.

| Gate                          | Verdict | Reasoning                                                                                                                                                                                                                     |
| ----------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1 (genuine convergence)      | PASS    | Two independent authors (Edwards 2023, Ryer 2024) from different Go web service contexts independently concluded that ResponseRecorder-only handler tests are inferior and that full-HTTP-stack tests are the better default. |
| V2 (novel questions answered) | PASS    | "When should I use mock injection vs. real-dependency e2e tests?" — neither book answers this because each presents only its own approach. The merged skill provides the decision matrix.                                     |
| V3 (non-obvious synthesis)    | PASS    | The CSRF Sec-Fetch-Site header requirement, the side-by-side tier decision matrix, and Ryer's explicit deletion rule are not documented together in the Go ecosystem.                                                         |
| V4 (sharper A2)               | PASS    | Merged A2 answers the full strategy question: what test layers, when to use mocks vs. real infra, what infrastructure each tier requires. Neither source alone answers this.                                                  |

## Synthesis Decisions

### R Section

- Both sources quoted with attribution. Ryer's quotes are verbatim from the source (verified in pair-028-phase1.md §Phase 1.5). Edwards' quotes are paraphrased — flagged in the Audit Information section of SKILL.md.
- Convergence note explicitly names the shared conclusion (full-stack HTTP testing superior) and the one critical divergence (dependency fidelity at the data layer).

### I Section

- Unified framework: the two approaches are named Tier 1 (Edwards) and Tier 2 (Ryer) rather than "Edwards says / Ryer says." This is the key synthesis insight from Phase 2 instructions: they are complementary tiers, not competing choices.
- Decision matrix table encodes all dimensions where the tiers differ.
- The delete-duplicates rule (Ryer) is included with the team-governance caveat (from Ryer's own B section in the source).

### A1 Section

- Two cases in genuinely different domains: Grafana IRM (real-dependency e2e, multi-tenant HTTP API) and Let's Go snippet application (mock-injection e2e, CSRF/session form flows).
- The CSRF/Sec-Fetch-Site finding is elevated to the conclusion of Case 2 because it is the most operationally non-obvious piece of Edwards' approach.

### A2 Section

- Five triggers added; all five require knowing both tiers to answer.
- Trigger 4 explicitly addresses the choice between tiers — the question neither source alone answers.
- Trigger 5 addresses the CSRF debugging scenario (the most common real-world pain point from Edwards).

### E Section

- Structured as two separate labeled sections (Tier 1 and Tier 2) within one E section.
- Total steps: 7 (Tier 1) + 5 (Tier 2) = 12, but each tier's steps are self-contained. Neither tier's step count exceeds its source (Edwards: 7 steps; Ryer: 6 steps).
- Step 5 of Tier 2 (delete duplicates) is included as it is a key behavioral prescription from Ryer, with the team-governance caveat.

### B Section

- Three-part structure: Tier 1 failures (Edwards), Tier 2 failures (Ryer), synthesis-specific failure mode.
- Synthesis failure mode: believing one tier provides complete coverage — a failure mode that only exists in the merged context where two tiers are defined.
- Contradiction between Ryer (delete unit tests) and Edwards (three-tier coexistence) surfaced explicitly with a team-governance resolution rather than suppression.

## Quote Verification Status

- Ryer "I err on the side of end-to-end testing" quote: verified verbatim against source (pair-028-phase1.md §Phase 1.5, source line 596)
- Ryer "I would rather call the run function" quote: verified verbatim (source line 598)
- Ryer "I will go back and delete tests" quote: verified (source line 598+)
- Edwards quotes: paraphrased, not verbatim — source is epub at bookSource/golang/lets-go.epub; verbatim accuracy not confirmed. Flagged in SKILL.md Audit Information.

## Divergences Encoded as Conditionals

| Divergence                                                    | Encoding                                                                     |
| ------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Real DB (Ryer) vs. mock models (Edwards)                      | Decision matrix table in I section; separate Tier 1/Tier 2 labels throughout |
| Delete unit tests (Ryer) vs. three-tier coexistence (Edwards) | Surfaced as contradiction in B section; resolved as team governance decision |
| Port management needed (Ryer) vs. not needed (Edwards)        | Captured in decision matrix and in Tier 2 B section                          |

## Files Written

- `SKILL.md` — merged skill (this document's counterpart)
- `merge-audit.md` — this file

## Merge Date

2026-05-05
