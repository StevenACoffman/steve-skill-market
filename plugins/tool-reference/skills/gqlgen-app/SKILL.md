---
name: gqlgen-app
description: |
  Use when building a GraphQL server in Go with gqlgen
  (github.com/99designs/gqlgen). Covers project setup, gqlgen.yml
  configuration, code generation, resolver patterns, dependency injection,
  schema design, middleware, context, dataloaders, error handling,
  subscriptions, custom directives, testing, and Apollo Federation.

  Trigger signals:
  - Setting up or configuring a gqlgen project (gqlgen.yml, generated.go)
  - Writing or wiring resolver implementations
  - Injecting dependencies into resolvers
  - Adding middleware, extensions, or interceptors to the server
  - Handling N+1 queries with dataloaders
  - Returning errors with GraphQL extensions
  - Implementing subscriptions
  - Writing custom schema directives
  - Testing resolvers with the gqlgen client helper
  - Configuring Apollo Federation
  - Any "how do I do X with gqlgen" question
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

## Gqlgen.yml Configuration

Full reference for the most important fields:

```yaml
# Schema files (glob patterns supported, ** for recursion)
schema:
  - graph/*.graphqls

# Generated execution engine
exec:
  filename: graph/generated.go
  package: graph

# Generated model types
model:
  filename: graph/model/models_gen.go
  package: model

# Resolver stub layout
resolver:
  layout: follow-schema       # one file per schema file (recommended)
  dir: graph
  package: graph
  filename_template: '{name}.resolvers.go'

# Autobind: scan these packages for types matching GraphQL type names
autobind:
  - github.com/myorg/myapp/model

# Per-type Go type overrides
models:
  UUID:
    model: github.com/google/uuid.UUID
  Time:
    model: time.Time

  # Map a GraphQL type to an existing Go struct
  User:
    model: github.com/myorg/myapp/model.User

  # Remap a field name (GraphQL name → Go struct field)
  Todo:
    model: github.com/myorg/myapp/model.Todo
    fields:
      text:
        fieldName: Description

# Federation (Apollo Federation v2)
federation:
  filename: graph/federation.go
  package: graph
  version: 2

# Global generation options
struct_fields_always_pointers: true    # nullable fields become *T
resolvers_always_return_pointers: true # resolver return types are pointers
omit_slice_element_pointers: false     # use []*T for list fields
nullable_input_omittable: false        # wrap nullable inputs with Omittable[T]
```

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

## Schema Features

### GraphQL Schema Directives Built into Gqlgen

```graphql
# Force gqlgen to generate a resolver method (instead of struct field access)
type Todo {
    id: ID!
    text: String!
    user: User! @goField(forceResolver: true)
    # Go field renamed from "internalText" to "text"
    internalText: String! @goField(name: "DisplayText")
}

# Mark a nullable input field as Omittable[T] (distinguishes "not set" from null)
input UpdateTodo {
    text: String @goField(omittable: true)
}
```

### Custom Scalars

In the schema:

```graphql
scalar UUID
scalar Time
```

Bind to Go types in `gqlgen.yml`:

```yaml
models:
  UUID:
    model: github.com/google/uuid.UUID
  Time:
    model: time.Time
```

`time.Time` and `uuid.UUID` implement `encoding.TextMarshaler` / `encoding.TextUnmarshaler`,
which gqlgen uses automatically. For custom scalars, implement `graphql.Marshaler`:

```go
func (t *MyScalar) UnmarshalGQL(v any) error {
	s, ok := v.(string)
	if !ok {
		return fmt.Errorf("scalar must be string")
	}
	*t = MyScalar(s)
	return nil
}

func (t MyScalar) MarshalGQL(w io.Writer) {
	fmt.Fprintf(w, `"%s"`, string(t))
}
```

### Autobind — Reuse Existing Go Types

```yaml
# gqlgen.yml
autobind:
  - github.com/myorg/myapp/model
```

