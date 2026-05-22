# Merge Audit — Characterization-Test-Golden-File

## Source Skills

| Field        | Source A                             | Source B                           |
| ------------ | ------------------------------------ | ---------------------------------- |
| Slug         | welc/welc-characterization-test      | hashimoto/golden-files-update-flag |
| Book         | Working Effectively with Legacy Code | Advanced Testing with Go           |
| Author       | Michael C. Feathers                  | Mitchell Hashimoto                 |
| Phase 1 file | candidates/pair-023-phase1.md        | —                                  |

## Phase 1 Verdict

ADVANCE — all four validation gates passed.

| Gate                          | Verdict | Reasoning                                                                                                                                                                                                                                                                                              |
| ----------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| V1 (genuine convergence)      | PASS    | Two independent authors from different domains and eras independently discovered let-code-supply-expected-value. Feathers (2005, OO legacy code rescue); Hashimoto (~2017, Go formatter testing). Each has ≥2 independent contexts in their sources.                                                   |
| V2 (novel questions answered) | PASS    | Neither source alone answers: "I need to characterize legacy service API before a rewrite AND want maintainable golden-file-backed tests." Feathers does not address storage format or update mechanics. Hashimoto does not address the legacy/unknown-behavior posture or characterization lifecycle. |
| V3 (non-obvious synthesis)    | PASS    | Golden files as the optimal storage format for characterization test expected values is not documented in Go circles. The comprehension-vs-maintainability conditional on when to use manual fail-observe-pin vs. -update flag is a novel articulation.                                                |
| V4 (sharper A2)               | PASS    | Merged A2 adds the rewrite-with-golden-file-behavioral-contract scenario. Neither source alone covers this. Trigger 1 in merged A2 describes a real Go microservice replacement scenario.                                                                                                              |

## Synthesis Decisions

### R Section

- Both sources quoted with attribution.
- Convergence note placed immediately after both quotes, in one sentence, naming what is shared and what each adds uniquely.
- Hashimoto's code block reproduced verbatim from source SKILL.md R section (uses `ioutil` per original; B section notes the `os` upgrade).

### I Section

- Unified framework: no "Feathers says / Hashimoto says" framing after the R section.
- The divergence on when to use manual vs. automated capture is encoded as a conditional table.
- The rewrite-enabler paragraph synthesizes the p20 extension (Feathers Testing Patience) with golden files as the storage mechanism — this is the key synthesis insight neither source articulates.

### A1 Section

- Two cases from different domains as required: PageGenerator (OO legacy class rescue, Feathers Ch. 13) and Terraform graph (Go formatter/DAG testing, Hashimoto).
- Deliberately no synthesis case in A1 — the composition pattern appears in E instead.

### A2 Section

- Merged A2 explicitly states "Instead of asking [Feathers trigger] or [Hashimoto trigger], use this when [composite condition]."
- Four triggers added; all four require both source skills to answer.
- Do-not-use section reconciles Feathers' "code you are not about to touch" constraint with Hashimoto's unconstrained applicability.

### E Section

- 9 steps total. Longer source E (Hashimoto: 6 steps) had 6 steps. Merged E is 9 steps but steps 4–6 replace the separate Feathers write-fail-observe-pin (5 steps) and Hashimoto generate-inspect-commit (3 steps) with an integrated sequence.
- Sequence follows Phase 2 instructions: (1) identify behavior (Feathers), (2) write failing assertion, (3) run and capture as golden file (Hashimoto), (4) commit, (5) add -update flag.
- Step 8 shows table-driven composition (map key → golden filename) as a concrete code example.

### B Section

- Three-part structure as required by RIA++ rules: (1) Source A failures, (2) Source B failures, (3) synthesis-specific failure mode.
- Synthesis failure mode: using -update flag as comprehension substitute — a failure mode that only exists in the merged context, not in either source alone.
- Contradiction between Feathers (temporary scaffolding) and Hashimoto (permanent fixture) surfaced explicitly with a resolution via conditional rather than suppression.

## Quote Verification Status

- Feathers characterization test algorithm: verified verbatim against source (pair-023-phase1.md §Phase 1.5)
- Feathers "not trying to find bugs" quote: verified (pair-023-phase1.md §Phase 1.5)
- Feathers behavioral invariants quote: verified from Testing Patience talks (pair-023-phase1.md §Phase 1.5)
- Hashimoto code block: reproduced from source SKILL.md R section, matches original at bookSource/hashimoto/Advanced_testing_with_go.md lines 98–124
- Hashimoto slide bullets: verified at bookSource/hashimoto/Advanced_testing_with_go.md line 126
- Hashimoto gofmt origin story: from talk transcript, not verbatim from text source — flagged in phase1.md §Phase 1.5 as "appears to be from a talk transcript"; reproduced as a quote block with attribution to the talk

## Divergences Encoded as Conditionals

| Divergence                                                                 | Encoding                                                                                                            |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Manual fail-observe-pin (Feathers) vs. -update flag automation (Hashimoto) | Conditional table in I section: comprehension goal → manual; maintainability goal → -update                         |
| Temporary scaffolding (Feathers) vs. permanent fixture (Hashimoto)         | Surfaced as contradiction in B section; resolved via conditional on context (refactoring vs. stable-output testing) |
| Targeted at change boundary (Feathers) vs. any complex output (Hashimoto)  | Do-not-use item in A2: "code with no imminent changes" retains Feathers' constraint as a condition                  |

## Files Written

- `SKILL.md` — merged skill (this document's counterpart)
- `merge-audit.md` — this file

## Merge Date

2026-05-05
