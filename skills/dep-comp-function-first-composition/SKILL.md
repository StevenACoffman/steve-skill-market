---
name: dep-comp-function-first-composition
description: |
  Invoke this skill when a Go developer asks how to inject dependencies, wants
  to avoid writing interfaces for every external call, or finds their test setup
  heavy with mock generation. The core technique: define a `Dependencies` struct
  with one function-typed field per external dependency, write a factory function
  `New(deps Dependencies)` that closes over the struct and returns the operational
  function, then wire real implementations in `main.go` and inline function
  literals in tests.

  Do NOT invoke for "should I define an interface between packages?" — that is
  the dep-comp-cross-package-contract-decision skill. Do NOT invoke when a
  dependency has many methods (8+) and the caller uses most of them; in that
  case a local minimal interface (option 1) is the better fit. This skill
  addresses the mechanics of wiring and testing single-responsibility modules,
  not the question of when a cross-package contract is warranted.

  Key trigger signals: a developer declaring interfaces only to satisfy
  constructor injection; test boilerplate that requires mock generation for a
  simple function; wanting to test an HTTP handler without a real database;
  asking "what's the Go way to do dependency injection?"; any hodgepodge where
  some modules use constructor injection, others use global init(), and tests
  require different setups per module.
source_book: '"Dependency Composition (Go Adaptation)" by Daniel Somerfield (2023, updated 2026)'
source_chapter: Option 4 — Dependencies Struct with Function Fields
tags: [go, dependency-injection, testing, closure, composition]
related_skills:
  - dep-comp-cross-package-contract-decision  # precedes: use that skill to decide IF a contract is needed; use this skill for HOW to wire it
  - golang-dependency-injection               # broader: covers all four DI options; this skill is option 4 in depth
---

# Function-First Dependency Composition in Go

## R — Original Text (Reading)

> "By choosing to fulfill dependency contracts with function-typed fields in
> structs rather than with classes or interface registries, minimizing the code
> sharing between packages and driving the design through tests, I can create a
> Go system composed of highly discrete, evolvable, but still type-safe modules.
> Dependencies structs with function fields replace interface-based injection
> without requiring interface declarations. Option 4 is almost free of ceremony:
> no interface declaration, no mock generation, just a function literal in the
> test and a real function value in main.go."
>
> "This small detail is the first step toward the closure-over-dependencies
> pattern, where a factory function (NewTopRatedHandler) captures its
> dependencies and returns a function that uses them."

— Daniel Somerfield, *Dependency Composition (Go Adaptation)*, Option 4

## I — Methodological Framework (Interpretation)

Go's conventional dependency injection pattern declares an interface, implements
it in production code, and produces a mock implementation (by hand or via
generation) for tests. This works, but the ceremony accumulates: one interface
declaration per dependency boundary, one mock type per interface, framework
configuration when multiple dependencies are in play.

The function-first pattern collapses this into three mechanical parts:

**Part 1 — `Dependencies` struct.** Each external call the module makes becomes
one field, typed as the exact function signature needed. No interface is declared.
The struct is the contract.

```go
type Dependencies struct {
	GetTopRestaurants func(ctx context.Context, city string) ([]Restaurant, error)
}
```

**Part 2 — Factory function.** `New(deps Dependencies)` captures the struct
in a closure and returns the operational function (an `http.HandlerFunc`, a
domain function, a service function). The factory does nothing except close
over the dependencies and return the function value.

```go
func New(deps Dependencies) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		city := r.URL.Query().Get("city")
		restaurants, err := deps.GetTopRestaurants(r.Context(), city)
		// ...
	}
}
```

**Part 3 — Wiring.** In `main.go`, construct `Dependencies` with real function
values from real implementations. In tests, construct `Dependencies` with inline
function literals — no mock type, no generation, no framework.

```go
// main.go
handler := toprated.New(toprated.Dependencies{
	GetTopRestaurants: restaurantStore.GetTopRestaurants,
})

// test
handler := toprated.New(toprated.Dependencies{
	GetTopRestaurants: func(ctx context.Context, city string) ([]Restaurant, error) {
		return []Restaurant{{Name: "Test Place"}}, nil
	},
})
```

The critical insight: a function type in Go is structurally typed. Any function
with the matching signature satisfies the field — production function, method
value, or inline literal. The type system enforces the contract without an
explicit interface declaration.

This pattern particularly shines at the domain layer where a module may have
several dependencies (3–6 is typical). Each can be stubbed independently with
a single function literal, so a test that exercises one code path needs only one
field to return a meaningful value; the rest can return zero values or errors to
expose handling bugs.

## A1 — Past Application (From the Book)

### Case 1: `NewTopRatedHandler` — HTTP Handler with One Function Dependency (C01)

**Problem**: An HTTP handler needs to call a restaurant data store to get top-rated
restaurants for a city. The team needs the handler testable without a real database
or HTTP test server setup.

**Method**: Define `Dependencies` with one field:

```go
type Dependencies struct {
	GetTopRestaurants func(ctx context.Context, city string) ([]Restaurant, error)
}

func New(deps Dependencies) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		city := r.URL.Query().Get("city")
		restaurants, err := deps.GetTopRestaurants(r.Context(), city)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(restaurants)
	}
}
```

