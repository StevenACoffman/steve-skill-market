---
name: gqlgen-app
description: "Use when building a GraphQL server in Go with gqlgen (github.com/99designs/gqlgen): gqlgen.yml, code generation, resolvers and dependency injection, schema design, middleware, dataloaders for N+1, errors, subscriptions, custom directives, resolver tests, and Apollo Federation."
allowed-tools: Bash, Read, Edit, Write
---

# Gqlgen — Application Developer Guide

gqlgen is a schema-first GraphQL server library for Go. You write a GraphQL
schema, run code generation, and implement the generated resolver interfaces.
gqlgen guarantees type safety — invalid schema references are compile errors.

Module path: `github.com/99designs/gqlgen`

______________________________________________________________________

## Quick-Reference Cheat Sheet

| Task                                    | Where / How                                          |
| --------------------------------------- | ---------------------------------------------------- |
| Scaffold new project                    | `gqlgen init`                                        |
| Run codegen                             | `go generate ./...` or `gqlgen generate`             |
| Inject dependencies into resolvers      | Fields on your `Resolver` struct                     |
| Add HTTP middleware                     | Wrap `srv` with standard `http.Handler` middleware   |
| Add GraphQL middleware (field/op level) | `srv.AroundFields(...)`, `srv.AroundOperations(...)` |
| Map GraphQL type to existing Go struct  | `autobind:` in `gqlgen.yml`, or `models:` section    |
| Force a field to have a resolver        | `@goField(forceResolver: true)` in schema            |
| Rename generated Go field               | `@goField(name: "GoName")` in schema                 |
| Add auth/validation directive           | Define in schema + implement in `DirectiveRoot`      |
| Enable introspection                    | `srv.Use(extension.Introspection{})`                 |
| Limit query complexity                  | `srv.Use(extension.FixedComplexityLimit(1000))`      |
| Test a resolver                         | `client.New(srv)` + `c.MustPost(...)`                |

______________________________________________________________________

## Project Setup

### Install

```bash
go get github.com/99designs/gqlgen
```

### Scaffold a New Project

```bash
gqlgen init
```

Generates the standard layout:

```text
graph/
  schema.graphqls          # GraphQL schema (edit this)
  generated.go             # codegen output — DO NOT EDIT
  models_gen.go            # generated Go models — DO NOT EDIT
  resolver.go              # your Resolver struct + New() function
  schema.resolvers.go      # your resolver method implementations
gqlgen.yml                 # codegen config
server.go                  # HTTP server entry point
```

### Go Generate Directive

Add to `resolver.go` or `tools.go`:

```go
//go:generate go run github.com/99designs/gqlgen generate
```

Run with:

```bash
go generate ./...
```

______________________________________________________________________

## Reference Files

Read the matching file in `references/` when the task needs it:

- [`references/configuration.md`](references/configuration.md) — read when editing `gqlgen.yml` (schema paths, models, autobind, resolver layout, federation, generation options).
- [`references/schema-features.md`](references/schema-features.md) — read when using built-in directives like `@goField`, defining custom scalars, or autobinding existing Go types.
- [`references/middleware-and-context.md`](references/middleware-and-context.md) — read when adding `AroundOperations`/`AroundFields`/`AroundResponses` middleware, writing a custom extension, or reading operation/field context and per-request data.
- [`references/dataloaders.md`](references/dataloaders.md) — read when fixing N+1 queries with dataloaders.
- [`references/error-handling.md`](references/error-handling.md) — read when returning errors, partial results, a custom error presenter, or panic recovery.
- [`references/subscriptions.md`](references/subscriptions.md) — read when implementing subscriptions or the WebSocket transport.
- [`references/custom-directives.md`](references/custom-directives.md) — read when defining and implementing schema directives in `DirectiveRoot`.
- [`references/testing.md`](references/testing.md) — read when testing resolvers with the `client` helper (variables, errors, headers, raw responses).
- [`references/federation.md`](references/federation.md) — read when configuring Apollo Federation and entity resolvers.

______________________________________________________________________

## Code Generation Output

### `generated.go` — Do Not Edit

Contains:

