---
name: seam-to-zone-refactoring-trajectory
allowed-tools: Bash, Read, Edit
id: seam-to-zone-refactoring-trajectory
description: Use when working with legacy code that has tangled dependencies and you need both a way in (breaking the dependency for testing) and an architectural destination (where the extracted code should end up). Covers the full trajectory from legacy entanglement to two-zone clarity.
type: merged-skill
source_skills:
  - slug: welc/welc-seam-model
    book: Working Effectively with Legacy Code
    author: Michael C. Feathers
  - slug: fcis/fcis-two-zone-architecture
    book: Functional Core, Imperative Shell
    author: Gary Bernhardt
related_skills:
  - slug: welc/welc-seam-model
    relation: supersedes
    note: Merged into seam-to-zone-refactoring-trajectory; adds two-zone as the architectural destination after seam-based access
  - slug: fcis/fcis-two-zone-architecture
    relation: supersedes
    note: Merged into seam-to-zone-refactoring-trajectory; adds seam taxonomy for reaching two-zone from legacy code
tags: []
---

# Seam to Zone — Refactoring Trajectory

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Package-level global vars (seam candidates):
!`grep -rn '^var ' --include='*.go' . 2>/dev/null | grep -v '_test.go\|_gen.go' | head -10`

Go files without corresponding test files:
!`find . -name '*.go' -not -name '*_test.go' -not -path './.git/*' -not -path '*/vendor/*' | while read f; do dir=$(dirname "$f"); base=$(basename "$f" .go); [ ! -f "${dir}/${base}_test.go" ] && echo "$f"; done | grep -v 'main.go\|_gen.go\|generated' | head -10`

### R — Original Sources

**Feathers** (Working Effectively with Legacy Code, Ch. 4):

> "A seam is a place where you can alter behavior in your program without editing in that place."
>
> "Every seam has an enabling point, a place where you can make the decision to use one behavior or another."
>
> "The seam view of software helps us see the opportunities that are already in the code base. If we can replace behavior at seams, we can selectively exclude dependencies in our tests."

**Convergence note:** Both frameworks locate the architectural problem before the testing problem. Feathers notes that the seam view shows "opportunities already in the code" — structure determines testability. Bernhardt's claim is structurally identical: if code lives in the functional core, testing is trivially easy; if it lives in the shell, testing is unnecessary (thin shell, no logic) or requires careful management. In both cases, testability is a diagnostic readout of architectural position.

**Bernhardt** (Functional Core, Imperative Shell, DAS-0072):

> "The ideal program contains a large body of immutable code written in a functional style, and then small pieces of mutable code doing imperative things — but having those pieces be very localized, separate from the data, and separate from the core behavior of the system. Push all the logic and data manipulation into immutable objects, and confine every side effect, every mutable reference, and every interaction with the outside world to a thin outer shell."

______________________________________________________________________

### I — Unified Framework

The seam model and two-zone architecture describe the same refactoring trajectory from opposite ends of the code lifecycle.

**Feathers is working backward from tangled code.** Given legacy code that was not designed for testability, the seam model asks: where in this program can behavior be substituted without editing that location? Every seam has two parts: the seam location (the call site where behavior varies) and the enabling point (the external location — constructor argument, build script, classpath — that controls which behavior runs). Finding the seam gives you access; acting at the enabling point lets you substitute a fake without touching the code under test.

**Bernhardt is working forward from clean architecture.** Given the choice of how to structure new code, two-zone architecture asks: which code touches the outside world? If a unit touches nothing external (no I/O, no mutable shared state, no network), it belongs in the functional core — pure values in, pure values out, testable with a one-liner. Everything that does touch the world belongs in a thin imperative shell whose job is to hold mutable state, receive events, call core functions, and update its references.

The frameworks are sequentially composable: **seam-first gives you access; two-zone gives you the destination.**

When you break a dependency using a seam and extract a fake for testing, the extracted fake represents behavior that could instead live as a pure value in Bernhardt's functional core. The fake you introduced to enable testing is documenting the architectural boundary — it marks exactly where pure logic was tangled with impure infrastructure. That boundary is the starting point for the second-phase refactoring: move the pure logic into core value objects; push the infrastructure toward the shell.

