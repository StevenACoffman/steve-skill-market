---
name: structured-goroutine-lifetime
description: |
  Activate when a user is writing, reviewing, or debugging Go code that spawns goroutines
  and any of these signals appear: bare `go func()` without an accompanying WaitGroup or
  errgroup, a function that returns before all goroutines finish, channels that senders can
  block on indefinitely, unbounded goroutine fan-out in a loop, or a question about goroutine
  leaks and how to detect them.

  Trigger signals:
  - "goroutine leak", "leaked goroutine", "goroutine stuck", "blocked on channel send"
  - "how do I wait for goroutines", "fan-out pattern", "worker pool", "bounded concurrency"
  - `go func()` without WaitGroup/errgroup visible in the same scope
  - Early return inside a function that spawned goroutines writing to unbuffered channels
  - `make(chan ...)` with no buffer where multiple senders may not all be read
  - "semaphore", "limit goroutines", "max concurrent", "backpressure"
tags: [go, concurrency, goroutines, safety]
---

# Structured Goroutine Lifetime Management

## R — Original Text (Reading)

> Spawning a thread or goroutine that outlives its parent is the concurrency equivalent of
> `goto`. The spawned work escapes the scope that created it, and now you have to reason about
> lifetimes that cross boundaries. … Never start a goroutine without knowing when it will stop.
> Before writing `go func()`, you should be able to answer: what signals this goroutine to stop,
> and what waits for it to finish? If you can't answer both, the goroutine's lifetime is unknown
> and it can leak. … The trap is the early return. With an unbuffered channel, a send blocks
> until a receiver is ready. If you return before reading from the remaining channels, the
> goroutines writing to them block forever. That's a goroutine leak.
>
> — rednafi, structured_concurrency / early_return_and_goroutine_leak

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Go's `go` statement is deliberately unstructured — it launches a goroutine and walks away.
Unlike Python's `asyncio.TaskGroup` or Kotlin's `coroutineScope`, no scope automatically
waits for it, cancels siblings on failure, or propagates errors. You must impose that
structure yourself, and the cost of skipping it is goroutine leaks that are invisible to
`go vet` and to the race detector.

**Three termination patterns to know:**

1. **errgroup (cancel-on-error)** — `errgroup.WithContext` derives a context that is
   cancelled the moment any goroutine returns a non-nil error. All other goroutines observe
   this via `ctx.Done()` and exit. `g.Wait()` collects the first error and blocks until all
   goroutines finish. This is the Go equivalent of `asyncio.TaskGroup`.

2. **WaitGroup (supervisor / wait-all)** — Siblings keep running regardless of individual
   failures. Errors are collected in a mutex-guarded slice. `wg.Wait()` blocks until all
   goroutines finish. This is the Go equivalent of Kotlin's `supervisorScope`.

3. **Context cancel signal** — A `context.CancelFunc` passed to long-running goroutines lets
   the caller signal "stop now". Goroutines check `ctx.Done()` at loop boundaries or blocking
   operations. This is a signal mechanism, not a lifetime mechanism — the caller must still
   wait (via WaitGroup or errgroup) for goroutines to actually finish after signalling.

**Buffered channel as semaphore:** `sem := make(chan struct{}, N)` limits live goroutines to N
at once. Send into `sem` before spawning (`sem <- struct{}{}`); the send blocks when N slots
are full, applying natural backpressure. The goroutine defers its release (`defer func() { <-sem }()`). The semaphore and errgroup are independent concerns — a semaphore bounds
concurrency; errgroup manages lifetime and error propagation. Combine them by wrapping
`g.Go(func() error { sem <- struct{}{}; defer func() { <-sem }(); return work() })`.

**Early-return + unbuffered channel leak:** When N goroutines each send to their own unbuffered
channel and the receiver returns early after the first error, all remaining senders block
forever. Fix options: (a) always drain all channels before evaluating errors, (b) buffer each
channel by exactly 1 so the send completes without a receiver, or (c) switch to errgroup which
eliminates the channel plumbing entirely.

