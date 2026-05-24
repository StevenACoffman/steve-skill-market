---
name: webapp-pubsub
description: |
  Use when writing Go code in github.com/Khan/webapp that publishes or
  receives Google Cloud Pub/Sub messages. Covers the KAContext interface,
  SendJSON/SendProtobuf, push subscription handling, pubsub.yaml format,
  ordering keys, read-only mode, and how to assert on published messages in
  tests. ONLY applies to github.com/Khan/webapp.

  Trigger signals:
  - "how do I publish a pub/sub message in webapp?"
  - "how do I handle a push subscription in webapp?"
  - "how do I assert that a message was published in a test?"
  - "what is pubsub.yaml for?"
  - "how do I use ordering keys?"
  - Any question about Pub/Sub in webapp Go code
allowed-tools: Bash, Read, Edit, Write
---

# Pub/Sub in Webapp

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. The
> `pubsub` package wraps the Google Cloud Pub/Sub API with webapp-specific
> interface types, message signing, and a test emulator. Do not apply these
> patterns to any other repository.

Package: `github.com/Khan/webapp/pkg/gcloud/pubsub`

______________________________________________________________________

## KAContext Interface

```go
type KAContext interface {
	Pubsub() Client             // Read-write client
	PubsubProdFallback() Client // Prod client available from dev environments
}
```

Embed `pubsub.KAContext` in a function's context parameter when the function
publishes messages.

______________________________________________________________________

## Publishing Messages

### Protobuf Messages (Preferred for Structured Data)

```go
import "github.com/Khan/webapp/pkg/gcloud/pubsub"

func publishEvent(ctx interface {
	pubsub.KAContext
	timectx.KAContext
	secrets.KAContext
	web.FrontendAppNameContext
}, msg *mypb.MyEvent) error {
	result, err := ctx.Pubsub().SendProtobuf(ctx, "my-topic-name", msg)
	if err != nil {
		return err
	}
	// Optionally log the result asynchronously
	ctx.Pubsub().LogResult(func() {
		if _, err := result.Get(ctx); err != nil {
			// handle publish error
		}
	})
	return nil
}
```

`SendProtobuf` sets the `Info` field on the protobuf message in-place before
publishing, filling in a UUID, the current timestamp, and the request ID from
context. The proto type must implement `KAProtobuf`:

```go
type KAProtobuf interface {
	proto.Message
	GetInfo() *protos.Common
}
```

### JSON Messages

```go
result, err := ctx.Pubsub().SendJSON(ctx, "my-topic-name", myStruct, nil)
```

Pass a `map[string]string` as the last argument to attach custom attributes.

### Publishing with an Ordering Key

```go
result, err := ctx.Pubsub().SendProtobufWithOrderingKey(
	ctx, "my-topic-name", msg, orderingKey,
)
```

The topic's subscription must have `enableMessageOrdering: true` in
`pubsub.yaml`. If publishing fails for a key, call `ResumePublish` before
retrying:

```go
ctx.Pubsub().ResumePublish("my-topic-name", orderingKey)
```

### Message Signing

All messages are automatically signed with an HMAC-SHA512 signature attached
as a `signature` attribute. Do not add or verify signatures manually — the
package handles this.

______________________________________________________________________

## Receiving Messages (Push Subscriptions)

Push subscriptions deliver messages as HTTP POST requests. Decode and validate
the incoming request with:

```go
func handlePush(ctx interface {
	secrets.KAContext
	web.FrontendAppNameContext
}, r *http.Request) error {
	data, err := pubsub.DecodeAndValidatePushMsg(ctx, r)
	if err != nil {
		return err
	}
	var msg mypb.MyEvent
	if err := proto.Unmarshal(data, &msg); err != nil {
		return err
	}
	// process msg
	return nil
}
```

`DecodeAndValidatePushMsg` decodes the GCP push envelope, verifies the HMAC
signature, and returns the raw message bytes. It returns an error if the
signature is invalid.

______________________________________________________________________

## `pubsub.yaml` Format

Declare topics and subscriptions in `pubsub.yaml` at the service root. This
file is read by `AutoRegisterPubsubYamlForDev` in dev and test environments.

```yaml
  - topic: my-topic-name
    subscriptions:
      my-subscription-name:
        endpoint: https://my-service-cloudrun-region.run.app/path/to/handler
        retainAckedMessages: false
        enableMessageOrdering: false
        ackDeadlineSeconds: 60
```

| Field                   | Notes                                                        |
| ----------------------- | ------------------------------------------------------------ |
| `topic`                 | GCP topic name                                               |
| `subscriptions`         | Map of subscription name → config                            |
| `endpoint`              | Push endpoint URL; rewritten to the local emulator in dev    |
| `retainAckedMessages`   | Keep messages after ack (useful for replay)                  |
| `enableMessageOrdering` | Enable FIFO delivery for messages with the same ordering key |
| `ackDeadlineSeconds`    | Seconds the subscriber has to ack before redelivery          |

