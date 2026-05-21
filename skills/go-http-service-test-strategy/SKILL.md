---
name: go-http-service-test-strategy
allowed-tools: Bash, Read, Edit
id: go-http-service-test-strategy
description: Use when designing the test architecture for a Go HTTP service from scratch, or when evaluating an existing test suite that relies solely on httptest.ResponseRecorder handler tests. Specifically addresses the decision of when to use mock-injection e2e tests (fast, parallel, CI-friendly) vs. real-dependency run()-based integration tests (catches migration bugs, real DB constraints, auth path failures) — and how to combine both tiers.
type: merged-skill
source_skills:
  - slug: lets-go/letsgo-layered-testing
    book: "Let's Go"
    author: Alex Edwards
  - slug: matryer-http-services/matryer-run-e2e-testing
    book: "How I Write HTTP Services in Go After 13 Years"
    author: Mat Ryer
related_skills:
  - slug: lets-go/letsgo-layered-testing
    relation: supersedes
    note: Merged skill adds Ryer's run()-based tier and the decision matrix; use this when choosing between test strategies
  - slug: matryer-http-services/matryer-run-e2e-testing
    relation: supersedes
    note: Merged skill adds Edwards' mock-injection tier and CSRF/session mechanics; use this for complete strategy
tags: []
---

# Go HTTP Service Test Strategy — Two-Tier Full-Stack Testing

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

httptest.ResponseRecorder usage:
!`grep -rn 'httptest\.NewRecorder\|ResponseRecorder' --include='*_test.go' . 2>/dev/null | head -5`

Full-stack test server usage:
!`grep -rn 'httptest\.NewTLSServer\|newTestServer\|newTestApplication' --include='*_test.go' . 2>/dev/null | head -5`

run()-based e2e tests:
!`grep -rn 'go run(' --include='*_test.go' . 2>/dev/null | head -5`

### R — Original Text (Reading)

**Ryer — the case against ResponseRecorder-only tests:**

> "If you do this, you cut out any middleware like auth, and go straight to the handler code. This is nice if there is some specific complexity you want to build some test support around. However, there's an advantage when your test code calls APIs in the same way your users will. I err on the side of end-to-end testing at this level, rather than unit testing all the pieces inside."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*, 2024
>
> "I would rather call the `run` function to execute the whole program as close to how it will run in production as possible. This will parse any arguments, connect to any dependencies, migrate the database, whatever else it will do in the wild, and eventually start up the server. Then when I hit the API from my test code, I am going through all the layers and even interacting with a real database. I am also testing `routes.go` at the same time."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*, 2024
>
> "I will go back and delete tests if they're repeating the same thing as an end-to-end test."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*, 2024

**Edwards — mock-injection e2e tests with the full middleware stack:**

> "For end-to-end tests, we'll use `httptest.NewTLSServer(app.routes())` with mock models injected via `newTestApplication(t)`. The key insight is that because `routes()` returns an `http.Handler`, we can pass the entire middleware stack — including session management and CSRF — into the test server with one line."
>
> — Alex Edwards, *Let's Go*, 2023, Ch. 13

**Convergence note:** Both authors independently concluded that `httptest.ResponseRecorder`-only handler tests are an inferior default because they bypass the middleware chain — the HTTP routing, auth, session, and CSRF layers that users actually traverse. Each advocates for a test that exercises the full HTTP stack. They diverge on exactly one critical dimension: Ryer uses real dependencies (real database, real migrations, real auth via `run()`), which catches integration failures but requires infrastructure; Edwards uses mock injection (in-memory mock models behind the real routing and middleware stack), which is fast and CI-friendly but catches only behavior the mock encodes.

---

### I — Methodological Framework (Interpretation)

Both authors share a foundational judgment: a test that sends a real HTTP request through the full application stack — routing, middleware, handler, response — is more valuable as a default than a test that calls a handler function directly through `ResponseRecorder`. The reason is the middleware chain: auth, session management, CSRF validation, rate limiting, logging, and request parsing all live there. A `ResponseRecorder`-based handler test exercises none of it.

