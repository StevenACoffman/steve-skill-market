---
name: go-beyond-four-tenet-layout
description: |
  Invoke this skill when a user is structuring a new Go application or reorganizing an
  existing one and asks about package layout, directory structure, or how to prevent
  circular imports. Trigger signals include: "how should I organize my Go packages?",
  "I keep getting import cycle errors", "where should I put my models/types?",
  "how do I structure my Go project?", or "should I use models/, handlers/, controllers/
  directories?" Also activate when a user has functional-grouping packages (models/,
  handlers/, services/) and is hitting circular dependency errors.

  Not suitable for: questions about individual file organization within a package,
  Go module setup (go.mod), questions about code formatting or style, or architecture
  decisions that are purely about business logic with no package structure dimension.

  Key trigger: user is deciding where code lives across multiple packages — especially
  when they ask about "structure" or when they describe a circular import error.
tags: [package-layout, architecture, domain-design, go, dependency-management]
---

# Four-Tenet Domain-First Package Layout

## R — Original Text (Reading)

> "The package strategy that I use for my projects involves 4 simple tenets:
>
> 1. Root package is for domain types
> 2. Group subpackages by dependency
> 3. Use a shared mock subpackage
> 4. Main package ties together dependencies
>
> These rules help isolate our packages and define a clear domain language across
> the entire application."
>
> "Your root package should not depend on any other package in your application! I
> place my domain types in my root package. This package only contains simple data
> types like a User struct for holding user data or a UserService interface for
> fetching or saving user data."
>
> — Ben B. Johnson, *standard-package-layout.md*

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Most Go developers organize packages by function type (models/, handlers/, services/) — the same way Ruby or Java code is organized. This fails in Go because the compiler forbids circular imports, and function-type packages inevitably import each other, creating cycles.

Johnson's solution is a four-rule architecture built around a single principle: **the domain sits at the bottom; everything depends on it; nothing depends on anything except the domain.**

The four tenets work together as a system:

1. **Root package = domain only.** The root package (named after your application, e.g. `myapp`) holds only plain structs and interfaces: `User`, `Order`, `UserService`. It has **zero external imports** — no database drivers, no HTTP libraries, no third-party code. If you add an external import to the root package, you've broken the system.

2. **Subpackages = one dependency each.** Every subpackage wraps exactly one external dependency: `sqlite/`, `postgres/`, `http/`, `stripe/`, `twilio/`. Each subpackage implements one or more interfaces from the root package. The naming convention (`postgres.UserService` implementing `myapp.UserService`) makes the adapter relationship explicit.

3. **A shared `mock/` subpackage** contains hand-written stub implementations of every root-package interface. Stubs are simple structs with function fields: `UserFn func(id int) (*myapp.User, error)`. Any test file anywhere in the project imports `mock/` and injects the stub — no code generation, no reflection.

4. **`cmd/<binary>/main.go` is the only wiring point.** The main package is where concrete implementations get injected into interfaces. It is the sole adapter between the OS/terminal and the domain. Business logic never lives here — only wiring.

The structural consequence: you can swap any infrastructure layer (change the database, add a cache, replace the HTTP framework) by writing a new subpackage that implements the domain interface. The domain code, the mock/ tests, and the other subpackages are untouched.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: WTF Dial — Postgres/SQLite and HTTP in One Application

- **Question:** Johnson needed a production Go web application (WTF Dial) with a SQLite database, an HTTP layer, and WebSocket support. The initial naive layout had http/ importing sqlite/ directly.
- **Use of methodology:** Applied the four tenets: created a `wtf` root package with `Dial`, `User`, `DialService`, `UserService` domain types. Created `sqlite/` and `http/` as separate subpackages both depending on `wtf`. Created `mock/` with `DialService` and `UserService` mock structs. Wired everything in `cmd/wtfd/main.go`.
- **Conclusion:** http/ no longer imports sqlite/ — both depend only on `wtf`. HTTP handler tests inject mock services without touching the database. Swapping storage requires no changes to the HTTP layer.
- **Result:** The complete WTF Dial application (publicly available at github.com/benbjohnson/wtf) demonstrates the layout at production scale.

### Case 2: Rails-Style Layout Failure (Motivating Counter-Case)

- **Question:** Johnson (and many Go developers migrating from Rails) initially organized Go apps with models/, handlers/, controllers/ packages.
- **Use of methodology:** Tried to apply Rails grouping conventions to Go.
- **Conclusion:** Names stuttered (controller.UserController), and circular dependencies appeared as soon as handlers needed models and models needed services and services needed helpers that referenced handlers.
- **Result:** The layout is not fixable without architectural restructuring. The four-tenet system was developed specifically to avoid this outcome.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A developer starting a new Go web service asks how to structure their project — where to put database code, API handlers, and business logic.
2. A developer hits `import cycle not allowed` and can't figure out how to break the cycle without introducing a messy third package.
3. A developer working from a Rails, Django, or Spring background has organized their Go code with models/, controllers/, services/ packages and is asking why it doesn't feel right.
4. A developer wants to unit-test HTTP handlers without spinning up a real database, but their handler imports the database package directly.
5. A developer asks "should my interface be in the package that implements it or the package that uses it?"

