---
name: grpc-observability-three-pillar-with-trace-log-bridge
allowed-tools: Bash, Read, Edit
id: grpc-observability-three-pillar-with-trace-log-bridge
description: >
  Invoke when instrumenting a gRPC service for production visibility, or when
  logs and traces are collected separately but cannot be correlated in Kibana or
  Grafana. Key trigger: "I have metrics, logs, and traces running but I cannot
  filter my log lines by trace ID." The missing step is a trace-aware log
  formatter that injects trace_id/span_id into every structured log entry by
  reading span context from log.WithContext(ctx) — without it, all three
  pillars are live and still unlinked.
type: merged-skill
source_skills:
  - slug: grpc-up-and-running/grpc-observability-three-pillar
    book: 'gRPC: Up and Running'
    author: Kasun Indrasiri and Danesh Kuruppu
  - slug: grpc-microservices-in-go/grpc-traceid-log-correlation
    book: gRPC Microservices in Go
    author: Hüseyin Babal
related_skills:
  - slug: grpc-up-and-running/grpc-observability-three-pillar
    relation: supersedes
    note: Covers three-pillar pattern without the trace-log bridge step; use this merged skill instead.
  - slug: grpc-microservices-in-go/grpc-traceid-log-correlation
    relation: supersedes
    note: Covers the trace-log bridge in isolation without the full three-pillar wiring context.
tags: []
---

# gRPC Production Observability — Three Pillars Plus the Trace-Log Bridge

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

OTel / tracing setup:
!`grep -rn 'otelgrpc\|opentelemetry\|TracerProvider\|TraceProvider' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -5`

Prometheus / metrics setup:
!`grep -rn 'grpc_prometheus\|prometheus\.NewServer\|grpcMetrics' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -5`

Structured log setup:
!`grep -rn 'grpc_zap\|grpc_logrus\|UnaryServerInterceptor.*zap' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -5`

### R — Reading

> "When talking about observability, there are three main pillars that we normally
> talk about: metrics, logging, and tracing. These are the main techniques used to
> gain the observability of the system. It's better to have all three pillars enabled
> in your system to gain maximum visibility of the internal state."

*gRPC: Up and Running, Ch. 7 — Running gRPC in Production* (Indrasiri & Kuruppu)

> "To inject trace and span IDs into every log we printed using the logrus library,
> we can configure it to use a log formatter... When you look at the logic in the
> Format function, you can see it loads span data from context and configures the
> existing log entry to inject tracing data... TraceID and SpanID fields can be used
> in the logging backend to filter and show the logs related to a specific operation."

*gRPC Microservices in Go, Ch. 9 — Observability* (Babal)

**Convergence note:** Both sources ground observability in OpenTelemetry interceptor injection via `otelgrpc` — the same mechanism applied independently to the ProductInfo service (Up and Running, Ch. 7) and the Order/Payment service pair (Microservices in Go, Ch. 9). What each adds uniquely: Up and Running gives the strategic three-signal architecture (what each pillar answers and at what cost), while Microservices in Go provides the concrete integration step that links the signals in the observability backend — a trace-aware log formatter that neither book fully combines with the other's material.

### I — Interpretation

Each observability signal answers a distinct class of question. None of the three is redundant with the others; missing any one leaves a category of production failure invisible.

**Metrics** answer: "Is the system healthy in aggregate?" They provide counts, rates, and latency histograms at constant storage cost regardless of traffic volume. Standard gRPC signals: `grpc_server_handled_total` (labeled by service, method, status code), in-flight RPC count, and `grpc_server_handling_seconds_bucket`. These are always-on — every request contributes. Metrics reveal *that* a category of requests is failing; they cannot reveal *why* a specific request failed.

**Logs** answer: "What happened in this specific request?" They capture per-event detail — request IDs, user IDs, error messages, stack traces. For gRPC, logs are injected via `grpc_zap` or `grpc_logrus` interceptors from `go-grpc-middleware`. The interceptor produces a structured log line per RPC (method, duration, status code, peer address) without any code inside the handler.

**Traces** answer: "What path did this specific request take across services?" A distributed trace reconstructs the end-to-end chain with timing for each hop. This is what neither metrics nor logs provide: a request that fails in ServiceC may appear as a `DEADLINE_EXCEEDED` in ServiceC's metrics, but only a trace reveals that ServiceA consumed 490ms of a 500ms deadline before the call was made. Traces are sampled (not every request), injected via `otelgrpc`, and propagated via gRPC metadata.

