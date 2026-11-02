---
name: webapp
description: |
  Use when writing or reviewing any Go code in github.com/Khan/webapp. Covers all 31 custom linters and key standard linters enforced at CI. ONLY applies to github.com/Khan/webapp — do not apply these rules to any other repository.
allowed-tools: Bash, Read, Edit, Write
---

# Khan Academy Webapp Go Coding Guidelines

> **Scope:** These rules apply exclusively to `github.com/Khan/webapp`. Do not
> apply them to any other repository — the custom linter binary, banned-symbol
> lists, package conventions, and KAContext system are all webapp-specific.

All rules below are enforced by the customized golangci-lint binary at CI time.
The linters' source in the webapp checkout is the full specification, including edge
cases.
A `//nolint:linter-name // reason` comment can suppress a rule for one line —
but `nolintlint` enforces that the linter name and reason are always present.

______________________________________________________________________

## Quick-Reference Cheat Sheet

The most-commonly violated rules at a glance. ✓ = auto-fixable.

| Violation                                   | Linter                    | Fix                                                                |
| ------------------------------------------- | ------------------------- | ------------------------------------------------------------------ |
| `fmt.Errorf(...)`                           | `ka-banned-symbol`        | `errors.New(...)` or `errors.Wrap(err, ...)` from `pkg/lib/errors` |
| `errors.Wrap(err, "key")` (even arg count)  | `ka-errors-wrap`          | `errors.Wrap(err)` or `errors.Wrap(err, "key", val)`               |
| Third-party error returned unwrapped        | `ka-errors-stacktrace` ✓  | `errors.Wrap(err)`                                                 |
| Log error AND return it                     | `ka-log-or-return-error`  | Choose one: log OR return                                          |
| `errors.Is(sentinel, err)` (reversed)       | `ka-errors-arguments`     | `errors.Is(err, sentinel)`                                         |
| `context.Background()` in non-init/main     | `ka-context`              | Receive `ctx` from caller                                          |
| `ctx` not first parameter                   | `ka-context`              | Move `ctx context.Context` to position 0                           |
| `time.Now()` / `time.Since()`               | `ka-banned-symbol`        | `ctx.Time().Now()` / `ctx.Time().Since()`                          |
| `sync.WaitGroup`                            | `ka-banned-symbol`        | `tracegroup.New(ctx)`                                              |
| `http.NewRequest(...)`                      | `ka-banned-symbol`        | `http.NewRequestWithContext(ctx, ...)`                             |
| `http.Error(...)` without `return`          | `ka-http-return`          | Add `return` immediately after                                     |
| `os.Setenv` in tests                        | `ka-banned-symbol`        | `suite.Setenv(...)`                                                |
| `const MY_CONST = ...` (screaming snake)    | `ka-no-screaming-snake` ✓ | `const MyConst = ...`                                              |
| Resolver missing permission check           | `ka-permissions`          | Call a `//ka:permission-check` function                            |
| Mutation resolver returns `error`           | `ka-resolver-error`       | Put error in response struct (ADR-303)                             |
| `datastore.NameKey(...)` in service code    | `ka-banned-symbol`        | `MakeMyModelKey(id)`                                               |
| `io.Closer` not closed                      | `ka-always-close`         | `defer obj.Close()`                                                |
| Exported fn in multi-file pkg, no doc       | `ka-documentation`        | Add `// FuncName does...` comment                                  |
| Import `errors` (stdlib)                    | `depguard`                | `github.com/Khan/webapp/pkg/lib/errors`                            |
| Import `github.com/stretchr/testify/assert` | `depguard`                | `suite.Assert()`                                                   |

______________________________________________________________________

## Reference Files

The detailed rules, with bad/good examples and edge cases, live in
`references/`. Read only the file for the area you are touching:

- [`references/linting-infrastructure.md`](references/linting-infrastructure.md)
  — read when `make lint` or `make linc` fails with a plugin-load or
  binary-not-found error, or to map a `ka-` linter to its plugin.
- [`references/error-handling.md`](references/error-handling.md) — read when
  creating, wrapping, comparing, or logging errors (`pkg/lib/errors` imports,
  converting `fmt.Errorf`, `errors.Wrap` arguments, log-or-return).
- [`references/context-logging-time-http.md`](references/context-logging-time-http.md)
  — read when a function takes `ctx`, logs, reads the time, runs goroutines, or
  sends or answers HTTP requests.
- [`references/testing.md`](references/testing.md) — read when writing tests:
  suite setup, `ka-suite` assertions, lifecycle methods, envvars in tests.
- [`references/datastore.md`](references/datastore.md) — read when defining a
  model, building keys, writing a transaction, or handling not-found.
- [`references/graphql.md`](references/graphql.md) — read when writing a
  resolver or mutation, or calling another service.
