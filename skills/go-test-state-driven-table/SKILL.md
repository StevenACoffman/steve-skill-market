---
name: go-test-state-driven-table
allowed-tools: Bash, Read, Edit
id: go-test-state-driven-table
description: Use when writing a Go test for a function that has stateful external dependencies AND multiple input scenarios. Combines a map[string]struct{} table (so every failure names the scenario) with a handwritten fake collaborator (so every assertion checks observable state, not call sequences). The composition makes failures simultaneously identifiable by name and behaviorally meaningful by state — neither source describes this pattern; it emerges from applying both.
type: merged-skill
source_skills:
  - slug: rednafi/test-state-not-interactions
    book: Go Advice
    author: Redowan Delowar (rednafi)
  - slug: hashimoto/table-driven-named-cases
    book: Advanced Testing with Go
    author: Mitchell Hashimoto
related_skills:
  - slug: rednafi/test-state-not-interactions
    relation: supersedes
    note: Merged skill adds table-driven structure; use this for functions with multiple input cases
  - slug: hashimoto/table-driven-named-cases
    relation: supersedes
    note: Merged skill adds handwritten fake pattern; use this for functions with stateful dependencies
tags: [go, testing, quality, mocking, fakes, table-driven]
---

# Go State-Driven Table Test — Map-Keyed Cases with Handwritten Fakes

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Mock library usage in tests:
!`grep -rln 'gomock\|testify/mock\|mock\.' --include='*_test.go' . 2>/dev/null | head -5`

Slice-indexed test tables (anti-pattern):
!`grep -rn 'cases := \[\]struct' --include='*_test.go' . 2>/dev/null | head -5`

Map-keyed test tables (desired pattern):
!`grep -rn 'cases := map\[string\]struct' --include='*_test.go' . 2>/dev/null | head -5`

### R — Original Text (Reading)

**rednafi — state over interaction testing:**

> The general theme when writing unit tests should be checking the behavior of the system, not the scaffolding of its implementation. It doesn't matter which method called which, how many times, or with what arguments. What matters is: if you give the SUT some input, does it return the expected output? In a stateful system, does the input cause the system to mutate some persistence layer in the expected way?
>
> If an error is accidentally swallowed, callers get the wrong signal but the test still passes... A real DB or an in-memory fake would raise a constraint error that should propagate. The mock test goes green anyway because it only checked the call path. The common thread is that mocks lock tests to implementation details. They don't protect the behavior that real users rely on.
>
> — rednafi, *Go Advice*, test_state_not_interactions

**Hashimoto — map-keyed table-driven tests:**

> Consider naming cases. Using array indices for names produces failure messages like "test index 3014 failed," which is useless. A map or a named field makes failures immediately identifiable:
>
> ```go
> func TestAdd(t *testing.T) {
> 	cases := map[string]struct{ A, B, Expected int }{
> 		"foo": {1, 1, 2},
> 		"bar": {1, -1, 0},
> 	}
> 	for k, tc := range cases {
> 		actual := tc.A + tc.B
> 		if actual != tc.Expected {
> 			t.Errorf(
> 				"%s: %d + %d = %d, expected %d",
> 				k, tc.A, tc.B, actual, tc.Expected)
> 		}
> 	}
> }
> ```
>
> Follow this pattern a lot; use it even for single cases if the function could plausibly need more cases in the future.
>
> — Mitchell Hashimoto, *Advanced Testing with Go*, Part 1 / Table-Driven Tests

**Convergence note:** Both authors prescribe a concrete structural fix — fake over mock (rednafi); map over slice (Hashimoto) — that makes test failure output self-describing without requiring the reader to trace implementation code. rednafi arrived at this from a correctness argument (mocks hide real bugs by only recording call paths); Hashimoto arrived at it from a diagnostic efficiency argument (slice indices require counting to locate the failing case). The two prescriptions are orthogonal and compose directly: the map key names the behavioral scenario, the fake's state assertion proves the scenario produced the right outcome.

______________________________________________________________________

### I — Methodological Framework (Interpretation)

A test for a function with external dependencies and multiple input cases faces two independent failure-mode axes.

