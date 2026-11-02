# KAContext in Tests

`servicetest.Suite` creates and owns the test context. Never construct a
`kacontext` directly in a test; use `suite.KAContext()` instead.

```go
type myServiceSuite struct {
	servicetest.Suite
}

func TestMyService(t *testing.T) {
	khantest.Run(t, &myServiceSuite{})
}

func (suite *myServiceSuite) TestSomething() {
	ctx := suite.KAContext()

	// Replace a single client using With* helpers — returns a new *kaContext
	ctx = ctx.WithDatastore(myFakeDatastoreClient)
	ctx = ctx.WithMemorystore(myFakeMemorystore)
	ctx = ctx.WithAlloyDB(myFakeAlloyDB)

	result, err := myService.DoThing(ctx, input)
	suite.Require().NoError(err)
	suite.Require().Equal(expected, result)
}
```

Client-replacement helpers available on `*kaContext` in tests: `WithDatastore`,
`WithMemorystore`, `WithAlloyDB`, `WithBigQuery`. Each returns a new `*kaContext`
with that one client replaced; all others are inherited. See
`pkg/kacontext/testing.go` for the full list.

The suite pre-wires:

- `timectx.NewAdvancingTimer()` — deterministic, auto-advancing time
- `log.NewTestLogger(ctx)` — captures log output in test output
- `datastore.NewTestClient()` — datastore emulator (lazy-started)
- `memorystore.NewMiniRedisClient()` — in-process Redis
- `pubsub.NewTestClient()` — in-process pub/sub
- `gcs.NewFSClient()` — temp-directory-backed GCS
- Mock clients for GraphQL, Slack, Emails
