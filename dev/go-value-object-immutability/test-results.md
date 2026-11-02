# Test Results — Go-Value-Object-Immutability

## Verdict: PASS

### Should_invoke

| #   | Prompt Summary                                                                     | Result | Notes                                                                                                                                                                                                                         |
| --- | ---------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Should Money's Add method use pointer or value receiver?                           | PASS   | A2 names this exact anti-pattern. E step 3 specifies value receivers; I explains why pointer receivers contradict the value object contract. Non-generic, skill-specific answer.                                              |
| 2   | Two Color instances with same RGB not equal under == — what's wrong?               | PASS   | A2 names this exact failure mode (constructor returns `*Color`). E step 2 and I's value-type vs pointer-type equality explanation diagnose and fix it.                                                                        |
| 3   | Implement a DateRange value object — what should struct and constructor look like? | PASS   | E steps 1–4 produce a complete canonical implementation: unexported fields, NewDateRange returning DateRange (not `*DateRange`), value receiver methods. Output is highly specific and would not come from generic Go advice. |

### Should_not_invoke

| #   | Prompt Summary                                                | Result | Notes                                                                                                                                             |
| --- | ------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4   | How to implement optimistic locking for a database row in Go? | PASS   | B explicitly excludes infrastructure concerns. Optimistic locking is version-field/database CAS pattern; no value object design question present. |
| 5   | What's the difference between a Go interface and a struct?    | PASS   | Fundamental Go language question. No domain type classification or immutability design decision. Skill correctly defers.                          |

### Blurred_boundary

| #   | Prompt Summary                                                                       | Result | Notes                                                                                                                                                                                                                |
| --- | ------------------------------------------------------------------------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6   | json.Marshal won't include unexported fields — should I export Money's fields?       | PASS   | E step 6 explicitly prescribes a separate persistence/serialization model. B acknowledges the infrastructure adapter cost. Skill applies with the correct answer (do not export) and appropriate engineering caveat. |
| 7   | ProductCatalogEntry has 20 fields — okay to use pointer receiver to avoid copy cost? | PASS   | B explicitly names the performance trade-off for large value objects. Skill applies with nuance: benchmark first, pointer receivers defeat immutability semantics, flag as a trade-off rather than a default.        |

## Issues Found

None. E section is implementation-specific (Go syntax patterns, not general DDD advice). B section covers both blurred-boundary scenarios explicitly. Decoy prompts are clearly outside the skill's domain.

## Rework Required

None.
