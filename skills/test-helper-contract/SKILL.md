---
allowed-tools: Bash, Read, Edit
name: test-helper-contract
description: |
  Test helpers in Go must never return errors. The conventional Go error-return
  idiom is correct for production code, but test helpers have access to
  *testing.T and must use it: call t.Fatalf internally when setup fails, so
  every call site in the test body is free of error-handling boilerplate.

  The second half of the contract is the cleanup func(): instead of returning
  a resource and leaving teardown to the caller, return a closure that captures
  *testing.T and can itself call t.Fatalf if teardown fails. The test body
  becomes: resource, cleanup := testHelper(t); defer cleanup(). When the helper
  returns only a cleanup function, the one-liner defer testHelper(t, arg)() is
  idiomatic: the helper is called immediately and the returned func() is deferred.

  Sign every test helper as func testXxx(t *testing.T, [args]) (Resource, func()).
  Never end the signature with error. If setup fails, call t.Fatalf and let Go's
  test runtime handle termination. The test body should contain zero error-handling
  lines for setup infrastructure — only the logic under test.

  Two language features extend this pattern: t.Helper() (Go 1.9+) should be
  called at the start of the helper so failure line numbers point to the call
  site rather than inside the helper body. t.Cleanup(func(){...}) (Go 1.14+)
  allows helpers to register cleanup directly on t, eliminating the need to
  return a func() in most cases — callers no longer need to write defer cleanup()
  at all.
source_book: '"Advanced Testing with Go" by Mitchell Hashimoto'
source_chapter: Part 1 — Test Methodology / Test Helpers
tags: [go, testing, test-helpers, cleanup, test-methodology]
related_skills:
  - never-mock-net-conn-use-loopback  # composes-with: testConn IS a test helper following this contract
  - testing-go-public-test-api        # composes-with: testing.go factory functions must follow this contract
  - golden-files-update-flag          # composes-with: golden file fixture helpers follow this contract
  - table-driven-named-cases          # composes-with: helpers are commonly called inside table case loops
---

# R — Raw Source

## Current State

Test helpers that return errors instead of calling t.Fatal (anti-pattern):
!`grep -rn 'func.*testing\.T.*error' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -8`

Helpers using the correct contract (t.Fatal + cleanup func):
!`grep -rn 'func.*\*testing\.T.*func()' --include='*.go' . 2>/dev/null | grep -v vendor | head -5`

defer cleanup() pattern in use:
!`grep -rn 'defer.*()$\|, cleanup :=' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -5`

From "Advanced Testing with Go" (Mitchell Hashimoto, GopherCon):

> Test helpers should **never return errors**. Accept `*testing.T` and call
> `t.Fatalf` internally. By not returning errors, usage is much prettier since
> error checking is eliminated. Test helpers exist to make the test clear on what
> it is actually testing, not to add boilerplate.

**testTempFile — filesystem resource with cleanup closure:**

```go
func testTempFile(t *testing.T) (string, func()) {
    tf, err := ioutil.TempFile("", "test")
    if err != nil {
        t.Fatalf("err: %s", err)
    }
    tf.Close()
    return tf.Name(), func() { os.Remove(tf.Name()) }
}

func TestThing(t *testing.T) {
    tf, tfclose := testTempFile(t)
    defer tfclose()
}
```

> **Return a `func()` for cleanup.** The cleanup closure is an elegant way to
> bundle teardown with setup. Because it is a closure, it retains access to
> `*testing.T` and can call `t.Fatalf` if cleanup itself fails.

**testChdir — OS state with one-liner defer:**

```go
func testChdir(t *testing.T, dir string) func() {
    old, err := os.Getwd()
    if err != nil {
        t.Fatalf("err: %s", err)
    }
    if err := os.Chdir(dir); err != nil {
        t.Fatalf("err: %s", err)
    }
    return func() { os.Chdir(old) }
}

func TestThing(t *testing.T) {
    defer testChdir(t, "/other")()
    // …
}
```

> Proper setup and teardown for `testChdir` without the helper would be at least
> 10 lines in every test. The helper eliminates that across all tests.

---

## I — Interpretation

**Why no error return?**

Go's error-return idiom is correct for production code. In production, the caller
must decide what to do with a failure. But a test helper's caller is a test function.
When setup fails in a test, there is exactly one correct response: fail the test
immediately. That decision should be made once, inside the helper, not delegated to
every call site. A helper that returns an error forces the test body to contain:

```go
tf, err := testTempFile(t)
if err != nil {
    t.Fatalf("setup failed: %s", err)
}
```

