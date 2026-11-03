---
name: grpc-bufconn-unit-testing
description: Trigger when setting up unit tests for a gRPC service that need a real gRPC server without binding a network port, or when needing per-test fault injection on storage doubles.
---
# bufconn Unit Testing — In-Memory gRPC Server with FakeDb Functional Options

## R — Reading

> "lis = bufconn.Listen(bufSize) / s := grpc.NewServer() / var testServer \*server = &server{d: fakeDb} / pb.RegisterTodoServiceServer(s, testServer) / go func() { if err := s.Serve(lis); err != nil && err.Error() != 'closed' { log.Fatalf(...) } }() ... func bufDialer(context.Context, string) (net.Conn, error) { return lis.Dial() } ... func NewFakeDb(opts ...TestOption) \*FakeDb { fdb := &FakeDb{available: true, tasks: make([]\*pb.Task, 0)}; for \_, o := range opts { o.apply(fdb) }; return fdb }"

## Ch9 (Production-Grade APIs)

## I — Interpretation

`google.golang.org/grpc/test/bufconn` is an in-memory connection listener that replaces a TCP socket entirely. The server calls `Serve(lis)` as it normally would; clients connect by passing `grpc.WithContextDialer(bufDialer)` where `bufDialer` returns `lis.Dial()`. No OS port is allocated, so tests are deterministic, require no port cleanup, and run without any network access. Because the connection never leaves the process, TLS is unnecessary — insecure credentials are used, which also means the interceptor stack (auth, TLS) is deliberately excluded. This is intentional: unit tests own endpoint logic, not the interceptor stack.

The `FakeDb` / `TestOption` pattern applies the functional options idiom — familiar from `grpc.ServerOption` — to test doubles. `NewFakeDb()` accepts zero or more `TestOption` values. Each option is a struct implementing `apply(*FakeDb)`. `IsAvailable(false)` injects a failure mode where every database operation returns an error, enabling fault injection without global mutable state or test-order dependencies. Between tests that mutate the in-memory task list, `fakeDb.Reset()` restores default state.

The server is started in an `init()` goroutine and the listener is a package-level variable shared across all tests in the package. This avoids the overhead of spinning up and tearing down the server per test while keeping tests parallel-safe through the `Reset()` contract.

The complete harness — `bufconn.Listen` + `grpc.WithContextDialer(bufDialer)` + `init()` goroutine + `FakeDb.Reset()` — is a tested, production-quality pattern. Its location in `google.golang.org/grpc/test/bufconn` (a test subdirectory) means it is not linked from the main gRPC-go README, making it genuinely non-obvious.

## A1 — Past Application

The TODO service test suite in Ch9 uses this harness to test all four endpoint types (AddTask unary, ListTasks server-streaming, UpdateTasks client-streaming, DeleteTasks bidirectional). A test for the error case uses `fakeDb = NewFakeDb(IsAvailable(false))` to verify the endpoint returns `codes.Internal`. The "happy path" test resets to `NewFakeDb()` for normal behavior. The client in tests uses `grpc.DialContext(ctx, "bufnet", grpc.WithContextDialer(bufDialer), grpc.WithTransportCredentials(insecure.NewCredentials()))`.

## A2 — Future Trigger ★

- You are writing gRPC endpoint unit tests and want to avoid the complexity of binding real ports, managing port conflicts, or configuring TLS in tests
- You need a test double for a storage interface that can be placed in an error state for a specific test case without affecting other tests
- You want to run gRPC endpoint tests in CI without a network stack or external dependencies
- You are reviewing code where a gRPC unit test connects to `localhost:50051` and want to recommend a better approach

## E — Execution

1. Import `google.golang.org/grpc/test/bufconn` and define a package-level `var lis *bufconn.Listener`
2. In `init()` or `TestMain`, call `lis = bufconn.Listen(bufSize)` (e.g., `bufSize = 1024*1024`), construct `grpc.NewServer()` with no interceptors, register the service with a `FakeDb` instance, and start `go s.Serve(lis)` in a goroutine
3. Define `func bufDialer(context.Context, string) (net.Conn, error) { return lis.Dial() }` as the context dialer
4. Implement `FakeDb` with functional options: define a `TestOption` interface with `apply(*FakeDb)`, implement `IsAvailable(bool)` as a concrete option struct
5. In each test, create the gRPC client with `grpc.DialContext(ctx, "bufnet", grpc.WithContextDialer(bufDialer), grpc.WithTransportCredentials(insecure.NewCredentials()))`
6. Call `fakeDb.Reset()` in `t.Cleanup` or at the start of any test that mutates state

## B — Boundary

This harness tests endpoint logic only — without TLS, auth interceptors, or rate limiting. Integration tests own the interceptor stack and require real credentials. The `bufconn` approach does not test that your server handles concurrent connections correctly at the OS level; for that, use Docker Compose or `ghz` load tests. The `bufDialer` function ignores the address argument, so all clients in the package share the same in-memory server — tests that require server state isolation must use `Reset()` or create separate server instances.

## Related Skills

______________________________________________________________________

## Provenance

- **Source:** [gRPC Go for Professionals, Clément Jean, Packt, 2023]
