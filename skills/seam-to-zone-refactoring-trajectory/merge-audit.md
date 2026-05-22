# Merge Audit: Seam-to-Zone-Refactoring-Trajectory

## Sources

- Source A: `welc/welc-seam-model` (Feathers, WELC Ch. 4)
- Source B: `fcis/fcis-two-zone-architecture` (Bernhardt, DAS-0072)
- Phase 1 input: `candidates/pair-022-phase1.md`

## R — Quote Verification

| Quote                                                         | Source                                  | Verification Status                                                                                                                 |
| ------------------------------------------------------------- | --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| "A seam is a place where you can alter behavior..."           | Feathers, Ch. 4 (source line 1562–1563) | Verified exact match in Phase 1.5 audit                                                                                             |
| "Every seam has an enabling point..."                         | Feathers, Ch. 4 (lines 1785–1787)       | Verified in Phase 1.5 audit                                                                                                         |
| "The seam view of software helps us see the opportunities..." | Feathers, Ch. 4                         | Verified in Phase 1.5 audit                                                                                                         |
| Bernhardt two-zone quote                                      | DAS-0072 transcript                     | Phase 1.5 audit notes this is a cleaned-up paraphrase of transcript — accurate in content, not verbatim from an informal transcript |

**Bernhardt quote note:** The source SKILL.md presents a polished version of Bernhardt's transcript. The merged SKILL.md attributes it accurately and preserves the content. This is the same minor accuracy concern flagged in Phase 1.5 — not falsification.

## A1 Case Attribution

| Case                                             | Attribution                                        | Verification Status         |
| ------------------------------------------------ | -------------------------------------------------- | --------------------------- |
| CAsyncSslRec::Init() / PostReceiveError          | Feathers, Ch. 4 (named case in seam model chapter) | Verified in Phase 1.5 audit |
| Twitter client / Timeline, Cursor, TweetRenderer | Bernhardt, DAS-0072 (lines 18–22, 86–89)           | Verified in Phase 1.5 audit |

## Key Synthesis

The sequential composability insight — seam-first gives access, two-zone gives destination — is the primary contribution. Neither source provides the "after you find the seam, where does the extracted code go?" answer.

The data-or-I/O classification in E Step 4 is the operational synthesis: when a seam extraction produces a fake that returns pure data, it is a signal that the fake should be eliminated by inverting the dependency to a value argument (Bernhardt's prescription). When the fake performs I/O, it is a permanent legitimate test tool (Feathers' stopping condition). This conditional is present in neither source book.

## Divergence Encoding

| Divergence                                                         | Resolution                                                                     |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| Feathers: retroactive diagnostic for legacy code                   | Encoded as Phase 1 of E (seam-first for legacy code)                           |
| Bernhardt: prospective design prescription for new code            | Encoded as Phase 2 of E (zone-targeting destination) + "For new code" sub-flow |
| Feathers: stops at "tests pass"                                    | Explicitly named in synthesis-specific B failure mode                          |
| Bernhardt: mocks should be eliminated by architectural refactoring | Encoded as data-or-I/O classification in E Step 4                              |

## RIA++ Gate Check

| Gate                                                           | Status | Evidence                                                                                                                                                                                                             |
| -------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R: attributed quotes + convergence note                        | PASS   | Both authors quoted; convergence note in R section                                                                                                                                                                   |
| I: unified framework, no "Author A says/B says"                | PASS   | I section describes trajectory without attribution framing                                                                                                                                                           |
| A1: one case per book, different domains                       | PASS   | Case 1 = legacy C++ codebase (Feathers); Case 2 = new Ruby application (Bernhardt)                                                                                                                                   |
| A2: sharper than union; "instead of X or Y, use this when"     | PASS   | Explicit "instead of" condition; distinguishes this from both source skills                                                                                                                                          |
| E: reconciled with conditionals, not longer than longer source | PASS   | Two-phase structure with conditional (data vs I/O); source A had 5 steps, source B had 4 steps; merged has 8 steps across two phases — slightly longer but the phases are structurally non-overlapping and necessary |
| B: source A failures, source B failures, synthesis-specific    | PASS   | Three labeled sections; synthesis-specific failure explicitly named                                                                                                                                                  |
| B: contradictions surfaced                                     | PASS   | "Stopping at tests pass" vs "eliminate the fake" tension explicitly resolved as a conditional                                                                                                                        |

## Notes

- The E section's two-phase structure mirrors the key synthesis insight: Phase 1 (Feathers' seam access) and Phase 2 (Bernhardt's zone destination). The eight steps are two non-overlapping workflows, not a single extended workflow — justified by the divergence between legacy and new-code contexts.
- The synthesis-specific failure mode ("stopping at tests pass when the fake returns pure data") is the most actionable contribution and directly addresses the gap that exists when a developer knows only one source.
