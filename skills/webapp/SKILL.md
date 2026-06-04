---
name: webapp
description: Use when writing or reviewing any Go code in github.com/Khan/webapp. Covers all 31 custom linters and key standard linters enforced at CI. ONLY applies to github.com/Khan/webapp — do not apply these rules to any other repository.
allowed-tools: Bash, Read, Edit, Write
---

# Khan Academy Webapp Go Coding Guidelines

> **Scope:** These rules apply exclusively to `github.com/Khan/webapp`. Do not
> apply them to any other repository — the custom linter binary, banned-symbol
> lists, package conventions, and KAContext system are all webapp-specific.

All rules below are enforced by the customized golangci-lint binary at CI time.
Full linter specification (including source paths and edge cases) lives at
`/Users/steve/Documents/agent-orange/webapp_linters_spec.md`.
A `//nolint:linter-name // reason` comment can suppress a rule for one line —
but `nolintlint` enforces that the linter name and reason are always present.

______________________________________________________________________

## Linting Infrastructure

### How the Custom Binary Is Built

webapp does **not** use an upstream golangci-lint release. It builds the binary
from source at `genfiles/go/bin/golangci-lint` using `go build` against the
version pinned in `go.mod`, stamped with `main.version=khan-local`. This means
the exact binary version is tied to the repo's Go module graph.

In addition to the upstream binary, webapp compiles 30 custom linter plugins as
Go shared objects (`-buildmode=plugin`) under `genfiles/go/plugins/linters/*.so`.
Every rule prefixed `ka-` in the cheat sheet above comes from one of these plugins.

### Rebuilding the Linting Tools

Two Make targets handle this (both live in the root `webapp/` Makefile):

```bash
# Rebuild only the golangci-lint binary
# Deps: go.mod, current Go version
make -B genfiles/go/bin/golangci-lint

# Rebuild the binary AND all 30 custom plugin .so files
# This is what runlint/quicklinc actually need
make -B go_lint_deps
```

`-B` forces an unconditional rebuild regardless of timestamps — use it when the
binary or a plugin is stale or missing. Without `-B` Make skips the target if
the output file already exists and its declared inputs haven't changed.

`go_lint_deps` is the target called by `dev/testing/cmd/runlint` before linting.
Running it manually is the right fix when `make lint` or `make linc` fails with
a plugin load error or a binary-not-found error.

### Custom Plugin List

Each plugin source lives at `dev/linters/plugins/<name>/main.go` and compiles
to `genfiles/go/plugins/linters/<name>.so`:

| Plugin                   | Rule enforced (see sections above)               |
| ------------------------ | ------------------------------------------------ |
| `always-close`           | `ka-always-close` — defer Close on io.Closer     |
| `backfill-cedar`         | enforces backfill patterns                       |
| `banned-symbol`          | `ka-banned-symbol` — forbidden APIs              |
| `cache`                  | `ka-cache` — cache ordering rules                |
| `compare`                | `ka-compare` — use `.Equal`/`.Before`/`.After`   |
| `context`                | `ka-context` — ctx first param, no Background    |
| `context-interface`      | `ka-context-interface` — embed only what you use |
| `cross-service`          | `ka-cross-service` — genqlient call boundaries   |
| `datastore-model`        | `ka-datastore-model` — model struct rules        |
| `datastore-not-found`    | `ka-datastore-not-found` — no (nil, nil) return  |
| `datastore-transaction`  | `ka-datastore-transaction` — re-init in closure  |
| `deprecated-terminology` | `ka-deprecated-terminology` — banned word list   |
| `documentation`          | `ka-documentation` — exported fn doc comments    |
| `errors-arguments`       | `ka-errors-arguments` — Is/As arg order          |
| `errors-stacktrace`      | `ka-errors-stacktrace` — wrap third-party errors |
| `errors-wrap`            | `ka-errors-wrap` — odd arg count, string keys    |
| `eval-component`         | `ka-eval-component`                              |
| `genqlient`              | `ka-genqlient` — genqlient usage rules           |
| `graphql-task`           | `ka-graphql-task`                                |
| `http-return`            | `ka-http-return` — return after http.Error       |
| `import`                 | `ka-import` — service/pkg boundary enforcement   |
| `json-tag`               | `ka-json-tag` — explicit json struct tags        |
| `linewrap`               | `ka-linewrap` — 80/100 char line limits          |
| `log`                    | `ka-log` — no fmt.Sprintf in log messages        |
| `log-or-return-error`    | `ka-log-or-return-error` — log OR return         |
| `no-screaming-snake`     | `ka-no-screaming-snake` — no SCREAMING_SNAKE     |
| `permissions`            | `ka-permissions` — resolver permission checks    |
| `resolver-error`         | `ka-resolver-error` — error in response struct   |
| `suite`                  | `ka-suite` — khantest.Suite assertions           |
| `visiblity`              | `ka-visibility` — `_`-prefixed file-private      |

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