gqlgen loads the package and matches exported type names to GraphQL type names.
If `model.User` exists and the schema has `type User`, gqlgen uses your type
instead of generating a new one. Fields are matched by name (case-insensitive).
Add `gqlgen:"fieldName"` struct tags to override matching.

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

## Middleware

gqlgen provides four interception levels, from outermost to innermost:

```text
AroundOperations  (wraps the entire operation: parse → validate → execute)
  AroundRootFields  (wraps each top-level Query/Mutation field)
    AroundFields      (wraps every field resolver in the tree)
      resolver called
    AroundFields
  AroundRootFields
  AroundResponses   (wraps response serialisation)
AroundOperations
```

### AroundOperations — Whole Operation

```go
srv.AroundOperations(func(ctx context.Context, next graphql.OperationHandler) graphql.ResponseHandler {
	opCtx := graphql.GetOperationContext(ctx)
	start := time.Now()

	handler := next(ctx)

	return func(ctx context.Context) *graphql.Response {
		resp := handler(ctx)
		log.Printf("op=%s duration=%s", opCtx.OperationName, time.Since(start))
		return resp
	}
})
```

### AroundFields — Every Field

```go
srv.AroundFields(func(ctx context.Context, next graphql.Resolver) (any, error) {
	fc := graphql.GetFieldContext(ctx)
	res, err := next(ctx)
	if err != nil {
		log.Printf("field error: %s.%s: %v", fc.Object, fc.Field.Name, err)
	}
	return res, err
})
```

### AroundRootFields — Top-Level Fields Only

```go
srv.AroundRootFields(func(ctx context.Context, next graphql.RootResolver) graphql.Marshaler {
	fc := graphql.GetFieldContext(ctx)
	log.Printf("root field: %s", fc.Field.Name)
	return next(ctx)
})
```

### AroundResponses — Serialisation

```go
srv.AroundResponses(func(ctx context.Context, next graphql.ResponseHandler) *graphql.Response {
	resp := next(ctx)
	if resp.Extensions == nil {
		resp.Extensions = map[string]any{}
	}
	resp.Extensions["requestID"] = getRequestID(ctx)
	return resp
})
```

### Custom Extension (Reusable Middleware)

`graphql.HandlerExtension` requires two methods. The interceptor interfaces are
optional — implement only the ones you need:

```go
type HandlerExtension interface {
	ExtensionName() string
	Validate(schema ExecutableSchema) error
}

// Optional interceptor interfaces (implement any subset):
// OperationParameterMutator — mutate raw request before parsing
//   MutateOperationParameters(ctx context.Context, request *RawParams) *gqlerror.Error
// OperationContextMutator — mutate parsed operation context
//   MutateOperationContext(ctx context.Context, opCtx *OperationContext) *gqlerror.Error
// OperationInterceptor — wrap the whole operation
//   InterceptOperation(ctx context.Context, next OperationHandler) ResponseHandler
// ResponseInterceptor — wrap response serialisation
//   InterceptResponse(ctx context.Context, next ResponseHandler) *Response
// RootFieldInterceptor — wrap root fields only
//   InterceptRootField(ctx context.Context, next RootResolver) Marshaler
// FieldInterceptor — wrap every field resolver
//   InterceptField(ctx context.Context, next Resolver) (res any, err error)
```

Example — field-level tracing extension:

```go
type TracingExtension struct{}

func (TracingExtension) ExtensionName() string                          { return "Tracing" }
func (TracingExtension) Validate(schema graphql.ExecutableSchema) error { return nil }

func (TracingExtension) InterceptField(ctx context.Context, next graphql.Resolver) (any, error) {
	fc := graphql.GetFieldContext(ctx)
	span, ctx := tracer.StartSpan(ctx, fc.Field.Name)
	defer span.Finish()
	return next(ctx)
}

// srv.Use(TracingExtension{})
```

______________________________________________________________________

## Context

### Operation Context

Available from any resolver or middleware:

```go
opCtx := graphql.GetOperationContext(ctx)
opCtx.RawQuery             // original query string
opCtx.Variables            // map[string]any of variables
opCtx.OperationName        // operation name (or "")
opCtx.Headers              // http.Header from the request
opCtx.Doc                  // *ast.QueryDocument (parsed query)
opCtx.Operation            // *ast.OperationDefinition
opCtx.Extensions           // map[string]any from the request body
opCtx.DisableIntrospection // true when introspection is blocked
opCtx.Stats                // graphql.Stats — timing for parsing/validation/execution
```

To check which fields a client requested (avoids fetching data for unused
fields):

```go
func logTodoFields(ctx context.Context) {
	// Returns all fields selected on typeName in the current operation.
	fields := graphql.CollectAllFields(ctx, "Todo")
	for _, f := range fields {
		fmt.Println(f) // field names: "id", "text", "user", …
	}
}
```

### Field Context

```go
fc := graphql.GetFieldContext(ctx)
fc.Object     // parent type name: "Query", "Todo", …
fc.Field.Name // field name: "todo", "user", …
fc.Args       // map[string]any of resolved arguments
fc.Path()     // ast.Path — position in response tree, e.g. ["posts", 0, "title"]
fc.IsMethod   // true if resolver is a Go method
fc.IsResolver // true if field has a dedicated resolver (vs. struct field access)
fc.Parent     // *FieldContext of the enclosing field, nil at root
fc.Result     // any — the resolved value (available post-resolution)
```

### Storing per-Request Data

Use a typed context key — never a string or built-in type:

```go
type ctxKey struct{ name string }

var currentUserKey = ctxKey{"currentUser"}

// In HTTP middleware (before gqlgen):
func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := authenticateRequest(r)
		ctx := context.WithValue(r.Context(), currentUserKey, user)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// In resolver:
func (r *queryResolver) Me(ctx context.Context) (*model.User, error) {
	user, ok := ctx.Value(currentUserKey).(*model.User)
	if !ok || user == nil {
		return nil, gqlerror.Errorf("unauthenticated")
	}
	return user, nil
}
```

______________________________________________________________________

## Dataloaders (N+1 Prevention)

Use a dataloader to batch many individual loads into one DB query. Two library
options:

| Library                            | Approach        | Notes                                   |
| ---------------------------------- | --------------- | --------------------------------------- |
| `github.com/vektah/dataloaden`     | Code-generated  | Used in gqlgen's own examples           |
| `github.com/vikstrous/dataloadgen` | Generic library | Modern alternative; no codegen required |

The examples below use `dataloadgen`.

### Setup

```bash
go get github.com/vikstrous/dataloadgen
```

Define loader types and attach them to the request context via HTTP middleware.
Loaders must be created **per request** — they batch within one operation only.

```go
type Loaders struct {
	UserByID *dataloadgen.Loader[string, *model.User]
}

func NewLoaders(db *sql.DB) *Loaders {
	return &Loaders{
		UserByID: dataloadgen.NewLoader(
			func(ctx context.Context, ids []string) ([]*model.User, []error) {
				// one DB query for all ids collected in this tick
				rows := db.QueryUsersByIDs(ctx, ids)
				byID := make(map[string]*model.User, len(rows))
				for _, u := range rows {
					byID[u.ID] = u
				}
				// results must be in the same order as ids
				result := make([]*model.User, len(ids))
				errs := make([]error, len(ids))
				for i, id := range ids {
					result[i] = byID[id]
					if result[i] == nil {
						errs[i] = fmt.Errorf("user %s not found", id)
					}
				}
				return result, errs
			},
			dataloadgen.WithWait(500*time.Microsecond),
		),
	}
}

type loadersKey struct{}

func LoadersMiddleware(db *sql.DB, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := context.WithValue(r.Context(), loadersKey{}, NewLoaders(db))
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func GetLoaders(ctx context.Context) *Loaders {
	return ctx.Value(loadersKey{}).(*Loaders)
}
```

### Usage in Resolver

```go
func (r *todoResolver) User(ctx context.Context, obj *model.Todo) (*model.User, error) {
	return GetLoaders(ctx).UserByID.Load(ctx, obj.UserID)
}
```

