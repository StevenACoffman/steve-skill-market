---
name: webapp-analytics
description: |
  Use when writing Go code in github.com/Khan/webapp that instruments
  analytics events via the CEDAR pipeline. Covers analytics_events.yml
  format, the make eventgen workflow (eventsync + eventgen), the shape of
  generated models/publish/test files, how to call generated publish
  functions, and how to verify published events in tests. ONLY applies to
  github.com/Khan/webapp.

  Trigger signals:
  - "how do I add a new analytics event in webapp?"
  - "how do I publish an analytics event?"
  - "what does make eventgen do?"
  - "what is analytics_events.yml?"
  - "how do I test that an event was published?"
  - Any question about CEDAR event instrumentation in webapp
allowed-tools: Bash, Read, Edit, Write
---

# Analytics Event Tracking (CEDAR Pipeline)

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. The
> CEDAR event pipeline, `analytics_events.yml`, and the generated event code
> are webapp-specific. Do not apply these patterns to any other repository.

______________________________________________________________________

## Overview

Each service declares which analytics events it publishes in
`analytics_events.yml`. Running `make eventgen` syncs schemas from the central
event schema registry and generates three Go files. Calls to the generated
publish functions flow through Pub/Sub to the CEDAR analytics pipeline.

The event schemas themselves live in the `Khan/event-schemas` repository.
**You must publish a schema version in that repo before you can reference it
in `analytics_events.yml`.**

______________________________________________________________________

## `analytics_events.yml` Format

Located at the root of each service directory (e.g.,
`services/my-service/analytics_events.yml`).

```yaml
events:
  - name: MyEvent
    version: 1
  - name: MyEvent
    version: 2       # multiple versions of the same event are allowed
  - name: OtherEvent
    version: 3
```

| Field     | Notes                                                             |
| --------- | ----------------------------------------------------------------- |
| `name`    | Exact event name as published in `Khan/event-schemas`             |
| `version` | Integer schema version; must be merged to main in `event-schemas` |

______________________________________________________________________

## Code Generation Workflow

```bash
cd services/my-service
make eventgen
```

This runs two steps in order:

1. **`eventsync`** — Reads `analytics_events.yml`, fetches matching schemas
   from the central schema registry, and writes
   `generated/analytics_events/schemas.json`.

2. **`eventgen`** — Reads `schemas.json` and renders three files under
   `generated/analytics_events/`:

   - `models.go` — Struct definitions for each event version
   - `publish.go` — A `Publish*` function for each event version
   - `test.go` — A `Verify*` function for each event version

Commit all generated files. Run `make verify-eventgen` in CI to confirm
generated files match the source YAML.

______________________________________________________________________

## Generated Code

### `models.go`

One struct per event version. The struct embeds `events.EventBase` with struct
tags that record the event type name and schema version:

```go
type MyEventV1 struct {
	events.EventBase `eventType:"MyEvent" schemaVersion:"1"`
	Title            string `json:"title"`
	ContentId        string `json:"contentId"`
	Score            *int   `json:"score"` // nullable → pointer
}
```

Enum fields get their own named type:

```go
type StatusMyEventV1 string

const (
	PublishedStatusMyEvent StatusMyEventV1 = "PUBLISHED"
	DraftStatusMyEvent     StatusMyEventV1 = "DRAFT"
)
```

### `publish.go`

One function per event version. The function requires a context that satisfies
three interfaces:

```go
func PublishMyEventV1(
	ctx interface {
		events.PublishEventContext
		timectx.KAContext
		log.KAContext
	},
	title string,
	contentId string,
	score *int, // nullable fields are pointers
	status *StatusMyEventV1, // enum nullable field
	opts ...events.PublishOption,
) {
	// publishes via Pub/Sub; logs a warning on error
}
```

Publish errors are non-fatal: the function logs a `Warn` and continues. This
matches the CEDAR pipeline contract (best-effort delivery for analytics).

### `test.go`

One verification function per event version, used in tests:

```go
func VerifyMyEventV1(
	message *pstest.Message,
	expectedTitle string,
	expectedContentId string,
	expectedScore *int,
	expectedStatus *StatusMyEventV1,
) error
```

Returns a non-nil error if any field does not match.

______________________________________________________________________

## Publishing an Event

```go
import analytics "github.com/Khan/webapp/services/my-service/generated/analytics_events"

func handleAction(ctx interface {
	events.PublishEventContext
	timectx.KAContext
	log.KAContext
}) {
	score := 95
	status := analytics.PublishedStatusMyEvent
	analytics.PublishMyEventV1(ctx, "Introduction to Go", "x:abc123", &score, &status)
}
```

The `KAContext` from `servicetest.Suite` satisfies all three required
interfaces automatically.

______________________________________________________________________

## Context Requirements

| Interface                    | Import                                   | Purpose                             |
| ---------------------------- | ---------------------------------------- | ----------------------------------- |
| `events.PublishEventContext` | `github.com/Khan/webapp/pkg/analytics`   | Routes to the correct Pub/Sub topic |
| `timectx.KAContext`          | `github.com/Khan/webapp/pkg/lib/timectx` | Provides the event timestamp        |
| `log.KAContext`              | `github.com/Khan/webapp/pkg/lib/log`     | Logs publish errors as warnings     |

______________________________________________________________________

## Testing — Verifying a Published Event

`servicetest.Suite.KAContext()` includes a Pub/Sub emulator. After calling
code that publishes an event, retrieve messages from the emulator and use the
generated `Verify*` function:

```go
func (s *mySuite) TestPublishesMyEvent() {
	ctx := s.KAContext()

	score := 95
	status := analytics.PublishedStatusMyEvent
	// call the production code that internally publishes
	err := myHandler(ctx, "Introduction to Go", "x:abc123", score)
	s.Require().NoError(err)

	msgs := ctx.Pubsub().ServerForTests().Messages()
	s.Require().Len(msgs, 1)

	err = analytics.VerifyMyEventV1(msgs[0], "Introduction to Go", "x:abc123", &score, &status)
	s.Require().NoError(err)
}
```

`VerifyMyEventV1` handles timestamp comparison at microsecond precision and
checks event type and schema version fields automatically.

______________________________________________________________________

## Side Effects at Boundary

Keep `Publish*` calls at the outermost layer — HTTP handler, task handler, or
cron function. Pass plain data into service functions and call the generated
publish function only after the service function succeeds. This makes business
logic independently testable without a Pub/Sub client.

```go
// Good — publish happens at the handler boundary, after work succeeds
func handleEnroll(ctx context.Context) error {
	if err := service.EnrollUser(ctx, kaid, classID); err != nil {
		return err
	}
	analytics.PublishUserEnrolledV1(ctx, kaid, classID)
	return nil
}
```

______________________________________________________________________

## Key Import Paths

| Symbol                       | Import                                                              |
| ---------------------------- | ------------------------------------------------------------------- |
| Generated event package      | `github.com/Khan/webapp/services/{name}/generated/analytics_events` |
| `events.PublishEventContext` | `github.com/Khan/webapp/pkg/analytics`                              |
| `timectx.KAContext`          | `github.com/Khan/webapp/pkg/lib/timectx`                            |
| `log.KAContext`              | `github.com/Khan/webapp/pkg/lib/log`                                |
| `pstest.Message`             | `cloud.google.com/go/pubsub/v2/pstest`                              |
