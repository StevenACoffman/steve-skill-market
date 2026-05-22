# Merge Audit: Test-Double-Diagnostic-Sensing-to-Core

## Sources

- Source A: `welc/welc-sensing-vs-separation` (Feathers, WELC Ch. 3)
- Source B: `fcis/fcis-mocks-as-architecture-signal` (Bernhardt, DAS-0072)
- Phase 1 input: `candidates/pair-024-phase1.md`

## R — Quote Verification

| Quote                                                   | Source                            | Verification Status                                                                                                               |
| ------------------------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Sensing and separation definition (both numbered items) | Feathers, Ch. 3 (lines 1102–1107) | Verified exact match in Phase 1.5 audit                                                                                           |
| Bernhardt "no mocks, no stubs" passage                  | DAS-0072 transcript (lines 64–68) | Phase 1.5 audit notes this is a close paraphrase from an informal transcript; accurate in substance; minor accuracy concern noted |

**Bernhardt quote note:** The transcript is a video transcription; the SKILL.md presents a cleaned-up version. The merged SKILL.md preserves the content while keeping the attribution accurate.

## A1 Case Attribution

| Case                              | Attribution                                             | Verification Status         |
| --------------------------------- | ------------------------------------------------------- | --------------------------- |
| NetworkBridge / EndPoint hardware | Feathers, Ch. 3 (named case — NetworkBridge)            | Verified in Phase 1.5 audit |
| Sale/FakeDisplay                  | Feathers, Ch. 3 (primary example, scan/display pattern) | Verified in Phase 1.5 audit |
| Lone stub / Tweet value object    | Bernhardt, DAS-0072 (line 68)                           | Verified in Phase 1.5 audit |
| TweetRenderer no-mock case        | Bernhardt, DAS-0072 (lines 64–65)                       | Verified in Phase 1.5 audit |

**Note on case selection:** The merged A1 uses NetworkBridge (Case 1, hardware domain — covers both axes) and the Lone Stub (Case 2, pure value domain — covers Bernhardt's self-correction). Sale/FakeDisplay from Feathers is referenced in the I section instead to keep A1 to two cases. The merged cases are from different domains (hardware infrastructure vs. pure value objects) and demonstrate complementary aspects of the synthesis.

## Key Synthesis

The central operational synthesis is the purity test in E Step 4: after introducing a test double using Feathers' diagnostic, ask whether the mocked collaborator is pure data or genuine I/O. This conditional is provided by neither source book alone:

- Feathers says: use the right test double (recording fake for sensing, stub for separation). Stopping condition: tests pass.
- Bernhardt says: mocks are architecture signals; eliminate them by inverting collaborators to value arguments. Does not provide a stopping condition for when mocks are legitimate.
- Synthesis: the stopping condition is purity. Pure-data collaborator → Bernhardt's prescription (invert, eliminate). Genuine-I/O collaborator → Feathers' prescription (keep the test double).

## Divergence Encoding

| Divergence                                                                  | Resolution                                                                                 |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Feathers: mocks are the solution for legacy code                            | Encoded as Steps 1–3 (choose and apply the right test double)                              |
| Bernhardt: mocks are symptoms to be eliminated by architectural refactoring | Encoded as Steps 4–5 (purity test determines whether each double is permanent or a prompt) |
| Feathers stops at "tests pass"                                              | Named explicitly in synthesis-specific B failure                                           |
| Bernhardt doesn't address legitimate permanent mocks for I/O                | Named explicitly as source B limitation and resolved by the data-or-I/O conditional        |

## Genuine Tension Surfaced

B section explicitly surfaces: "Feathers accepts mocks as permanent fixtures in well-tested legacy code. Bernhardt treats mocks as temporary symptoms to be resolved by architectural refactoring." Resolution: these apply to different collaborator types. The conditional (data vs. I/O) resolves the tension per-collaborator, not universally.

## RIA++ Gate Check

| Gate                                                           | Status | Evidence                                                                                                                                                            |
| -------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R: attributed quotes + convergence note                        | PASS   | Both authors quoted; convergence note in R section                                                                                                                  |
| I: unified framework, no "Author A says/B says"                | PASS   | I section describes two-pass decision path without attribution framing; decision tree diagram included                                                              |
| A1: one case per book, different domains                       | PASS   | Case 1 = hardware infrastructure / both axes (Feathers); Case 2 = pure value domain / self-correction (Bernhardt)                                                   |
| A2: sharper than union; "instead of X or Y, use this when"     | PASS   | Explicit "instead of" trigger condition; distinguishes this from both source skills                                                                                 |
| E: reconciled with conditionals, not longer than longer source | PASS   | 5 steps; source A had 3 steps; source B had 4 steps; merged is slightly longer but the purity test (Step 4) is the synthesis contribution that makes the difference |
| B: source A failures, source B failures, synthesis-specific    | PASS   | Three labeled sections; synthesis-specific failure explicitly names the "stop at tests pass" failure                                                                |
| B: contradictions surfaced                                     | PASS   | "Genuine tension" paragraph explicitly names Feathers/Bernhardt stopping-condition conflict and resolution                                                          |

## Notes

- The decision tree in the I section is the most directly actionable part of the synthesis. It encodes both passes in a single readable structure that neither source book provides.
- The V1 concern from Phase 1.5 (Bernhardt's two cases both from the same Twitter client codebase) is addressed in the merged skill by using NetworkBridge (Feathers, hardware domain) as Case 1 and the Lone Stub (Bernhardt, pure value domain) as Case 2 — genuinely different domains.
- The synthesis-specific failure ("stop at tests pass when the recording fake returns pure data") is the highest-value contribution and directly addresses the gap between the two books' stopping conditions.
