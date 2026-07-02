---
name: go-http-service-di-composition
description: |
  Invoke when wiring a Go HTTP service's dependency injection from the entrypoint down to handlers — specifically when choosing how to make startup logic testable, how to inject shared handler dependencies, and how to compose both concerns without globals.
tags: []
allowed-tools: Bash, Read, Edit
---

# Go Http Service Di Composition

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

run() functions:
!`grep -rn '^func run(' --include='*.go' . 2>/dev/null | head -5`

Application/server struct definitions:
!`grep -rn '^type application struct\|^type app struct\|^type server struct\|^type Server struct' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -5`

Package-level vars (global state risk):
!`grep -rn '^var ' --include='*.go' . 2>/dev/null | grep -v '_test.go\|_gen.go' | head -10`

### R — Reading

> "A neat way to inject dependencies is to put them into a custom `application` struct, and then define your handler functions as methods against application. [...] We just need to initialize all our dependencies in `main()`, then use them to construct the `application` struct, and then wire up our routes."
>
> — Alex Edwards, *Let's Go*
>
> "The `run` function is like the `main` function, except that it takes in operating system fundamentals as arguments, and returns, you guessed it, an error. [...] If you keep away from any global scope data, you can usually use `t.Parallel()` in more places, to speed up your test suites. Everything is self-contained, so multiple calls to `run` don't interfere with each other."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*

