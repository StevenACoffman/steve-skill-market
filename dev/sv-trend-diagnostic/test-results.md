# Test Results: Schedule Variance Trend Diagnostic

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description and A2 trigger conditions are well-targeted. The description names EVM, negative/flat/worsening SV, and the specific framing of "corrective trigger vs. status data point." This is specific enough to distinguish sv-trend-diagnostic from general schedule management questions. The A2 section provides five concrete trigger scenarios covering the core use cases: active programs with SV trends, PMO portfolio reviews, milestone conversations, post-mortems, and tool evaluation decisions. Together, description + A2 reliably distinguish this skill from: (a) Agile/sprint velocity problems, (b) situations without an EVM baseline, (c) stakeholder communication questions about how to present bad news.

The boundary conditions are clearly articulated and map well to the should-not-invoke prompts. The one area of genuine ambiguity — tp-07, where someone wants help framing a conversation with a difficult sponsor — is correctly acknowledged in A2 as a separate problem. The skill does not overreach into stakeholder navigation, which keeps the invocation boundary clean.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                   | Result | Notes                                                                                                                                          |
| ----- | ------------------------------------------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-01 | 5 periods negative SV, PM says recoverable, no improvement, sponsor accepting                    | PASS   | Stable-negative trend; corrective pathway blocked at failure-narrative and sponsor-authority; SKILL.md Step 3 and Step 5 directly address this |
| tp-02 | Post-mortem: worsening SV from week 8, every report said "recovery plan," finished 6 months late | PASS   | Worsening trend retrospective; broken feedback loop diagnosis; Step 5 output format matches expected behavior                                  |
| tp-03 | Negative SV but gap narrowing each week — should I worry?                                        | PASS   | Improving trend classification; feedback loop is functioning; Step 2 and Step 4 handle this clearly                                            |
| tp-04 | Portfolio review: three programs, all flat negative SV, all have recovery plans                  | PASS   | Portfolio-wide stable-negative pattern; systemic corrective pathway diagnosis; A2 bullet 2 specifically covers PMO portfolio scenario          |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                                            | Result | Notes                                                                                                           |
| ----- | ------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------- |
| tp-05 | Sprint velocity declining for 6 weeks, defect load issue                  | PASS   | B section explicitly excludes Agile/sprint contexts; description requires EVM Schedule Variance                 |
| tp-06 | No performance baseline yet, 8 weeks in, just getting WBS baselined       | PASS   | B section requires EVM baseline; without it there is no SV to trend; skill correctly excludes                   |
| tp-07 | SV is negative, how do I frame this conversation with a difficult sponsor | PASS   | B section and A2 explicitly note stakeholder navigation is a separate skill; expected behavior correctly defers |

### Blurred_boundary

| ID    | Prompt summary                                                                      | Result | Notes                                                                                                                                 |
| ----- | ----------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| tp-08 | Week 4 of 52-week program, SV already negative, sponsor asking if there's a problem | PASS   | B section covers "not reliable in first 15% of timeline"; skill invokes with qualification and recommends monitoring cadence          |
| tp-09 | SV worsening, pathway blocked at sponsor level — what now?                          | PASS   | Diagnostic is complete; skill correctly names its own boundary and defers to stakeholder influence skill                              |
| tp-10 | 6 weeks of inconsistent SV data due to EVM tool migration                           | PASS   | Data quality check before trend classification is the correct response; Step 1 requires a reliable series; skill surfaces the problem |

## Issues Found

None. The SKILL.md's B section maps cleanly onto every should-not-invoke case. The three blurred-boundary prompts all have clearly articulable handling logic in the SKILL.md (15% startup zone, explicit boundary on pathway navigation, data quality requirement). No gaps identified.

## Verdict

PASS — The skill's description and A2 trigger conditions are specific enough to fire reliably on the right prompts, the B section correctly excludes all decoys, and the Execution section addresses the full range of should_invoke scenarios including improving trends (not just deteriorating ones).