The divergence is on dependency fidelity at the data layer, and it is not a disagreement about which approach is better — it is a disagreement about which problem each approach solves.

**Tier 1: Mock-injection e2e (Edwards).** `newTestApplication(t)` constructs the application with in-memory mock models substituted for the real data layer. `httptest.NewTLSServer(app.routes())` starts a TLS test server with the real middleware stack. Tests make real HTTP requests (with a cookie jar for session continuity), exercise real CSRF validation, real session management, real template rendering — but the database is a controlled, deterministic in-memory fake. This tier is fast, parallel-safe (no port management, no real DB), and CI-friendly (no database container required). It catches bugs in routing, middleware, handler logic, session handling, and response formatting. It does not catch wrong SQL, missing DB indexes, migration failures, or constraint violations.

**Tier 2: Real-dependency e2e (Ryer).** `go run(ctx)` in a test goroutine starts the entire program — argument parsing, dependency connection, database migrations, server startup — exactly as it runs in production. Tests wait for readiness via `/healthz`, then make real HTTP requests using a real `http.Client`. This tier is slower (server startup, real DB connection) and harder to parallelize (port collision risk), but it catches integration failures that the mock-injection tier silently passes: wrong SQL queries, missing migrations, auth middleware bypasses, real constraint violations.

These are not alternatives. They target different failure classes and compose as two tiers in a single test suite.

| Dimension                   | Tier 1: Edwards (mock-injection)                  | Tier 2: Ryer (real dependencies)                       |
| --------------------------- | ------------------------------------------------- | ------------------------------------------------------ |
| DB in tests                 | In-memory mock models                             | Real DB with real migrations                           |
| Speed                       | Fast — in-process, no network                     | Slower — server startup, DB connection                 |
| Parallel safety             | Yes — `httptest.NewTLSServer` uses available port | Requires `net.Listen(":0")` for dynamic port           |
| CI infrastructure           | No DB container needed                            | Requires DB running in CI                              |
| Catches wrong SQL           | No — mock doesn't execute queries                 | Yes — DB raises constraint/syntax errors               |
| Catches migration bugs      | No                                                | Yes — `run()` applies real migrations                  |
| Catches middleware bypasses | Yes — real middleware stack                       | Yes — real middleware stack                            |
| CSRF/session mechanics      | Yes — full nosurf + session state                 | Yes if service uses CSRF; Ryer's examples may not      |
| Test deletion rule          | No explicit guidance                              | Explicit: delete handler unit tests that duplicate e2e |

**The delete-duplicates rule.** Ryer is explicit that once an e2e test covers what a handler unit test already asserts, the handler unit test should be deleted. This reduces maintenance cost: one handler change should require updating one test, not three. Edwards' three-tier model (unit + e2e + integration) does not advocate for deletion. The merged strategy treats deletion as appropriate when a handler test duplicates Tier 1 or Tier 2 coverage — but as a team decision, not a unilateral one.

---

### A1 — Past Application

## R — Original Text (Reading)

**Ryer — the case against ResponseRecorder-only tests:**

> "If you do this, you cut out any middleware like auth, and go straight to the handler code. This is nice if there is some specific complexity you want to build some test support around. However, there's an advantage when your test code calls APIs in the same way your users will. I err on the side of end-to-end testing at this level, rather than unit testing all the pieces inside."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*, 2024
>
> "I would rather call the `run` function to execute the whole program as close to how it will run in production as possible. This will parse any arguments, connect to any dependencies, migrate the database, whatever else it will do in the wild, and eventually start up the server. Then when I hit the API from my test code, I am going through all the layers and even interacting with a real database. I am also testing `routes.go` at the same time."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*, 2024
>
> "I will go back and delete tests if they're repeating the same thing as an end-to-end test."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*, 2024

