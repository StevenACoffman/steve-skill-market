# Test Results — Design It Twice

## Overall: PASS (10/10 Prompts Correct)

| ID   | Category          | Prompt (abbreviated)                                                                                                 | Result | Notes                                                                                                                                                                                                 |
| ---- | ----------------- | -------------------------------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp01 | should_invoke     | "I've come up with an API design for our new payments module, pretty solid — should I just implement it?"            | PASS   | Single proposed design with no alternatives; trigger fires ("any significant interface decision"); E steps 1–2 (write Design A, generate Design B) apply directly                                     |
| tp02 | should_invoke     | Event bus interface feels clean, team wants to start building — reason to slow down?                                 | PASS   | Finalization pressure with one design on the table; trigger fires ("when a design review produces only minor refinements"); SKILL provides the reason and the procedure                               |
| tp03 | should_invoke     | "Here's my proposed class hierarchy for the reporting engine, I'm confident — can you review it?"                    | PASS   | Trigger fires: "when a senior developer says 'obviously we should do X'" / single frame in review; SKILL explicitly addresses confident expert resistance                                             |
| tp04 | should_invoke     | "Went from requirements to implementation; API feels clunky; teammates finding edge cases" — what to do differently? | PASS   | Retrospective on skipping design exploration; SKILL names this failure mode and prescribes the corrective                                                                                             |
| tp05 | should_not_invoke | Two caching strategies exist (LRU vs. TTL) — how to run an A/B test to pick the winner?                              | PASS   | A/B testing is runtime experiment methodology; two designs already exist, the generative phase is done; A/B test is not the SKILL's concern                                                           |
| tp06 | should_not_invoke | What should be on our code review checklist?                                                                         | PASS   | Code review process question; SKILL is about pre-implementation design exploration, not review process                                                                                                |
| tp07 | should_not_invoke | Should I build a prototype before committing to the architecture?                                                    | PASS   | Prototyping validates a single design; SKILL generates multiple candidates for comparison; prototyping is adjacent but distinct — correctly not invoked                                               |
| tp08 | boundary          | Stuck between generic `Repository<T>` and specific `UserRepository`, `OrderRepository` — how to pick?                | PASS   | Two alternatives already exist (generative phase done); SKILL's E step 3 (compare trade-offs per use case) is the right tool for the comparison phase; boundary correctly acknowledged                |
| tp09 | boundary          | UUID vs. auto-increment integer as primary key                                                                       | PASS   | Narrow implementation detail; B section states "design-it-twice is about interface contracts, not variable names, private function signatures, or minor internal refactors"; correctly does not apply |
| tp10 | boundary          | `timeout` vs. `timeoutMillis` for a parameter name                                                                   | PASS   | Minor naming decision; B section is explicit that the overhead is not justified for decisions that are easy to reverse and affect only one scope                                                      |

## Issues Found

None. All 10 prompts correctly handled.

A notable strength: tp07 (prototyping) is correctly excluded. The SKILL is precise that design-it-twice compares interface contracts before implementation — prototyping validates one design through implementation, which is a different activity. The boundary is correctly drawn.

The two narrow boundary prompts (tp09, tp10) are cleanly excluded by the B section's explicit scope statement: the skill applies to decisions that are hard to reverse and affect multiple callers over time. UUID vs. auto-increment and parameter naming do not clear that bar.

tp08 is the most interesting case: two alternatives already exist, so the generative phase is moot, but the comparison framework (E step 3) still applies. The SKILL handles this gracefully.

## Verdict

PASS — skill is well-scoped and handles all test cases correctly. The B section's explicit scope limitation ("interface contracts, not implementation details") makes the should_not_invoke boundary cases clean, and E step 3 (compare trade-offs per use case) provides useful guidance even when alternatives already exist.