**Axis 1 — What you assert (rednafi).** Interaction testing asserts that specific methods were called a specific number of times with specific arguments: `mock.AssertExpectations(t)`. State testing asserts on the observable outcome after the operation: `reflect.DeepEqual(db.ListUsers(), []string{"alice"})` or `errors.Is(err, ErrDuplicate)`. Interaction testing locks tests to implementation structure — rename `InsertUser` to `UpsertUser` and every interaction assertion must be rewired, even though public behavior is identical. More critically, interaction testing stays green through real bugs: if `CreateUser` silently swallows the error from `InsertUser`, the mock records that `InsertUser` was called and `AssertExpectations` passes. The bug ships. A state-holding fake catches the bug because the state after the swallowed error is wrong — `db.ListUsers()` returns the empty list it had before, not the list with the new user.

**Axis 2 — How you organize cases (Hashimoto).** A `[]struct{...}` table keyed by slice index produces failure messages like "test index 3014 failed" — the developer must open the file and count rows. A `map[string]struct{...}` table keyed by a descriptive string produces failure messages like "duplicate returns ErrDuplicate: got nil, want ErrDuplicate" — the failing scenario is immediately named. The map enforces uniqueness of case names (two entries with the same key compile as one, rather than silently creating two cases with the same description). The overhead is three extra lines of syntax; the benefit accrues at every future debugging session.

**The composition.** These two axes are independent: you can have a map-keyed table that uses generated mocks (named cases, wrong assertion type) or a single-case fake test (right assertion type, not organized for multiple cases). Neither source describes the combination. The merged pattern applies both simultaneously: each row of a `map[string]struct{}` table exercises a different input against a `FakeDB`, and each assertion checks the observable state of the fake after the operation, not which methods were called. The map key names the behavioral scenario; the state assertion proves the scenario produced the right outcome.

**The correctness stake.** rednafi's principle has a correctness stake: fakes catch bugs that mocks miss. Hashimoto's principle has only a diagnostic efficiency stake: named cases are faster to debug. The merged pattern is therefore stronger than either source alone — it is both correct (catches swallowed errors) and efficient to debug (names the failing scenario). When a test fails, the failure message tells you which scenario failed (by map key) and what the system state was (by state assertion) — everything needed to diagnose the bug without reading implementation code.

**When to apply.** Apply the full merged pattern — map-keyed table + handwritten fake + state assertions — when a function: (1) has at least one external stateful dependency, and (2) has multiple distinguishable input scenarios or error conditions. If the function has dependencies but only one meaningful scenario, write a single named case (still use the map — it costs nothing and the function will likely accumulate cases). If the function is a pure function with no dependencies, there is no fake to write; use a map-keyed table with direct value assertions.

______________________________________________________________________

### A1 — Past Application

## R — Original Text (Reading)

**rednafi — state over interaction testing:**

> The general theme when writing unit tests should be checking the behavior of the system, not the scaffolding of its implementation. It doesn't matter which method called which, how many times, or with what arguments. What matters is: if you give the SUT some input, does it return the expected output? In a stateful system, does the input cause the system to mutate some persistence layer in the expected way?
>
> If an error is accidentally swallowed, callers get the wrong signal but the test still passes... A real DB or an in-memory fake would raise a constraint error that should propagate. The mock test goes green anyway because it only checked the call path. The common thread is that mocks lock tests to implementation details. They don't protect the behavior that real users rely on.
>
> — rednafi, *Go Advice*, test_state_not_interactions

**Hashimoto — map-keyed table-driven tests:**

> Consider naming cases. Using array indices for names produces failure messages like "test index 3014 failed," which is useless. A map or a named field makes failures immediately identifiable:
>
> ```go
> func TestAdd(t *testing.T) {
> 	cases := map[string]struct{ A, B, Expected int }{
> 		"foo": {1, 1, 2},
> 		"bar": {1, -1, 0},
> 	}
> 	for k, tc := range cases {
> 		actual := tc.A + tc.B
> 		if actual != tc.Expected {
> 			t.Errorf(
> 				"%s: %d + %d = %d, expected %d",
> 				k, tc.A, tc.B, actual, tc.Expected)
> 		}
> 	}
> }
> ```
>
> Follow this pattern a lot; use it even for single cases if the function could plausibly need more cases in the future.
>
> — Mitchell Hashimoto, *Advanced Testing with Go*, Part 1 / Table-Driven Tests

**Convergence note:** Both authors prescribe a concrete structural fix — fake over mock (rednafi); map over slice (Hashimoto) — that makes test failure output self-describing without requiring the reader to trace implementation code. rednafi arrived at this from a correctness argument (mocks hide real bugs by only recording call paths); Hashimoto arrived at it from a diagnostic efficiency argument (slice indices require counting to locate the failing case). The two prescriptions are orthogonal and compose directly: the map key names the behavioral scenario, the fake's state assertion proves the scenario produced the right outcome.

