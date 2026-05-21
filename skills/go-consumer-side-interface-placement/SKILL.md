---
name: go-consumer-side-interface-placement
allowed-tools: Bash, Read, Edit
id: go-consumer-side-interface-placement
description: Invoke when deciding where to define a Go interface — in the consuming package, inline on a struct, or at the domain root — especially when hitting import cycles, designing for testability, or choosing between three valid placement options.
type: merged-skill
source_skills:
  - slug: go-with-the-domain/consumer-side-interface-definition
    book: Go with the Domain
    author: Three Dots Labs (R. Laszczak, M. Smółka)
  - slug: go-beyond/go-beyond-interface-consumer-ownership
    book: Go Beyond
    author: Ben B. Johnson
related_skills:
  - slug: go-with-the-domain/consumer-side-interface-definition
    relation: supersedes
    note: Merged into go-consumer-side-interface-placement; source covers the architectural enforcement argument and import-cycle prevention.
  - slug: go-beyond/go-beyond-interface-consumer-ownership
    relation: supersedes
    note: Merged into go-consumer-side-interface-placement; source covers inline placement and the proliferation blind spot.
tags: []
---

# Go Consumer Side Interface Placement

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Interface declarations:
!`grep -rn '^type [A-Z].* interface {' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -15`

### R — Reading

> "Because the Go interfaces don't need to be explicitly implemented, we can define them next to the code that needs them. So the application service defines: 'I need a way to cancel a training with given UUID. I don't care how you do it, but I trust you to do it right if you implement this interface.'"
>
> — *Go with the Domain*, Three Dots Labs
>
> "The biggest turning point for me was realizing that my caller should create the interface instead of the callee providing an interface. This makes sense because the caller can declare exactly what it needs."
>
> — Ben B. Johnson, *Go Beyond*

**Convergence note:** Both sources independently assert that the consuming package — not the providing package — owns the interface definition, arriving at this from different angles: Three Dots Labs frames it as architectural necessity (the only placement that prevents import cycles in a layered codebase), while Johnson frames it as caller-minimal design (the caller shrinks the interface to exactly what it calls). Together they add a placement decision tree that neither source alone provides.

---

### I — Unified Framework

In Go, interfaces are satisfied implicitly — no `implements` keyword, no import of the interface definition. This affordance makes possible a design rule that most developers from Java, C#, and TypeScript miss: **the package that uses a type should define the interface, not the package that provides it.** The consuming package declares exactly the methods it needs; any type with matching methods satisfies it automatically.

Consumer-side interface placement has three valid forms, with different triggers:

## R — Reading

> "Because the Go interfaces don't need to be explicitly implemented, we can define them next to the code that needs them. So the application service defines: 'I need a way to cancel a training with given UUID. I don't care how you do it, but I trust you to do it right if you implement this interface.'"
>
> — *Go with the Domain*, Three Dots Labs
>
> "The biggest turning point for me was realizing that my caller should create the interface instead of the callee providing an interface. This makes sense because the caller can declare exactly what it needs."
>
> — Ben B. Johnson, *Go Beyond*

**Convergence note:** Both sources independently assert that the consuming package — not the providing package — owns the interface definition, arriving at this from different angles: Three Dots Labs frames it as architectural necessity (the only placement that prevents import cycles in a layered codebase), while Johnson frames it as caller-minimal design (the caller shrinks the interface to exactly what it calls). Together they add a placement decision tree that neither source alone provides.

---

## I — Unified Framework

In Go, interfaces are satisfied implicitly — no `implements` keyword, no import of the interface definition. This affordance makes possible a design rule that most developers from Java, C#, and TypeScript miss: **the package that uses a type should define the interface, not the package that provides it.** The consuming package declares exactly the methods it needs; any type with matching methods satisfies it automatically.

Consumer-side interface placement has three valid forms, with different triggers:

### Placement 1 — Inline on the Struct (Third-Party Client, Single Consumer)

When a struct wraps a single external dependency it calls with one or a few methods, define the interface inline on the struct field:

```go
type MyApplication struct {
    YoClient interface {
        Send(string) error
    }
}
```

Use this when: the dependency is a third-party library, the consumer needs only one method, and no other package needs the same interface shape. The mock is a three-line struct in the test file. The provider package is never imported by the test.

### Placement 2 — Package-Level in the Consuming Package (Architectural Adapter Boundary)

When a domain or application package depends on an infrastructure adapter (DB, gRPC client, message queue), define the interface as an unexported type in the consuming package file:

```go
// app/training_service.go  (no import of adapters)
type trainingRepository interface {
    CancelTraining(ctx context.Context, user auth.User, trainingUUID string) error
}
```

Use this when: the dependency crosses an architectural layer boundary. This is not a style preference — it is the *only* placement that produces the correct, compiler-enforced dependency direction. If the interface lives in `adapters`, and `app` imports `adapters` to get the interface type, and `adapters` imports `app` to implement domain operations, Go refuses to compile the cycle. Consumer-side placement makes the cycle structurally impossible.

### Placement 3 — Root Domain Package (Shared Domain Contract)

When the interface IS part of the domain — a contract that multiple infrastructure packages (http, sqlite, grpc) need to implement — define it at the root domain package:

```go
// wtf/dial.go (domain root package)
type DialService interface { ... }
type UserService interface { ... }
```

Use this when: the interface is a domain concept that multiple infrastructure adapters implement, and the root package is itself the domain layer. Both `http/` and `sqlite/` import the root; they never import each other. This is Johnson's "legitimate case where the interface is defined centrally because it is itself part of the domain contract."

### Choosing Between the Three Placements

