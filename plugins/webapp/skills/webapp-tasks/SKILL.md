---
name: webapp-tasks
description: |
  Use when writing Go code in github.com/Khan/webapp that creates or handles
  Cloud Tasks. Covers the KAContext interface, TaskConfig, queue.yaml format,
  CreateTask/DeleteTask, GraphQLTask helper, task handler registration with
  serve.CreateTaskHandler, header forwarding, and taskstest patterns. ONLY
  applies to github.com/Khan/webapp.

  Trigger signals:
  - "how do I enqueue a task in webapp?"
  - "how do I write a task handler?"
  - "how do I create a deferred GraphQL mutation task?"
  - "how do I test Cloud Tasks?"
  - "what is queue.yaml for?"
  - "how do I use RunAllTasks in a test?"
  - Any question about Cloud Tasks in webapp Go code
allowed-tools: Bash, Read, Edit, Write
---

# Cloud Tasks in Webapp

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. The
> `tasks` package, `queue.yaml` conventions, and `taskstest` helpers are
> webapp-specific. Do not apply these patterns to any other repository.

Package: `github.com/Khan/webapp/pkg/gcloud/tasks`

______________________________________________________________________

## KAContext Interface

```go
type KAContext interface {
	Tasks() Client
	context.Context
	httpctx.KAContext
	secrets.KAContext
	service_discovery.KAContext
	web.ServiceVersionContext
}
```

Embed `tasks.KAContext` in a function's context parameter when the function
creates or deletes tasks. `ctx.Tasks()` returns a `Client`.

______________________________________________________________________

## Client Interface

```go
type Client interface {
	CreateTask(ctx KAContext, queue string, task *TaskConfig) error
	DeleteTask(ctx KAContext, queue string, taskName string) error
	WithHeaderForwarding(requestHeader http.Header) Client
	CloneReadOnly() Client
	CloneReadWrite() Client
}
```

| Method                 | Notes                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------- |
| `CreateTask`           | Enqueues `task` to `queue`; `queue` must exist in `queue.yaml`                                       |
| `DeleteTask`           | Removes task by name; `taskName` is the bare name from `TaskConfig.Name`                             |
| `WithHeaderForwarding` | Returns a new client that forwards an allowlisted subset of `requestHeader` to every task it creates |
| `CloneReadOnly`        | Returns a client that rejects `CreateTask`/`DeleteTask`                                              |
| `CloneReadWrite`       | Reverses `CloneReadOnly`                                                                             |

`CreateTask` returns an error with gRPC status code `codes.AlreadyExists` when
a task with the same name is already in the queue:

```go
func createIdempotent(ctx kacontext.Base, task *tasks.TaskConfig) error {
	err := ctx.Tasks().CreateTask(ctx, "my-deferred-queue", task)
	if status.Code(err) == codes.AlreadyExists {
		// idempotent — task already enqueued
		return nil
	}
	return err
}
```

______________________________________________________________________

## TaskConfig

```go
type TaskConfig struct {
	Name         string      // Optional; auto-assigned UUID if empty (alphanumeric, hyphens, underscores only)
	ScheduleTime time.Time   // When to execute; zero value means immediately
	Target       string      // Cloud Run service name OR an https:// URL
	HTTPMethod   string      // "POST" (default), "GET", "PUT", "DELETE", etc.
	RelativeURI  string      // URL path (default: "/"); ignored if Target is a full URL
	Headers      http.Header // Custom headers; no multi-value headers allowed
	Body         []byte      // Request body; only valid with POST, PUT, or PATCH
}
```

### Basic Task

```go
err := ctx.Tasks().CreateTask(ctx, "my-deferred-queue", &tasks.TaskConfig{
	Target:      "my-service",
	RelativeURI: "/tasks/my-handler",
	Body:        jsonBytes,
})
```

### Scheduled (Delayed) Task

```go
err := ctx.Tasks().CreateTask(ctx, "my-deferred-queue", &tasks.TaskConfig{
	Target:       "my-service",
	RelativeURI:  "/tasks/my-handler",
	Body:         jsonBytes,
	ScheduleTime: time.Now().Add(30 * time.Minute),
})
```

### Named Task (For Deduplication)

Setting `Name` prevents the same logical task from being enqueued twice.
Google Cloud Tasks holds a name for 4 days after completion.

```go
err := ctx.Tasks().CreateTask(ctx, "my-deferred-queue", &tasks.TaskConfig{
	Name:        "backfill-user-" + kaid,
	Target:      "my-service",
	RelativeURI: "/tasks/backfill",
	Body:        jsonBytes,
})
```

______________________________________________________________________

## GraphQL Mutation Tasks

Use `tasks.GraphQLTask` to create a task that fires a GraphQL mutation via the
`graphql-gateway`. The mutation **must be idempotent** because the task queue
retries on error.

