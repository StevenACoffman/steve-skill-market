# Interfaces and Fragments

## Interfaces and Fragments

### Interface Fields

genqlient generates a Go interface and one concrete struct per possible
implementation. Use a type switch:

```go
resp, err := GetContent(ctx, client, "123")
switch c := resp.Content.(type) {
case *GetContentContentArticle:
	fmt.Println(c.Text)
case *GetContentContentVideo:
	fmt.Println(c.Duration)
}
// or via the shared interface:
fmt.Println(resp.Content.GetTitle())
```

If you only need the shared fields and don't need type assertions, skip the
interface:

```graphql
# @genqlient(struct: true)
content(id: $id) { id title }   # generates a plain struct
```

### Named Fragments for Type Sharing

```graphql
fragment UserFields on User { id name }

query GetPlayers {
  game {
    winner { ...UserFields }   # winner embeds UserFields
    banker  { ...UserFields }  # banker  embeds UserFields
  }
}
```

```go
// Pass the embedded fragment to shared functions:
func PrintUser(u UserFields) { fmt.Println(u.Id, u.Name) }

// Or use genqlient's getter interface — both Winner and Banker have GetName():
type HasName interface{ GetName() string }

func printName(v HasName) { fmt.Println(v.GetName()) }

func useFragments(resp *GetPlayersResponse) {
	PrintUser(resp.Game.Winner.UserFields)
	printName(resp.Game.Winner)
	printName(resp.Game.Banker)
}
```

**flatten** removes the wrapper struct when a field's selection is a single
fragment spread:

```graphql
query GetUser {
  # @genqlient(flatten: true)
  user { ...UserFields }   # field type is UserFields directly
}
```
