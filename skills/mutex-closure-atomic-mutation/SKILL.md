---
name: mutex-closure-atomic-mutation
description: |
  Apply when a user has a struct with separate Get() and Set() methods each protected by a mutex,
  or when they ask why concurrent mutations produce wrong values despite using locks, or when
  go test -race passes but their counter or shared state is incorrect.

  The core trap: individually-locked Get() and Set() methods are each safe in isolation, but the
  sequence Get → mutate → Set is not atomic. Between the Get and the Set, another goroutine can
  run and modify the same value. The first goroutine then overwrites that change. This is a logical
  race (lost-update bug), not a data race. The Go race detector is silent because each lock
  acquisition is individually valid — there is no unsynchronized memory access to detect.

  The fix is closure inversion: instead of Get()/Set(v), expose Set(func(*T)). The method acquires
  the lock once and holds it for the entire closure body. The read, check, and write all happen
  inside the same lock window, with no gap where another goroutine can interfere.
tags: [go, concurrency, mutex, safety, data-races]
---

# Mutex Closure Pattern for Atomic Read-Modify-Write

## R — Original Text (Reading)

> When multiple goroutines need to read and write the same value, you need a mutex to make sure
> they don't step on each other. [...] This works fine when you're replacing the value wholesale —
> just call `counter.Set(42)` and move on. But when your mutation depends on the current value,
> `Get` and `Set` can race against each other. Each individual call is safe — `Get` holds the lock
> while reading, `Set` holds it while writing. But the three calls together aren't atomic. Between
> `Get` and `Set`, another goroutine can modify the value, and your increment overwrites theirs.
> That's the classic lost-update bug.
>
> The race detector (`go test -race`) won't catch this. It detects data races — two goroutines
> accessing the same memory without synchronization. Here, every `Get` and `Set` properly acquires
> the mutex, so each individual access is synchronized. The bug is a logical race (lost update),
> not a data race. The race detector sees nothing wrong.
>
> Instead of taking a value, have `Set` take a function: `func (l *Locked[T]) Set(f func(*T))`.
> The lock is held for the entire closure. There's no gap between reading and writing, so no other
> goroutine can interfere.
>
> — rednafi, mutex_closure

______________________________________________________________________

## I — Methodological Framework (Interpretation)

## The Problem: Individually Safe Operations That Are Collectively Unsafe

A mutex wrapper with separate `Get()` and `Set(v T)` methods protects each operation in
isolation. But any compound mutation — increment, conditional update, multi-field struct change —
requires a sequence of calls. The window between the `Get` return and the `Set` call is
unprotected. Another goroutine can run in that window, read the same value, and write its own
update. When the first goroutine's `Set` executes, it overwrites the second goroutine's write.
Neither goroutine's lock was improperly held, yet state is lost.

## This Is a Logical Race, Not a Data Race — the Race Detector Cannot Catch It

`go test -race` instruments memory accesses. It detects when two goroutines access the same
memory location without one of them holding a lock. In the Get/Set pattern, every memory
access is properly locked. The race detector has nothing to flag. The corruption is semantic:
the caller's invariant ("if Get returned X, Set can safely compute from X") is violated
between two lock acquisitions that are each individually correct. You can pass `-race` with
a green result and still lose 80%+ of your updates.

## The Fix: Closure Inversion — the Struct Holds the Lock for Everything

Change `Set(v T)` to `Set(f func(*T))`. Inside, the method acquires the lock, calls `f(&l.v)`,
and releases the lock. The caller's entire read-check-write logic moves into `f`. Because `f`
executes under the lock, no other goroutine can see intermediate state. The read, the decision,
and the write are all atomic from the outside.

**Why a pointer parameter: `func(*T)` not `func(T)`**

The closure receives `*T`, not `T`. This allows in-place mutation without copying. For large
structs, it also avoids copying the whole value into the closure on every call.

## Real-World Validation — Two Independent Production Systems

`database/sql` uses an internal `withLock(lk sync.Locker, fn func())` helper at ~18 call sites
in `sql.go` to serialize driver connection access. Tailscale's `syncs.MutexValue[T]` provides
`WithLock(f func(*T))` alongside `Store`/`Load` for exactly this distinction: wholesale
replacement vs. compound mutation. Both systems arrived at the closure pattern independently.

