# Test Results — Entity-Vs-Value-Object-Decision

## Verdict: PASS

### Should_invoke

| #   | Prompt Summary                                       | Result | Notes                                                                                                                                                       |
| --- | ---------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | ShippingAddress vs Shipment: entity or value object? | PASS   | A2 explicitly names ShippingAddress; E walks through the three questions distinctly for each type, producing different implementations. Not generic advice. |
| 2   | Should Money have a UUID?                            | PASS   | Framework inverts the team's instinct with concrete reasoning; E step 1-3 answer definitively; A2 covers this exact pattern. Distinctive output.            |
| 3   | ProductVariant: value or identity?                   | PASS   | E's three-question sequence handles the "it depends on per-line refund tracking" nuance in tp-03 expected behavior; decision logic is input-dependent.      |

### Should_not_invoke

| #   | Prompt Summary                                | Result | Notes                                                                                             |
| --- | --------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------- |
| 4   | How to connect Go app to PostgreSQL with pgx? | PASS   | B explicitly excludes infrastructure concerns. No domain modeling vocabulary matches this prompt. |
| 5   | Goroutines vs channels for batch processing?  | PASS   | No trigger in A2 or description matches concurrency design. Skill correctly defers.               |

### Blurred_boundary

| #   | Prompt Summary                                                                 | Result | Notes                                                                                                                                                         |
| --- | ------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6   | Customer: value object in Orders, entity in CRM?                               | PASS   | B explicitly addresses per-context application. The skill handles this with the "same concept, different classification per context" nuance documented in B.  |
| 7   | GORM needs exported fields but Address passes all three value-object questions | PASS   | B explicitly names the ORM impedance mismatch as a known limitation. E step 6 prescribes a separate persistence model. Skill applies with appropriate caveat. |

## Issues Found

None. All three question categories produce appropriately differentiated output. The E section has clear decision logic (three questions with branching at each). The B section rules out infrastructure prompts cleanly and documents the ORM limitation and per-context caveat explicitly.

## Rework Required

None.
