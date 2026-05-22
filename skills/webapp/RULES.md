# Webapp Rules That Supersede General Go Advice

> **Scope:** These rules apply exclusively to `github.com/Khan/webapp`. Do not
> apply them to any other repository.

These rules are enforced by webapp's custom linters and either directly contradict
widely-accepted Go conventions (including those in `go-advice/summary_rules.md`) or
add restrictions that general Go advice does not impose. They take unconditional
precedence when working in `github.com/Khan/webapp`.

Each rule names the enforcing linter so violations can be understood at CI time.

______________________________________________________________________

## Rule 1: Use Testify via khantest.Suite — Not Stdlib Testing Alone

**Linters:** `ka-suite`, `depguard`

**What webapp requires:** Every test suite must embed `khantest.Suite` and be run
with `khantest.Run(t, &MySuite{})`. Assertion calls must go through
`suite.Assert()` or `suite.Require()` — never through directly imported testify
packages (`testify/assert`, `testify/require`) and never through hand-rolled
helpers.

**What general Go advice says:** *Do not use third-party testing frameworks — use
the stdlib `testing` package only.* Define three per-package helpers (`assert`,
`ok`, `equals`) instead of importing an assertion library. (`summary_rules.md` §10)

**Resolution:** In webapp, the testify-based `khantest.Suite` is not optional. The
hand-rolled helper pattern described in general Go advice, while idiomatic elsewhere,
is explicitly prohibited by `AGENTS.md` and would fail `ka-suite`'s ban on direct
`testify/assert` and `testify/require` usage.

______________________________________________________________________

## Rule 2: Wrap Errors with Key-Value Pairs — Not Op-Path Strings

**Linters:** `ka-errors-stacktrace`, `ka-errors-wrap`, `depguard` (stdlib `errors`)

**What webapp requires:**

```go
// Wrap third-party and sentinel errors before returning
return errors.Wrap(err)
return errors.Wrap(err, "user_id", userID, "operation", "create")
```

- Use `pkg/lib/errors`, never stdlib `errors` or `fmt.Errorf`.
- `errors.Wrap` takes odd-count args; keys must be string literals.
- Sentinels (`var ErrFoo = errors.New(...)`) and all third-party/stdlib errors must
  be wrapped before returning.

**What general Go advice says:** Wrap errors by attaching an `Op` string in
`"package.Type.Method"` format, building a logical call-path stack trace:

```go
return &myapp.Error{Op: "sqlite.UserService.CreateUser", Err: err}
```

The root package defines one `Error` struct with `Code`/`Message` (leaf errors) or
`Op`/`Err` (wrapping errors). (`summary_rules.md` §3)

General Go advice also uses `fmt.Errorf("...: %w", err)` as a lightweight wrapping
idiom in several canonical examples.

**Resolution:** The two error architectures are structurally incompatible. In
webapp, `fmt.Errorf` is banned by `ka-banned-symbol`, stdlib `errors` is banned by
`depguard`, and the Op-string wrapping style does not exist. Use webapp's
`errors.Wrap` with structured key-value context.

______________________________________________________________________

## Rule 3: Never Use `fmt.Errorf`

**Linter:** `ka-banned-symbol`

**What webapp requires:** Create all errors with `pkg/lib/errors.New(...)` or
`pkg/lib/errors.Wrap(err, ...)`. `fmt.Errorf` is banned even for simple
format-and-wrap cases.

**What general Go advice says:** `fmt.Errorf("context: %w", err)` is idiomatic Go
for lightweight error wrapping at boundary layers. `summary_rules.md` uses it in
multiple canonical code examples including association loading, HTTP helpers, and
test helpers.

**Resolution:** Every `fmt.Errorf` call in webapp is a lint failure regardless of
context. Use `errors.Wrap(err, "key", value)` to attach context.

______________________________________________________________________

## Rule 4: Never Use `sync.WaitGroup` — Use `tracegroup`

**Linter:** `ka-banned-symbol`

**What webapp requires:**

```go
// Bad — banned
var wg sync.WaitGroup

// Good
g := tracegroup.New(ctx) // from pkg/external/opentelemetry/tracegroup
g.Go(func(ctx context.Context) error { return doWork(ctx) })
if err := g.Wait(); err != nil { ... }
```

**What general Go advice says:** `sync.WaitGroup` is idiomatic for coordinating
goroutine lifecycle. `summary_rules.md` §7 includes a canonical graceful-shutdown
example using `var wg sync.WaitGroup` / `wg.Add(1)` / `wg.Done()` / `wg.Wait()`.

**Resolution:** `sync.WaitGroup` is banned in all non-test, non-script code.
`tracegroup` propagates OpenTelemetry spans across goroutine boundaries, which
`sync.WaitGroup` cannot. Use `tracegroup.New(ctx)` for all goroutine fan-out.

______________________________________________________________________

## Rule 5: Never Use `golang.org/x/sync/errgroup` — Use `tracegroup`

**Linter:** `depguard`

**What webapp requires:** `golang.org/x/sync/errgroup` is a banned import. Use
`tracegroup` from `pkg/external/opentelemetry/tracegroup` for all parallel-work
fan-in patterns.

**What general Go advice says:** *Use `errgroup` or a fan-in channel to collect
immutable results from parallel goroutines, then process them in the owner
goroutine.* (`summary_rules.md` §11)

**Resolution:** `errgroup` is banned by `depguard`. `tracegroup` satisfies the same
pattern and additionally carries OTel trace context into spawned goroutines.

______________________________________________________________________

