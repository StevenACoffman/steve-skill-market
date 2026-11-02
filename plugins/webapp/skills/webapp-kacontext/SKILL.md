---
name: webapp-kacontext
description: |
  Use when writing or reviewing any Go code in github.com/Khan/webapp that touches context. Covers KAContext sub-interface selection, Upgrade() entry points, logging, time, HTTP, web request data, lifecycle methods, and test contexts. ONLY applies to github.com/Khan/webapp — do not apply to any other repository.
allowed-tools: Bash, Read, Edit
---

# KAContext in Khan Academy Webapp

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. The
> `kacontext` system, its sub-interfaces, and all patterns here are webapp-specific
> and must not be applied to any other repository.

`kacontext` is webapp's dependency-injection system built on top of `context.Context`.
Every service function receives a `ctx` that carries typed client handles (datastore,
logging, HTTP, pubsub, etc.) rather than injecting them as separate parameters.
The system uses Go interface composition to make each function's dependencies explicit
and compile-time verified.

______________________________________________________________________

## Sub-Interface Reference

Each capability is a one-method interface in its own package. Embed only what a
function actually calls.

| Interface                            | Import path (relative to `github.com/Khan/webapp/`) | Method                                                          | What it provides                             |
| ------------------------------------ | --------------------------------------------------- | --------------------------------------------------------------- | -------------------------------------------- |
| `kacontext.Base`                     | `pkg/kacontext`                                     | `WithContext`, `Detach`, `Close`, `MaybeSetRequestIDAndTraceID` | Core context operations; always embed this   |
| `log.KAContext`                      | `pkg/lib/log`                                       | `Log() Logger`                                                  | Structured logging                           |
| `timectx.KAContext`                  | `pkg/lib/timectx`                                   | `Time() Timer`                                                  | Injectable time (`Now`, `Since`)             |
| `httpctx.KAContext`                  | `pkg/lib/httpctx`                                   | `HTTP() *http.Client`                                           | Outbound HTTP client                         |
| `datastore.KAContext`                | `pkg/gcloud/datastore`                              | `Datastore() Client`                                            | Cloud Datastore                              |
| `memorystore.KAContext`              | `pkg/gcloud/memorystore`                            | `Memorystore() *Client`                                         | Redis                                        |
| `pubsub.KAContext`                   | `pkg/gcloud/pubsub`                                 | `Pubsub() Client`                                               | Pub/Sub publish                              |
| `tasks.KAContext`                    | `pkg/gcloud/tasks`                                  | `Tasks() Client`                                                | Cloud Tasks enqueue                          |
| `gqlclient.KAContext`                | `pkg/gqlclient`                                     | `GraphQL() Client`                                              | Cross-service GraphQL                        |
| `emails.KAContext`                   | `pkg/emails`                                        | `Emails() Client`                                               | Transactional email                          |
| `secrets.KAContext`                  | `pkg/gcloud/secrets`                                | `Secrets() Client`                                              | Secret Manager                               |
| `gcs.KAContext`                      | `pkg/gcloud/gcs`                                    | `GCS() Client`                                                  | Cloud Storage                                |
| `bigquery.KAContext`                 | `pkg/gcloud/bigquery`                               | `BigQuery() Client`                                             | BigQuery                                     |
| `alloydb.KAContext`                  | `pkg/gcloud/alloydb`                                | `AlloyDB() Client`                                              | AlloyDB (Postgres)                           |
| `featureflags.KAContext`             | `pkg/featureflags`                                  | `FeatureFlags() Client`                                         | Feature flags                                |
| `slack.KAContext`                    | `pkg/slack`                                         | `Slack() Client`                                                | Slack notifications                          |
| `fastly.KAContext`                   | `pkg/fastly`                                        | `Fastly() Client`                                               | Fastly CDN                                   |
| `pubsub.SendProtobufContext`         | `pkg/gcloud/pubsub`                                 | `SendProtobuf(...)`                                             | Publish protobuf messages to Pub/Sub         |
| `pubsub.LogContext`                  | `pkg/gcloud/pubsub`                                 | `LogPubsubEvent(...)`                                           | Log pub/sub event metadata                   |
| `events.PublishEventContext`         | `pkg/events`                                        | `PublishEvent(...)`                                             | Domain event publishing                      |
| `web.AuthedUserContext`              | `pkg/web`                                           | `RequestUser() (*UserIdentity, error)`                          | Current authenticated user                   |
| `web.AuthedTaskContext`              | `pkg/web`                                           | `RequestTask()`                                                 | Authenticated task identity                  |
| `web.AuthedServiceContext`           | `pkg/web`                                           | `RequestService()`                                              | Authenticated service-to-service identity    |
| `web.BrowserContext`                 | `pkg/web`                                           | `Browser()`                                                     | Browser/user-agent info                      |
| `web.CookieContext`                  | `pkg/web`                                           | `Cookies()`, `SetCookie()`                                      | Cookie read/write                            |
| `web.KALocaleContext`                | `pkg/web`                                           | `KALocale()`                                                    | Request locale                               |
| `web.IPContext`                      | `pkg/web`                                           | `RequestIP()`                                                   | Caller IP address                            |
| `web.OriginalHostContext`            | `pkg/web`                                           | `OriginalHost()`                                                | Incoming hostname                            |
| `web.PublishedContentVersionContext` | `pkg/web`                                           | `PublishedContentVersion()`                                     | Active content deployment version            |
| `web.RatelimitContext`               | `pkg/web`                                           | `Ratelimit()`                                                   | Rate-limit information for the request       |
| `web.SetActorContext`                | `pkg/web`                                           | `SetActor(...)`                                                 | Replace authenticated user (login mutations) |
| `environ.ServiceNameContext`         | `pkg/environ`                                       | `ServiceNameFromEnv()`                                          | Service name at runtime                      |
| `environ.ServiceVersionContext`      | `pkg/environ`                                       | `ServiceVersionFromEnv()`                                       | Deployed version                             |