______________________________________________________________________

## A1 — Past Application

### Case 1: Counter Struct — 10000 Expected, ~1855 Actual (C05 / Ce18)

- **Problem:** A `Locked[int]` wrapper with `Get() int` and `Set(v int)` was used to implement
  a concurrent counter. Ten goroutines each called `v := counter.Get(); v++; counter.Set(v)` 1000
  times. Expected final value: 10000.

- **Method:** Each `Get` and `Set` individually acquired `l.mu`. The three-call sequence was not
  atomic. Between the `Get` return and the `Set` call, other goroutines ran their own `Get`+`Set`
  cycles, reading the same value and overwriting each other's increments. `go test -race` reported
  no race conditions because every individual lock acquisition was properly paired.

- **Conclusion:** The race detector gave a false green. The bug is a logical race (lost-update),
  not a data race. It is structurally invisible to the race detector. The only way to observe it
  is with an expected-value assertion: final counter != 10000.

- **Result:** Changing to `Set(func(v *int) { *v++ })` fixed the issue. The lock was held for
  the entire increment. Final count: 10000. The fix required zero changes to the locking mechanism
  — only the API shape changed.

### Case 2: Rate Limiter — Check-Then-Increment Window (V2)

- **Problem:** A rate limiter with `GetCount()` and `IncrementCount()` as separate locked methods.
  A goroutine checked `if GetCount() < limit` then called `IncrementCount()`. Multiple goroutines
  passed the limit check simultaneously before any of them incremented.

- **Method:** Same structural issue — the limit check and the increment were in different lock
  windows. Both goroutines could read a count below the limit, both decide to proceed, both
  increment. The limit was effectively bypassed.

- **Result:** Fixed by `Update(func(*map[string]int))` which holds the lock for the entire
  check-and-increment block. The rate limiter now correctly enforces the limit.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Concrete Scenarios

1. A concurrent counter produces incorrect totals despite using a mutex-wrapped struct.
2. A rate limiter allows more requests than its configured limit under concurrent load.
3. A struct with multiple fields needs conditional updates (e.g., `if Count < 10 { Count++; Name = ... }`),
   and the caller is doing `s := state.Get(); s.Count++; state.Set(s)`.
4. A user asks "why does my mutex-protected counter give the wrong value?" and race detection
   passes cleanly.
5. A user asks "how do I make a read-modify-write atomic in Go without channels?"

### Language Signals

- "I'm using a mutex but still getting wrong values"
- "go test -race passes but my counter is wrong"
- "how do I make this read-modify-write atomic"
- "lost updates even with locks"
- "concurrent map/counter corruption but no race detected"
- "Get then Set — is this safe?"

### Distinguishing from Adjacent Skills

- **Difference from `structured-goroutine-lifetime`:** Structured goroutine lifetime manages
  when goroutines start and stop (WaitGroup, errgroup, context). This skill is about making
  a compound mutation atomic within a single goroutine's operation — the goroutine lifetime
  is not the issue.

- **Difference from `context-cancellation-cause`:** Context cancellation is about propagating
  why a context was cancelled. This skill is about preventing lost updates inside a shared
  mutable value — no context is involved.

- **Difference from `sync/atomic`:** `sync/atomic` provides atomic operations only for
  primitive integer and pointer types (`atomic.AddInt64`, `atomic.CompareAndSwapPointer`).
  The closure pattern handles arbitrary struct types, multi-field updates, and conditional
  mutations that cannot be expressed as a single atomic CPU instruction.

______________________________________________________________________

## E — Execution Steps