## Error Handling

### Imports

Always use webapp's error package, never stdlib:

```go
// Bad — use stdlib errors/fmt
// import "errors"
// import "fmt"
func badErr(err error) error {
	return fmt.Errorf("not found: %w", err)
}

// Good — use github.com/Khan/webapp/pkg/lib/errors
func goodErr(err error) error {
	return errors.New("bad input")
}
```

### Converting `fmt.Errorf` Calls

`errors.Wrap` does **not** accept a format string. Every interpolated value in
the original `fmt.Errorf` becomes a `"key", value` pair. Keys are string
literals; the leading sentence stays plain text.

```go
// Bad — fmt.Errorf is banned (ka-banned-symbol)
func badCreate(id string, err error) error {
	return fmt.Errorf("creating user %s: %w", id, err)
}

func badValidate(score int, kaid string, err error) error {
	return fmt.Errorf("invalid score %d for kaid %s: %w", score, kaid, err)
}

// Good — same context, no format string; each %-placeholder becomes a key/val pair
func goodCreate(id string, err error) error {
	return errors.Wrap(err, "operation", "createUser", "user_id", id)
}

func goodValidate(score int, kaid string, err error) error {
	return errors.Wrap(err, "operation", "validateScore", "score", score, "kaid", kaid)
}

// Bad — fmt.Errorf with no wrapped error
func badRange(score int) error {
	return fmt.Errorf("score %d out of range", score)
}

// Good — errors.New for the message; Wrap adds fields
func goodRange(score int) error {
	return errors.Wrap(errors.New("score out of range"), "score", score)
}
```

Common keys: `"operation"` (verb/function name), `"user_id"`/`"kaid"`,
`"resource_id"`, `"input"` (the raw user input). Drop English connectives
like "while" / "when" / ": failed to" — the wrapped chain already carries
that meaning.

### Wrapping Rules (`ka-errors-stacktrace`)

Wrap **sentinel errors** and **third-party/stdlib errors** before returning.
This captures the call-site stack trace. The linter auto-fixes these.

```go
var ErrNotFound = errors.New("not found")

// Bad — sentinel and stdlib errors returned bare
func badWrap() error {
	return ErrNotFound
}

// Good
func goodWrap() error {
	return errors.Wrap(ErrNotFound)
}

// Bad — third-party call result not wrapped
func badThirdParty(b []byte, v any) error {
	_, err := json.Marshal(v)
	return err
}

// Good
func goodThirdParty(b []byte, v any) error {
	if _, err := json.Marshal(v); err != nil {
		return errors.Wrap(err)
	}
	return nil
}
```

Internal webapp errors returned directly are fine — they already carry a trace.

### `errors.Wrap` Argument Format (`ka-errors-wrap`)

```text
errors.Wrap(err)
errors.Wrap(err, "key", value)
errors.Wrap(err, "key1", val1, "key2", val2)
```

Rules: total arg count is odd; every key must be a **string literal**.

```go
// Bad — even count
errors.Wrap(err, "key1")

// Bad — variable key
errors.Wrap(err, keyVar, value)

// Good
errors.Wrap(err, "user_id", userID)
```

### Argument Order (`ka-errors-arguments`)

```go
// Bad — arguments reversed
errors.Is(ErrNotFound, err)
errors.As(myErrType, err) // missing &

// Good
errors.Is(err, ErrNotFound) // local var first, sentinel second
var myErr *MyError
errors.As(err, &myErr) // local var first, reference second
```

### Log OR Return — Never Both (`ka-log-or-return-error`)

```go
// Bad — double-reporting
if err != nil {
	ctx.Log().Error(errors.Wrap(err))
	return err // err will be logged again higher up the stack
}

// Good — return and let the caller decide
if err != nil {
	return errors.Wrap(err, "operation", "createUser")
}

// Also fine — log and swallow (when caller doesn't need to know)
if err != nil {
	ctx.Log().Error(errors.Wrap(err, "job", "backgroundSync"))
}
```

