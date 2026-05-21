---
name: grpc-test-pyramid-interceptors-and-infrastructure
allowed-tools: Bash, Read, Edit
id: grpc-test-pyramid-interceptors-and-infrastructure
description: >
  Invoke when structuring a test suite for a gRPC service that has both interceptors
  (auth, rate-limit, TLS) and infrastructure dependencies (database, downstream
  services). Key trigger: "my unit tests pass but integration is flaky" or "I'm
  not sure which tier owns interceptor testing vs. database adapter testing."
  The synthesis: the integration tier covers two distinct sub-concerns that must
  stay separate — (1) interceptor chain with real TLS via bufconn, and (2)
  infrastructure adapters with real containers via testcontainers + wait.ForSQL.
  Collapsing them mixes setup complexity and obscures root cause on failure.
type: merged-skill
source_skills:
  - slug: grpc-go-for-professionals/grpc-testing-level-selection
    book: "gRPC Go for Professionals"
    author: Clément Jean
  - slug: grpc-microservices-in-go/grpc-testcontainers-pyramid
    book: "gRPC Microservices in Go"
    author: Hüseyin Babal
related_skills:
  - slug: grpc-go-for-professionals/grpc-testing-level-selection
    relation: supersedes
    note: Covers tier ownership without testcontainers infrastructure tooling.
  - slug: grpc-microservices-in-go/grpc-testcontainers-pyramid
    relation: supersedes
    note: Covers testcontainers tooling without interceptor-tier ownership principles.
tags: []
---

# gRPC Test Pyramid — Interceptors and Infrastructure as Separate Integration Concerns

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

bufconn usage (interceptor integration tests):
!`grep -rn 'bufconn\|google.golang.org/grpc/test/bufconn' --include='*.go' . 2>/dev/null | head -5`

testcontainers usage (infrastructure tests):
!`grep -rn 'testcontainers\|testcontainers-go' --include='*.go' . 2>/dev/null | head -5`

grpc.NewServer in tests (unit tier):
!`grep -rn 'grpc\.NewServer()' --include='*_test.go' . 2>/dev/null | head -5`

### R — Reading

> "One important thing to understand here is that we are not testing the whole server
> that we wrote in main.go. We are simply testing our endpoints implementation. This is
> why we can connect to the server with insecure credentials. The interceptors,
> encryption, and so on should be tested in integration tests."

*gRPC Go for Professionals, Ch. 9 — Production-Grade APIs* (Jean)

> "Unit tests are designed to test one component at a time, with maximum isolation.
> While testing a component (SUT), you should mock the other dependencies... Once you
> move to the integration test, you need third-party tools to maintain dependencies,
> such as having test containers for a DB connection... End-to-end tests can contain
> all the available services in your environment because you test a flow from beginning
> to end."

*gRPC Microservices in Go, Ch. 7 — Testing* (Babal)

**Convergence note:** Both sources independently prescribe the same three-tier isolation model (unit / integration / top-tier) from different services and different books — the TODO service (Go for Professionals, Ch. 9) and the Order/Payment service (Microservices in Go, Ch. 7). What each adds uniquely: Go for Professionals defines which gRPC-specific concern each tier *owns* (interceptors belong in integration, not unit), while Microservices in Go provides the concrete infrastructure tooling for the integration tier (testcontainers, `wait.ForSQL`, testify/suite lifecycle).

### I — Interpretation

A gRPC service with both interceptors and a database dependency has two distinct integration-tier concerns that must be tested separately. Collapsing them produces integration tests that are simultaneously complex to set up and hard to diagnose when they fail — because a MySQL startup race and an auth interceptor bug look identical until you isolate them.

**Unit tier:** Replace all real dependencies with interfaces backed by mocks or fakes. No containers, no network, no credentials, no interceptors. Use `grpc.NewServer()` with zero server options and `insecure.NewCredentials()` on the client. The `bufconn` listener consumes no OS resources and allows parallel execution. Unit tests own endpoint logic — given correct inputs, the handler returns the correct gRPC status code and correctly calls the storage interface. Everything else is out of scope.