- `NewExecutableSchema(cfg Config) graphql.ExecutableSchema` — wire this to the server
- `ResolverRoot` interface — implement all methods to satisfy this
- `DirectiveRoot` struct — one function field per custom schema directive
- `ComplexityRoot` struct — one function field per field, for complexity limiting

### `models_gen.go` — Do Not Edit

Contains Go structs for every GraphQL type that wasn't autobind-matched or
overridden in `models:`. Regenerated on every `gqlgen generate`.

### `resolver.go` — Edit This

Contains your `Resolver` struct and the `New()` constructor. Add dependency
fields here. The file is generated once and never overwritten.

### `schema.resolvers.go` — Edit This

Contains stub implementations of every resolver method. Also generated once;
gqlgen adds stubs for new fields but never removes your implementations.

______________________________________________________________________

## Resolver Patterns

### Generated ResolverRoot Interface

```go
// graph/generated.go (generated — do not edit)
type ResolverRoot interface {
	Mutation() MutationResolver
	Query() QueryResolver
	Todo() TodoResolver // only if Todo has field resolvers
	Subscription() SubscriptionResolver
}

type QueryResolver interface {
	Todo(ctx context.Context, id string) (*model.Todo, error)
	Todos(ctx context.Context) ([]*model.Todo, error)
}

type MutationResolver interface {
	CreateTodo(ctx context.Context, input model.NewTodo) (*model.Todo, error)
	DeleteTodo(ctx context.Context, id string) (bool, error)
}

type TodoResolver interface {
	// Field resolver for Todo.user — present only if forceResolver: true
	User(ctx context.Context, obj *model.Todo) (*model.User, error)
}
```

### Dependency Injection via Resolver Struct

All dependencies live on the root `Resolver` struct. The type-cast pattern
lets query/mutation/subscription resolvers share the same fields without
copying them.

```go
// graph/resolver.go
type Resolver struct {
	DB     *sql.DB
	Cache  *redis.Client
	Events *EventBus
}

func (r *Resolver) Query() generated.QueryResolver       { return (*queryResolver)(r) }
func (r *Resolver) Mutation() generated.MutationResolver { return (*mutationResolver)(r) }
func (r *Resolver) Todo() generated.TodoResolver         { return (*todoResolver)(r) }

// graph/schema.resolvers.go

type queryResolver Resolver // alias — shares fields, no copy

func (r *queryResolver) Todo(ctx context.Context, id string) (*model.Todo, error) {
	return r.DB.QueryTodo(ctx, id)
}

type mutationResolver Resolver

func (r *mutationResolver) CreateTodo(ctx context.Context, input model.NewTodo) (*model.Todo, error) {
	return r.DB.InsertTodo(ctx, input)
}

type todoResolver Resolver

func (r *todoResolver) User(ctx context.Context, obj *model.Todo) (*model.User, error) {
	return r.DB.QueryUser(ctx, obj.UserID)
}
```

### Wiring up the Server