Multiple resolver calls for `User` within one GraphQL operation are automatically
batched into a single `QueryUsersByIDs` call.

### One-to-Many Loaders

When each key maps to a slice of results, use `[]*T` as the value type:

```go
PostsByAuthorID * dataloadgen.Loader[string, []*model.Post]

// fetch returns [][]*model.Post, one slice per author id
func(ctx context.Context, authorIDs []string) ([][]*model.Post, []error) {
	rows := db.QueryPostsByAuthorIDs(ctx, authorIDs)
	byAuthor := make(map[string][]*model.Post)
	for _, p := range rows {
		byAuthor[p.AuthorID] = append(byAuthor[p.AuthorID], p)
	}
	result := make([][]*model.Post, len(authorIDs))
	for i, id := range authorIDs {
		result[i] = byAuthor[id] // empty slice if no posts
	}
	return result, make([]error, len(authorIDs))
}
```

______________________________________________________________________

## Error Handling

### Returning Errors from Resolvers

```go
func notFoundErr(id string) (*Todo, error) {
	// Simple error — wrapped by DefaultErrorPresenter
	_ = fmt.Errorf("todo not found")

	// Full gqlerror with extensions
	_ = &gqlerror.Error{
		Message: "todo not found",
		Extensions: map[string]any{
			"code":   "NOT_FOUND",
			"todoID": id,
		},
	}

	// Convenience constructor
	return nil, gqlerror.Errorf("todo %s not found", id)
}
```

The response path is attached automatically by the runtime.

### Partial Results

A resolver that returns both data AND an error produces a partial response —
data is included up to the failed field, errors list the failures. This is
valid GraphQL behaviour. Return `(nil, err)` to omit the field entirely.

### Custom Error Presenter

Transform or sanitise errors before they reach the client:

```go
srv.SetErrorPresenter(func(ctx context.Context, err error) *gqlerror.Error {
	gqlErr := graphql.DefaultErrorPresenter(ctx, err)

	var appErr *AppError
	if errors.As(err, &appErr) {
		gqlErr.Extensions = map[string]any{
			"code":    appErr.Code,
			"message": appErr.UserMessage,
		}
	} else {
		// Don't leak internal errors to clients
		gqlErr.Message = "internal server error"
	}

	return gqlErr
})
```

### Panic Recovery

```go
srv.SetRecoverFunc(func(ctx context.Context, err any) error {
	log.Printf("panic: %v\n%s", err, debug.Stack())
	return fmt.Errorf("internal server error")
})
```

______________________________________________________________________

## Subscriptions

### Schema

```graphql
type Subscription {
    commentAdded(postID: ID!): Comment!
}
```

### Implementation

The resolver returns a receive-only channel. Close the channel to end the
subscription. When the client disconnects, `ctx.Done()` fires.

```go
func (r *subscriptionResolver) CommentAdded(ctx context.Context, postID string) (<-chan *model.Comment, error) {
	ch := make(chan *model.Comment, 1)

	go func() {
		defer close(ch)
		sub := r.Events.Subscribe(postID)
		defer r.Events.Unsubscribe(postID, sub)

		for {
			select {
			case <-ctx.Done():
				return
			case comment := <-sub:
				ch <- comment
			}
		}
	}()

	return ch, nil
}
```

### WebSocket Transport

Add to the server before handling requests:

```go
srv.AddTransport(transport.Websocket{
	KeepAlivePingInterval: 10 * time.Second,
	Upgrader: websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true },
	},
})
```

______________________________________________________________________

## Custom Directives

### Schema Definition

```graphql
directive @auth(role: String!) on FIELD_DEFINITION
directive @validate(min: Int, max: Int) on ARGUMENT_DEFINITION | INPUT_FIELD_DEFINITION
```

### Generated DirectiveRoot

gqlgen generates one function field per directive:

```go
// graph/generated.go (do not edit)
type DirectiveRoot struct {
	Auth     func(ctx context.Context, obj any, next graphql.Resolver, role string) (any, error)
	Validate func(ctx context.Context, obj any, next graphql.Resolver, min *int, max *int) (any, error)
}
```

