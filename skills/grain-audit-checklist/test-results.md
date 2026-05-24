# Test Results: Grain-Audit-Checklist

**Total cases**: 7
**Passed**: 7
**Pass rate**: 100%
**Status**: ACCEPT

## Case-by-Case Results

| ID                    | Type               | Verdict | Notes                                                                                                                                                                                                                                                                                                                                                                  |
| --------------------- | ------------------ | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| should-trigger-01     | should_trigger     | PASS    | "About to go live" + declared grain + "what checks should we run" is the canonical pre-deployment trigger. Matches description signal "We're about to deploy this table — how do we verify the grain is right?"                                                                                                                                                        |
| should-trigger-02     | should_trigger     | PASS    | User has already run Check 1 and found a COUNT vs COUNT DISTINCT mismatch. Pre-deployment context is stated. Matches A2 language signal "How do I verify the PK is actually unique?" and the Check 1 failure pattern described in A2.                                                                                                                                  |
| should-trigger-03     | should_trigger     | PASS    | Late-arriving data concern before deployment is the exact Check 3 scenario. Matches A2 language signal "What happens if data arrives late for this table?" and the A2 trigger narrative about a daily_active_sessions table.                                                                                                                                           |
| should-trigger-04     | should_trigger     | PASS    | Stated grain, pre-handoff framing, and explicit requests for duplicate check, null check, and documentation verification cover Checks 1, 2, and 4. Matches "I designed the grain as one row per X, but I want to double-check before shipping."                                                                                                                        |
| should-not-trigger-01 | should_not_trigger | PASS    | "We don't have a grain defined yet" and "starting the design from scratch" explicitly exclude this skill — B section requires a declared grain as input. Redirects to grain-decision-four-questions. The decoy danger is that "analytics events table" and grain vocabulary might trigger the skill; the explicit "no grain defined" phrase prevents this.             |
| should-not-trigger-02 | should_not_trigger | PASS    | Table has been in production for six months with downstream consumers. B section explicitly: "The table is already in production with downstream consumers — the audit can identify that the grain is wrong, but it cannot fix it." The user wants a fix, not a checklist. The correct response is that fixing requires a grain redesign project from raw source data. |

## Edge Case Reasoning

| ID           | Type      | Verdict            | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------------ | --------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| edge-case-01 | edge_case | INVOKE with caveat | The A2 language signal "something looks off with the row counts after the join" is a direct match for this skill. A view complicates the production/pre-deployment boundary: a view is a query definition, not a materialized deployment in the same sense as a table. Running Check 1 (COUNT vs COUNT DISTINCT on the view result) is still a valid diagnostic action even in production — it identifies the fan-out without "fixing" anything. Invoke grain-audit-checklist diagnostically, while noting: (a) if the underlying tables are in production, fixing the grain requires a redesign, not a checklist pass; (b) the checklist here serves as diagnosis, not gate. Partial invocation is appropriate. |

## Failure Analysis

No failures. All binary cases passed.

**Decoy strength assessment:**

- `should-not-trigger-01` is a strong decoy: the question involves a table type (analytics events) that appears throughout grain-audit-checklist examples. The explicit "no grain defined yet" phrase is the key exclusion signal. Risk of false trigger is low if the skill description is read carefully.
- `should-not-trigger-02` is the strongest decoy: it uses COUNT vs COUNT DISTINCT language (Check 1 syntax), which is grain-audit-checklist vocabulary. The critical differentiator is "been in production for six months" — the audit is a pre-deployment gate, not a production repair tool. If a model triggers on the COUNT check language alone without reading the production-context signal, this would be a false trigger. The B section language is explicit and should prevent this.

**Check coverage:**

- Check 1 (uniqueness): should-trigger-02, should-trigger-04, edge-case-01
- Check 2 (NULLs): should-trigger-04
- Check 3 (late-arriving data): should-trigger-03
- Check 4 (documentation): should-trigger-04
- Check 5 (use-case coverage): should-trigger-01 (implied by the full checklist invocation)
  All five checks are covered across the trigger cases.