**Integration tier — interceptor sub-concern:** Start the server exactly as `main.go` starts it, with all interceptors registered and real TLS test credentials loaded from files. Use `bufconn` for the transport (no OS port allocation). Test that an unauthenticated request returns `codes.Unauthenticated`, that a rate-limited request returns `codes.ResourceExhausted`, and that metrics counters increment correctly. These tests are slower than unit tests because they load credentials and start a full server, but faster than infrastructure tests because there are no containers.

**Integration tier — infrastructure sub-concern:** Use `testcontainers-go` to provision a real MySQL container (or other dependency). The `SetupSuite` method (from `testify/suite`) calls `testcontainers.GenericContainer` with `WaitingFor: wait.ForSQL(tableName, driverName, dataSourceName)`. This blocks until MySQL accepts real connections to the specified table — preventing the flaky startup race that occurs when tests begin before the database is ready. Test that the real adapter correctly persists and retrieves objects. Mocks cannot catch GORM configuration errors, schema migration issues, or SQL query bugs.

**Why these sub-concerns must be separate:** An interceptor integration test that requires a MySQL container to run is both slower and more fragile than necessary. A MySQL integration test that also spins up the full interceptor chain makes it harder to isolate whether a failure is a TLS credential issue or a database connection issue. Each sub-concern has different setup requirements and different diagnostic signals; keeping them in separate test files makes failures immediately attributable.

**Top tier — e2e functional tests:** Use `testcontainers.LocalDockerCompose` to bring up the entire stack defined in `docker-compose.yml`. Connect with a real `grpc.Dial` client and validate user flows end-to-end (create order, retrieve order, verify fields round-trip correctly). Keep scenario count small — happy path plus critical failure paths only.

**Top tier — load tests:** Run `ghz` against a deployed instance (not in the unit test runner). Validate status-code distribution and p50/p95/p99 latency against the service's SLOs. Load tests in shared CI environments produce flaky results from infrastructure contention; they belong in a dedicated pipeline stage against a deployment, not in `go test ./...`.

The third tier differs between the two sources: Go for Professionals uses `ghz` load testing (performance validation); Microservices in Go uses `LocalDockerCompose` functional e2e testing (flow correctness). These are not competing definitions — they are different types of validation that both belong above the integration tier. A complete test strategy includes both as explicit, separately managed pipeline stages.

**Mock tooling:** The source books present two approaches — handwritten `FakeDb` structs (Go for Professionals) and `mockery`-generated mocks from port interfaces (Microservices in Go). `summary_rules.md §10` resolves this: "Hand-write mocks in a `mock` package. No third-party mock generation tools." Handwritten fakes with function-typed fields (`SaveFn func(*domain.Order) error`) and `Invoked bool` fields are the prescribed form. The mockery approach is noted here as the source book's pattern; prefer handwritten fakes when following `summary_rules.md`.

### A1 — Past Application

## R — Reading

> "One important thing to understand here is that we are not testing the whole server
> that we wrote in main.go. We are simply testing our endpoints implementation. This is
> why we can connect to the server with insecure credentials. The interceptors,
> encryption, and so on should be tested in integration tests."

*gRPC Go for Professionals, Ch. 9 — Production-Grade APIs* (Jean)

> "Unit tests are designed to test one component at a time, with maximum isolation.
> While testing a component (SUT), you should mock the other dependencies... Once you
> move to the integration test, you need third-party tools to maintain dependencies,
> such as having test containers for a DB connection... End-to-end tests can contain
> all the available services in your environment because you test a flow from beginning
> to end."

*gRPC Microservices in Go, Ch. 7 — Testing* (Babal)

