---
name: go-beyond-packages-as-layers
description: |
  Invoke this skill when a user is confused about WHY circular imports happen in Go,
  or when they understand the error but not the mental model needed to prevent it
  structurally. Also invoke when a user is asking "why can't I have these two packages
  import each other?" or when they're trying to reason about Go package design from a
  perspective shaped by Ruby, Java, Python, or JavaScript module systems.

  Trigger signals: "I keep getting circular import errors and don't understand why",
  "how are Go packages different from Python modules?", "why does Go prevent circular
  dependencies?", "I can't seem to get my package structure right — everything depends
  on everything else", or any situation where the user is debugging import graph
  problems rather than just applying a fix.

  Not suitable for: users who already understand the layers model and just need the
  four-tenet layout recipe (use go-beyond-four-tenet-layout instead); performance
  questions; build system questions.

  Key trigger: the user needs the conceptual WHY, not just the structural WHAT.
source_book: "Go Beyond" Ben B. Johnson
source_chapter: packages-as-layers.md
tags: [mental-model, package-layout, circular-dependencies, go, architecture]
related_skills: []
---

# Packages as Layers Mental Model

## R — Original Text (Reading)

> "Nearly all programming languages have a mechanism for grouping related functionality
> together. Ruby has gems, Java has packages. Those languages don't have a standard
> convention for grouping code because, honestly, it doesn't matter. It all comes down
> to personal preference. However, developers that transition to Go are surprised by how
> often their package organization comes back to bite them. Why are Go packages so
> different from other languages? It's because they're not groups — they're layers."
>
> "After understanding the logical layers of your application, you can extract data types
> & interface contracts for your business domain and move them into your root package to
> serve as a common domain language for all subpackages."
>
> — Ben B. Johnson, *packages-as-layers.md*

______________________________________________________________________

## I — Methodological Framework (Interpretation)

In Ruby, Java, and most other languages, packages are **containers** — folders for grouping related files. The grouping is arbitrary; "related" is a judgment call; and packages can freely import each other in any direction because the language permits it.

Go packages are different in one decisive way: **circular imports are a compile error.** This single constraint transforms packages from containers into **layers**.

A layer is directional. Lower layers don't know about higher layers. The standard library demonstrates this:

- `io` (at the bottom) knows nothing about `net`
- `net` builds on `io`
- `net/http` builds on `net`
- Nothing reaches back downward — `io` does not import `net`

When developers treat Go packages as groups and hit circular import errors, they are experiencing the consequence of that category error. The compiler is not being difficult; it's enforcing the physics of layered architecture.

**The diagnostic question:** When you see a circular import error, ask: "Which package is trying to reach upward into a package that depends on it?" That upward reach is the error. The fix is not to introduce a third package or use `interface{}` to break the cycle — it's to identify which type or interface belongs in the *lower* layer and move it there.

**The application to Go code:** For any application:

- The domain types (User, Order, Event) and interface contracts (UserService, EventStore) belong at the lowest layer — the root package, which depends on nothing.
- Infrastructure adapters (postgres/, http/, redis/) sit above it, depending on the root.
- The main package sits at the top, depending on everything, known by nothing.

The mental model predicts the layout. Every time you feel the urge to create a new package, ask: "What layer does this belong in, and what may it depend on?" — not "what category does this belong in?"

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Standard Library as a Layers Demonstration

- **Question:** How do you explain Go's package system to developers from other languages in a way that makes the constraint feel natural rather than arbitrary?
- **Use of methodology:** Johnson points to the standard library itself: `io` → `net` → `net/http` is the canonical example of correct layering. Each layer adds abstraction; none reaches backward. This is not a convention enforced by the Go team — it falls out naturally from the no-circular-dependency rule.
- **Conclusion:** The standard library structure is the model to imitate. Application packages should form the same directed graph.
- **Result:** This concrete example makes the abstract concept tangible without requiring familiarity with any specific application architecture.

### Case 2: WTF Dial — Fixing the Direct Http → Sqlite Dependency

- **Question:** In the WTF Dial application, the initial layout had `http/` importing `sqlite/` directly (to get access to domain types like `User`). This tied the HTTP layer to a specific database engine.
- **Use of methodology:** Applied the layers model: `http/` and `sqlite/` are both at the same layer (infrastructure adapters). They should not depend on each other. The fix is to identify what `http/` actually needs (the `DialService` interface) and move that to the bottom layer (root `wtf` package). Now `http/` depends on `wtf`; `sqlite/` depends on `wtf`; neither depends on the other.
- **Conclusion:** The dependency graph collapsed from vertical (http → sqlite → wtf) to flat (http → wtf ← sqlite), with `wtf` as the hub.
- **Result:** HTTP tests can inject a mock instead of a SQLite database. Swapping storage backends requires no changes to the HTTP layer.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A Go developer from a Ruby/Python/Java background organizes code into functional groups (models/, services/, handlers/) and hits circular import errors when the groups reference each other.
2. A developer asks "why does Go not allow circular imports?" and wants a conceptual answer, not just a workaround.
3. A developer is trying to add a new package but can't figure out where to place it without breaking the import graph.
4. A developer has used `interface{}` or moved types to a third "shared" package to break a cycle, and the workaround has made things more confusing.
5. A code review surfaces a comment like "this package imports the package that imports it" and the developer needs to explain why this is a problem and how to fix it structurally.

