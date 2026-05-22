---
allowed-tools: Bash, Read, Edit
name: time-multiplier-over-fake-time
description: |
  Apply when a test waits on a goroutine, channel, or event; the test passes locally
  but times out in CI; or a colleague suggests injecting a Clock interface. Use a
  real timeout via `select` + `time.After` with a package-level `var timeMultiplier`
  — set it larger in CI via TestMain or an env var, with no production code changes.
  Do not apply when the test must assert on ordering of time events (cache TTL vs
  retry); real time is too non-deterministic for that, and a clock mock is warranted.
source_book: "Advanced Testing with Go" by Mitchell Hashimoto
source_chapter: Part 1 — Test Methodology / Timing-Dependent Tests
tags: [go, testing, timing, async, concurrency, test-methodology]
related_skills:
  - avoid-t-parallel-use-multiple-processes  # contrasts-with: both address flaky/slow tests but different root causes
---

# Time Multiplier Over Fake Time

## R — Reference (What the Book Actually Says)

## Current State

Fake clock injection (interfaces spreading through production code):
!`grep -rn 'Clock\|FakeClock\|MockClock\|fakeClock\|clock\.Now' --include='*.go' . 2>/dev/null | grep -v vendor | head -8`

time.Sleep in tests (potential flakiness source):
!`grep -rn 'time\.Sleep' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -8`

timeMultiplier pattern already in use:
!`grep -rn 'timeMultiplier\|TimeMultiplier\|time\.Duration(1)' --include='*.go' . 2>/dev/null | grep -v vendor | head -5`

select + time.After timeout patterns in tests:
!`grep -rn 'time\.After\|time\.NewTimer' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -5`

From the **Timing-Dependent Tests** section of *Advanced Testing with Go*:

> For tests that wait on asynchronous behavior, use a `select` with a timeout:

```go
func TestThing(t *testing.T) {
	// …
	select {
	case <-thingHappened:
	case <-time.After(timeout):
		t.Fatal("timeout")
	}
}
```

> We do not use "fake time." Instead we have a multiplier available that can be
> set to increase timeouts in slow environments:

```go
func TestThing(t *testing.T) {
	// …
	timeout := 3 * time.Minute * timeMultiplier
	select {
	case <-thingHappened:
	case <-time.After(timeout):
		t.Fatal("timeout")
	}
}
```

> This is not perfect, but it is less intrusive than fake time. Fake time could
> be better, but we have not found an effective way to use it yet.

The `timeMultiplier` is a package-level variable declared as:

```go
var timeMultiplier = time.Duration(1)
```

Its default value of `1` means all timeouts are unchanged in local development.
In CI, an environment variable (e.g., `TEST_TIMEOUT_MULTIPLIER=5`) is read in
`TestMain` or a package-level `init()` and assigned to `timeMultiplier`.

______________________________________________________________________

## I — Interpretation (What It Means and Why)

When a test has to wait for a goroutine to complete, a channel to receive a
value, or a distributed event to propagate, there are two approaches: fake the
passage of time, or wait with a real timeout and make that timeout tunable.

**Why fake time fails in practice.** Clock injection requires defining a `Clock`
or `Timer` interface, injecting it into every constructor that touches time, and
wiring it through every call site. This is invasive: production code is
restructured to satisfy a test concern. Fake time also requires deliberate
`Advance()` calls interleaved with goroutine waits — correctly ordering those
calls is subtle, and bugs in the coordination create flaky tests that look like
real timing failures. Hashimoto's team tried this and describes the result as
"not effective."

**Why real time + a multiplier works.** The `select` + `time.After` pattern
tests the actual production behavior: real goroutine scheduling, real channel
sends, real event propagation. This is especially important for distributed
system tests (Consul cluster events, Raft leader election, job scheduling) where
the correctness question is "does the event happen?" not "does the event happen
at a specific simulated time?" The multiplier provides the only tuning knob
actually needed by CI: "wait longer on slow machines." That knob is a single
package variable — no interface definition, no constructor parameter, no
`Advance()` choreography.

**The key insight.** Developers reach for fake time because they conflate two
separate problems:

1. *My test is flaky because it times out on slow CI machines.* — Solved by
   `timeMultiplier`.
2. *My test must assert that event A occurs before event B at specific times.* —
   Requires deterministic time control; clock injection is the right tool.

Most async test failures are problem 1, not problem 2. `timeMultiplier` gives
80% of the benefit of fake time with nearly none of the production-code cost.

______________________________________________________________________

## A1 — Application (Cases from the Book)

## Case 1 — Consul / Distributed System Tests (Real Cluster Events)

Consul tests launch real goroutines for leader election, health checks, and RPC
calls. A test verifies that a cluster event (e.g., a node becoming leader)
eventually propagates. The test cannot use fake time because the event depends on
actual goroutine scheduling and network I/O — simulated time would not drive the
real event loop. The `select` + `time.After(timeout * timeMultiplier)` pattern
allows the test to wait an appropriate duration and fail clearly if the event
never arrives, without requiring any changes to Consul's production code paths.

## Case 2 — General Async Test Design as a HashiCorp Convention

Across Vault, Nomad, Terraform, and Consul, `var timeMultiplier = time.Duration(1)`
is a standard package-level declaration in any package containing timing-dependent
tests. CI pipelines set `TEST_TIMEOUT_MULTIPLIER` (or equivalent) to `3`–`5` for
resource-constrained runners. Local development uses the default multiplier of `1`,
so tests run at full speed. The pattern is never project-specific; it is the
house standard for any test that issues a `select` with a timeout channel.