```go
// server.go
import (
	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/lru"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/myorg/myapp/graph"
	"github.com/myorg/myapp/graph/generated"
)

func main() {
	resolver := &graph.Resolver{
		DB:    openDB(),
		Cache: openRedis(),
	}

	schema := generated.NewExecutableSchema(generated.Config{
		Resolvers: resolver,
	})

	srv := handler.New(schema)

	// Transports — handler.New adds NONE; add at least POST
	srv.AddTransport(transport.Options{})     // CORS preflight
	srv.AddTransport(transport.GET{})         // read-only queries via URL
	srv.AddTransport(transport.POST{})        // standard queries and mutations
	srv.AddTransport(transport.MultipartForm{ // file uploads (multipart)
		MaxUploadSize: 32 << 20,
		MaxMemory:     32 << 20,
	})
	srv.AddTransport(transport.Websocket{ // subscriptions
		KeepAlivePingInterval: 10 * time.Second,
	})
	// transport.SSE{} — subscriptions over Server-Sent Events (no upgrade needed)

	// Query cache (avoids re-parsing identical queries)
	srv.SetQueryCache(lru.New[*ast.QueryDocument](1000))

	// Extensions
	srv.Use(extension.Introspection{}) // disabled by default; add explicitly
	srv.Use(extension.FixedComplexityLimit(1000))
	srv.Use(extension.AutomaticPersistedQuery{
		Cache: lru.New[string](100),
	})

	http.Handle("/query", srv)
	http.Handle("/", playground.Handler("GraphQL", "/query"))
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

______________________________________________________________________

## Available Transports

All transports live in `github.com/99designs/gqlgen/graphql/handler/transport`.
`handler.New` adds **none by default** — add what your server needs.

| Transport         | Struct                       | When to add                                               |
| ----------------- | ---------------------------- | --------------------------------------------------------- |
| HTTP POST         | `transport.POST{}`           | Standard queries and mutations (add this first)           |
| HTTP GET          | `transport.GET{}`            | Read-only queries via URL; no body needed                 |
| CORS preflight    | `transport.Options{}`        | Responds to `OPTIONS` requests; needed for browser CORS   |
| File upload       | `transport.MultipartForm{}`  | `Upload` scalar; `MaxUploadSize` and `MaxMemory` in bytes |
| GraphQL over HTTP | `transport.GRAPHQL{}`        | `application/graphql` content type                        |
| URL-encoded form  | `transport.UrlEncodedForm{}` | `application/x-www-form-urlencoded` POST bodies           |
| WebSocket         | `transport.Websocket{}`      | Subscriptions; requires a WebSocket-capable client        |
| SSE               | `transport.SSE{}`            | Subscriptions via Server-Sent Events; no upgrade needed   |
| Multipart mixed   | `transport.MultipartMixed{}` | Incremental delivery (`@defer` / `@stream`)               |

______________________________________________________________________

## Common Mistakes

### Forgetting to Add Transports

`handler.New(schema)` creates a server with **no transports**. Without
`srv.AddTransport(transport.POST{})`, every request returns 400.

### Editing Generated Files

`generated.go` and `models_gen.go` are overwritten on every `gqlgen generate`.
Put custom logic in `resolver.go` or `schema.resolvers.go`.

### Not Closing Subscription Channels

If a subscription goroutine does not close the channel on `ctx.Done()`, it
leaks. Always `defer close(ch)` and select on `ctx.Done()`.

### Resolver Struct Vs Type-Cast Pattern

Using `type queryResolver Resolver` (not `type queryResolver struct { *Resolver }`)
means the type cast is a zero-cost operation and you access fields directly
(`r.DB`) without indirection. Both work, but the cast pattern avoids an extra
allocation and an interface-to-pointer level of indirection.

### Complexity Limit and ComplexityRoot

Without custom `ComplexityRoot` functions, `extension.FixedComplexityLimit`
assigns each field a default complexity of 1, so a limit of 1000 means the
client cannot select more than ~1000 fields in a single operation. This is
useful as a basic depth/breadth guard.

To assign higher costs to expensive fields (e.g. a paginated list that hits the
DB), populate `Config.Complexity`:

```go
generated.Config{
	Resolvers: resolver,
	Complexity: generated.ComplexityRoot{
		Query: struct {
			Todos func(childComplexity int, limit int) int
		}{
			Todos: func(childComplexity int, limit int) int {
				return childComplexity * limit // each item in the list costs its own complexity
			},
		},
	},
}
```

______________________________________________________________________

## Key Import Paths

| Package                                                 | Used For                                     |
| ------------------------------------------------------- | -------------------------------------------- |
| `github.com/99designs/gqlgen/graphql/handler`           | `handler.New(schema)`                        |
| `github.com/99designs/gqlgen/graphql/handler/transport` | `transport.POST{}`, `transport.Websocket{}`  |
| `github.com/99designs/gqlgen/graphql/handler/extension` | `extension.Introspection{}`, complexity      |
| `github.com/99designs/gqlgen/graphql/handler/lru`       | `lru.New[T](n)` for query/APQ cache          |
| `github.com/99designs/gqlgen/graphql/playground`        | `playground.Handler("title", "/query")`      |
| `github.com/99designs/gqlgen/graphql`                   | `graphql.GetOperationContext`, field context |
| `github.com/99designs/gqlgen/client`                    | `client.New(srv)` for tests                  |
| `github.com/vektah/gqlparser/v2/gqlerror`               | `gqlerror.Error`, `gqlerror.Errorf`          |