______________________________________________________________________

## Declaring Context Requirements

### Pattern a — Named Interface for Service Functions

Use a named interface type when the same context shape is used by multiple
functions in a file or package, or when the interface has more than ~5 members.

```go
// Define the interface at package scope, near the function that uses it.
type HandleDonationSuccessContext interface {
	kacontext.Base
	log.KAContext
	gqlclient.KAContext
	datastore.KAContext
	timectx.KAContext
	emails.KAContext
}

func HandleDonationSuccess(
	ctx HandleDonationSuccessContext,
	params *HandleDonationSuccessParams,
) error {
	ctx.Log().Info("processing donation", log.Fields{"donationID": params.DonationID})
	user, err := cross_service.GetUser(ctx, params.Kaid)
	// ...
}
```

### Pattern B — Inline Anonymous Interface in Resolvers

GraphQL resolvers receive `context.Context` from the gqlgen runtime. Upgrade at
the top of the resolver, using an inline interface to declare exactly what the
resolver needs.

Note that `context.Context` is often included in the inline interface alongside
`kacontext.Base`. This is necessary when the variable needs to be passed to
gqlgen-generated or other library code that accepts `context.Context` — embedding
`context.Context` in the interface type ensures the static type of `ktx` satisfies
that parameter.

```go
func (r *mutationResolver) CreateUserAssessment(
	ctx context.Context,
	input graphql.CreateUserAssessmentInput,
) (*graphql.CreateOrResumeUserAssessmentResponse, error) {
	var ktx interface {
		kacontext.Base
		context.Context // needed to pass ktx to library code taking context.Context
		alloydb.KAContext
		gqlclient.KAContext
		log.KAContext
		secrets.KAContext
		timectx.KAContext
		web.AuthedUserContext
	} = kacontext.Upgrade(ctx)

	ktx.Log().SetDefaultFields(log.Fields{"assessmentID": input.AssessmentID})

	user, err := ktx.RequestUser()
	if err != nil {
		return nil, errors.Wrap(err)
	}
	// ...
}
```

### Embed Only What You Call

`ka-context-interface` enforces this at compile time: every embedded sub-interface
must be referenced via an actual method call or passed to a callee that requires it.

```go
// Bad — embeds datastore but never calls ctx.Datastore()
type MyContext interface {
	kacontext.Base
	log.KAContext
	datastore.KAContext // unused — linter fires
}

// Good — only what the function body actually uses
type MyContext interface {
	kacontext.Base
	log.KAContext
}
```

