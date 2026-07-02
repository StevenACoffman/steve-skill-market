---
name: context-cancellation-cause
description: |
  Trigger: user uses context cancellation or timeout and wants to know WHY a context was
  canceled — for logging, debugging, alerting, or routing retry logic. The standard
  "context canceled" / "context deadline exceeded" errors say a context was canceled but
  not what caused it. Go 1.20 added context.WithCancelCause and context.Cause to attach
  a specific reason to any cancellation. Go 1.21 added WithTimeoutCause to label the
  timeout path. The critical gotcha: WithTimeoutCause returns a plain CancelFunc, so
  defer cancel() on the success path discards the cause — context.Cause returns nil.
  Fix: use WithCancelCause + time.AfterFunc to wire the timer manually; a single
  CancelCauseFunc covers all paths, and first-cancel-wins records the most specific
  reason. When downstream code also needs errors.Is(err, context.DeadlineExceeded) to
  work, stack WithCancelCause on top of WithTimeoutCause with careful LIFO defer
  ordering.
tags: [go, context, concurrency, observability, debugging]
---

# Context Cancellation Cause

## R — Original Text (Reading)

> Go 1.20 and 1.21 added cause-tracking functions to the `context` package that fix this,
> but there's a subtlety with `WithTimeoutCause` that most examples skip.
>
> `WithTimeoutCause` returns `(Context, CancelFunc)`, not `(Context, CancelCauseFunc)`. The
> cancel function you get back doesn't accept an error argument. Think about what happens
> when `processOrder` finishes normally in 100ms, well before the 5-second timeout:
> `defer cancel()` fires. Since it's a plain `CancelFunc`, it can't take a cause argument.
> The Go source shows what it does internally: `return c, func() { c.cancel(true, Canceled, nil) }`.
> It passes `Canceled` with a nil cause. Your custom cause only gets recorded when the
> internal timer fires. On the normal return path, the cause is just `context.Canceled`.
>
> The way around this is to skip `WithTimeoutCause` and wire the timer yourself using
> `WithCancelCause`. Since there's only one `CancelCauseFunc`, every path goes through the
> same door, and first-cancel-wins handles the rest.
> — rednafi, context_cancellation_cause

______________________________________________________________________

## I — Methodological Framework (Interpretation)

**The cause API surface:**

- `context.WithCancelCause(parent)` returns `(ctx, cancelCause func(error))` — the `CancelCauseFunc` accepts an error
- `context.Cause(ctx)` returns the error passed to `cancelCause`, or falls back to `ctx.Err()` if not canceled with cause; returns `nil` on an uncanceled context
- `context.WithTimeoutCause(parent, d, cause)` labels only the timeout path; its returned cancel is a plain `CancelFunc` — `defer cancel()` calls `c.cancel(true, Canceled, nil)` internally, discarding any cause on the success path

**The asymmetry (the gotcha):**

- Timeout fires first: `context.Cause(ctx)` returns your custom message — correct
- Function returns first: `defer cancel()` runs with no cause argument — `context.Cause(ctx)` returns `nil` — cause lost
- This is intentional design per rsc: "the cancel on one of these is typically just for cleanup" — but it creates a subtle, silent gap on the most common path

**Fix: manual timer with WithCancelCause (covers all paths):**

```go
ctx, cancel := context.WithCancelCause(ctx)        // one CancelCauseFunc for everything
defer cancel(errors.New("processOrder completed")) // default cause if nothing else cancels first

timer := time.AfterFunc(5*time.Second, func() {
	cancel(fmt.Errorf("order %s: 5s timeout exceeded", orderID)) // timeout path
})
defer timer.Stop() // stop timer on normal return

if err := checkInventory(ctx, orderID); err != nil {
	cancel(fmt.Errorf("order %s: inventory check failed: %w", orderID, err))
	return err
}
```

**First-cancel-wins:** the most specific `cancel` call — closest to the actual failure — is recorded; all subsequent calls are no-ops. `defer cancel(nil)` only takes effect if nothing else canceled first.

**Trade-off of manual timer approach:** `ctx.Err()` always returns `context.Canceled`, never `context.DeadlineExceeded`; `ctx.Deadline()` returns zero value; downstream gRPC propagation of deadlines is broken.

**When DeadlineExceeded is also needed:** stack `WithCancelCause` (outer) on top of `WithTimeoutCause` (inner). Defer order is LIFO — `cancelCause` must be deferred after `cancelTimeout` so it runs before it, or `cancelTimeout` cancels the inner context before `cancelCause` sets a meaningful cause.

**Logging pattern:** `ctx.Err()` gives the category (Canceled or DeadlineExceeded); `context.Cause(ctx)` gives the specific reason. Keep as separate structured log fields so they are independently queryable.