In the test, pass an inline function literal:

```go
handler := New(Dependencies{
	GetTopRestaurants: func(_ context.Context, city string) ([]Restaurant, error) {
		if city == "" {
			return nil, errors.New("city required")
		}
		return []Restaurant{{Name: "Somerfield's"}}, nil
	},
})
```

**Conclusion**: The test exercises the full handler logic — parameter extraction,
error handling, JSON encoding — without database setup, without an interface
declaration, and without a generated mock type.

**Result**: The handler and its test each fit in one file. Wiring in `main.go`
is one line. If the real data-store function signature changes, the compiler
reports every call site immediately.

______________________________________________________________________

### Case 2: `toprated.New` — Domain Layer Factory with Three Function Dependencies (C02)

**Problem**: The domain layer aggregates data from three sources: ratings by
restaurant, a rating calculator, and a restaurant lookup. These are independent
concerns from independent packages. Testing each code path requires controlling
all three independently.

**Method**: Define `Dependencies` with three function fields, one per source:

```go
type Dependencies struct {
	FindRatingsByRestaurant      func(ctx context.Context, restaurantID string) ([]Rating, error)
	CalculateRatingForRestaurant func(ctx context.Context, ratings []Rating) (float64, error)
	GetRestaurantByID            func(ctx context.Context, id string) (Restaurant, error)
}

func New(deps Dependencies) func(ctx context.Context, city string) ([]Restaurant, error) {
	return func(ctx context.Context, city string) ([]Restaurant, error) {
		// orchestrate deps.FindRatingsByRestaurant,
		//             deps.CalculateRatingForRestaurant,
		//             deps.GetRestaurantByID
	}
}
```

Each test case stubs only the fields it needs to exercise a specific branch.
A test for the error path from `FindRatingsByRestaurant` sets only that field;
the other two fields are never called.

**Conclusion**: The domain layer is independently testable from the persistence
layer and the HTTP layer. No integration setup is required at any layer boundary.
Each layer's `New` function composes with adjacent layers' `New` functions in
`main.go`.

**Result**: Three independently tested modules compose into a single handler.
`main.go` is a flat list of `New(Dependencies{...})` calls. Adding a fourth
dependency is one new field and one new `main.go` assignment.

## A2 — Trigger Scenario (Future Trigger) ★

1. **"How do I inject dependencies in Go?"** A developer asking this open question
   has not yet committed to a pattern. Present the four-option framework from the
   source, then recommend option 4 for typical single-responsibility modules.

2. **"I have to write an interface for every external call"**: The developer is
   following the Java-style convention: declare an interface, implement it, mock
   it. Show how the `Dependencies` struct with function fields eliminates the
   interface declaration entirely.

3. **"My tests need a lot of mock setup for a simple function"**: Three or more
   lines of mock initialization before a test body begins. The function-literal
   approach replaces the mock struct with an inline closure in the test call.

4. **"I want to test my HTTP handler without a real database"**: Classic use case
   for Case 1. The handler factory pattern lets the test control the data layer
   with a one-field struct literal.

5. **"Our codebase has inconsistent DI — some constructors, some globals, some
   init()"**: Hodgepodge DI. Tests require different approaches per module;
   broken contracts accumulate. Standardize on the `Dependencies` struct pattern
   across all new modules.

6. **Developer new to Go asking about dependency injection**: They may be bringing
   Java/Spring or Python DI framework assumptions. Explain that Go's structural
   typing for function values makes an explicit DI container unnecessary.

### Language Signals

- "How should I inject dependencies in my Go service?"
- "I'm tired of writing interfaces for every dependency"
- "My tests require a lot of mock setup for a simple function"
- "I want to test my HTTP handler without spinning up a real database"
- "Do I need a DI framework in Go?"
- "What's the idiomatic way to handle dependencies in Go?"
- "My constructor takes too many interface parameters"
- "How do I stub out an external call in a Go test?"

### Distinguishing from Adjacent Skills

- **dep-comp-cross-package-contract-decision**: That skill answers "should I
  define a contract at this package boundary at all?" This skill answers "once
  I've decided to inject a dependency, how do I wire and test it?" Use the
  contract-decision skill first if the team is debating whether packages should
  share an abstraction.

- **golang-samber-do / DI frameworks**: Container-based DI (Uber Dig, Google
  Wire, samber/do) hides the dependency graph behind reflection or code
  generation. `main.go` is no longer a readable wiring diagram. The
  `Dependencies` struct pattern keeps wiring explicit and visible.

## E — Execution Steps

## Step 1: Identify What the Module Calls Externally

List every external call the function makes — other packages, databases, HTTP
clients, time sources. Each call becomes one field in `Dependencies`. Keep the
field type to the exact signature needed, not a broader interface.

Completion criterion: a `Dependencies` struct exists in the module's package
with one field per external call, all typed as named `func(...)` types or
inline function signatures.

## Step 2: Write the Factory Function

```go
func New(deps Dependencies) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// use deps.FieldName(...) for each external call
	}
}
```

