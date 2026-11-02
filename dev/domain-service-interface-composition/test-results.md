# Test Results — Domain-Service-Interface-Composition

## Verdict: PASS

### Should_invoke

| #   | Prompt Summary                                                                                                | Result | Notes                                                                                                                                                                                                                                                                               |
| --- | ------------------------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | PricingService needs external exchange rate API — how to structure for unit testability without mocking HTTP? | PASS   | A2 names this exact scenario. E steps 1–7 produce a concrete implementation path (define interface in domain package → inject in constructor → adapter in infrastructure → wire in main.go). The output is architecture-specific and would not come from generic Go testing advice. |
| 2   | Domain service struct has httpClient `*http.Client` field — is this a problem?                                | PASS   | A2 names this exact anti-pattern. E steps 1–4 prescribe the fix: extract a domain-language interface, define in domain package, inject the HTTP client behind an adapter. Distinctive, opinionated output.                                                                          |
| 3   | Where to put code that sequences three domain service calls and handles partial failures?                     | PASS   | I's "application services are coordination only" rule directly answers this. E step 4's "no infrastructure imports in domain package" and the layered responsibility model are distinctive. Skill correctly directs the developer to the application service layer.                 |

### Should_not_invoke

| #   | Prompt Summary                                                  | Result | Notes                                                                                                                                                                 |
| --- | --------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4   | How to set up gomock for a Go project?                          | PASS   | Tooling setup question. No service design or interface composition decision. Skill description specifies "deciding how to inject dependencies into a domain service." |
| 5   | What is the difference between an interface and a struct in Go? | PASS   | Fundamental Go language question. Skill correctly defers; no service architecture decision is being made.                                                             |

### Blurred_boundary

| #   | Prompt Summary                                                                                                       | Result | Notes                                                                                                                                                                                                                                                                                                      |
| --- | -------------------------------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6   | Domain service needs paginated results from external API — is that too much infrastructure leakage in the interface? | PASS   | B explicitly identifies this as a complexity the simple examples do not address. Skill applies with two concrete options (hide pagination in adapter vs domain-language cursor type) and the key principle: the domain service expresses what it needs, not how the external system implements pagination. |
| 7   | 15 interfaces to inject, main.go getting unwieldy — should I use a DI container?                                     | PASS   | B explicitly names this limitation (constructor injection does not scale automatically). Skill applies with three concrete options (google/wire, samber/do, factory functions) and clarifies the pattern is correct regardless of wiring mechanism.                                                        |

## Issues Found

None. E section has clear decision logic: define interface in domain package (always), implement adapter in separate package (always), wire in main.go (always). The decision logic varies by what capability is needed and how complex the external API is (blurred-boundary cases). Decoy prompts are cleanly excluded by the skill's specific triggering description.

## Rework Required

None.
