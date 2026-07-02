---
name: domain-service-interface-composition
description: |
  Apply when structuring a domain service that depends on external capabilities (payment gateways, third-party APIs, other domain services) — specifically when deciding how to inject dependencies into a domain service and how to separate coordination logic from domain logic.
---
# Domain Service Receives Interfaces; Application Service Composes Layers

## R — Reading

> "Notice here how we have not coupled our interface to the partnership's implementation at all. We have used domain language from our bounded context and defined what a reasonable, sensible interface is. This will help us a lot in the long run, as it will make moving to the new partnerships system much easier. Note that we do not actually have a concrete implementation of this service yet and we do not know how it works. However, it does not stop us from developing our recommendation system... Application services are used to compose other services and repositories. They are responsible for managing transactional guarantees in place among various models. They should not contain domain logic. Application services are usually very thin. They are used only for coordination."

## Chapter 4: Repositories and Services / Chapter 6: a Practical Example — Part 2

## I — Interpretation

The pattern separates two distinct concerns that are frequently collapsed in Go codebases: domain logic (what the business requires) and coordination logic (how components are wired and sequenced). Domain services handle the first; application services handle the second.

A domain service receives interfaces defined in domain language as constructor arguments. `NewService(availability AvailabilityGetter) (*Service, error)` tells the compiler that `Service` needs something that can retrieve availability, but not what that something is. The `AvailabilityGetter` interface is defined in the same domain package as `Service`, expressed in the terms the domain understands. The concrete implementation — an HTTP client wrapping a third-party API — is injected from outside, typically from `main.go`. The domain service never imports HTTP, never imports the adapter, never knows that "availability" comes from a REST API. This means the domain service can be unit-tested with a hand-written stub or a `gomock`-generated mock, with zero infrastructure dependencies and zero network calls.

Application services (or, in thin microservices, the transport handler) compose the concrete implementations and inject them into domain services. In `main.go`, the constructor calls chain: `partnerAdapter := adapter.NewPartnershipAdaptor(httpClient)`, then `svc, _ := recommendation.NewService(partnerAdapter)`. The wiring is explicit, visible, and testable. There are no service locators, no reflection-based injection containers, no magic — just constructor calls in dependency order.

The layered responsibility is precise: domain services contain business logic and accept interfaces; application services contain coordination and security; transport handlers accept requests, delegate to application services, and translate results into wire format. Each layer depends only on the layer below it through interfaces, never on concrete implementations above it or beside it.

## A1 — Past Application

In the travel recommendation microservice (Chapter 6), Boyle defines `AvailabilityGetter` in the `recommendation` domain package before writing any implementation code. The `recommendation.Service` struct holds the interface as a field and receives it through `NewService`. The actual implementation — `PartnershipAdaptor` in `adapter.go` — is written later, satisfying the interface by calling the third-party HTTP API and translating the response into `[]Option`. The domain service is complete and testable before the adapter exists; the development sequence mirrors the dependency inversion. The HTTP transport handler in the `transport` package composes these: it receives a `*recommendation.Service` (itself an interface-accepting domain service) and calls `svc.Get(...)` on each request. The handler does no domain logic — it translates HTTP parameters into domain types and domain results into HTTP responses.

In CoffeeCo (Chapter 5), the `purchase.Service.CompletePurchase` domain service receives three interfaces: `purchaseRepo Repository`, `cardChargeService payment.CardCharger`, and `storeService store.Service`. Each is defined in its respective domain package. The `main.go` (application composition root) wires concrete implementations — the Mongo repository, the Stripe charge adapter, the store service — to these interfaces and constructs the domain service. No domain package imports infrastructure; all wiring happens at the composition root.

## A2 — Future Trigger ★

- A developer is writing a `PricingService` that needs to call an external exchange rate API and wants to mock it in tests — apply the pattern: define `ExchangeRateProvider` interface in the `pricing` domain package (`GetRate(ctx, from, to string) (float64, error)`), inject via constructor, test with a stub; the HTTP client is injected only in `main.go`.
- A code review shows a domain service struct with `httpClient *http.Client` as a direct field — the domain service is importing and using infrastructure directly; extract an interface in domain language and inject the HTTP client behind it; the domain service must not know it is making HTTP calls.
- A developer asks where to put "coordination code" that sequences three domain service calls and handles errors — that is application service logic; it belongs in an application service or the transport handler, not inside any domain service; domain services perform atomic domain operations, not multi-step workflows.

## E — Execution

1. Identify what the domain service needs from the outside world — express it as a domain capability: not "I need an HTTP client" but "I need something that can provide availability for a date range and location."
2. Define that capability as a Go interface in the domain package, using domain language for method names and types: `type AvailabilityGetter interface { GetAvailability(ctx context.Context, start, end time.Time, location string) ([]Option, error) }`.
3. Write the domain service constructor accepting the interface: `func NewService(availability AvailabilityGetter) (*Service, error)` — validate that the dependency is non-nil; return an error if not.
4. Implement the domain service's methods using only the interface and domain types — no infrastructure imports anywhere in the domain package.
5. Write the concrete adapter in a separate package (e.g. `adapter/`, `infrastructure/`) that satisfies the interface by calling the real external system.
6. In `main.go` (or the application composition root), construct the adapter, inject it into the domain service constructor, and inject the domain service into the transport handler: explicit, sequential, no magic.
7. In tests, inject a hand-written stub or a `gomock`-generated mock satisfying the interface — tests are independent of the concrete adapter.

## B — Boundary

The pattern assumes that all external dependencies of a domain service can be abstracted into domain-language interfaces. This works cleanly for simple request/response interactions. It becomes complex when the external system has session management, streaming, pagination, or other stateful interaction patterns that do not map cleanly to a single method call. In those cases, the interface may need to be more complex, or the adapter may need to present a simplified view that hides the complexity — which can be its own design challenge.

Application services should not contain domain logic, but in practice the line is not always clear. A sequence of domain service calls with conditional branching based on domain results is arguably both coordination (application service concern) and domain logic (which sequence is correct is a business rule). Boyle does not provide a rule for this ambiguity; teams must develop a team-specific convention.

The pattern uses constructor injection, which is idiomatic Go but does not scale automatically to large applications with many dependencies. As the number of injected interfaces grows, `main.go` or the composition root becomes complex. Boyle does not cover dependency injection frameworks (e.g. `samber/do`, `google/wire`); teams adopting this pattern in large projects should consider whether a DI container improves the composition root's maintainability.

Boyle's domain service examples are stateless (domain service with injected interfaces, no instance state). Domain services that need to cache external data, maintain connection pools, or hold configuration are harder to keep stateless; the interface injection pattern still applies but the service lifecycle becomes more complex.

## Related Skills

- **ddd-fitness-scorecard** — depends on: the layered domain/application service architecture is tactical DDD overhead; the scorecard confirms it is justified before this pattern is applied.
- **internal-package-bounded-context-enforcement** — informs: domain service interfaces defined via this pattern belong inside internal/ (enforced by that skill); the composition root in main.go sits outside internal/ and provides the wiring.
- **strong-consistency-across-bounded-contexts** — informs: the consistency rule determines whether a domain service calls another service directly (within-context, strong consistency) or publishes an event (cross-context, eventual consistency); this choice determines the interface design and composition structure.
- **go-value-object-immutability** — informs: value objects are the primary types in domain service interface method signatures; their value-type vs pointer-type semantics affect the API contract design.

______________________________________________________________________

## Provenance

- **Source:** Domain-Driven Design with Golang, Matthew Boyle, 2022