______________________________________________________________________

## I — Methodological Framework (Interpretation)

A test for a function with external dependencies and multiple input cases faces two independent failure-mode axes.

**Axis 1 — What you assert (rednafi).** Interaction testing asserts that specific methods were called a specific number of times with specific arguments: `mock.AssertExpectations(t)`. State testing asserts on the observable outcome after the operation: `reflect.DeepEqual(db.ListUsers(), []string{"alice"})` or `errors.Is(err, ErrDuplicate)`. Interaction testing locks tests to implementation structure — rename `InsertUser` to `UpsertUser` and every interaction assertion must be rewired, even though public behavior is identical. More critically, interaction testing stays green through real bugs: if `CreateUser` silently swallows the error from `InsertUser`, the mock records that `InsertUser` was called and `AssertExpectations` passes. The bug ships. A state-holding fake catches the bug because the state after the swallowed error is wrong — `db.ListUsers()` returns the empty list it had before, not the list with the new user.

**Axis 2 — How you organize cases (Hashimoto).** A `[]struct{...}` table keyed by slice index produces failure messages like "test index 3014 failed" — the developer must open the file and count rows. A `map[string]struct{...}` table keyed by a descriptive string produces failure messages like "duplicate returns ErrDuplicate: got nil, want ErrDuplicate" — the failing scenario is immediately named. The map enforces uniqueness of case names (two entries with the same key compile as one, rather than silently creating two cases with the same description). The overhead is three extra lines of syntax; the benefit accrues at every future debugging session.

**The composition.** These two axes are independent: you can have a map-keyed table that uses generated mocks (named cases, wrong assertion type) or a single-case fake test (right assertion type, not organized for multiple cases). Neither source describes the combination. The merged pattern applies both simultaneously: each row of a `map[string]struct{}` table exercises a different input against a `FakeDB`, and each assertion checks the observable state of the fake after the operation, not which methods were called. The map key names the behavioral scenario; the state assertion proves the scenario produced the right outcome.

**The correctness stake.** rednafi's principle has a correctness stake: fakes catch bugs that mocks miss. Hashimoto's principle has only a diagnostic efficiency stake: named cases are faster to debug. The merged pattern is therefore stronger than either source alone — it is both correct (catches swallowed errors) and efficient to debug (names the failing scenario). When a test fails, the failure message tells you which scenario failed (by map key) and what the system state was (by state assertion) — everything needed to diagnose the bug without reading implementation code.

**When to apply.** Apply the full merged pattern — map-keyed table + handwritten fake + state assertions — when a function: (1) has at least one external stateful dependency, and (2) has multiple distinguishable input scenarios or error conditions. If the function has dependencies but only one meaningful scenario, write a single named case (still use the map — it costs nothing and the function will likely accumulate cases). If the function is a pure function with no dependencies, there is no fake to write; use a map-keyed table with direct value assertions.

______________________________________________________________________

## A1 — Past Application

### Case 1: CreateUser — Mock Passes, Fake Catches Swallowed Error (Rednafi)

**Problem:** `CreateUser` is refactored to ignore its own error: `_ = s.db.InsertUser(name); return nil`. Every caller now silently receives success even when the database rejects the insert (duplicate, constraint violation, connection error).

**Methodology:** Mock-based test asserts `db.EXPECT().InsertUser("alice").Return(nil).Once()` then calls `db.AssertExpectations(t)`. The call happened; the mock passes. Handwritten `FakeDB` test calls `svc.CreateUser("alice")` twice. The second call should return `ErrDuplicate`. Because `CreateUser` swallows the error, the fake's `seen` map still does not contain a duplicate entry being properly rejected — and the assertion `assert(t, errors.Is(err, ErrDuplicate), ...)` fails, catching the bug.

**Conclusion:** The mock validated the call path; the fake validated the outcome. Only the fake caught the regression. The fake's `seen map[string]struct{}` enforces the same duplicate-detection rule that a real database enforces via a unique constraint — and the state assertion on `db.ListUsers()` after the operation proves what changed in the world.

**Result:** Handwritten `FakeDB` catches the bug on first run. The assertion `reflect.DeepEqual(db.ListUsers(), []string{"alice"})` — the state of the store after the operation — is the signal, not `mock.AssertExpectations`.