______________________________________________________________________

## Context

### First Parameter, Named `ctx` (`ka-context`)

```go
// Bad
func doWork(name string, ctx context.Context) {}
func doWork(c context.Context)                {}

// Good
func doWork(ctx context.Context, name string) {}
```

### No `context.Background()` Outside Init/main

```go
// Bad — inside a handler or service
func badHandler() {
	ctx := context.Background()
	_ = ctx
}

// Good — receive ctx from caller
func HandleRequest(ctx kacontext.MutableContext) error { return nil }
```

### No `nil` Context — Ever

### `kacontext.Upgrade()` Call Sites Only

`kacontext.Upgrade()` converts a plain `context.Context` into a `KAContext`.
It is only allowed in:

- `main()` functions
- GraphQL resolver functions
- HTTP request handlers (`*http.Request` / `*httputil.ProxyRequest` parameters)
- `PreSave()` methods
- Dataloader functions
- Pub/Sub message handlers (also call `.MaybeSetRequestIDAndTraceID()` after Upgrade)

### Embed Only What You Use (`ka-context-interface`)

```go
// Bad — embeds all context capabilities but only calls Log
type MyContext interface {
	kacontext.KAContext // everything
}

// Good — embed only what this function actually calls
type MyContext interface {
	log.KAContext
	time.KAContext
}
```

______________________________________________________________________

## Logging

```go
// Bad — use webapp logger, not "log" or "github.com/sirupsen/logrus"
func badLog(ctx kacontext.MutableContext, id, userID string, err error) {
	log.Printf("user: %s", id)
	logrus.Infof("done")
	ctx.Log().Info(fmt.Sprintf("processing user %s", userID)) // bad: fmt.Sprintf in message

	// Bad — every form of stdout write is banned in services/ and pkg/
	//   (ka-banned-symbol). This includes the builtins, not just the fmt
	//   wrappers. Temporary "just for debugging" output is not exempt.
	fmt.Print("…")
	fmt.Printf("user=%s\n", id)
	fmt.Println("debug")
	print("debug")
	println("debug")
	os.Stdout.Write([]byte("…"))
}

// Good — Debug/Info: fixed string message + log.Fields for variable data
func goodLog(ctx kacontext.MutableContext, userID string, err error) {
	ctx.Log().Info("processing user", log.Fields{"user_id": userID})
	ctx.Log().Debug("cache miss") // fieldsMaps is variadic; omit when there are no fields

	// Good — Warn/Error/Panic: error object only; attach context to the error itself
	ctx.Log().Error(errors.Wrap(err, "user_id", userID))
	ctx.Log().Warn(errors.Wrap(err, "operation", "fetchUser"))
}
```

`cmd/` scripts (`main` packages) are the only place `fmt.Print*` / `print` /
`println` / `os.Stdout` are allowed — that's where stdout is the legitimate
output channel. Everywhere else (anything under `services/` or `pkg/`), use
`ctx.Log()`.

`Debug` and `Info` take `(message string, fieldsMaps ...log.Fields)`. `Warn`,
`Error`, and `Panic` take `(err error)` only — attach structured context via
`errors.Wrap(err, "key", val)` before passing to the logger. Mixing up these
calling conventions is a compile error.

______________________________________________________________________

## Time and Concurrency

### Time

```go
// Bad — not injectable, breaks tests
now := time.Now()
elapsed := time.Since(start)

// Good
now := ctx.Time().Now()
elapsed := ctx.Time().Since(start)
```

### Concurrency

```go
// Bad
var wg sync.WaitGroup
var m sync.Map

// Good
g := tracegroup.New(ctx) // propagates OTel spans
var m generic.SyncMap[K, V]
```

______________________________________________________________________

## HTTP

### Outbound Requests

```go
// Bad — every stdlib shortcut is banned (ka-banned-symbol). They use
// http.DefaultClient internally, which drops context, auth headers,
// and observability spans.
resp, err := http.Get(url)
resp, err := http.Head(url)
resp, err := http.Post(url, contentType, body)
resp, err := http.PostForm(url, formValues)
resp, err := http.DefaultClient.Get(url)
resp, err := http.DefaultClient.Do(req)

// Bad — no context
req, err := http.NewRequest("GET", url, nil)

// Good — build a request with context, send through ctx.HTTP()
req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
if err != nil {
	return errors.Wrap(err)
}
resp, err := ctx.HTTP().Do(req)
if err != nil {
	return errors.Wrap(err)
}
defer resp.Body.Close()

// Good — POST / form / HEAD all build their own request the same way
req, err := http.NewRequestWithContext(ctx, "POST", url, body)
req.Header.Set("Content-Type", contentType)
resp, err := ctx.HTTP().Do(req)
```