______________________________________________________________________

## Read-Only Mode

Services operating in a preview or read-only context receive a `Client` where
publishing is disabled. Calls to `SendJSON`/`SendProtobuf` return a
`ReadOnlyError`. The `kalog` topic is exempt from read-only restrictions.

Get a read-only client explicitly with `client.CloneReadOnly()`, or restore
full publishing with `client.CloneReadWrite()`.

______________________________________________________________________

## Asynchronous Result Logging

`LogResult` runs a callback when the publish result is ready. In production it
runs in a goroutine (non-blocking). In tests it runs synchronously:

```go
ctx.Pubsub().LogResult(func() {
	if _, err := result.Get(ctx); err != nil {
		ctx.Log().Warn(errors.Internal("publish failed", err))
	}
})
```

______________________________________________________________________

## Idempotency and Error Handling

Pub/Sub subscriptions retry delivery on any non-200 response. Handlers must be
idempotent — processing the same message twice must produce the same result.

Distinguish retryable from permanent failures in the handler's return value:

| Return        | What Pub/Sub does                             |
| ------------- | --------------------------------------------- |
| `nil`         | Acks message — delivery complete              |
| non-nil error | Nacks message — redelivered up to retry limit |

For **permanent failures** (bad signature, schema mismatch, data that will
never be valid), log a warning and return `nil` to ack and stop retries. For
**transient failures** (downstream service unavailable), return an error to
trigger retry.

```go
func handlePush(ctx interface {
	secrets.KAContext
	web.FrontendAppNameContext
	log.KAContext
}, r *http.Request) error {
	data, err := pubsub.DecodeAndValidatePushMsg(ctx, r)
	if err != nil {
		// Permanent — bad signature; ack to discard
		ctx.Log().Warn(errors.Internal("invalid push message", err))
		return nil
	}
	var msg mypb.MyEvent
	if err := proto.Unmarshal(data, &msg); err != nil {
		// Permanent — schema mismatch; ack to discard
		ctx.Log().Warn(errors.Internal("unmarshal failed", err))
		return nil
	}
	// Transient failures: return error to trigger retry
	return processEvent(ctx, &msg)
}
```

______________________________________________________________________

## Side Effects at Boundary

Keep publish calls at the outermost layer (HTTP handler, task handler, cron
function). Functions that transform or compute data should accept and return
plain values; only the entry point calls `SendProtobuf`/`SendJSON`. This makes
business logic independently testable without a Pub/Sub client.

______________________________________________________________________

## Testing — Asserting on Published Messages

`servicetest.Suite.KAContext()` wires up an in-process Pub/Sub emulator
automatically. After code that publishes a message runs, retrieve messages via
`ServerForTests()`:

```go
func (s *mySuite) TestPublishesEvent() {
	ctx := s.KAContext()

	// Run code under test that publishes to "my-topic-name"
	err := myFunc(ctx)
	s.Require().NoError(err)

	// Inspect published messages
	server := ctx.Pubsub().ServerForTests()
	msgs := server.Messages()
	s.Require().Len(msgs, 1)

	var got mypb.MyEvent
	s.Require().NoError(proto.Unmarshal(msgs[0].Data, &got))
	s.Require().Equal("expected-value", got.SomeField)
}
```

`ServerForTests()` returns a `*pstest.Server` (Google Cloud's in-process
emulator). Call `server.ClearMessages()` between subtests if needed.

### Creating a Test Push Message

To test a push handler, construct a valid signed envelope with:

```go
body, err := pubsub.NewPushMessageForTests(ctx, msgBytes)
s.Require().NoError(err)

req := httptest.NewRequest(http.MethodPost, "/my/handler", bytes.NewReader(body))
// pass req to your handler
```

______________________________________________________________________

## Key Import Paths

| Symbol                            | Import                                     |
| --------------------------------- | ------------------------------------------ |
| `pubsub.KAContext`                | `github.com/Khan/webapp/pkg/gcloud/pubsub` |
| `pubsub.Client`                   | `github.com/Khan/webapp/pkg/gcloud/pubsub` |
| `pubsub.KAProtobuf`               | `github.com/Khan/webapp/pkg/gcloud/pubsub` |
| `pubsub.DecodeAndValidatePushMsg` | `github.com/Khan/webapp/pkg/gcloud/pubsub` |
| `pubsub.NewPushMessageForTests`   | `github.com/Khan/webapp/pkg/gcloud/pubsub` |
| `pstest.Server`                   | `cloud.google.com/go/pubsub/v2/pstest`     |
