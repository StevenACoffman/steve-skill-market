---
name: test-state-not-interactions
description: |
  Activate when a developer asks about testing strategy, mocking approach, or complains about
  brittle tests. Core question: "should I use mocks?" Answer: not usually — prefer handwritten
  fakes that encode domain rules and assert observable state.

  The skill covers three tightly connected ideas from rednafi's "Go Advice":
  1. Test the outcome a function produces (return values, mutations, side effects), not which
     collaborator methods it called. Google calls the latter "interaction tests" — rednafi calls
     them actively harmful.
  2. Handwritten fakes beat generated mocks (mockery, gomock) because they hold in-memory state
     that encodes real domain rules (duplicate rejection, ordering constraints). A mock records
     that InsertUser() was called; a fake records that "alice" is now in the store.
  3. Organize tests and lifecycle by the isolation level each scenario needs: per-test
     (t.Cleanup), grouped (parent subtest sharing state), or package-wide (TestMain for expensive
     infrastructure only). The choice of isolation scope is itself a state-testing decision.

  Trigger phrases: "my tests keep breaking when I refactor", "how do I mock X in Go",
  "should I use mockery / gomock / testify mock", "tests are green but the feature is broken",
  "LLM generated tests for me", "test setup is longer than the code", "tests are brittle".

  Do NOT activate for: pure functions with no dependencies (no fake needed at all), questions
  about testcontainers integration (complementary pattern, not a replacement), or gRPC server
  testing where generated mocks are genuinely ergonomic.
source_book: "Go Advice" by Redowan Delowar (rednafi)
source_chapter: test_state_not_interactions, mocking_libraries_bleh, organizing_tests, lifecycle_management_in_tests
tags: [go, testing, quality, mocking, fakes]
related_skills:
  - slug: consumer-side-interface-segregation
    relation: composes-with
  - slug: repository-unit-of-work
    relation: composes-with
  - slug: merged/all-books-v1/go-test-state-driven-table
    relation: superseded-by
    note: Merged skill adds table-driven structure; use this for functions with multiple input cases.
---

# Test State Not Interactions

## R — Original Text (Reading)

> The general theme when writing unit tests should be checking the behavior of the system,
> not the scaffolding of its implementation. It doesn't matter which method called which,
> how many times, or with what arguments. What matters is: if you give the SUT some input,
> does it return the expected output? In a stateful system, does the input cause the system
> to mutate some persistence layer in the expected way?
>
> If an error is accidentally swallowed, callers get the wrong signal but the test still
> passes... A real DB or an in-memory fake would raise a constraint error that should
> propagate. The mock test goes green anyway because it only checked the call path. The
> common thread is that mocks lock tests to implementation details. They don't protect the
> behavior that real users rely on.
>
> — rednafi, test_state_not_interactions

______________________________________________________________________

## I — Methodological Framework (Interpretation)

**State testing vs. interaction testing.** State testing asks: "what does the system look
like after this runs?" You assert on return values, on what the fake's internal store
contains, on the error that surfaces. Interaction testing asks: "did the right methods get
called?" You assert on call counts and argument lists. Interaction testing is the anti-pattern:
it locks tests to implementation structure, not behavior.

**Why mocks fail in two opposite directions.** (1) They break on harmless refactors — rename
`InsertUser` to `UpsertUser` and every mock expectation must be rewired, even though public
behavior is identical. (2) They stay green through real bugs — if `CreateUser` silently
swallows the error (`_ = s.db.InsertUser(name); return nil`), the mock still records the
call and `AssertExpectations` passes. The mock cannot tell that the error was discarded.

**Handwritten fakes encode domain rules.** A fake is a struct with in-memory state (a `map`,
a `[]string`) that implements the same interface as the real dependency. Crucially, the fake
encodes the one or two domain invariants that matter for the tests: a `seen map[string]struct{}`
detects duplicate inserts and returns `ErrDuplicate`. The real database enforces this via a
unique constraint; the fake enforces it via the map. Tests then assert on `db.ListUsers()`
or `errors.Is(err, ErrDuplicate)` — not on `mock.AssertExpectations`.

**AI-generated tests compound the problem.** LLMs default to mocking libraries because they
were trained on web examples that use them. They produce interaction-checking test suites
that are fragile by construction: break on refactors, pass through bugs, and require more
setup code than the code under test.

**Lifecycle scopes as isolation policy.** Per-test (`t.Cleanup`): default, maximum isolation,
fresh state for every function. Grouped (parent subtest with shared fake/DB): use when tests
need sequential shared state, e.g., create-then-list flows. Package (`TestMain`): only for
expensive infrastructure like a real container — never use it to share in-memory state, since
one test's mutation poisons the next.