### Response Writing

Always `return` immediately after `http.Error` or `http.Redirect`. The linter
uses control-flow analysis; a `return` outside the same block does not count.

```go
// Bad
if !authorized {
	http.Error(w, "unauthorized", http.StatusUnauthorized)
}
doMoreWork(w) // still executes

// Good
if !authorized {
	http.Error(w, "unauthorized", http.StatusUnauthorized)
	return
}
```

### Cookie

```go
// Bad
http.SetCookie(w, cookie)

// Good
ctx.SetCookie(w, cookie)
```

______________________________________________________________________

## Testing

### Suite Setup

```go
// Bad — plain testify suite
import "github.com/stretchr/testify/suite"
import "github.com/stretchr/testify/assert"

// Good
import "github.com/Khan/webapp/dev/khantest"

type MyTestSuite struct {
	khantest.Suite
}

func TestMyTestSuite(t *testing.T) {
	khantest.Run(t, &MyTestSuite{})
}
```

### Assertions (`ka-suite`)

```go
// Outside All() — use Require (fails fast)
func (suite *MyTestSuite) TestFoo() {
	result, err := doThing(suite.Ctx())
	suite.Require().NoError(err) // not suite.Assert()
	suite.Require().NotNil(result)

	// Multiple soft assertions — use All
	suite.All(func() {
		suite.Assert().Equal(expected, result.Name)
		suite.Assert().Equal(42, result.Count)
	})
}
```

Do **not** use `suite.Nil(err)` for errors — use `suite.Require().NoError(err)`.

### Lifecycle Methods Must Call Super

```go
func (suite *MyTestSuite) SetupSuite() {
	suite.Suite.SetupSuite() // required

	// your setup here
}

func (suite *MyTestSuite) TearDownTest() {
	suite.Suite.TearDownTest() // required
}
```

### Environment Variables in Tests

```go
// Bad
os.Setenv("MY_FLAG", "true")

// Good
suite.Setenv("MY_FLAG", "true") // automatically cleaned up
```

______________________________________________________________________

## Datastore

### Model Struct Requirements (`ka-datastore-model`)

```go
type UserData struct {
	datastore.BaseModel           // required embed
	Name                string    `datastore:"name"`                 // all fields must be tagged
	CreatedAt           time.Time `datastore:"created_at,omitempty"` // time: omitempty
	Profile             Profile   `datastore:"profile,omitempty"`    // struct: omitempty
	Tags                []string  `datastore:"tags"`                 // slice: NO omitempty
}

// Required: key constructor in same file
func MakeUserDataKey(id string) *datastore.Key { return nil }

// Required: PreSave calls both super and safety check
func (m *UserData) PreSave(ctx context.Context) error {
	if err := m.BaseModel.PreSave(ctx); err != nil {
		return errors.Wrap(err)
	}
	return datastore.CheckTransactionSafetyForPut(ctx, m)
}
```

`omitempty` rules summary: **struct and `time.Time` fields** → add `omitempty`;
**slice fields** → never add `omitempty` (already omitted by datastore, adding
it breaks behavior).

### Key Construction (Service/non-Model Code)

```go
// Bad — raw key constructors banned in service code
key := datastore.NameKey("UserData", id, nil)
key := datastore.IDKey("UserData", numID, nil)

// Good — generated helpers
key := models.MakeUserDataKey(id)
```

### Transaction Closures (`ka-datastore-transaction`)

Outer variables declared with zero value and modified inside a transaction
closure **must be re-initialized at the very top** of the closure. Transactions
may retry up to three times, so the closure must be idempotent — it must
produce the same result whether it runs once or three times.

```go
var user models.UserData
err := ctx.Datastore().RunInTransaction(ctx, func(txn *datastore.Transaction) error {
	user = models.UserData{} // re-init first, before any other statement
	return getUserAndModify(ctx, txn, &user)
})
```

### Not-Found Handling (`ka-datastore-not-found`)

Functions that call `Get`/`GetMulti`/`GetAll`/`Iterator.Next` must never
return `(nil, nil)`.