**The question to ask before every `go func()`:**

> "What signals this goroutine to stop, and what waits for it to finish?"

If you cannot answer both, the goroutine's lifetime is unknown.

______________________________________________________________________

## A1 — Past Application

### Case 1: Early Return on Unbuffered Channel (C04, Ce02)

- **Problem:** A function starts two goroutines, each sending a result to its own unbuffered
  channel. The main goroutine reads from `ch1`, sees an error, and returns immediately. The
  goroutine writing to `ch2` blocks forever on its send — a silent goroutine leak. `go vet`
  is silent; `go test -race` is silent; the test may simply hang.
- **Method:** The author presents three progressive fixes. First: always drain both channels
  before branching on errors, so every send has a matching receive. Second: buffer each channel
  by 1 so the goroutine's send completes into the buffer even if the main goroutine returns
  early. Third (preferred for error aggregation): replace the channel plumbing with errgroup
  — each goroutine returns an error, `g.Wait()` collects the first, and there is nothing left
  to drain or forget.
- **Conclusion:** The draining fix is safe but forces you to wait for all workers even when
  one already failed. Buffering allows early return at the cost of losing the buffered value.
  errgroup is the cleanest path when you only need to aggregate errors across concurrent tasks.
- **Result:** goleak test passes in all three fixed forms. The blocked-sender goroutine
  disappears from the goroutine dump.

### Case 2: Bounding Goroutines with Buffered Channel Semaphore (C07, Ce17)

- **Problem:** A Kafka polling loop spawns one goroutine per message in fire-and-forget style.
  If Kafka produces faster than workers process, goroutine count grows without bound, consuming
  all memory and CPU and potentially overwhelming the downstream system.
- **Method:** A buffered channel `sem := make(chan struct{}, maxConcurrency)` acts as a
  counting semaphore. The main loop sends into `sem` before spawning each goroutine. When all
  N slots are occupied, the send blocks, applying backpressure to the producer loop. The
  goroutine defers a receive from `sem` to release its slot when done. Worker logic stays in
  a clean inner function untouched by semaphore mechanics.
- **Conclusion:** Capacity of `sem` directly controls peak goroutine count. Blocking the
  producer before spawning (not inside the goroutine after) is the correct placement because
  it prevents goroutine creation rather than throttling after the fact. Keeping semaphore logic
  in a closure wrapper around the worker preserves testability of the worker itself.
- **Result:** At `maxConcurrency = 2`, only two workers run simultaneously regardless of
  event rate. Goroutine count stays bounded for the lifetime of the process.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Scenario 1: Fan-Out with Early Error Return

A function spawns goroutines to make parallel HTTP requests. Each goroutine sends its
`(result, error)` to an unbuffered channel. The caller reads results in a loop and returns on
the first error. All unread senders block forever.

### Scenario 2: Fire-and-Forget Worker Pool Under Load

A message consumer spawns `go worker(msg)` in a tight loop. No WaitGroup, no semaphore. When
throughput spikes, goroutine count grows until OOM.

### Scenario 3: Library Function Spawns Internal Goroutine

A library function starts a background goroutine to perform cleanup without telling the caller.
The caller's test finishes, but goleak reports an unexpected goroutine in state "chan receive".
The caller has no handle to wait on it.

### Scenario 4: Background Batch Processor with Cancel-on-Error + Concurrency Bound

A batch job processes N items concurrently, cancels remaining items if any fails (errgroup),
and must never exceed M simultaneous DB connections (semaphore). Both constraints are required
but are separate concerns.

### Scenario 5: Test That Cannot Reproduce a Goroutine Leak

A developer suspects a goroutine leak in production but the test passes. They have not added
goleak to `TestMain`. The leak only manifests under error paths that tests don't hit.

______________________________________________________________________

### Language Signals