**When a real service is the right fake.** Testcontainers are still state testing, just at
higher fidelity. Use them when the fake would need to emulate complex behavior (transactions,
constraint propagation, SQL semantics) that is too expensive to replicate correctly by hand.

______________________________________________________________________

## A1 — Past Application

### Case 1: CreateUser with Error Swallowed — Mock Passes, Fake Fails (C03, Ce04)

- **Problem:** `CreateUser` is refactored to ignore its own error:
  `_ = s.db.InsertUser(name); return nil`. Every caller now silently receives success even
  when the database rejects the insert (duplicate, constraint violation, connection error).
- **Method:** Mock-based test asserts `db.EXPECT().InsertUser("alice").Return(nil).Once()`
  then calls `db.AssertExpectations(t)`. The call happened; mock passes. Fake-based test
  calls `svc.CreateUser("alice")` twice and asserts `errors.Is(err, ErrDuplicate)` on the
  second call. Fake fails because the error was swallowed before reaching the caller.
- **Conclusion:** The mock validated the call path; the fake validated the outcome. Only the
  fake caught the regression.
- **Result:** Handwritten `FakeDB` with a `seen map[string]struct{}` detects the bug on
  first run. Test reads: `reflect.DeepEqual(db.ListUsers(), []string{"alice"})` — the state
  of the store after the operation is the assertion, not the call record.

### Case 2: AI-Generated Mock Tests Vs Handwritten Fakes (Ce11)

- **Problem:** An LLM generates a test suite that imports mockery and gomock. Every dependency
  is mocked. Tests verify which methods were called with which arguments. The suite has more
  setup code than production code. Tests break immediately when a method is renamed from
  `chargeCard` to `processPayment` (harmless refactor), but stay green when the error return
  from the charge is silently dropped (real bug).
- **Method:** The author advocates writing the first few tests by hand to establish the pattern.
  These seed tests use handwritten fakes and assert on state. LLM-generated tests that follow
  the established pattern will be better because they have a model to imitate.
- **Conclusion:** "The seed tests, the first handful that set the standard, need to come from
  you. They define what correctness means in your system and give the ensuing tests a model
  to follow."
- **Result:** Suites built on fakes are stable across refactors (method renames don't break
  assertions on `db.ListUsers()`) and sensitive to behavior changes (swallowed errors surface
  as wrong state in the fake).

______________________________________________________________________

## A2 — Trigger Scenario ★

### Language Signals

- "my tests keep breaking when I refactor" (classic interaction-test fragility)
- "how do I mock X in Go" (redirect to fake pattern)
- "should I use mockery / gomock / testify mock"
- "the LLM generated tests for me but they feel wrong"
- "my tests pass but I know the feature is broken"
- "test setup is longer than the code under test"
- "how do I test a function that calls a database / HTTP API / queue"
- "how do I organize my tests" (three-level structure answer)
- "should I use TestMain"

### Distinguishing from Adjacent Skills

- **Difference from `repository-unit-of-work`:** That skill is about structuring the
  repository layer and coordinating transactions. This skill is about how to test whatever
  repository structure you chose. They compose: use the repository pattern, then test it
  with a handwritten in-memory fake.
- **Difference from `consumer-side-interface-segregation`:** Interface segregation is about
  defining minimal interfaces on the consumer side to reduce coupling. This skill is about
  what you put behind those interfaces in tests (a handwritten fake, not a generated mock).
  They compose: define a narrow interface, then back it with a fake for tests.
- **Difference from testcontainers usage:** Testcontainers are state testing at higher
  fidelity — they are complementary, not competing. Use fakes for fast unit tests; use
  testcontainers in the `integration/` package when behavior must match production exactly.

______________________________________________________________________

## E — Execution Steps

1. **Identify what the system is supposed to produce (state)**

   - Ask: "What changes in the world after this function runs?"
   - For a write operation: what is now in the store? What error surfaces to the caller?
   - For a read operation: what value is returned?
   - Completion criteria: you can write the assertion before writing the fake. Example:
     `if got, want := db.ListUsers(), []string{"alice"}; !reflect.DeepEqual(got, want) { ... }` or
     `assert(t, errors.Is(err, ErrDuplicate), fmt.Sprintf("expected ErrDuplicate, got %v", err))`.

2. **Define a minimal interface for the dependency**

   - Use Go's implicit satisfaction: define the interface in the consumer package, not the
     producer package.
   - Include only the methods this code actually calls. If `CreateUser` calls `InsertUser`
     and `ListUsers`, include exactly those two.
   - Completion criteria: the interface compiles and the real dependency satisfies it without
     changes.