- [`references/naming-imports-misc.md`](references/naming-imports-misc.md) —
  read for naming rules, import and package boundaries (banned packages), and
  the miscellaneous rules: `io.Closer`, comparisons, JSON tags, doc comments,
  line length, cache ordering, and `//nolint` format.

______________________________________________________________________

## Pull Requests

**Never open a webapp PR against `master`.** webapp deploys through
per-developer branches, so `master` is the wrong integration point. Base the PR
on the author's personal deploy branch:

```bash
gh pr create --base "$MY_DEPLOY_BRANCH" --head my-feature-branch
```

Branch names are per-user, so this skill cannot name yours — keep it wherever
your per-user preferences live and confirm the base before creating.

Check it up front: **a closed PR's base cannot be changed.** `gh pr edit --base`
fails with `Cannot change the base branch of a closed pull request`, so getting
it wrong means opening a replacement.

`git push` runs a pre-push hook that invokes `ka-lint`, which lives at
`testing/ka-lint` (a symlink to `tools/runlint.sh`). If `webapp/testing` is not
on your `PATH` the push aborts with `FileNotFoundError: 'ka-lint'`. Put it on
`PATH` rather than reaching for `--no-verify`:

```bash
PATH="$PWD/testing:$PATH" git push -u origin my-feature-branch
```

______________________________________________________________________

## Code Review Checklist

Walk through these for every PR touching Go code in webapp.

## Error Handling

- [ ] `pkg/lib/errors` used (not stdlib `errors`, not `fmt.Errorf`)
- [ ] Sentinel and third-party errors wrapped with `errors.Wrap`
- [ ] `errors.Wrap` argument count is odd; keys are string literals
- [ ] `errors.Is`/`errors.As` arguments are in correct order
- [ ] Errors are logged OR returned — not both

## Context

- [ ] `ctx` is first parameter in every function that takes a context
- [ ] No `context.Background()` outside init/main
- [ ] `kacontext.Upgrade()` only at approved call sites
- [ ] KAContext interfaces embed only what is used

## Logging / Output

- [ ] `ctx.Log()` only — no stdlib `log`, no `fmt.Print*` in server code
- [ ] Log messages are fixed strings; variables are in `log.Fields`

## Time / Concurrency

- [ ] `ctx.Time().Now()` and `ctx.Time().Since()` used (not `time.Now`/`time.Since`)
- [ ] `tracegroup` used instead of `sync.WaitGroup`

## HTTP

- [ ] `ctx.HTTP()` for outbound requests; `http.NewRequestWithContext`
- [ ] `return` immediately after `http.Error`/`http.Redirect`

## Testing

- [ ] `khantest.Suite` embedded; `khantest.Run` used
- [ ] `suite.Require()` outside `All`; `suite.Assert()` inside `All`
- [ ] Lifecycle methods call their `super` counterpart
- [ ] `suite.Setenv` used (not `os.Setenv`)

## Datastore

- [ ] Model embeds `BaseModel`; all fields tagged; `PreSave` calls both super and `CheckTransactionSafetyForPut`
- [ ] Slice fields have no `omitempty`; struct and time fields do
- [ ] `MakeModelKey()` used (not raw `datastore.NameKey`/`IDKey`)
- [ ] Outer variables re-initialized at top of `RunInTransaction` closures
- [ ] No `(nil, nil)` returns from Get functions
- [ ] No direct datastore calls in `models/` or `resolvers/`

## GraphQL

- [ ] Every resolver calls a `//ka:permission-check` function
- [ ] Mutation resolvers put errors in the response struct (not `error` return)
- [ ] genqlient calls only from `cross_service/`
- [ ] Resolver body is thin — delegates work to a service function; no business logic embedded in the resolver

## Tasks / Pub/Sub

- [ ] Handler is idempotent — delivering the same message or task twice produces the same result
- [ ] Permanent failures (bad payload, schema mismatch) ack/consume the message; transient failures return an error to trigger retry

## Naming / Imports

- [ ] No `SCREAMING_SNAKE_CASE` exported identifiers
- [ ] `_`-prefixed identifiers not referenced from other files
- [ ] No banned terminology in identifiers
- [ ] No banned package imports (see [`references/naming-imports-misc.md`](references/naming-imports-misc.md))
- [ ] `pkg` does not import `services/`; services do not import each other

## Miscellaneous

- [ ] `io.Closer` objects closed (preferably with `defer`)
- [ ] `.Equal()`/`.Before()`/`.After()` used instead of `==`/`<`/`>`
- [ ] JSON-marshalled structs have `json:"..."` tags on all exported fields
- [ ] Exported functions documented in multi-file packages
- [ ] `//nolint` comments name the linter and include a reason

## Pull Request

- [ ] Base branch is the author's deploy branch, never `master`
