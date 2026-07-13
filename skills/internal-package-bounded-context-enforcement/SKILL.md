---
name: internal-package-bounded-context-enforcement
description: |
  Apply when structuring a Go DDD project and needing compile-time enforcement that one bounded context cannot import another's domain types directly — specifically when organising a monorepo, a multi-service project, or any Go module where domain leakage across context boundaries is a risk.
---
# Use internal/ Package to Structurally Enforce Domain Boundaries

## R — Reading

> "The internal folder is a special folder in Golang. Anything within the internal directory cannot be imported by other projects. This is a great fit for DDD as we do not want our domain code to be part of our public API. To automatically enforce this, we will be putting all our domain code inside this internal folder."

## Chapter 5: a Practical Example — Part 1 (The CoffeeCo Monolith)

## I — Interpretation

Go's `internal/` directory is a compiler-enforced access control mechanism: the Go toolchain rejects any import of a package at path `foo/internal/...` from any package outside the `foo` directory tree. This is not a convention, a code review practice, or a linting rule — it is a language-level compile-time error. No build will succeed if the boundary is violated.

This property maps directly onto DDD's bounded context isolation requirement. If each bounded context's domain code lives under its own `internal/` path, then by definition no other context can import its domain types. The "do not couple bounded contexts at the type level" rule becomes physically unbreakable within the Go toolchain. A developer who tries to use `orders/internal/domain.Order` from the inventory service will receive a compile error before they can even run a test.

The contrast with other language ecosystems is important context. In Java, bounded context enforcement relies on Maven/Gradle module boundaries (which can be bypassed by adding a dependency), package-private visibility (which is per-package, not per-bounded-context), or architectural test frameworks like ArchUnit (runtime, requires test discipline). In C#, the equivalent is project/assembly separation. Go's `internal/` provides this without any additional tooling, configuration, or test infrastructure — it ships with the language.

In a monorepo structure, placing each service at `services/<context>/` with domain code at `services/<context>/internal/domain/` means that `services/orders/internal/domain` is only importable from within `services/orders/`. The Inventory service at `services/inventory/` receives a compile error if it attempts to import Order domain types. Cross-context communication must happen through published interfaces (HTTP, gRPC, events) — which is exactly the architectural constraint DDD requires.

## A1 — Past Application

In the CoffeeCo monolith (Chapter 5), Boyle creates an `internal/` directory at the project root and places all domain packages inside it: `internal/loyalty/`, `internal/purchase/`, `internal/store/`, `internal/payment/`. The domain code — entities, value objects, aggregates, repository interfaces, domain services — all live under `internal/`. Nothing in `internal/` is importable by an external project or a future second service in the repository. When the HTTP transport layer needs to call the domain service, it does so from within the same module (the CoffeeCo module), which is permitted. But if a separate `analytics` service in a different module tried to import `coffeeco/internal/purchase`, it would fail to compile. In Chapter 6, the travel recommendation microservice independently uses the same pattern: `recommendation/internal/recommendation/` holds the domain code, and the transport layer (`recommendation/internal/transport/`) lives inside `internal/` as well, insulating both from external import.

## A2 — Future Trigger ★

- A developer building a monorepo with three bounded contexts (Orders, Inventory, Payments) asks how to prevent direct cross-context type imports — apply the rule: place each context at `services/<context>/` with domain code under `services/<context>/internal/domain/`; the Go toolchain enforces the boundary without any test infrastructure.
- Code review reveals that the shipping service imports `import "mycompany/orders/internal/domain"` directly — this is a compile-time violation that the toolchain should have caught; investigate whether the packages are in the same module (in which case `internal/` permits it) or different modules (in which case the import should fail); if they are in the same module, use separate modules or tighten the `internal/` nesting.
- A new microservice template is being designed and the question is where to put the domain code — the default answer is `internal/domain/`: it keeps domain private, prevents accidental public API surface for domain types, and signals clearly that domain code is not a reusable library.

## E — Execution

1. Create the `internal/` directory at the root of each bounded context's module or service directory: `services/orders/internal/`.
2. Place all domain code (entities, value objects, aggregates, repository interfaces, domain services, factories) under `internal/`: `services/orders/internal/domain/`.
3. Place infrastructure code that is internal to the service (database implementations, adapters) also under `internal/`: `services/orders/internal/infrastructure/`.
4. Place transport-layer code (HTTP handlers, gRPC server) under `internal/` as well if it is not intended as a public API: `services/orders/internal/transport/`.
5. Only place code under the non-`internal/` root if it is genuinely intended to be imported by other modules (e.g. shared protobuf types, published language contracts, SDK clients). Keep this surface minimal.
6. In a monorepo, verify that each bounded context is its own Go module (has its own `go.mod`) to ensure that `internal/` boundaries between services are enforced cross-module. If all services share one module, `internal/` at the module root only prevents external projects from importing; services within the same module can still cross-import.

## B — Boundary

The `internal/` mechanism enforces that domain code cannot be imported from outside the containing module, but it does not prevent domain logic from leaking upward within the same module. An application service in `internal/app/` can still import `internal/domain/` and implement domain logic there — `internal/` enforces boundary externally, not internally. The more common failure mode in DDD projects (business logic in application or transport layers) is not prevented by this pattern; it requires code review and team discipline.

In a monorepo where all services share a single Go module, `internal/` at the module root permits any package within the module to import any `internal/` package. To get true cross-service enforcement in a shared-module monorepo, you must either use separate modules per service or add a linting rule (e.g. `depguard`, `gomodguard`) — the language-level enforcement does not apply.

The pattern does not help with the problem Boyle identifies as a key failure mode of distributed systems: services sharing a database schema. `internal/` prevents Go type imports; it says nothing about shared database tables or shared schema ownership. A bounded context can have `internal/` enforcement in the code and still be tightly coupled to another context through a shared database.

Boyle's claim that `internal/` "enforces" the domain boundary is accurate for import-time coupling but overstated as a general claim. Enforcing that bounded contexts do not share runtime state (shared memory, shared caches, shared queues) requires architectural decisions beyond package structure.

## Related Skills

- **ddd-fitness-scorecard** — depends on: internal/ enforcement only makes sense once bounded contexts are established; the scorecard confirms the project warrants that architectural investment.
- **strong-consistency-across-bounded-contexts** — combines: internal/ defines where context lines are drawn structurally; the consistency rule defines what those lines mean at runtime — use both together to design the full bounded-context boundary.
- **domain-service-interface-composition** — informs: internal/ ensures that domain service interfaces defined inside internal/ are not accidentally exposed as a public API; the composition root in main.go sits outside internal/ and wires concrete implementations in.

______________________________________________________________________

## Provenance

- **Source:** Domain-Driven Design with Golang, Matthew Boyle, 2022