### Implementation

```go
cfg := generated.Config{
	Resolvers: &graph.Resolver{DB: db},
	Directives: generated.DirectiveRoot{
		Auth: func(ctx context.Context, obj any, next graphql.Resolver, role string) (any, error) {
			user := getCurrentUser(ctx)
			if user == nil || !user.HasRole(role) {
				return nil, gqlerror.Errorf("forbidden: requires role %s", role)
			}
			return next(ctx) // proceed to the real resolver
		},

		Validate: func(ctx context.Context, obj any, next graphql.Resolver, min *int, max *int) (any, error) {
			res, err := next(ctx)
			if err != nil {
				return nil, err
			}
			s, ok := res.(string)
			if !ok {
				return res, nil
			}
			if min != nil && len(s) < *min {
				return nil, gqlerror.Errorf("value too short (min %d)", *min)
			}
			if max != nil && len(s) > *max {
				return nil, gqlerror.Errorf("value too long (max %d)", *max)
			}
			return res, nil
		},
	},
}
```

Directives can:

- Short-circuit by returning an error without calling `next(ctx)`
- Mutate `ctx` before calling `next(ctx)` (e.g., to store auth state)
- Post-process results by inspecting `res` after `next(ctx)`

______________________________________________________________________

## Testing

### Client Helper

`github.com/99designs/gqlgen/client` wraps an `http.Handler` and provides a
simple POST-based query API:

```go
import (
	"github.com/99designs/gqlgen/client"
	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/stretchr/testify/require"
	"testing"
)

func TestCreateTodo(t *testing.T) {
	srv := handler.New(generated.NewExecutableSchema(generated.Config{
		Resolvers: &graph.Resolver{DB: testDB},
	}))
	srv.AddTransport(transport.POST{})

	c := client.New(srv)

	var resp struct {
		CreateTodo struct {
			ID   string
			Text string
		}
	}
	c.MustPost(`
        mutation {
            createTodo(input: { text: "test task" }) {
                id
                text
            }
        }
    `, &resp)

	require.NotEmpty(t, resp.CreateTodo.ID)
	require.Equal(t, "test task", resp.CreateTodo.Text)
}
```

### Variables

```go
var resp struct {
	Todo struct{ Text string }
}
c.MustPost(
	`query GetTodo($id: ID!) { todo(id: $id) { text } }`,
	&resp,
	client.Var("id", "abc123"),
)
```

### Expecting an Error

```go
var resp struct {
	Todo *struct{ Text string }
}
err := c.Post(`{ todo(id: "nonexistent") { text } }`, &resp)
require.Error(t, err)
require.Contains(t, err.Error(), "not found")
```

### Headers

```go
c.MustPost(query, &resp,
	client.AddHeader("Authorization", "Bearer "+token),
)
```

### Raw Response (Extensions, Errors List)

```go
raw, err := c.RawPost(`{ todos { id } }`)
// raw.Data      — map[string]any
// raw.Errors    — []map[string]any
// raw.Extensions — map[string]any
```

______________________________________________________________________

## Apollo Federation

### Gqlgen.yml

```yaml
federation:
  filename: graph/federation.go
  package: graph
  version: 2
```

### Schema Markup

```graphql
type User @key(fields: "id") {
    id: ID!
    name: String!
}

# Extend a type from another subgraph
extend type Post @key(fields: "id") {
    id: ID! @external
    author: User!
}
```

### Entity Resolver

gqlgen generates an `EntityResolver` interface with one method per `@key` type.
Wire it through `ResolverRoot`:

```go
// graph/resolver.go
func (r *Resolver) Entity() generated.EntityResolver { return (*entityResolver)(r) }

type entityResolver Resolver

func (r *entityResolver) FindUserByID(ctx context.Context, id string) (*model.User, error) {
	return r.DB.QueryUser(ctx, id)
}
```

The Apollo Router calls `_entities` automatically; you never call `FindUserByID`
directly. The `_service` SDL endpoint is also handled by the generated code.

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
