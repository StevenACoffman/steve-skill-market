---
allowed-tools: Bash, Read, Edit
name: avoid-t-parallel-use-multiple-processes
description: |
  Invoke this skill when someone proposes adding t.Parallel() to speed up a
  Go test suite, or when a parallel test is failing intermittently and the
  root cause is unclear. The core rule: do not call t.Parallel(). When a
  parallel test fails you cannot determine whether the cause is a pure logic
  bug (reproducible with -parallel=1) or a race condition (requires the
  -race flag to surface) — the two root causes are mixed into one ambiguous
  signal. That ambiguity has a cost every time a test fails.

  Instead: use multiple go test processes for speed (go test ./... already
  runs package tests in parallel; add explicit CI jobs per package if needed),
  and write separate, purpose-built tests under go test -race for concurrent
  code. Each approach isolates exactly one failure source.

  Do NOT invoke for tests that already use t.Parallel() if the user is simply
  asking how t.Parallel() works — that is documentation, not application of
  this skill. Do NOT invoke when the user is debugging the mechanics of
  subtests (t.Run) or goroutine leaks — those are adjacent but different
  concerns.

  Key trigger signals: "add t.Parallel() to all tests", "parallel test is
  flaky", "is this a race condition or a logic bug?", "how do I speed up our
  test suite?", "tests pass locally but fail in CI", "I need to detect race
  conditions in my tests".
source_book: '"Advanced Testing with Go" by Mitchell Hashimoto'
source_chapter: Part 1 — Test Methodology / Parallelization
tags: [go, testing, parallelism, concurrency, race-conditions, test-methodology]
related_skills:
  - time-multiplier-over-fake-time  # contrasts-with: both address slow CI tests but different root causes
---

# Avoid t.Parallel() — Use Multiple Go Test Processes for Speed, Dedicated Race Tests for Concurrency

## Current State

t.Parallel() usage (anti-pattern per Hashimoto):
!`grep -rn 't\.Parallel()' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -10`

-race flag or race-specific test jobs:
!`grep -rn '\-race' Makefile lefthook.yml .github 2>/dev/null | head -5`

Per-package test targets in CI config:
!`find . -name 'Makefile' -o -name '*.yml' -path '*github*' 2>/dev/null | head -5`

## R — Original Text (Reading)

> **Don't do it. Run multiple processes instead.**
>
> ```go
> func TestThing(t *testing.T) {
> 	t.Parallel()
> }
> ```
>
> - Parallel tests make failures uncertain: is the failure due to a pure logic
>   bug, or a race condition?
> - Prefer running tests with both `-parallel=1` and `-parallel=N` if you need
>   to check both
> - We have preferred not to use parallelization. We use multiple processes and
>   unit tests specifically written to test for races.

— Mitchell Hashimoto, *Advanced Testing with Go*, Part 1 / Parallelization

## I — Methodological Framework (Interpretation)

When `t.Parallel()` is called, Go runs that test function concurrently with
other parallel tests within the same process. The intent is speed. The cost is
a loss of diagnostic clarity: when a parallel test fails, the failure has two
possible root causes and you cannot distinguish between them from the output
alone.

**Root cause 1: logic bug.** The test fails regardless of concurrency. You
could reproduce it with `-parallel=1` (one test at a time, sequential). This
is the common case and the easiest to fix.

**Root cause 2: race condition.** The test only fails when multiple tests run
concurrently, because two goroutines access shared state without
synchronization. This requires the `-race` flag to detect reliably.

When both root causes are present in the same test run — which is the
inevitable result of `t.Parallel()` — a failure could be either. To confirm
which one, you must re-run the suite with `-parallel=1` anyway. The speed gain
from parallelism is partially spent on extra diagnostic runs every time a test
fails.

HashiCorp's alternative separates the two concerns cleanly:

- **For speed**: `go test ./...` already runs tests for different packages in
  parallel (each package gets its own process). For finer control, configure
  CI to run package tests in parallel jobs — each job produces an isolated,
  unambiguous failure. No `t.Parallel()` calls required.

- **For race detection**: Write tests specifically for concurrent code and run
  them with `go test -race ./...` as a separate CI stage. A failure from this
  stage means exactly one thing: a data race. No ambiguity with logic bugs.

