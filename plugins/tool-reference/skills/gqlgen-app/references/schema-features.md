# Schema Features

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
