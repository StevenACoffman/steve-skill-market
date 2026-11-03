# Subscriptions

## Subscriptions

### Schema

```graphql
type Subscription {
    commentAdded(postID: ID!): Comment!
}
```

### Implementation

The resolver returns a receive-only channel. Close the channel to end the
subscription. When the client disconnects, `ctx.Done()` fires.

```go
func (r *subscriptionResolver) CommentAdded(ctx context.Context, postID string) (<-chan *model.Comment, error) {
	ch := make(chan *model.Comment, 1)

	go func() {
		defer close(ch)
		sub := r.Events.Subscribe(postID)
		defer r.Events.Unsubscribe(postID, sub)

		for {
			select {
			case <-ctx.Done():
				return
			case comment := <-sub:
				ch <- comment
			}
		}
	}()

	return ch, nil
}
```

### WebSocket Transport

Add to the server before handling requests:

```go
srv.AddTransport(transport.Websocket{
	KeepAlivePingInterval: 10 * time.Second,
	Upgrader: websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true },
	},
})
```