**Edwards — mock-injection e2e tests with the full middleware stack:**

> "For end-to-end tests, we'll use `httptest.NewTLSServer(app.routes())` with mock models injected via `newTestApplication(t)`. The key insight is that because `routes()` returns an `http.Handler`, we can pass the entire middleware stack — including session management and CSRF — into the test server with one line."
>
> — Alex Edwards, *Let's Go*, 2023, Ch. 13

**Convergence note:** Both authors independently concluded that `httptest.ResponseRecorder`-only handler tests are an inferior default because they bypass the middleware chain — the HTTP routing, auth, session, and CSRF layers that users actually traverse. Each advocates for a test that exercises the full HTTP stack. They diverge on exactly one critical dimension: Ryer uses real dependencies (real database, real migrations, real auth via `run()`), which catches integration failures but requires infrastructure; Edwards uses mock injection (in-memory mock models behind the real routing and middleware stack), which is fast and CI-friendly but catches only behavior the mock encodes.

---

## I — Methodological Framework (Interpretation)

Both authors share a foundational judgment: a test that sends a real HTTP request through the full application stack — routing, middleware, handler, response — is more valuable as a default than a test that calls a handler function directly through `ResponseRecorder`. The reason is the middleware chain: auth, session management, CSRF validation, rate limiting, logging, and request parsing all live there. A `ResponseRecorder`-based handler test exercises none of it.

The divergence is on dependency fidelity at the data layer, and it is not a disagreement about which approach is better — it is a disagreement about which problem each approach solves.

**Tier 1: Mock-injection e2e (Edwards).** `newTestApplication(t)` constructs the application with in-memory mock models substituted for the real data layer. `httptest.NewTLSServer(app.routes())` starts a TLS test server with the real middleware stack. Tests make real HTTP requests (with a cookie jar for session continuity), exercise real CSRF validation, real session management, real template rendering — but the database is a controlled, deterministic in-memory fake. This tier is fast, parallel-safe (no port management, no real DB), and CI-friendly (no database container required). It catches bugs in routing, middleware, handler logic, session handling, and response formatting. It does not catch wrong SQL, missing DB indexes, migration failures, or constraint violations.

**Tier 2: Real-dependency e2e (Ryer).** `go run(ctx)` in a test goroutine starts the entire program — argument parsing, dependency connection, database migrations, server startup — exactly as it runs in production. Tests wait for readiness via `/healthz`, then make real HTTP requests using a real `http.Client`. This tier is slower (server startup, real DB connection) and harder to parallelize (port collision risk), but it catches integration failures that the mock-injection tier silently passes: wrong SQL queries, missing migrations, auth middleware bypasses, real constraint violations.

These are not alternatives. They target different failure classes and compose as two tiers in a single test suite.

| Dimension                   | Tier 1: Edwards (mock-injection)                  | Tier 2: Ryer (real dependencies)                       |
| --------------------------- | ------------------------------------------------- | ------------------------------------------------------ |
| DB in tests                 | In-memory mock models                             | Real DB with real migrations                           |
| Speed                       | Fast — in-process, no network                     | Slower — server startup, DB connection                 |
| Parallel safety             | Yes — `httptest.NewTLSServer` uses available port | Requires `net.Listen(":0")` for dynamic port           |
| CI infrastructure           | No DB container needed                            | Requires DB running in CI                              |
| Catches wrong SQL           | No — mock doesn't execute queries                 | Yes — DB raises constraint/syntax errors               |
| Catches migration bugs      | No                                                | Yes — `run()` applies real migrations                  |
| Catches middleware bypasses | Yes — real middleware stack                       | Yes — real middleware stack                            |
| CSRF/session mechanics      | Yes — full nosurf + session state                 | Yes if service uses CSRF; Ryer's examples may not      |
| Test deletion rule          | No explicit guidance                              | Explicit: delete handler unit tests that duplicate e2e |