**Convergence note:** Both sources independently prescribe the same three-tier isolation model (unit / integration / top-tier) from different services and different books — the TODO service (Go for Professionals, Ch. 9) and the Order/Payment service (Microservices in Go, Ch. 7). What each adds uniquely: Go for Professionals defines which gRPC-specific concern each tier *owns* (interceptors belong in integration, not unit), while Microservices in Go provides the concrete infrastructure tooling for the integration tier (testcontainers, `wait.ForSQL`, testify/suite lifecycle).

## I — Interpretation

A gRPC service with both interceptors and a database dependency has two distinct integration-tier concerns that must be tested separately. Collapsing them produces integration tests that are simultaneously complex to set up and hard to diagnose when they fail — because a MySQL startup race and an auth interceptor bug look identical until you isolate them.

**Unit tier:** Replace all real dependencies with interfaces backed by mocks or fakes. No containers, no network, no credentials, no interceptors. Use `grpc.NewServer()` with zero server options and `insecure.NewCredentials()` on the client. The `bufconn` listener consumes no OS resources and allows parallel execution. Unit tests own endpoint logic — given correct inputs, the handler returns the correct gRPC status code and correctly calls the storage interface. Everything else is out of scope.

**Integration tier — interceptor sub-concern:** Start the server exactly as `main.go` starts it, with all interceptors registered and real TLS test credentials loaded from files. Use `bufconn` for the transport (no OS port allocation). Test that an unauthenticated request returns `codes.Unauthenticated`, that a rate-limited request returns `codes.ResourceExhausted`, and that metrics counters increment correctly. These tests are slower than unit tests because they load credentials and start a full server, but faster than infrastructure tests because there are no containers.

**Integration tier — infrastructure sub-concern:** Use `testcontainers-go` to provision a real MySQL container (or other dependency). The `SetupSuite` method (from `testify/suite`) calls `testcontainers.GenericContainer` with `WaitingFor: wait.ForSQL(tableName, driverName, dataSourceName)`. This blocks until MySQL accepts real connections to the specified table — preventing the flaky startup race that occurs when tests begin before the database is ready. Test that the real adapter correctly persists and retrieves objects. Mocks cannot catch GORM configuration errors, schema migration issues, or SQL query bugs.

**Why these sub-concerns must be separate:** An interceptor integration test that requires a MySQL container to run is both slower and more fragile than necessary. A MySQL integration test that also spins up the full interceptor chain makes it harder to isolate whether a failure is a TLS credential issue or a database connection issue. Each sub-concern has different setup requirements and different diagnostic signals; keeping them in separate test files makes failures immediately attributable.

**Top tier — e2e functional tests:** Use `testcontainers.LocalDockerCompose` to bring up the entire stack defined in `docker-compose.yml`. Connect with a real `grpc.Dial` client and validate user flows end-to-end (create order, retrieve order, verify fields round-trip correctly). Keep scenario count small — happy path plus critical failure paths only.

**Top tier — load tests:** Run `ghz` against a deployed instance (not in the unit test runner). Validate status-code distribution and p50/p95/p99 latency against the service's SLOs. Load tests in shared CI environments produce flaky results from infrastructure contention; they belong in a dedicated pipeline stage against a deployment, not in `go test ./...`.

The third tier differs between the two sources: Go for Professionals uses `ghz` load testing (performance validation); Microservices in Go uses `LocalDockerCompose` functional e2e testing (flow correctness). These are not competing definitions — they are different types of validation that both belong above the integration tier. A complete test strategy includes both as explicit, separately managed pipeline stages.

**Mock tooling:** The source books present two approaches — handwritten `FakeDb` structs (Go for Professionals) and `mockery`-generated mocks from port interfaces (Microservices in Go). `summary_rules.md §10` resolves this: "Hand-write mocks in a `mock` package. No third-party mock generation tools." Handwritten fakes with function-typed fields (`SaveFn func(*domain.Order) error`) and `Invoked bool` fields are the prescribed form. The mockery approach is noted here as the source book's pattern; prefer handwritten fakes when following `summary_rules.md`.

## A1 — Past Application

### Case 1: TODO Service — Interceptor Tier Ownership

