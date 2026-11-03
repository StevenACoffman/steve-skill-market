# Test Results: Letsgo-Postform-Not-Postformvalue

## Verdict: PASS

## Prompt-by-Prompt Evaluation

| ID           | Prompt (summary)                                                              | Type          | Result | Notes                                                                                    |
| ------------ | ----------------------------------------------------------------------------- | ------------- | ------ | ---------------------------------------------------------------------------------------- |
| tp-p02p10-01 | r.PostFormValue() with malformed request body — what happens?                 | should_invoke | PASS   | I section: returns empty string, silently discards ParseForm error                       |
| tp-p02p10-02 | Difference between r.PostFormValue(), r.FormValue(), r.PostForm.Get()         | should_invoke | PASS   | I section covers all three; E step 3 names the correct one                               |
| tp-p02p10-03 | Correctly read form data from POST, return 400 if malformed                   | should_invoke | PASS   | E steps 1-2: explicit ParseForm() + error check + r.PostForm.Get()                       |
| tp-p02p10-04 | r.FormValue() picking up URL query string instead of POST body                | should_invoke | PASS   | I section explains FormValue reads both Form (URL) and PostForm (body); A2 trigger 6     |
| tp-p02p10-05 | What does internal/ do — convention or compiler-enforced?                     | should_invoke | PASS   | I section second half: "not a naming convention — the compiler enforces it"              |
| tp-p02p10-06 | Which packages under internal/ vs module root?                                | should_invoke | PASS   | E step 5 and A1 project layout show models, validator, assert, mocks all under internal/ |
| tp-p02p10-07 | Using gorilla/schema — still need r.ParseForm() first?                        | should_invoke | PASS   | E step 4 explicitly: pass r.PostForm (already parsed), not r, to decoder.Decode          |
| tp-p02p10-08 | Put models under internal/ — what happens if external module tries to import? | should_invoke | PASS   | I section: compiler rejects it; B section mentions monorepo caveat                       |
| tp-p02p10-09 | Prevent teammates from accidentally importing implementation packages         | should_invoke | PASS   | A2 trigger 3; internal/ provides compiler-enforced answer                                |

## Summary

9/9 prompts pass. The skill covers two distinct but book-paired concerns: HTTP input parsing correctness (PostFormValue silent discard, FormValue body/query mixing) and Go's internal/ package compiler enforcement. Both have non-obvious failure modes that generic advice misses. E section provides clear decision rules for both. B section correctly scopes out multipart forms, JSON bodies, and multi-module monorepo edge cases.
