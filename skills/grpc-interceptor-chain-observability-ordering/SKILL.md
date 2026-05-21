---
name: grpc-interceptor-chain-observability-ordering
allowed-tools: Bash, Read, Edit
id: grpc-interceptor-chain-observability-ordering
description: >
  Invoke when composing multiple gRPC server interceptors into a production chain,
  particularly when combining security interceptors (auth, rate-limit) with
  observability interceptors (Prometheus, logging). Key trigger: "error-rate alerts
  are firing but only during auth attack traffic" or "where does auth go in the chain
  relative to metrics?" The canonical order is rate-limit → auth → metrics → logging.
  Auth before metrics is operationally critical: unauthenticated requests must not
  inflate Prometheus error-rate counters and trigger false alerts on real-service SLOs.
type: merged-skill
source_skills:
  - slug: grpc-go-for-professionals/grpc-interceptor-composition
    book: "gRPC Go for Professionals"
    author: Clément Jean
  - slug: grpc-up-and-running/grpc-observability-three-pillar
    book: "gRPC: Up and Running"
    author: Kasun Indrasiri and Danesh Kuruppu
related_skills:
  - slug: grpc-go-for-professionals/grpc-interceptor-composition
    relation: supersedes
    note: Covers chain ordering mechanics without full observability interceptor wiring.
  - slug: grpc-up-and-running/grpc-observability-three-pillar
    relation: supersedes
    note: Covers observability interceptors without auth positioning or ordering consequences.
tags: []
---

# gRPC Interceptor Chain — Canonical Ordering for Observability and Security Correctness

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Interceptor chain registrations:
!`grep -rn 'ChainUnaryInterceptor\|ChainStreamInterceptor\|grpc\.UnaryInterceptor(' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -10`

### R — Reading

> "Note that the order of these interceptors is important because they will be called
> in the order provided in the grpc.ChainUnaryInterceptor function... gRPC accepts only
> one call of grpc.UnaryInterceptor and grpc.StreamInterceptor. We can now merge, in
> server/main.go, two Interceptors of the same type (unary or stream) like so:
> opts := []grpc.ServerOption{grpc.ChainUnaryInterceptor(unaryAuthInterceptor,
> unaryLogInterceptor), grpc.ChainStreamInterceptor(streamAuthInterceptor,
> streamLogInterceptor)}"

*gRPC Go for Professionals, Ch. 7 and Ch. 8* (Jean)

> "When talking about observability, there are three main pillars that we normally talk
> about: metrics, logging, and tracing. It's better to have all three pillars enabled
> in your system to gain maximum visibility of the internal state."

*gRPC: Up and Running, Ch. 7 — Running gRPC in Production* (Indrasiri & Kuruppu)

**Convergence note:** Both books independently endorse `grpc.ChainUnaryInterceptor` as the correct mechanism for stacking multiple server interceptors — Go for Professionals (TODO service, Ch. 7–8) and Up and Running (ProductInfo service, Ch. 7). What each adds uniquely: Go for Professionals provides the ordering constraint and its operational consequence (auth before metrics is a correctness requirement, not a style preference), while Up and Running provides the specific observability interceptors that populate the chain (Prometheus, zap, OTel) and their initialization requirements.

### I — Interpretation

**The single-registration constraint.** gRPC-go silently enforces a limit of one registered unary interceptor and one registered stream interceptor per server. Calling `grpc.UnaryInterceptor` more than once silently overwrites the previous registration — no compile error, no runtime panic, no log warning. The only safe mechanism for multiple interceptors is `grpc.ChainUnaryInterceptor` and `grpc.ChainStreamInterceptor`, which combine any number of interceptors into one registered function.

**The bidirectional execution model.** Interceptors execute left-to-right on the request path (first argument runs first, wrapping all subsequent ones) and right-to-left on the response path. The outermost interceptor on the request path is also the outermost on the response path. This means the first interceptor in the chain sees the raw incoming request before any processing, and sees the final outgoing response after all processing.

**The canonical production ordering: `rate-limit → auth → metrics → logging`.**

