# @Genqlient Directive Reference

## Omitempty

Omit the argument from the request if its Go value is the zero value. Only
valid on nullable (optional) arguments.

```graphql
query Search(
  # @genqlient(omitempty: true)
  $query: String,
) { ... }
```

Structs have no zero concept — combine with `pointer: true` for optional struct inputs.

## Pointer

Generate `*T` instead of `T`. On a response field, `nil` means the server
returned null. On an argument, pass `nil` to send null.

```graphql
query GetUser($login: String!) {
  user(login: $login) {
    # @genqlient(pointer: true)
    bio           # generates *string
    createdAt     # generates time.Time (unchanged)
  }
}
```

Apply globally: `optional: pointer` in `genqlient.yaml`.

## Typename

Assign a specific name to the generated Go type for a field. Two uses with the
same `typename` must request identical fields.

```graphql
query GetUser {
  # @genqlient(typename: "User")
  user { id name }
}
```

## Struct

For an interface/union field, generate a plain struct instead of a Go interface

- multiple concrete types. Only valid when no inline fragments are present.

```graphql
query GetContent($id: ID!) {
  # @genqlient(struct: true)
  content(id: $id) { id title }   # generates a single struct; no type switch needed
}
```

## Flatten

When a field's selection is a single named fragment spread, use the fragment
type directly rather than wrapping it.

```graphql
query GetUser {
  # @genqlient(flatten: true)
  user { ...UserFields }   # field type becomes UserFields, not a thin wrapper
}
```

## Bind

Use an existing Go type for this field (per-operation override of `bindings`).
Use `bind: "-"` to cancel a global binding.

```graphql
query GetDates {
  # @genqlient(bind: "time.Time")
  createdAt
}
```

## Alias

Rename the Go struct field (and its getter) without changing the JSON wire name
or creating a GraphQL alias. The server still receives and returns the original
field name; only the generated Go identifier changes.

```graphql
query GetUser {
  user {
    # @genqlient(alias: "UserID")
    id      # Go field: UserID, json:"id" (wire name unchanged)
    # @genqlient(alias: "DisplayName")
    name    # Go field: DisplayName, json:"name"
  }
}
```

Compare with a **GraphQL alias** (`goName: fieldName`), which changes the wire
name too — use `@genqlient(alias:)` when the server limits alias count or you
can't touch the query text.

## For

Redirect a directive to an input-type field that doesn't appear in the query
text. Must be placed at operation or fragment level.

```graphql
# @genqlient(for: "UserInput.id", omitempty: true)
# @genqlient(for: "UserInput.name", pointer: true)
query CreateUser($input: UserInput!) { ... }
```
