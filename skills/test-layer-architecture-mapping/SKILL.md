---
id: test-layer-architecture-mapping
title: Test Architecture Mapping to Code Layers
description: Invoke when deciding what kind of test to write for a given piece of logic — domain function, repository adapter, HTTP/gRPC endpoint wiring, or cross-service contract — or when designing a test strategy for a new service.
source: Go with the Domain, Three Dots Labs (R. Laszczak, M. Smółka), 2026
---

## R — Reading

> "Unit tests: domain layer — pure logic, no mocks, no infrastructure, high coverage.
> Integration tests: adapter layer — real database in Docker, tests if you use the DB correctly, parallel execution mandatory.
> Component tests: full single service in-process — real ports, real adapters with Docker DB, but mock all adapters reaching external services.
> End-to-end tests: all services via docker-compose — only critical path, verify contract is not broken, do not re-test logic already covered at lower levels."

## Chapter 12: Tests Architecture

## I — Interpretation

Each architectural layer has one corresponding test type. The layer where logic lives — not preference, familiarity, or convenience — determines which test type to write. This mapping makes the test strategy non-negotiable: if you are testing a domain method, you write a unit test with no mocks. If you are testing a Firestore adapter, you write an integration test with a real Docker container. The layer determines the test; the test cannot be "promoted" to the next level as a substitute.

The counterintuitive claim in the book is that component tests, not end-to-end tests, are the primary safety net for service correctness. Component tests start the full service binary in-process — real HTTP/gRPC ports, real database via Docker — but replace external service adapters with mocks. They verify the complete service wiring (port routes to handler, handler calls domain, domain result persists) without requiring other services to run. End-to-end tests are then narrow smoke tests that verify cross-service contracts are not broken, not re-examine logic that component tests already cover.

The four-layer taxonomy also enforces quality standards within each type: integration tests must run in parallel (each test creates an isolated DB record or schema), must be deterministic (no `time.Sleep`, channel sync instead), must run on any machine (Docker, not a shared test DB), and must be readable (the test name and assertions explain themselves without comments).

## A1 — Past Application

In Wild Workouts, the trainings service used all four layers:

**Unit tests** — `TestTraining_Cancel` and `TestCancelBalanceDelta` called domain methods directly. No mocks, no DB, no HTTP. These ran in under 1ms each.

**Integration tests** — `TestRepository` accepted a `hour.Repository` interface and ran `testUpdateHour_parallel` (20 goroutines racing to schedule the same slot) against `MemoryHourRepository`, `MySQLHourRepository`, and `FirestoreHourRepository` in parallel. Docker started Firestore and MySQL emulators. Each test run was isolated.

**Component tests** — `TestMain` started the full HTTP server in-process using `NewComponentTestApplication`, which injected `TrainerServiceMock{}` and `UserServiceMock{}` in place of real gRPC clients but kept the real Firestore adapter with a Docker container. Tests called live HTTP endpoints via the oapi-codegen client and verified end-to-end behavior within the single service.

**End-to-end tests** — docker-compose started all services. A single `TestCreateAndCancelTraining` verified the critical user journey. No business logic was tested here that was not already covered by component tests.

## A2 — Future Trigger ★

- A new command handler is added and the question is: "should I write an integration test or a component test to verify it persists correctly to the DB?"
- A Firestore adapter method needs a test — you are deciding whether to use a real DB (Docker) or mock the Firestore SDK.
- The team is writing E2E tests for every feature and the suite takes 45 minutes to run.
- A domain aggregate method needs testing and someone suggests using `httptest` to drive it through the HTTP layer.
- You are designing the test strategy for a new service from scratch and need to allocate test effort across the four types.

## E — Execution

1. Identify the layer of the code under test: domain (pure Go, no imports of infrastructure), adapter (DB, external HTTP/gRPC), port (HTTP/gRPC handler), or cross-service contract.
2. Map to test type: domain → unit test, adapter → integration test (Docker DB, parallel, no sleep), service wiring → component test (`NewTestApplication` constructor), cross-service contract → end-to-end test.
3. For component tests, create a second application constructor that accepts mock implementations of external service interfaces. Start the service on a random port in `TestMain`.
4. For integration tests, run each test in a transaction (rolled back after) or create unique records per test run to ensure parallel isolation. Never share mutable state between parallel tests.
5. Do not write E2E tests for logic already covered by component or unit tests. E2E tests should only cover the critical path that spans multiple services.

## B — Boundary

This taxonomy is for services that follow a layered architecture (domain / app / adapters / ports). A simple CRUD service with no domain layer has no unit test targets by this definition — all its logic is in adapters and ports. In that case, integration and component tests carry more weight.

The dual-constructor pattern for component tests requires discipline: `NewApplication` and `NewComponentTestApplication` must stay synchronized when new dependencies are added. If the test constructor drifts from the production constructor, tests stop catching real wiring bugs.

End-to-end tests are necessary but must be kept narrow. Adding E2E coverage for every feature negates the speed and determinism benefits of the lower layers. When the E2E suite grows beyond a handful of tests, review whether the tests are actually re-testing component-level concerns.

## Related Skills

- **[anti-dry-separate-read-write-models](../anti-dry-separate-read-write-models/SKILL.md)** — informs: separate read and write models map cleanly to distinct test targets — command handlers (component tests) and query handlers (integration tests against optimized projections).
