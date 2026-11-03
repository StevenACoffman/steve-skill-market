---
name: webapp-kacontext
description: "Use when writing or reviewing Go code in github.com/Khan/webapp that touches context. Covers KAContext sub-interface selection, Upgrade() entry points, logging, time, HTTP, request data, lifecycle methods, and test contexts. Only for github.com/Khan/webapp."
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

## Reference Files

Read these only when the task needs them:

- [`references/time-http-env.md`](references/time-http-env.md) — read when code
  reads the clock, makes an outbound HTTP request, or needs an environment
  variable in `services/` or `pkg/`.
- [`references/web-request-data.md`](references/web-request-data.md) — read when
  a handler or resolver needs the authenticated user, locale, host, or cookies,
  or when writing a login mutation that calls `SetActor`.
- [`references/lifecycle-and-constructors.md`](references/lifecycle-and-constructors.md)
  — read when adding a deadline or value (`WithContext`), starting a goroutine
  that outlives the request (`Detach`), needing a read-only context, reading
  prod data from dev, or wiring a production or script context in `main.go`.
- [`references/kacontext-testing.md`](references/kacontext-testing.md) — read
  when writing tests that need a KAContext or a replaced client.
- [`references/common-mistakes.md`](references/common-mistakes.md) — read when
  reviewing context code or fixing a `ka-context`, `ka-context-interface`, or
  `ka-banned-symbol` finding.
- [`references/stale-imports.md`](references/stale-imports.md) — read after
  removing sub-interfaces from `ctx` parameters, when `go vet` reports
  `imported and not used`.