**The integration gap.** Implementing all three pillars correctly does not automatically link them in the observability backend. Metrics, logs, and traces are separate signal streams. A structured log line from the Order service and a trace span from the Payment service for the same user request will not be connected in Kibana or Grafana unless the `trace_id` and `span_id` appear in the log line's JSON fields. This connection requires two things that neither pillar's default interceptor provides on its own:

1. A **trace-aware log formatter** — a custom `logrus.Formatter` (or equivalent for `zap`/`slog`) whose `Format` method calls `trace.SpanFromContext(entry.Context)`, reads `span.SpanContext().TraceID().String()` and `span.SpanContext().SpanID().String()`, and injects them into the log entry's data map before serializing.

2. **Context-threaded log calls** — every log call must use `log.WithContext(ctx).Info(...)` rather than `log.Info(...)`. Without `WithContext`, the formatter cannot retrieve the span because the entry's `Context` field is nil.

The formatter is installed once globally (`logrus.SetFormatter(&traceAwareFormatter{})` in `main.go`). It applies to all log lines in all packages without requiring those packages to import the tracing library. A missing `WithContext` call silently produces a log line with no trace fields — no error, no warning, just an invisible gap. This is the most common reason a team with all three pillars deployed still cannot correlate logs and traces at query time.

**All three signals plus the bridge must be injected via interceptors.** Observability logic inside handler functions must be duplicated for every method, will be omitted from future methods, and mixes infrastructure concerns with business logic. Interceptors registered at server creation apply automatically to every RPC.

### A1 — Past Application

## R — Reading

> "When talking about observability, there are three main pillars that we normally
> talk about: metrics, logging, and tracing. These are the main techniques used to
> gain the observability of the system. It's better to have all three pillars enabled
> in your system to gain maximum visibility of the internal state."

*gRPC: Up and Running, Ch. 7 — Running gRPC in Production* (Indrasiri & Kuruppu)

> "To inject trace and span IDs into every log we printed using the logrus library,
> we can configure it to use a log formatter... When you look at the logic in the
> Format function, you can see it loads span data from context and configures the
> existing log entry to inject tracing data... TraceID and SpanID fields can be used
> in the logging backend to filter and show the logs related to a specific operation."

*gRPC Microservices in Go, Ch. 9 — Observability* (Babal)

**Convergence note:** Both sources ground observability in OpenTelemetry interceptor injection via `otelgrpc` — the same mechanism applied independently to the ProductInfo service (Up and Running, Ch. 7) and the Order/Payment service pair (Microservices in Go, Ch. 9). What each adds uniquely: Up and Running gives the strategic three-signal architecture (what each pillar answers and at what cost), while Microservices in Go provides the concrete integration step that links the signals in the observability backend — a trace-aware log formatter that neither book fully combines with the other's material.

## I — Interpretation

Each observability signal answers a distinct class of question. None of the three is redundant with the others; missing any one leaves a category of production failure invisible.

**Metrics** answer: "Is the system healthy in aggregate?" They provide counts, rates, and latency histograms at constant storage cost regardless of traffic volume. Standard gRPC signals: `grpc_server_handled_total` (labeled by service, method, status code), in-flight RPC count, and `grpc_server_handling_seconds_bucket`. These are always-on — every request contributes. Metrics reveal *that* a category of requests is failing; they cannot reveal *why* a specific request failed.

**Logs** answer: "What happened in this specific request?" They capture per-event detail — request IDs, user IDs, error messages, stack traces. For gRPC, logs are injected via `grpc_zap` or `grpc_logrus` interceptors from `go-grpc-middleware`. The interceptor produces a structured log line per RPC (method, duration, status code, peer address) without any code inside the handler.

**Traces** answer: "What path did this specific request take across services?" A distributed trace reconstructs the end-to-end chain with timing for each hop. This is what neither metrics nor logs provide: a request that fails in ServiceC may appear as a `DEADLINE_EXCEEDED` in ServiceC's metrics, but only a trace reveals that ServiceA consumed 490ms of a 500ms deadline before the call was made. Traces are sampled (not every request), injected via `otelgrpc`, and propagated via gRPC metadata.

**The integration gap.** Implementing all three pillars correctly does not automatically link them in the observability backend. Metrics, logs, and traces are separate signal streams. A structured log line from the Order service and a trace span from the Payment service for the same user request will not be connected in Kibana or Grafana unless the `trace_id` and `span_id` appear in the log line's JSON fields. This connection requires two things that neither pillar's default interceptor provides on its own:

1. A **trace-aware log formatter** — a custom `logrus.Formatter` (or equivalent for `zap`/`slog`) whose `Format` method calls `trace.SpanFromContext(entry.Context)`, reads `span.SpanContext().TraceID().String()` and `span.SpanContext().SpanID().String()`, and injects them into the log entry's data map before serializing.

2. **Context-threaded log calls** — every log call must use `log.WithContext(ctx).Info(...)` rather than `log.Info(...)`. Without `WithContext`, the formatter cannot retrieve the span because the entry's `Context` field is nil.

The formatter is installed once globally (`logrus.SetFormatter(&traceAwareFormatter{})` in `main.go`). It applies to all log lines in all packages without requiring those packages to import the tracing library. A missing `WithContext` call silently produces a log line with no trace fields — no error, no warning, just an invisible gap. This is the most common reason a team with all three pillars deployed still cannot correlate logs and traces at query time.

**All three signals plus the bridge must be injected via interceptors.** Observability logic inside handler functions must be duplicated for every method, will be omitted from future methods, and mixes infrastructure concerns with business logic. Interceptors registered at server creation apply automatically to every RPC.

## A1 — Past Application

### Case 1: ProductInfo Service — Single-Service Three-Pillar Instrumentation

The book *gRPC: Up and Running* instruments the `ProductInfo` service (Ch. 7) with all three signals independently:

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

This is a single-service case. All three pillars produce signals, but the signals exist in separate stores. The configuration does not link log lines to trace spans — Prometheus dashboards show error rates, log lines show per-request detail, and Jaeger shows trace trees, but querying by trace ID in a log tool returns nothing.

### Case 2: Order/Payment Service Pair — Cross-Service Trace-Log Bridge

The book *gRPC Microservices in Go* instruments the Order service calling the Payment service (Ch. 9). Because two services participate in a single request, a `trace_id` propagated via gRPC metadata is the only identifier shared by both services' log streams. Without the bridge, log lines from Order and Payment for the same request are unlinked: filtering Payment logs by `trace_id = "abc123..."` in Kibana returns zero results, even though both services are running OTel interceptors.

The bridge is implemented as:

```go
type traceAwareFormatter struct {
	inner logrus.Formatter
}

func (f *traceAwareFormatter) Format(entry *logrus.Entry) ([]byte, error) {
	span := trace.SpanFromContext(entry.Context)
	if span.SpanContext().IsValid() {
		entry.Data["trace_id"] = span.SpanContext().TraceID().String()
		entry.Data["span_id"] = span.SpanContext().SpanID().String()
	}
	return f.inner.Format(entry)
}
```

Registered globally in `cmd/main.go`:

```go
func init() {
	logrus.SetFormatter(&traceAwareFormatter{inner: &logrus.JSONFormatter{}})
}
```

After deployment, filtering Kibana by `trace_id = "abc123..."` returns log lines from both the Order service and the Payment service for that specific request. The cross-service case is the only context where the integration gap becomes visible — a single-service setup cannot exhibit it because there is only one log stream.

## A2 — Future Trigger ★

Instead of applying the three-pillar pattern (Up and Running) or the trace-log bridge (Microservices in Go) independently, use this merged skill when:

- You have Prometheus metrics, structured logs, and OTel traces all running in production, but filtering logs by trace ID in Kibana or Grafana Loki returns no results — the bridge step is missing.
- You are instrumenting a gRPC service for the first time and want all three pillars plus correlation configured in a single pass — follow the merged execution sequence below from the start.
- A developer is manually adding `logrus.WithFields(logrus.Fields{"trace_id": span.TraceID()})` to individual log calls — centralize this in the formatter.
- A service is being promoted to production: the observability gate requires not just that all three interceptors are registered, but also that log lines from a test request include `trace_id` and `span_id` fields in their JSON output.
- You have a multi-service trace showing a request crossed three services, but only one service's log lines appear when you filter by trace ID — check that the other services have the bridge installed and are using `log.WithContext(ctx)`.

## E — Execution

1. **Configure the OTel TracerProvider.**

   ```go
   exporter, _ := otlptracegrpc.New(ctx, otlptracegrpc.WithEndpoint("otel-collector:4317"))
   tp := tracesdk.NewTracerProvider(tracesdk.WithBatcher(exporter))
   otel.SetTracerProvider(tp)
   otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}))
   defer tp.Shutdown(ctx)
   ```