- **Rate-limit first:** Sheds load before any expensive work. A request rejected by the rate limiter never reaches auth logic, never allocates tokens, never generates log lines.
- **Auth second:** Unauthenticated requests are rejected before reaching metric counters. This is not merely stylistic — it is operationally consequential (see below).
- **Metrics third:** Records the request after it has been authenticated. Counters reflect real service traffic only.
- **Logging last:** After auth context and correlation IDs have been attached by upstream interceptors, so log lines carry full request identity and authenticated user context.

**Why auth before metrics is operationally critical.** Prometheus error-rate counters (`grpc_server_handled_total{grpc_code="UNAUTHENTICATED"}`) are typically included in error-rate alerts. During an authentication attack — a burst of requests with invalid tokens — if metrics is registered before auth in the chain, every rejected request increments the Prometheus error counter. The alert fires, on-call engineers are paged, and the incident response begins for what is actually normal system behavior (the auth interceptor is working correctly, rejecting attackers). By placing auth before metrics, unauthenticated requests never reach the metrics interceptor and do not appear in Prometheus counters at all. The alert fires only when real authenticated requests fail — which is the signal the alert is intended to convey.

**The three observability interceptors and their initialization.** The chain populates from Up and Running:

- **Prometheus (`grpc_prometheus`):** `grpcMetrics.UnaryServerInterceptor()` — records request counts, in-flight counts, and latency histograms per method and status code. Call `grpcMetrics.InitializeMetrics(s)` after service registration to pre-populate label combinations so zero-value metrics are visible from the first scrape.
- **Structured logging (`grpc_zap` or `grpc_logrus`):** Emits one structured log line per RPC containing method, peer address, duration, and status code.
- **Tracing (OpenTelemetry):** `otelgrpc.NewServerHandler()` as a `grpc.StatsHandler` — not a chain interceptor. Injects distributed trace context and propagates `TraceID`/`SpanID` via gRPC metadata to downstream calls.

Note: OTel uses the stats handler API, not the interceptor API, because it needs access to lower-level transport events. Tracing does not participate in the `ChainUnaryInterceptor` ordering.

**The full production chain:**

```go
s := grpc.NewServer(
    grpc.StatsHandler(otelgrpc.NewServerHandler()),  // OTel — outside the chain
    grpc.ChainUnaryInterceptor(
        rateLimitInterceptor,
        authInterceptor,
        grpcMetrics.UnaryServerInterceptor(),
        grpc_zap.UnaryServerInterceptor(zapLogger),
    ),
    grpc.ChainStreamInterceptor(
        rateLimitStreamInterceptor,
        authStreamInterceptor,
        grpcMetrics.StreamServerInterceptor(),
        grpc_zap.StreamServerInterceptor(zapLogger),
    ),
)
pb.RegisterYourServiceServer(s, &yourServer{})
grpcMetrics.InitializeMetrics(s)
```

Three-Pillar (Up and Running) shows the observability chain in isolation — metrics before zap, no auth. Interceptor-Composition (Go for Professionals) shows the auth+metrics chain. The merged ordering is not a conflict between these: Three-Pillar describes the observability sub-chain; Interceptor-Composition describes the full production chain including security. The merged ordering inserts auth in its correct position relative to the observability interceptors that Three-Pillar provides.

### A1 — Past Application

## R — Reading

> "Note that the order of these interceptors is important because they will be called
> in the order provided in the grpc.ChainUnaryInterceptor function... gRPC accepts only
> one call of grpc.UnaryInterceptor and grpc.StreamInterceptor. We can now merge, in
> server/main.go, two Interceptors of the same type (unary or stream) like so:
> opts := []grpc.ServerOption{grpc.ChainUnaryInterceptor(unaryAuthInterceptor,
> unaryLogInterceptor), grpc.ChainStreamInterceptor(streamAuthInterceptor,
> streamLogInterceptor)}"

*gRPC Go for Professionals, Ch. 7 and Ch. 8* (Jean)

> "When talking about observability, there are three main pillars that we normally talk
> about: metrics, logging, and tracing. It's better to have all three pillars enabled
> in your system to gain maximum visibility of the internal state."

*gRPC: Up and Running, Ch. 7 — Running gRPC in Production* (Indrasiri & Kuruppu)

