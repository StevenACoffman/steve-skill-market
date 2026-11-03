# Test Results: Test-Layer-Architecture-Mapping

**Skill:** Test Architecture Mapping to Code Layers
**Date:** 2026-05-05
**Verdict:** PASS

______________________________________________________________________

## Prompt Evaluations

### Tp-01 — Should_invoke — PASS

**Prompt:** New command handler calls Firestore adapter and external gRPC service. Integration test or component test?

**Assessment:** A2 trigger: "A new command handler is added and the question is: should I write an integration test or a component test to verify it persists correctly to the DB?" The E section answers directly: command handler wiring (handler → domain → adapter) is the component test layer. Firestore adapter testing in isolation is the integration test layer. The external gRPC service gets mocked in the component test. The skill produces a clear, non-obvious answer: the command handler gets a component test (not integration test) because it involves service wiring, while the Firestore adapter gets its own integration test. This is distinctly different from generic "integration test everything" advice. **PASS.**

______________________________________________________________________

### Tp-02 — Should_invoke — PASS

**Prompt:** Team writes E2E tests for every feature. Suite takes 40 minutes. How to restructure?

**Assessment:** A2 trigger: "The team is writing E2E tests for every feature and the suite takes 45 minutes to run." I section: "component tests, not end-to-end tests, are the primary safety net for service correctness." E step 5: "Do not write E2E tests for logic already covered by component or unit tests." The skill produces specific restructuring guidance: move service-wiring tests to component tests, move pure logic tests to unit tests, keep E2E only for critical cross-service paths. This is the B section boundary applied prescriptively. **PASS.**

______________________________________________________________________

### Tp-03 — Should_invoke — PASS

**Prompt:** How to test Firestore repository adapter without mocking the Firestore SDK?

**Assessment:** A2 trigger: "A Firestore adapter method needs a test — you are deciding whether to use a real DB (Docker) or mock the Firestore SDK." The I section: "integration tests — adapter layer — real database in Docker." E step 4: run each test in a transaction or with unique records for parallel isolation; never use `time.Sleep`. The skill produces concrete guidance: use the Firestore emulator in Docker, run parallel, no sleep. The "no mock the SDK" answer is exactly right — mocking Firestore SDK gives false confidence. **PASS.**

______________________________________________________________________

### Tp-04 — Should_invoke — PASS

**Prompt:** Component test for HTTP service with real DB but no external payment service.

**Assessment:** A2 trigger: "You are designing the test strategy for a new service from scratch." E step 3 prescribes exactly this: "create a second application constructor that accepts mock implementations of external service interfaces. Start the service on a random port in TestMain." The `NewComponentTestApplication` pattern with Docker DB and mocked external services is the skill's central demonstration. **PASS.**

______________________________________________________________________

### Tp-05 — Should_not_invoke — PASS

**Prompt:** How do I use testify/assert for table-driven unit tests in Go?

**Assessment:** This is a testing library syntax question — nothing about layer mapping, test strategy, or architectural placement. The skill has no guidance on testify. It would correctly not fire. **PASS.**

______________________________________________________________________

### Tp-06 — Should_not_invoke — PASS

**Prompt:** How do I set up GitHub Actions to run my Go tests in CI?

**Assessment:** CI pipeline configuration — infrastructure, not test architecture. The skill would not fire. **PASS.**

______________________________________________________________________

### Tp-07 — Blurred_boundary — PASS

**Prompt:** Should I mock the database in command handler tests, or use a real database?

**Assessment:** The taxonomy answers this indirectly but precisely: command handler wiring tests are component tests, which use a real database via Docker. Only integration tests at the adapter level use real DB in isolation. The "should I mock?" question dissolves into "which layer am I testing?" — the skill's core value. The answer depends on whether you're testing the adapter (real DB, no mock) or the full service wiring (component test, real DB via Docker, but external services mocked). The skill produces nuanced output: mock the external services, not the database, when testing command handler wiring. **PASS.**

______________________________________________________________________

### Tp-08 — Blurred_boundary — PASS

**Prompt:** Domain unit tests are slow because they use time.Sleep for async operations.

**Assessment:** This is partially in scope: the I section's integration test quality principles include "must be deterministic (no time.Sleep, channel sync instead)." But the person has this problem in domain unit tests, not integration tests. The skill handles the ambiguity: first note that domain unit tests should have no async operations at all (they're pure logic, no infrastructure), then apply the "no sleep, use channel sync" principle from integration test quality. The skill provides useful guidance while noting that the async pattern in a domain unit test suggests the domain layer may have inappropriate infrastructure dependencies. **PASS.**

______________________________________________________________________

### Tp-09 — Blurred_boundary — PASS

**Prompt:** Pub/Sub message triggers domain operation and persists result. What kind of test?

**Assessment:** A2 trigger overlaps: "You are designing the test strategy for a new service from scratch." The Pub/Sub trigger → domain → persist flow spans port (Pub/Sub adapter) → app handler → domain → repository. This maps to a component test (full service wiring). However, the async nature (Pub/Sub) adds synchronization concerns not directly addressed in the E section. The skill handles this gracefully: maps to component test, notes that the TestMain approach with Docker DB applies, and acknowledges the asynchronous aspect requires additional test infrastructure (channel sync or polling with timeout, not sleep). The layer mapping is clear even if Pub/Sub synchronization is a topic beyond this skill's scope. **PASS.**

______________________________________________________________________

## Summary

| Prompt | Type              | Result |
| ------ | ----------------- | ------ |
| tp-01  | should_invoke     | PASS   |
| tp-02  | should_invoke     | PASS   |
| tp-03  | should_invoke     | PASS   |
| tp-04  | should_invoke     | PASS   |
| tp-05  | should_not_invoke | PASS   |
| tp-06  | should_not_invoke | PASS   |
| tp-07  | blurred_boundary  | PASS   |
| tp-08  | blurred_boundary  | PASS   |
| tp-09  | blurred_boundary  | PASS   |

## 9/9 PASS — Skill Verdict: PASS

**Strengths:** The four-layer taxonomy is crisp and non-overlapping. A2 triggers cover the five most common decision points. B section enforces the E2E narrowness rule that prevents the common over-reliance trap. The integration-vs-component distinction (both use Docker DB but serve different purposes) is the skill's most distinctive contribution.

**No rework needed.**
