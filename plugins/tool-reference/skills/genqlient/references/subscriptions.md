# Subscriptions

## Subscriptions

Subscriptions require `graphql.NewClientUsingWebSocket`. You must implement the
`graphql.Dialer` interface (gorilla/websocket satisfies the underlying conn):

```go
import (
	"github.com/Khan/genqlient/graphql"
	"github.com/gorilla/websocket"
)

type wsDialer struct{ *websocket.Dialer }

func (d *wsDialer) DialContext(ctx context.Context, url string, h http.Header) (graphql.WSConn, error) {
	conn, resp, err := d.Dialer.DialContext(ctx, url, h)
	if resp != nil {
		resp.Body.Close()
	}
	return conn, err
}

func main() {
	wsClient := graphql.NewClientUsingWebSocket(
		"wss://api.example.com/graphql",
		&wsDialer{Dialer: websocket.DefaultDialer},
		graphql.WithConnectionParams(map[string]interface{}{
			"Authorization": "Bearer " + token, // protocol-level auth
		}),
	)
	errChan, err := wsClient.Start(ctx)
	defer wsClient.Close()

	// Given: subscription CountEvents { count }
	dataChan, subID, err := CountEvents(ctx, wsClient)

	for {
		select {
		case msg, ok := <-dataChan:
			if !ok {
				return
			} // channel closed: server done or we unsubscribed
			if len(msg.Errors) > 0 {
				log.Println(msg.Errors)
				return
			}
			if msg.Data != nil {
				fmt.Println(msg.Data.Count) // msg.Data is *CountEventsResponse
			}
		case err := <-errChan:
			log.Println("ws error:", err)
			return
		}
	}
	_ = subID // wsClient.Unsubscribe(subID) to cancel early
}
```

`dataChan` carries `graphql.BaseResponse[*CountEventsResponse]` — `.Data` is a
pointer and may be nil on error events; always nil-check before dereferencing.
Subscription functions require a `graphql.WebSocketClient`, not `graphql.Client`.
