---
name: matryer-waitfor-ready
description: |
  When a test starts a server in a goroutine via `run()`, there is a race: the test can send
  requests before the server is listening. The idiomatic fix is not a channel or a sleep — it
  is a `/healthz` or `/readyz` HTTP endpoint plus a `waitForReady` helper that polls until a
  200 response arrives or the context is cancelled. This doubles as a production health-check
  used by Kubernetes probes, load-balancer checks, and orchestrators, so the test requirement
  surfaces a feature the production system needs anyway.
tags: [go, testing, health-checks, readiness, http-services, e2e-testing]
---

# Wait for Readiness via a Health Endpoint

## R — Original Text (Reading)

> Since the `run` function executes in a goroutine, we don't really know exactly when it's
> going to start up. If we're going to start hitting the API like real users, we are going to
> need to know when it's ready.
>
> We could set up some way of signalling readiness, like a channel or something — but I prefer
> to have a `/healthz` or `/readyz` endpoint running on the server. As my old grandma used to
> say, the proof of the pudding is in the actual HTTP requests (she was way ahead of her time).
>
> This is an example where our efforts to make the code more testable gives us an insight into
> what our users will need. They probably want to know if the service is ready or not as well,
> so why not have an official way to find this out?

The accompanying `waitForReady` implementation:

```go
// waitForReady calls the specified endpoint until it gets a 200
// response or until the context is cancelled or the timeout is
// reached.
func waitForReady(
	ctx context.Context,
	timeout time.Duration,
	endpoint string,
) error {
	client := http.Client{}
	startTime := time.Now()
	for {
		req, err := http.NewRequestWithContext(
			ctx,
			http.MethodGet,
			endpoint,
			nil,
		)
		if err != nil {
			return fmt.Errorf("failed to create request: %w", err)
		}

		resp, err := client.Do(req)
		if err != nil {
			fmt.Printf("Error making request: %s\n", err.Error())
			continue
		}
		if resp.StatusCode == http.StatusOK {
			fmt.Println("Endpoint is ready!")
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
			// wait a little while between checks
			time.Sleep(250 * time.Millisecond)
		}
	}
}
```

And the route registration that makes `/healthz` available:

```go
mux.HandleFunc("/healthz", handleHealthzPlease(logger))
```

## I — Methodological Framework (Interpretation)

### The Core Problem

`go run(ctx)` returns immediately. The TCP listener inside `run` is not yet bound. Any test
that immediately dials the server will get `connection refused`. Two naive fixes are common:

- `time.Sleep(100 * time.Millisecond)` — brittle on slow CI; wastes time on fast machines.
- A dedicated channel that `run` closes once the listener is up — leaks test-only logic into
  production code and does not validate the HTTP path.

### The Preferred Fix: Poll the Health Endpoint

Register a real HTTP endpoint (`/healthz` or `/readyz`) that returns `200 OK` when the server
is ready to accept traffic. In `waitForReady`:

1. Loop, making a real `GET` with the test's context attached.
2. On `200`, return `nil` — server is ready.
3. On transport error (connection refused, etc.), continue immediately — server not up yet.
4. On non-200 status, back off and retry.
5. On `ctx.Done()` or elapsed timeout, surface the error — something is wrong.

### Why Polling the HTTP Endpoint Is Better Than a Channel

| Concern                              | Channel signal                   | HTTP poll                           |
| ------------------------------------ | -------------------------------- | ----------------------------------- |
| Validates TCP listener is bound      | No — only signals internal state | Yes                                 |
| Validates HTTP stack is routing      | No                               | Yes                                 |
| Produces a production feature        | No                               | Yes — k8s liveness/readiness probes |
| Keeps test concerns out of prod code | No — channel lives in run()      | Yes — /healthz is a real route      |
| Catches misconfigured route table    | No                               | Yes                                 |

### The Design Insight

Ryer states it plainly: the test requirement and the production requirement are the same
question — "is this service accepting traffic?" Answering it once, with a real HTTP endpoint,
satisfies both callers. This is the principle that designing for testability gives you insight
into what your users will need.

### Anatomy of `waitForReady`

- **Signature**: `ctx context.Context, timeout time.Duration, endpoint string` — all
  externally supplied; no globals, fully testable.
- **Context propagation**: `http.NewRequestWithContext` ensures the HTTP call respects
  cancellation, not just the outer select.
- **Timeout vs cancellation**: both are checked — the passed context (cancelled by
  `t.Cleanup`) and an explicit wall-clock timeout guard against hanging tests.
- **250 ms sleep**: only taken after a non-200 response to avoid hammering the server. On a
  connection-refused error the loop continues immediately because the server may be up on the
  very next iteration.

## A1 — Past Application (From the Book)

Ryer shows the canonical test harness pattern in full:

```go
func Test(t *testing.T) {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	t.Cleanup(cancel)
	go run(ctx)
	// waitForReady would be called here before hitting the API
}
```

The route table always includes `/healthz`:

```go
func addRoutes(
	mux *http.ServeMux,
	logger *logging.Logger,
	config Config,
	// ... other dependencies
) {
	mux.Handle("/api/v1/", handleTenantsGet(logger, tenantsStore))
	mux.HandleFunc("/healthz", handleHealthzPlease(logger))
	mux.Handle("/", http.NotFoundHandler())
}
```

The `handleHealthzPlease` handler is intentionally trivial — its only job is to return `200 OK`. The value is not in the handler logic; it is in the fact that a real round-trip over TCP
and through the HTTP mux had to succeed for the test to proceed.