______________________________________________________________________

### Case 2: Terraform — "Test Index 3014 Failed" and the Map-Keyed Fix (Hashimoto)

**Problem:** During Terraform development, test tables grew to hundreds of rows indexed by slice position. A CI failure appeared at "test index 3014 failed." The developer had to open the test file, count to row 3014, and reconstruct what that case was testing — all before beginning to diagnose the actual bug.

**Methodology:** After experiencing this pattern repeatedly, the Terraform team switched all test tables from `[]struct{...}` to `map[string]struct{}`. Descriptive string keys were added retroactively to all existing tables. Failure messages now read "snapshot-with-empty-node: got X, want Y" — the failing scenario is immediately named.

**Conclusion:** "That was a mistake we made early on." The pain of index 3014 is the origin of HashiCorp's map-keyed convention, adopted across Terraform, Consul, Vault, and Nomad.

**Result:** The convention is now applied from the start on all new HashiCorp projects. The cost of the Terraform migration was absorbed once; the benefit — self-describing failure messages — accrues at every subsequent debugging session.

______________________________________________________________________

## A2 — Trigger Scenario ★

Instead of asking "should I use mocks?" (rednafi alone) or "which case in my table failed?" (Hashimoto alone), use this merged skill when:

**Trigger 1 — Writing a new test for a function with stateful dependencies and multiple scenarios:** You have a `UserService.CreateUser` (or equivalent) that calls a database, cache, queue, or other stateful collaborator. You need to cover at least two scenarios: happy path and at least one error or edge case. Apply the full pattern from the start.

**Trigger 2 — Test suite uses generated mocks (mockery, gomock) and tests are breaking on harmless refactors:** The tests are asserting on call paths, not outcomes. The signal: renaming a method breaks tests even when public behavior is unchanged. Migrate to handwritten fakes and state assertions; add map-keyed table structure at the same time.

**Trigger 3 — Tests pass but a known bug is in production:** A test suite that uses interaction testing (mock.AssertExpectations) may be green while a swallowed error or wrong state mutation is shipping. Rewrite with state assertions to surface the bug.

**Trigger 4 — CI failure message says "test index N failed":** The existing test uses a `[]struct{}` table. Refactor to `map[string]struct{}` with descriptive keys. The next failure will name itself.

**Trigger 5 — LLM generated a test suite using mocks:** LLMs default to mockery/gomock because those are overrepresented in training data. The generated tests verify interaction, not state. They are fragile by construction. Replace with the map-keyed table + handwritten fake pattern.

**Do NOT use when:**

- The function is a pure function with no external dependencies (no fake needed; use a map-keyed table with direct value assertions — drop the fake portion).
- The external dependency is too complex for a handwritten fake (SQL transaction semantics, large binary protocols, network timing) — use testcontainers against a real service instead.
- The test is a sequential integration test that boots a server, sends multiple requests, and verifies system state — those are not independent parallel cases and do not fit the table pattern.
- Testing a gRPC server where generated protocol types and interceptors make handwritten fakes painful — one case where generated mocks are genuinely ergonomic.

______________________________________________________________________

## E — Execution Steps

## Step 1: Identify What the System Is Supposed to Produce (State)

Ask: "What changes in the world after this function runs?"

- For a write operation: what is now in the store? What error surfaces to the caller?
- For a read operation: what value is returned?

Write the assertion before writing the fake:

- `if got, want := db.ListUsers(), []string{"alice"}; !reflect.DeepEqual(got, want) { t.Errorf(...) }`
- `assert(t, errors.Is(err, ErrDuplicate), fmt.Sprintf("expected ErrDuplicate, got %v", err))`

## Step 2: Define a Minimal Interface for the Dependency