The first argument is **not** a raw mutation string. `ka-graphql-task` requires
it to be a `genqlient.<service>_Task_<something>_Operation` symbol generated
from a `# @genqlient` directive in the same file. A raw string fails the linter.

```go
// Bad — raw mutation string (ka-graphql-task fires)
func badEnroll(ctx tasks.KAContext, userKaid, classId string) error {
	task, err := tasks.GraphQLTask(
		`mutation EnrollUser($kaid: String!, $classId: String!) {
			enrollUserInClassroom(kaid: $kaid, classId: $classId) {
				error { code }
			}
		}`,
		map[string]any{"kaid": userKaid, "classId": classId},
	)
	if err != nil {
		return errors.Wrap(err)
	}
	return ctx.Tasks().CreateTask(ctx, "enrollments-deferred-queue", task)
}

// Good — declare the operation with @genqlient, then pass the generated
//
//	_Operation symbol. The directive lives in the same file as the call.
func goodEnroll(ctx tasks.KAContext, kaid, classID string) error {
	_ = `# @genqlient
		mutation Enrollments_Task_EnrollUser($kaid: String!, $classId: String!) {
			enrollUserInClassroom(kaid: $kaid, classId: $classId) {
				error { code }
			}
		}
	`

	task, err := tasks.GraphQLTask(
		genqlient.Enrollments_Task_EnrollUser_Operation,
		map[string]any{"kaid": kaid, "classId": classID},
	)
	if err != nil {
		return errors.Wrap(err)
	}
	return ctx.Tasks().CreateTask(ctx, "enrollments-deferred-queue", task)
}
```

The operation name must follow the `<service>_Task_<something>` convention —
the linter checks that `_Task_` appears in the symbol name and that it ends in
`_Operation`. The service prefix (e.g. `Enrollments_`) must match the owning
service's operation-name mapping; `ka-cross-service-opname` flags mismatches.

`GraphQLTask` sets `Target: "graphql-gateway"` and routes to
`/tasks/graphql/{operationName}`. The queue's `target` in `queue.yaml` must
also be `graphql-gateway`.

The gateway retries the task if the response contains a top-level `errors`
array or any field named `error` or `errors`.

______________________________________________________________________

## `queue.yaml` Format

Declare queues in `services/{name}/queue.yaml` (service-specific) or
`pkg/queue.yaml` (shared). Convention: queue names end in `-deferred-queue`.

```yaml
queue:
  - name: my-service-deferred-queue
    rate: 90/s
    target: my-service         # Cloud Run service name, or https:// URL
    retry_parameters:
      min_backoff_seconds: 120
      task_retry_limit: 10
```

| Field                                  | Notes                                                                             |
| -------------------------------------- | --------------------------------------------------------------------------------- |
| `name`                                 | Must follow `foo-deferred-queue` naming convention                                |
| `rate`                                 | Dispatch rate (e.g., `90/s`, `5/m`)                                               |
| `target`                               | Cloud Run service name or `https://` URL; use `graphql-gateway` for GraphQL tasks |
| `retry_parameters.min_backoff_seconds` | Minimum wait between retries                                                      |
| `retry_parameters.task_retry_limit`    | Maximum number of retries before dropping the task                                |

______________________________________________________________________

## Task Handler Registration

Register task handlers alongside your other HTTP routes using
`serve.CreateTaskHandler`. The wrapper validates that the request came from
Cloud Tasks before calling your handler.

```go
serve.Main(
	ctx,
	serve.HandleFunc(
		"/tasks/my-handler",
		serve.CreateTaskHandler(func(r *http.Request) error {
			var payload myPayload
			if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
				return err
			}
			return doWork(r.Context(), payload)
		}),
	),
)
```

`serve.CreateTaskHandler`:

- Requires `POST`; returns 405 otherwise.
- Validates the request is from Cloud Tasks via a secret header; returns 401
  if not.
- Returns 200 on success; returns an error status on non-nil error.

______________________________________________________________________

## Header Forwarding

Attach a filtered subset of the originating request's headers to every task
the client creates. Only an allowlisted set of headers is forwarded (including
`X-Ka-Kaid`, `X-Ka-Locale`, `X-Ka-Fastly-Country`, and trace headers).

```go
taskClient := ctx.Tasks().WithHeaderForwarding(r.Header)
err := taskClient.CreateTask(ctx, "my-queue", task)
```

Pass the returned client to any function that needs to enqueue tasks in the
context of an ongoing request.

______________________________________________________________________

## Testing — `taskstest`

Import: `github.com/Khan/webapp/pkg/gcloud/tasks/taskstest`

`servicetest.Suite.KAContext()` wires up a `taskstest.TestClient`
automatically. Tasks do **not** run automatically; call `RunAllTasks` when you
want to execute them.

