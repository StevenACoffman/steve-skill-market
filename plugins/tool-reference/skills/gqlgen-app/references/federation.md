# Apollo Federation

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