**Middleware pattern:** wrap request context with `WithCancelCause` at middleware level; stash the `CancelCauseFunc` via `context.WithValue`; handlers pull it out and call it with a specific error — first-cancel-wins records the most specific reason across the whole request lifecycle.

______________________________________________________________________

## A1 — Past Application

### Case 1: WithTimeoutCause — Timeout Path Labeled, Success Path Cause Lost

- **Problem:** A DB query handler uses `context.WithTimeoutCause(ctx, 5*time.Second, ErrQueryTimeout)` and `defer cancel()`. On timeout the cause is correct. On fast success the middleware logs `context.Cause(ctx)` and gets `nil`, indistinguishable from an un-tracked context. On-call cannot determine whether silence means success or a swallowed cancellation.
- **Method:** Checked `context.Cause(ctx)` in middleware after handler returns. Added a playground reproduction confirming that `defer cancel()` on a `WithTimeoutCause`-derived context sets cause to `nil`. Traced the stdlib source: the returned `CancelFunc` calls `c.cancel(true, Canceled, nil)`.
- **Conclusion:** `WithTimeoutCause` only carries the custom cause when the timer fires. `defer cancel()` on any non-timeout path silently discards it. Middleware logging `Cause` sees `nil` on the hot path.
- **Result:** Replaced `WithTimeoutCause` with `WithCancelCause + time.AfterFunc`. All three paths (timeout, error, normal) now carry distinct, non-nil causes. Middleware log field `cause` is consistently populated.

### Case 2: Manual Timer + WithCancelCause — All Paths Carry Cause

- **Problem:** A DB query handler needs to distinguish client disconnect, slow DB timeout, and success in structured logs, plus set different retry/alert behavior per cause.
- **Method:** Applied the manual timer pattern: `WithCancelCause` + `time.AfterFunc` for timeout; explicit `cancel(ErrClientGone)` on client disconnect detection; explicit `cancel(ErrQueryTimeout)` in timer callback; `defer cancel(nil)` as fallback. Logged `ctx.Err()` (category) and `context.Cause(ctx)` (specific reason) as separate slog fields.
- **Conclusion:** The three log lines now read `cause="client disconnected"`, `cause="db query timeout"`, `cause="query completed"` instead of all showing `context canceled`. Alerting rules can key on the cause field independently of the error category.
- **Result:** Incident triage time for context-related failures dropped. Retry logic correctly skips retries on `ErrClientGone` and retries with backoff on `ErrQueryTimeout`. No production regression; `ctx.Err()` still returns `context.Canceled` which existing callers handle correctly.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Language Signals

- "I keep seeing `context: context canceled` in logs but can't tell why"
- "I have a timeout but don't know if it fired or if something else canceled the context"
- "how do I trace why my context was canceled"
- "context canceled vs context deadline exceeded — how do I distinguish client disconnect from timeout"
- "I want to log the cancellation reason in my middleware"
- "how do I attach a reason to context.Cancel"
- "WithTimeoutCause isn't working on the success path"
- "context.Cause returns nil even though I set a cause"

### Distinguishing from Adjacent Skills

- **Difference from `structured-goroutine-lifetime`:** `structured-goroutine-lifetime` is about ensuring goroutines are bounded and don't leak — lifetime management. This skill is about why a context was canceled once it is canceled — observability and triage. They compose: use errgroup for lifetime, then use `WithCancelCause` to label cancellation reasons.
- **Difference from `error-translation-layer-boundaries`:** error translation converts storage-specific errors into domain sentinels as they cross layer boundaries. Cancellation cause is about labeling the context lifecycle itself — the cause lives on the context, not in the error return value, and is read via `context.Cause`, not `errors.Is`.

______________________________________________________________________

## E — Execution Steps

1. **Replace WithCancel/WithTimeout/WithTimeoutCause with WithCancelCause**

   - `ctx, cancel := context.WithCancelCause(parent)`
   - Remove any `context.WithTimeoutCause` call if all-paths cause tracking is needed
   - Completion criteria: `cancel` is a `CancelCauseFunc` (accepts an `error` argument)

2. **Wire time.AfterFunc for the timeout path**

   - `timer := time.AfterFunc(timeout, func() { cancel(fmt.Errorf("...: timeout exceeded")) })`
   - `defer timer.Stop()` immediately after, to stop the timer on normal return
   - Completion criteria: the timeout path calls `cancel` with a specific error sentinel; timer is stopped on early exit to avoid a goroutine firing after the function returns

3. **Add explicit cause on each cancellation path**

   - Error path: `cancel(fmt.Errorf("operation X failed: %w", err))` before `return err`
   - Client disconnect: `cancel(ErrClientGone)`
   - Normal completion fallback: `defer cancel(nil)` — runs only if no other cancel fired first
   - Completion criteria: `context.Cause(ctx)` returns a non-nil, meaningful error for each failure path; `defer cancel(nil)` is present as a safety fallback