3. **Build a handwritten fake for the dependency**

   - The fake holds in-memory state: a `map` for lookup, a `[]string` for ordering.
   - Encode exactly one domain rule that matters for the tests. For a user store: duplicate
     detection via `seen map[string]struct{}`. For an order store: max-quantity enforcement.
   - Do not encode rules the tests do not exercise — keep the fake minimal.
   - Completion criteria: the fake implements the interface, holds state, and returns a domain
     sentinel error (defined in the production package) when the rule is violated.

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

4. **Write tests that assert the state, not the call**

   - Replace `mock.AssertExpectations(t)` with assertions on observable outcomes.
   - Assert return values: `ok(t, err)`, `assert(t, errors.Is(err, ErrDuplicate), fmt.Sprintf("expected ErrDuplicate, got %v", err))`.
   - Assert store state: `if got, want := db.ListUsers(), []string{"alice"}; !reflect.DeepEqual(got, want) { t.Errorf("users: got %v, want %v", got, want) }`.
   - Never assert which method was called or how many times.
   - Completion criteria: if you rename `InsertUser` to `UpsertUser` inside the implementation
     (keeping the same behavior), the test still passes without modification.

   ```go
   func assert(t *testing.T, condition bool, msg string) {
   	t.Helper()
   	if !condition {
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
   	db := NewFakeDB()
   	svc := usersvc.NewUserService(db)

   	ok(t, svc.CreateUser("alice"))
   	if got, want := db.ListUsers(), []string{"alice"}; !reflect.DeepEqual(got, want) {
   		t.Errorf("users: got %v, want %v", got, want)
   	}
   }

   func TestUserService_CreateUser_DuplicateSurfaces(t *testing.T) {
   	db := NewFakeDB()
   	svc := usersvc.NewUserService(db)

   	ok(t, svc.CreateUser("alice"))
   	err := svc.CreateUser("alice")
   	assert(t, errors.Is(err, usersvc.ErrDuplicate),
   		fmt.Sprintf("expected ErrDuplicate, got %v", err))
   	if got, want := db.ListUsers(), []string{"alice"}; !reflect.DeepEqual(got, want) {
   		t.Errorf("users: got %v, want %v", got, want) // state unchanged after duplicate
   	}
   }
   ```

5. **Choose the right lifecycle scope for setup and teardown**

   - **Per-test (`t.Cleanup`):** Default. Create a fresh fake in each test function. Maximum
     isolation. Use `t.Helper()` + `t.Cleanup()` in a `newTestDB(t *testing.T)` helper.
     Completion criteria: each test creates its own fake; no shared state.
   - **Grouped (parent subtest):** When tests need sequential shared state — e.g., create a
     user and then list users in the same flow. Create the fake once in the parent test;
     subtests share it via closure. Teardown runs when the parent returns.
     Completion criteria: `db.AssertExpectations` is gone; instead the final subtest asserts
     the expected store contents.
   - **TestMain:** Only for expensive infrastructure setup — a real PostgreSQL container via
     testcontainers, a network listener, a compiled binary. Never use it to share in-memory
     fakes across tests; global mutable state poisons isolation.
     Completion criteria: `TestMain` starts and stops one piece of infrastructure; individual
     test functions still create their own per-test scopes for everything else.

6. **Organize tests by granularity**

   - In-package (`package mypkg`): white-box unit tests with access to unexported identifiers.
     Most tests live here.
   - Co-located external (`package mypkg_test`): black-box tests that only call exported APIs.
     Use when verifying the public contract.
   - Separate `integration/` package: tests that span multiple packages or require real
     infrastructure. Run separately (build tag or dedicated `go test` invocation).
   - Completion criteria: `go test ./...` runs in-package and external tests; integration
     tests run only when explicitly included.

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- Testing a **pure function with no dependencies**: `func Add(a, b int) int` needs no fake.
  Call it and assert the return value directly.
- The external dependency is too **complex for a handwritten fake**: large binary protocols,
  SQL transaction semantics, network timing. Use testcontainers against a real service instead
  of a fake that would be wrong in subtle ways.
- **Integration or E2E tests** intentionally verify full-system behavior. These should use
  testcontainers and real services — fakes would undermine the purpose of the test.
- Testing a **gRPC server** where the generated protocol types and interceptors make handwritten
  fakes painful. rednafi acknowledges this as one case where generated mocks are genuinely
  ergonomic.

### Failure Patterns from the Book