### Run All Queued Tasks

```go
func (s *mySuite) TestEnqueuesAndRunsTask() {
	ctx := s.KAContext()

	// Run the code under test that enqueues a task
	err := myFunc(ctx)
	s.Require().NoError(err)

	// Execute all enqueued tasks against the service handler
	testClient := ctx.Tasks().(*taskstest.TestClient)
	err = testClient.TestServer().RunAllTasks(ctx)
	s.Require().NoError(err)

	// Assert on side-effects produced by the task handler
}
```

`RunAllTasks` executes each queued task exactly once in an arbitrary
deterministic order. It returns an error if any task fails (collecting all
failures), but continues running remaining tasks even after a failure.

### Assert on Queued Tasks Without Running Them

```go
queued := ctx.Tasks().(*taskstest.TestClient).TestServer().QueuedTasks()
s.Require().Len(queued, 1)
s.Require().Equal("/tasks/my-handler", queued[0].RelativeURI)
```

### Providing a Handler to `taskstest`

By default the test client runs tasks against a nil handler (which panics). If
`RunAllTasks` needs to execute task HTTP callbacks, pass your handler at
construction:

```go
handler := s.GetTestServer(ctx).Config.Handler
testClient := taskstest.NewTestClient(handler)
// wire into context
```

When `servicetest.Suite` creates the client automatically, it is created
without a handler; replace it in the context if your test requires actual task
execution.

______________________________________________________________________

## Read-Only Mode

`CloneReadOnly()` returns a client where `CreateTask` and `DeleteTask` return
`ReadOnlyError`. Used in contexts where tasks must not be created (e.g.,
preview mode or goshell).

```go
roClient := ctx.Tasks().CloneReadOnly()
```

______________________________________________________________________

## Handler Idempotency and Error Handling

Cloud Tasks retries any handler that returns a non-2xx response. All task
handlers — not just GraphQL mutation tasks — must be idempotent.

Distinguish retryable from permanent failures:

| Return value  | What Cloud Tasks does                       |
| ------------- | ------------------------------------------- |
| `nil`         | 200 OK — task complete                      |
| non-nil error | 5xx — task retried up to `task_retry_limit` |

After `task_retry_limit` retries, Cloud Tasks silently drops the task. Webapp
does **not** route dropped tasks to a dead-letter queue (DLQ) by default. If
silent loss is unacceptable, keep a durable record of the task before enqueueing
and mark it complete inside the handler.

For **permanent failures** (malformed payload, data that will never be valid),
log a warning and return `nil` to consume the task and stop retries:

```go
serve.CreateTaskHandler(func(r *http.Request) error {
	var payload myPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		// Permanent — bad payload; consume task to stop retries
		log.Warnf(r.Context(), "bad task payload: %v", err)
		return nil
	}
	// Transient failures: return error to trigger retry
	return doWork(r.Context(), payload)
})
```

______________________________________________________________________

## Side Effects at Boundary

Enqueue tasks at the outermost layer — HTTP handler, resolver, or cron
function. Functions that compute or transform data should accept plain values
and return plain values; only the entry point calls `ctx.Tasks().CreateTask`.
This keeps business logic independently testable without a tasks client.

______________________________________________________________________

## Tasks Vs Pub/Sub

| Dimension              | Cloud Tasks                                  | Pub/Sub                                              |
| ---------------------- | -------------------------------------------- | ---------------------------------------------------- |
| **Delivery guarantee** | Exactly-once attempt; retry on failure       | At-least-once; always retries until ack              |
| **Fan-out**            | One handler per task                         | Multiple subscriptions per topic                     |
| **Scheduling**         | Supports future `ScheduleTime`               | No scheduling; delivers immediately                  |
| **Deduplication**      | Named tasks are deduplicated for 4 days      | No deduplication                                     |
| **Ordered delivery**   | No ordering guarantee                        | Ordering keys available per subscription             |
| **Use when**           | Deferred work for one consumer; delayed jobs | Multiple consumers; event fan-out; ordered pipelines |

______________________________________________________________________

## Key Import Paths

| Symbol                    | Import                                              |
| ------------------------- | --------------------------------------------------- |
| `tasks.KAContext`         | `github.com/Khan/webapp/pkg/gcloud/tasks`           |
| `tasks.Client`            | `github.com/Khan/webapp/pkg/gcloud/tasks`           |
| `tasks.TaskConfig`        | `github.com/Khan/webapp/pkg/gcloud/tasks`           |
| `tasks.GraphQLTask`       | `github.com/Khan/webapp/pkg/gcloud/tasks`           |
| `taskstest.TestClient`    | `github.com/Khan/webapp/pkg/gcloud/tasks/taskstest` |
| `serve.CreateTaskHandler` | `github.com/Khan/webapp/pkg/web/serve`              |