Define the interface in the consumer package (Go's implicit satisfaction). Include only the methods the code under test actually calls.

```go
type DB interface {
	InsertUser(name string) error
	ListUsers() []string
}
```

## Step 3: Build a Handwritten Fake for the Dependency

The fake holds in-memory state and encodes exactly the domain invariants needed for the tests.

```go
type FakeDB struct {
	seen  map[string]struct{}
	order []string
}

func NewFakeDB() *FakeDB {
	return &FakeDB{seen: make(map[string]struct{})}
}

func (f *FakeDB) InsertUser(name string) error {
	if _, ok := f.seen[name]; ok {
		return usersvc.ErrDuplicate // domain sentinel, not a string
	}
	f.seen[name] = struct{}{}
	f.order = append(f.order, name)
	return nil
}

func (f *FakeDB) ListUsers() []string {
	out := make([]string, len(f.order))
	copy(out, f.order)
	return out
}
```

**Step 4: Declare the test table as `map[string]struct{}`**

Each key is a short English phrase describing the behavioral scenario. Each value holds the inputs, optional setup function, and expected outcomes.

```go
cases := map[string]struct {
	name        string
	setupFake   func(*FakeDB)
	expectErr   error
	expectUsers []string
}{
	"first insert succeeds": {
		name:        "alice",
		expectUsers: []string{"alice"},
	},
	"duplicate returns ErrDuplicate": {
		name:        "alice",
		setupFake:   func(db *FakeDB) { db.InsertUser("alice") },
		expectErr:   ErrDuplicate,
		expectUsers: []string{"alice"},
	},
	"empty name returns ErrInvalid": {
		name:        "",
		expectErr:   ErrInvalid,
		expectUsers: []string{},
	},
}
```

Completion criterion: each key is a short English phrase describing the scenario. No key is "case1", "test_a", or a copy of the input value.

## Step 5: Write the Test Loop with State Assertions

```go
func assert(t *testing.T, cond bool, msg string) {
	t.Helper()
	if !cond {
		t.Fatal(msg)
	}
}

func ok(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestUserService_CreateUser(t *testing.T) {
	cases := map[string]struct {
		name        string
		setupFake   func(*FakeDB)
		expectErr   error
		expectUsers []string
	}{
		"first insert succeeds": {
			name:        "alice",
			expectUsers: []string{"alice"},
		},
		"duplicate returns ErrDuplicate": {
			name:        "alice",
			setupFake:   func(db *FakeDB) { db.InsertUser("alice") },
			expectErr:   ErrDuplicate,
			expectUsers: []string{"alice"},
		},
	}

	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			db := NewFakeDB()
			if tc.setupFake != nil {
				tc.setupFake(db)
			}
			svc := usersvc.NewUserService(db)

			err := svc.CreateUser(tc.name)

			if tc.expectErr != nil {
				assert(t, errors.Is(err, tc.expectErr),
					fmt.Sprintf("%s: expected %v, got %v", name, tc.expectErr, err))
			} else {
				ok(t, err)
			}
			if got, want := db.ListUsers(), tc.expectUsers; !reflect.DeepEqual(got, want) {
				t.Errorf("%s: users: got %v, want %v", name, got, want)
			}
		})
	}
}
```

Key rules:

- Include the map key (`name`) as the first token in every failure message: `"%s: ..."`.
- Never call `mock.AssertExpectations`. Assert on `db.ListUsers()`, return values, and sentinel errors.
- Use `t.Run(name, ...)` (Go 1.7+) for per-case subtests — gives named output in `go test -v` and lets individual cases run with `-run TestFoo/case-name`.

## Step 6: Apply Even for One Case

If the function has exactly one scenario today, ask: "Could this function plausibly need more cases in the future?" For functions with external dependencies, the answer is almost always yes. Write the map table from the start. The overhead is three lines; the benefit accrues at every future debugging session and every new case added.

## Step 7: Choose the Right Lifecycle Scope

- **Per-test (default):** Create a fresh `FakeDB` in each test case via `NewFakeDB()`. Maximum isolation. This is what the step 5 example shows.
- **Grouped (parent subtest):** When test cases need sequential shared state (create-then-list flows), create the fake once in the parent test and share it via closure across subtests. Use with care — map iteration order is randomized in Go.
- **TestMain:** Only for expensive infrastructure (a real container, a compiled binary). Never use it to share in-memory fakes across tests.

______________________________________________________________________

## B — Boundaries and Failure Modes

### Source a Failures (Rednafi — State Testing / Handwritten Fakes)

- **ce04 — Mock passes, bug lands:** `CreateUser` silently swallows `InsertUser`'s error. Mock verifies the call happened; fake verifies the error surfaces. Bug is invisible to the mock, caught immediately by the fake.
- **ce11 — AI-generated test bloat:** LLMs default to mockery/gomock because those dominate training data. Tests verify interaction, not state. Suite is brittle on refactors (harmless renames break expectations) and permissive through bugs (swallowed errors pass). Mitigation: write the first few tests by hand to establish the fake + state pattern; LLMs imitating the established seed are better.
- **ce14 — Mocks don't enforce data invariants:** A mock verifies `Save(user="alice")` was called. The real database has a unique constraint. Duplicate records are inserted without the mock objecting. The handwritten fake with a `seen` map catches this immediately.
- **Large interface drift:** Handwritten fakes must be maintained as interfaces change. For interfaces with 10+ methods or fast-evolving contracts across many consumers, the maintenance burden is real. Use generated mocks or testcontainers in those cases.

### Source B Failures (Hashimoto — Map-Keyed Table)

- **Slice indices in failure messages:** "test index 3014 failed" requires manual row-counting. Refactor to `map[string]struct{}`.
- **Omitting the key from the error format string:** `t.Errorf("got %d, want %d", got, tc.Expected)` inside the loop discards the case name. Always include `%s` for the key as the first token.
- **Generic or duplicate keys:** "test1", "case_a", "happy path" repeated in two entries — these defeat the purpose. Keys must describe the specific scenario.
- **Using `[]struct{name string; ...}` instead of `map[string]struct{}`:** Functionally equivalent if the name field is always included, but the map syntax enforces uniqueness of case names and eliminates forgetting the name field on a new entry.
- **Map iteration order is randomized:** Running cases in random order is usually beneficial (catches order-dependent bugs) but can surprise developers who expect deterministic ordering. If order matters (sequential state scenarios), use a different structure.

### Synthesis-Specific Failure Mode

- **Map-keyed table with generated mocks:** You apply Hashimoto's naming convention (map key, descriptive string, key in error format) but retain a generated mock (mockery/gomock) behind it. The failure messages now name the scenario, but the assertions still check call paths. This is better than anonymous slice-indexed mocks, but it does not catch swallowed errors or data invariant violations. The synthesis is incomplete: naming without state assertions gives you DX benefits but not correctness benefits. The full merged pattern requires both: map key for naming + fake state assertion for correctness.

______________________________________________________________________

## Related Skills

- **rednafi/test-state-not-interactions** — superseded-by: this merged skill for functions with multiple input cases; source skill remains useful for single-case tests and lifecycle scope guidance
- **hashimoto/table-driven-named-cases** — superseded-by: this merged skill for functions with stateful dependencies; source skill remains useful for pure functions with no fake needed
- **hashimoto/golden-files-update-flag** — composes-with: when each table case produces complex output, the map key becomes the `.golden` filename — `filepath.Join("test-fixtures", name+".golden")`; golden files provide scalable expected output storage; the merged skill provides the fake and assertion pattern
- **rednafi/consumer-side-interface-segregation** — depends-on: defining a minimal interface in the consumer package is the prerequisite for building a fake that implements only the methods the code under test calls
- **rednafi/repository-unit-of-work** — composes-with: the `Store` interface from the repository pattern is exactly what this skill puts a handwritten fake behind

______________________________________________________________________

## Audit Information

- **Phase 1 verdict:** ADVANCE (all four gates passed; V2 and V3 with moderate confidence)
- **V1 (genuine convergence):** PASS — two independent authors from different contexts (rednafi: correctness of test doubles; Hashimoto: ergonomics of test tables) independently concluded that test structure must communicate intent clearly
- **V2 (novel questions answered):** MARGINAL PASS — "How do I write a Go test for a function with external dependencies AND multiple input cases?" requires both skills. The composition (map-keyed table + FakeDB state assertions) is genuinely novel relative to both sources.
- **V3 (non-obvious synthesis):** MARGINAL PASS — that the map key in a table-driven test should name the behavioral scenario tested by the fake, and that the fake's state assertions make the test both legible AND correct, is a specific combination not articulated in either source
- **V4 (sharper A2):** PASS — merged A2 adds "I'm writing a test for a function with stateful dependencies and multiple input cases — how do I organize it so failures are immediately identifiable AND the test catches swallowed errors?" — a composite trigger better served by the merged skill than by either alone
- **Merge date:** 2026-05-05
- **Revised 2026-05-08**: E section Step 5 — stdlib `assert`/`ok`/`equals` helper equivalents noted alongside testify examples
- **Revised 2026-05-09**: All testify code examples replaced with stdlib helpers (`assert`, `ok`, `reflect.DeepEqual` inline); I and A1 inline references updated; testify redirect note removed; T1 tension fully resolved
