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

### Omitempty

Omit the argument from the request if its Go value is the zero value. Only
valid on nullable (optional) arguments.

```graphql
query Search(
  # @genqlient(omitempty: true)
  $query: String,
) { ... }
```

Structs have no zero concept — combine with `pointer: true` for optional struct inputs.

### Pointer

Generate `*T` instead of `T`. On a response field, `nil` means the server
returned null. On an argument, pass `nil` to send null.

```graphql
query GetUser($login: String!) {
  user(login: $login) {
    # @genqlient(pointer: true)
    bio           # generates *string
    createdAt     # generates time.Time (unchanged)
  }
}
```

Apply globally: `optional: pointer` in `genqlient.yaml`.

### Typename

Assign a specific name to the generated Go type for a field. Two uses with the
same `typename` must request identical fields.

```graphql
query GetUser {
  # @genqlient(typename: "User")
  user { id name }
}
```

### Struct

For an interface/union field, generate a plain struct instead of a Go interface

- multiple concrete types. Only valid when no inline fragments are present.

```graphql
query GetContent($id: ID!) {
  # @genqlient(struct: true)
  content(id: $id) { id title }   # generates a single struct; no type switch needed
}
```

### Flatten

When a field's selection is a single named fragment spread, use the fragment
type directly rather than wrapping it.

```graphql
query GetUser {
  # @genqlient(flatten: true)
  user { ...UserFields }   # field type becomes UserFields, not a thin wrapper
}
```

### Bind

Use an existing Go type for this field (per-operation override of `bindings`).
Use `bind: "-"` to cancel a global binding.

```graphql
query GetDates {
  # @genqlient(bind: "time.Time")
  createdAt
}
```

### Alias

Rename the Go struct field (and its getter) without changing the JSON wire name
or creating a GraphQL alias. The server still receives and returns the original
field name; only the generated Go identifier changes.

```graphql
query GetUser {
  user {
    # @genqlient(alias: "UserID")
    id      # Go field: UserID, json:"id" (wire name unchanged)
    # @genqlient(alias: "DisplayName")
    name    # Go field: DisplayName, json:"name"
  }
}
```

Compare with a **GraphQL alias** (`goName: fieldName`), which changes the wire
name too — use `@genqlient(alias:)` when the server limits alias count or you
can't touch the query text.

### For

Redirect a directive to an input-type field that doesn't appear in the query
text. Must be placed at operation or fragment level.

```graphql
# @genqlient(for: "UserInput.id", omitempty: true)
# @genqlient(for: "UserInput.name", pointer: true)
query CreateUser($input: UserInput!) { ... }
```

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
import "github.com/Khan/genqlient/graphql"

// Standard POST client:
client := graphql.NewClient("https://api.example.com/graphql", http.DefaultClient)

// GET client (queries only; useful for CDN caching; cannot be used for mutations):
client := graphql.NewClientUsingGet("https://api.example.com/graphql", nil)
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
import "github.com/vektah/gqlparser/v2/gqlerror"

resp, err := GetUser(ctx, client, "login")

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
```

______________________________________________________________________

## Type Bindings for Custom Scalars

Map GraphQL scalar names to Go types in `genqlient.yaml`:

```yaml
bindings:
  DateTime:
    type: time.Time                  # uses standard JSON marshal/unmarshal
  Date:
    type: time.Time
    marshaler: pkg.MarshalDate       # func MarshalDate(v *time.Time) ([]byte, error)
    unmarshaler: pkg.UnmarshalDate   # func UnmarshalDate(b []byte, v *time.Time) error
  UUID:
    type: github.com/google/uuid.UUID
  JSON:
    type: encoding/json.RawMessage
  Int:
    type: int32                      # override built-in scalar
```

Per-operation override with `@genqlient(bind: "time.Time")` on a specific field.
Use `bind: "-"` on a field to cancel a global binding for that one query.

______________________________________________________________________

## Nullable Fields and Optional Arguments

**Default (`optional: value`):** null → Go zero value. Cannot distinguish null
from `""`, 0, false.

**Pointer approach:** `optional: pointer` globally, or `@genqlient(pointer: true)` per field. `nil` means null.

```graphql
# Per-field:
query GetUser($login: String!) {
  user(login: $login) {
    # @genqlient(pointer: true)
    bio     # *string; nil if server returned null
  }
}
```

**Three-way distinction for arguments:**

| Directive                        | Go type | Wire behavior                                    |
| -------------------------------- | ------- | ------------------------------------------------ |
| *(neither)*                      | `T`     | Always sent; zero value sends zero value         |
| `omitempty: true`                | `T`     | Omitted from request when Go zero value          |
| `pointer: true`                  | `*T`    | `nil` sends explicit `null`; non-nil sends value |
| `pointer: true, omitempty: true` | `*T`    | `nil` omits entirely; non-nil sends value        |

**Optional struct arguments** — structs have no zero concept; pointer lets you
distinguish "not provided" from "provided empty":

```graphql
query Search(
  # @genqlient(omitempty: true, pointer: true)
  $filter: FilterInput,
) { ... }
```

Or set `use_struct_references: true` globally to apply this to all struct inputs.

**Generic option type:** `optional: generic` + `optional_generic_type: pkg.Option[T]` — requires the type to implement `json.Marshaler` / `json.Unmarshaler`.

______________________________________________________________________

## Interfaces and Fragments

### Interface Fields

genqlient generates a Go interface and one concrete struct per possible
implementation. Use a type switch:

```go
resp, err := GetContent(ctx, client, "123")
switch c := resp.Content.(type) {
case *GetContentContentArticle:
	fmt.Println(c.Text)
case *GetContentContentVideo:
	fmt.Println(c.Duration)
}
// or via the shared interface:
fmt.Println(resp.Content.GetTitle())
```

If you only need the shared fields and don't need type assertions, skip the
interface:

```graphql
# @genqlient(struct: true)
content(id: $id) { id title }   # generates a plain struct
```

### Named Fragments for Type Sharing

```graphql
fragment UserFields on User { id name }