**Do not put an omnibus interface in a function signature.** `kacontext.TestContext`
exists for the test suite (it embeds every capability), but production code must
take the narrowest interface it uses. Same for the per-package omnibus types you
might see in `cmd/` wiring: those are entry-point types, not service-function
parameter types.

```go
// Bad — function signature takes the test omnibus; ka-context-interface
// fires for every capability the body doesn't call.
func badProcessSignup(ctx kacontext.TestContext, args *Args) error {
	ctx.Log().Info("starting", nil)
	return nil
}

// Bad — function signature takes the concrete kacontext type. Aside from
//
//	defeating dependency narrowing, this also makes the function impossible
//	to call with a narrower interface in tests.
func badProcessSignupConcrete(ctx *kacontext.KAContext, args *Args) error {
	ctx.Log().Info("starting", nil)
	return nil
}

// Good — declare a named interface with exactly the sub-interfaces called.
type ProcessSignupContext interface {
	kacontext.Base
	log.KAContext
	datastore.KAContext
	emails.KAContext
}

func goodProcessSignup(ctx ProcessSignupContext, args *Args) error {
	ctx.Log().Info("starting", nil)
	return nil
}
```

If the function calls only one or two sub-interfaces, use an inline anonymous
interface in the parameter type rather than declaring a named one:

```go
// Good — 2-interface helper inlines the type
func goodLogFailure(
	ctx interface {
		kacontext.Base
		log.KAContext
	},
	err error,
) {
	ctx.Log().Error(errors.Wrap(err))
}
```

### Passing Ctx Between Functions

Because all KAContext values satisfy any interface whose methods they implement,
simply pass `ctx` to callees that require a narrower interface:

```go
type ProcessSignupContext interface {
	kacontext.Base
	log.KAContext
	datastore.KAContext
	emails.KAContext
	tasks.KAContext
	timectx.KAContext
}

func ProcessSignup(ctx ProcessSignupContext, args *Args) error {
	// logOnlyOp only needs log.KAContext — ctx satisfies it
	logOnlyOp(ctx, args.Email)

	// datastoreOp needs kacontext.Base + datastore.KAContext — ctx satisfies it
	if err := datastoreOp(ctx, args); err != nil {
		return errors.Wrap(err)
	}
	return nil
}
```

______________________________________________________________________

## `kacontext.Upgrade()`

`Upgrade` converts a plain `context.Context` into a `*kaContext` that satisfies
the requested interface. It must only be called at these entry points:

| Entry point                | Example                                                                |
| -------------------------- | ---------------------------------------------------------------------- |
| `main()`                   | Service startup wiring                                                 |
| GraphQL resolver functions | `func (r *mutationResolver) CreateFoo(ctx context.Context, ...) ...`   |
| HTTP request handlers      | Functions with `*http.Request` or `*httputil.ProxyRequest` parameter   |
| `PreSave()` model methods  | `func (m *MyModel) PreSave(ctx context.Context) error`                 |
| Dataloader functions       | Load functions registered with the dataloader framework                |
| Pub/Sub message handlers   | `sub.Receive(ctx, func(_ context.Context, msg *pubsub.Message) {...})` |

Calling `Upgrade` outside these entry points is a `ka-context` linter violation.

```go
// HTTP handler entry point
func (rts *Routes) HandleGraphQL(w http.ResponseWriter, r *http.Request) {
	var ctx interface {
		kacontext.Base
		datastore.KAContext
		log.KAContext
		timectx.KAContext
		web.AuthedUserContext
		web.KALocaleContext
		// ... other sub-interfaces this handler needs
	} = kacontext.Upgrade(r.Context())

	// ctx is now fully typed; use it throughout the handler
}

// PreSave — minimal context, just what the hook needs
func (m *AssessmentTask) PreSave(ctx context.Context) error {
	var ktx interface {
		timectx.KAContext
	} = kacontext.Upgrade(ctx)

	if err := m.BaseModel.PreSave(ctx); err != nil {
		return errors.Wrap(err)
	}
	m.UpdatedAt = ktx.Time().Now()
	return datastore.CheckTransactionSafetyForPut(ctx, m)
}
```