**Convergence note:** Both sources share the same meta-principle — all dependencies must be explicit, constructor-available, and global-state-free — and both name testability as the primary motivation; Edwards focuses on the handler layer (struct fields, mock injection via newTestApplication), while Ryer focuses on the entrypoint layer (run() parameters, getenv injection, parallel-safe startup tests), and a third source (rednafi's manual-dependency-injection) independently confirms that "the call order is the dependency graph" and that the Go compiler enforces it without a framework.

______________________________________________________________________

### I — Unified Framework

Go HTTP service dependency injection operates at two architectural layers that **compose rather than compete**. Neither pattern replaces the other; a complete service uses both.

## R — Reading

> "A neat way to inject dependencies is to put them into a custom `application` struct, and then define your handler functions as methods against application. [...] We just need to initialize all our dependencies in `main()`, then use them to construct the `application` struct, and then wire up our routes."
>
> — Alex Edwards, *Let's Go*
>
> "The `run` function is like the `main` function, except that it takes in operating system fundamentals as arguments, and returns, you guessed it, an error. [...] If you keep away from any global scope data, you can usually use `t.Parallel()` in more places, to speed up your test suites. Everything is self-contained, so multiple calls to `run` don't interfere with each other."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*

**Convergence note:** Both sources share the same meta-principle — all dependencies must be explicit, constructor-available, and global-state-free — and both name testability as the primary motivation; Edwards focuses on the handler layer (struct fields, mock injection via newTestApplication), while Ryer focuses on the entrypoint layer (run() parameters, getenv injection, parallel-safe startup tests), and a third source (rednafi's manual-dependency-injection) independently confirms that "the call order is the dependency graph" and that the Go compiler enforces it without a framework.

______________________________________________________________________

## I — Unified Framework

Go HTTP service dependency injection operates at two architectural layers that **compose rather than compete**. Neither pattern replaces the other; a complete service uses both.

### Layer 1 — Entrypoint Layer: Ryer's Run()

`func main()` has two irremovable problems: it cannot return an error, and it cannot accept arguments. Both limitations make startup logic impossible to test directly. The fix: extract all real work into a `run()` function that accepts everything `main()` would reach for via global state as explicit parameters.

```go
func run(
	ctx context.Context,
	args []string,
	getenv func(string) string,
	stdin io.Reader,
	stdout, stderr io.Writer,
) error {
	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()
	// construct dependencies, build application struct, start server
	return nil
}

func main() {
	ctx := context.Background()
	if err := run(ctx, os.Args, os.Getenv, os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
```

`run()` enables: calling the program from tests with controlled arguments, running multiple tests concurrently via `t.Parallel()` (no global state is mutated), and per-test server lifetime control via `context.WithCancel` + `t.Cleanup(cancel)`.

**Key discipline:** Use `flag.NewFlagSet` inside `run()`, not the global `flag.Parse`. Global flag state is shared across goroutines; `NewFlagSet` is scoped to the call.

**getenv injection:** Replace all `os.Getenv` calls in `run()` and its callees with `getenv("KEY")` calls on the parameter. In production `main()` passes `os.Getenv` directly. In tests a closure returns controlled values per key. This beats `t.SetEnv` because `t.SetEnv` mutates the real process environment and forces Go's test runner to serialize tests that use it.

### Layer 2 — Handler Layer: Edwards's Application Struct

> ⚠ **Conflict with summary_rules.md §7 (Shape A / HTTP Services):** The handler layer described below uses the Edwards struct-receiver pattern — handlers as methods on `*application`. `summary_rules.md §7` explicitly rejects this: "Handlers used to be methods on a server struct, but I no longer do this." The summary prescribes the maker-func pattern instead:
>
> ```go
> func handleFoo(logger *Logger, store *Store) http.Handler {
> 	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
> 	})
> }
> ```
>
> The `run()` entrypoint layer (Layer 1, Ryer) is fully aligned with `summary_rules.md`. The handler layer (Layer 2, Edwards) is not — these are architecturally incompatible handler shapes. **Choose one pattern per codebase.** If following `summary_rules.md`, use maker-funcs and `NewServer(logger, store) http.Handler` with `addRoutes`. The struct-receiver pattern is documented here as a widely-used community pattern (Edwards/Let's Go), not as the summary's prescribed approach.

Inside `run()`, all shared dependencies are constructed and assembled into an `application` struct. Handler functions are methods on that struct — not standalone functions, not closures capturing mutable globals.

```go
// inside run():
app := &application{
	logger:         slog.New(slog.NewTextHandler(os.Stdout, nil)),
	snippets:       &models.SnippetModel{DB: db},
	users:          &models.UserModel{DB: db},
	templateCache:  templateCache,
	formDecoder:    formDecoder,
	sessionManager: sessionManager,
}
srv := &http.Server{Handler: app.routes()}
```

Every handler is then a method:

```go
func (app *application) home(w http.ResponseWriter, r *http.Request) {
	snippets, err := app.snippets.Latest()
	// ...
}
```

The struct grows as the application grows — each new dependency is one field and one assignment in `run()`. Nothing else changes. The pattern scales to twenty fields without architectural revision.

**Handler-level testing:** `newTestApplication(t)` substitutes mocks for any subset of fields:

```go
func newTestApplication(t *testing.T) *application {
	return &application{
		logger:         slog.New(slog.NewTextHandler(io.Discard, nil)),
		snippets:       &mocks.SnippetModel{},
		users:          &mocks.UserModel{},
		templateCache:  tc,
		formDecoder:    formDecoder,
		sessionManager: sessionManager,
	}
}
```

The handler code is identical in production and test — only the struct contents differ. Global variables cannot be swapped in parallel tests without data races. Only the struct-receiver pattern makes mock injection trivial and race-free.

### How the Two Layers Compose

`run()` is the composition root. It constructs the `application` struct and hands it to `http.ListenAndServe`. The two layers address different architectural concerns that happen at different times:

- `run()` parameters: injected once at program startup; control startup behavior, flag parsing, and stream I/O
- `application` struct fields: injected once at server construction; control per-request behavior for all handlers

Tests using `go run(ctx, ...)` exercise the full program (startup logic, flag parsing, graceful shutdown). Tests using `newTestApplication(t)` exercise individual handlers (business logic, mock substitution). Both testing strategies are available simultaneously, and they do not conflict.

**rednafi's confirming principle:** "The call order is the dependency graph. Errors are handled right where they happen. If a constructor changes, the compiler points straight at every broken call. No reflection, no generated code, no global state." — rednafi, *Go Advice*. `run()` and the `application` struct assembly are both manifestations of this: explicit, ordered, compiler-checked.

______________________________________________________________________

## A1 — Past Application

### Case 1: Snippetbox — Application Struct Across Six Chapters (Let's Go)

Edwards builds the Snippetbox CMS incrementally. The `application` struct gains fields across chapters — `logger`, `snippets`, `templateCache`, `formDecoder`, `sessionManager`, `users` — and the pattern never changes shape. In Chapter 13, `newTestApplication(t)` swaps in `&mocks.SnippetModel{}` and `&mocks.UserModel{}`. The production handler code is exercised without a real database or TLS server.

**What this demonstrates:** The struct-receiver pattern scales across six chapters and hundreds of lines of handler code without architectural revision. Each new dependency is one field addition; no handler function signature changes.

### Case 2: Getenv Injection — Parallel-Safe Environment Variable Control (Matryer)

Problem: tests calling `os.Getenv("DATABASE_URL")` cannot run in parallel because `t.SetEnv` serializes the test runner. Method: replace all `os.Getenv` calls in `run()` with a `getenv func(string) string` parameter; tests pass a closure switching on key name.

```go
func TestRun(t *testing.T) {
	t.Parallel()
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)
	getenv := func(key string) string {
		switch key {
		case "MYAPP_FORMAT":
			return "json"
		default:
			return ""
		}
	}
	go run(ctx, []string{"myapp", "--addr", "localhost:0"}, getenv, nil, &bytes.Buffer{}, &bytes.Buffer{})
	// wait for readiness, assert
}
```

**What this demonstrates:** `run()` as a testable entrypoint gives `t.Parallel()` everywhere without flakiness. Inside `run()`, the `application` struct is constructed with the same dependency values the test controls via `getenv`.

______________________________________________________________________

## A2 — Trigger ★

**Use this skill when:**

- You are starting a new Go HTTP service with more than one shared dependency and need to decide how to wire them without globals.
- Your existing service reads `os.Getenv` and parses `flag.Parse()` inside `main()` — tests cannot exercise startup configuration without process environment mutation.
- Tests pass in isolation but fail randomly when run together because they share `flag.CommandLine` (second call to `flag.Parse()` panics with "flag redefined").
- You are retrofitting a service that uses package-level globals and has test-isolation problems.
- You want to add `t.Parallel()` across your test suite but cannot because tests mutate shared state.
- A new team member asks why certain tests must run sequentially.

**Three distinct testing scenarios this skill addresses:**

1. Handler-level tests: `newTestApplication(t)` with mocks for `snippets`, `users`, etc. (Edwards)
2. End-to-end tests: `go run(ctx, args, getenv, ...)` in a goroutine with context cancellation per test (Ryer)
3. Flag/env-variable isolation: `getenv` closure per test, no process environment mutation (Ryer)

______________________________________________________________________

## E — Execution

## Step 1 — Extract Run() from Main()

Move all startup logic into `run(ctx context.Context, args []string, getenv func(string) string, stdin io.Reader, stdout, stderr io.Writer) error`. The original Matryer pattern places `signal.NotifyContext` inside `run()` with `defer cancel()`. `summary_rules.md §7` Shape A places it in `main()` instead, calling `stop()` explicitly before `os.Exit(1)` — because `os.Exit` bypasses deferred functions, a `defer cancel()` inside `run()` would leak the signal goroutine on the error path. Follow whichever form your codebase has adopted; for new code, prefer the `main()` placement.

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

`fs := flag.NewFlagSet(args[0], flag.ContinueOnError)` scopes the flag set to this call. Replace all `os.Getenv` calls with `getenv("KEY")`.

## Step 4 — Inside Run(), Construct the Application Struct

Assemble all shared dependencies — DB connections, template caches, session managers, model structs — into `app := &application{...}`. Use interface types for any field that needs mocking in tests (`SnippetModelInterface`, not `*models.SnippetModel`).

**Step 5 — Write handlers** *(see conflict note in I section)*

> ⚠ **If following summary_rules.md §7:** Use maker-funcs, not struct-receiver methods:
>
> ```go
> func handleHome(logger *slog.Logger, snippets SnippetModelInterface) http.Handler {
> 	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
> 	})
> }
>
> // In addRoutes():
> // mux.Handle("GET /", handleHome(logger, snippets))
> ```
>
> **If using the Edwards pattern (this skill, not summary_rules.md):** Write handlers as methods on `*application`:
>
> ```go
> func (app *application) home(w http.ResponseWriter, r *http.Request) {}
> ```
>
> No closure captures. No globals. All handler dependencies come through `app`.

Choose one pattern. Do not mix struct-receiver handlers and maker-func handlers in the same codebase.

## Step 6 — Create newTestApplication(t) for Handler Tests

```go
func newTestApplication(t *testing.T) *application {
	return &application{
		logger:   slog.New(slog.NewTextHandler(io.Discard, nil)),
		snippets: &mocks.SnippetModel{},
		users:    &mocks.UserModel{},
		// ... other fields
	}
}
```

## Step 7 — Write Run() Tests for Startup-Level Concerns

```go
func TestRun(t *testing.T) {
	t.Parallel()
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(cancel)
	go run(ctx, []string{"app", "--addr", "localhost:0"}, func(k string) string { return "" }, nil, &bytes.Buffer{}, &bytes.Buffer{})
	// waitForReady, then make assertions
}
```

## Step 8 — Verify No Global State Remains

Audit for `os.Getenv`, `flag.Parse`, `flag.CommandLine`, `os.Args`, or package-level variables written during startup. Each is a parallel-safety hazard.

______________________________________________________________________

## B — Boundary

### Conflict with Summary_rules.md §7 (Shape a — HTTP Services)

This merged skill teaches two patterns at different architectural layers:

- **Layer 1 (`run()` entrypoint, Ryer):** Fully aligned with `summary_rules.md §7` Shape A — `run()` accepts OS primitives as params and returns `error`.
- **Layer 2 (handler layer, Edwards):** Architecturally incompatible with `summary_rules.md §7`, which explicitly rejects struct-receiver handlers in favour of maker-funcs. **Do not apply Layer 2 if your codebase follows `summary_rules.md`.**

The conflict is confined to the handler layer. Apply Layer 1 (`run()`) universally; confirm your handler pattern before applying Layer 2.

### Source a Failures (Edwards / Let's Go)

- Package-level globals as dependency carriers — cannot be swapped in parallel tests without data races.
- Closures that capture mutable state at definition time — bake in dependencies before the test can substitute them.
- Pattern inapplicable for trivial single-handler scripts, though starting with it costs nothing.
- Does not address graceful shutdown (that is `http.Server.Shutdown`, not a struct concern), distributed tracing, or multiple entrypoints.

### Source B Failures (Ryer / Matryer)

- **Signature drift:** The more dependencies a program has, the longer `run()`'s parameter list grows. A struct-of-dependencies alternative is not discussed; teams with many parameters may find that approach cleaner, but the author acknowledges the tradeoff without prescribing a limit.
- **getenv stub only covers run():** If any package-level `init()` reads `os.Getenv`, the injection cannot reach it. The pattern assumes all environment reads happen inside `run()` or its callees.
- **Context propagation is required but not enforced:** Graceful shutdown only works if every goroutine respects the context. The compiler does not enforce this. Tests relying on `t.Cleanup(cancel)` for server shutdown will hang if any code path ignores the context.
- **signal.NotifyContext placement:** The original Matryer talk placed `signal.NotifyContext` inside `run()`. `summary_rules.md §7` Shape A subsequently moved it to `main()` with `defer stop()` (or explicit `stop()` before `os.Exit`), so that `stop()` fires even if `run()` returns an error and the caller calls `os.Exit(1)` — ensuring the signal goroutine is always released. Either placement is structurally correct; the summary's `main()` placement is more robust. Do not omit the `stop()` call entirely — that leaks the signal goroutine.
- No guidance on test ports — starting a server in tests requires a free port; using `:0` (OS-assigned ports) is not covered here (see matryer-waitfor-ready).

### Synthesis-Specific Failure Mode

**Treating run() and the application struct as alternatives rather than layers.** Developers who learn Ryer's pattern sometimes eliminate the `application` struct, accumulating all dependencies as closures or locals inside `run()`. Developers who learn Edwards's pattern sometimes leave startup logic in `main()`, making it untestable. The correct composition is: `run()` constructs the `application` struct; the struct carries dependencies to handlers. Applying only one layer produces either untestable startup logic (Edwards alone) or no coherent handler dependency model (Ryer alone). The synthesis failure is invisible until you try to write both kinds of test — handler-level mock injection AND parallel-safe startup tests — and find that one or the other is structurally blocked.

> **Note on quote accuracy:** Edwards's source text says "a neat way" not "the cleanest way" — the source SKILL.md paraphrased this. The merged skill uses the correct verbatim quote.

______________________________________________________________________

## Provenance

- **Merged from:** Let's Go (Alex Edwards); How I Write HTTP Services in Go After 13 Years (Mat Ryer)
- **Type:** merged-skill
- **Related skills:** lets-go/letsgo-application-struct-di (supersedes; Merged into go-http-service-di-composition; source covers the application struct pattern and newTestApplication(t) handler-level mocking.); matryer-http-services/matryer-run-function (supersedes; Merged into go-http-service-di-composition; source covers the run() entrypoint pattern, getenv injection, and parallel-safe startup testing.); rednafi/manual-dependency-injection (composes-with; Third convergence source; independently confirms "pass values into constructors, main() is the DI container" principle and the anti-DI-framework argument.)
