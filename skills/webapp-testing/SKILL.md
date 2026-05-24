---
name: webapp-testing
description: |
  Use when writing or reading Go tests in github.com/Khan/webapp. Covers
  suite selection (khantest.Suite vs servicetest.Suite), KAContext setup in
  tests, fake service clients (datastore, pubsub, tasks, secrets,
  featureflags), BuildTestClientForSchema for GraphQL resolver tests, and
  gqltest.Query/Mutate/QueryType. ONLY applies to github.com/Khan/webapp.

  Trigger signals:
  - "how do I write a test in webapp?"
  - "which test suite should I use?"
  - "how do I get a KAContext in a test?"
  - "how do I test a GraphQL resolver?"
  - "how do I assert on a pub/sub message in a test?"
  - "how do I mock a fake datastore/tasks/secrets client?"
  - Any question about testing patterns inside webapp
allowed-tools: Bash, Read, Edit, Write
---

# Webapp Testing Patterns

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. Do not
> apply these patterns to any other repository — the test suite hierarchy,
> `kacontext.TestContext`, and fake clients are all webapp-specific.

______________________________________________________________________

## Suite Selection

| Need                                                                          | Suite               | Package                                  |
| ----------------------------------------------------------------------------- | ------------------- | ---------------------------------------- |
| Pure logic — no GCP or webapp services                                        | `khantest.Suite`    | `github.com/Khan/webapp/dev/khantest`    |
| Code that uses KAContext, datastore, pubsub, tasks, secrets, or feature flags | `servicetest.Suite` | `github.com/Khan/webapp/dev/servicetest` |
| Tests of code inside `pkg/` that must avoid circular imports                  | `khantest.Suite`    | (cannot import first-party packages)     |

Use `khantest.Suite` for fast, isolated unit tests. Use `servicetest.Suite` for
anything that needs `KAContext` or fake infrastructure clients.

______________________________________________________________________

## `khantest.Suite`

Import: `github.com/Khan/webapp/dev/khantest`

### Registration Pattern

```go
type mySuite struct{ khantest.Suite }

func (s *mySuite) TestSomething() {
	s.Require().Equal("a", "a")
}

func TestMyPackage(t *testing.T) {
	khantest.Run(t, new(mySuite))
}
```

### Key Methods

| Method                       | What It Does                                                                  |
| ---------------------------- | ----------------------------------------------------------------------------- |
| `s.AddCleanup(func())`       | Registers a teardown function; runs after each test in LIFO order             |
| `s.Setenv(key, value)`       | Sets an env var for the duration of the test; restores original on teardown   |
| `s.Unsetenv(key)`            | Unsets an env var for the duration of the test; restores original on teardown |
| `s.SkipIfNoGCPCredentials()` | Skips the test if GCP application-default credentials are unavailable         |
| `s.All(assertions ...bool)`  | Evaluates all assertions; fails fast (`FailNow`) on the first false           |
| `khantest.TestdataDir()`     | Returns the `testdata/` directory sibling to the calling test file            |
| `khantest.Run(t, suite)`     | Re-export of `testify/suite.Run` — use instead of importing testify directly  |

`SetupTest` sets `GOOGLE_CLOUD_PROJECT=khan-test` to prevent accidental prod
calls. `TearDownTest` runs all registered cleanups in reverse order.

______________________________________________________________________

## `servicetest.Suite`

Import: `github.com/Khan/webapp/dev/servicetest`

### Registration Pattern

```go
type mySuite struct{ servicetest.Suite }

func (s *mySuite) TestSomething() {
	ctx := s.KAContext()
	// use ctx with your service functions
}

func TestMyPackage(t *testing.T) {
	servicetest.Run(t, new(mySuite))
}
```

### Key Methods

| Method                                                                                 | What It Does                                                                                                |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `s.KAContext() kacontext.TestContext`                                                  | Returns (and lazily initialises) a full test KAContext with all fake clients wired up                       |
| `s.GetTestServer(ctx, ...serve.HandlerOption) *httptest.Server`                        | Starts a real HTTP server; registers cleanup to close it                                                    |
| `s.BuildTestClientForSchema(ctx, schema) gqlclient.Client`                             | Starts a GraphQL HTTP server with the given schema; returns a configured client (see GraphQL Testing below) |
| `s.BuildTestClientForSchemaFastlyCacheable(ctx, schema) gqlclient.Client`              | Same, but adds Fastly-cacheable headers and sets a nil user                                                 |
| `s.BuildTestClientForSchemaWithResponseHeaders(ctx, schema, headers) gqlclient.Client` | Same as `BuildTestClientForSchema`, but captures response headers into the provided `http.Header` map       |

