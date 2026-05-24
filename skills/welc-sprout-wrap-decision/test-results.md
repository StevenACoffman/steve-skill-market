# Test Results: Welc-Sprout-Wrap-Decision

## Summary

- Total prompts: 10
- PASS: 8
- FAIL: 2
- Reworks performed: 2

## Results

| ID   | Category          | Verdict | Notes                                                                                                                                                                                                                                                                     |
| ---- | ----------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp01 | should_invoke     | PASS    | Subordinate logging addition to untestable method maps directly to Sprout Method via Step 2 left branch. All expected concepts covered.                                                                                                                                   |
| tp02 | should_invoke     | PASS    | Class requiring heavyweight deps to construct maps directly to Sprout Class escalation via Step 1 NO branch. All expected concepts covered.                                                                                                                               |
| tp03 | should_invoke     | PASS    | Cross-cutting behavior on third-party class applying to all callers maps directly to Wrap Class via Step 1 NO branch. All expected concepts covered.                                                                                                                      |
| tp04 | should_invoke     | PASS    | Co-equal notification on instantiable class maps to Wrap Method via Step 2 NO branch. All expected concepts covered.                                                                                                                                                      |
| tp05 | should_not_invoke | PASS    | Boundary section explicitly restricts scope to untestable code; refactoring well-tested code falls outside the skill. Skill would correctly stay out of the way.                                                                                                          |
| tp06 | should_not_invoke | PASS    | Boundary section explicitly distinguishes GoF Decorator (deliberate design choice) from Wrap Class (safety intervention); skill would not misfires on greenfield design questions.                                                                                        |
| tp07 | should_not_invoke | PASS    | Related Skills section redirects characterization testing to welc-characterization-test; these are contrasting safety strategies. Skill stays out.                                                                                                                        |
| tp08 | blurred_boundary  | PASS    | "Cumulative avoidance" counter-example and "bridges not destinations" warning in both Interpretation and Boundary sections directly address this. Skill gives clear guidance.                                                                                             |
| tp09 | blurred_boundary  | FAIL    | Behavior is subordinate AND must reach all callers via interface. Step 2 only asked subordinate vs co-equal — "applies to all callers" had no branch when class is instantiable. Skill would route to Sprout Method, missing callers who bypass the sprouted-into method. |
| tp10 | blurred_boundary  | FAIL    | Step 1 posed "can instantiate" as binary. Technically-possible-but-prohibitively-costly instantiation (5 fakes, 2 in-memory DBs, stubbed network) had no guidance. Practical threshold not addressed.                                                                     |

## Reworks

### Rework 1 — Tp09: Subordinate-but-Universal Tiebreaker (Step 2)

**Gap:** Step 2 only asked "subordinate or co-equal?" and routed to Sprout Method if subordinate. It did not ask whether the new behavior must reach all callers. Sprout Method can miss callers who invoke the class through a different method or bypass the sprouted-into entry point.

**Fix:** Step 2 now has a nested decision: if subordinate, ask "does it need to reach ALL callers via the interface?" If no, Sprout Method. If yes, Wrap Class — with an explicit note that Sprout Method would miss callers that do not go through the sprouted-into method.

### Rework 2 — Tp10: Practical Threshold for "Cannot Instantiate" (Step 1)

**Gap:** Step 1 asked "Can you instantiate the class in a test harness?" as a binary YES/NO. When instantiation is technically possible but requires five fakes, in-memory databases, and stubbed external services, the skill gave no guidance. The goal is testable new behavior, not theoretical testability.

**Fix:** Step 1 now includes the qualifying clause "at a cost you will actually pay" and adds a parenthetical rule: treat instantiation as "NO" (use the class-level technique) if the setup is so expensive you will not write the tests in practice — with a concrete example of what "too expensive" looks like.