This separation means every failure has a single, known root cause. The
investigation starts at the right place immediately.

If you must use `t.Parallel()` in an existing codebase, run the suite twice in
separate CI steps: once with `-parallel=1` (to isolate logic bugs) and once
with `-parallel=N` and `-race` (to surface race conditions). Compare failures
between the two runs. This recovers diagnostic clarity at the cost of
additional CI compute — it is better than nothing, but still inferior to not
using `t.Parallel()` at all.

## A1 — Past Application (From the Book)

### Case 1: HashiCorp Institutional Policy Across All Projects (C10)

**Problem**: HashiCorp's engineering teams work across large Go codebases
(Vault, Terraform, Consul, Nomad) with many contributors. Any mechanism that
makes test failures ambiguous slows down everyone who touches those codebases.
A flaky parallel test wastes contributor time on every occurrence.

**Method**: Establish an explicit policy: `t.Parallel()` is never called. Race
conditions are caught via dedicated race tests with the `-race` flag. Speed is
achieved by running multiple `go test` processes (one per package) rather than
parallelizing within a single process.

**Conclusion**: The policy is a deliberate engineering tradeoff: accept
sequential tests within each package in exchange for unambiguous failures.

**Result**: All HashiCorp projects — Vault, Terraform, Consul, Nomad — follow
this policy. When a test fails, the root cause is always a logic bug in that
package. Race conditions are a separate signal from a separate CI stage.

______________________________________________________________________

### Case 2: the -Parallel=1 and -parallel=N Investigation Protocol (C10)

**Problem**: A developer inherits a codebase that uses `t.Parallel()` and a
test is failing intermittently. They need to determine whether to fix a logic
bug or hunt a data race.

**Method**: Run the suite twice: first with `-parallel=1` to suppress
concurrency effects, then with `-parallel=N` (and `-race`) to surface them.
Compare which failures appear in each run. A failure in the `-parallel=1` run
is a logic bug. A failure that only appears in the `-parallel=N` run is a
concurrency bug.

**Conclusion**: The two-run protocol recovers diagnostic clarity that
`t.Parallel()` had destroyed. It is the escape hatch when removing
`t.Parallel()` is not immediately feasible.

**Result**: Hashimoto recommends this explicitly as the investigation
methodology if you are already using parallelism and cannot remove it.

## A2 — Trigger Scenario (Future Trigger) ★

1. **"My test suite is slow. Should I add t.Parallel() to all tests?"**
   Do not add `t.Parallel()`. Measure whether the bottleneck is within a
   package or between packages. If between packages, `go test ./...` already
   parallelizes at the package level — you have the speed without the
   ambiguity. If within a package, add a parallel CI job for that package
   rather than parallelizing inside it.

2. **"A parallel test is failing intermittently in CI. Is it a race condition
   or a logic bug?"**
   The ambiguity is exactly Hashimoto's concern made concrete. Run the failing
   package with `-parallel=1 -count=10` to check for a reproducible logic bug.
   Run it with `-race -parallel=N -count=10` to check for a race. Whichever
   run reproduces the failure names its root cause.

3. **"How do I speed up our Go test suite without introducing race conditions?"**
   Use `go test ./...` (parallel by package) or add CI matrix jobs with one
   package per job. Write `go test -race ./...` as a dedicated second stage.
   The first stage finds logic bugs; the second finds races. Both stages
   produce unambiguous, actionable failures.

4. **"Tests pass locally but fail in CI, and I suspect concurrency."**
   Local runs are often sequential (fewer CPUs, fewer goroutines). CI has more
   parallelism. Run locally with `go test -race ./...` to surface the race
   without `t.Parallel()`. If the race only appears with `t.Parallel()`,
   remove `t.Parallel()` and write a dedicated race test instead.

### Language Signals

- "Should I use t.Parallel()?"
- "How do I speed up my test suite?"
- "This test fails sometimes but I can't reproduce it"
- "I can't tell if this is a race condition or a bug"
- "Tests pass with -count=1 but fail with -count=10"
- "Is this a flaky test or a real failure?"
- "How do I detect race conditions in tests?"

