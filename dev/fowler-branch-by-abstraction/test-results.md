# Test Results: Fowler-Branch-by-Abstraction

**Date**: 2026-05-05
**Total test cases**: 12
**Pass**: 12
**Fail**: 0
**Pass rate**: 100%
**Status**: PASS

## Results by Case

| ID   | Type               | Result | Notes                                                                                                                                                                                                                                                                                                                                                                      |
| ---- | ------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp01 | should_trigger     | PASS   | Canonical BBA trigger: 200 call sites, live production, no feature freeze. Four phases apply directly.                                                                                                                                                                                                                                                                     |
| tp02 | should_trigger     | PASS   | 80 packages, multi-PR migration. Matches Scenario 2 (logging framework) in A2 verbatim.                                                                                                                                                                                                                                                                                    |
| tp03 | should_trigger     | PASS   | 60 route handlers, no freeze. Matches Scenario 5 (framework migration). `must_not_include: big-bang` correctly captures BBA as the explicit alternative.                                                                                                                                                                                                                   |
| tp04 | should_trigger     | PASS   | Matches Fowler's original language ("gradually work on it over weeks / whoever touches the zone"). Abstraction layer enables incremental progress without a dedicated sprint.                                                                                                                                                                                              |
| tp05 | should_trigger     | PASS   | Shared-component extraction. Matches Scenario 4. Interface-first → migrate 30 call sites → move implementation to shared library.                                                                                                                                                                                                                                          |
| tp06 | should_trigger     | PASS   | gRPC client wrapper (code-level, not service boundary). Interface-first enables parallel PRs without merge conflicts. Build stays green throughout.                                                                                                                                                                                                                        |
| tp07 | should_not_trigger | PASS   | Git branch naming question. BBA is explicitly an alternative to long-lived refactoring branches — not a recommendation for them. No BBA invocation appropriate.                                                                                                                                                                                                            |
| tp08 | should_not_trigger | PASS   | 15-site rename fits in a single commit. Boundary section prohibits BBA for single-commit refactors. IDE rename or Change Function Declaration is correct.                                                                                                                                                                                                                  |
| tp09 | should_not_trigger | PASS   | External API consumers — callers are not code the team controls. Boundary section explicitly excludes this case. API versioning with deprecation window is correct.                                                                                                                                                                                                        |
| tp10 | edge_case          | PASS   | Dual-skill case. BBA handles the code side (repository interface + incremental caller migration + ORM swap); fowler-database-parallel-change handles the schema side. Both skills are required and complementary. This is code-level migration (BBA) plus data-level migration (parallel-change), not one or the other.                                                    |
| tp11 | edge_case          | PASS   | BBA applies to the code layer (PaymentProcessor interface, 40 call sites). The service boundary is a network boundary — the implementation swap involves production traffic to an external provider, not an in-process library swap. Additional patterns (traffic shadowing, rollback, monitoring) are required beyond BBA. Skill correctly scoped with the caveat.        |
| tp12 | edge_case          | PASS   | Stalled BBA migration (60% complete, six months stalled). Recognized as the known failure mode from the Failure Patterns section ("leaving phase 2 partially done"). Correct response: either recommit with CI-enforced tracking of remaining direct usages and complete the migration, or standardize on one approach rather than leaving the codebase permanently split. |

## Failures and Reworks

None. All 12 test cases passed on first evaluation. No changes were required to SKILL.md or test-prompts.json.

## Notes on Edge Case Judgment

**tp10 (ORM + schema)**: This is Branch By Abstraction (code) — the ORM call sites are code the team controls, and the 4-phase abstraction pattern applies cleanly. The schema migration is a parallel concern requiring fowler-database-parallel-change. The edge case is correctly specified as a dual-skill scenario, not a case of confusion between skills.

**tp11 (service boundary)**: BBA applies at the code layer (the interface and call-site migration are identical to the in-process case). The edge is the production traffic concern at the implementation-swap phase — not the abstraction introduction or caller migration phases. The skill correctly states its boundary in the B section ("the abstraction layer must also handle network failures, latency, serialization, and partial responses").

**tp06 vs tp11 disambiguation**: tp06 ("gRPC client wrapper library") is an in-process code concern — BBA applies cleanly. tp11 ("replace internal payment service with third-party") involves live production traffic to an external system — BBA applies to the code layer but requires additional network-level migration patterns. The distinction is correctly captured.

## Verdict

PASS
