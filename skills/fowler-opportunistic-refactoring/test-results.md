# Test Results: Fowler-Opportunistic-Refactoring

**Date**: 2026-05-05
**Total test cases**: 14
**Pass**: 14
**Fail**: 0
**Pass rate**: 100%
**Status**: PASS

## Results by Case

| ID     | Type               | Result | Notes                                                                                                                                      |
| ------ | ------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| ST-01  | should_trigger     | PASS   | Preparatory mode: code mixes concerns before adding pagination — reshape first                                                             |
| ST-02  | should_trigger     | PASS   | Comprehension mode: 20 minutes reading → externalize understanding into code now                                                           |
| ST-03  | should_trigger     | PASS   | Litter-pickup: duplicate validation at three call sites noticed while fixing bug                                                           |
| ST-04  | should_trigger     | PASS   | Long-term mode: structural mess can't be frozen — Branch By Abstraction applies                                                            |
| ST-05  | should_trigger     | PASS   | Preparatory mode: hardcoded discount logic in 5 places → consolidate before adding new type                                                |
| ST-06  | should_trigger     | PASS   | Planned-vs-opportunistic: execute sprint but establish opportunistic habits to prevent recurrence                                          |
| ST-07  | should_trigger     | PASS   | Comprehension mode during code review: rename/extract instead of adding comments                                                           |
| ST-08  | should_trigger     | PASS   | Litter-pickup with size triage: 3 hours = note and defer, not derail current task                                                          |
| SNT-01 | should_not_trigger | PASS   | Extract Function technique question — catalog skill, not when-to-refactor mode selection                                                   |
| SNT-02 | should_not_trigger | PASS   | Stakeholder justification question — fowler-design-stamina, not this skill                                                                 |
| SNT-03 | should_not_trigger | PASS   | Code smell identification — fowler-code-smells diagnostic vocabulary, not this skill                                                       |
| EC-01  | edge_case          | PASS   | Comprehension mode triggered but Boundary constraint fires: no tests → unsafe; advise tests first                                          |
| EC-02  | edge_case          | PASS   | Preparatory mode mid-feature is valid; Two Hats discipline governs execution — stop, commit, switch hats, refactor, run tests, switch back |
| EC-03  | edge_case          | PASS   | Litter-pickup triggered but security risk adds a non-size triage dimension; escalate rather than defer with a note                         |

## Failures and Reworks

None. All 14 test cases passed without modification to SKILL.md or test-prompts.json.

## Verdict

PASS