**The delete-duplicates rule.** Ryer is explicit that once an e2e test covers what a handler unit test already asserts, the handler unit test should be deleted. This reduces maintenance cost: one handler change should require updating one test, not three. Edwards' three-tier model (unit + e2e + integration) does not advocate for deletion. The merged strategy treats deletion as appropriate when a handler test duplicates Tier 1 or Tier 2 coverage — but as a team decision, not a unilateral one.

---

## A1 — Past Application

### Case 1: Grafana IRM Suite — Real-Dependency E2e via Run() (Ryer)

**Problem:** Grafana OnCall and Grafana Incident are real-database, multi-tenant HTTP APIs. Rather than a handler-by-handler unit test suite, Ryer's team at Grafana Labs built their primary test layer around `run()`.

**Methodology:** Each test calls `run(ctx)` in a goroutine with a cancelled context deferred via `t.Cleanup`. `waitForReady` polls `http://localhost:<port>/healthz` until the server is accepting connections. Tests then make real HTTP requests using a standard `http.Client` — the same network path a production caller uses. Because `run()` also handles argument parsing, environment injection, and database migrations, these tests catch integration failures that a mocked-store test would silently pass: wrong SQL queries, missing migrations, auth middleware bypasses.

**Conclusion:** The test layer documents user interactions, not implementation details. When a handler changes, one test changes — not one handler test plus one integration test plus one unit test.

**Result:** A smaller, more powerful test suite. Handler unit tests are deleted when they duplicate e2e coverage. The `/healthz` readiness endpoint serves double duty: test synchronization and production health monitoring.

---

### Case 2: Let's Go Snippet Application — Mock-Injection E2e with CSRF and Sessions (Edwards)

**Problem:** A Go web application with CSRF-protected POST forms, session management, and multi-step user flows (login → create snippet → redirect). The application uses the `nosurf` middleware for CSRF protection. Tests must exercise the full middleware chain including session tokens and CSRF tokens, but running against a real database is too slow and fragile for CI.

**Methodology:** `newTestApplication(t)` injects in-memory mock models. `newTestServer(t, app.routes())` wraps `httptest.NewTLSServer(app.routes())` with a cookie jar (so sessions persist across requests) and a `CheckRedirect` that stops at the first redirect. A multi-request test flow: GET the login form → extract the CSRF token from the HTML body using `regexp` → POST with the token and `Sec-Fetch-Site: same-origin` header → verify redirect → GET the create-snippet form → extract a second CSRF token → POST the snippet → assert `303 See Other`.

**Conclusion:** The `Sec-Fetch-Site: same-origin` header is the non-obvious requirement: `nosurf` uses it as a secondary CSRF signal. Tests that omit it will fail CSRF validation even with a valid token — and the failure is indistinguishable from a missing-token failure without reading the nosurf source.

**Result:** The test exercises routing, `nosurf` middleware, `scs` session middleware, authentication, template rendering, and redirect logic — all with mock models and no database container. The full middleware stack is tested; the data layer is controlled and deterministic.

---

## A2 — Trigger Scenario ★

Instead of asking "should I unit test my handlers?" (Ryer alone) or "how do I set up tests for a Go web app?" (Edwards alone), use this merged skill when:

**Trigger 1 — Designing a test suite from scratch for a Go HTTP service:** You are starting a new service or establishing the test architecture for an existing one. You need to decide: what tiers do I need, what does each tier cover, and what infrastructure does each tier require?

**Trigger 2 — Your test suite uses only `httptest.ResponseRecorder`:** Every handler has a unit test using `ResponseRecorder`. Middleware is untested. Integration failures (wrong SQL, migration bugs) are invisible. You need to know what to add and what to delete.

**Trigger 3 — CI is failing due to database-related test failures:** Tests that worked with mocks are passing but production is failing on constraint violations, wrong SQL, or migration errors. You need Tier 2 (real-dependency e2e) to catch these.