`<ReturnType>` is the operational type: `http.HandlerFunc`, a domain function
signature, a service function signature. The factory contains no logic — only
the closure and the `return` statement.

Completion criterion: `New` does nothing except return the function value. Logic
lives in the returned function, not in `New` itself.

## Step 3: Write the Test with Inline Function Literals

```go
func TestMyModule_HappyPath(t *testing.T) {
	fn := New(Dependencies{
		CallA: func(ctx context.Context, id string) (Result, error) {
			return Result{Value: "stub"}, nil
		},
		CallB: func(ctx context.Context) error { return nil },
	})
	got, err := fn(context.Background(), "input")
	// assert got and err
}
```

Completion criterion: no mock type is declared. No mock library is imported.
Each test case constructs `Dependencies` inline with function literals.

**Step 4: Wire in `main.go`**

```go
myFn := mymodule.New(mymodule.Dependencies{
	CallA: realPackage.CallA,
	CallB: otherPackage.SomeMethod,
})
```

Completion criterion: `main.go` (or the application wiring file) lists all
`Dependencies` constructions as plain struct literals with real function values.
The full dependency graph is readable from this file without navigating into
package internals.

## B — Boundary ★

## When NOT to Use

- **Dependency with many methods (8+)**: If the module calls 8 or more methods
  on a single dependency and uses most of them across different code paths,
  declare a local minimal interface (option 1 from the four-option framework)
  instead. A `Dependencies` struct with 8+ fields becomes a maintenance burden
  and signals that the module should be decomposed into smaller units.

- **Non-Go codebases**: The mechanism depends on Go's structural typing for
  function values. Other languages require different approaches. Do not port
  this pattern directly to TypeScript, Java, or Python — the ergonomics will
  not carry over.

- **Module already using a stable, well-defined interface shared across many
  callers**: If an existing interface is serving multiple implementations in
  production (not just in tests), replacing it with a `Dependencies` struct
  is not worth the churn. This pattern is most valuable for new modules or
  modules with exactly one production implementation.

## Failure Patterns

- **Hodgepodge DI**: No team decision → some modules use constructor injection
  with interfaces, others initialize state in `init()`, others use package-level
  globals. Tests require three different setups depending on which module is
  under test. Broken contracts accumulate across package boundaries because there
  is no single convention to rely on. This is the failure mode the
  `Dependencies` pattern is designed to prevent when adopted consistently.

- **Interface registries and DI frameworks**: Wiring is hidden behind reflection
  (Uber Dig) or code generation (Google Wire). The dependency graph is no longer
  readable from `main.go`. Test setup requires framework-specific mocking
  primitives. When the framework is upgraded or replaced, all wiring must be
  rewritten. Somerfield's approach keeps wiring as plain Go struct literals,
  readable without framework knowledge.

- **Choosing a DI pattern for aesthetic reasons**: "What DI pattern should we
  use?" before "What testability and coupling qualities do we need?" leads to
  selecting patterns based on familiarity with other languages rather than
  fitness for the actual module boundaries. Start with the qualities (isolated
  testability, explicit wiring, no ceremony) and the `Dependencies` struct
  follows directly.

- **Stub fields returning zero values silently**: A test that does not set all
  fields may call a stub returning `nil, nil` and not realize a real code path
  was exercised against a no-op. When a field must not be called in a given
  test path, assign it a function that calls `t.Fatalf("unexpected call to X")`.

## Author Blind Spots

- **Concurrency safety of the `Dependencies` struct**: The struct is captured
  by value in the closure, so fields are read-only after `New` returns. This is
  safe. However, if a function-typed field is itself mutated from a test goroutine
  (e.g., swapping out the stub mid-test), the caller must synchronize. Somerfield
  does not address concurrent test mutation.

- **Generics (Go 1.18+)**: A `Dependencies[T any]` struct could parameterize
  the return type of a field, reducing boilerplate when the same dependency
  pattern appears across many modules. The book predates widespread generics
  adoption in Go and does not explore this.

## Easily Confused Methods

- **`http.HandlerFunc` wrapping vs. interface satisfaction**: `http.HandlerFunc`
  is a function type that satisfies `http.Handler`. Returning it from `New` is
  not a special trick — it is the same closure-over-dependencies pattern applied
  to an existing stdlib type. Do not confuse "returning `http.HandlerFunc`"
  with "implementing the `http.Handler` interface by method."

## Related Skills

- **dep-comp-cross-package-contract-decision** (precedes): Answers whether a
  package boundary requires a shared contract at all. Use that skill before
  reaching for the `Dependencies` struct if the team is debating the package
  structure itself.
- **golang-dependency-injection** (broader): Covers all four dependency injection
  options (local interface, `io.Writer`-style stdlib interface, `Dependencies`
  struct with function fields, full DI framework). Use that skill for a
  comparative overview; use this skill when option 4 has been chosen and
  implementation details are needed.

## Audit Information

- Source extraction date: 2026-05-05
- Primary source: "Dependency Composition (Go Adaptation)" by Daniel Somerfield (2023, updated 2026)
- Pipeline stage: Phase 2 (RIA-TV++)
- Version: 0.1.0
