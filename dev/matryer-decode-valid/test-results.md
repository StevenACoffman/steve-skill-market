# Test Results: Matryer-Decode-Valid

## Summary

- Total prompts: 10
- PASS: 10
- FAIL: 0
- Reworks performed: 0

## Results

| ID    | Category          | Verdict | Notes                                                                                                                                                                                                                   |
| ----- | ----------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| si-1  | should_invoke     | PASS    | Direct trigger-phrase match for repeated decode+validate boilerplate. Validator interface + decodeValid generic is the answer.                                                                                          |
| si-2  | should_invoke     | PASS    | problems map[string]string keyed by field name is the exact return type; directly serializable for 400 responses.                                                                                                       |
| si-3  | should_invoke     | PASS    | Asks explicitly for decodeValid[T Validator] generic; full implementation and type-constraint explanation are in the skill.                                                                                             |
| si-4  | should_invoke     | PASS    | Architectural placement question answered by Validator interface moving field-level rules onto the struct away from handler bodies.                                                                                     |
| sni-1 | should_not_invoke | PASS    | DB uniqueness check is I/O-dependent validation; skill explicitly places this outside Valid() in the handler. Skill correctly out-of-scope.                                                                             |
| sni-2 | should_not_invoke | PASS    | Third-party schema validation library question. Skill uses hand-rolled interface; does not compare libraries. No false trigger.                                                                                         |
| sni-3 | should_not_invoke | PASS    | JWT auth middleware is a different concern (matryer-middleware-constructor territory). Decode/validation skill does not apply.                                                                                          |
| bb-1  | blurred_boundary  | PASS    | DB record existence check sounds like validation but is I/O-dependent. B section and E Step 5 explicitly address this split: decodeValid for structural, handler for relational checks.                                 |
| bb-2  | blurred_boundary  | PASS    | Multipart form request: conceptual pattern applies (decode+validate in one step) but decodeValid uses json.NewDecoder. B section notes this limitation. Skill partially applies.                                        |
| bb-3  | blurred_boundary  | PASS    | Library comparison (go-playground/validator vs. hand-rolled Valid()): skill advocates one approach without comparing alternatives. Relevant problem space but the question asks for comparison; skill is a partial fit. |

## Reworks

None.