**Convergence note:** Both books independently endorse `grpc.ChainUnaryInterceptor` as the correct mechanism for stacking multiple server interceptors — Go for Professionals (TODO service, Ch. 7–8) and Up and Running (ProductInfo service, Ch. 7). What each adds uniquely: Go for Professionals provides the ordering constraint and its operational consequence (auth before metrics is a correctness requirement, not a style preference), while Up and Running provides the specific observability interceptors that populate the chain (Prometheus, zap, OTel) and their initialization requirements.

## I — Interpretation

**The single-registration constraint.** gRPC-go silently enforces a limit of one registered unary interceptor and one registered stream interceptor per server. Calling `grpc.UnaryInterceptor` more than once silently overwrites the previous registration — no compile error, no runtime panic, no log warning. The only safe mechanism for multiple interceptors is `grpc.ChainUnaryInterceptor` and `grpc.ChainStreamInterceptor`, which combine any number of interceptors into one registered function.

**The bidirectional execution model.** Interceptors execute left-to-right on the request path (first argument runs first, wrapping all subsequent ones) and right-to-left on the response path. The outermost interceptor on the request path is also the outermost on the response path. This means the first interceptor in the chain sees the raw incoming request before any processing, and sees the final outgoing response after all processing.

**The canonical production ordering: `rate-limit → auth → metrics → logging`.**

- **Rate-limit first:** Sheds load before any expensive work. A request rejected by the rate limiter never reaches auth logic, never allocates tokens, never generates log lines.
- **Auth second:** Unauthenticated requests are rejected before reaching metric counters. This is not merely stylistic — it is operationally consequential (see below).
- **Metrics third:** Records the request after it has been authenticated. Counters reflect real service traffic only.
- **Logging last:** After auth context and correlation IDs have been attached by upstream interceptors, so log lines carry full request identity and authenticated user context.

**Why auth before metrics is operationally critical.** Prometheus error-rate counters (`grpc_server_handled_total{grpc_code="UNAUTHENTICATED"}`) are typically included in error-rate alerts. During an authentication attack — a burst of requests with invalid tokens — if metrics is registered before auth in the chain, every rejected request increments the Prometheus error counter. The alert fires, on-call engineers are paged, and the incident response begins for what is actually normal system behavior (the auth interceptor is working correctly, rejecting attackers). By placing auth before metrics, unauthenticated requests never reach the metrics interceptor and do not appear in Prometheus counters at all. The alert fires only when real authenticated requests fail — which is the signal the alert is intended to convey.

**The three observability interceptors and their initialization.** The chain populates from Up and Running:

- **Prometheus (`grpc_prometheus`):** `grpcMetrics.UnaryServerInterceptor()` — records request counts, in-flight counts, and latency histograms per method and status code. Call `grpcMetrics.InitializeMetrics(s)` after service registration to pre-populate label combinations so zero-value metrics are visible from the first scrape.
- **Structured logging (`grpc_zap` or `grpc_logrus`):** Emits one structured log line per RPC containing method, peer address, duration, and status code.
- **Tracing (OpenTelemetry):** `otelgrpc.NewServerHandler()` as a `grpc.StatsHandler` — not a chain interceptor. Injects distributed trace context and propagates `TraceID`/`SpanID` via gRPC metadata to downstream calls.

Note: OTel uses the stats handler API, not the interceptor API, because it needs access to lower-level transport events. Tracing does not participate in the `ChainUnaryInterceptor` ordering.

**The full production chain:**

```go
s := grpc.NewServer(
    grpc.StatsHandler(otelgrpc.NewServerHandler()),  // OTel — outside the chain
    grpc.ChainUnaryInterceptor(
        rateLimitInterceptor,
        authInterceptor,
        grpcMetrics.UnaryServerInterceptor(),
        grpc_zap.UnaryServerInterceptor(zapLogger),
    ),
    grpc.ChainStreamInterceptor(
        rateLimitStreamInterceptor,
        authStreamInterceptor,
        grpcMetrics.StreamServerInterceptor(),
        grpc_zap.StreamServerInterceptor(zapLogger),
    ),
)
pb.RegisterYourServiceServer(s, &yourServer{})
grpcMetrics.InitializeMetrics(s)
```