query GetPlayers {
  game {
    winner { ...UserFields }   # winner embeds UserFields
    banker  { ...UserFields }  # banker  embeds UserFields
  }
}
```

```go
// Pass the embedded fragment to shared functions:
func PrintUser(u UserFields) { fmt.Println(u.Id, u.Name) }
PrintUser(resp.Game.Winner.UserFields)

// Or use genqlient's getter interface — both Winner and Banker have GetName():
type HasName interface{ GetName() string }
func printName(v HasName) { fmt.Println(v.GetName()) }
printName(resp.Game.Winner)
printName(resp.Game.Banker)
```

**flatten** removes the wrapper struct when a field's selection is a single
fragment spread:

```graphql
query GetUser {
  # @genqlient(flatten: true)
  user { ...UserFields }   # field type is UserFields directly
}
```

______________________________________________________________________

## Subscriptions

Subscriptions require `graphql.NewClientUsingWebSocket`. You must implement the
`graphql.Dialer` interface (gorilla/websocket satisfies the underlying conn):

```go
import (
	"github.com/Khan/genqlient/graphql"
	"github.com/gorilla/websocket"
)

type wsDialer struct{ *websocket.Dialer }

func (d *wsDialer) DialContext(ctx context.Context, url string, h http.Header) (graphql.WSConn, error) {
	conn, resp, err := d.Dialer.DialContext(ctx, url, h)
	if resp != nil {
		resp.Body.Close()
	}
	return conn, err
}

func main() {
	wsClient := graphql.NewClientUsingWebSocket(
		"wss://api.example.com/graphql",
		&wsDialer{Dialer: websocket.DefaultDialer},
		graphql.WithConnectionParams(map[string]interface{}{
			"Authorization": "Bearer " + token, // protocol-level auth
		}),
	)
	errChan, err := wsClient.Start(ctx)
	defer wsClient.Close()

	// Given: subscription CountEvents { count }
	dataChan, subID, err := CountEvents(ctx, wsClient)

	for {
		select {
		case msg, ok := <-dataChan:
			if !ok {
				return
			} // channel closed: server done or we unsubscribed
			if len(msg.Errors) > 0 {
				log.Println(msg.Errors)
				return
			}
			if msg.Data != nil {
				fmt.Println(msg.Data.Count) // msg.Data is *CountEventsResponse
			}
		case err := <-errChan:
			log.Println("ws error:", err)
			return
		}
	}
	_ = subID // wsClient.Unsubscribe(subID) to cancel early
}
```

`dataChan` carries `graphql.BaseResponse[*CountEventsResponse]` — `.Data` is a
pointer and may be nil on error events; always nil-check before dereferencing.
Subscription functions require a `graphql.WebSocketClient`, not `graphql.Client`.

______________________________________________________________________

## Testing

**Option A — httptest.Server (most realistic):**

```go
func TestGetUser(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"data":{"user":{"name":"Alice","createdAt":"2020-01-01T00:00:00Z"}}}`)
	}))
	defer srv.Close()

	client := graphql.NewClient(srv.URL, srv.Client())
	resp, err := GetUser(context.Background(), client, "alice")
	require.NoError(t, err)
	assert.Equal(t, "Alice", resp.User.Name)
}
```

**Option B — mock transport:**

```go
type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func mockClient(body string) graphql.Client {
	return graphql.NewClient("https://fake", &http.Client{
		Transport: roundTripFunc(func(_ *http.Request) (*http.Response, error) {
			return &http.Response{
				StatusCode: 200,
				Header:     http.Header{"Content-Type": {"application/json"}},
				Body:       io.NopCloser(strings.NewReader(body)),
			}, nil
		}),
	})
}
```

**Option C — implement graphql.Client directly:**

```go
type mockGQLClient struct{ response interface{} }

func (c *mockGQLClient) MakeRequest(_ context.Context, _ *graphql.Request, resp *graphql.Response) error {
	b, _ := json.Marshal(c.response)
	return json.Unmarshal(b, resp.Data)
}
```

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
