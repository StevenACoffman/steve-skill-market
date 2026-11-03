# Testing

## Testing

### Client Helper

`github.com/99designs/gqlgen/client` wraps an `http.Handler` and provides a
simple POST-based query API:

```go
import (
	"github.com/99designs/gqlgen/client"
	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/stretchr/testify/require"
	"testing"
)

func TestCreateTodo(t *testing.T) {
	srv := handler.New(generated.NewExecutableSchema(generated.Config{
		Resolvers: &graph.Resolver{DB: testDB},
	}))
	srv.AddTransport(transport.POST{})

	c := client.New(srv)

	var resp struct {
		CreateTodo struct {
			ID   string
			Text string
		}
	}
	c.MustPost(`
        mutation {
            createTodo(input: { text: "test task" }) {
                id
                text
            }
        }
    `, &resp)

	require.NotEmpty(t, resp.CreateTodo.ID)
	require.Equal(t, "test task", resp.CreateTodo.Text)
}
```

### Variables

```go
var resp struct {
	Todo struct{ Text string }
}
c.MustPost(
	`query GetTodo($id: ID!) { todo(id: $id) { text } }`,
	&resp,
	client.Var("id", "abc123"),
)
```

### Expecting an Error

```go
var resp struct {
	Todo *struct{ Text string }
}
err := c.Post(`{ todo(id: "nonexistent") { text } }`, &resp)
require.Error(t, err)
require.Contains(t, err.Error(), "not found")
```

### Headers

```go
c.MustPost(query, &resp,
	client.AddHeader("Authorization", "Bearer "+token),
)
```

### Raw Response (Extensions, Errors List)

```go
raw, err := c.RawPost(`{ todos { id } }`)
// raw.Data      — map[string]any
// raw.Errors    — []map[string]any
// raw.Extensions — map[string]any
```
