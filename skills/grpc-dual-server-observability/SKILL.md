---
id: grpc-dual-server-observability
title: Dual-Server Observability — Concurrent gRPC + Prometheus HTTP Server with errgroup Lifecycle
description: Trigger when running a gRPC server and a Prometheus metrics HTTP server in the same process with unified error propagation and coordinated graceful shutdown.
source: [gRPC Go for Professionals, Clément Jean, Packt, 2023]
---

## R — Reading

> "g, ctx := errgroup.WithContext(ctx) / g.Go(func() error { log.Printf('gRPC server listening at %s', grpcAddr); if err := grpcServer.Serve(lis); err != nil { return err }; return nil }) / metricsServer := newMetricsServer(httpAddr) / g.Go(func() error { if err := metricsServer.ListenAndServe(); err != nil && err != http.ErrServerClosed { return err }; return nil })"

## Ch8 (More Essential Features) and Ch9 (Production-Grade APIs)

## I — Interpretation

`golang.org/x/sync/errgroup` provides a `WaitGroup`-like API where any goroutine may return an error. `errgroup.WithContext` returns a group and a derived context that is cancelled when the first goroutine returns a non-nil error. This enables running two independent servers — gRPC and HTTP — so that if either fails to start or crashes at runtime, the context cancellation triggers shutdown of the other.

The graceful shutdown challenge is that the two servers have different shutdown APIs. `grpcServer.GracefulStop()` drains in-flight RPCs before closing the listener — it blocks until all streaming RPCs complete. `metricsServer.Shutdown(ctx)` stops accepting new HTTP connections but waits for active HTTP handlers to return. Both are necessary to avoid dropping in-progress requests.

In Kubernetes, gRPC and Prometheus endpoints should never share a port. The gRPC server is registered in the headless service exposed to the Envoy proxy; the metrics HTTP server exposes `/metrics` on a separate `containerPort` scraped by Prometheus. A single-port deployment would require Prometheus to scrape through the gRPC proxy, which cannot parse HTTP/1.1 scrape requests.

The SIGTERM handler pattern: a signal goroutine blocks on `signal.Notify(sigCh, syscall.SIGTERM)`; when the signal arrives, it calls `grpcServer.GracefulStop()` and `metricsServer.Shutdown(ctx)` in sequence. The errgroup then unblocks from `g.Wait()` because both `g.Go` goroutines return nil (server closed normally) rather than an error. Without explicit SIGTERM handling, Kubernetes pod termination sends SIGTERM and then SIGKILL after the grace period; without `GracefulStop()`, in-flight RPCs are dropped.

## A1 — Past Application

The TODO service in Ch8 introduces the dual-server pattern with `errgroup`: the gRPC server listens on `:50051` and the Prometheus metrics server listens on `:9090`. The metrics registry uses `prometheus.NewRegistry()` with `grpcprom.NewServerMetrics` (including latency histogram buckets). Both servers share the `errgroup` context so a startup failure of either terminates the process. Ch9 adds the SIGTERM handler: a goroutine calls `signal.Notify`, triggers `GracefulStop()` on the gRPC server and `Shutdown()` on the HTTP server, and the errgroup unblocks cleanly.

## A2 — Future Trigger ★

- You need to expose Prometheus metrics from a gRPC service and are deciding whether to add a `/metrics` endpoint to the gRPC port or run a separate HTTP server
- Your gRPC service does not gracefully drain in-flight RPCs when Kubernetes sends SIGTERM, causing errors during rolling deployments
- You are running two servers in the same process with `go func()` goroutines and have no way to propagate errors from either server to `main()`
- You need coordinated shutdown where both the gRPC server and the metrics server stop cleanly when either one fails

## E — Execution

1. Import `golang.org/x/sync/errgroup` and `os/signal`
2. Create `g, ctx := errgroup.WithContext(context.Background())`
3. Start the gRPC server: `g.Go(func() error { return grpcServer.Serve(lis) })`
4. Create the metrics HTTP server with `http.NewServeMux()`, register `promhttp.HandlerFor(registry, ...)` on `/metrics`, and wrap in an `http.Server`
5. Start the metrics server: `g.Go(func() error { err := metricsServer.ListenAndServe(); if errors.Is(err, http.ErrServerClosed) { return nil }; return err })`
6. In a third goroutine, block on `signal.Notify(sigCh, syscall.SIGTERM, syscall.SIGINT)`, then call `grpcServer.GracefulStop()` followed by `metricsServer.Shutdown(ctx)` when the signal arrives
7. Block on `g.Wait()` in `main()`; a non-nil return means a server failed unexpectedly

## B — Boundary

`GracefulStop()` blocks indefinitely if streaming RPCs do not complete; add a timeout context to `GracefulStop`'s wrapping if your service has long-lived bidirectional streams. The errgroup pattern unifies startup failure detection but does not coordinate partial shutdown ordering — if the metrics server fails after the gRPC server is already handling RPCs, both servers shut down regardless. For services with more than two concurrent servers, consider a dedicated lifecycle manager. The Prometheus metrics registry must be thread-safe; use `prometheus.NewRegistry()` (not `prometheus.DefaultRegisterer`) to avoid test interference from the global registry.

## Related Skills