| Trigger                                                  | Placement                          |
| -------------------------------------------------------- | ---------------------------------- |
| One consumer, third-party dep, testing-only concern      | Inline on struct                   |
| App/adapter boundary, import cycle risk, DIP enforcement | Package-level in consuming package |
| Interface is itself a domain concept, multiple adapters  | Root domain package                |

### What All Three Placements Share

In all three cases: the *producer* never exports the interface. The implementing package exports concrete types (structs, pointers). New methods can be added to the concrete type at any time; no consumer breaks unless those consumers already declare that method in their interface. This is the reciprocal discipline: producers return concrete types, consumers define minimal interfaces.

---

## A1 — Past Application

### Case 1: Wild Workouts TrainingService — Import Cycle as Architectural Enforcement (Go with the Domain)

In Wild Workouts, an initial attempt to store a direct reference to `adapters.DB` in `TrainingService` produced:

```text
import cycle not allowed
package .../trainings imports .../trainings/adapters
imports .../trainings/app
imports .../trainings/adapters
```

The compiler pointed exactly at the wrong dependency direction. The fix moved the interface to the `app` package:

```go
// app/training_service.go
type trainingRepository interface {
    CancelTraining(ctx context.Context, user auth.User, trainingUUID string) error
}
```

`adapters.DB` satisfied this interface implicitly. No reference to `adapters` remained in `app`. The import cycle was impossible by structure, not by convention.

**Domain:** DDD-layered Go microservice. **Outcome:** Compiler-enforced dependency direction; component tests injected `TrainerServiceMock{}` without any adapters import.

### Case 2: Yo API — Inline Interface for Isolated Testing (Go Beyond)

Johnson's application needed to send Yo notifications without making real HTTP calls in tests. The Yo client package exported no interface. Rather than asking the provider to add one, Johnson defined the interface inline:

```go
type MyApplication struct {
    YoClient interface {
        Send(string) error
    }
}
```

In the test file, a three-line struct with a `Send` function field satisfied the interface. The test file imported nothing from the Yo package. Switching from the Yo API to a different notification provider required changing only the concrete type injected in `main.go`.

**Domain:** Third-party HTTP notification client. **Outcome:** Zero-dependency test doubles; provider swap isolated to main.

---

## A2 — Trigger ★

Instead of the generic "put the interface in the consumer package," use this skill when you face a specific placement decision:

**Use this skill when:**

- You hit a Go import cycle compile error and need to understand why it happened and how to fix it structurally — not just by moving code around, but by correcting the dependency direction permanently.
- You are placing a new interface (PaymentGateway, UserRepository, EmailSender) and are unsure whether it belongs inline, in the consuming package, or in a shared location.
- A code review question arises: "should this interface be in `domain/`, `app/`, `adapters/`, or a shared `contracts/` package?"
- You want to mock a third-party library that exports no interface.
- You have a 10-method interface in a provider package and your consumer only calls 2 methods.

**Not this skill when:** the interface IS a standard library interface (io.Reader, http.Handler) — those are defined at the provider by design and are already minimal.

---

## E — Execution

1. **Identify the consuming package.** Which package calls the methods? That package owns the interface.

2. **List only the methods that package actually calls.** One to five is normal. This list is the interface.

3. **Choose a placement form** using the decision table in I: inline on the struct if one consumer and simple testing case; package-level unexported if crossing an architectural layer boundary; root package if the interface is a domain concept.

4. **Define the interface there.** Do not import the provider package to name the interface type. Do not create a shared `contracts/` or `interfaces/` package — both sides would need to import it, recreating the coupling you just removed.

5. **Let Go's implicit satisfaction connect them.** The concrete type in the provider package satisfies the interface without a declaration, an `implements` keyword, or a compile-time assertion (though `var _ trainingRepository = (*DB)(nil)` is acceptable documentation).

6. **In `main.go`, inject the concrete implementation** via constructor parameter: `NewFooHandler(repo fooRepository)`. Only `main.go` imports the provider package's concrete type.

7. **In tests, satisfy the interface with a minimal stub** defined in the test file. No imports from the provider package. No mock generation.

---

## B — Boundary

### Source a Failures (Go with the Domain)

- Creating a `contracts/` or `interfaces/` shared package to hold interfaces — both sides must import it, recreating the coupling. This is the most common way to implement consumer-side placement incorrectly.
- Defining an interface wider than the consumer actually needs — declaring all 10 methods of an adapter when only 2 are called defeats the minimal-contract purpose.
- Applying the pattern in trivial single-package, single-implementation scripts where interface indirection adds ceremony with no benefit.

### Source B Failures (Go Beyond)

- Provider-side interfaces that force large mock surface area — when the provider defines a 15-method interface, every mock must implement all 15, revealing which methods are not needed and creating ongoing maintenance load.
- **Interface proliferation:** In large codebases, many tiny consumer-defined interfaces can be functionally identical but not interchangeable — `interface { Send(string) error }` defined in five packages is five types, not one. Discovery requires tooling (grep, gopls) rather than language-native navigation. Johnson acknowledges this blind spot; Three Dots Labs does not.

### Synthesis-Specific Failure Mode

**Placement confusion across all three forms:** Developers who know "consumer-side placement" as a single rule apply it as "always package-level in the consuming package." This misses both the inline case (over-engineering for trivial third-party wrapping) and the root-package case (under-engineering for domain contracts that ARE the architecture). The placement decision table in I resolves this — but skipping the table produces interfaces in the wrong location even when the consumer-side principle is applied.

> **Surface contradiction:** Three Dots Labs treats package-level placement in the consuming package as universal. Johnson explicitly carves out the root-package case as "a legitimate counter-case." The merged skill resolves this by making both placements valid with different triggers — they describe the same principle at different architectural levels, not a contradiction.