Three-Pillar (Up and Running) shows the observability chain in isolation — metrics before zap, no auth. Interceptor-Composition (Go for Professionals) shows the auth+metrics chain. The merged ordering is not a conflict between these: Three-Pillar describes the observability sub-chain; Interceptor-Composition describes the full production chain including security. The merged ordering inserts auth in its correct position relative to the observability interceptors that Three-Pillar provides.

## A1 — Past Application

### Case 1: TODO Service — Interceptor Chain Incremental Build

The book *gRPC Go for Professionals* builds the TODO service interceptor chain across Ch. 7 and Ch. 8. Ch. 7 introduces the initial chain: `grpc.ChainUnaryInterceptor(unaryAuthInterceptor, unaryLogInterceptor)`. Ch. 8 extends it incrementally with metrics (grpc-prometheus) and OTel. The auth interceptor reads `metadata.FromIncomingContext`, extracts the authorization token, validates it with `validateAuthToken`, and returns `codes.Unauthenticated` on failure.

The counter-example motivating the auth-before-metrics rule: when metrics is registered before auth, a burst of requests with invalid tokens increments `grpc_server_handled_total{grpc_code="UNAUTHENTICATED"}` — firing the error-rate alert on authentication attack traffic rather than real service errors. The correct chain ensures unauthenticated requests exit at the auth interceptor before the metrics interceptor sees them.

### Case 2: ProductInfo Service — Observability-Only Chain

The book *gRPC: Up and Running* instruments the `ProductInfo` service (Ch. 7) with the observability sub-chain only (no auth interceptor shown in this chapter):

```go
grpcMetrics := grpc_prometheus.NewServerMetrics()
zapLogger, _ := zap.NewProduction()

s := grpc.NewServer(
    grpc.StatsHandler(otelgrpc.NewServerHandler()),
    grpc.ChainUnaryInterceptor(
        grpcMetrics.UnaryServerInterceptor(),
        grpc_zap.UnaryServerInterceptor(zapLogger),
    ),
    grpc.ChainStreamInterceptor(
        grpcMetrics.StreamServerInterceptor(),
        grpc_zap.StreamServerInterceptor(zapLogger),
    ),
)
pb.RegisterProductInfoServer(s, &productInfoServer{})
grpcMetrics.InitializeMetrics(s)
http.Handle("/metrics", promhttp.Handler())
go http.ListenAndServe(":9092", nil)
```

This is the correct observability chain for a service without auth. When auth is added (as in Case 1), it must be inserted before `grpcMetrics.UnaryServerInterceptor()` — not appended at the end.

**Cross-case insight:** The two cases represent sequential stages of building a production chain. Up and Running provides the "start with observability" pattern; Go for Professionals provides the "add auth to an existing observability chain in the correct position" pattern. A developer building a production service encounters both: first add observability (Three-Pillar), then add auth/rate-limiting in the correct position relative to existing observability interceptors (Interceptor-Composition). Neither book alone provides the merged ordering.

## A2 — Future Trigger ★

Instead of applying the chain composition rules (Go for Professionals) or the observability interceptor wiring (Up and Running) independently, use this merged skill when:

- You have Prometheus metrics interceptors registered and your error-rate alert is firing, but all the alerted requests are auth failures from invalid tokens — not real service errors. This means auth is registered after metrics in the chain. Swap the order in `ChainUnaryInterceptor` to: rate-limit → auth → metrics → logging. Verify by running a request that fails auth and confirming it does not increment your Prometheus error counter.
- You are adding an auth interceptor to a service that already has Prometheus and logging interceptors registered and need to know where in the existing chain auth belongs.
- A PR registers a second interceptor with `grpc.UnaryInterceptor(...)` rather than using `ChainUnaryInterceptor` — the first registration is silently overwritten.
- You are reviewing a chain where logging is registered before auth — log lines will lack authenticated user context and may surface partial request information for requests that subsequently fail auth.
- A service has unary interceptors but no streaming interceptors — streaming RPCs have no auth coverage or observability.

## E — Execution

1. **Configure OTel TracerProvider and install as a `grpc.StatsHandler`.**

   ```go
   otel.SetTracerProvider(tp)
   otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}))
   // StatsHandler is separate from ChainUnaryInterceptor
   ```