**Trigger 4 — Choosing between mock injection and real dependencies:** You know you need e2e tests. You need a decision matrix for when to use mock models (Edwards' Tier 1) vs. real infrastructure (Ryer's Tier 2).

**Trigger 5 — CSRF-protected form tests are failing:** Tests that POST to a CSRF-protected endpoint are failing even with a valid token. The missing piece is likely `Sec-Fetch-Site: same-origin`.

**Do NOT use when:**

- Testing pure business logic with no HTTP layer (no test server needed — call the function directly).
- The question is about a non-Go language (this skill is Go-specific: `httptest`, `go test`, `run()`).
- The user is asking about load testing, chaos testing, or contract testing between services — those require different tools.

---

## E — Execution Steps

### Tier 1: Mock-Injection E2e (Edwards — Fast Parallel Suite, CI-Friendly)

## Step 1: Design the Application Struct for Dependency Injection

Ensure the `application` struct (or equivalent) holds interface-typed fields for its dependencies (database models, email sender, etc.). This is what makes mock substitution possible.

```go
type application struct {
    snippets models.SnippetModelInterface
    users    models.UserModelInterface
    logger   *slog.Logger
    // ...
}
```

## Step 2: Implement Mock Models

Create `internal/models/mocks/` with one mock file per model interface. Implement the same method signatures using hard-coded test fixtures and in-memory state.

```go
type MockSnippetModel struct{}

func (m *MockSnippetModel) Insert(title, content string, expires int) (int, error) {
    return 2, nil
}
func (m *MockSnippetModel) Get(id int) (models.Snippet, error) {
    if id == 1 {
        return mockSnippet, nil
    }
    return models.Snippet{}, models.ErrNoRecord
}
```

**Step 3: Create `newTestApplication(t)`**

```go
func newTestApplication(t *testing.T) *application {
    templateCache, err := newTemplateCache()
    if err != nil {
        t.Fatal(err)
    }
    return &application{
        logger:        slog.New(slog.NewTextHandler(io.Discard, nil)),
        snippets:      &mocks.MockSnippetModel{},
        users:         &mocks.MockUserModel{},
        templateCache: templateCache,
        sessionManager: scs.New(),
    }
}
```

**Step 4: Create `newTestServer(t, h)` wrapping `httptest.NewTLSServer`**

```go
type testServer struct{ *httptest.Server }

func newTestServer(t *testing.T, h http.Handler) *testServer {
    ts := httptest.NewTLSServer(h)
    jar, err := cookiejar.New(nil)
    if err != nil {
        t.Fatal(err)
    }
    ts.Client().Jar = jar
    ts.Client().CheckRedirect = func(req *http.Request, via []*http.Request) error {
        return http.ErrUseLastResponse
    }
    t.Cleanup(ts.Close)
    return &testServer{ts}
}
```

**Step 5: Add `get()` and `postForm()` helpers; set `Sec-Fetch-Site` on POST**

```go
func (ts *testServer) postForm(t *testing.T, urlPath string, form url.Values) (int, http.Header, string) {
    req, err := http.NewRequest(http.MethodPost, ts.URL+urlPath,
        strings.NewReader(form.Encode()))
    if err != nil {
        t.Fatal(err)
    }
    req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
    req.Header.Set("Sec-Fetch-Site", "same-origin") // required by nosurf
    // ...
}
```

**Step 6: Add `extractCSRFToken(t, body)` for CSRF-protected forms**

```go
func extractCSRFToken(t *testing.T, body string) string {
    t.Helper()
    re := regexp.MustCompile(`<input type='hidden' name='csrf_token' value='(.+?)'>`)
    matches := re.FindStringSubmatch(body)
    if len(matches) < 2 {
        t.Fatal("no csrf token found in body")
    }
    return html.UnescapeString(matches[1])
}
```