- **ce04 — Mock passes, bug lands:** `CreateUser` silently swallows `InsertUser`'s error.
  Mock verifies the call happened; fake verifies the error surfaces to the caller. Bug is
  invisible to the mock, caught immediately by the fake.
- **ce11 — AI-generated test bloat:** LLM pulls in mockery and gomock because those are
  overrepresented in its training data. Tests verify interaction, not state. Suite is brittle
  by construction.
- **ce14 — Mocks don't enforce data invariants:** A mock verifies `Save(user="alice")` was
  called. The real database has a unique constraint on email. Duplicate alice records are
  inserted without the mock objecting. The handwritten fake with a `seen` map catches this
  immediately.

### Author's Blind Spots

- In organizations with 50+ developers, generated mocks provide **consistency guarantees**
  across teams that handwritten fakes can't easily replicate. When interfaces evolve, generated
  mocks are regenerated automatically; handwritten fakes drift silently.
- Fakes **must be maintained** as interfaces change. rednafi acknowledges this but asserts
  without evidence that the maintenance burden is lower than updating mock expectations. For
  large interfaces (10+ methods), this claim is less obvious.
- For testing **across package boundaries with multiple consumers**, a generated mock checked
  into the repository gives every consumer a shared, up-to-date fake. Handwritten fakes
  duplicated across packages diverge.
- The "no mocking library" stance applies most cleanly to **application code**. Library authors
  testing against interfaces they don't control may find generated mocks more practical.

### Reconciliation with Summary_rules.md

`summary_rules.md §10` shares the same core principle: hand-write test doubles; no
third-party mock generation tools (`mockery`, `gomock`). Both this skill and the summary
prohibit generated mocks.

The differences are in **location** and **verification style**, not in direction:

- **Location:** The summary places hand-written fakes in a dedicated `mock/` package
  (e.g. `mock/mock.go`), co-located with the domain package. This skill puts fakes in
  the test file (e.g. `FakeDB` inside `usersvc_test.go`). Both are acceptable; the
  summary's `mock/` package approach makes the fake reusable across test files.
- **Verification style:** The summary's fakes use function-typed fields
  (`InsertFn func(name string) error`) and an `Invoked bool` field to record whether the
  function was called. This skill uses a state-holding map (`seen map[string]struct{}`).
  These are two flavors of the same handwritten-fake philosophy. The `Invoked` field
  enables lightweight call-presence checks without importing a mock library; the
  `seen`-map approach asserts the same thing through observable state. Prefer
  state assertions where possible; use `Invoked` for side-effect functions that produce
  no queryable state.

When following `summary_rules.md`, apply the `mock/` package structure and `Fn`/`Invoked`
field convention. The state-assertion principle from this skill is fully compatible —
implement fakes with state-holding behaviour (`seen map[string]struct{}`) in addition to
`Fn` fields where the domain rule warrants it.

### Easily Confused With

- **Testcontainers:** Complementary, not competing. Testcontainers give high-fidelity state
  testing at integration scope; fakes give fast state testing at unit scope. Use both.
- **Test doubles taxonomy (spy, stub, fake, mock):** rednafi uses "fake" specifically for a
  state-holding in-memory implementation. He uses "mock" for a generated call-recording object
  (mockery/gomock). These terms differ from the classic Fowler taxonomy.
- **Monkey patching:** rednafi covers package-level variable replacement for legacy code where
  signature injection isn't practical. This is a last resort — tests that mutate package state
  can't run in parallel and must restore state with `t.Cleanup`.

______________________________________________________________________

## Related Skills

- **composes-with** [`consumer-side-interface-segregation`](../consumer-side-interface-segregation/SKILL.md): Consumer-side interfaces define the narrow seam the fake must implement. A 1-2 method interface is easy to fake in 5 lines; a fat producer-side interface forces stubs for unused methods. Define the narrow interface first, then build a state-holding fake behind it — the two skills together eliminate both mock libraries and SDK imports from tests.
- **composes-with** [`repository-unit-of-work`](../repository-unit-of-work/SKILL.md): The `Store` interface produced by the repository pattern is exactly what this skill puts a handwritten fake behind. An in-memory `memStore` with a mutex-guarded map satisfies the same interface the real SQL repository does, runs in microseconds, and lets tests assert on what's in the store — not on SQL call sequences.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Date**: 2026-05-05
- **Revised 2026-05-08**: B section reconciliation note added (location: `mock/` package vs. test-local; verification style: `Invoked` bool vs. state-map); A1 and E section inline examples updated to stdlib forms
- **Revised 2026-05-09**: E section code block and all inline testify references replaced with stdlib helpers (`ok`, `assert`, `reflect.DeepEqual`); source article fake-test block revised in parallel