4. **Log context.Cause(ctx) as a separate structured field at the top level**

   - `slog.Error("request failed", "err", ctx.Err(), "cause", context.Cause(ctx))`
   - `ctx.Err()` = category (Canceled / DeadlineExceeded); `context.Cause(ctx)` = specific reason
   - Completion criteria: logs show specific cause string, not just "context canceled"; the two fields are independently queryable in log aggregation

5. **If downstream code needs errors.Is(err, context.DeadlineExceeded): use stacked contexts**

   - `ctx, cancelCause := context.WithCancelCause(ctx)` (outer)
   - `ctx, cancelTimeout := context.WithTimeoutCause(ctx, d, cause)` (inner)
   - `defer cancelTimeout()` first; `defer cancelCause(errors.New("completed"))` second (LIFO: cancelCause runs first)
   - Completion criteria: timeout path sets both `DeadlineExceeded` (via inner) and custom cause; error paths set cause via outer `cancelCause`; `errors.Is(ctx.Err(), context.DeadlineExceeded)` works for timeout detection

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- Simple timeout with no need to distinguish timeout vs. other cancellation — `context.WithTimeout` is sufficient and less code
- Library code that shouldn't know about cancellation reasons — pass context through, let the caller interpret the cause at the boundary where it's meaningful
- Fire-and-forget operations where cancellation cause is irrelevant to callers or monitoring
- Codebase targets Go < 1.20 — `context.WithCancelCause` is not available; `context.WithTimeoutCause` requires Go 1.21

### Failure Patterns

- **defer cancel() on success path discards cause — the WithTimeoutCause gotcha (ce06):** Using `WithTimeoutCause` + `defer cancel()` looks correct but `context.Cause(ctx)` returns `nil` on the happy path. The custom cause only appears when the timer fires. Fix: use the manual timer pattern.
- **Multiple goroutines calling cancel() — only first wins:** This is correct behavior, but it must be documented in code. The most specific `cancel` call should happen closest to the failure site, before any deferred `cancel(nil)` runs.
- **Reversed LIFO defer order in stacked context pattern:** If `defer cancelCause(...)` is deferred before `defer cancelTimeout()`, then `cancelTimeout()` runs first (LIFO), canceling the inner context with `context.Canceled` before `cancelCause` can set a meaningful cause. Always defer `cancelTimeout` first, `cancelCause` second.
- **Inspecting context.Cause on the inner context after stacking:** After line (2) in the stacked pattern, `ctx` points to the inner context. `context.Cause(ctx)` on the inner context after a `cancelCause(specificErr)` call shows `context.Canceled` (propagated from outer), not the specific error. The specific cause lives on the outer context variable.

### Author's Blind Spots

- `context.WithCancelCause` is Go 1.20+; `context.WithTimeoutCause` is Go 1.21+ — not available in codebases pinned to older Go versions
- The manual timer approach is more complex than `WithTimeout`; for simple timeouts with no need to distinguish cancellation reasons, `WithDeadline + checking ctx.Deadline()` is simpler
- No guidance on propagating cause across service boundaries — gRPC sends `ctx.Deadline()` across the wire (which the manual timer approach breaks); HTTP responses don't carry context cause automatically
- The stdlib HTTP server and most third-party libraries predating Go 1.20 cancel contexts without setting a cause (client disconnects arrive as `context.Canceled` with no custom cause); the cause APIs are most useful for reasons set by your own code

### Easily Confused With

- `context.WithTimeout` — simpler for pure timeout, but cause is lost on success path; use when you only need timeout, not cause-on-every-path
- Error wrapping patterns (`fmt.Errorf("op: %w", err)`) — error translation is about the `error` return value crossing layer boundaries; cancellation cause is about the context lifecycle, read via `context.Cause(ctx)`, not the return value
- `ctx.Err()` — returns `Canceled` or `DeadlineExceeded` (the category); `context.Cause(ctx)` returns the specific reason (the why); both are needed for complete logging

______________________________________________________________________

## Related Skills

- **composes-with** `structured-goroutine-lifetime`: Structured goroutine lifetime management uses context cancellation as the stop signal — goroutines check `ctx.Done()` in loops and return when the context is cancelled. `context.WithCancelCause` adds observability to that signal: when errgroup cancels the shared context on first error, `context.Cause(ctx)` in middleware or logging shows exactly which goroutine failed and why. Use errgroup for lifetime; use `WithCancelCause` to label the reason.
- **composes-with** `context-key-collision-prevention`: Both are about using `context` correctly in the same request lifecycle. A request context often carries both typed value keys (request ID, user ID) via `WithValue` and a cancellation cause via `WithCancelCause`. Correct key types prevent value shadowing; correct cancel cause tracking preserves the cancellation reason. Apply both when instrumenting middleware.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Go Advice" by Redowan Delowar (rednafi) — context_cancellation_cause
