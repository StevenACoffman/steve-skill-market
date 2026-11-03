# Custom Directives

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
