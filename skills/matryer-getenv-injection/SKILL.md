---
name: matryer-getenv-injection
description: |
  Inject environment variable access as a `getenv func(string) string` parameter on the `run()` function instead of calling `os.Getenv` directly. Pass `os.Getenv` in `main()` and pass a closure returning test-specific values in tests. Invoke when Go service or CLI tests set environment variables with `t.Setenv` and cannot call `t.Parallel()`, or when a test suite is slowed by sequential env-var tests. DO NOT INVOKE when the codebase has no `run()` function pattern, when env vars are accessed only at startup outside of tests, or when the question is about a non-Go language.
source_book: "How I Write HTTP Services in Go After 13 Years" — Mat Ryer (2024)
source_chapter: Controlling the environment
tags: [go, testing, environment-variables, parallelism, dependency-injection]
related_skills:
  - matryer-run-function
  - matryer-run-e2e-testing
---

# Getenv Injection: Parallel-Safe Environment Variables via `func(string) string`

## R — Original Text (Reading)

Mat Ryer introduces `getenv func(string) string` as one of the OS-level dependencies injected into the `run()` function alongside `args`, `stdin`, `stdout`, and `stderr`:

> "The following table shows examples of input arguments to the run function:
> | `os.Getenv` | `func(string) string` | For reading environment variables |"

The canonical `run()` signature he arrives at:

```go
func run(
	ctx context.Context,
	args []string,
	getenv func(string) string,
	stdin io.Reader,
	stdout, stderr io.Writer,
) error
```

On injecting a closure in tests instead of mutating the real environment:

> "If your program uses environment variables over flags (or even both) then the `getenv` function allows you to plug in different values without changing the actual environment."

```go
getenv := func(key string) string {
	switch key {
	case "MYAPP_FORMAT":
		return "markdown"
	case "MYAPP_TIMEOUT":
		return "5s"
	default:
		return ""
	}
}
go run(ctx, args, getenv)
```

On why this beats `t.Setenv`:

> "For me, using this `getenv` technique beats using `t.SetEnv` for controlling environment variables because you can continue to run your tests in parallel by calling `t.Parallel()`, which `t.SetEnv` doesn't allow."

In `main()`, pass the real function:

```go
func main() {
	ctx := context.Background()
	if err := run(ctx, os.Getenv, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
```

And on the broader guarantee:

> "If you keep away from any global scope data, you can usually use `t.Parallel()` in more places, to speed up your test suites. Everything is self-contained, so multiple calls to `run` don't interfere with each other."

______________________________________________________________________

## I — Methodological Framework (Interpretation)

`t.Setenv` works by calling `os.Setenv` on the real process environment and registering a cleanup to restore the original value. Because the process environment is a single shared map, two tests that both call `t.Setenv("DATABASE_URL", ...)` on the same key will race. Go's testing package detects this and panics when `t.Parallel()` is called alongside `t.Setenv` in the same test.

The injected `getenv` eliminates the shared mutable state entirely. Each test constructs its own closure that answers lookup calls from its own local variables — no process-level mutation, no race, no restriction on parallelism.

The type `func(string) string` is exactly `os.Getenv`'s signature, so production code passes `os.Getenv` without any wrapping. Tests pass a closure. This is the same dependency-injection pattern applied to functions rather than interfaces; the "seam" is the function parameter itself.

Key properties of the pattern:

1. **Zero global mutation** — the process environment is never touched during tests.
2. **Call-site transparency** — inside `run()`, every `getenv("KEY")` call reads identically regardless of whether it is production or test code.
3. **Selective override** — the closure's `default: return ""` branch delegates unknown keys to nothing (or, if desired, to a captured `os.Getenv` for a partial-override pattern).
4. **Composable** — multiple concurrent test goroutines each hold a distinct closure; they never share state.
5. **No extra library** — the type is a plain Go function value; no interface, no struct, no mock framework required.

The pattern extends naturally to other "global" accessors (`os.Getwd`, `time.Now`, etc.) using the same injection approach.

______________________________________________________________________

## A1 — Past Application (From the Book)

Ryer applies the pattern to test a CLI tool that reads `MYAPP_FORMAT` and `MYAPP_TIMEOUT`. Without injection, each test would call `t.Setenv("MYAPP_FORMAT", "markdown")`, serializing the entire suite. With injection, each test builds its own closure and passes it to `run()`:

```go
func TestMarkdownFormat(t *testing.T) {
	t.Parallel()
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)

	getenv := func(key string) string {
		switch key {
		case "MYAPP_FORMAT":
			return "markdown"
		case "MYAPP_TIMEOUT":
			return "5s"
		default:
			return ""
		}
	}

	var stdout bytes.Buffer
	go run(ctx, []string{"myapp"}, getenv, nil, &stdout, io.Discard)
	// assertions ...
}
```

`t.Parallel()` is safe because `getenv` is a pure local closure with no shared state. All tests in the suite run concurrently.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