2. **Define all interceptors with their correct signatures.**

   ```go
   // Rate limiter: first line of defense
   rateLimitInterceptor := func(ctx context.Context, req interface{},
       info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) { ... }

   // Auth: using go-grpc-middleware/v2 AuthFunc for unary+stream unification
   authInterceptor := auth.UnaryServerInterceptor(validateAuthToken)

   // Metrics: from go-grpc-prometheus
   grpcMetrics := grpc_prometheus.NewServerMetrics()

   // Logging: from go-grpc-middleware
   zapLogger, _ := zap.NewProduction()
   ```

3. **Register the complete chain with a single `ChainUnaryInterceptor` call.**

   ```go
   s := grpc.NewServer(
       grpc.StatsHandler(otelgrpc.NewServerHandler()),
       grpc.ChainUnaryInterceptor(
           rateLimitInterceptor,
           authInterceptor,                          // auth before metrics — critical
           grpcMetrics.UnaryServerInterceptor(),
           grpc_zap.UnaryServerInterceptor(zapLogger),
       ),
       grpc.ChainStreamInterceptor(
           rateLimitStreamInterceptor,
           authStreamInterceptor,
           grpcMetrics.StreamServerInterceptor(),
           grpc_zap.StreamServerInterceptor(zapLogger),
       ),
   )
   ```

4. **Register the service and initialize metrics.**

   ```go
   pb.RegisterYourServiceServer(s, &yourServer{})
   grpcMetrics.InitializeMetrics(s)  // must be called after service registration
   ```

5. **Expose the Prometheus scrape endpoint.**

   ```go
   http.Handle("/metrics", promhttp.Handler())
   go http.ListenAndServe(":9092", nil)
   ```

6. **Verify ordering in an integration test.**

   ```go
   // Send a request that fails auth (invalid or missing token)
   // Assert it returns codes.Unauthenticated
   // Assert the Prometheus counter for this method has NOT incremented
   // (query grpcMetrics or inspect a test Prometheus registry)
   ```

   This is the only test that validates the auth-before-metrics ordering constraint is actually enforced.

## B — Boundary

**Source A (Go for Professionals) failure modes:**

- Silent override if `grpc.UnaryInterceptor` is called twice — one interceptor disappears in production with no error signal.
- Client-side interceptors use `grpc.WithChainUnaryInterceptor` and follow a different ordering principle: retry wraps auth (not the reverse), because the client retries after re-acquiring credentials.
- Existing chain audit required before inserting new interceptors into a chain you did not design — do not assume the existing order is canonical.
- The `go-grpc-middleware/v2` `AuthFunc` pattern applies to both unary and stream via a single function, but custom interceptors that manipulate stream headers must still implement `grpc.StreamServerInterceptor` separately.

**Source B (Up and Running) failure modes:**

- OpenCensus (`ocgrpc`) is deprecated. Replace with `otelgrpc` for all new projects.
- Service mesh sidecars (Istio, Linkerd) generate L7 metrics that may duplicate in-process Prometheus counters. Evaluate whether to keep in-process instrumentation.
- Streaming RPCs require `ChainStreamInterceptor` registered separately. Omitting it leaves streaming methods without auth, metrics, or log coverage.
- Skipping `grpcMetrics.InitializeMetrics(s)` causes zero-value metrics to be absent until the first request for each method — alert gaps for methods that have never been called.

**Synthesis-specific failure mode:**
A team can implement all three observability interceptors correctly (per Up and Running) and still have incorrect alert behavior from wrong ordering (per Go for Professionals). Equally, a team can implement the correct auth-before-metrics ordering (per Go for Professionals) without the full three observability interceptors wired (per Up and Running). The synthesis-specific failure is building a chain that has all the right interceptors but in the wrong relative positions — the chain compiles, runs, and produces metrics, but those metrics are inflated by unauthenticated traffic and trigger alerts that do not reflect real service health. The verification test in step 6 is the only way to confirm the ordering constraint is enforced, not just declared.

**Ordering scope:** The canonical ordering (rate-limit → auth → metrics → logging) applies to server-side unary and stream interceptors. The OTel stats handler (`grpc.StatsHandler`) is not part of the chain and does not participate in this ordering. It records trace events at the transport level, before any chain interceptor runs.
