---
name: fowler-branch-by-abstraction
description: |
  Invoke this skill when a team needs to replace a library, framework, or large structural component that is used in many places across a production codebase — and cannot freeze the codebase or do the replacement in a single commit.

  Key trigger signal: "We need to replace X across N call sites while the service keeps running" or "We can't take a feature freeze to migrate away from this library."

  This skill is specifically about the code-level strategy of introducing an abstraction layer to enable incremental, never-broken migration. It is NOT about git branching strategy (despite the confusable name), and it is NOT primarily about database schema migration (use fowler-database-parallel-change for that, though the same principle applies).

  Do NOT invoke this skill for small refactorings that fit in a single commit or a single session — use fowler-opportunistic-refactoring for those. Do NOT invoke for keeping refactoring and feature work separated in a session — use fowler-two-hats for that.
source_book: 'Refactoring: Improving the Design of Existing Code — Martin Fowler (2018)'
source_chapter: Chapter 2
tags: [refactoring, architecture, migration, abstraction]
related_skills:
  - slug: fowler-database-parallel-change
    relation: composes-with
  - slug: fowler-opportunistic-refactoring
    relation: composes-with
  - slug: fowler-yagni-refactoring
    relation: contrasts-with
---

# Branch by Abstraction — Incremental Large-Scale Refactoring

## R — Original Text (Reading)

> Most refactoring can be completed within a few minutes—hours at most. But there are some larger refactoring efforts that can take a team weeks to complete. Perhaps they need to replace an existing library with a new one. Or pull some section of code out into a component that they can share with another team. Or fix some nasty mess of dependencies that they had allowed to build up.
>
> Even in such cases, I'm reluctant to have a team do dedicated refactoring. Often, a useful strategy is to agree to gradually work on the course of the next few weeks. Whenever anyone goes near any code that's in the refactoring zone, they move it a little way in the direction they want to improve. This takes advantage of the fact that refactoring doesn't break the code—each small change leaves everything in a still-working state. To change from one library to another, start by introducing a new abstraction that can act as an interface to either library. Once the calling code uses this abstraction, it's much easier to switch one library for another. (This tactic is called Branch By Abstraction [mf-bba].)
>
> — Martin Fowler, Chapter 2

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Branch By Abstraction is a four-phase technique for replacing a widely-used component — a library, a framework, a subsystem — across a large codebase, in a live production environment, without ever leaving the code in a broken state.

The four phases are:

1. **Introduce the abstraction.** Create a thin interface or wrapper type (e.g., `HTTPClient`, `EmailSender`, `StorageBackend`) whose API is shaped around what callers actually need — not necessarily a mirror of the current library's API. Implement this abstraction using the existing library. At this point, nothing has changed for callers; the abstraction is a new seam that delegates to the current implementation.

2. **Migrate callers to the abstraction.** Incrementally update each call site to go through the new abstraction instead of calling the old library directly. This can be done file by file, PR by PR, by anyone on the team touching those files in the normal course of work. At all times, the system is runnable and deployable — every step compiles and all tests pass.

3. **Swap the implementation.** Once all callers use the abstraction, replace the implementation behind the abstraction with the new library. The abstraction layer absorbs the difference in API between old and new. Callers are unaffected.

4. **Retire the old implementation.** Remove the old library and any adapter code. The abstraction may be kept if it provides lasting value (testability, swap flexibility), or it may itself be removed if it was only needed as a migration vehicle.

The defining invariant of the technique is that **the code is never broken**. There is no migration branch, no feature freeze, no big-bang cutover day. Each of the four phases can be spread across normal work over days or weeks. The team makes progress on the migration in small increments, distributed naturally — whoever is touching a given file migrates that file as they pass through it.

This is a code strategy, not a git strategy. The name "Branch By Abstraction" refers to the abstraction layer acting as a conceptual branch point (both implementations live behind it simultaneously during phase 3), not to a git branch.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case: Replacing a Library Across a Large Codebase

- **Question:** A team needs to replace one library with another, and the library is called from dozens or hundreds of places in the codebase. Doing the replacement in a single commit is impractical. Taking a feature freeze to allow a dedicated migration sprint introduces business risk and organizational friction.
- **Use of Methodology:** Fowler's prescription is exactly the four phases above. First, introduce an abstraction that wraps the current library — the existing library backs this interface, so nothing breaks. Second, migrate call sites to use the abstraction gradually (opportunistically, as team members touch those files). Third, once all call sites are on the abstraction, implement the new library behind it. Fourth, remove the old library.
- **Conclusion:** The migration distributes itself naturally across normal work. No special sprint, no feature freeze, no merge conflict from a long-lived migration branch. The code compiles and deploys at every step.
- **Result:** The technique exploits the core property of refactoring — that behavior is preserved at every step — to make a large-scale change feel like a series of small, safe increments.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

