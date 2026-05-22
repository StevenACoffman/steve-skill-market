---
id: strong-consistency-across-bounded-contexts
title: Strong Consistency Inside / Eventual Consistency Across Bounded Contexts
description: Apply when designing inter-service communication, choosing between synchronous and asynchronous coordination, or deciding whether a cross-context state change should be part of the same database transaction — specifically whenever a developer reaches for a distributed transaction or synchronous RPC call to update data in a different bounded context.
source: Domain-Driven Design with Golang, Matthew Boyle, 2022
---

## R — Reading

> "For aggregates, we are looking for transactional consistency, not eventual consistency; we want any changes to our aggregate to be immediate and atomic. Therefore, we can think of an aggregate as a transactional consistency boundary. Whenever we make changes within our domain, we should ideally only modify one aggregate per transaction. If it is more, then your model is probably not quite correct, and you should revisit it... Beyond our bounded context, we should expect (and aim for) eventual consistency. This means we expect the other systems to receive and process our event in a reasonable amount of time, but we do not expect it to be atomically up-to-date as we would expect our bounded contexts to be. This leads to more decoupled systems with stronger resilience and scalability possibilities."

## Chapter 3: Entities, Value Objects, and Aggregates

## I — Interpretation

The rule creates a two-level consistency model that maps architectural boundaries directly to consistency guarantees. Inside a bounded context, everything that must be true simultaneously belongs in a single aggregate transaction: either all changes commit or none do. Across bounded context boundaries, changes propagate as domain events and consumers update asynchronously. The boundary is not just a design choice — it is the point where atomicity becomes both impractical and undesirable.

The "aim for eventual consistency" phrasing is deliberate and often overlooked. Eventual consistency across boundaries is not merely a necessary trade-off imposed by distribution — it is the architecturally preferable model. A system where Orders waits for Inventory to confirm before completing a transaction has introduced a synchronous dependency that makes Orders' availability contingent on Inventory's uptime. Publishing a domain event after committing the Order aggregate decouples that dependency entirely: Orders succeeds or fails on its own terms, and Inventory catches up.

This asymmetry is the architectural basis for deciding between synchronous RPC and asynchronous domain events. If the interaction crosses a bounded context boundary, the default answer is an event. If the interaction is within a bounded context, the default answer is a direct method call within the aggregate or domain service. Developers who reach for synchronous HTTP calls between services for every interaction are missing this rule and building the coupling that eventual consistency is designed to avoid.

The consistency boundary also serves as a diagnostic tool: if completing a business operation requires modifying two aggregates in the same transaction, the aggregate boundary is probably wrong. Either the two aggregates should be one (they share a transactional invariant) or the coordination should be event-driven (they belong to different contexts).

## A1 — Past Application

In the CoffeeCo monolith (Chapter 5), the `purchase.Service.CompletePurchase` method commits the Purchase aggregate atomically — card charge and CoffeeBux loyalty update happen within the same bounded context, and the domain service enforces both or neither. The CoffeeBux aggregate is the consistency boundary for the loyalty scheme. When Boyle discusses extending CoffeeCo to multiple contexts (Store, Loyalty, Subscription), the pattern changes: changes that affect the loyalty context from the purchase context propagate as domain events, not as direct function calls into the loyalty aggregate. The aggregates do not share a transaction boundary across contexts — this is the strong/eventual asymmetry applied to the monolith architecture before it is scaled out.

## A2 — Future Trigger ★

- A developer asks whether to update Inventory synchronously inside the Order transaction when a customer places an order — apply the rule: Inventory is a separate bounded context; the Order aggregate commits and publishes an `OrderPlaced` event; the Inventory context subscribes and updates asynchronously.
- A team is designing a Payments service and wants to query the Subscriptions service for the customer's plan before processing a payment, in a synchronous call — the consistency rule points toward eventual consistency: the payment bounded context should hold the relevant subscription state as a projection updated via events, not a live synchronous query.
- A code review shows a single database transaction spanning two aggregate types in different packages — this violates the one-aggregate-per-transaction rule; the reviewer should ask whether these aggregates belong together (same boundary) or should be decoupled via events (different boundaries).

## E — Execution

1. Identify the bounded context boundary: does the state change you are designing involve one bounded context or two?
2. If within one bounded context: the state change belongs in a single aggregate transaction. All modifications must be atomic. Do not publish an event; call the domain service directly.
3. If crossing a bounded context boundary: the originating context commits its aggregate change first, then publishes a domain event. Never include the downstream context's state change in the same transaction.
4. Design the domain event payload to be self-contained (include all data the consumer needs; do not require the consumer to call back to the origin context to enrich the event).
5. In the consuming context, update state idempotently in response to the domain event (handle duplicate delivery without double-applying effects).
6. If the business requirement appears to demand cross-context atomicity (e.g. "inventory must decrease at exactly the moment the order is placed"), challenge the requirement with the domain expert: eventual consistency within a guaranteed delivery window (sub-second on a message bus) is usually acceptable and eliminates the distributed transaction.

## B — Boundary

The rule does not eliminate the need for error handling in the originating context. A failed publish after a successful aggregate commit creates an inconsistency unless an outbox pattern or transactional messaging is used. Boyle does not cover outbox patterns; this is a significant implementation gap when applying the rule in production.

The "eventually consistent" model requires that the message bus provides at-least-once delivery guarantees and that all consumers are idempotent. Neither guarantee is provided by the developer adopting this framework — they must be explicitly engineered into the infrastructure. The framework assumes a reliable message bus without discussing what happens when the bus is unavailable.

The consistency asymmetry is clear for well-drawn bounded contexts, but the rule provides no guidance for systems where the bounded contexts are incorrect or contested. If the team is uncertain about where the boundary lies, applying this rule prematurely can produce an event-driven system with incorrect event granularity that is harder to refactor than a synchronous monolith would have been.

Boyle does not discuss event schema versioning, consumer group management, or what happens when an event-consuming context falls behind. These are operational consequences of adopting eventual consistency that teams discover in production rather than design.

## Related Skills

- **[ddd-fitness-scorecard](../ddd-fitness-scorecard/SKILL.md)** — depends on: the consistency asymmetry model is only applicable once the scorecard confirms DDD adoption with multiple bounded contexts.
- **[internal-package-bounded-context-enforcement](../internal-package-bounded-context-enforcement/SKILL.md)** — combines: internal/ package boundaries define where context lines are drawn; this skill defines the consistency guarantees that apply at those same lines — use together when designing the full bounded-context architecture.
- **[domain-service-interface-composition](../domain-service-interface-composition/SKILL.md)** — informs: the decision to publish a domain event (eventual consistency) vs. call a domain service directly (strong consistency) determines how domain services are composed and what interface contracts are needed.