- "goroutine is leaking / goroutine leak"
- "how do I limit concurrent goroutines"
- "errgroup vs WaitGroup — which one"
- "goroutine stuck on channel send"
- "test hangs when I trigger an error"
- "how do I wait for all goroutines before returning"
- "semaphore pattern in Go"
- "go func in a loop keeps spawning"
- "unbounded goroutine creation under load"
- "goleak says I have unexpected goroutines"

### Distinguishing from Adjacent Skills

- **Difference from `mutex-closure-atomic-mutation`:** That skill addresses concurrent
  read-modify-write on shared memory (logical races between Get and Set that the race detector
  misses). This skill addresses goroutine spawning, lifetime ownership, and channel send/receive
  balance. The concerns are orthogonal — a goroutine leak can exist with no shared memory; a
  logical mutex race can exist with no goroutine spawning.

- **Difference from `context-cancellation-cause`:** Context cancellation is a signal mechanism
  — it tells goroutines to stop. Lifetime management is about waiting for goroutines to actually
  finish after signalling, ensuring sends complete, and bounding concurrency. You need both:
  cancellation signals the intent to stop; lifetime management enforces that the stop
  completes before the parent returns.

______________________________________________________________________

## E — Execution Steps

1. **Before writing `go func()`, answer two questions.**
   What signals this goroutine to stop? (context cancellation, channel close, errgroup cancel)
   What waits for it to finish? (WaitGroup.Wait, errgroup.Wait, channel drain)
   If you cannot answer both, do not write the `go func()` yet.

2. **Choose the right lifetime owner.**

   - Need to collect the first error and cancel siblings? Use `errgroup.WithContext`. Each
     goroutine returns an error; the group cancels the context on the first non-nil return;
     `g.Wait()` blocks until all finish and returns the first error.
   - Need all goroutines to run regardless of failures and collect all errors? Use
     `sync.WaitGroup` + mutex-guarded `[]error` slice. `wg.Wait()` blocks until all finish.
   - Starting goroutines in a library that callers did not ask for? Don't. Return a value and
     let the caller decide the concurrency model.

3. **For bounded concurrency, compose semaphore + lifetime owner independently.**

   ```go
   sem := make(chan struct{}, maxConcurrency) // concurrency bound
   g, ctx := errgroup.WithContext(ctx)        // lifetime + cancel-on-error

   for _, item := range items {
   	g.Go(func() error {
   		sem <- struct{}{}        // acquire slot; blocks if full
   		defer func() { <-sem }() // release slot on exit
   		select {
   		case <-ctx.Done():
   			return ctx.Err()
   		default:
   			return process(ctx, item)
   		}
   	})
   }
   return g.Wait()
   ```

   The send into `sem` must happen inside `g.Go` (not before), so the errgroup's context
   cancellation can abort a goroutine waiting to acquire a slot.

4. **Fix unbuffered channel + early return.**
   If you cannot switch to errgroup, choose one of:

   - **Drain:** Always receive from all channels before evaluating errors. Correct but forces
     you to wait for all workers even if one already failed.
   - **Buffer by 1:** `make(chan result, 1)`. Each goroutine's send completes into the buffer
     immediately; the goroutine exits even if the receiver returned early. The buffered value
     is lost, which is acceptable for fire-and-forget work.
   - **errgroup (preferred):** Replace channel plumbing with `g.Go(func() error { ... })`.
     No channels, no drain logic, no leak surface.

5. **Add goleak to tests to catch leaks at development time.**

   ```go
   func TestMain(m *testing.M) {
   	goleak.VerifyTestMain(m) // fails if any goroutines are still running
   }
   ```

   For targeted test cases: `defer goleak.VerifyNone(t)` at the top of the test. Cover error
   paths explicitly — leaks usually only manifest when errors occur.