**The diagnostic signal from extracted behavior:** When you extract a fake to break a dependency, ask: does the fake return data (pure data in → data out), or does it perform I/O? If data: this behavior belongs in the functional core — eliminate the fake by inverting the dependency to a value argument. If I/O: this is genuine shell behavior — the fake is a permanent legitimate test tool.

**For new code:** Two-zone is the design prescription. If the code is new, no seam analysis is needed — design with core and shell explicitly separated from the start. The seam model becomes relevant only if the code later degrades (logic accumulates in the shell, I/O creeps into the core).

**For legacy code:** Seam-first. Locate the enabling point, introduce the minimum substitution, get the code under test. Then use two-zone as the refactoring target: each dependency-breaking step should move the code closer to the two-zone structure — pure logic toward value objects, I/O toward a thin shell.

______________________________________________________________________

### A1 — Applications

## R — Original Sources

**Feathers** (Working Effectively with Legacy Code, Ch. 4):

> "A seam is a place where you can alter behavior in your program without editing in that place."
>
> "Every seam has an enabling point, a place where you can make the decision to use one behavior or another."
>
> "The seam view of software helps us see the opportunities that are already in the code base. If we can replace behavior at seams, we can selectively exclude dependencies in our tests."

**Convergence note:** Both frameworks locate the architectural problem before the testing problem. Feathers notes that the seam view shows "opportunities already in the code" — structure determines testability. Bernhardt's claim is structurally identical: if code lives in the functional core, testing is trivially easy; if it lives in the shell, testing is unnecessary (thin shell, no logic) or requires careful management. In both cases, testability is a diagnostic readout of architectural position.

**Bernhardt** (Functional Core, Imperative Shell, DAS-0072):

> "The ideal program contains a large body of immutable code written in a functional style, and then small pieces of mutable code doing imperative things — but having those pieces be very localized, separate from the data, and separate from the core behavior of the system. Push all the logic and data manipulation into immutable objects, and confine every side effect, every mutable reference, and every interaction with the outside world to a thin outer shell."

______________________________________________________________________

## I — Unified Framework

The seam model and two-zone architecture describe the same refactoring trajectory from opposite ends of the code lifecycle.

**Feathers is working backward from tangled code.** Given legacy code that was not designed for testability, the seam model asks: where in this program can behavior be substituted without editing that location? Every seam has two parts: the seam location (the call site where behavior varies) and the enabling point (the external location — constructor argument, build script, classpath — that controls which behavior runs). Finding the seam gives you access; acting at the enabling point lets you substitute a fake without touching the code under test.

**Bernhardt is working forward from clean architecture.** Given the choice of how to structure new code, two-zone architecture asks: which code touches the outside world? If a unit touches nothing external (no I/O, no mutable shared state, no network), it belongs in the functional core — pure values in, pure values out, testable with a one-liner. Everything that does touch the world belongs in a thin imperative shell whose job is to hold mutable state, receive events, call core functions, and update its references.

The frameworks are sequentially composable: **seam-first gives you access; two-zone gives you the destination.**

When you break a dependency using a seam and extract a fake for testing, the extracted fake represents behavior that could instead live as a pure value in Bernhardt's functional core. The fake you introduced to enable testing is documenting the architectural boundary — it marks exactly where pure logic was tangled with impure infrastructure. That boundary is the starting point for the second-phase refactoring: move the pure logic into core value objects; push the infrastructure toward the shell.

**The diagnostic signal from extracted behavior:** When you extract a fake to break a dependency, ask: does the fake return data (pure data in → data out), or does it perform I/O? If data: this behavior belongs in the functional core — eliminate the fake by inverting the dependency to a value argument. If I/O: this is genuine shell behavior — the fake is a permanent legitimate test tool.

**For new code:** Two-zone is the design prescription. If the code is new, no seam analysis is needed — design with core and shell explicitly separated from the start. The seam model becomes relevant only if the code later degrades (logic accumulates in the shell, I/O creeps into the core).

**For legacy code:** Seam-first. Locate the enabling point, introduce the minimum substitution, get the code under test. Then use two-zone as the refactoring target: each dependency-breaking step should move the code closer to the two-zone structure — pure logic toward value objects, I/O toward a thin shell.

______________________________________________________________________

## A1 — Applications

### Case 1: Feathers — CAsyncSslRec::Init() — Seam Introduction in Legacy C++ (Legacy Codebase Domain)