— repeated for every helper call. These lines are not testing anything. They are
mechanical boilerplate that buries the actual test logic. The helper defeats its
own purpose: it was written to concentrate setup noise, but the noise escapes back
into the test body via the error return.

**Why return a cleanup func()?**

Cleanup is part of the helper's responsibility. If the helper allocates a resource,
it should know how to release it. The closure is the right vehicle: it bundles
teardown with setup as a single unit, it retains `*testing.T` via capture (so cleanup
can also call `t.Fatalf` if teardown fails), and it enables defer to be placed
immediately after the helper call — at the same visual line that reveals the resource
name. Setup and its corresponding teardown are never separated by test logic.

**The one-liner `defer testHelper(t, arg)()`**

When the helper returns only a `func()` (no resource value to use), calling
`defer testHelper(t, arg)()` is idiomatic. The outer `()` calls the helper now
(performing setup); the `defer` defers the returned inner `func()` (performing
teardown). The test body needs no variable at all. The technique looks unusual
until you parse it as two function calls: `(call helper)(defer returned func)`.

## The Core Inversion

Test helpers are not production code. Production helpers must respect their callers
by returning errors; test helpers must protect their callers from irrelevant error
handling. Accepting this inversion requires acknowledging that `*testing.T` access
changes the contract entirely.

---

## A1 — Worked Cases

### Case 1: testTempFile — Filesystem Resource

The canonical example from the source. Creates a temporary file, fails the test
internally if creation fails, and returns the path alongside a cleanup closure.

```go
func testTempFile(t *testing.T) (string, func()) {
    t.Helper() // failure line numbers point to caller, not here
    tf, err := ioutil.TempFile("", "test")
    if err != nil {
        t.Fatalf("testTempFile: %s", err)
    }
    tf.Close()
    return tf.Name(), func() {
        if err := os.Remove(tf.Name()); err != nil {
            t.Fatalf("testTempFile cleanup: %s", err)
        }
    }
}

func TestWriteConfig(t *testing.T) {
    path, cleanup := testTempFile(t)
    defer cleanup()

    if err := WriteConfig(path, cfg); err != nil {
        t.Fatalf("WriteConfig: %s", err)
    }
    // assertions…
}
```

The test body contains one error check — the one about WriteConfig, the function
under test — and zero error checks for setup infrastructure.

### Case 2: testChdir — OS State, One-Liner Defer

When the helper returns only `func()`, skip the intermediate variable:

```go
func testChdir(t *testing.T, dir string) func() {
    t.Helper()
    old, err := os.Getwd()
    if err != nil {
        t.Fatalf("testChdir: Getwd: %s", err)
    }
    if err := os.Chdir(dir); err != nil {
        t.Fatalf("testChdir: Chdir(%s): %s", dir, err)
    }
    return func() { os.Chdir(old) }
}

func TestCLIFromProjectRoot(t *testing.T) {
    defer testChdir(t, "/project/root")()
    // entire test body runs in /project/root; restored on exit
}
```

`defer testChdir(t, "/project/root")()` is a single line that handles setup,
teardown registration, and cleanup — replacing 10+ lines of boilerplate.

### Case 3: testConn — Network Resource Pair

Applying the same contract to a network domain (from the verified entry V1 evidence):

```go
func testConn(t *testing.T) (client, server net.Conn) {
    t.Helper()
    ln, err := net.Listen("tcp", "127.0.0.1:0")
    if err != nil {
        t.Fatalf("testConn: Listen: %s", err)
    }

    var wg sync.WaitGroup
    wg.Add(1)
    go func() {
        defer wg.Done()
        var err error
        server, err = ln.Accept()
        if err != nil {
            t.Errorf("testConn: Accept: %s", err)
        }
    }()

    client, err = net.Dial("tcp", ln.Addr().String())
    if err != nil {
        t.Fatalf("testConn: Dial: %s", err)
    }
    wg.Wait()
    ln.Close()
    return client, server
}

func TestProtocol(t *testing.T) {
    client, server := testConn(t)
    defer client.Close()
    defer server.Close()
    // test protocol framing between the two ends
}
```

No error return. Three potential failure points (`Listen`, `Accept`, `Dial`) are
all handled internally via `t.Fatalf`/`t.Errorf`. The test body receives two live
connections with no setup noise.

---

## A2 — Activation

This skill applies when:

- "I'm writing a test helper that creates a temporary database / file / server.
  Should it return an error?"