**Pub/Sub message handlers** need one additional call: `MaybeSetRequestIDAndTraceID()`
assigns a fresh trace ID and request ID to the context so that log lines emitted
while processing a message are correlated. The message callback receives a plain
`context.Context`, not a KAContext, so both Upgrade and trace assignment are needed:

```go
sub.Receive(baseCtx, func(_ context.Context, msg *pubsub.Message) {
	var ktx interface {
		kacontext.Base
		log.KAContext
		datastore.KAContext
		timectx.KAContext
		pubsub.LogContext
	} = kacontext.Upgrade(baseCtx).MaybeSetRequestIDAndTraceID()

	ktx.Log().Info("processing message", log.Fields{"msgID": msg.ID})
	// ...
	msg.Ack()
})
```

`Upgrade` panics if the context was not originally created by `kacontext` — it
checks whether the context chain contains a `*kaContext`. In tests this is provided
by `servicetest.Suite`.

______________________________________________________________________

## Logging

The `Logger` interface has two distinct calling conventions. **Debug and Info**
take a string message plus optional `log.Fields` maps. **Warn, Error, and Panic**
take only a Khan `error` object — structured context goes on the error, not as
a separate fields argument.

```go
// Debug / Info — string message, optional fields
ctx.Log().Debug("cache miss", log.Fields{"key": cacheKey})
ctx.Log().Info("logged in", log.Fields{
	"kaid":      kaid,
	"loginType": loginType,
})

// Warn / Error / Panic — error object only; attach context via errors.Wrap
ctx.Log().Error(errors.Wrap(err, "operation", "cancelRecurring"))
ctx.Log().Warn(errors.NotFound("user not found", errors.Fields{"kaid": kaid}))
ctx.Log().Panic(errors.Internal("invariant violated"))

// SetDefaultFields — persisted on ctx.Log(); merged into every subsequent call
ctx.Log().SetDefaultFields(log.Fields{"assessmentID": input.AssessmentID})

// Sensitive data — obfuscate before logging
ctx.Log().Info("sent verification email", log.ObfuscateEmail(ctx, recipientEmail, nil))

// Security events — routed to SIEM; different severity semantics than application logs
ctx.Log().Security(log.InfoLevel, "auth token issued", log.Fields{"kaid": kaid})
```

Key rules:

- Never pass `fmt.Sprintf(...)` as the message — `ka-log` enforces this.
- `Debug`/`Info` `fieldsMaps` is variadic: `ctx.Log().Info("msg")` is fine when there are no fields.
- To add context to an error log, attach it to the error: `errors.Wrap(err, "key", val)`.
- `log.Fields` is for `Debug`/`Info`; `errors.Fields` is the analogous type for
  `errors.New`/`errors.Wrap`. Do not confuse them — they are different types.
- `SetDefaultFields` is useful for request-scoped identifiers (assessment ID, user ID)
  that should appear on every subsequent log line within the request handler.

______________________________________________________________________

## Time

`ctx.Time().Now()` and `ctx.Time().Since()` replace `time.Now()` and
`time.Since()` everywhere. `ka-banned-symbol` bans the bare stdlib versions in
service code.

```go
// Bad
now := time.Now()
elapsed := time.Since(start)

// Good
now := ctx.Time().Now()
elapsed := ctx.Time().Since(start)

// In tests, the suite provides an advancing timer, making time deterministic:
ctx := suite.KAContext()
beforeTime := ctx.Time().Now()
doOperation(ctx)
afterTime := ctx.Time().Now()
suite.Require().True(afterTime.After(beforeTime))
```

______________________________________________________________________

## HTTP

`ctx.HTTP()` returns the injected `*http.Client`. Build requests with
`http.NewRequestWithContext`. `ka-banned-symbol` bans `http.DefaultClient`,
bare `http.Get`, and `http.NewRequest`.

```go
// Bad
resp, err := http.Get(url)
req, _ := http.NewRequest("POST", url, body)

// Good
req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, body)
if err != nil {
	return errors.Wrap(err)
}
req.Header.Set("Content-Type", "application/json")
resp, err := ctx.HTTP().Do(req)
if err != nil {
	return errors.Wrap(err)
}
defer resp.Body.Close()
```

______________________________________________________________________

## Environment Variables

