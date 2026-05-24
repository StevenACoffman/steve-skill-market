# Test Results: Grain-Decision-Four-Questions

**Total cases**: 7
**Passed**: 7
**Pass rate**: 100%
**Status**: ACCEPT

## Case-by-Case Results

| ID                    | Type               | Verdict | Notes                                                                                                                                                                                                                                                                                                                            |
| --------------------- | ------------------ | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| should-trigger-01     | should_trigger     | PASS    | "What level of detail we actually need" + "not sure" + new dataset design maps cleanly to A2 scenario 1 and language signal "what should one row represent?"                                                                                                                                                                     |
| should-trigger-02     | should_trigger     | PASS    | Stakeholder conflict between raw events and daily summaries with storage as the objection is A2 scenario 3 verbatim. Q2-beats-Q3 tie-breaking rule is the resolution path.                                                                                                                                                       |
| should-trigger-03     | should_trigger     | PASS    | Analytical question that cannot be answered from pre-aggregated data is A2 scenario 4. "Monthly revenue totals" when rep-level attribution is needed is the coarser-grain-than-question failure.                                                                                                                                 |
| should-trigger-04     | should_trigger     | PASS    | "What should one row in the feature table represent?" is a direct A2 language signal. Cross-form grain alignment for ML feature stores is A2 scenario 5.                                                                                                                                                                         |
| should-trigger-05     | should_trigger     | PASS    | Row multiplication on join ("3x the customers") is the fan-out warning sign and A2 language signal "the numbers double when I do this join." Maps to A2 scenario 2 (grain conflict during integration).                                                                                                                          |
| should-not-trigger-01 | should_not_trigger | PASS    | User explicitly declares the grain ("order-line grain, one row per product per order") and asks only about aggregation design. B section and A2 distinguishing notes redirect this to aggregation-workflow-four-steps. The phrase "I know the grain" is a strong exclusion signal.                                               |
| should-not-trigger-02 | should_not_trigger | PASS    | Declared grain (user_id + date), pre-deployment context, and explicit request for "sanity check" / "no duplicate primary keys" / "late-arriving data" all point to grain-audit-checklist. B section explicitly names this redirect: "if grain is already known and the question is about validation, use grain-audit-checklist." |

## Edge Case Reasoning

| ID           | Type      | Verdict            | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------------ | --------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| edge-case-01 | edge_case | INVOKE with caveat | The question "is the current grain fine?" is asking whether the grain design choice (header vs. line) is correct — a grain decision question, not a validation question. Grain-decision-four-questions should trigger. However the B section says the four questions won't help if the system is already in production (the source data that would require a finer grain may be gone). The prompt says "not sure it's worth the refactor" implying production, which introduces the caveat: if in production, Q4 must consider whether source data for line-item grain still exists. Invoke the skill with a production-constraint note. |

## Failure Analysis

No failures. All binary cases (should_trigger and should_not_trigger) passed.

**Decoy strength assessment:**

- `should-not-trigger-01` is a strong decoy: the word "grain" appears and the domain is the same (order modeling), but the stated grain and aggregation-only framing clearly redirect to aggregation-workflow-four-steps. No false-trigger risk.
- `should-not-trigger-02` is a strong decoy: pre-deployment + declared grain + validation language directly matches grain-audit-checklist description. The only risk would be if a naive trigger on "grain" alone fires; the A2 distinguishing section and B section both explicitly name this redirect.

**A2 coverage:**
All five A2 trigger scenarios are represented (scenarios 1–5 across the five should_trigger cases). All six A2 language signals are covered or paraphrased across the test cases.