### Distinguishing from Adjacent Skills

- **time-multiplier-over-fake-time**: Addresses slow tests caused by timing
  timeouts, not parallelism. If tests are slow because they wait for goroutines
  or channels, that skill applies. If tests are slow because there are many of
  them, this skill applies.

- **`t.Run()` subtests**: Used to create named subtests inside a single test
  function. Can be combined with `t.Parallel()` for table-driven parallel
  subtests, but that combination still produces the ambiguity described here.
  Using `t.Run()` without `t.Parallel()` is unaffected by this skill.

- **Race detection tooling**: The `-race` flag is a Go toolchain feature for
  detecting data races at runtime. This skill recommends it for a dedicated CI
  stage. It does not replace `t.Parallel()` detection — it replaces the need
  to use `t.Parallel()` as a race trigger.

## E — Execution Steps

**Step 1: Remove or do not add `t.Parallel()` calls**

```go
// Before (avoid this)
func TestProcessOrder(t *testing.T) {
	t.Parallel()
	// test body
}

// After
func TestProcessOrder(t *testing.T) {
	// test body — no t.Parallel()
}
```

Completion criterion: no test function in the package calls `t.Parallel()`.
Verify with `grep -r 't\.Parallel()' ./...`.

**Step 2: Use `go test ./...` for package-level parallelism**

Go's test tool already runs tests for separate packages in parallel by
default. A single `go test ./...` command exercises all packages and the
failures from each package are isolated to that package's process.

```sh
# Runs all packages; each package is a separate process
go test ./...

# Verbose: shows per-package results as they complete
go test -v ./...

# Limit parallelism to N packages simultaneously (useful for CI resource control)
go test -p 4 ./...
```

Completion criterion: CI runs `go test ./...` (or equivalent per-package
matrix jobs) and each failing output names exactly one package.

**Step 3: Add a dedicated `-race` stage for concurrent code**

Write tests for functions that use goroutines, channels, or shared mutable
state. Run them under `-race` in a separate CI step.

```sh
# Separate CI stage — detects data races
go test -race ./...
```

A failure from this stage means exactly one thing: a data race was detected.
A failure from the logic stage (Step 2, no `-race`) means a deterministic bug.

Completion criterion: CI has at minimum two test stages: one without `-race`
(logic correctness) and one with `-race` (race detection). Failures from each
stage are investigated differently and never mixed.

## Step 4 (If Migrating an Existing Codebase): Use the Two-Run Protocol

If removing `t.Parallel()` is not immediately feasible, run two separate CI
jobs for the affected package:

```sh
# Job A: logic bugs only
go test -parallel=1 ./pkg/...

# Job B: race conditions
go test -race -parallel=8 ./pkg/...
```

Compare failures across jobs. A failure in Job A is a logic bug. A failure
that only appears in Job B is a race condition.

Completion criterion: each CI job's failures are investigated independently,
and developers know which root cause applies without re-running the suite.

## B — Boundary ★

### Reconciliation with Summary_rules.md

`summary_rules.md §10` takes a conditional position on `t.Parallel()`: it is appropriate and encouraged **when each test creates a fully isolated environment** — no shared global state, no shared database connection, no fixed port. The summary's position is that `t.Parallel()` is a useful tool when the isolation precondition is met.

This skill's position is more restrictive: Hashimoto recommends against `t.Parallel()` as an institutional policy across all test types, including pure unit tests. The reasoning is diagnostic: even for isolated tests, a failure mixed with other parallel tests requires a mental disambiguation step to confirm there is no shared state involved.

**How to reconcile:** The HashiCorp policy is a deliberate institutional tradeoff, not a universal Go truth. It is most defensible for large codebases with many contributors where diagnostic clarity on every failure matters operationally. For smaller teams or codebases, the summary's conditional endorsement is reasonable: use `t.Parallel()` freely when each test constructs a fully isolated environment (its own `FakeDB`, its own in-memory store, no global variables). Reserve the HashiCorp policy for integration and system tests where shared infrastructure (containers, ports, databases) makes isolation genuinely hard to guarantee. The two-stage CI approach (no-race logic stage + dedicated `-race` stage) adds value regardless of whether `t.Parallel()` is used.

