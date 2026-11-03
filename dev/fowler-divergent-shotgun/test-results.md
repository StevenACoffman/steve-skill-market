# Test Results: Fowler-Divergent-Shotgun

**Date**: 2026-05-05
**Total test cases**: 12
**Pass**: 12
**Fail**: 0
**Pass rate**: 100%
**Status**: PASS

## Results by Case

| ID                                     | Type              | Result | Notes                                                                                                                                                                                                                                                                                                    |
| -------------------------------------- | ----------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| fowler-divergent-shotgun-should-01     | should_invoke     | PASS   | Canonical dual-diagnosis: Divergent Change (OrderService, two axes) + Shotgun Surgery (PaymentService, three modules). Skill directly answers "no, these are inverse problems."                                                                                                                          |
| fowler-divergent-shotgun-should-02     | should_invoke     | PASS   | Classic Shotgun Surgery: one logical change (new payment method) scattered across five classes, causing consistent underestimation.                                                                                                                                                                      |
| fowler-divergent-shotgun-should-03     | should_invoke     | PASS   | Divergent Change caught in PR review: one class modified for two unrelated reasons (auth provider change + billing plan update).                                                                                                                                                                         |
| fowler-divergent-shotgun-should-04     | should_invoke     | PASS   | Shotgun Surgery onboarding signal: discount calculation in four places with diverging logic. Maps to A2 Scenario 4 verbatim.                                                                                                                                                                             |
| fowler-divergent-shotgun-should-05     | should_invoke     | PASS   | Divergent Change at service granularity: two independent axes (data warehouse schema vs. report domain) at different frequencies. Covered in A2 Scenario 3.                                                                                                                                              |
| fowler-divergent-shotgun-should-06     | should_invoke     | PASS   | Shotgun Surgery checklist signal: 18-month-old "did you remember to update X?" item. Maps to A2 language signal "I forgot to update the [file] again."                                                                                                                                                   |
| fowler-divergent-shotgun-should-not-01 | should_not_invoke | PASS   | Pure Long Function smell (200 lines, nested conditionals, readability). No change-axis language. SKILL.md explicitly excludes long function questions.                                                                                                                                                   |
| fowler-divergent-shotgun-should-not-02 | should_not_invoke | PASS   | Two Hats problem (mixed refactoring and feature work, tests failing). No structural smell diagnosis needed. SKILL.md explicitly excludes two-hats scenarios.                                                                                                                                             |
| fowler-divergent-shotgun-should-not-03 | should_not_invoke | PASS   | Full smell catalog survey requested. SKILL.md explicitly excludes broad smell surveys; fowler-code-smells is the correct skill.                                                                                                                                                                          |
| fowler-divergent-shotgun-boundary-01   | boundary          | PASS   | Service with business + infrastructure change axes. Skill invokes and applies the key test: are the axes independently varying? If they always move together, it is intentional layering, not Divergent Change.                                                                                          |
| fowler-divergent-shotgun-boundary-02   | boundary          | PASS   | HttpHandler with three change axes (endpoints, validation, serialization). Textbook Divergent Change, but skill applies the "intentional orchestrator?" boundary check before recommending a split.                                                                                                      |
| fowler-divergent-shotgun-boundary-03   | boundary          | PASS   | Strategy pattern (Factory + Registry + interface updated per new strategy) superficially resembles Shotgun Surgery. Skill invokes because the user is asking whether it is the smell — and the B section directly resolves it: intentional pattern structure is not the smell; accidental scattering is. |

## Failures and Reworks

None.

## Verdict

PASS
