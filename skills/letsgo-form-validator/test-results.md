# Test Results: Letsgo-Form-Validator

## Verdict: PASS

## Prompt-by-Prompt Evaluation

| ID        | Prompt (summary)                                                             | Type          | Result | Notes                                                                          |
| --------- | ---------------------------------------------------------------------------- | ------------- | ------ | ------------------------------------------------------------------------------ |
| tp-f06-01 | Pass validation errors and original input back in a single struct            | should_invoke | PASS   | Core skill; embedding enforces bundling structurally                           |
| tp-f06-02 | Go struct embedding for form validation in Snippetbox                        | should_invoke | PASS   | I section explains embedding + method promotion; book-specific context         |
| tp-f06-03 | 400 vs 422 for form validation failure                                       | should_invoke | PASS   | B section explicitly states 422 correct, 400 wrong, with semantic reasoning    |
| tp-f06-04 | Storing errors in map and re-reading r.PostForm for template — what's wrong? | should_invoke | PASS   | A2 trigger 3 exactly identifies this as the anti-pattern being replaced        |
| tp-f06-05 | Non-field error like "Email or password is incorrect"                        | should_invoke | PASS   | E step 4 and A1 show `form.AddNonFieldError(...)` with login example           |
| tp-f06-06 | Reuse same Validator across signup, login, create-snippet forms              | should_invoke | PASS   | I section: embedding requires no modification for reuse across form types      |
| tp-f06-07 | go-playground/validator vs custom Validator struct — tradeoffs               | should_invoke | PASS   | B section covers explicitly: verbose but readable and debuggable vs automatic  |
| tp-f06-08 | Display per-field errors inline with original input in template              | should_invoke | PASS   | E step 6 gives exact template patterns for field errors and value repopulation |
| tp-f06-09 | Write Validator struct with CheckField, AddNonFieldError, Valid()            | should_invoke | PASS   | E step 1 gives complete field and method list                                  |

## Summary

9/9 prompts pass. The skill's structural insight — embedding enforces bundling and prevents the state-divergence anti-pattern — distinguishes it from generic form validation advice. The 422 vs 400 decision, non-field errors, and template rendering patterns are all specifically covered. B section correctly excludes file uploads, multipart forms, JSON bodies, and struct-tag validation libraries.