- Writing a `setUp` function that multiple tests call, where every caller repeats
  the same `if err != nil { t.Fatalf(...) }` pattern.
- A test body has multiple consecutive error checks for setup steps, none of which
  relate to the function under test.
- "How do I handle cleanup in Go tests without defer getting complicated?"
- Any helper with a signature ending in `(..., error)` that is only ever called
  from test code.
- Code review finding `t.Fatal` inside a test *after* calling a helper, for errors
  the helper itself returned.

---

## E — Execution Steps

1. **Sign the helper correctly.**
   `func testXxx(t *testing.T, [args]) (Resource, func())`
   If there is no resource to return: `func testXxx(t *testing.T, [args]) func()`
   Never end with `error`.

2. **Add `t.Helper()` as the first line.**
   This marks the function as a test helper so that failure line numbers in
   `go test` output point to the call site, not inside the helper.

3. **Call `t.Fatalf` (not `return nil, err`) when setup fails.**
   The helper owns failure handling. The caller must not be burdened with it.

4. **Build the cleanup closure before returning.**
   The closure captures all resources allocated in the helper — file handles,
   connections, temporary paths. If teardown can fail, capture `t` and call
   `t.Fatalf` inside the closure.

5. **In the test: `resource, cleanup := testHelper(t); defer cleanup()`.**
   Place `defer cleanup()` on the immediately following line so setup and its
   corresponding teardown are visually co-located.

6. **If there is no resource value, use the one-liner:**
   `defer testHelper(t, arg)()`
   The helper is called now; the returned func() is deferred.

7. **Consider `t.Cleanup` (Go 1.14+) as an alternative.**
   Instead of returning `func()`, register cleanup directly inside the helper:
   `t.Cleanup(func() { os.Remove(tf.Name()) })`
   Callers no longer need to manage the cleanup variable at all.

---

## B — Boundaries and Blind Spots

**Scope: test code only.**
This pattern applies exclusively to helpers in `_test.go` files or `testing.go`
files (the public test API pattern). Do not apply it to production code. A production
helper that calls `t.Fatalf` would not compile outside of test contexts.

**Author blind spot: `t.Cleanup()` (Go 1.14+).**
The book predates `t.Cleanup`. In modern Go, a helper can register cleanup
directly on `t` rather than returning a `func()`:

```go
func testTempFile(t *testing.T) string {
    t.Helper()
    tf, err := ioutil.TempFile("", "test")
    if err != nil {
        t.Fatalf("testTempFile: %s", err)
    }
    tf.Close()
    t.Cleanup(func() { os.Remove(tf.Name()) })
    return tf.Name()
}
```

The caller writes only `path := testTempFile(t)` — no cleanup variable, no defer.
This is now the idiomatic form in Go 1.14+ codebases. The `(Resource, func())`
signature is still valid but no longer the default choice.

**Author blind spot: `t.Helper()` (Go 1.9+).**
The book also predates `t.Helper()`. Without it, a `t.Fatalf` call inside the
helper reports the failure at the helper's line number, not the test's call site.
Every test helper should call `t.Helper()` as its first statement.

**Confusion with test fixtures.**
This pattern is for dynamic resource management — resources created at test runtime
that require cleanup. It does not apply to static test fixtures (files in
`test-fixtures/` directories), which require no cleanup function.

**`ioutil` is deprecated.**
The `ioutil.TempFile` and `ioutil.ReadFile` calls in the source examples are
deprecated since Go 1.16. Use `os.CreateTemp`, `os.ReadFile`, and `os.WriteFile`
in all new code.

### Related Skills

- **never-mock-net-conn-use-loopback** (composes-with): The `testConn` helper is a direct application of this contract — it accepts `*testing.T`, calls `t.Fatalf` on all three failure points (Listen, Accept, Dial), and never returns an error. Both skills are in effect whenever a connection helper is written.
- **testing-go-public-test-api** (composes-with): Every factory function exported in `testing.go` (e.g., `TestServer(t)`, `TestConfig(t)`) must follow this contract — no error return, `t.Fatalf` internally, cleanup via `t.Cleanup` or returned `func()`. The `testing.go` skill governs location; this skill governs signature.
- **golden-files-update-flag** (composes-with): Fixture helpers that set up complex input structures for golden file tests should follow this contract. The helper creates the struct, calls `t.Fatalf` if construction fails, and returns the ready-to-use value.
- **table-driven-named-cases** (composes-with): Helpers are called inside the table case loop to set up per-case resources. The no-error-return contract ensures the loop body stays focused on the case logic, not setup error handling.
