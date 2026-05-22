---
name: dep-comp-cross-package-contract-decision
description: |
  Invoke this skill when a Go developer is deciding how two packages should
  share a type or contract without one importing the other's concrete type.
  The trigger is any question of the form: "my two packages both need a
  struct — where should it live?" or "should I extract this type to a shared
  package?" or "how do I avoid importing package X just to use one field?"

  The skill provides a four-option decision framework. Default to
  function-typed fields for single-operation dependencies. Use a local
  interface for multi-method contracts or third-party insulation. Use a
  shared package only when confident types will NEVER diverge. Use duplicate
  types + adapter when uncertain about divergence — merging separated types
  later is cheap; pulling apart merged types with many callers is expensive.

  Do NOT invoke when the question is whether to use dependency injection at
  all — that is dep-comp-function-first-composition. Do NOT invoke for
  non-Go languages; Go's structural interface typing is the mechanism that
  makes options 1 and 4 work without ceremony.

  Key trigger signals: "should I extract this to a shared package?", "my
  types package is getting huge", "how do I avoid import cycles?", "should
  I define an interface or use the concrete type?", "my billing package
  needs the User type from auth".
source_book: '"Dependency Composition (Go Adaptation)" by Daniel Somerfield (2023, updated 2026)'
source_chapter: Type Exposure Decision Framework
tags: [go, dependency-injection, interfaces, type-design, package-design, coupling, architecture]
related_skills:
  - dep-comp-function-first-composition  # prerequisite: this skill assumes you already use Dependencies structs; the cross-package contract arises once two packages share types
---

# Cross-Package Contract Decision: Four Options for Sharing a Type Between Go Packages

## R — Original Text (Reading)

> **When you need a contract that a caller can hold without importing the callee's concrete type, you have four options:**
>
> 1. **Local interface**: Define a narrow interface in the caller's package, containing only the methods the caller needs. Any type from any package satisfying those methods works without the callee knowing the interface exists.
> 2. **Shared package**: Extract to a common package (e.g., `domain`). Use when the type is a genuinely universal domain concept that appears by name in acceptance criteria.
> 3. **Duplicate types + adapter**: Define the type separately in each package; write an adapter function at the seam.
> 4. **Function-typed fields**: Rather than a method interface, express the dependency as a `func(...)` field in a Dependencies struct.
>
> "In this case, I am not confident that these types are literally the same. They might be different projections of the same domain entity with different fields, and I don't want to share them across the package boundaries risking deeper coupling... collapsing the entities is very cheap and easy at this point. If they begin to diverge, I probably shouldn't merge them anyway, but pulling them apart once they are bound can be very tricky."
>
> "The test for 'should this be shared?' is: if two packages have structurally identical types and you are confident they will always be structurally identical, the duplicate is pure noise. If you are not confident, keep them separate."

— Daniel Somerfield, *Dependency Composition (Go Adaptation)*, Type Exposure Decision Framework

## I — Methodological Framework (Interpretation)

The core problem is **incidental coupling**: relationships between packages that increase fragility without reflecting a genuine domain constraint. When two packages import a shared concrete type, a change to that type affects every importer — even those whose logic is unrelated to the changed field. The four options represent four different ways to share a contract while keeping incidental coupling low.

### The Four Options and When to Use Each

## Option 1: Local Interface

The caller's package defines a narrow interface containing only the methods it needs. Because Go interfaces are satisfied implicitly, any type from any package — including third-party types — satisfies the interface without the provider knowing the interface exists.

```go
// In package controller — defined by the caller, not the provider
type RestaurantLister interface {
	ListTopRated(ctx context.Context, city string, n int) ([]Restaurant, error)
}
```

Use when:

- The consumer needs a multi-method contract (more than one method call on the dependency).
- You are insulating from a third-party concrete type (so you can swap implementations without changing callers).
- You want to test with a hand-written stub that implements only the methods you use.

## Option 2: Shared Package

Extract the type to a package both sides can import (e.g., `domain`, `types`). Both packages refer to the same struct.

Use when:

- The type is a genuinely universal domain concept — it appears by name in acceptance criteria, sprint tickets, or the ubiquitous language of the domain.
- You are **confident** the type will always be structurally identical across every package that uses it.
- Examples: `Rating` (a typed constant representing a star rating), `UserID` (a typed identifier referenced by every layer).

## Option 3: Duplicate Types + Adapter

Define structurally similar (or identical) types independently in each package. Write an adapter function at the boundary that converts from one to the other.

```go
// In package toprated
type Restaurant struct {
	ID     string
	Rating float64
}

// In package controller
type Restaurant struct {
	ID   string
	Name string
}

// Adapter function at the seam (in controller or a dedicated adapter package)
func toControllerRestaurant(r toprated.Restaurant) Restaurant {
	return Restaurant{ID: r.ID}
}
```

