# Error Handling

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
