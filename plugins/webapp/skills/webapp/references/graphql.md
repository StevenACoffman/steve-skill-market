# GraphQL and Resolvers

## Every Resolver Needs a Permission Check (ADR-211, `ka-permissions`)

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

## Mutation Resolvers Use Response Objects (ADR-303, `ka-resolver-error`)

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

## Cross-Service Calls

- Call genqlient-generated functions only from `cross_service/` packages.
- `gqlclient.Mux.Handle`/`Match*` mocks belong in `cross_service/`.
- `gqlclient.WithService()` operations must map to exactly one service; use the
  gateway for multi-service operations.