Use when:

- The types are currently identical but you are **not confident** they will stay identical — each package may need different fields as the system evolves.
- Different layers represent different projections of the same domain entity (the controller's Restaurant carries a `Name` for JSON rendering; the domain's Restaurant carries only fields needed for sorting by rating).
- You want the freedom to evolve each layer independently without cascading changes.

## Option 4: Function-Typed Fields

Express the dependency as a `func(...)` field in a `Dependencies` struct. No interface, no concrete type shared — just a function signature.

```go
type Dependencies struct {
	GetTopRestaurants func(ctx context.Context, city string) ([]Restaurant, error)
}
```

Use when:

- The dependency is a **single operation** (one function call).
- You want compile-time checking without any interface declaration ceremony.
- Tests can wire inline function literals directly.

This is the default for single-operation dependencies. Only escalate to option 1 (local interface) if you need multiple methods on the same object, or to option 2/3 if a struct type must cross the boundary.

### The Divergence Confidence Test

The critical decision is option 2 vs. option 3. Apply this test: **"Will these two types always be structurally identical?"**

- **Yes, I am certain** → option 2 (shared package). The duplication is pure noise.
- **Uncertain** → option 3 (duplicate + adapter). The asymmetry matters:
  - Merging two separated types is cheap: add an import, update one call site per package, delete the local type.
  - Separating a shared type used by many packages is expensive: find all callers, determine which projection each needs, create divergent types, write adapters, update every import.

When in doubt, keep them separate. The adapter is a small upfront cost; re-entangling is a large deferred cost.

### Decision Heuristic (Summary)

```text
Single-operation dependency?
  → Option 4 (function-typed field)

Multi-method contract, or insulating a third-party type?
  → Option 1 (local interface)

Struct type must cross the boundary AND types will NEVER diverge?
  → Option 2 (shared package)

Struct type must cross the boundary AND uncertain about divergence?
  → Option 3 (duplicate types + adapter)
```

## A1 — Past Application (From the Book)

### Case 1: `Restaurant` in Controller and Toprated Packages

**Problem**: The HTTP controller package and the toprated domain package both work with a "restaurant" concept. The naïve approach is to define `Restaurant` once in a shared package and import it everywhere.

**Method**: Somerfield chose option 3 (duplicate types + adapter). The controller's `Restaurant` carries a `Name` field for JSON rendering; the domain's `Restaurant` carries only fields needed for sorting by rating. These packages represent different layers with different concerns — they will likely need different projections as requirements evolve. A `toRestaurant()` adapter function converts between them at the seam.

**Conclusion**: Even though the two structs looked identical at the time, the author was not confident they would stay identical. The cost of duplication was low; the cost of premature sharing would be borne every time one layer needed a field the other did not.

**Result**: Each package owns its `Restaurant` type. The adapter lives at the boundary and is the only place that knows about both packages' shapes. Changes to one package's `Restaurant` don't cascade to the other.

______________________________________________________________________

### Case 2: `RestaurantRating` in Toprated and Ratingsalgorithm Packages

**Problem**: Two packages — the toprated domain and the ratings algorithm — both represent a "restaurant with a rating" as a struct. They are structurally identical at the time of writing.

**Method**: Option 3 again (kept separate). The two packages occupy different layers of the system: one is a domain orchestration layer, the other is a calculation engine. As the system evolves, each might need different projections — the algorithm might need raw input fields; the domain layer might need computed metadata.

**Conclusion**: Structural identity at a point in time is not sufficient evidence for confident permanence. Two packages at different architectural layers are likely to diverge.

**Result**: Each package defines its own `RestaurantRating` struct. No shared import between them; conversion happens at the layer boundary.

______________________________________________________________________

### Case 3: `Rating` Typed Constant Promoted to Shared Package

**Problem**: The `Rating` type (e.g., a `float64` alias representing a star rating from 0.0 to 5.0) was independently defined in multiple packages. Unlike `Restaurant`, this concept is explicitly named in acceptance criteria and appears uniformly across the entire domain.

**Method**: Option 2 (shared package). The `Rating` type is a universal domain concept that is definitionally identical everywhere it appears. There is no scenario in which the billing layer's `Rating` and the display layer's `Rating` would need different representations — they mean the same thing.

**Conclusion**: The divergence confidence test passes: "Will these always be structurally identical?" Yes — `Rating` is a scalar value type with no fields to diverge.

**Result**: `Rating` lives in a `domain` package. All packages import it. Changes to `Rating`'s definition (e.g., adding validation) propagate correctly everywhere.

## A2 — Trigger Scenario (Future Trigger) ★