## Rule 6: Role-Based Packages Are Enforced — `models/`, `resolvers/`, `services/` Are Load-Bearing

**Linters:** `ka-import`, `ka-banned-symbol` (ADR-312)

**What webapp requires:** The `models/`, `resolvers/`, and `services/` directory
structure is not organizational convention — it is linter-enforced architecture with
hard behavioral rules:

- `models/` must not call `ctx.Datastore()` or `datastore.Transaction`.
- `resolvers/` must not call `ctx.Datastore()` or `datastore.Transaction` (except
  in `backfills.go`).
- `pkg/` must not import `services/`.
- A service must not import another service.

**What general Go advice says:** *Do not group packages by role (`models/`,
`controllers/`, `handlers/`) — causes circular dependency problems.* Name packages
after the dependency they wrap (`sqlite`, `http`, `mock`). (`summary_rules.md` §1)

**Resolution:** webapp was built with role-based structure and its linters enforce
it. The advice to avoid role-based packages applies to new projects, not to webapp.
Restructuring toward dependency-named packages would violate the linter rules.
Work within the existing `models/` / `services/` / `resolvers/` model and respect
the enforced access boundaries.

______________________________________________________________________

## Rule 7: Authorization Goes in Resolvers — Not Only at the Data Layer

**Linter:** `ka-permissions`

**What webapp requires:** Every GraphQL resolver must call at least one function
annotated with `//ka:permission-check` before returning (ADR-211). The check must
be visible at the resolver level — it cannot be satisfied by an implicit check
buried in a SQL WHERE clause or a service layer that the resolver calls.

**What general Go advice says:** *Do not enforce authorization in HTTP handlers or
middleware. Enforce authorization at the lowest level — embedded in SQL `WHERE`
clauses so the database engine enforces it, not application-level filtering after
the fact.* (`summary_rules.md` §6)

**Resolution:** webapp's resolver-layer permission check and data-layer enforcement
are complementary, but the linter requires the resolver-layer check to be explicit
and present. A resolver that relies entirely on a downstream SQL WHERE clause
without calling a `//ka:permission-check` function fails `ka-permissions` regardless
of how thorough the data-layer enforcement is.

______________________________________________________________________

## Rule 8: `stdlib errors` Package Is Banned

**Linter:** `depguard`

**What webapp requires:** Import `github.com/Khan/webapp/pkg/lib/errors` for all
error creation and wrapping. The stdlib `errors` package (`import "errors"`) is a
banned import.

**What general Go advice says:** The stdlib `errors` package is not restricted.
`errors.New`, `errors.Is`, `errors.As`, and `errors.Unwrap` from stdlib are
standard idiomatic Go. General advice does not ban them.

**Resolution:** `import "errors"` fails `depguard`. Use `pkg/lib/errors` for
`New`, `Wrap`, and error inspection. `errors.Is` and `errors.As` from stdlib are
available through the webapp errors package or can be called on the stdlib error
values through the webapp package's re-exports.

______________________________________________________________________

## Rule 9: Time Injection Goes Through `ctx` — Not Through a `Clock` Parameter

**Linter:** `ka-banned-symbol`

**What webapp requires:**

```go
// Bad — banned
now := time.Now()
elapsed := time.Since(start)

// Good
now := ctx.Time().Now()
elapsed := ctx.Time().Since(start)
```

**What general Go advice says:** Inject time via a `Clock` interface
(`type Clock interface { Now() time.Time }`) passed as a function parameter or
stored in a struct field. This makes time testable without threading it through
every call in the application. (`summary_rules.md` §11)

General Go advice also uses `time.Now()` freely in test-helper code (e.g., in
`waitForReady` polling loops).

**Resolution:** In webapp, `time.Now()` and `time.Since()` are banned by
`ka-banned-symbol`. The injection mechanism is `ctx.Time()` rather than a separate
`Clock` parameter — the kacontext carries a replaceable time source. Using a
`Clock` interface as a separate parameter is not idiomatic in webapp and would still
leave `time.Now()` calls (which the linter would flag).

______________________________________________________________________

## Summary: What Webapp Overrides

| General Go advice                                        | webapp linter rule                                | Linter                                   |
| -------------------------------------------------------- | ------------------------------------------------- | ---------------------------------------- |
| stdlib `testing` only; no assertion library              | `khantest.Suite` required                         | `ka-suite`, `depguard`                   |
| Op-string error wrapping (`{Op: "pkg.T.M", Err: err}`)   | Key-value `errors.Wrap(err, "k", v)`              | `ka-errors-wrap`, `ka-errors-stacktrace` |
| `fmt.Errorf` as lightweight wrapper                      | `fmt.Errorf` banned                               | `ka-banned-symbol`                       |
| `sync.WaitGroup` for goroutine lifecycle                 | `sync.WaitGroup` banned; use `tracegroup`         | `ka-banned-symbol`                       |
| `errgroup` for fan-in                                    | `errgroup` banned; use `tracegroup`               | `depguard`                               |
| Avoid role-based packages (`models/`, etc.)              | `models/`, `resolvers/`, `services/` are enforced | `ka-import`, `ka-banned-symbol`          |
| Authorization at data layer (SQL WHERE), not in handlers | Permission check required in every resolver       | `ka-permissions`                         |
| stdlib `errors` package unrestricted                     | stdlib `errors` banned                            | `depguard`                               |
| `Clock` interface injected as parameter                  | `ctx.Time().Now()` / `ctx.Time().Since()`         | `ka-banned-symbol`                       |
