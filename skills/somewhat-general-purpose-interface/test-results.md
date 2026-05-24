# Test Results — Somewhat General-Purpose Interface

## Overall: PASS (10/10 Prompts Correct)

| ID   | Category          | Prompt (abbreviated)                                                                                                      | Result | Notes                                                                                                                                                                 |
| ---- | ----------------- | ------------------------------------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp01 | should_invoke     | Text editor has `deleteSelectedText()`, `backspaceCharacter()`, `deleteWordForward()`; colleague suggests `delete(range)` | PASS   | Ousterhout's exact example from A1 Case 1; SKILL provides direct authoritative guidance                                                                               |
| tp02 | should_invoke     | Search API: `searchByName()`, `searchByEmail()`, `searchByPhone()` vs. `search(criteria)`                                 | PASS   | Interface growing by accretion per use case; trigger fires ("API is growing by accretion"); three-question test applies                                               |
| tp03 | should_invoke     | Method named `saveUserProfileChanges()`, called from only one place                                                       | PASS   | Trigger fires explicitly: "a method's name includes a UI action or user operation" and "a method is called in exactly one place"                                      |
| tp04 | should_invoke     | `renderDashboardWidget()` growing with new types; generalize now or wait for three examples?                              | PASS   | YAGNI-vs-generality tension; SKILL explicitly addresses "when generality also makes the interface simpler, YAGNI is the wrong frame"                                  |
| tp05 | should_not_invoke | Sorting algorithm needs to work for integers, strings, dates — how to make comparator generic                             | PASS   | Type parameter / implementation generics question, not API interface design philosophy; SKILL scoped to interface contract, not type system usage                     |
| tp06 | should_not_invoke | Duplicate line-item total logic in `InvoiceService` and `QuoteService` — DRY?                                             | PASS   | DRY/implementation deduplication; not about interface generality level                                                                                                |
| tp07 | should_not_invoke | Extracted helper method used in three places — should it be in the public API?                                            | PASS   | Visibility/export decision; SKILL handles interface design, not access control decisions                                                                              |
| tp08 | boundary          | SDK for third-party developers with unknown use cases — general or specific methods?                                      | PASS   | SKILL's B section boundary 3 explicitly addresses "when the caller set is open — no current needs to anchor the test"; SKILL provides honest scoping of its limits    |
| tp09 | boundary          | `exportReport()` with `format` parameter vs. separate `exportAsPdf()`, `exportAsCsv()`, `exportAsExcel()`                 | PASS   | Parameter-vs-multiple-methods is the three-question test applied directly; SKILL handles it; boundary noted since implementation divergence matters                   |
| tp10 | boundary          | Plugin hooks: fine-grained (one per event type) vs. coarse-grained (one generic hook with event object)                   | PASS   | SKILL applies the three-question test; B section boundary 3 (unknown caller set, versioning concerns) applies; skill provides useful framing with appropriate caveats |

## Issues Found

None. All 10 prompts correctly handled.

A notable strength: tp08 (SDK design for unknown callers) is the hardest boundary case. The SKILL's B section boundary 3 directly addresses this and honestly states the limitation — the three-question test requires known callers to anchor Q1. This is a self-aware boundary, not a gap.

The three should_not_invoke cases are cleanly separated: tp05 is about type system generics (implementation concern, not interface philosophy), tp06 is about DRY (implementation deduplication), and tp07 is about visibility/export decisions.

## Verdict

PASS — skill is well-scoped and handles all test cases correctly. The three-question test provides a concrete procedure that differentiates the hard boundary cases from the clear invocations, and the boundary section honestly acknowledges where the test's preconditions don't hold.