`os.Getenv`, `os.LookupEnv`, `os.Environ`, and `os.ExpandEnv` are banned in
`services/` and `pkg/` (`ka-banned-symbol`). The model is **read once at the
top level, then thread the value through** — service code never asks the OS
directly.

Exempt locations: `cmd/` scripts, `pkg/kacontext`, `pkg/web/serve`, any
`root.go`, and test files (test files may also use `suite.Setenv`).

```go
// Bad — reading envvars in a service or pkg function
func badNewClient() *Client {
	url := os.Getenv("MY_SERVICE_URL")    // ka-banned-symbol
	timeout, _ := os.LookupEnv("TIMEOUT") // ka-banned-symbol
	return &Client{URL: url, Timeout: timeout}
}

// Bad — listing all envvars in service/pkg code
func badListEnv() {
	for _, kv := range os.Environ() { // ka-banned-symbol
		_ = kv
	}
}

// Good — main reads, constructor receives explicit values
//
//	cmd/serve/root.go (or main.go):
func goodMainWiring() *Client {
	url := os.Getenv("MY_SERVICE_URL") // ok in root.go / main.go
	timeout := os.Getenv("TIMEOUT")
	return goodNewClient(url, timeout)
}

// pkg/myservice/client.go:
func goodNewClient(url, timeout string) *Client {
	return &Client{URL: url, Timeout: timeout}
}

// Good — iterate envvars via the context (works in service/pkg code)
func goodListEnv(ctx kacontext.Base) {
	for k, v := range kacontext.Environ(ctx) {
		_, _ = k, v
	}
}

// Good — tests use suite.Setenv (auto-cleaned)
func (suite *MySuite) TestFoo() {
	suite.Setenv("MY_FLAG", "true")
	// ...
}
```

For envvars that must be read after startup (e.g. a script that wants to
honour `--env` overrides), use `kacontext.Environ(ctx)` rather than reaching
back through `os` — the context-provided map respects test overrides.

______________________________________________________________________

## Web Request Data

`web.*Context` interfaces expose per-request data parsed from the incoming HTTP
request. These are available after `Upgrade()` in handlers and resolvers.

```go
// Current authenticated user
user, err := ctx.RequestUser()
if err != nil {
	// err is non-nil if there is no authenticated user
	return nil, errors.Wrap(err)
}
kaid := user.Kaid
isPhantom := user.IsPhantom

// Locale
locale := ctx.KALocale() // e.g., "en", "es"

// Request hostname
host := ctx.OriginalHost() // e.g., "www.khanacademy.org"

// Cookie read/write
cookieVal := ctx.Cookies().Get("my_cookie")
ctx.SetCookie(w, cookie)
```

### `SetActor` — Updating the Authenticated User After Login

Login mutations replace the request's authenticated user after verifying credentials:

```go
ctx.SetActor(
	web.UserIdentity{
		Kaid:              kaid,
		BingoID:           userData.GAEBingoIdentity,
		HasAnyPermissions: userData.HasAnyPermissions,
		IsPhantom:         userData.IsPhantom,
	},
	cookies.NewCookieCache(userData, userSettings, "").AsCombinedHeader(),
)
// After SetActor: ctx.RequestUser() returns the new identity,
// and cross-service GraphQL calls include updated auth headers.
```

`SetActor` is only available via `web.SetActorContext`. Include it in the context
interface only in login-related code.

______________________________________________________________________

## Context Lifecycle Methods

### `WithContext` — Attach a New Deadline or Value

```go
// Add a deadline without losing the KAContext clients:
ctx = ctx.WithContext(context.WithDeadline(ctx, deadline))

// Add a context value:
ctx = ctx.WithContext(context.WithValue(ctx, myKey, myValue))
```

### `Detach` — Fire-and-Forget Goroutines

`Detach` creates a copy of the KAContext with all clients intact, but with a fresh
background context (so the detached work is not canceled when the request ends).
It also registers the goroutine for graceful shutdown.

```go
detachedCtx, cancel := ctx.Detach(5 * time.Minute) // 0 = no timeout
defer cancel()
go func() {
	if err := doBackgroundWork(detachedCtx); err != nil {
		detachedCtx.Log().Error(errors.Wrap(err))
	}
}()
```