### Language Signals

- "Why can't package A and package B import each other?"
- "I keep getting 'import cycle not allowed'"
- "In Python/Ruby I could just import whatever I needed — why is Go so strict?"
- "I created a shared/ or common/ package to break the cycle but now everything imports that"
- "My package graph is a mess — how do I untangle it?"
- "How do Go packages work differently from [other language]?"

### Distinguishing from Adjacent Skills

- Difference from `go-beyond-four-tenet-layout`: Packages as Layers is the *why* (the mental model); Four-Tenet Layout is the *what* (the specific recipe). If the user needs to understand the reasoning, use this skill. If they just need instructions on how to structure their project, use Four-Tenet Layout. In practice, both are often invoked together.
- Difference from `go-beyond-interface-consumer-ownership`: Packages as Layers explains the directional dependency graph. Interface Consumer Ownership explains who defines the seam between layers. Different concerns that complement each other.

______________________________________________________________________

## E — Execution Step

1. **Identify the existing package dependency direction.**

   - Ask: for each package pair (A, B) where A imports B, does B ever import A (directly or transitively)?
   - If yes: this is a layer violation — two "same-level" packages are treating each other as groups.
   - Completion: can draw the import graph as a directed acyclic graph (DAG) with no cycles.

2. **Find the type or interface causing the upward reach.**

   - The circular import almost always exists because a type that Package A needs lives in Package B, and Package B also needs something from Package A.
   - Ask: what is the type or interface that both packages need? That type belongs at a *lower* layer.
   - Completion: identified the specific type/interface that needs to move.

3. **Move the shared type/interface to the layer both packages depend on.**

   - If both packages are infrastructure adapters, the shared type belongs in the root/domain package.
   - If one package is lower-level than the other, the type belongs in the lower-level package.
   - Do not create a new "shared" or "common" package — that is treating packages as groups again. Move to an *existing* lower layer.
   - Completion: circular import error gone; both packages depend on the lower layer; neither depends on the other.

4. **Verify the layer invariant holds.**

   - The root/domain package must have zero external imports.
   - Infrastructure subpackages may only import the root package + their own external dependency.
   - The main package is the only package that imports concrete implementations.
   - Completion: `go build ./...` passes; the import graph is a DAG pointing toward the root.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The user understands the model and needs the layout recipe:** If they already understand layers vs. groups, skip to `go-beyond-four-tenet-layout` for the actionable structure.
- **Package naming or style questions:** This mental model is about import direction, not naming conventions.
- **Module-level (go.mod) dependency management:** Layers are an intra-module concept. Multi-module setups have different concerns.

### Failure Patterns Warned About in the Book

- **Creating a "shared", "common", or "util" package to break cycles or consolidate helpers (ce03, ce04):** This doesn't fix the category error — it just adds another group. Generic utility packages have the same layering problem as models/ or handlers/ — they inevitably accumulate types that need to reference each other or the domain. The correct action: absorb pure-function utilities into the root package (they have no external deps, so no cycle risk), or name adapter subpackages after the specific dependency they wrap. Never create a package named "util", "common", or "shared". The types in the shared package end up needing to import from the packages that use them, recreating the problem one level down.
- **Using `interface{}` to pass data across package boundaries to avoid import cycles:** This breaks type safety and makes the code harder to understand. It's a symptom of layers being treated as groups.
- **Over-splitting into many small packages based on file count (ce14):** Creates a package mesh with constant cycle risk. Packages should be split by dependency isolation, not by file count.

### Author's Blind Spots / Limitations of the Era

- **The model applies within a single application:** In microservices, each service is its own repository with its own domain layer. The layers model doesn't prescribe inter-service dependency direction — that's a different problem (network calls, contracts, versioning).
- **Some legitimate peer-level packages exist:** Test utilities, protocol implementations, and some library packages genuinely need to be at the same layer without a clear hierarchy. The model handles 90% of application code; edge cases exist.

### Easily Confused Proximity Methodology

- **Onion Architecture / Hexagonal Architecture:** These describe similar directional layering but come with prescribed layer names (Domain, Application, Infrastructure, Presentation) and stricter coupling rules. The Packages as Layers model is simpler and Go-native: it prescribes only the direction (dependencies point inward/downward toward the domain), not specific named layers.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- composes-with: [go-beyond-four-tenet-layout](../go-beyond-four-tenet-layout/SKILL.md) — the four tenets are the actionable recipe built on this mental model

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: See test-prompts.json
- **Distillation Time**: 2026-05-05
