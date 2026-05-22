# Test Results — Strong-Consistency-Across-Bounded-Contexts

## Verdict: PASS

### Should_invoke

| #   | Prompt Summary                                                                    | Result | Notes                                                                                                                                                                                                                           |
| --- | --------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Decrement inventory synchronously inside order transaction, or publish event?     | PASS   | A2 names this exact scenario. E steps 1–3 directly answer it: Order and Inventory are separate contexts; commit then publish. Clear, non-generic output.                                                                        |
| 2   | Two aggregate types updated in a single database transaction — is that a problem? | PASS   | I's diagnostic use of the rule is directly applicable. E step 2 says one aggregate per transaction; skill diagnoses whether to merge aggregates or decouple with events based on the invariant. Decision logic varies by input. |
| 3   | Payments service needs subscription tier — synchronous query or local projection? | PASS   | A2 names this exact scenario. E step 3 and I's "eventual consistency is architecturally preferable" reasoning produces a distinctive, DDD-grounded answer.                                                                      |

### Should_not_invoke

| #   | Prompt Summary                                                    | Result | Notes                                                                                                                      |
| --- | ----------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------- |
| 4   | How to implement a Kafka consumer in Go using confluent-kafka-go? | PASS   | Library-specific implementation question. No consistency boundary decision is being made. A2 and description do not match. |
| 5   | PostgreSQL vs MongoDB for a Go service?                           | PASS   | Database technology selection. No bounded context architecture decision. Skill correctly stays silent.                     |

### Blurred_boundary

| #   | Prompt Summary                                                                                              | Result | Notes                                                                                                                                                                                                                                            |
| --- | ----------------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 6   | Payment failure must cancel order "atomically" — does this require a distributed transaction?               | PASS   | E step 6 explicitly says to challenge the requirement with the domain expert. The skill applies with nuance: Saga/compensating transactions satisfy the business requirement without distributed atomicity. Outbox pattern gap is flagged per B. |
| 7   | Not sure if Inventory and Orders are separate bounded contexts — how does the consistency rule help decide? | PASS   | I explicitly calls out the diagnostic use: "if the business says that invariant must be atomic, they may belong in the same aggregate/context." The skill applies as a boundary diagnostic tool, which is precisely what tp-07 expects.          |

## Issues Found

None. The E section produces different answers depending on whether the interaction is within one context (synchronous aggregate method call) or across contexts (event after commit). Both blurred-boundary cases are addressed explicitly in either E or B. Decoy prompts are cleanly excluded.

## Rework Required

None.