**Step 7 (conditional — integration layer):** If model SQL correctness matters, add `newTestDB(t)` that opens a real connection, runs `testdata/setup.sql`, and registers `t.Cleanup` to run `testdata/teardown.sql`. This is a separate integration test tier, not part of the fast e2e suite.

---

### Tier 2: Real-Dependency E2e via Run() (Ryer — Catches Integration Failures)

**Step 1: Ensure `run()` accepts a `context.Context`**

```go
func run(ctx context.Context, args []string, stdout, stderr io.Writer) error {
    // parse args, connect to DB, run migrations, start server
}
```

**Step 2: Add `/healthz` to your routes**

```go
mux.HandleFunc("/healthz", handleHealthzPlease(logger))
```

The handler returns 200 OK when the service is up and dependencies are reachable.

**Step 3: Implement `waitForReady`**

```go
func waitForReady(ctx context.Context, timeout time.Duration, endpoint string) error {
    client := http.Client{}
    startTime := time.Now()
    for {
        req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
        if err != nil {
            return fmt.Errorf("failed to create request: %w", err)
        }
        resp, err := client.Do(req)
        if err != nil {
            continue
        }
        if resp.StatusCode == http.StatusOK {
            resp.Body.Close()
            return nil
        }
        resp.Body.Close()
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            if time.Since(startTime) >= timeout {
                return fmt.Errorf("timeout reached while waiting for endpoint")
            }
            time.Sleep(250 * time.Millisecond)
        }
    }
}
```

## Step 4: Write the E2e Test Scaffold

```go
func TestCreateUser(t *testing.T) {
    ctx, cancel := context.WithCancel(context.Background())
    t.Cleanup(cancel)

    go run(ctx, []string{}, os.Stdout, os.Stderr)

    err := waitForReady(ctx, 5*time.Second, "http://localhost:8080/healthz")
    if err != nil {
        t.Fatalf("server did not become ready: %v", err)
    }

    resp, err := http.Post(
        "http://localhost:8080/api/v1/users",
        "application/json",
        strings.NewReader(`{"name":"alice"}`),
    )
    if err != nil {
        t.Fatalf("request failed: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusCreated {
        t.Errorf("want 201, got %d", resp.StatusCode)
    }
}
```

## Step 5: Identify and Delete Handler Unit Tests That Duplicate Tier 1 or Tier 2 Coverage

For each handler unit test, ask:

- Does it assert the same status code, body, or headers already asserted by a Tier 1 or Tier 2 test?
- Does it exercise a code path that either tier would reach?

If yes to both: delete it. Retain handler unit tests only for code paths that neither tier can practically reach (obscure error branches, complex parsing logic worth TDD before the server is up).

---

## B — Boundaries and Failure Modes

### Tier 1 Failures (Edwards — Mock-Injection E2e)

- **Mock drift:** Mock models must stay in sync with real model interfaces. When a model method is added or its signature changes, the mock must be updated manually. Drift causes false-positive test results — the test passes because the mock's old behavior is exercised, but the real data layer behaves differently.
- **TLS verification disabled:** `httptest.NewTLSServer` uses a self-signed certificate. The test HTTP client must disable TLS verification (`ts.Client()` returns a pre-configured client; do not use `http.DefaultClient`).
- **Mocks cannot catch data-layer bugs:** Wrong SQL queries, missing indexes, migration errors, and real constraint violations are invisible to mock-injection tests. If the mock's `Insert` always returns `nil`, a real DB `INSERT` that fails due to a missing NOT NULL column will not be caught until Tier 2 or production.
- **Does not cover real external services:** Email sending, payment processors, third-party APIs — these require separate integration environments.

### Tier 2 Failures (Ryer — Real-Dependency E2e via Run())