### Language Signals

- "I'm getting circular import errors in my Go project"
- "Where should I put my models / types / structs?"
- "How do I organize a Go project with a database and HTTP layer?"
- "My handlers depend on my repository which depends on my models which depends back on handlers"
- "I want to test without a real database — how?"
- "Should I use a models/ package?"

### Distinguishing from Adjacent Skills

- Difference from `go-beyond-packages-as-layers`: Four-Tenet Layout is the *actionable system* (what to do); Packages as Layers is the *mental model* (why). Use this skill when the user needs a structural answer; use Packages as Layers when they need to understand the underlying reasoning.
- Difference from `go-beyond-interface-consumer-ownership`: This skill covers where packages live and how they relate. Interface Consumer Ownership covers specifically who defines the interface. They compose: tenet 1 (root package for interfaces) + Interface Consumer Ownership (caller defines them) work together.

______________________________________________________________________

## E — Execution Step

1. **Audit the root package — is it clean?**

   - Ask: does the root package import any external library or any subpackage within this project?
   - If yes: identify which types/interfaces need to move in or out to make the root zero-dependency.
   - Completion: root package `go list -deps` shows only stdlib + the root package itself.

2. **Name subpackages after their external dependency, not after their role.**

   - Rename models/ → the-actual-db-name/ (e.g. `postgres/`); rename handlers/ → `http/`; rename services/ → remove (services belong in the root as interfaces).
   - Each subpackage should satisfy at least one interface defined in the root package.
   - Completion: every non-root, non-cmd, non-mock subpackage name matches the external dependency it wraps.

3. **Create or locate the `mock/` subpackage.**

   - For each interface in the root package, add a corresponding struct to `mock/` with function fields matching each method.
   - Add an `Invoked bool` field for each method if call tracking is needed.
   - Completion: any test that needs to inject a fake implementation imports `mock/` rather than writing its own struct.

4. **Confine all wiring to `cmd/<binary>/main.go`.**

   - If any package other than main constructs concrete implementations and injects them into interfaces, move that wiring to main.
   - Completion: `grep -r "sqlite.New\|postgres.New\|http.NewServer" .` returns results only inside `cmd/`.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Microservices with separate repositories:** If each service is its own repository, apply the tenets within each service independently. Do not create a shared root package across service boundaries — that re-introduces the monolith coupling this system is designed to avoid.
- **Very small scripts or single-file programs:** A program under ~500 SLOC with one external dependency doesn't need the full four-tenet system. The overhead of separate subpackages adds friction without benefit at that scale.
- **Existing large codebases mid-refactor:** Applying all four tenets simultaneously to a large existing codebase is disruptive. Use the tenets as a migration target, not an immediate requirement.

### Failure Patterns Warned About in the Book

- **Rails-style layout (ce02, ce03):** models/, handlers/, controllers/ produces naming stutter (`controller.UserController`) and circular dependencies when any two function-type packages reference each other.
- **Module-grouping layout (ce04):** users/, orders/, accounts/ produces the same stutter and circular dependencies as Rails-style when domain modules reference each other.
- **Direct http → database import (ce05):** When http/ imports sqlite/ directly, HTTP tests require a real database, and swapping the database engine requires touching the HTTP layer.
- **Over-splitting by file count (ce14):** Creating new subpackages to manage file count (instead of dependency isolation) produces cycles and a maze of micro-packages.

### Author's Blind Spots / Limitations of the Era

- **Small team assumption:** The root package as the single home for all domain types creates a merge contention bottleneck when multiple teams modify the domain simultaneously. For large teams, consider domain sub-grouping (still zero-external-deps, but with sub-namespaces).
- **Pre-generics design (Go 1.17 and earlier):** Some patterns (mock structs, filter objects) would simplify with generics (Go 1.18+). The function-field mock pattern is more verbose than a generic `MockFunc[T]` would be.
- **Single-application assumption:** The four-tenet layout assumes one application (or one service). Multi-service monorepos with shared domain types across services require adaptation.

### Easily Confused Proximity Methodology

- **Hexagonal Architecture / Ports & Adapters:** Johnson's layout implements a similar idea (domain in the center, adapters on the outside) but with Go-specific mechanics (no circular imports, implicit interface satisfaction). The tenets are a Go-idiomatic instantiation, not a direct copy.
- **Clean Architecture layers:** Similar directional layering, but Johnson's version is flatter (no use-case layer, no separate interface layer) and designed specifically for Go's package system constraints.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: go-beyond-packages-as-layers — layers model is the conceptual foundation for the four-tenet structure
- composes-with: go-beyond-three-consumer-error — error type lives in the root package per tenet 1
- composes-with: go-beyond-service-transaction-boundary — tenet 2 (subpackages as adapters) is where transaction boundaries live

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: See test-prompts.json
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Go Beyond" Ben B. Johnson