`SetupTest` disables prod access for all GCP clients (AlloyDB, BigQuery,
Datastore, GCS, Pub/Sub, Secrets, Tasks). Any attempt to talk to a real GCP
service from a test panics.

### What `KAContext()` Provides

On first call per test, `KAContext()` initialises a `kacontext.TestContext`
containing:

| Service        | Fake type                   |
| -------------- | --------------------------- |
| Datastore      | Cloud Datastore emulator    |
| Pub/Sub        | Pub/Sub in-process emulator |
| GCS            | Filesystem-backed fake      |
| BigQuery       | BigQuery test client        |
| Secrets        | `secrets.TestClient`        |
| Tasks          | `taskstest.TestClient`      |
| Feature flags  | `featureflags.TestClient`   |
| Logger         | `log.NewTestLogger`         |
| HTTP client    | `lib.NewTestHTTPClient`     |
| GraphQL client | `gqlclient.NewMockClient`   |
| Emails         | `emails.MockClient`         |
| Slack          | `slack.MockClient`          |
| Fastly         | `fastly.NewTestClient`      |
| Time           | `timectx.NewAdvancingTimer` |

The context is reset between tests (`kaContext` is cleared in `SetupTest`).

### Time Travel in Tests

The `Time` entry above means `ctx.Time()` returns a deterministic
`timectx.AdvancingTimer` rather than the real wall clock. You can advance it or
freeze it to test time-sensitive logic without `time.Sleep`:

```go
func (s *mySuite) TestExpiredToken() {
	ctx := s.KAContext()
	timer := ctx.Time().(*timectx.AdvancingTimer)

	// Code under test sets an expiry 30 minutes from now
	err := createToken(ctx)
	s.Require().NoError(err)

	// Advance time past the expiry
	timer.Advance(31 * time.Minute)

	// Now the token should be considered expired
	valid, err := validateToken(ctx)
	s.Require().NoError(err)
	s.Require().False(valid)
}
```

Production code must call `ctx.Time().Now()` (never `time.Now()`) for this to
work. The `timectx.KAContext` interface enforces this at the context boundary.

### Accessing Test-Specific Methods on Fake Clients

The `KAContext` interfaces expose only the production API. Cast to the concrete
type to reach test helpers:

```go
ctx := s.KAContext()

// Access published pub/sub messages
server := ctx.Pubsub().ServerForTests()

// Run all enqueued Cloud Tasks immediately
ctx.Tasks().(*taskstest.TestClient).RunAllTasks(ctx)

// Mock a feature flag value
ctx.FeatureFlags().(*featureflags.TestClient).MockFlagValue("my-flag", true)

// Register a secret value
ctx.Secrets().(*secrets.TestClient).RegisterSecret(mySecretKey, "test-value")
```

### Customising the Test Context

Clone and override individual fields for a single test:

```go
ctx := s.KAContext().Clone()
// Set a specific user for this test
ctx = ctx.WithRequestUser(myTestUser)
```

______________________________________________________________________

## GraphQL Resolver Testing

Import: `github.com/Khan/webapp/dev/gqltest`

### Building a Test Client

```go
import (
	"github.com/Khan/webapp/dev/gqltest"
	"github.com/Khan/webapp/dev/servicetest"
	"github.com/Khan/webapp/pkg/web/gqlclient/js"
	generated "myservice/generated/graphql" // your service's gqlgen schema
)

func (s *mySuite) TestResolver() {
	ctx := s.KAContext()
	client := s.BuildTestClientForSchema(ctx, generated.NewExecutableSchema(generated.Config{
		Resolvers: &myResolver{ctx: ctx},
	}))

	result, err := gqltest.Query(ctx, client.AsUser(), `
        query GetFoo($id: String!) {
            foo(id: $id) { name }
        }
    `, js.Obj{"id": "123"})
	s.Require().NoError(err)
	s.Require().Equal(js.Obj{"foo": js.Obj{"name": "bar"}}, result)
}
```

**Headers are set at client creation time from the context state, not per
query.** To test as a different user, clone the context before building the
client.

### `gqltest` Functions

