# Test Results — Ddd-Fitness-Scorecard

## Verdict: PASS

### Should_invoke

| #   | Prompt Summary                                                                                    | Result | Notes                                                                                                                                                                                                                                    |
| --- | ------------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | 6-person startup, 18 stories, novel insurance underwriting domain — adopt DDD?                    | PASS   | A2 names this exact scenario. E walks through all five criteria; "novel domain" is flagged as decisive even with low story count. Non-generic output.                                                                                    |
| 2   | E-commerce platform with 120 stories, multi-tenant pricing, loyalty, subscriptions — justify DDD? | PASS   | E scores each criterion against the described system; score clearly exceeds threshold. "Document the score" step and stakeholder commitment requirement are distinctive.                                                                 |
| 3   | Engineering manager says 25-story admin dashboard is "just CRUD" — evaluate objectively?          | PASS   | E's facilitation framing (run scorecard together, not as engineering veto) is precisely what tp-03 expected. The skill correctly acknowledges the objection may be right if the score comes back low. Decision logic is input-dependent. |

### Should_not_invoke

| #   | Prompt Summary                                               | Result | Notes                                                                                                                        |
| --- | ------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------- |
| 4   | What is the difference between an entity and a value object? | PASS   | No scorecard trigger. Description restricts skill to "whether to adopt DDD" decisions. This is a tactical modeling question. |
| 5   | How do I structure Go packages in a microservice?            | PASS   | No scorecard trigger. Go project layout question does not match A2 or description triggers.                                  |

### Blurred_boundary

| #   | Prompt Summary                                                                      | Result | Notes                                                                                                                                                                                                                                                     |
| --- | ----------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6   | Complex crypto exchange domain (80+ stories) but no DDD experience, 6-week deadline | PASS   | B explicitly names team maturity as a scorecard limitation. The skill applies with the correct qualification: score likely clears threshold, but recommend strategic patterns only (ubiquitous language, bounded contexts) before full tactical adoption. |
| 7   | Score of 6 but hard event-sourcing compliance requirement                           | PASS   | B explicitly documents "cost of being wrong on irreversible architectural choices" as a scorecard blind spot. Skill applies with the correct caveat: event sourcing complexity is not captured by the score and warrants a supplemental analysis.         |

## Issues Found

None. The E section produces input-sensitive output (the five-criterion table scores differently for different described systems). The B section covers both blurred-boundary scenarios explicitly. Decoy prompts are cleanly excluded by the skill's narrow triggering description.

## Rework Required

None.