1. **"Should I define an interface or just use the concrete type?"**
   Start with option 4 (function-typed field) if the dependency is a single operation. If you need multiple methods, define a local interface in the caller's package (option 1). Never let the provider define the interface — the caller defines what it needs.

2. **"Two of my packages need the same struct — should I extract it to a shared package?"**
   Apply the divergence confidence test. Are you certain both packages will always use the same fields? If yes, extract (option 2). If there is any doubt — different layers, different projections, evolving requirements — keep them separate and write a small adapter (option 3).

3. **"My `types` package is getting huge and everything depends on it."**
   This is the premature-shared-types failure mode. The `types` package has become a coupling hub. Identify which types are genuinely universal domain concepts (candidates for a `domain` package) and which are incidentally co-located. For the incidental ones, migrate to option 3 (duplicate + adapter) or option 4 (function field), eliminating the import of `types` package by package.

4. **"How do I avoid import cycles in Go?"**
   Import cycles are often a symptom of incidental coupling. If `package A` imports `package B` for a type, and `package B` imports `package A` for another type, neither can import the other. Break the cycle using option 1 (define a local interface in the caller's package — no import needed), option 3 (duplicate the type and adapt at the boundary), or option 4 (replace the type dependency with a function field). The cycle disappears because the caller no longer imports the provider for a concrete type.

5. **"My billing package needs to use the `User` type from the auth package."**
   Ask what the billing package actually needs from `User`. If it needs only one operation (e.g., look up a user's payment method), use option 4 (function field — no `User` import at all). If it needs to pass a `UserID` scalar, consider option 2 (shared `domain.UserID`). If it needs a subset of `User` fields, use option 3 (define `billing.User` with only the fields billing needs, write an adapter at the boundary).

### Language Signals

- "Should I define an interface or just use the concrete type?"
- "Two of my packages need the same struct — should I extract it?"
- "My types package is getting huge and everything depends on it"
- "How do I avoid import cycles in Go?"
- "My billing package needs to use the User type from the auth package"
- "Where should I define this shared type?"
- "Should I put this in a common package?"
- "I keep getting import cycle errors"
- "My packages all depend on the same models package"

### Distinguishing from Adjacent Skills

- **dep-comp-function-first-composition**: Addresses whether to use dependency injection via function-typed fields at all — the foundational pattern. This skill assumes you are already structuring dependencies as `Dependencies` structs and addresses the narrower question of how a struct type should cross a package boundary.

- **Standard Go interface injection**: The local interface option (option 1) is related to standard Go interface-based injection but differs in direction: the caller defines the interface, not the provider. If you see a provider package defining `type XxxInterface interface {...}` for callers to reference, that is the provider-defines-interface anti-pattern this skill corrects.

## E — Execution Steps

## Step 1: Identify Whether the Cross-Boundary Dependency Is a Single Operation or Multi-Method

If the caller needs only one function call on the dependency (e.g., "fetch top restaurants"), proceed to Step 2. If it needs to call multiple methods on the same object (e.g., a repository with `FindByID`, `Save`, `Delete`), proceed to Step 3.

## Step 2: Single-Operation Dependency — Use a Function-Typed Field (Option 4)

Replace any concrete type import with a function field in the caller's `Dependencies` struct:

```go
// In package controller
type Dependencies struct {
	// No import of toprated package needed
	GetTopRestaurants func(ctx context.Context, city string) ([]Restaurant, error)
}
```

Wire the real implementation in `main.go`:

```go
// In main.go
controllerDeps := controller.Dependencies{
	GetTopRestaurants: topRatedService.GetTop, // method value — bound at wire time
}
```

Test with an inline function literal:

```go
deps := controller.Dependencies{
	GetTopRestaurants: func(ctx context.Context, city string) ([]Restaurant, error) {
		return []controller.Restaurant{{ID: "r1", Name: "Test"}}, nil
	},
}
```

Completion criterion: the caller's package has no import of the provider's package. `go list -deps ./controller/...` does not include the provider package.

## Step 3: Multi-Method Dependency or Third-Party Insulation — Use a Local Interface (Option 1)

Define the interface in the **caller's** package, not the provider's:

```go
// In package controller — caller defines what it needs
type RestaurantRepository interface {
	FindByCity(ctx context.Context, city string) ([]Restaurant, error)
	FindByID(ctx context.Context, id string) (Restaurant, error)
}

type Dependencies struct {
	Restaurants RestaurantRepository
}
```

Do not add `RestaurantRepositoryInterface` or any named interface to the provider package. The provider simply implements the methods; Go's structural typing makes it satisfy the interface automatically.

Completion criterion: the interface definition lives in the caller's package. The provider package has no knowledge of the interface name.

## Step 4: Struct Type Must Cross the Boundary — Apply the Divergence Confidence Test

Ask: "Will these two types always be structurally identical?" Write your answer down.

- If **yes, certain**: extract to a shared `domain` package (option 2). Both packages import `domain.X`.
- If **uncertain or no**: define the type separately in each package and write an adapter (option 3).

For option 3:

```go
// toprated/restaurant.go
type Restaurant struct {
	ID     string
	Rating float64
}

// controller/restaurant.go
type Restaurant struct {
	ID   string
	Name string
}

// controller/adapter.go — the only file that knows both shapes
func toControllerRestaurant(r toprated.Restaurant, name string) Restaurant {
	return Restaurant{ID: r.ID, Name: name}
}
```

Completion criterion: each package's type is defined in that package. The adapter function is the only location that imports both packages.

## Step 5: Verify No Coupling Hub Is Forming

Run `go list -f '{{.ImportPath}}: {{join .Imports " "}}' ./...` and inspect for any package that appears as a dependency of five or more other packages. If a `types`, `models`, or `common` package is in that list, evaluate each type using Step 4 and migrate incidental shared types away from it.

## B — Boundary ★

## When the Concern Is Less Acute

- **Scalar value types** (typed `int`, `float64`, `string` aliases like `type UserID string`): These have no fields to diverge. The divergence confidence test almost always passes. Option 2 (shared package) is the right choice. Duplication of a scalar type is pure noise.

- **Standard library types** (`time.Time`, `net/http.Request`, etc.): These are already implicitly shared via the standard library. No decision needed; import them directly.

- **Small, fully internal packages**: If both packages live in the same module and there is no possibility of independent deployment or third-party consumers, the coupling cost of option 2 is low. The divergence risk is the deciding factor, not the import itself.

## Failure Patterns

- **Premature shared `types` or `models` package**: Teams default to creating a `types.go` or `models/` package containing all shared structs. Every package imports it. Any change to any type — even adding an optional field — forces recompilation of every importer and may require updates across the entire codebase. The `types` package becomes a coupling hub where incidental coupling is invisible until it is very expensive to remove. Diagnosis: if `go list -deps ./...` shows `types` or `models` imported by more than half your packages, you have a coupling hub.

- **Provider defines the interface**: A provider package defines `type EmailSenderInterface interface { Send(...) error }` and exports it for callers to reference. This is backwards. The provider cannot know all the narrow contracts its callers will need. Callers end up importing the provider's package just to reference the interface — creating exactly the import dependency the interface was meant to avoid. The caller must define what it needs; the provider simply implements it.

- **Adapter in the wrong package**: Writing the adapter function inside the provider's package requires the provider to import the caller (creating a cycle) or to know about the caller's types (creating coupling in the wrong direction). The adapter belongs at the boundary — in the caller's package or in a dedicated adapter package that imports both.

- **Promoting types to shared package under schedule pressure**: When a deadline is approaching, teams share types "just for now" to avoid writing adapters. This short-circuits the divergence confidence test. The deferred cost is paid when one package needs a new field and every other importer must be updated or the shared type becomes bloated with fields only relevant to one consumer.

## Author Blind Spots

- **Scale threshold**: Somerfield's worked example is a 3-layer, ~5-type service. In a large monorepo with 50+ packages and 100+ types, the "duplicate types" approach multiplies the number of adapter functions significantly. The author does not address at what scale option 2 (shared domain package) becomes the practical default despite divergence risk, simply because the adapter maintenance cost exceeds the coupling cost.

- **Generated types** (protobuf, OpenAPI, database schema): These types are already shared by definition — they come from an external contract. Options 3 and 4 are still applicable at the boundary between generated types and your domain types, but the author does not discuss generated code as a distinct case.

- **Merging is not always cheap**: The claim "collapsing separated types is cheap" holds when you control all call sites. In a public API or a plugin interface, separated types cannot be merged without a breaking change. The author's assumption of a closed codebase is implicit but not stated.

## Related Skills

- **dep-comp-function-first-composition** (prerequisite): Establishes the `Dependencies` struct pattern and function-typed fields as the foundational approach to dependency injection in Go. This skill extends that pattern to address how struct types cross package boundaries once the function-field default is established.

## Audit Information

- Source extraction date: 2026-05-05
- Primary source: `/Users/steve/Documents/agent-orange/bookSource/misc/dependency-composition.md`
- Book overview: `/Users/steve/Documents/agent-orange/books/dependency-composition/BOOK_OVERVIEW.md`
- Cases used: Restaurant (option 3), RestaurantRating (option 3), Rating (option 2) — from Type Exposure Decision Framework section
- Counter-examples used: premature shared types package, provider-defines-interface anti-pattern
- Pipeline stage: Phase 2 (RIA++)
- Version: 0.1.0
