# Test Results: Fowler-Two-Hats

**Date**: 2026-05-05
**Total test cases**: 13
**Pass**: 13
**Fail**: 0
**Pass rate**: 100%
**Status**: PASS

## Results by Case

| ID                    | Type               | Result | Notes                                                                                                                                                                                                                                               |
| --------------------- | ------------------ | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| should-trigger-01     | should_trigger     | PASS   | Core hat-mixing violation with test-attribution failure. Matches A2 Scenario 1 and language signals exactly.                                                                                                                                        |
| should-trigger-02     | should_trigger     | PASS   | PR-level hat violation. Matches A2 Scenario 5 (mixed diffs in code review).                                                                                                                                                                         |
| should-trigger-03     | should_trigger     | PASS   | Moment-of-decision scenario. Matches E section Stop Condition and A2 Scenario 2.                                                                                                                                                                    |
| should-trigger-04     | should_trigger     | PASS   | "While I'm at it" rationalization during refactoring. Matches A2 Scenario 2 (adding behavior mid-refactoring).                                                                                                                                      |
| should-trigger-05     | should_trigger     | PASS   | Direct knowledge question. Covered by R section and frontmatter trigger description.                                                                                                                                                                |
| should-trigger-06     | should_trigger     | PASS   | Nuanced exception (untested case discovery). Explicitly handled in R section and A2 language signals.                                                                                                                                               |
| should-trigger-07     | should_trigger     | PASS   | "Clean up later" culture pattern. Skill correctly applies: continuous hat-swapping eliminates the need for scheduled cleanup. Covered by I section and E section.                                                                                   |
| should-not-trigger-01 | should_not_trigger | PASS   | 200-site library migration. B boundary section explicitly excludes multi-system week-scale migrations; frontmatter routes to fowler-branch-by-abstraction. No risk of false activation.                                                             |
| should-not-trigger-02 | should_not_trigger | PASS   | Stakeholder justification for refactoring. Trigger description requires active mode-mixing; this prompt is about organizational argument. No trigger signal present.                                                                                |
| should-not-trigger-03 | should_not_trigger | PASS   | Preparatory refactoring decision. Frontmatter excludes "deciding whether to refactor at all." Primary skill is opportunistic-refactoring; boundary is correctly drawn. Marginal case but discrimination is valid.                                   |
| should-not-trigger-04 | should_not_trigger | PASS   | Code review vocabulary. No mode-mixing signal present. Belongs to fowler-code-smells.                                                                                                                                                               |
| edge-01               | edge_case          | PASS   | TDD refactor phase + conceptually wrong interface. Clear judgment: fixing a wrong interface requires new behavior (new tests), which is functionality hat. TDD refactor step has same constraint as refactoring hat. I and E sections support this. |
| edge-02               | edge_case          | PASS   | Bug discovered mid-refactoring. Clear judgment: behavioral change (bug fix) not allowed during refactoring hat. Two valid options given in expected behavior, both coherent and covered by E section stop conditions and R section exception rules. |
| edge-03               | edge_case          | PASS   | 3-second IDE rename — discipline still applies. I section ("Awareness is the operative word") and E section make clear discipline scales to any size refactoring step.                                                                              |

## Failures and Reworks

None. All 13 test cases passed without requiring changes to SKILL.md or test-prompts.json.

## Verdict

PASS — The skill boundary is well-calibrated across all three dimensions: (1) trigger cases are clearly covered by A2 scenarios and language signals; (2) non-trigger cases are clearly excluded by frontmatter Do-Not-Invoke rules and B boundary section; (3) edge cases have coherent, well-supported judgments grounded in R and E sections. The most demanding discrimination (should-not-trigger-03, preparatory refactoring vs. Two Hats execution) is correctly handled by the "deciding whether to refactor" exclusion in the frontmatter. No rework required.