- **Port collision in parallel tests:** When `t.Parallel()` is used, multiple `run()` goroutines compete for the same port. Use `net.Listen("tcp", ":0")` to get a random available port; pass the listener (or derived port) into `run()` and derive the base URL per test.
- **Database state contamination:** Each e2e test hits a real database. Without isolation, test order becomes load-bearing and failures become mysterious. Use isolated schemas per test, or clean up data in `t.Cleanup`.
- **Test speed:** Starting `run()` per test is measurably slower than an in-process `ResponseRecorder` call. For large suites, consider one shared server instance for all tests in the package, trading isolation for startup time.
- **"Delete unit tests" is a team decision:** Ryer explicitly notes this depends on the opinions of those around you. On teams where unit tests are a code review requirement or CI gate, propose the change explicitly before deleting tests.

### Synthesis-Specific Failure Mode

- **Running only one tier and believing you have complete coverage:** A suite with only Tier 1 (mock-injection) has no coverage of SQL correctness, migration correctness, or real constraint enforcement. A suite with only Tier 2 (real-dependency) is slower, harder to parallelize, and more brittle due to infrastructure dependencies — it is not an appropriate primary CI suite. The failure mode is choosing one tier and considering the strategy complete. The merged strategy requires deliberate allocation: Tier 1 for the broad fast suite; Tier 2 for the small number of critical integration paths where real infrastructure correctness matters.

### Contradiction to Surface Explicitly

Ryer explicitly advocates deleting handler unit tests that duplicate e2e coverage. Edwards presents a three-tier model (unit + e2e + integration) without advocating for test deletion. These cannot be fully reconciled. The merged strategy surfaces this as a team governance decision: the deletion rule reduces maintenance cost and is technically sound, but it requires explicit team alignment before execution. On teams where unit test coverage is a CI gate or code review requirement, the deletion rule cannot be applied unilaterally.

---

## Related Skills

- **lets-go/letsgo-layered-testing** — superseded-by: this merged skill; source skill remains useful for Let's Go-specific setup details (CSRF extraction pattern, template cache, session manager configuration)
- **matryer-http-services/matryer-run-e2e-testing** — superseded-by: this merged skill; source skill remains useful for run()-specific details (waitForReady implementation, getenv injection for parallel safety)
- **matryer-http-services/matryer-run-function** — depends-on (Tier 2): `run()` is the mechanism that makes Tier 2 testing possible; the run-function skill defines the signature and contract
- **matryer-http-services/matryer-waitfor-ready** — depends-on (Tier 2): `waitForReady` is required before any assertions; the skill provides the full implementation
- **lets-go/letsgo-application-struct-di** — depends-on (Tier 1): `newTestApplication(t)` is only possible because the application struct accepts interface-typed fields; the DI struct design enables mock injection
- **lets-go/letsgo-middleware-composition** — depends-on (Tier 1): `routes()` returning `http.Handler` is the design decision that enables `httptest.NewTLSServer(app.routes())` to exercise the full middleware stack in one line

---

## Audit Information

- **Phase 1 verdict:** ADVANCE (all four gates passed)
- **V1 (genuine convergence):** PASS — two independent authors (Edwards 2023, Ryer 2024) independently concluded that ResponseRecorder-only tests are the wrong default and full-HTTP-stack tests are better
- **V2 (novel questions answered):** PASS — merged skill provides the decision matrix "when to use mock injection vs. real dependencies" that neither source alone supplies
- **V3 (non-obvious synthesis):** PASS — the two-tier composition, the CSRF Sec-Fetch-Site requirement, and the side-by-side decision matrix are not documented together anywhere in the Go ecosystem
- **V4 (sharper A2):** PASS — merged A2 answers "what combination of test layers do I need, when do I use mock models vs. real dependencies, what infrastructure does each tier require?" — the complete strategy question that requires both books
- **Note on Edwards R-quote accuracy:** The Let's Go source is an epub; R-section quotes are paraphrased/reconstructed as flagged in pair-028-phase1.md §Phase 1.5. Verbatim accuracy cannot be confirmed without epub text extraction. Code examples are concrete and verifiable.
- **Merge date:** 2026-05-05
