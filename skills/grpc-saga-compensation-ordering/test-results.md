# Test Results — Grpc-Saga-Compensation-Ordering

## Verdict: PASS (10/10)

## Should_invoke

| ID   | Prompt (summary)                                                  | Result | Notes                                                                                                      |
| ---- | ----------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| tp01 | Compensation ordering when shipping fails in 3-step saga          | PASS   | I section states bottom-up rule precisely: Shipping failure → refund payment → cancel order                |
| tp02 | Why must compensating transactions be idempotent?                 | PASS   | I section explains retries due to network failures / orchestrator restarts; applies-twice-same-effect rule |
| tp03 | Choreography vs orchestration trade-offs for checkout flow        | PASS   | I section covers both variants with explicit pros/cons; A1 references the e-commerce example               |
| tp04 | Sequential calls with no compensation — charged-but-never-shipped | PASS   | A2 trigger 1 exact match; I section covers compensation design for partial failure                         |

## Should_not_invoke

| ID   | Prompt (summary)                              | Result | Notes                                                                                                           |
| ---- | --------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------- |
| tp05 | Kafka publish/consume implementation in Go    | PASS   | Kafka infrastructure details; A2 triggers are about compensation ordering and choreography/orchestration choice |
| tp06 | 2PC vs eventual consistency                   | PASS   | B section references 2PC as out-of-scope alternative; not the core of this skill                                |
| tp07 | Go state machine for order status transitions | PASS   | E step 2 mentions saga state machine but generic state machine implementation is not the trigger                |

## Blurred_boundary

| ID   | Prompt (summary)                                                            | Result | Notes                                                                                                                                     |
| ---- | --------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| tp08 | Saga orchestrator crash — how to resume compensation from where it left off | PASS   | E step 2 identifies need to persist state; skill correctly acknowledges the requirement without over-specifying the persistence mechanism |
| tp09 | Choreography saga with lost payment_failed event                            | PASS   | B section notes correlation IDs needed; event reliability and reconciliation are acknowledged as natural follow-ons beyond scope          |
| tp10 | Adding 4th step to 3-step saga — redesign compensation sequence?            | PASS   | Bottom-up rule applies directly; skill correctly answers the core question while Related Skills pointer handles schema evolution angle    |