```go
// Bad
if err := ctx.Datastore().Get(ctx, key, &u); err != nil {
	return nil, nil
}

// Good
if err := ctx.Datastore().Get(ctx, key, &u); err != nil {
	if datastore.IsNotFound(err) {
		return nil, errors.NotFound("user %s not found", id)
	}
	return nil, errors.Wrap(err)
}
return &u, nil
```

### Datastore Access Boundaries (ADR-312)

Code in `models/`, `pkg/services_shared/`, and `resolvers/` must **not** call
`ctx.Datastore()` or `datastore.Transaction`. Put datastore calls in a
dedicated service layer and call it from those packages. The one exception:
`resolvers/backfills.go` files may call `ctx.Datastore()` directly.

______________________________________________________________________

## GraphQL and Resolvers

### Every Resolver Needs a Permission Check (ADR-211, `ka-permissions`)

```go
// Bad — no permission check
func (r *queryResolver) GetUser(ctx context.Context, id string) (*User, error) {
	return r.userService.Get(ctx, id)
}

// Good
// checkUserReadPermission verifies the caller can read user data.
//
//ka:permission-check
func checkUserReadPermission(ctx kacontext.Context, userID string) error { return nil }

func (r *queryResolver) GetUser(ctx context.Context, id string) (*User, error) {
	if err := checkUserReadPermission(ctx, id); err != nil {
		return nil, err
	}
	return r.userService.Get(ctx, id)
}
```

The `//ka:permission-check` directive must appear on its own comment line,
attached to the function declaration (not inside the function body). When the
function is called via an interface, the directive must also appear on the
interface method declaration.

### Mutation Resolvers Use Response Objects (ADR-303, `ka-resolver-error`)

```go
// Bad — mutation returning error directly
func (r *mutationResolver) CreateUser(ctx context.Context, input CreateUserInput) (*User, error) {
	return nil, someErr
}

// Good — error in response struct
type CreateUserResponse struct {
	User  *User  `json:"user"`
	Error string `json:"error"`
}

func (r *mutationResolver) CreateUser(ctx context.Context, input CreateUserInput) (*CreateUserResponse, error) {
	user, err := r.userService.Create(ctx, input)
	if err != nil {
		return &CreateUserResponse{Error: err.Error()}, nil
	}
	return &CreateUserResponse{User: user}, nil
}
```

### Cross-Service Calls

- Call genqlient-generated functions only from `cross_service/` packages.
- `gqlclient.Mux.Handle`/`Match*` mocks belong in `cross_service/`.
- `gqlclient.WithService()` operations must map to exactly one service; use the
  gateway for multi-service operations.

______________________________________________________________________

## Naming Conventions

### No Screaming Snake Case (`ka-no-screaming-snake`)

```go
// Bad
const MAX_RETRIES = 3

var INITIAL_THETA = 0.0

type ERROR_CODE int

// Good
const MaxRetries = 3

var InitialTheta = 0.0

type ErrorCode int
```

The linter auto-suggests the `MixedCaps` form.

### File-Private Identifiers (`ka-visibility`)

Identifiers starting with `_` are a file-private convention. Do not reference
them from any other file in the same package.

```go
// file_a.go
var _cache = newCache()

// file_b.go — Bad
x := _cache.Get(key) // cross-file reference to _-prefixed identifier
```

Test files and `testutil/` directories are exempt.

### Deprecated Terminology (`ka-deprecated-terminology`)

Do not use these terms in identifiers, comments, or filenames:

| Banned                              | Use instead               |
| ----------------------------------- | ------------------------- |
| `student_list` / `studentList`      | `classroom`               |
| `u13` / `under13`                   | `underAgeGate` / `child`  |
| `language` (as a KA locale concept) | `kaLocale`                |
| `topic` (as a content node)         | `curationNode`            |
| `scratchpad` / `scratchpads`        | `program` / `programs`    |
| `readableID` / `readableId`         | `slug`                    |
| `learnMenu` / `learnMenus`          | `coursesMenu`             |
| `commitSHA` / `publishSHA`          | `publishedContentVersion` |

The linter splits identifiers into words before checking, so
`GetStudentListForClass` would trigger on "student" + "list".

______________________________________________________________________

## Import and Package Boundaries (`ka-import`, `depguard`)

### Structural Boundaries

- `pkg/` must not import `services/`.
- A service (`services/foo`) must not import another service (`services/bar`).
- Only `resolvers/` packages (and `main.go` files) may import a service's
  `generated/graphql` package.

For shared types across services, extract to `pkg/`.

### Banned Packages (Use Alternatives)

