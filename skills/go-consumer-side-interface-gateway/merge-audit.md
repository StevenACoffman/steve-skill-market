# Merge Audit — Go-Consumer-Side-Interface-Gateway

## Convergence Map

| Claim                                             | GWTP         | rednafi             | Verdict               |
| ------------------------------------------------- | ------------ | ------------------- | --------------------- |
| Consumer package defines the interface            | ✓            | ✓                   | Confirmed convergence |
| Interface should be minimal (only called methods) | ✓            | ✓ (1-2 methods max) | Confirmed convergence |
| Producer package returns concrete types           | ✓ (implicit) | ✓ (explicit rule)   | Confirmed convergence |
| Anti-pattern: shared contracts/interfaces package | ✓            | ✓                   | Confirmed convergence |
| Wiring in cmd/main.go                             | ✓ (implicit) | ✓ (explicit step)   | Confirmed convergence |
| Test with handwritten fake, no mock library       | ✓            | ✓                   | Confirmed convergence |

## Divergence Map

| Dimension                                         | GWTP                                           | rednafi                                          | Resolution                                            |
| ------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------- |
| Primary framing                                   | Import cycle prevention (structural necessity) | Unnecessary dependency spread prevention         | Both preserved; different levels of the same pattern  |
| Gateway package location                          | Not named                                      | `external/<provider>/gateway.go`                 | rednafi's structure adopted; adds to GWTP's principle |
| Interface naming discipline                       | Not addressed                                  | Method-derived names (Uploader, Charger, Sender) | rednafi's naming convention added to I                |
| Reciprocal rule (producers return concrete types) | Not stated                                     | Explicit rule                                    | rednafi's rule added to I                             |
| Scope                                             | App/adapter intra-service boundary             | External SDKs and third-party APIs               | Both scopes presented as Level 1 and Level 2 in I     |
| SDK type leakage through signatures               | Not mentioned                                  | Explicit blind spot                              | Added to B as Source B failure                        |
| Library author inapplicability                    | Not mentioned                                  | Explicit boundary                                | Added to B                                            |

## A2 Sharpness Check

Source A A2: generic placement question, import cycle, mock scenario, shared contracts question.
Source B A2: concrete SDK type as parameter, fat inherited interface, external service in business logic, multiple providers, gRPC client.

Merged A2 is sharper because:

1. Leads with the most concrete trigger: "a business logic function accepts `*s3.Client` as a parameter" — immediately actionable, no ambiguity.
2. Adds "where does the real SDK code live?" as a trigger — this question is the gateway pattern's specific contribution and is absent from GWTP's A2.
3. The "Not this skill when" section explicitly excludes library authors and stdlib interfaces — boundaries neither source stated in the A2 position.

## Quote Accuracy Notes

- GWTP quote: Verified verbatim against go_with_domain_book.md line 3816.
- rednafi quote 1 ("define small interfaces on the consumer side"): Verified verbatim against rednafi/interface_segregation.md line 162.
- rednafi quote 2 (Go interfaces generally belong in the package that uses them): Verified verbatim against interface_segregation.md lines 170–171.
- rednafi quote 3 ("Insert a seam between two tightly coupled components"): Verified verbatim against interface_segregation.md line 279.

## Synthesis-Specific Failure Mode Justification

"Structural drift when the gateway is omitted" is synthesis-specific because:

- GWTP provides the principle (consumer-side interface, import cycle prevention) but not the structural location for the real SDK implementation.
- rednafi provides `external/<provider>/gateway.go` as the named location but does not articulate the import-cycle enforcement argument.
- A developer applying GWTP's principle alone might correctly define the interface in the business package but leave the Stripe SDK calls scattered — in the business package "temporarily," or in main.go directly. Without the named gateway location, the pattern is applied incompletely.
- This failure mode cannot be derived from either source alone; it emerges from the gap between them. Naming it makes the incompleteness observable before it becomes a structural problem.
