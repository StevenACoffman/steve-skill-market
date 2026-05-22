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
// Bad
import "errors"
import "fmt"
return fmt.Errorf("not found: %w", err)
return errors.New("bad input")

// Good
import "github.com/Khan/webapp/pkg/lib/errors"
return errors.New("bad input")
return errors.Wrap(err)
```

### Wrapping Rules (`ka-errors-stacktrace`)

Wrap **sentinel errors** and **third-party/stdlib errors** before returning.
This captures the call-site stack trace. The linter auto-fixes these.

```go
// Bad — sentinel and stdlib errors returned bare
var ErrNotFound = errors.New("not found")
return ErrNotFound
return io.ErrUnexpectedEOF

// Good
return errors.Wrap(ErrNotFound)
return errors.Wrap(io.ErrUnexpectedEOF)

// Bad — third-party call result not wrapped
data, err := json.Unmarshal(b, &v)
return err

// Good
if err := json.Unmarshal(b, &v); err != nil {
	return errors.Wrap(err)
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
ctx := context.Background()

// Good — receive ctx from caller
func HandleRequest(ctx kacontext.MutableContext) error { ... }
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
// Bad — banned package
import "log"
import "github.com/sirupsen/logrus"
log.Printf("user: %s", id)
logrus.Infof("done")

// Bad — fmt.Sprintf in log message (ka-log)
ctx.Log().Info(fmt.Sprintf("processing user %s", userID))

// Bad — printing to stdout in server code (ka-banned-symbol)
fmt.Println("debug")

// Good — Debug/Info: fixed string message + log.Fields for variable data
ctx.Log().Info("processing user", log.Fields{"user_id": userID})
ctx.Log().Debug("cache miss")  // fieldsMaps is variadic; omit when there are no fields

// Good — Warn/Error/Panic: error object only; attach context to the error itself
ctx.Log().Error(errors.Wrap(err, "user_id", userID))
ctx.Log().Warn(errors.Wrap(err, "operation", "fetchUser"))
```

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
// Bad — no context propagation, bypasses observability
resp, err := http.Get(url)
resp, err := http.DefaultClient.Get(url)

// Bad — no context
req, err := http.NewRequest("GET", url, nil)

// Good
req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
resp, err := ctx.HTTP().Do(req)
defer resp.Body.Close()
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
    datastore.BaseModel                          // required embed
    Name      string    `datastore:"name"`       // all fields must be tagged
    CreatedAt time.Time `datastore:"created_at,omitempty"` // time: omitempty
    Profile   Profile   `datastore:"profile,omitempty"`    // struct: omitempty
    Tags      []string  `datastore:"tags"`                 // slice: NO omitempty
}

// Required: key constructor in same file
func MakeUserDataKey(id string) *datastore.Key { ... }

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
may retry up to three times.

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
func checkUserReadPermission(ctx kacontext.Context, userID string) error { ... }

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
func DoThing(ctx context.Context) error { ... }
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
