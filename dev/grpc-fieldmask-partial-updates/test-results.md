# Test Results — Grpc-Fieldmask-Partial-Updates

## Verdict: PASS (10/10)

______________________________________________________________________

### Should_invoke

| ID   | Prompt Summary                                                           | Result | Notes                                                                                                            |
| ---- | ------------------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------- |
| tp01 | Add caller-controlled field selection to a gRPC list endpoint            | PASS   | A2 bullet 1 exact match; E steps 1-6 give the complete proto change + server-side implementation                 |
| tp02 | Server-side FieldMask filtering with ProtoReflect                        | PASS   | E step 3 gives the exact `ProtoReflect().Range()` loop with Clear() call                                         |
| tp03 | Computed 'overdue' depends on masked 'due_date' — should it be included? | PASS   | I section addresses this exact derived-field correctness requirement with the TODO service example               |
| tp04 | Why is FieldMask especially valuable for server-streaming vs. unary?     | PASS   | I section gives the precise insight: mask cost paid once, bandwidth savings compound across N streamed responses |

### Should_not_invoke

| ID   | Prompt Summary                                                            | Result | Notes                                                                                                                                   |
| ---- | ------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| tp05 | Implement partial update (PATCH) — update only fields the client provides | PASS   | Trigger description and A2 explicitly limit this skill to reads; write/mutation FieldMask is not in any section; skill correctly defers |
| tp06 | Add validation with protoc-gen-validate                                   | PASS   | No overlap with FieldMask field selection; no trigger condition fires                                                                   |
| tp07 | Serialize a large Protobuf message to a file                              | PASS   | Serialization to storage is unrelated to streaming field selection                                                                      |

### Blurred_boundary

| ID   | Prompt Summary                                            | Result | Notes                                                                                                                                                         |
| ---- | --------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp08 | FieldMask vs. separate DTOs for bandwidth reduction       | PASS   | Skill correctly argues for FieldMask while B section acknowledges the trade-off for tight read-model alignment — nuanced, not dismissive                      |
| tp09 | Should FieldMask also limit which DB columns are fetched? | PASS   | B section explicitly states FieldMask does not automatically limit DB queries and describes the mask-to-SELECT translation as an extension; correctly bounded |
| tp10 | Start with FieldMask or with field tag assignment?        | PASS   | Skill correctly defers sequencing decision to grpc-payload-optimization while explaining FieldMask's specific role                                            |

______________________________________________________________________

## Naming Note

The skill ID `grpc-fieldmask-partial-updates` contains the word "updates" but the skill exclusively covers read/list endpoints. The trigger description correctly says "read or list endpoint" and all A2 bullets describe read contexts. The should_not_invoke tp05 (write/PATCH) correctly does not fire because the trigger conditions contain no write context. No rework required — the internal logic is consistent; only the ID label is slightly misleading.

## Distinctive Value Assessment

The derived-field ordering correctness (tp03) is a subtle correctness requirement not found in standard FieldMask documentation. The "paid once, applied N times" streaming amortization insight (tp04) is specific to this book's streaming focus. Both pieces produce output that generic proto documentation would not provide.
