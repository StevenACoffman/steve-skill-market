# Test Results — Internal-Package-Bounded-Context-Enforcement

## Verdict: PASS

### Should_invoke

| #   | Prompt Summary                                                                                  | Result | Notes                                                                                                                                                                                                                        |
| --- | ----------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Monorepo with Orders, Inventory, Payments — prevent cross-context type imports at compile time? | PASS   | A2 names this exact scenario. E steps 1 and 6 describe the directory structure and separate go.mod requirement. Output is concrete and Go-specific; not available from generic DDD advice.                                   |
| 2   | Where to put domain entities and value objects in a Go microservice project structure?          | PASS   | E steps 1–4 give the canonical layout: internal/domain/, internal/infrastructure/, internal/transport/. Specific and actionable.                                                                                             |
| 3   | `import "mycompany/orders/internal/domain"` in shipping service — is this a problem?            | PASS   | A2 names this pattern. E step 6 and B's same-module caveat both apply. Skill correctly diagnoses whether enforcement fires (separate modules) or silently permits (same module), which is a non-obvious Go toolchain detail. |

### Should_not_invoke

| #   | Prompt Summary                                               | Result | Notes                                                                                                                             |
| --- | ------------------------------------------------------------ | ------ | --------------------------------------------------------------------------------------------------------------------------------- |
| 4   | How to set up a GitHub Actions CI pipeline for a Go project? | PASS   | CI/CD configuration question. No package structure or bounded context decision. Skill description and A2 have no match.           |
| 5   | What is the difference between a Go module and a Go package? | PASS   | Fundamental Go concepts question. Skill correctly defers; description restricts trigger to "structuring a DDD project" decisions. |

### Blurred_boundary

| #   | Prompt Summary                                                                                                        | Result | Notes                                                                                                                                                                                                                                                                              |
| --- | --------------------------------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6   | All three bounded contexts in the same Go module (one go.mod) — does internal/ still enforce boundaries?              | PASS   | B explicitly covers this as a "significant caveat." Skill applies with the correct nuance: single-module internal/ does not enforce cross-service boundaries; need separate modules or a lint rule. This is the skill's most important limitation and it is explicitly documented. |
| 7   | Services don't share Go type imports but share the same PostgreSQL database — are bounded contexts properly isolated? | PASS   | B explicitly states internal/ enforces import-time code coupling, not runtime data coupling. Skill applies with the correct answer: shared schema is a different and often more serious coupling form. internal/ is necessary but not sufficient.                                  |

## Issues Found

None. The E section provides Go-toolchain-specific, compile-time enforcement details that generic DDD advice would not provide. B covers both blurred-boundary cases explicitly, including the non-obvious single-module limitation. Decoy prompts are clearly outside scope.

## Rework Required

None.
