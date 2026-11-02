---
name: genqlient
description: |
  Use when writing Go code that calls a GraphQL API using genqlient
  (github.com/Khan/genqlient). Covers configuration, writing operations,
  @genqlient directives, generated code, client setup, authentication,
  error handling, type bindings, nullable fields, fragments, subscriptions,
  and testing.

  Trigger signals:
  - Writing or modifying .graphql operation files for genqlient
  - Configuring genqlient.yaml
  - Calling genqlient-generated functions
  - Handling GraphQL errors or partial data
  - Binding custom scalars or Go types
  - Setting up an authenticated HTTP client for genqlient
  - Writing tests for code that calls genqlient-generated functions
  - Any "how do I do X with genqlient" question
allowed-tools: Bash, Read, Edit, Write
---

# Genqlient — Using the Library

genqlient reads your GraphQL schema and `.graphql` operation files at **build
time** and emits fully type-safe Go functions and response structs. Invalid
queries are build errors, not runtime panics. The generated code is a plain
`.go` file you commit alongside your own code.

Module path: `github.com/Khan/genqlient`

______________________________________________________________________

## Quick-Reference Cheat Sheet

| Task                                 | Where / How                                                       |
| ------------------------------------ | ----------------------------------------------------------------- |
| Run code generation                  | `go run github.com/Khan/genqlient` (or `go generate`)             |
| Make query nullable/pointer          | `# @genqlient(pointer: true)` before the field                    |
| Omit zero-value argument             | `# @genqlient(omitempty: true)` before the arg                    |
| Use custom Go type for a scalar      | `bindings:` in `genqlient.yaml`                                   |
| Shorten generated type name          | `# @genqlient(typename: "Foo")` on the field                      |
| Share a fragment type across queries | Named fragment + embedding; or `@genqlient(flatten: true)`        |
| Interface field as plain struct      | `# @genqlient(struct: true)` when no fragments needed             |
| Rename a Go field (keep wire name)   | `# @genqlient(alias: "GoName")` before the field                  |
| Add auth headers                     | Wrap `http.Transport` in `RoundTrip`; pass to `graphql.NewClient` |
| Read response extensions             | `use_extensions: true` in genqlient.yaml                          |
| Subscriptions                        | `graphql.NewClientUsingWebSocket` + gorilla/websocket             |

______________________________________________________________________

## Genqlient.yaml — Key Fields

```yaml
# Required
schema: schema.graphql              # SDL file(s); globs and lists accepted
operations:
  - genqlient.graphql               # .graphql files and/or .go source files
  - pkg/**/*.go

# Output
generated: generated.go             # default
package: mypackage                  # defaults to directory name

# Context / client injection
context_type: context.Context       # set to "-" to omit context entirely
client_getter: pkg.GetClient        # func(ctx) (graphql.Client, error); omits client param

# Nullable / optional fields
# "value" (default): null -> Go zero value
# "pointer":         null -> nil pointer (*T)
# "pointer_omitempty": pointer + omitempty on all optional fields
# "generic":         null -> optional_generic_type[T]
optional: value
optional_generic_type: github.com/you/pkg.Option  # only for optional: generic

# If true, optional struct inputs default to pointer: true, omitempty: true
use_struct_references: false

# If true, generated functions return (data, map[string]interface{}, error)
use_extensions: false

# Type bindings: map GraphQL type names to existing Go types
bindings:
  DateTime:
    type: time.Time
  UUID:
    type: github.com/google/uuid.UUID
    marshaler: pkg.MarshalUUID      # optional custom marshaler
    unmarshaler: pkg.UnmarshalUUID
  JSON:
    type: encoding/json.RawMessage

# Automatically bind all exported types in a package
package_bindings:
  - package: github.com/you/yourpkg/models

# Emit an operation manifest (for query safelisting / persisted queries)
export_operations: operations.json
```

______________________________________________________________________

## Writing Operation Files

Operations are standard GraphQL. The **operation name** becomes the generated
Go function name — use an uppercase initial letter.

```graphql
query GetUser($login: String!) {
  user(login: $login) {
    name
    createdAt
  }
}

mutation CreateUser($name: String!) {
  createUser(input: {name: $name}) {
    id
    name
  }
}
```

**Embedding in Go source:** include `.go` files in `operations` and write the
query as a string literal whose first line is `# @genqlient`:

```go
_ = `# @genqlient
query GetUser($login: String!) {
  user(login: $login) { name }
}
`
```

**Field aliases** rename Go fields without changing the wire name:

```graphql
query GetUser($login: String!) {
  user(login: $login) {
    displayName: name   # Go field: DisplayName
  }
}
```

______________________________________________________________________

## @Genqlient Directives

`@genqlient` is a comment-directive placed on the line **immediately before**
the node it applies to.

**Placement:** before the query keyword → applies to all matching nodes in the
operation. Before a specific field or argument → applies to that node only.
Node-level overrides operation-level.

```graphql
# @genqlient(omitempty: true)        <- all args in this operation
# @genqlient(for: "Input.id", pointer: true)  <- only Input.id
query MyQuery($arg1: Input!, $arg2: String) { ... }
```

Read [`references/directives.md`](references/directives.md) for each option (`omitempty`, `pointer`, `typename`, `struct`, `flatten`, `bind`, `alias`, `for`) with examples.

______________________________________________________________________

## Generated Code and Calling It

For each operation genqlient emits:

- A constant `OperationName_Operation` holding the query text.
- Response structs named `OperationNamePathToField` (e.g. `GetUserUser`).
- A Go function with the same name as the operation.

```go
// Generated function signature (standard setup):
func GetUser(ctx context.Context, client graphql.Client, login string) (*GetUserResponse, error)

// Response struct (always non-nil, even on error — fields are zero values):
type GetUserResponse struct{ User GetUserUser }
type GetUserUser struct {
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
}

// Every field also gets a getter method: resp.User.GetName()
```

**Calling generated functions:**

```go
resp, err := GetUser(ctx, client, "mylogin")
if err != nil {
	return err
}
fmt.Println(resp.User.Name)
```

`resp` is always non-nil, even on error, so you can safely read zero-value
fields without a nil check.

**Enum types** are generated as `type Role string` with constants and an
`AllRole []Role` slice for exhaustive switches.

______________________________________________________________________

## Client Setup and Authentication

```go
func newClients(endpoint string) (graphql.Client, graphql.Client) {
	// Standard POST client:
	post := graphql.NewClient(endpoint, http.DefaultClient)

	// GET client (queries only; useful for CDN caching; cannot be used for mutations):
	get := graphql.NewClientUsingGet(endpoint, nil)

	return post, get
}
```

**Adding auth headers via transport:**

```go
type authedTransport struct {
	token   string
	wrapped http.RoundTripper
}

func (t *authedTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Set("Authorization", "Bearer "+t.token)
	return t.wrapped.RoundTrip(req)
}

func NewClient(endpoint, token string) graphql.Client {
	return graphql.NewClient(endpoint, &http.Client{
		Transport: &authedTransport{token: token, wrapped: http.DefaultTransport},
	})
}
```

For **per-request headers** (e.g., trace IDs from context), read the request's
context in `RoundTrip`:

```go
func (t *tracingTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if id := tracing.IDFromContext(req.Context()); id != "" {
		req.Header.Set("X-Trace-Id", id)
	}
	return t.wrapped.RoundTrip(req)
}
```

**Custom client (intercept all requests):** implement `graphql.Client`:

```go
type Client interface {
	MakeRequest(ctx context.Context, req *Request, resp *Response) error
}
```

______________________________________________________________________

## Error Handling

Every generated function returns `(*ResponseType, error)`. Three error shapes:

```go
func handleErrors(ctx context.Context, client graphql.Client) {
	resp, err := GetUser(ctx, client, "login")
	_ = resp

	var list gqlerror.List
	var httpErr *graphql.HTTPError

	switch {
	case err == nil:
		// success — use resp normally

	case errors.As(err, &list):
		// Server returned HTTP 200 with GraphQL errors in the payload.
		// resp is non-nil and MAY have partial data (some fields set, others zero).
		for _, e := range list {
			log.Printf("GraphQL error: %s at %v (extensions: %v)", e.Message, e.Path, e.Extensions)
		}
		// Decide whether to use partial resp.User data or discard it.

	case errors.As(err, &httpErr):
		// Non-200 HTTP response (rate limit, auth failure, server error).
		log.Printf("HTTP %d: %v", httpErr.StatusCode, httpErr.Response.Errors)

	default:
		// Network error, DNS failure, context cancellation, etc.
		log.Printf("network error: %v", err)
	}
}
```

______________________________________________________________________

## Reference Files

- [`references/directives.md`](references/directives.md) — read when adding any `@genqlient(...)` directive.
- [`references/types-and-nullability.md`](references/types-and-nullability.md) — read when binding custom scalars to Go types or handling nullable fields and optional arguments.
- [`references/fragments.md`](references/fragments.md) — read when querying interface or union fields or sharing types via named fragments.
- [`references/subscriptions.md`](references/subscriptions.md) — read when implementing GraphQL subscriptions over WebSocket.
- [`references/testing.md`](references/testing.md) — read when writing tests for code that calls genqlient-generated functions.

______________________________________________________________________

## Common Gotchas

**Verbose type names are intentional.** `GetMonopolyPlayersGameWinnerUser` is
stable across query changes. Use `@genqlient(typename: "User")` or Go type
aliases (`type User = GetMonopolyPlayersGameWinnerUser`) to shorten them in
calling code.

**`omitempty` silently ignores struct types** (same as `encoding/json`). Use
`pointer: true` + `omitempty: true` together for optional struct inputs, or set
`use_struct_references: true` globally.

**`struct` and fragments are incompatible.** If you add a fragment to a field
that had `@genqlient(struct: true)`, remove the directive and update `.Field`
accesses to `.GetField()`.

**`typename` and `bind` cannot be combined.** To name a type and override a
binding, write `@genqlient(typename: "Foo", bind: "-")`.

**Input type directives must agree across the package.** All operations using
the same input type must have matching `@genqlient` directives on its fields
(via `for:`). Conflicting directives produce duplicate type names, a compile
error.

**`NewClientUsingGet` is for queries only.** It encodes the query in URL
parameters. Using it for mutations returns an error at runtime.

**`go mod tidy` may remove genqlient from `go.sum`** if it's only a `go run`
dep. Fix with a `tools.go` file:

```go
//go:build tools

package yourpkg

import _ "github.com/Khan/genqlient"
```

**After code generation, reload the generated file in your IDE** (or restart
gopls). The LSP needs to reindex the new types before completions work.

**`for:` only applies at operation or fragment level.** Writing it on a
specific field is a genqlient error.

**`flatten` requires a single named fragment spread.** Inline fragments and
multi-spread selections are not supported.