**Scenario 1 — HTTP client library replacement**: A team needs to replace `net/http` with a more featureful client library (e.g., for retry semantics, tracing, or timeout policy) across 150 call sites. Branch By Abstraction: define an `HTTPClient` interface matching how callers use the current library; implement it with the current library; migrate call sites; then build a new implementation backed by the replacement library.

**Scenario 2 — Logging framework migration**: A service uses a deprecated logging library called at hundreds of points. Define a `Logger` interface; implement it with the existing library; migrate callers one package at a time; then implement `Logger` with the new library; remove the old one.

**Scenario 3 — ORM or database access layer swap**: The team wants to replace a heavy ORM with direct SQL (or vice versa), used across many repository functions. Define a repository interface per domain entity; implement each interface using the current ORM; migrate callers to the interface; then rewrite implementations using the new approach. (Note: if the schema itself changes, add fowler-database-parallel-change to handle data migration separately.)

**Scenario 4 — Architectural extraction**: A section of code needs to be pulled out into a shared component. Define an interface representing the functionality being extracted; route all in-process callers through that interface; then move the implementation to the new component location.

**Scenario 5 — Framework migration without freeze**: A team wants to migrate from one web framework to another. Define a request/response handler interface; implement it with the current framework adapter; migrate handlers one by one; then swap the framework adapter.

### Language Signals

- "We need to replace X across N call sites"
- "We can't take a feature freeze to migrate"
- "How do we migrate away from this library while keeping the service running?"
- "We want to switch frameworks / ORMs / clients but it's used everywhere"
- "How do we do a big refactoring without a big-bang"
- "We've been putting off replacing X because there are too many call sites"

### Distinguishing from Adjacent Skills

- **Difference from `fowler-database-parallel-change`**: Database parallel change (expand-contract) addresses the specific problem of mutating a live database schema while old and new code versions run simultaneously against it — the challenge involves data migration scripts, backward-compatible column additions, and multi-release windows to avoid downtime. Branch By Abstraction is the code-level cousin: when code (not data) needs to transition from one implementation to another across many call sites. They are complementary. An ORM replacement that also changes the schema needs both.
- **Difference from `fowler-two-hats`**: Two Hats is a within-session discipline (keep refactoring and feature work separated). Branch By Abstraction is a multi-week strategy for large-scale migration. They operate at completely different time scales.
- **Difference from `fowler-opportunistic-refactoring`**: Opportunistic refactoring covers small, within-session improvements. Branch By Abstraction is specifically for changes too large to complete in a session or a day — weeks of incremental work by multiple team members.

______________________________________________________________________

## E — Execution Step

1. **Identify the boundary and introduce the abstraction.**

   - Define an interface (or thin wrapper type) whose API reflects exactly what callers currently need from the component being replaced. Name it after the capability, not the implementation (e.g., `HTTPClient`, not `NetHTTPAdapter`).
   - Write a first implementation of this interface backed by the existing library/component. No caller code changes yet.
   - Completion criteria: The new interface compiles. All existing tests pass. The interface is reachable from call sites but not yet used.

2. **Migrate call sites to use the abstraction.**

   - Update call sites to go through the new interface — either by dependency injection, by replacing a package-level function call with a method call on the interface, or by wrapping. Work file by file or package by package.
   - This step may be distributed across the team over days or weeks: anyone touching a file in the refactoring zone migrates that file's call sites.
   - Completion criteria: Zero direct usages of the old library remain in production code. All tests pass. The code deploys at every intermediate state.

3. **Implement the new component behind the abstraction.**

   - Build a new implementation of the interface backed by the replacement library or new architecture.
   - Run the full test suite against the new implementation. Fix any behavioral differences.
   - Completion criteria: The new implementation passes all tests. The old implementation is still present but unused.

4. **Wire the new implementation and remove the old one.**

   - Switch dependency injection or factory code to supply the new implementation.
   - Delete the old implementation and (if applicable) the old library dependency.
   - Completion criteria: The old library is removed from the dependency manifest. All tests pass. The abstraction layer may be retained (for testability) or removed if it served only as a migration seam.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **When the refactoring fits in a single commit or session**: Branch By Abstraction is designed for changes too large to do in one step. Extracting a method, renaming a variable, or moving a function to a different file does not need an abstraction layer and a multi-week migration plan. Use fowler-opportunistic-refactoring instead.