1. **Identify read-modify-write patterns**

   - Look for: any code that calls `Get()` (or reads a value) and then calls `Set()` (or writes
     a value) based on the result of that read, within the same logical operation.
   - Also look for: compound struct mutations where multiple fields are read and updated together.
   - Completion criteria: Named the compound operation (e.g., "increment counter", "update if
     under limit", "conditional multi-field set").

2. \**Replace separate Get+Set with Set(func(*T))**

   - Change the method signature from `Set(v T)` to `Set(fn func(*T))`.
   - Inside the method: acquire the lock, call `fn(&l.v)`, release the lock (use `defer`).
   - Keep a separate `Get()` for pure read-only access where no mutation follows.
   - Completion criteria: The method signature is `Set(fn func(*T))` or `Update(fn func(*State))`;
     inside, lock is acquired, fn is called with a pointer to the value, lock is released.

3. **Move all mutation logic into the closure body**

   - The caller's code that was `v := x.Get(); v++; x.Set(v)` becomes `x.Set(func(v *int) { *v++ })`.
   - Any conditional logic that previously read a value before deciding whether to write must
     move into the closure body.
   - Completion criteria: No caller calls `Get()` immediately before `Set()` for the same
     logical operation; all reads of the guarded value happen inside the closure body when a
     write will follow.

4. **Verify with go test -race AND with expected-value assertion**

   - Do not rely on `go test -race` alone — it will pass even with the bug.
   - Write a test with 10+ goroutines performing the compound operation concurrently (e.g.,
     10 goroutines × 1000 increments each).
   - Assert the final value matches the expected result (10000 in the counter case).
   - Completion criteria: Test with concurrent goroutines asserts the expected final value and
     passes consistently. `go test -race` also passes (it should pass before and after the fix).

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- **Single-goroutine code:** Mutex overhead is unnecessary if only one goroutine accesses the
  value. Use a plain field.
- **The operation is truly read-only:** If you only call `Get()` and never write based on the
  result, there is no race. A standalone `Get()` with its own lock is correct.
- **Simple integer counters in hot paths:** `sync/atomic.AddInt64` is simpler, faster, and
  sufficient for incrementing or decrementing a single integer. Use the closure pattern when
  you have struct types, multi-field mutations, or conditional logic.
- **Cross-struct coordination:** The closure pattern makes one struct's mutation atomic. If
  two separate structs must be updated atomically (e.g., decrement stock AND create order),
  you need a database transaction or a channel-based unit-of-work pattern. The closure
  cannot span multiple mutexes safely (would require lock ordering to avoid deadlock).

### Failure Patterns

- **Separate Get()/Set() methods with individual locks** — creates the logical race window
  even though the race detector is silent (ce18). The classic symptom: correct results under
  low concurrency, wrong results under high concurrency, no race warnings.
- **Exposing Lock()/Unlock() directly** — callers will forget to pair them, will panic if
  the lock is held and an error return skips `Unlock()`, or will double-unlock. The closure
  pattern makes it impossible to forget.
- **Returning a pointer from Get()** — if `Get()` returns `*T` instead of `T`, callers can
  mutate the value without holding the lock. Always return a copy from `Get()`.

### Author's Blind Spots

- The closure pattern protects one struct's invariants atomically. It does not help when two
  independent structs must be updated atomically — that requires database transactions, a
  single coordinating mutex that spans both, or a channel-based design.
- The closure allocates a function value on the heap on each call. For extremely hot paths
  (millions of calls per second), this allocation is measurable (~35% overhead vs. direct
  lock/unlock per rednafi's benchmarks: 14.65 ns/op vs. 10.82 ns/op). In practice, if the
  critical section does any real work, the overhead is negligible.

### Easily Confused With

- **sync.Mutex.Lock()/Unlock() manually:** Exposes locking discipline to callers. They must
  remember to call `Lock()` before and `Unlock()` after. The closure pattern internalizes this
  — callers cannot forget.
- **sync/atomic:** Works only for single integers or pointers (`int32`, `int64`, `unsafe.Pointer`).
  Cannot express "read Count, check it, conditionally increment Count and update Name atomically."
  For compound state, the closure pattern is the only correct option.
- **Tailscale's Store()/Load():** These are correct for wholesale replacement (assign a new value
  without reading the old one). Use `WithLock(func(*T))` when the new value depends on the old.

______________________________________________________________________

## Related Skills

- **contrasts-with** `structured-goroutine-lifetime`: Both address correctness problems in concurrent code, but at different levels. The mutex closure pattern makes a compound read-modify-write atomic within one operation — it prevents lost updates the race detector cannot see. Structured goroutine lifetime management controls when goroutines start, stop, and propagate errors — it prevents goroutine leaks and unbounded fan-out. A function can leak goroutines while having perfect mutex discipline; it can have correct lifetime management while losing counter updates. Choose based on whether the problem is in shared memory mutation or goroutine coordination.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Go Advice" by Redowan Delowar (rednafi) — mutex_closure