The book *gRPC Go for Professionals* builds the TODO service test suite across Ch. 7–9. Unit tests use the `bufconn`+`FakeDb` harness with zero interceptors and `insecure.NewCredentials()` — the test verifying that `IsAvailable(false)` returns `codes.Internal` is a unit test because it validates endpoint logic, not the interceptor stack. Ch. 7 and Ch. 8 introduce auth and metrics interceptors registered in `main.go` but deliberately excluded from the test server. The explicit rationale: if interceptors were in unit tests, every unit test would require auth credentials and full chain setup, slowing execution and mixing concerns.

The production-level failure mode that motivates this discipline: an auth interceptor that silently passed all requests was deployed because it was never exercised at the integration tier. The unit tests passed (endpoint logic was correct) but the interceptor had a bug that no test covered.

### Case 2: Order Service — Infrastructure Tier Tooling

> **Note:** The examples below use `mockery`-generated mocks and `testify/suite` as shown in the source book (*gRPC Microservices in Go*). These patterns conflict with `summary_rules.md §10` (no third-party mock generation tools; no third-party testing frameworks). The tier model and testcontainers tooling are correct and reusable; substitute hand-written fakes and `TestMain` lifecycle for the prohibited patterns — see the E section for the corrected implementation.

The book *gRPC Microservices in Go* builds the Order service test suite in Ch. 7. Unit tests in `internal/application/core/api/application_test.go` use `mockery`-generated `mockedPayment` and `mockedDb` structs — `On("Save", ...).Return(nil)` for success, `On("Save", ...).Return(error)` for the DB failure path. No containers, no network.

Integration tests in `internal/adapters/db/db_integration_test.go` use:

```go
func (s *DBTestSuite) SetupSuite() {
    ctx := context.Background()
    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image:        "mysql:8.0.30",
            ExposedPorts: []string{"3306/tcp"},
            WaitingFor:   wait.ForSQL("orders", "mysql", dataSourceName),
        },
        Started: true,
    })
    port, _ := container.MappedPort(ctx, "3306/tcp")
    dsn := fmt.Sprintf("root:password@tcp(localhost:%s)/orders", port.Port())
    s.db = db.NewAdapter(dsn)
}
```

The `wait.ForSQL` probe blocks until the `orders` table is accessible — preventing the startup race that caused intermittent failures when `db.NewAdapter` was called before MySQL finished initializing.

E2e tests in `e2e/create_order_e2e_test.go` use `testcontainers.LocalDockerCompose` pointing at the project's `docker-compose.yml`, create a real `grpc.Dial` connection, and assert that `CustomerId`, `OrderItems`, and status fields survive the full create/retrieve round-trip.

**Cross-case insight:** The two cases are complementary stages of the integration tier. Go for Professionals illustrates the interceptor/TLS isolation principle clearly because its unit tests have no database dependency. Microservices in Go illustrates the infrastructure provisioning pattern because its integration tier has a real database dependency. A service with both interceptors and a database needs both patterns in separate integration test suites.

## A2 — Future Trigger ★

Instead of applying the tier-ownership principle (Go for Professionals) or the testcontainers tooling (Microservices in Go) independently, use this merged skill when:

- Your gRPC service has both an auth interceptor and a database adapter, and you are unsure which tier owns each concern. Map them explicitly: auth rejection belongs in the interceptor integration suite with real TLS credentials; the MySQL adapter belongs in the infrastructure integration suite with `wait.ForSQL`; multi-service flows belong in e2e with `LocalDockerCompose`.
- Your unit tests pass but integration tests are failing intermittently — diagnose by separating interceptor tests (deterministic, no containers) from infrastructure tests (container startup may be the flaky component).
- An auth interceptor bug reached production undetected — add an interceptor integration test that calls the endpoint without credentials and asserts `codes.Unauthenticated`.
- Integration tests are slow because they spin up MySQL containers and the full interceptor chain together — split them into separate suites so the faster interceptor tests can run without waiting for containers.
- You need to add load testing but have no dedicated pipeline stage — add `ghz` as an explicit fourth tier against a deployment, not inside `go test ./...`.