6. **For library code, never spawn goroutines the caller cannot observe.**
   Return a value, accept `context.Context` as the first parameter, and check `ctx.Done()` in
   long-running loops. If a goroutine is truly necessary, return a `Stop()` function or a
   channel the caller can close to signal termination, and document it clearly.

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- The code is single-goroutine or sequential with no `go` statements.
- The question is about channel direction, select mechanics, or buffered vs. unbuffered channel
  semantics without a goroutine lifetime concern.
- The concern is purely about data races on shared memory (use mutex-closure-atomic-mutation).
- The concern is about what cancellation cause to propagate (use context-cancellation-cause).
- The goroutines are already managed by an existing framework (e.g., `net/http` handler pool)
  and the question is about handler logic, not goroutine lifecycle.

### Failure Patterns from the Book

- **Early return on unbuffered channel (ce02, c04):** Two goroutines send to unbuffered
  channels. Main goroutine returns on first error, skipping the second receive. Second sender
  blocks forever. Invisible to `go vet` and race detector. goleak surface this as "goroutine
  in state chan send".

- **Bare go func() in library functions (ce09):** A function spawns a background goroutine
  without tying its lifetime to the caller. The goroutine continues running after the function
  returns, accesses resources freed by the caller, and may crash or corrupt state. The caller
  has no handle to wait on it.

- **Goroutine count growing unbounded under load (ce17):** A polling loop spawns one goroutine
  per message with no semaphore or WaitGroup. At high throughput, goroutine count grows until
  OOM. The system appears healthy under normal load and fails only at spike conditions.

### Author's Blind Spots

- **Buffered channel semaphore doesn't integrate with errgroup naturally.** The send into the
  semaphore must happen inside `g.Go`, not before it, otherwise a goroutine waiting on the
  semaphore has no way to observe context cancellation. The ordering matters and is not
  explicitly documented in the book.

- **`wg.Go` (Go 1.25+) simplifies WaitGroup usage** by handling `Add`/`Done` internally, but
  is not available in most production codebases targeting earlier Go versions. The book's
  WaitGroup examples use the new API. In older codebases, use `wg.Add(1)` before the goroutine
  and `defer wg.Done()` as the first statement inside it.

- **goleak requires covering error paths in tests.** Leaks almost always manifest on error
  paths. If your tests only cover the happy path, goleak will not catch the leak because the
  leaking code path is never exercised.

- **The semaphore pattern shown does not propagate worker errors.** The Kafka polling example
  uses a fire-and-forget goroutine with a semaphore but no error collection. In production,
  you need either a WaitGroup + error slice or errgroup to surface worker failures.

### Easily Confused With

- **Context cancellation** is orthogonal: it is a signal mechanism (telling goroutines to
  stop) not a lifetime mechanism (ensuring they have stopped). You need both together for
  well-structured concurrent code. cancellation without waiting leaks; waiting without
  cancellation hangs.

- **Mutex-closure pattern** addresses concurrent read-modify-write correctness. It does not
  address goroutine spawning or channel lifetime. A function with correct mutex usage can still
  leak goroutines.

- **`sync.Once`** is for one-time initialization, not goroutine lifetime. Goroutines launched
  inside a `Once.Do` still need explicit lifetime management.

______________________________________________________________________

## Related Skills

- **composes-with** `context-cancellation-cause`: Context cancellation is the signal mechanism — `ctx.Done()` tells goroutines to stop. Structured lifetime management is the enforcement mechanism — errgroup/WaitGroup ensures goroutines have actually stopped before the parent returns. Both are needed: cancellation without waiting leaks; waiting without cancellation hangs.
- **contrasts-with** `mutex-closure-atomic-mutation`: Both address problems that arise from concurrent execution, but at different levels. Goroutine lifetime management controls when goroutines start and stop. The mutex closure pattern makes compound mutations inside a single operation atomic. A function can have correct lifetime management and still have logical mutex races; a function can use the closure pattern and still leak goroutines.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Go Advice" by Redowan Delowar (rednafi) — structured_concurrency, early_return_and_goroutine_leak, limit_goroutines_with_buffered_channels