2. **Install the trace-aware log formatter before any log calls.**

   ```go
   logrus.SetFormatter(&traceAwareFormatter{inner: &logrus.JSONFormatter{}})
   ```

   This must happen in `init()` or early in `main()`, before the gRPC server starts.

3. **Register all interceptors with `grpc.ChainUnaryInterceptor`.**

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
   ```

   Note: OTel trace context injection is handled by `grpc.StatsHandler(otelgrpc.NewServerHandler())`, not a chain interceptor.

4. **Initialize Prometheus metrics and expose the scrape endpoint.**

   ```go
   pb.RegisterYourServiceServer(s, &yourServer{})
   grpcMetrics.InitializeMetrics(s) // pre-populate label combinations to avoid zero-gap monitoring
   http.Handle("/metrics", promhttp.Handler())
   go http.ListenAndServe(":9092", nil)
   ```

5. **Update all log call sites to pass context.**

   ```go
   // Correct — trace fields will appear in the log line
   log.WithContext(ctx).Info("processing order")

   // Incorrect — trace fields will be absent; no error is raised
   log.Info("processing order")
   ```

   Audit every log call site in the service. Library wrappers must thread the context through their signatures.

6. **Register the client-side OTel handler for outbound calls.**

   ```go
   conn, _ := grpc.Dial(address,
   	grpc.WithStatsHandler(otelgrpc.NewClientHandler()),
   )
   ```

   This propagates the trace context to downstream services so their log lines share the same `trace_id`.

7. **Configure the observability backend for signal linking.**

   - Grafana: pair Loki (logs) with Tempo (traces); configure the Loki data source with a derived field that extracts `trace_id` and links to Tempo.
   - Elastic Stack: configure Kibana with a trace-ID–based filter panel.
     Without backend support for linking, the `trace_id` fields in log lines are present but not clickable.

8. **Verify the bridge in a test.**
   Call an endpoint, capture log output, and assert that `trace_id` and `span_id` fields are present and non-empty in the JSON. If either is absent, check: (a) the formatter is registered, (b) the log call uses `WithContext(ctx)`, (c) the OTel stats handler is registered on the server.

9. **Configure Prometheus alerts.**
   At minimum: alert when `grpc_server_handled_total{grpc_code=~"UNAVAILABLE|INTERNAL|UNKNOWN"}` rate exceeds threshold, and when `grpc_server_handling_seconds_bucket` p99 exceeds the service SLO.

## B — Boundary

**Source A (Up and Running) failure modes:**

- OpenCensus (`ocgrpc`) is deprecated and archived. Replace with `otelgrpc` for all new projects.
- Service mesh sidecars (Istio, Linkerd) generate L7 metrics that may duplicate in-process Prometheus counters. Evaluate whether to keep in-process instrumentation (richer business-specific labels) or rely on the mesh. Application logs remain the application's responsibility regardless.
- Streaming RPCs require `ChainStreamInterceptor` registered separately from `ChainUnaryInterceptor`. Omitting this leaves streaming methods without metrics or log coverage.
- Skipping `grpcMetrics.InitializeMetrics(s)` causes zero-value metrics to be absent from Prometheus until the first request for each method — alert gaps for newly deployed or rarely called methods.

**Source B (Microservices in Go) failure modes:**

- `log.Info(...)` without `WithContext(ctx)` produces log lines with no trace fields. This is silent — no error, no warning. Pre-commit hooks or linters that enforce `WithContext` are the only automated safeguard.
- The trace-log bridge requires the observability backend to support signal linking. The formatter code alone is not enough — Grafana Loki + Tempo, or Elastic Stack, must be configured to join on `trace_id`. Without this backend configuration, the fields are present but unused.
- logrus is the specific library used in the book. The `slog` and `zap` equivalents use different extension points (`Handler` for `slog`, `Core` for `zap`) but follow the same pattern: extract span from context in the hook, inject fields before serialization.
- The Jaeger exporter (`go.opentelemetry.io/otel/exporters/jaeger`) is deprecated. Use the OTLP exporter pointing at an OTel Collector for new projects.

**Synthesis-specific failure mode:**
A team can implement all three pillars correctly per Up and Running (metrics interceptor, log interceptor, OTel stats handler) and still have zero log-trace correlation in the observability backend. The three-pillar skill does not warn that this gap exists; the trace-log bridge skill addresses it but does not show the full server wiring. Teams working from either source alone will not discover the missing step until they try to filter logs by trace ID in production and get no results. Implementing the bridge requires both: the full interceptor wiring from the three-pillar pattern, and the formatter + `WithContext` discipline from the trace-log correlation pattern.
