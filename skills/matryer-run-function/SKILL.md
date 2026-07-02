---
name: matryer-run-function
description: |
  Apply this skill when a Go developer needs to make their program's startup logic testable, wants to call their program from tests with controlled inputs, or needs t.Parallel() safety across tests that read environment variables or parse flags. Trigger on: "how do I test my main function", "os.Getenv in tests breaks parallel", "flag.Parse global state", "graceful shutdown from tests", "inject environment variables in Go tests". DO NOT INVOKE when the question is about HTTP handler logic, middleware construction, or request/response decoding — those are covered by matryer-maker-func, matryer-middleware-constructor, and matryer-decode-valid.
tags: [go, testing, http-services, dependency-injection, entry-point, parallelism]
---

# The Run() Function Pattern: Testable, Parallel-Safe Entry Points

## R — Original Text (Reading)

> The `run` function is like the `main` function, except that it takes in operating system fundamentals as arguments, and returns, you guessed it, an error.
>
> Operating system fundamentals are passed into run as arguments. For example, you might pass in `os.Args` if it has flag support, and even `os.Stdin`, `os.Stdout`, `os.Stderr` dependencies. This makes your programs much easier to test because test code can call run to execute your program, controlling arguments, and all streams, just by passing different arguments.
>
> If you keep away from any global scope data, you can usually use `t.Parallel()` in more places, to speed up your test suites. Everything is self-contained, so multiple calls to `run` don't interfere with each other.
>
> For me, using this `getenv` technique beats using `t.SetEnv` for controlling environment variables because you can continue to run your tests in parallel by calling `t.Parallel()`, which `t.SetEnv` doesn't allow.
>
> The `args` and `getenv` parameters give us a couple of ways to control how our program behaves through flags and environment variables. Flags are processed using the args (as long as you don't use the global space version of flags, and instead use `flags.NewFlagSet` inside `run`).

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The core insight is that `func main()` in Go has two irremovable problems: it cannot return an error, and it cannot accept arguments. Both limitations make startup logic impossible to test directly. The fix is to extract all real work into a `run()` function that accepts everything `main()` would reach for via global state — `os.Args`, `os.Getenv`, `os.Stdin`, `os.Stdout`, `os.Stderr` — as explicit parameters, and returns an error.

`main()` becomes a three-line shim: create a background context, call `run()`, and handle the error. Every program behavior is now reachable through `run()`'s parameters.

This unlocks three compounding benefits. First, test code can call `run()` directly, passing fake args, in-memory writers, and stub `getenv` functions without touching the real process environment. Second, because no global state is mutated, multiple tests can call `run()` concurrently — `t.Parallel()` becomes safe. Third, graceful shutdown flows naturally: `run()` creates a `signal.NotifyContext` and defers `cancel()`, so the context is cancelled on `SIGINT`; tests cancel it by deferring `t.Cleanup(cancel)` on a `context.WithCancel` context, letting each test's server stop when the test ends.

The key discipline that makes this work is the use of `flag.NewFlagSet` inside `run()` rather than the global `flag.Parse`. Global flag state is shared across all goroutines; `NewFlagSet` is scoped to the call, which is what makes parallel flag-parsing safe.

The `getenv func(string) string` parameter replaces `os.Getenv` calls throughout the program. In production `main()` passes `os.Getenv` directly. In tests, a closure returns controlled values per key. This is superior to `t.SetEnv` because `t.SetEnv` mutates the real process environment and forces Go's test runner to serialize tests that use it.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: the Canonical Run() Signature

The author shows the evolution from a minimal signature to the full production form. Early in the article he uses `run(ctx context.Context, w io.Writer, args []string) error`, then notes that real services end up with:

```go
func run(
	ctx context.Context,
	args []string,
	getenv func(string) string,
	stdin io.Reader,
	stdout, stderr io.Writer,
) error
```

Problem: `main()` cannot return errors or accept injected dependencies, making startup logic unreachable by tests. Method: Extract to `run()` with explicit OS-fundamental parameters. Conclusion: `main()` becomes a three-liner that passes the real `os.*` values; tests pass fakes. Result: the entire program is testable end-to-end from a single function call.

### Case 2: Getenv Injection Over t.SetEnv

Problem: tests that call `os.Getenv` directly cannot run in parallel because `t.SetEnv` serializes the test runner by reverting global env mutations. Method: replace all `os.Getenv` call sites in `run()` with a `getenv func(string) string` parameter; in tests, pass a closure that switches on key name and returns controlled values. Conclusion: no process environment is mutated. Result: `t.Parallel()` works freely, test suites run faster, and environment configuration is explicit and readable in the test itself.

### Case 3: per-Test Server Lifetime via Context Cancellation

Problem: when `go run(ctx)` starts a server in a goroutine, there is no built-in mechanism to stop it when the test finishes. Method: the test calls `context.WithCancel`, defers `t.Cleanup(cancel)`, and passes the cancellable context to `run()`. The server checks `ctx.Err()` and propagates context cancellation through its dependencies. Conclusion: each test owns its server instance's lifetime. Result: tests are isolated — no server bleeds state into the next test, and resource cleanup is automatic.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. You have a Go service that reads `os.Getenv("DATABASE_URL")` and parses flags with `flag.Parse()` inside `main()`. You want to write tests that exercise startup behavior with different configs, but adding `t.Parallel()` causes data races and `t.SetEnv` prints a warning about parallelism. You need a structural fix, not a workaround.

2. Your integration tests each start an HTTP server. Tests pass in isolation but fail randomly when run together because they share the default `flag.CommandLine` and the second call to `flag.Parse()` panics with "flag redefined." You need each test to get its own flag set without changing how flags work in production.

3. You are writing a CLI tool that reads from `os.Stdin`, writes to `os.Stdout`, and reads a config path from `os.Args`. You want to write table-driven tests that exercise multiple input/output combinations, but the tool's logic is locked inside `main()` and cannot be called from test code.

4. A new team member asks why your test suite is slow. You explain that tests are sequential because they use `t.SetEnv`. The team wants to enable `t.Parallel()` across the board without introducing flaky behavior. The answer requires changing the structural relationship between `main()` and the rest of the program.

______________________________________________________________________

## E — Execution Steps

## Step 1 — Extract Run() from Main()

Move everything from `main()` into a new function. Give it a `context.Context` as the first parameter and an `error` return:

```go
func run(ctx context.Context, args []string, getenv func(string) string, stdin io.Reader, stdout, stderr io.Writer) error {
	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()
	// all your startup code here
	return nil
}
```

The code above shows the original Matryer form. `summary_rules.md §7` Shape A places `signal.NotifyContext` in `main()` instead, so that `stop()` can be called explicitly before `os.Exit(1)` — `os.Exit` bypasses deferred functions, meaning `defer cancel()` inside `run()` would be skipped on the error path:

```go
// summary_rules.md §7 Shape A — preferred: signal.NotifyContext in main()
func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	if err := run(ctx, os.Args, os.Getenv, os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		stop()
		os.Exit(1)
	}
	stop()
}

func run(ctx context.Context, args []string, getenv func(string) string, stdin io.Reader, stdout, stderr io.Writer) error {
	// ctx already carries cancellation from main(); no signal.NotifyContext here
	// all your startup code here
	return nil
}
```

## Step 2 — Reduce Main() to Three Lines

```go
func main() {
	ctx := context.Background()
	if err := run(ctx, os.Args, os.Getenv, os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
```

## Step 3 — Replace flag.Parse with flag.NewFlagSet Inside Run()

```go
func run(ctx context.Context, args []string, getenv func(string) string) error {
	fs := flag.NewFlagSet(args[0], flag.ContinueOnError)
	addr := fs.String("addr", ":8080", "listen address")
	if err := fs.Parse(args[1:]); err != nil {
		return err
	}
	_ = addr
	// ...
}
```

## Step 4 — Replace os.Getenv Calls with the Getenv Parameter

Everywhere you previously wrote `os.Getenv("KEY")`, write `getenv("KEY")` instead. No other change is needed.

## Step 5 — Write Tests That Call Run() Directly

```go
func TestRun(t *testing.T) {
	t.Parallel()

	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)

	var stdout, stderr bytes.Buffer
	getenv := func(key string) string {
		switch key {
		case "MYAPP_FORMAT":
			return "json"
		default:
			return ""
		}
	}
	args := []string{"myapp", "--addr", "localhost:0"}

	go run(ctx, args, getenv, nil, &stdout, &stderr)
	// wait for readiness, then make assertions
}
```

## Step 6 — Verify No Global State Remains

Audit `run()` and everything it calls for references to `os.Getenv`, `flag.Parse`, `flag.CommandLine`, `os.Args`, `os.Stdout`, `os.Stderr`, `os.Stdin`, or package-level variables that are written during startup. Any remaining reference is a parallel-safety hazard.

______________________________________________________________________

## B — Boundaries and Blind Spots

**When inapplicable**: If the program truly has no testable startup logic — for example, a trivial one-shot script — the pattern adds ceremony for no gain. Also inapplicable when the program uses `cgo` or system calls that cannot be controlled via injected parameters.

**Signature drift**: The more dependencies a program has, the longer `run()`'s parameter list grows. The author acknowledges this with a note on long argument lists but does not prescribe a hard limit. A struct-of-dependencies alternative is not discussed; teams with many parameters may find that approach cleaner.

**The getenv stub only covers run()**: If any package-level `init()` function reads `os.Getenv`, the injection cannot reach it. The pattern assumes all environment reads happen inside `run()` or its callees.

**Context propagation is required but not enforced**: Graceful shutdown only works if every goroutine and blocking call receives and respects the context. The article states "it's important to respect it at every level" but the compiler does not enforce this. Tests that rely on `t.Cleanup(cancel)` for server shutdown will hang if any code path ignores the context.

**signal.NotifyContext placement**: The original Matryer article placed `signal.NotifyContext` and `defer cancel()` inside `run()`. `summary_rules.md §7` Shape A subsequently moved it to `main()` — specifically so `stop()` can be called explicitly before `os.Exit(1)` when `run()` returns an error. `os.Exit` bypasses all deferred functions, so a `defer cancel()` inside `run()` would be skipped on the error path, leaking the signal goroutine. The summary's `main()` placement with an explicit `stop()` before `os.Exit(1)` is preferred. The R and I sections above faithfully represent the original article, which used the inside-`run()` form.

**No guidance on ports**: Starting a server in tests requires a free port. The article does not cover using `:0` (OS-assigned ports) or how to discover the assigned port after binding. This is addressed in the companion `matryer-waitfor-ready` skill.

______________________________________________________________________

## Related Skills

- **matryer-maker-func** — pairs-with: maker functions are called from `addRoutes`, which is invoked during `run()`; the two patterns compose at the server-wiring layer.
- **matryer-run-e2e-testing** — prerequisite-for: `run()` is the exact mechanism that makes e2e tests possible — tests call `go run(ctx)` to start a real server.
- **matryer-getenv-injection** — prerequisite-for: `getenv func(string) string` is a parameter of `run()`; the injection pattern lives inside the `run()` signature.
- **matryer-waitfor-ready** — prerequisite-for: the server is started in a goroutine by `run()`; `waitForReady` polls the server that `run()` launched.

______________________________________________________________________

## Provenance

- **Source:** "How I Write HTTP Services in Go After 13 Years" — Mat Ryer (2024) — func main() only calls run()