## E — Execution

1. **Define four explicit test tiers in your test plan:**
   - Unit: bufconn, no interceptors, mocks/fakes, insecure credentials
   - Integration (interceptors): full server from `main.go`, real TLS test credentials, bufconn transport
   - Integration (infrastructure): testcontainers + `wait.ForSQL`, real adapter, no gRPC server
   - E2e: `LocalDockerCompose`, real gRPC client, full stack
   - Load: `ghz` against a deployment, separate pipeline stage

2. **Unit tier — endpoint logic only.**

   ```go
   func TestAddTask(t *testing.T) {
       listener := bufconn.Listen(1024 * 1024)
       s := grpc.NewServer() // zero server options — no interceptors, no TLS
       pb.RegisterTodoServiceServer(s, &todoServer{db: &FakeDb{}})
       go s.Serve(listener)

       conn, _ := grpc.DialContext(ctx, "bufnet",
           grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
               return listener.Dial()
           }),
           grpc.WithTransportCredentials(insecure.NewCredentials()),
       )
       client := pb.NewTodoServiceClient(conn)
       // test endpoint logic only
   }
   ```

3. **Integration tier (interceptors) — start the server as `main.go` starts it.**

   ```go
   //go:build integration

   func TestAuthInterceptorRejectsUnauthenticated(t *testing.T) {
       // Load TLS test credentials from testdata/
       creds, _ := credentials.NewServerTLSFromFile("testdata/server.crt", "testdata/server.key")
       s := grpc.NewServer(
           grpc.Creds(creds),
           grpc.ChainUnaryInterceptor(rateLimitInterceptor, authInterceptor, metricsInterceptor),
       )
       pb.RegisterYourServiceServer(s, &yourServer{})
       // ... start on bufconn
       // assert unauthenticated call returns codes.Unauthenticated
   }
   ```

4. **Integration tier (infrastructure) — testcontainers with `wait.ForSQL`.**

   > **Conflict note:** The source book (*gRPC Microservices in Go*) uses `testify/suite` (`SetupSuite`/`TearDownSuite`) for container lifecycle. `summary_rules.md §10` prohibits third-party testing frameworks: "Do not use third-party testing frameworks — use the stdlib `testing` package only." Use `TestMain` for package-wide container lifecycle and `t.Cleanup` for per-test teardown instead:

   ```go
   //go:build integration

   var testAdapter *db.Adapter
   var testContainer testcontainers.Container

   func TestMain(m *testing.M) {
       ctx := context.Background()
       container, _ := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
           ContainerRequest: testcontainers.ContainerRequest{
               Image:        "mysql:8.0.30",
               ExposedPorts: []string{"3306/tcp"},
               WaitingFor:   wait.ForSQL("orders", "mysql", dsn),
           },
           Started: true,
       })
       testContainer = container
       port, _ := container.MappedPort(ctx, "3306/tcp")
       testAdapter = db.NewAdapter(fmt.Sprintf("root:password@tcp(localhost:%s)/orders", port.Port()))
       code := m.Run()
       testContainer.Terminate(ctx)
       os.Exit(code)
   }

   func TestDBAdapter_Save(t *testing.T) {
       // testAdapter is package-level; individual tests use t.Cleanup for
       // any per-test state they set up (e.g., deleting inserted rows)
       order := domain.NewOrder(...)
       err := testAdapter.Save(order)
       if err != nil {
           t.Fatalf("Save: %v", err)
       }
       // assert retrieved state
   }
   ```

5. **E2e tier — `LocalDockerCompose`.**

   ```go
   //go:build e2e

   func (s *E2eSuite) SetupSuite() {
       compose := testcontainers.NewLocalDockerCompose(
           []string{"docker-compose.yml"}, "e2e",
       )
       compose.WithCommand([]string{"up", "-d"}).Invoke()
       s.compose = compose
       // wait for service to be ready, then dial
       s.conn, _ = grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
   }
   ```