A developer has integration tests for an HTTP service that reads `DATABASE_URL`, `API_KEY`, and `LOG_LEVEL` at startup via `os.Getenv`. Each test uses `t.Setenv` to set those keys:

```go
func TestWithPostgres(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://localhost/test_db")
	t.Setenv("LOG_LEVEL", "debug")
	// ... spin up run(), hit endpoints
}
```

Adding `t.Parallel()` to any of these tests causes the testing framework to panic: `testing: t.Setenv called after t.Parallel`. The suite runs sequentially and takes 45 seconds for 12 integration tests.

**The fix**: add `getenv func(string) string` to `run()`'s signature, replace all `os.Getenv(...)` calls inside `run()` with `getenv(...)`, pass `os.Getenv` in `main()`, and rewrite each test to pass a closure:

```go
func TestWithPostgres(t *testing.T) {
	t.Parallel()
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)

	getenv := func(key string) string {
		switch key {
		case "DATABASE_URL":
			return "postgres://localhost/test_db"
		case "LOG_LEVEL":
			return "debug"
		default:
			return os.Getenv(key) // pass through anything else
		}
	}

	go run(ctx, os.Args[:1], getenv, nil, io.Discard, io.Discard)
	waitForReady(ctx, 5*time.Second, "http://localhost:PORT/healthz")
	// assertions ...
}
```

The 12 tests now run in parallel; wall-clock time drops from 45 s to ~8 s.

______________________________________________________________________

## E — Execution Steps

**Step 1 — Update the `run()` signature.**

Add `getenv func(string) string` as the third parameter (after `args`, before `stdin`):

```go
func run(
	ctx context.Context,
	args []string,
	getenv func(string) string,
	stdin io.Reader,
	stdout, stderr io.Writer,
) error {
	// ...
}
```

**Step 2 — Replace all `os.Getenv` calls inside `run()`.**

Search for `os.Getenv(` within `run()` and its callees that are only reachable from `run()`. Change each to `getenv(`:

```go
// before
dbURL := os.Getenv("DATABASE_URL")

// after
dbURL := getenv("DATABASE_URL")
```

**Step 3 — Pass `os.Getenv` in `main()`.**

```go
func main() {
	ctx := context.Background()
	if err := run(ctx, os.Args, os.Getenv, os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
```

**Step 4 — Write test closures.**

For each test that previously used `t.Setenv`, replace the `t.Setenv` calls with a `getenv` closure:

```go
getenv := func(key string) string {
	switch key {
	case "DATABASE_URL":
		return testDatabaseURL
	case "API_KEY":
		return "test-api-key"
	default:
		return "" // or os.Getenv(key) for pass-through
	}
}
```

Pass the closure as the `getenv` argument to `run()`.

**Step 5 — Add `t.Parallel()` to each test.**

```go
func TestSomething(t *testing.T) {
	t.Parallel()
	// ...
}
```

**Step 6 — Verify no `os.Getenv` remains inside `run()` or its descendants.**

```sh
grep -n "os\.Getenv" yourfile.go
```

Any remaining calls that must stay (e.g., in an `init()` function) are acceptable but should be documented.

______________________________________________________________________

## B — Boundaries and Blind Spots

**When this pattern applies cleanly:**

- The `run()` function owns program startup; all env-var reads happen within or beneath it.
- Tests already call `run()` (end-to-end testing style).
- The team is comfortable with function-value parameters.

**When it is harder or inapplicable:**

- `os.Getenv` is called in `init()` functions or package-level `var` initializers. Those run before `main()` and cannot be injected. Move config reads into `run()`.
- Third-party libraries call `os.Getenv` internally (e.g., AWS SDK reading `AWS_REGION`). You cannot inject past a library boundary; `t.Setenv` or environment setup at the process level remains necessary for those keys.
- The codebase does not use the `run()` function pattern — injecting `getenv` requires the entry-point refactor first (see `matryer-run-function` skill).
- Very large numbers of keys: the `switch` closure becomes verbose. Consider a `map[string]string` closure helper:

```go
func mapEnv(m map[string]string) func(string) string {
	return func(key string) string {
		if v, ok := m[key]; ok {
			return v
		}
		return ""
	}
}
```

**Common mistakes:**

- Forgetting the `default` branch — keys not explicitly handled return `""`, which may silently break behaviour that relied on a real env var. Use `os.Getenv(key)` as the default if you want pass-through.
- Injecting `getenv` but still calling `os.Getenv` directly inside helper functions called from `run()` — those helpers must also receive `getenv` as a parameter (or accept it via closure capture).
- Using `t.Setenv` alongside the injected pattern in the same test — the `t.Setenv` call will still block `t.Parallel()` even if `run()` never sees it.

______________________________________________________________________

## Related Skills

- **matryer-run-function** — depends-on: `getenv func(string) string` is a parameter of `run()`; adopting this pattern requires the `run()` entry-point refactor first.
- **matryer-run-e2e-testing** — enables: replacing `t.Setenv` with an injected closure removes the parallelism restriction, allowing e2e tests to call `t.Parallel()` freely.
