# Naming, Imports, and Miscellaneous Rules

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