**Problem:** `CAsyncSslRec::Init()` in C++ calls the global function `PostReceiveError(SOCKETCALLBACK, SSL_FAILURE)` directly. No class method, no virtual dispatch — a bare global call. In tests, this call produces real side effects. No seam exists at the call site.

**Methodology:** Introduce a virtual method `PostReceiveError` on `CAsyncSslRec` itself with the same signature. Its body delegates to `::PostReceiveError` (the global, via C++'s scoping operator), preserving production behavior unchanged. Now the call in `Init()` dispatches through virtual dispatch. A test subclass `TestingAsyncSslRec` overrides the method with an empty body. The enabling point is wherever a `CAsyncSslRec*` is constructed.

With the seam established, apply the two-zone diagnostic: does `PostReceiveError` return data, or perform I/O? It performs I/O (socket error reporting). The fake is a permanent legitimate test tool — this is shell behavior. The seam does not point toward a functional core extraction; it points toward keeping the fake as the correct long-term test infrastructure.

**Conclusion:** An object seam created where none existed. The enabling point is the construction site of the object. The two-zone diagnostic confirms the fake is the permanent solution (I/O behavior → shell → keep the test double).

**Result:** Tests can run `Init()` and verify its other behavior without triggering `PostReceiveError`'s real side effects. No production code path changed.

______________________________________________________________________

### Case 2: Bernhardt — Ruby Twitter Client — Two-Zone Design from the Start (New Code Domain)

**Problem:** A terminal Twitter client with real-time network updates, keyboard input handling, and background threading. How do you structure it so that testing doesn't require a mock infrastructure?

**Methodology:** No legacy code, no seam analysis needed. Design with two zones explicit from the start. Four immutable core classes: `Tweet` (data carrier), `Timeline` (merge logic — produces a new timeline, never modifies its own array), `Cursor` (movement logic — each move returns a new cursor), `TweetRenderer` (display computation — data in, array of lines out). One shell file (~165 lines) handles the event loop, background thread, queue, and database writes.

Each state change in the shell is a single assignment line: `@cursor = cursor.move_down`. The logic of what "down" means lives in the core. The mutation is the assignment in the shell.

**Conclusion:** All four core classes are tested with zero setup, zero mocks, zero shared state. The shell is untested but simple. Background thread hands immutable `Timeline` values to the main thread without synchronization — no race conditions possible.

**Result:** A working production application with high test confidence, lock-free concurrency, and all side effects traceable to one file.

______________________________________________________________________

## A2 — When to Use This Skill

Use this skill — not one of its source skills — when:

- You have broken a dependency using a seam and now need to know what to do with the extracted behavior (Feathers stops at successful substitution; this skill adds the two-zone destination)
- You are starting new code and want to design it so that it won't require seam analysis later — use two-zone upfront
- You are refactoring legacy code and want to move it toward a testable, well-structured end state, not just toward "tests pass"
- A seam extraction produces a fake that returns pure data — this is the signal that the fake should not be permanent; the logic belongs in the functional core

**Instead of welc-seam-model or fcis-two-zone-architecture, use this when:** the question spans both diagnostic access (finding and using seams in legacy code) and prescriptive destination (where extracted code should live in the refactored design). Use `welc-seam-model` alone when the only question is "where is my hook point?" Use `fcis-two-zone-architecture` alone when designing new code with no legacy constraints.

**Language signals:**

- "I've broken the dependency — now where should I put this?"
- "My tests pass with the fake, but is the fake the right final shape?"
- "I want to refactor this toward something cleaner, not just testable"
- "The fake I extracted just returns some data — does it need to stay a fake?"
- "I can't test this without changing the code" (seam analysis first)
- "My business logic is mixed in with database calls" (two-zone prescription)

______________________________________________________________________

## E — Execution

**Phase 1 — Seam-first for legacy code (when entering existing tangled code):**

1. **Identify the dependency that is blocking the test.** Name the specific call or symbol connecting the code under test to infrastructure that cannot run in the test environment (database, filesystem, network, hardware, global side-effect function).

2. **Determine whether a seam already exists.** Ask in order:

   - Is the call through a virtual method or interface? → Object seam; enabling point is wherever the concrete object is created.
   - Is the symbol resolved by the linker or classpath? → Link seam; enabling point is the build script or classpath.
   - Does a C/C++ preprocessor run before this code? → Preprocessing seam; enabling point is the `#define` or alternate header.
     If no seam exists, introduce the minimum change that creates one (virtual wrapper, extracted factory method, function-type field).

3. **Act at the enabling point, not the seam location.** Construct or configure the fake at the enabling point. The seam location (the call site) must remain unchanged in production code.

4. **Classify the extracted behavior: data or I/O?** Ask: does the fake return pure data (in → out, no side effects), or does it perform I/O (write, network, mutation of external state)?

   - If data: this is the two-zone signal — the behavior belongs in the functional core. The fake is a refactoring prompt, not a permanent solution. Proceed to Phase 2.
   - If I/O: this is genuine shell behavior. The fake is the correct permanent test tool. Stop here.

**Phase 2 — Zone-targeting as the refactoring destination (when tests exist and dependencies are broken):**

5. **Classify every unit of code as core or shell.** Does it touch the outside world (call external service, write to database, read input, launch thread, mutate shared state)? If yes → shell. If no → core candidate.

6. **Extract pure logic into value objects.** For each mixed-zone unit: separate computation (what is being decided or transformed) from I/O (what is being fetched or written). The computation becomes a method on a value object: takes values as arguments, returns a value. Completion criterion: the extracted unit is testable with `construct input → call → assert output` and requires no mocks.

7. **Thin the shell by making mutation a single assignment per state change.** The shell's response to a core return value: `@state = core.compute(input)`. One assignment. The core computed the next state; the shell made it current. If the shell has branching logic beyond routing (which core function to call), that branching is a candidate for extraction to the core.

8. **Verify structural consequences.** Thread safety: are objects crossing thread boundaries all immutable? Is one thread the sole writer to each external resource? Testability: can every core function be tested with a one-liner? Does any core test require a mock?

**For new code (skip Phase 1):**

Begin at Step 5. Design with the two zones explicit from the start. Apply the side-effect test before writing any class. No seam analysis needed unless the code later degrades.

______________________________________________________________________

## B — Boundaries

**Do not apply seam analysis when:**

- The class already accepts the dependency through a constructor parameter or method argument, and an interface already exists — standard dependency injection applies; no seam analysis needed
- The code is being written from scratch — design with two-zone structure from the start; seam analysis is a retroactive diagnostic
- The only dependency is on language primitives (pure computation with no I/O) — there is no seam problem

**Do not apply two-zone prescription when:**

- Frameworks that impose their own structure (Rails, Django, Spring) conflict — FCIS can be applied within a framework, but don't fight the framework's prescribed structure directly
- The system is purely computational with no I/O — if there is no shell, the two-zone framing adds no value; everything is already core
- Distributed systems and microservice boundaries — FCIS addresses intra-service structure; the shell of one service is not the core of another

**Source A failures (Feathers / seam model):**

- Mistaking the call site for the enabling point: trying to modify the line of code that contains the dependency is not using a seam — it is editing the code under test
- Wrong seam type: attempting an object seam on a sealed/final class where no virtual dispatch exists; the correct response is to look for a link seam or introduce an interface parameter
- Link seam invisible in production: build script substitution can accidentally ship test stubs; make the difference between test and production environments obvious
- Preprocessing seam overuse in C++: use only when object and link seams are unavailable
- Stopping at "tests pass": if the fake returns pure data, the seam revealed a refactoring opportunity that Feathers' framework alone does not surface

**Source B failures (Bernhardt / two-zone):**

- Logic accumulating in the shell: every branch in the shell is logic that could live in the core as a pure function
- Treating the shell as a permanent home: rough code in the shell during exploration must be extracted; intermediate state left indefinitely defeats the architecture
- Muddy responsibilities in the core: core objects can grow unclear even without side effects; the cure is to extract sub-responsibilities into smaller, more cohesive value objects
- Error handling gap: the functional core pattern works for the happy path; failure representation (Result/Either pattern) is not addressed by Bernhardt and requires additional discipline

**Synthesis-specific failure mode:** Breaking a dependency via a seam, having tests pass, and treating that as the final state — when the extracted fake returns pure data. This is Feathers' stopping condition (tests pass = success) applied in a case where Bernhardt's framework would prescribe eliminating the fake by inverting the dependency to a value argument. The synthesis failure is treating every seam-based test as a permanent design decision rather than asking, after each extraction, whether the fake is revealing a refactoring opportunity toward the functional core.