| Function                                                       | What It Does                                                                                                 |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `gqltest.Query(ctx, client, operation, vars)`                  | Executes a single `query` operation; returns `js.Obj`                                                        |
| `gqltest.Mutate(ctx, client, operation, vars)`                 | Executes a single `mutation` operation; returns `js.Obj`                                                     |
| `gqltest.QueryType(ctx, client, representation, fields, vars)` | Simulates an Apollo Federation `_entities` query for testing resolvers on types that have no top-level query |
| `gqltest.Enum(value)`                                          | Wraps a string so it is rendered as a GraphQL enum (no quotes) in variables                                  |

### `gqltest.QueryType` — Federation Entity Testing

Use `QueryType` to test a resolver on a federated type (one that only exposes
fields via `@key`, not through a root query field).

```go
result, err := gqltest.QueryType(
	ctx,
	client.AsUser(),
	js.Obj{"__typename": "Assignment", "id": "456"}, // @key fields
	`{ dueDate }`, // fields to fetch
	nil,           // extra vars (inlined into fields string)
)
s.Require().NoError(err)
s.Require().Equal("2026-09-01", result["dueDate"])
```

`representation` must include `__typename` and all `@key` fields declared in
the schema. Variables in the `fields` string are inlined, not sent separately.

### `js.Obj` And Related Types

| Type                | Go type          | Use                                         |
| ------------------- | ---------------- | ------------------------------------------- |
| `js.Obj`            | `map[string]any` | JSON objects in query results and variables |
| `js.Array`          | `[]any`          | JSON arrays                                 |
| `js.UnorderedArray` | custom           | Equality check that ignores element order   |

### Auth Adapters

`gqlclient.Client` exposes three auth adapters. Pass one to `gqltest.Query/Mutate/QueryType`:

| Adapter                   | When to Use                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| `client.AsUser()`         | Simulates an authenticated user request (sets user auth headers) |
| `client.AsServiceAdmin()` | Simulates a cross-service admin call                             |
| `client.AsCronForTests()` | Simulates a cron or task queue call                              |

______________________________________________________________________

## Env Var Control (`khantest.Suite`)

```go
func (s *mySuite) TestWithOverride() {
	s.Setenv("MY_FLAG", "true")
	// env var is restored after the test automatically
}
```

______________________________________________________________________

## Sub-Tests

```go
func (s *mySuite) TestFeature() {
	cases := []struct{ name, input string }{
		{"empty", ""},
		{"valid", "hello"},
	}
	for _, tc := range cases {
		s.Run(tc.name, func() {
			s.Require().NotEmpty(tc.input)
		})
	}
}
```

Prefer flat test structures. A single level of `s.Run` for variations is fine;
avoid nesting `s.Run` inside `s.Run`. If a test requires deeply nested setup to
reach the assertion, the code under test likely has too many concerns — consider
extracting a helper or splitting the function.

______________________________________________________________________

## Tests as Design Pressure

A test that is hard to set up is a signal about the production code, not the
test. Common signals and their implications:

| Test difficulty                                | Likely cause                                       |
| ---------------------------------------------- | -------------------------------------------------- |
| Constructor requires many fake dependencies    | Function has too many responsibilities; split it   |
| Need to cast `KAContext` to multiple fakes     | Function's context interface is too broad          |
| Cannot test without running a full HTTP server | Logic is buried inside HTTP handlers; extract it   |
| Time-sensitive test requires `time.Sleep`      | Code calls `time.Now()` directly; use `ctx.Time()` |

If testing a single behavior requires an unreasonable amount of setup, treat
that as a refactoring signal before adding more test infrastructure.

______________________________________________________________________

## Key Import Paths

| Symbol                         | Import                                                                             |
| ------------------------------ | ---------------------------------------------------------------------------------- |
| `khantest.Suite`               | `github.com/Khan/webapp/dev/khantest`                                              |
| `servicetest.Suite`            | `github.com/Khan/webapp/dev/servicetest`                                           |
| `servicetest.ExecutableSchema` | `github.com/Khan/webapp/dev/servicetest` (re-export of `graphql.ExecutableSchema`) |
| `gqltest.Query`                | `github.com/Khan/webapp/dev/gqltest`                                               |
| `js.Obj`                       | `github.com/Khan/webapp/pkg/web/gqlclient/js`                                      |
| `taskstest.TestClient`         | `github.com/Khan/webapp/pkg/gcloud/tasks/taskstest`                                |
| `featureflags.TestClient`      | `github.com/Khan/webapp/pkg/external/featureflags`                                 |
| `secrets.TestClient`           | `github.com/Khan/webapp/pkg/gcloud/secrets`                                        |
