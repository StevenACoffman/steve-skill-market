# Test Results: Never-Mock-Net-Conn-Use-Loopback

Pass rate: 10/10 (100%)

## Results

| ID   | Type                          | Result | Notes                                                                                                                                                                                                                                                                                |
| ---- | ----------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| tp01 | should_trigger                | PASS   | "Should I create a MockConn with bytes.Buffer?" — A2 trigger 1 verbatim. Skill explicitly rejects bytes.Buffer, explains TCP semantic differences, provides `testConn` helper with `net.Listen("tcp", "127.0.0.1:0")` and goroutine for Accept.                                      |
| tp02 | should_trigger (code review)  | PASS   | MockConn struct wrapping two `bytes.Buffer` fields — A2 direct. Skill identifies the mock as the problem, names specific failure modes (partial reads return all bytes, blocking reads return EOF on empty, Close is a no-op), and provides the replacement with real loopback pair. |
| tp03 | should_trigger                | PASS   | "Write a testConn helper" — E section. All required elements: port 0, goroutine for Accept, `ln.Close()` after one connection, `t.Fatalf` not error return, usage example with both connection ends.                                                                                 |
| tp04 | should_not_trigger (boundary) | PASS   | HTTP handler test — B section "Where to use different tools instead / HTTP." Skill correctly redirects to `net/http/httptest.NewServer()` or `httptest.NewRecorder()` without recommending `testConn`.                                                                               |
| tp05 | should_not_trigger (boundary) | PASS   | gRPC service test — B section. Skill redirects to `google.golang.org/grpc/test/bufconn` as the gRPC-specific in-memory connection tool.                                                                                                                                              |
| tp06 | should_trigger (conceptual)   | PASS   | "Why can't I mock net.Conn?" — I section. Skill acknowledges the syntactic legitimacy of implementing the interface, then explains the specific TCP semantics lost in a mock (partial reads, blocking, close, half-close). "The mock tests the mock."                                |
| tp07 | should_trigger                | PASS   | "How does Packer test SSH?" — A1 case 2. Real in-process SSH server on loopback; goroutine running SSH handshake on accepted connection; real SSH client dials; both ends of authenticated session returned. Contrasts with what a mock would test.                                  |
| tp08 | should_trigger                | PASS   | "What is HashiCorp's policy on mocking net.Conn?" — R section. Direct quote or close paraphrase: "There is no reason to ever mock net.Conn." Provides the loopback alternative.                                                                                                      |
| tp09 | should_trigger (debugging)    | PASS   | Race detector error on bytes.Buffer mock from two goroutines — the fix is replacing the mock, not adding a mutex. Real `net.Conn` from `net.Listen`/`net.Dial` is goroutine-safe by Go net package guarantee. Skill correctly identifies the root cause.                             |
| tp10 | should_trigger                | PASS   | TCP server connection handler test — A2 (testConn without starting a full server). Pass server-side connection end directly to handler under test. Port 0, `t.Fatalf`, cleanup via `defer`.                                                                                          |

## Results for Boundary Cases

- **tp04** (HTTP): The B section is very explicit: "Do not use `testConn` for HTTP handlers or clients." This prevents misapplication of the pattern to a domain that has better standard-library support.
- **tp05** (gRPC): The B section names `bufconn` specifically, which prevents a developer from either using `testConn` directly (suboptimal) or mocking the gRPC interface (wrong).
- **tp09** (race detector on mock): This is a subtle correctness case — a developer might try to fix the mock by adding a mutex. The skill correctly redirects to replacing the mock entirely. The B section's "Confusion with TestHelperProcess" note explains that both this skill and `TestHelperProcess` reject shallow mocks in favor of real implementations.

## Analysis

All 10 prompts pass. The skill has strong, unambiguous triggers and well-defined boundaries. The "never mock net.Conn" rule is stated directly in the source and the description, making false negative (skill failing to activate when it should) very unlikely.

The two boundary probes (HTTP, gRPC) are important: they establish that the "never mock" philosophy does not mean "always use testConn" — the standard library provides better tools for those specific transports.

No changes to A2 or B are needed.