6. **Load tier — `ghz` against a deployment.**

   ```sh
   ghz --insecure \
       --proto service.proto \
       --call TodoService.AddTask \
       -d '{"description":"test","due_date":"2026-12-01"}' \
       -n 1000 -c 10 \
       localhost:50051
   ```

   Inspect status-code distribution for unexpected error codes and latency histogram for p99 target.

7. **Use build tags to separate all tiers from `go test ./...`.**

   ```go
   //go:build integration   // interceptor and infrastructure suites
   //go:build e2e           // e2e suite
   ```

   Run in CI with `go test -tags integration ./...` and `go test -tags e2e ./...` as separate pipeline stages. Load tests run in a dedicated deployment pipeline, not in CI unit test runs.

## B — Boundary

**Source A (Go for Professionals) failure modes:**

- Auth interceptor that silently passes all requests — deployed undetected because it was never tested at the integration tier.
- Load tests in shared CI environments produce flaky results from infrastructure contention — run `ghz` against a dedicated deployment.
- If a service has no interceptors, collapsing unit and integration tests is acceptable — this pattern is overhead for simple internal microservices.
- Client-side interceptors require separate testing setup; this skill covers server-side tier ownership.

### Conflicts with Summary_rules.md

**testify/suite prohibition (§10):** The source book uses `testify/suite` (`type DBIntegrationSuite struct { suite.Suite ... }`) for container lifecycle management. `summary_rules.md §10` prohibits third-party testing frameworks. Use `TestMain(m *testing.M)` for package-wide container setup/teardown and `t.Cleanup` for per-test cleanup instead (shown in E section step 4 above).

**mockery prohibition (§10):** The merged skill originally declared mockery-generated mocks and hand-written fakes "both valid." `summary_rules.md §10` does not treat them as equivalent: "Hand-write mocks in a `mock` package. No third-party mock generation tools." Handwritten fakes using function-typed fields are the required form. The I section has been updated to reflect this.

The gRPC testing tier model itself — unit/integration(interceptors)/integration(infrastructure)/e2e/load — is fully compatible with `summary_rules.md`. Only the library choices for lifecycle management and test doubles differ.

**Source B (Microservices in Go) failure modes:**

- `testcontainers.LocalDockerCompose` requires Docker available in CI — ensure the runner has Docker-in-Docker or a socket mount.
- `wait.ForSQL` requires the exact table name to exist at probe time. If the service creates tables via migration at startup, use `wait.ForLog` matching a startup log message instead.
- Container startup adds 10–30 seconds per suite — limit infrastructure integration suites to adapters that actually need real infrastructure. Do not put business logic tests in container suites.
- Keep e2e scenario count small — happy path plus critical failure paths only. A large e2e suite is slow and fragile.
- `mockery`-generated mocks must be regenerated when port interfaces change; commit them to the repository and regenerate as part of the proto generation pipeline.

**Synthesis-specific failure mode:**
A team can write a three-tier test suite and still have: (a) an auth interceptor that was never tested at the integration tier (Go for Professionals failure mode), (b) flaky infrastructure tests from MySQL not being ready (Microservices in Go failure mode), (c) both concerns mixed in a single integration suite — so when either fails, it is unclear whether the cause is a TLS issue or a database startup race. The synthesis-specific failure is the mixed suite: integration tests that require both real credentials and real containers are harder to diagnose than suites that isolate each concern. The solution is explicit separation of the two integration sub-concerns into different test files with different `SetupSuite` implementations.

**Third-tier divergence:** Go for Professionals defines the third tier as `ghz` load testing (performance). Microservices in Go defines it as `LocalDockerCompose` e2e testing (correctness). There is no contradiction — both types of validation are needed above the integration tier. The merged skill treats them as co-equal fourth-tier and top-tier concerns, not as competing definitions of the same tier. If your pipeline can only support one above-integration tier, prioritize `LocalDockerCompose` e2e for correctness validation and schedule `ghz` load testing separately.
