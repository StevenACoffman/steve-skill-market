# Merge Audit — Grpc-Test-Pyramid-Interceptors-and-Infrastructure

## Source Skills

| Field   | Source A                                               | Source B                                             |
| ------- | ------------------------------------------------------ | ---------------------------------------------------- |
| Slug    | grpc-go-for-professionals/grpc-testing-level-selection | grpc-microservices-in-go/grpc-testcontainers-pyramid |
| Book    | gRPC Go for Professionals                              | gRPC Microservices in Go                             |
| Author  | Clément Jean                                           | Hüseyin Babal                                        |
| Chapter | Ch. 9 — Production-Grade APIs                          | Ch. 7 — Testing                                      |
| Case    | TODO service (CRUD, no DB container)                   | Order/Payment service (MySQL + downstream)           |

## Phase 1 Verdict

ADVANCE — V1, V2, V3, V4 all PASS.

## R-Section Audit

**Source A quote** ("One important thing to understand here is that we are not testing the whole server..."): Verified verbatim at lines 8336-8339 of `gRPC_go_for_professionals_book.md`.

**Source B quote** ("Unit tests are designed to test one component at a time..."): Verified at lines 3603-3610 and 4515 of `gRPC_Microservices_in_Go_book.md`. The quote composites three sentences from adjacent paragraphs across Ch. 7; all claims verified.

**Convergence note:** Accurately describes genuine independent convergence on the three-tier model from two different books, two different services, and two different authors.

## I-Section Audit

**Tier ownership principle (Source A):** The claim that interceptors belong in integration tests, not unit tests, is verbatim from the source (lines 8336-8339). The failure mode (silent auth bypass reaching production) is attributed to Source A and is a plausible inference from the explicit framing, though the exact counter-example narrative is the SKILL author's synthesis from the principle.

**Testcontainers tooling (Source B):** `wait.ForSQL` pattern verified at Ch. 7 source discussion (lines 3603-3608). `testify/suite` lifecycle pattern confirmed consistent with `testcontainers-go` library APIs referenced throughout Ch. 7.

**Integration tier split (synthesis-specific):** The claim that the integration tier should cover two distinct sub-concerns (interceptors vs. infrastructure) as separate test suites is the key synthesis insight. This is not stated in either source — Source A covers interceptors, Source B covers database containers — but it is the correct inference from combining them. Both sources are silent about what to do when a service has both concerns; the merged skill fills this gap.

**Third-tier divergence:** Accurately surfaces the real disagreement between sources (ghz vs. LocalDockerCompose) and resolves it as complementary rather than contradictory. This is the correct treatment — neither source is wrong; they address different validation types.

## A1-Section Audit

**Case 1 (Source A — TODO service):** `bufconn`+`FakeDb` harness confirmed at Ch. 9 source (lines 8333-8339). The claim that interceptors are in `main.go` but excluded from test server is derived from the overall Ch. 7–9 narrative. Attribution accurate.

**Case 2 (Source B — Order service):** `wait.ForSQL("orders", "mysql", dataSourceName)` in `SetupSuite` confirmed at Ch. 7 context (lines 3603-3608). `e2e/create_order_e2e_test.go` with `LocalDockerCompose` and field round-trip assertions confirmed consistent with source. Attribution accurate within reasonable confidence.

**Cross-case insight:** The claim that the two cases are complementary stages of the integration tier (one illustrates interceptor isolation, the other illustrates infrastructure provisioning) is a valid logical inference from the source material.

## A2-Section Audit

**Merged A2 sharpness:** Source A A2: "auth interceptor passes all requests, undetected." Source B A2: "integration tests failing intermittently, MySQL not ready." Merged A2 is sharper — maps both concerns explicitly to correct tiers with the "Instead of" framing, names `codes.Unauthenticated` and `wait.ForSQL` as specific implementation prescriptions.

## E-Section Audit

**Execution length:** 7 steps. Source A E has 5 steps. Source B E has 6 steps. The merged E is not substantially longer than the longer source — the additional steps (explicit tier definition, build tag guidance) are single steps with short explanations.

**Reconciliation:** Steps from both sources are combined. The two integration sub-concerns are presented as steps 3 and 4, which is correct — they are parallel concerns, not sequential steps.

**Conditionals:** The note about `wait.ForLog` as an alternative to `wait.ForSQL` when migrations run at startup is correctly marked as a conditional from Source B. The third-tier divergence resolution is explicit — if only one tier is possible, prioritize e2e correctness over load testing.

## B-Section Audit

**Source A failures (4 items):** Auth interceptor silent pass-through, load test flakiness in shared CI, no-interceptor service collapse acceptance, client-side scope boundary — all verified against Source A B-section.

**Source B failures (5 items):** Docker-in-Docker requirement, `wait.ForSQL` table dependency, container startup time, e2e scenario count limit, mockery regeneration — all verified against Source B B-section.

**Synthesis-specific failure (1 item):** "Mixed integration suite where TLS issues and DB startup races are indistinguishable on failure" — correctly identified as the consequence of not separating the two integration sub-concerns. This is the key synthesis failure mode.

**Contradiction resolution:** Third-tier divergence (ghz vs. LocalDockerCompose) is explicitly surfaced and resolved: both are valid, both belong, neither supersedes the other. This is the correct treatment of a real disagreement between sources that is not a logical contradiction.

## V1–v4 Gate Summary

| Gate | Status | Evidence                                                                                                                     |
| ---- | ------ | ---------------------------------------------------------------------------------------------------------------------------- |
| V1   | PASS   | TODO service (A, Ch9 unit+interceptor) + Order service (B, Ch7 unit+integration+e2e) = 4 independent contexts across 2 books |
| V2   | PASS   | "How do I test a service with both an auth interceptor and a MySQL adapter?" — neither source alone answers both halves      |
| V3   | PASS   | The integration tier must cover two distinct sub-concerns separately — non-obvious even to experienced Go/gRPC developers    |
| V4   | PASS   | Merged A2 maps both concerns to correct tiers with specific implementation prescriptions, sharper than either source         |

## Slug Rationale

`grpc-test-pyramid-interceptors-and-infrastructure` — names both synthesis sub-concerns (interceptors, infrastructure) without privileging either source. A developer searching for interceptor testing or testcontainers in gRPC context will find this skill.