Do not share the original `ctx` with goroutines that outlive the request — the
request context will be canceled when the handler returns.

### `MakeReadOnly` — Read-Only Context for Safe Reads

Returns a context where write-capable clients (datastore, memorystore, pubsub)
are replaced with read-only variants. Use in backfill read-phase or dry-run paths.

```go
roCtx := ctx.MakeReadOnly()
// roCtx.Datastore() is read-only — puts and deletes will error
```

### `ProdDatastoreFallback` — Access Prod Data from a Dev Context

In development environments, the primary datastore client points at the dev
emulator. `ProdDatastoreFallback()` returns a read-only client pointing at the
production datastore — useful for scripts that need to inspect prod data without
writing to it.

```go
// Available only on datastore.KAContext; nil in prod (primary IS prod)
if fallback := ctx.ProdDatastoreFallback(); fallback != nil {
	entity, err := fallback.Get(ctx, key, &dst)
}
```

Do not use `ProdDatastoreFallback` in production service code — it returns `nil`
in prod and is intended only for dev scripts and tooling.

______________________________________________________________________

## Context Constructors

### In Production Code

Production and development contexts are created by the service's `main.go`
(the only non-Upgrade call site permitted):

| Constructor                                               | When used                                       |
| --------------------------------------------------------- | ----------------------------------------------- |
| `kacontext.NewForProd()`                                  | Cloud Run / App Engine production deployment    |
| `kacontext.NewForDev()`                                   | Local dev server (`dev_appserver.py` or Docker) |
| `kacontext.InitializeScriptContextForWriteableProd(&ctx)` | Scripts with prod write access                  |
| `kacontext.InitializeScriptContextForReadOnlyProd(&ctx)`  | Scripts with prod read-only access              |

Script contexts return a cleanup function:

```go
cleanup := kacontext.InitializeScriptContextForWriteableProd(&ctx)
defer cleanup()
```

### In Tests

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

______________________________________________________________________

## Common Mistakes

### Over-Broad Context Embedding

```go
// Bad — embeds everything; linter fires for each unused sub-interface
type MyContext interface {
	kacontext.Base
	context.Context
	datastore.KAContext
	log.KAContext
	timectx.KAContext
	httpctx.KAContext
	emails.KAContext    // never called
	gqlclient.KAContext // never called
}

// Good — only what the function body calls
type MyContext interface {
	kacontext.Base
	log.KAContext
	timectx.KAContext
}
```

**Test-complexity signal:** In tests, each sub-interface that the function uses
requires a fake client to be wired up or cast from the KAContext. If a test
requires casting to five or six different fakes just to call a single function,
the context interface is a sign that the function has too many responsibilities.
Consider splitting it into smaller functions, each with a narrower interface.

### Calling `Upgrade` Outside an Entry Point

```go
// Bad — Upgrade in a service-layer function (ka-context linter violation)
func doWork(ctx context.Context) error {
	ktx := kacontext.Upgrade(ctx) // WRONG
	// ...
}

// Good — receive a properly-typed KAContext from the caller
func doWork(ctx interface {
	kacontext.Base
	log.KAContext
}) error {
	ctx.Log().Info("doing work", nil)
	// ...
}
```

### Using `context.Background()` in Non-Init/main Production Code

```go
// Bad (ka-context linter violation in non-test code)
func newDetachedOp() {
	ctx := context.Background() // WRONG outside init/main
}

// Good — use Detach() from an existing KAContext
func doWorkDetached(ctx kacontext.Base) {
	detachedCtx, cancel := ctx.Detach(time.Minute)
	defer cancel()
	_ = detachedCtx
}
```

`context.Background()` is allowed in test files.

### `time.Now()` In Service Code

```go
// Bad (ka-banned-symbol)
record.CreatedAt = time.Now()
elapsed := time.Since(start)

// Good
record.CreatedAt = ctx.Time().Now()
elapsed := ctx.Time().Since(start)
```

### Mixing up `log.Fields` and `errors.Fields`