- **When the callers are external consumers, not code you control**: Branch By Abstraction requires migrating call sites. If the callers are external clients calling your public API — not internal code under your control — you cannot migrate them. The appropriate tool is API versioning with a deprecation window, not this technique.
- **When the abstraction boundary would cross a network call**: The technique assumes the abstraction wraps an in-process component. If the component being replaced is an external service (and the new component is a different external service), the abstraction layer must also handle network failures, latency, serialization, and partial responses — complexity that is out of scope for standard Branch By Abstraction and requires additional patterns (traffic shadowing, feature flags, circuit breakers).

### Failure Patterns

- **Migrating callers before the abstraction compiles**: The order of phases matters. If you start updating call sites to use the new interface before the interface exists and its first implementation is complete, the codebase will be in a broken state — some call sites use the old direct call, some use an interface that doesn't compile. Always complete phase 1 before beginning phase 2.
- **Designing the interface to mirror the old library's API instead of callers' needs**: If the interface is shaped around the old library (a 1:1 wrapper), implementing the new library behind it becomes the hardest part — the API mismatch is deferred rather than resolved at the abstraction. Design the interface around what callers need; absorb the API translation in the implementation layer.
- **Leaving phase 2 partially done**: If the team migrates 80% of call sites and loses momentum, the codebase has both the old direct calls and the new interface in use simultaneously — making it hard to reason about which path code is actually on and impossible to safely remove the old library. Agree on a completion signal (zero direct usages of old library) and track it.

### Author's Blind Spots / Limitations of the Era

- **Distributed systems and service boundaries**: The book describes Branch By Abstraction as a code technique within a single codebase. When the component being replaced crosses a service boundary — e.g., replacing one gRPC backend with another — the abstraction layer must also account for network-level concerns (retries, timeouts, dual-writing, traffic routing). The book does not address this extension.
- **No guidance on tooling to track migration progress**: Fowler's description relies on team discipline and the "whoever touches the file migrates it" heuristic. In large codebases, this can leave long-running partial migrations invisible. Modern teams can use linting rules, import checks, or grep-based CI gates to enforce zero remaining direct usages before phase 3 begins — but this is not discussed in the book.
- **The abstraction itself may become permanent technical debt**: Fowler notes the abstraction can be removed after migration, but in practice it often remains. An interface introduced as a migration seam that stays forever without a genuine design rationale adds indirection without value. The book does not discuss how to decide whether the abstraction should survive the migration.

### Easily Confused Proximity Methodology

- **Git feature branches named "refactoring"**: Developers sometimes create long-lived git branches for large refactorings and call this "branching for the refactor." Branch By Abstraction is explicitly an alternative to this approach — it allows the migration to proceed on the mainline, continuously integrated, without a diverging branch. The names sound similar; the mechanics are opposite.
- **Strangler Fig Pattern (from Michael Feathers / Martin Fowler)**: Strangler Fig also incrementally replaces a system component, but it operates at the service level — new code intercepts requests and gradually takes over from old code, with the old system being "strangled" over time. Branch By Abstraction operates within a single codebase at the library/module level. They are compatible and can be used together when the replacement also involves a service boundary.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- **composes-with** `fowler-database-parallel-change`: Branch By Abstraction handles the code layer of a large-scale migration — replacing a library or module across many call sites using an abstraction seam. Database Parallel Change (expand-contract) handles the schema layer. An ORM replacement that also changes the database schema needs both: Branch By Abstraction to migrate the code call sites incrementally, and Database Parallel Change to migrate the schema across multiple production releases without data loss. They operate in complementary layers and are frequently used together in the same migration project.

- **composes-with** `fowler-opportunistic-refactoring`: Branch By Abstraction is the enabling technique for the long-term mode of opportunistic refactoring. When a large structural problem cannot be addressed in one session, the strategy is to route all normal work through the affected zone toward the target state — one small step at a time. Branch By Abstraction provides the seam (the abstraction layer over the old and new implementations) that makes each incremental step safe to deploy to production.

- **contrasts-with** `fowler-yagni-refactoring`: Both skills involve abstraction layers, but in opposite situations. YAGNI says do not introduce an abstraction for a requirement that does not yet exist — it is a prevention of premature abstraction. Branch By Abstraction says introduce an abstraction to enable a concrete, immediate migration need. YAGNI governs the "should this abstraction exist at all?" question for speculative futures; Branch By Abstraction governs the "how do I safely replace this existing component?" question for real present requirements.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Time**: 2026-05-05
