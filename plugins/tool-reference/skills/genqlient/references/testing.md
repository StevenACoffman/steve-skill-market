# Testing

## Testing

**Option A — httptest.Server (most realistic):**

```go
func TestGetUser(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"data":{"user":{"name":"Alice","createdAt":"2020-01-01T00:00:00Z"}}}`)
	}))
	defer srv.Close()

	client := graphql.NewClient(srv.URL, srv.Client())
	resp, err := GetUser(context.Background(), client, "alice")
	require.NoError(t, err)
	assert.Equal(t, "Alice", resp.User.Name)
}
```

**Option B — mock transport:**

```go
type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func mockClient(body string) graphql.Client {
	return graphql.NewClient("https://fake", &http.Client{
		Transport: roundTripFunc(func(_ *http.Request) (*http.Response, error) {
			return &http.Response{
				StatusCode: 200,
				Header:     http.Header{"Content-Type": {"application/json"}},
				Body:       io.NopCloser(strings.NewReader(body)),
			}, nil
		}),
	})
}
```

**Option C — implement graphql.Client directly:**

```go
type mockGQLClient struct{ response interface{} }

func (c *mockGQLClient) MakeRequest(_ context.Context, _ *graphql.Request, resp *graphql.Response) error {
	b, _ := json.Marshal(c.response)
	return json.Unmarshal(b, resp.Data)
}
```