| Import                                | Use instead                                                    |
| ------------------------------------- | -------------------------------------------------------------- |
| `errors` (stdlib)                     | `github.com/Khan/webapp/pkg/lib/errors`                        |
| `log` (stdlib)                        | `github.com/Khan/webapp/pkg/lib/log`                           |
| `github.com/sirupsen/logrus`          | `github.com/Khan/webapp/pkg/lib/log`                           |
| `math/rand` or `math/rand/v2`         | `github.com/Khan/webapp/pkg/lib/rand`                          |
| `golang.org/x/exp/rand`               | `github.com/Khan/webapp/pkg/lib/rand`                          |
| `io/ioutil`                           | `io` or `os`                                                   |
| `golang.org/x/sync/errgroup`          | `github.com/Khan/webapp/pkg/external/opentelemetry/tracegroup` |
| `cloud.google.com/go/datastore`       | `github.com/Khan/webapp/pkg/gcloud/datastore`                  |
| `cloud.google.com/go/storage`         | `github.com/Khan/webapp/pkg/gcloud/gcs`                        |
| `github.com/pkg/errors`               | `github.com/Khan/webapp/pkg/lib/errors`                        |
| `github.com/stretchr/testify/suite`   | `github.com/Khan/webapp/dev/khantest`                          |
| `github.com/stretchr/testify/assert`  | `suite.Assert()`                                               |
| `github.com/stretchr/testify/require` | `suite.Require()`                                              |

______________________________________________________________________

## Miscellaneous Rules

### Always Close `io.Closer` Values (`ka-always-close`)

```go
// Good pattern
resp, err := ctx.HTTP().Do(req)
if err != nil {
	return errors.Wrap(err)
}
defer resp.Body.Close()
```

Functions that accept a closer and handle closing internally must be annotated
with `//ka:closer`.

### Use Comparison Methods (`ka-compare`)

```go
// Bad — using == / < / > on types with semantic comparison methods
if a == b {
}
if t1 < t2 {
}

// Good
if a.Equal(b) {
}
if t1.Before(t2) {
}
```

This applies to any type with `Equal(T) bool`, `Before(T) bool`, or
`After(T) bool` methods (e.g., `time.Time`).

### JSON Struct Tags (`ka-json-tag`)

Every exported field in a struct that is passed to `json.Marshal` or
`json.Unmarshal` must have an explicit `json:"name"` tag. Without tags,
renaming a Go field silently breaks the JSON API.

```go
// Bad
type Response struct {
	UserName string
	Score    int
}

// Good
type Response struct {
	UserName string `json:"user_name"`
	Score    int    `json:"score"`
}
```

### Documentation (`ka-documentation`)

Packages with more than one `.go` file require a doc comment on every exported
function, type, and variable. Generated files are exempt.

```go
// DoThing performs the thing operation and returns the result.
func DoThing(ctx context.Context) error { return nil }
```

### Line Length (`ka-linewrap`)

- Comment lines: **≤ 80 characters**.
- Code lines: **≤ 100 characters**.

Exempt: lines containing a URL, struct tag lines, lines with a single long
string literal, map-assignment lines.

### Cache Ordering (`ka-cache`)

When specifying multiple `cache.In(...)` options, order from fastest to slowest:

```go
// Good — fastest first
cache.Cache(fetchUser, cache.In(
	lib.RequestCache,  // priority 2000 — fastest
	lib.InstanceCache, // priority 1000
	memorystore.Cache, // priority 200
	datastore.Cache,   // priority 100 — slowest
))
```

Each named function may appear in at most one `cache.Cache(...)` call per
package. The function being cached must be a named function in the same package
(not a literal or cross-package reference).

### `//nolint` Format (`nolintlint`)

Suppressing a linter requires both the linter name and a reason:

```go
// Bad
// nolint
x := context.Background() //nolint

// Good
//
//nolint:ka-context // main entrypoint, kacontext not yet initialized
x := context.Background()
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
- [ ] No banned package imports (see §11 table)
- [ ] `pkg` does not import `services/`; services do not import each other

## Miscellaneous

- [ ] `io.Closer` objects closed (preferably with `defer`)
- [ ] `.Equal()`/`.Before()`/`.After()` used instead of `==`/`<`/`>`
- [ ] JSON-marshalled structs have `json:"..."` tags on all exported fields
- [ ] Exported functions documented in multi-file packages
- [ ] `//nolint` comments name the linter and include a reason
