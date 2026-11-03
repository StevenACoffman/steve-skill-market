# Middleware and Context

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