## When the Concern Is Less Acute

- **Pure unit tests with no shared state**: If tests create all their
  dependencies locally (no global variables, no shared database, no fixed
  port), `t.Parallel()` is safer — the concurrency effect is limited to CPU
  scheduling, not shared state mutation. Hashimoto's concern is most acute for
  integration and system tests where shared state (database connections,
  filesystem paths, network ports) exists. For truly pure unit tests, the
  ambiguity argument is weaker, though the advice still holds as a consistent
  policy.

- **`t.Run()` subtests with `t.Parallel()` (Go 1.7+)**: A common pattern in
  modern Go is table-driven tests where each subtest calls `t.Parallel()` and
  captures the loop variable. Each subtest is named, so failure output
  identifies which case failed. The naming reduces — but does not eliminate —
  the ambiguity: a named subtest failure still requires determining whether it
  is a logic bug or a race. The author's talk predates `t.Run()` and does not
  address this combination. For new code, the two-stage CI approach (Step 3)
  remains the cleaner solution.

- **`-race` always in CI base run**: If `-race` is included in every CI run
  (not just a dedicated stage), the ambiguity concern is reduced: a race is
  flagged immediately by the runtime, not inferred from intermittent failures.
  Some teams run `go test -race ./...` as their only test command. In this
  case, the "ambiguity" Hashimoto describes is addressed by the detector itself.
  The author's era predates the common practice of always-on `-race` in CI.

## Failure Patterns

- **Calling `t.Parallel()` without also running `-race`**: You get the speed
  benefit but no race detection. Races manifest as mysterious intermittent
  failures. This is the worst combination: ambiguous failures and no tooling
  to resolve them.

- **Using `t.Parallel()` in tests that access package-level variables**: Even
  read-only access can cause races if the variable is a pointer to a struct
  that is mutated elsewhere. Package-level variables are the primary source of
  ambiguous parallel failures.

- **Running `-race` only on the parallel test stage**: If `-race` is omitted
  from the sequential stage, races in single-goroutine code that happens to
  also be called from a goroutine are missed.

## Author Blind Spots

- **`t.Run()` + `t.Parallel()` table-driven pattern**: Introduced in Go 1.7,
  this combination is idiomatic in modern Go. Each subtest is a goroutine,
  named after the test case, and independently reported. The failure ambiguity
  is reduced because the race detector usually points directly to the data
  race line rather than producing a vague failure. The author's blanket
  avoidance is reasonable as a policy but overstated as a universal rule for
  this specific pattern.

- **Always-on `-race` in CI**: The race detector has improved significantly
  since this talk. Running `go test -race ./...` on every CI push is now
  standard practice in many Go projects and directly addresses the ambiguity
  Hashimoto describes. The separate "dedicated race tests" recommendation is
  still valid but less urgent when `-race` is always present.

- **Confusion with time-multiplier-over-fake-time**: Both skills address slow
  or flaky tests. The parallelism skill addresses ambiguous failures from
  concurrency; the time-multiplier skill addresses timeout failures in slow
  environments. They are independent — a test can suffer from both problems
  simultaneously.

## Related Skills

- **time-multiplier-over-fake-time** (contrasts-with): Both address slow or flaky tests in CI, but diagnose different root causes. `t.Parallel()` failure ambiguity is about concurrent execution mixing two signal types (logic bug vs. race condition). `timeMultiplier` is about individual async waits taking too long on slow machines. They are orthogonal — a test can need both solutions simultaneously.

## Audit Information

- Source extraction date: 2026-05-04
- Primary source: `/Users/steve/Documents/agent-orange/books/hashimoto/Advanced_testing_with_go.md`, Part 1 / Parallelization
- Verified entry: `/Users/steve/Documents/agent-orange/books/hashimoto/verified.md`, id: avoid-t-parallel-use-multiple-processes
- Cases used: c10 from `/Users/steve/Documents/agent-orange/books/hashimoto/candidates/cases.md`
- Counter-example used: ce04 from `/Users/steve/Documents/agent-orange/books/hashimoto/candidates/counter-examples.md`
- Pipeline stage: Phase 2 (RIA++)
- Version: 0.1.0