```go
// Bad — errors.Fields passed to Info (wrong type)
ctx.Log().Info("failed", errors.Fields{"kaid": kaid})

// Bad — log.Fields passed to errors.Wrap (wrong type)
return errors.Wrap(err, log.Fields{"kaid": kaid})

// Good
ctx.Log().Info("logged in", log.Fields{"kaid": kaid}) // Info takes log.Fields
ctx.Log().Error(errors.Wrap(err, "kaid", kaid))       // Error takes error
return errors.Wrap(err, "kaid", kaid)                 // errors.Wrap takes key, val pairs
```

### Passing Structured Fields to `Warn`/`Error` as a Second Argument

```go
// Bad — Warn and Error do not accept a fields map
ctx.Log().Error(err, log.Fields{"kaid": kaid}) // compile error

// Good — attach context to the error itself
ctx.Log().Error(errors.Wrap(err, "kaid", kaid))
```

### Missing `context.Context` Embed When Passing to Gqlgen or Stdlib Code

`*kaContext` always satisfies `context.Context` at runtime. The issue is whether
the interface variable's **static type** advertises the `context.Context` methods
to the compiler.

```go
// Bad — compile error: ktx doesn't satisfy context.Context
var ktx interface {
	kacontext.Base
	log.KAContext
	web.AuthedUserContext
} = kacontext.Upgrade(ctx)

// genqlient.MakeRequest(ktx, query) — compile error: cannot use ktx as context.Context

// Good — embed context.Context when passing to gqlgen-generated or stdlib code
var ktx2 interface {
	kacontext.Base
	context.Context
	log.KAContext
	web.AuthedUserContext
} = kacontext.Upgrade(ctx)

// genqlient.MakeRequest(ktx2, query) — ok
```

Embed `context.Context` only when `ktx` needs to be passed to code that accepts
a plain `context.Context`. Omit it when `ktx` is only passed to service functions
that accept KAContext sub-interfaces directly (they don't need the `context.Context`
methods advertised).

______________________________________________________________________

### Sharing the Request Context with Goroutines

```go
// Bad — goroutine uses ctx after request ends, causing use-after-cancel
go func() {
	slowOp(ctx) // ctx may be canceled before this finishes
}()

// Good
detachedCtx, cancel := ctx.Detach(2 * time.Minute)
defer cancel()
go func() {
	slowOp(detachedCtx)
}()
```

______________________________________________________________________

## Cleaning up Stale Imports After Context Edits

When you remove a sub-interface from a `ctx` parameter (e.g. dropping
`log.KAContext` because the function no longer logs), the corresponding import
often becomes unused. `go vet ./...` flags these as `imported and not used`.
The script below collects the offending file paths and runs `goimports -w`
on each:

```bash
#!/usr/bin/env bash
# Run `go vet ./...` from the webapp module root, collect any "imported and
# not used" errors, and apply `goimports -w` to each unique offending file.
set -u

go vet ./... 2>&1 |
	grep -E '^[^[:space:]]+\.go:[0-9]+:[0-9]+: .*imported and not used' |
	awk -F: '{print $1}' |
	sort -u |
	xargs -I{} goimports -w {}
```

**Cascading-fix variant.** Fixing one file can unblock a downstream package
that `go vet` previously refused to type-check. Loop until the output is
empty (capped to avoid an infinite loop on something the script can't fix):

```bash
#!/usr/bin/env bash
set -u

for _ in 1 2 3 4 5; do
	hits=$(go vet ./... 2>&1 |
		grep -E '^[^[:space:]]+\.go:[0-9]+:[0-9]+: .*imported and not used' |
		awk -F: '{print $1}' |
		sort -u)
	[ -z "$hits" ] && break
	xargs -I{} goimports -w {} <<<"$hits"
done
```

**Before running:**

- Commit or stash first — `goimports -w` rewrites in place.
- Ensure `goimports` is in `PATH`
  (`go install golang.org/x/tools/cmd/goimports@latest` if missing).
- Run from the webapp module root, not a subdirectory, so file paths in
  `go vet` output are resolvable from the current directory.

**Known limitation.** When `go vet` emits errors under a `# package/path`
header, the diagnostic line uses a package-relative path
(e.g. `client.go:5:2:` rather than `./pkg/foo/client.go:5:2:`). The script
won't find those files and `goimports` will print "no such file" for them;
the rest of the batch still completes. Re-run from the affected package
directory, or fix those by hand.
