# Gqlgen.yml Configuration

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