______________________________________________________________________

## A2 — Activation (When to Apply This Skill)

Apply this skill when you encounter any of the following:

- **"My async test times out in CI but passes locally."** The first move is not to
  mock the clock — it is to add a `timeMultiplier` and let CI set it higher.

- **"Should I inject a Clock interface to make this test deterministic?"** Ask
  whether deterministic *ordering* of time events is required for correctness.
  If the test only needs to confirm that an event *eventually* happens, a
  multiplier is sufficient and far less invasive.

- **"How do I test code that waits on a goroutine/channel?"** The canonical
  answer is `select { case <-expected: case <-time.After(timeout): t.Fatal() }`,
  with `timeout` derived from a multiplied constant.

- **Test flakiness caused by timing differences across hardware.** Before
  reaching for clock mocking, try increasing `timeMultiplier` in CI. If
  flakiness disappears, the problem was slow machines, not non-determinism.

- **Code review: production struct has a `Clock` field with a default
  `time.Now` wrapper.** Ask whether any test actually requires `Advance()`.
  If tests only check eventual outcomes, the `Clock` field is likely unnecessary
  complexity.

______________________________________________________________________

## E — Execution (Step-by-Step)

## Step 1 — Declare the Multiplier at Package Level

```go
// In any _test.go file (or a testutil file) within the package:
var timeMultiplier = time.Duration(1)
```

Use `time.Duration(1)` (not `1`). Multiplying a `time.Duration` by a
`time.Duration` produces nanoseconds-squared, which is wrong.
`time.Duration(1)` is the identity: `3*time.Minute * time.Duration(1) == 3*time.Minute`.

## Step 2 — Write the Timeout Using the Multiplier

```go
timeout := 3 * time.Minute * timeMultiplier
```

## Step 3 — Write the Select

```go
select {
case <-thingHappened:
	// success — event arrived within timeout
case <-time.After(timeout):
	t.Fatal("timeout waiting for thingHappened")
}
```

## Step 4 — Read an Env Var in TestMain (Or Init) and Set the Multiplier

```go
func TestMain(m *testing.M) {
	if v := os.Getenv("TEST_TIMEOUT_MULTIPLIER"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			fmt.Fprintf(os.Stderr, "invalid TEST_TIMEOUT_MULTIPLIER: %v\n", err)
			os.Exit(1)
		}
		timeMultiplier = time.Duration(n)
	}
	os.Exit(m.Run())
}
```

## Step 5 — Set the Env Var in CI

```yaml
# GitHub Actions example
env:
  TEST_TIMEOUT_MULTIPLIER: '5'
```

Or in a Makefile:

```makefile
test-ci:
    TEST_TIMEOUT_MULTIPLIER=5 go test ./...
```

## Step 6 — Verify Locally with the Default

```text
go test ./...
```

Local runs use `timeMultiplier = 1` (unchanged timeouts). CI runs use `5`
(5× timeouts). No production code was modified.

______________________________________________________________________

## B — Boundaries (Where This Skill Does Not Apply)

**When correctness requires deterministic time ordering.**
If the test must assert that a cache entry expires *before* a retry fires, or
that a deadline elapses *before* a fallback is triggered, real time is too
non-deterministic. The event ordering is the thing being tested, and real
goroutine scheduling cannot guarantee it. A proper clock mock with `Advance()`
is the right tool for that specific scenario.

**Author blind spot: established Go time-mocking libraries.**
Hashimoto's "not effective" verdict on fake time was formed in a specific context
(distributed systems tests, pre-2015). Widely-used libraries such as
[quartz](https://github.com/coder/quartz),
[clockwork](https://github.com/jonboulle/clockwork), and
[jonboulle/clock](https://github.com/jonboulle/clockwork) have matured
considerably and provide more principled alternatives. For code where time
control is genuinely needed (scheduler testing, TTL logic, retry backoff
verification), these libraries may be worth the injection cost.

**Author blind spot: `context.WithTimeout` propagation.**
An alternative to `select` + `time.After` for tests that call into
cancellable code is to pass a `context.WithTimeout` from the test itself:

```go
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute*timeMultiplier)
defer cancel()
result, err := doAsyncThing(ctx)
```

This does not require a separate `select` and integrates naturally when
production code already accepts a `context.Context`.

**Confusion with `t.Parallel()` for speed.**
`timeMultiplier` addresses *timeout duration* for async waits — it does not
make tests run faster. `t.Parallel()` is about concurrent test execution.
These are orthogonal concerns; combining them to "fix slow CI tests" conflates
two different problems.

**Confusion with `t.Cleanup()` and teardown.**
`timeMultiplier` has nothing to do with resource cleanup. If a test registers
cleanup via `t.Cleanup()` or a returned `func()`, that cleanup runs regardless
of whether the async wait succeeded or timed out — `t.Fatal` still runs
`t.Cleanup` callbacks.

## Related Skills

- **avoid-t-parallel-use-multiple-processes** (contrasts-with): Both address slow or flaky tests in CI, but for different root causes. `timeMultiplier` fixes timeout failures on slow machines (the async event *does* happen, just slowly). The parallel skill fixes ambiguous failures from concurrent execution. They are orthogonal — a test can suffer from both problems simultaneously, and each requires its own solution.