## A2 — Trigger Scenario (Future Trigger) ★

You are writing an end-to-end test for a Go HTTP service. The test calls `go run(ctx)` to
start the server, then immediately constructs an HTTP client and calls an endpoint. On your
laptop it works. In CI it fails intermittently with `connection refused`. A teammate adds
`time.Sleep(200 * time.Millisecond)` and the flakiness drops but does not disappear.

Apply this skill when you see any of:

- `time.Sleep` used to "wait for the server to start" in test setup.
- A dedicated channel, `sync.WaitGroup`, or boolean flag added to `run()` solely to signal
  that the server has started.
- Flaky tests where the first request after `go run(ctx)` occasionally fails.
- An HTTP service that lacks a `/healthz` or `/readyz` route.
- A service being deployed to Kubernetes without liveness or readiness probes configured.

## E — Execution Steps

### Step 1 — Register the Health Endpoint

In `addRoutes` (or wherever routes are declared), add:

```go
mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
})
```

For production use, `handleHealthzPlease` can log or check downstream dependencies; for the
basic readiness contract a `200` is sufficient.

### Step 2 — Add the `waitForReady` Helper

Place this in a test helper file (e.g., `helpers_test.go` or `testutil/ready.go`):

```go
func waitForReady(
	ctx context.Context,
	timeout time.Duration,
	endpoint string,
) error {
	client := http.Client{}
	startTime := time.Now()
	for {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
		if err != nil {
			return fmt.Errorf("failed to create request: %w", err)
		}
		resp, err := client.Do(req)
		if err != nil {
			// server not up yet — keep trying
			select {
			case <-ctx.Done():
				return ctx.Err()
			default:
				if time.Since(startTime) >= timeout {
					return fmt.Errorf("timeout reached while waiting for endpoint")
				}
				time.Sleep(250 * time.Millisecond)
				continue
			}
		}
		resp.Body.Close()
		if resp.StatusCode == http.StatusOK {
			return nil
		}
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

### Step 3 — Call `waitForReady` in Test Setup

```go
func TestAPI(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)

	go run(ctx, os.Stdout, []string{})

	addr := "http://localhost:8080"
	if err := waitForReady(ctx, 5*time.Second, addr+"/healthz"); err != nil {
		t.Fatalf("server did not become ready: %v", err)
	}

	// Now hit API endpoints — server is definitely accepting traffic
}
```

### Step 4 — Parameterise the Address

If the server binds to a random port (preferred for parallel tests), capture the address
from `run` before passing it to `waitForReady`:

```go
// run returns the bound address, e.g. "http://127.0.0.1:34521"
addr, err := run(ctx, os.Stdout, []string{"--addr=:0"})
if err != nil {
	t.Fatal(err)
}
if err := waitForReady(ctx, 5*time.Second, addr+"/healthz"); err != nil {
	t.Fatalf("server not ready: %v", err)
}
```

### Step 5 — Wire up Production Health Checks

Point Kubernetes liveness/readiness probes at the same endpoint:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 2
  periodSeconds: 5
```

No separate implementation is needed — the endpoint introduced for the test is the production
health-check.

## B — Boundaries and Blind Spots

**When `/healthz` returning 200 is not enough**
A `200` from `/healthz` means the HTTP server is accepting connections. It does not mean the
database is connected, the cache is warm, or downstream services are reachable. For deep
readiness, `/readyz` should check critical dependencies and return a non-200 until they are
available.

**Random port binding**
`waitForReady` requires the server's address. If `run` binds to `:0`, the chosen port must
be communicated back to the test. One approach: return the address from `run`; another: use
`net.Listen` outside `run` and pass the listener in.

**Parallel tests**
Multiple tests calling `go run(ctx)` simultaneously will fight over fixed ports. Use `:0`
(random port) and give each test its own address to avoid flakiness in `go test -parallel`.

**`waitForReady` does not belong in production binaries**
It is a test utility. Keep it in `_test.go` files or a `testutil` package that is not imported
by the main binary.

**The 250 ms sleep is a floor, not a ceiling**
On very slow startup (database migrations, large config loads) the 250 ms backoff may cause
the loop to burn through the timeout before the server is ready. Tune `timeout` to reflect
actual startup time, not a guess.

**Context cancellation vs timeout**
The test context is cancelled by `t.Cleanup(cancel)` — which fires after the test ends, not
during setup. If `waitForReady` is called before the server starts at all (e.g., `run` fails
silently), the timeout parameter is the only guard. Always set a meaningful timeout
(5–15 seconds for typical services).

**Do not use `waitForReady` to replace liveness in production**
The Kubernetes probe and `waitForReady` share the same endpoint, but they are not the same
thing. `waitForReady` is a one-shot polling loop for test synchronisation. The k8s probe runs
continuously throughout the pod's lifetime.

## Related Skills

- **matryer-run-function** — depends-on: the server that `waitForReady` polls is started in a goroutine by `run()`; without the `run()` pattern there is no in-process server to wait for.
- **matryer-run-e2e-testing** — required-by: e2e tests that call `go run(ctx)` must call `waitForReady` before making assertions; it is the synchronisation primitive that makes the e2e pattern race-free.

______________________________________________________________________

## Provenance

- **Source:** "How I Write HTTP Services in Go After 13 Years" — Mat Ryer (2024) — Designing for testability — Waiting for readiness
