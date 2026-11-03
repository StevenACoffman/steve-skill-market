# Type Bindings and Nullable Fields

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
