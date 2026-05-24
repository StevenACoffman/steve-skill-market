# Test Results — Define Errors Out of Existence

## Overall: PASS (10/10 Prompts Correct)

| ID   | Category          | Prompt (abbreviated)                                                                           | Result | Notes                                                                                                                                             |
| ---- | ----------------- | ---------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp01 | should_invoke     | File-deletion throws if file doesn't exist; every caller wraps in try/catch                    | PASS   | Tcl `unset` parallel is exact; SKILL covers this in A1 case 1 and the trigger                                                                     |
| tp02 | should_invoke     | `getUser` throws `UserNotFoundException`; every caller falls back to default                   | PASS   | Trigger explicitly names "boolean flag or nullable return" pattern; postcondition redesign applies                                                |
| tp03 | should_invoke     | `unsubscribe` throws 400 if email not subscribed; product wants idempotent calls               | PASS   | Idempotency = postcondition framing directly addressed in trigger and E step 2                                                                    |
| tp04 | should_invoke     | `Queue.pop()` — throw on empty vs. return sentinel debate                                      | PASS   | SKILL covers this: ask "does this error need to exist?" trigger fires on "adding throws X if Y clauses"                                           |
| tp05 | should_not_invoke | Error log formatting — stack trace vs. human-readable                                          | PASS   | SKILL scoped to error existence/contract design, not error message formatting; correctly does not apply                                           |
| tp06 | should_not_invoke | How to structure unit tests to verify error paths                                              | PASS   | Testing strategy for existing paths; SKILL does not address testing methodology                                                                   |
| tp07 | should_not_invoke | Catching exceptions earlier to improve API performance                                         | PASS   | Performance question; SKILL boundary section confirms "catching exceptions earlier" is not its domain                                             |
| tp08 | boundary          | Propagate IOException up to controller or handle in service layer with result type             | PASS   | SKILL handles this: "result type" option is postcondition redesign; boundary is acknowledged in E step 3 (only surface errors callers can act on) |
| tp09 | boundary          | Distributed transaction failing at step 3; compensating transactions vs. leaving partial state | PASS   | SKILL covers NFS masking case (A1 case 4) and boundary note on masking; correctly engages with partial answers                                    |
| tp10 | boundary          | `ValidationException` vs. result object with error list from `validate()`                      | PASS   | SKILL covers this: returning a result object is the "define the error out of existence as a normal return path"; boundary acknowledged            |

## Issues Found

None. All 10 prompts are correctly handled.

- The four should_invoke prompts map cleanly to the trigger conditions and execution steps.
- The three should_not_invoke prompts (tp05, tp06, tp07) are cleanly outside the SKILL's stated scope — error message formatting, testing strategy, and performance are all excluded by the framing of the SKILL, which is specifically about contract redesign.
- The three boundary prompts all receive genuine engagement from the SKILL: tp08 is addressed by the "only surface errors callers can act on" execution heuristic, tp09 by the NFS masking case and the B-section warning about masking hiding bugs, and tp10 by the postcondition-as-normal-return-path framing.

## Verdict

PASS — skill is well-scoped and handles all test cases correctly. The trigger conditions are precise enough to distinguish error-contract design questions from testing, logging, and performance questions. The boundary section provides the nuance needed for the harder cases.
