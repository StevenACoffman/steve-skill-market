---
name: strategic-before-tactical-ddd
description: |
  Invoke when a team is adopting DDD, planning service decomposition, or questioning whether their DDD implementation is delivering expected benefits — especially when they have tactical patterns in place but service boundaries feel wrong.
---
# Strategic Before Tactical DDD

## R — Reading

> "Many sources describing DDD spend most of the time covering tactical patterns. Sometimes, they even skip strategic patterns. You can practice DDD by using just the strategic patterns. In some projects using tactical DDD patterns is even overkill. Unfortunately, most people are doing the totally opposite thing. They use just tactical patterns without the strategic part. Without Strategic patterns, I'd say that you will just have 30% of advantages that DDD can give you. Strategic DDD patterns give us a way to answer: what problem you are solving? Will your solution meet stakeholders and users expectations? How to separate services to support fast development in the long term?"

## Chapter 16: Introduction to Strategic DDD

## I — Interpretation

DDD has two distinct tiers. Tactical patterns (entities, value objects, aggregates, repositories, domain events) answer the question of how to implement a bounded context correctly. Strategic patterns (Event Storming, Bounded Context identification, Ubiquitous Language developed with domain experts, Context Maps) answer the question of what problem to solve and where to draw service and team boundaries.

The book's claim is that most practitioners apply tactical patterns while skipping strategic ones — and that this produces approximately 30% of DDD's value. The reason is understandable: developers are comfortable writing code. Event Storming requires facilitating a room full of business stakeholders; Bounded Context discovery requires extended collaboration with people who do not think in terms of code. Developers default to what they control.

The consequence is teams with excellent code quality inside each service and wrong service boundaries across services. They have private fields, behavioral methods, and comprehensive repositories — and they cannot explain why a particular aggregate lives in a particular service. Features that should be simple require coordinating changes across multiple services. The tactical code is correct; the strategic decisions were never made.

The priority ordering is: do strategic work first, even if it delays writing code. Two weeks of Event Storming and Bounded Context mapping can save months of refactoring wrong service boundaries. The tactical patterns are not worthless — they make code within each bounded context clean — but they must be applied within boundaries discovered through strategic work.

## A1 — Past Application

Wild Workouts started with services split by technical convenience: a trainings service, a trainer service, a users service. The book traces how these service boundaries were drawn before Event Storming was applied. The trainings service held training scheduling logic that was tightly coupled to trainer availability, which lived in a different service. Features that changed the cancellation policy required coordinated changes to both the trainings and trainer services.

In Chapter 16, the book introduces the Wild Workouts domain through an Event Storming lens retrospectively: what domain events exist (`TrainingScheduled`, `TrainingCancelled`, `TrainingRescheduleRequested`), what commands trigger them, and which bounded contexts they belong to. The exercise reveals that some of the original service boundaries aligned with bounded contexts by luck, and others did not.

The counter-example is ce07: the team could have implemented every tactical DDD pattern (private fields, constructors, behavioral methods, CQRS handlers, repositories) without ever discovering the correct Bounded Contexts. Their code quality metrics would be high; their system's evolvability would not have improved from a strategic standpoint.

## A2 — Future Trigger ★

- A team has adopted Value Objects, private fields, and repository patterns but cannot explain what business problem each of their services solves independently.
- A new feature requires coordinated deployment of three services because domain logic is scattered across them.
- Management is asking why DDD adoption has not reduced the time required for major features.
- A team is planning to split a monolith into microservices and is deciding where to draw the service boundaries.
- A developer has read Evans' DDD book and is asking where to start — implementing aggregates or running Event Storming.

## E — Execution

1. Before writing domain code, run at least one Event Storming session with both technical and non-technical stakeholders. Map domain events (past tense: "Training Scheduled") on a timeline, then add commands and actors.
2. Identify clusters of events, commands, and actors that evolve together and are understood by the same vocabulary — these form candidate Bounded Contexts.
3. Verify that the Ubiquitous Language is consistent within each Bounded Context: the word "user" can mean different things in different contexts, and that is correct — do not force a single universal "user" model.
4. Draw explicit Context Maps showing where bounded contexts communicate and how (shared kernel, upstream/downstream, anti-corruption layer).
5. Only after Bounded Contexts are identified, apply tactical patterns within each context. Use DDD Lite (entity + behavioral methods + repository) as the default; escalate to full aggregates, domain events, and CQRS when complexity warrants.

## B — Boundary

Strategic DDD is not free. Event Storming sessions require facilitators, business stakeholder time, and organizational trust between developers and product people. In a small team building a simple internal tool, the investment is disproportionate. The book's 30% framing applies to systems with genuine domain complexity and multiple teams.

Tactical patterns are not wrong — they are simply insufficient without strategic grounding. A team doing DDD Lite (tactical only) in a well-understood domain with stable boundaries is still writing better code than a team using anemic domain models and god services.

Event Storming is not the only strategic tool. User Story Mapping, Impact Mapping, and Product Discovery workshops can substitute. The goal is domain understanding before code, not a specific technique.

## Related Skills

- **microservices-dont-fix-coupling** — prerequisite for: strategic DDD (Event Storming, Bounded Context mapping) is the specific cure for the distributed monolith problem; run this skill first to provide the boundary analysis that skill requires.
- **anti-dry-separate-read-write-models** — informs: separate read/write models are a tactical DDD pattern; strategic analysis determines which bounded context owns each model and prevents premature sharing across context boundaries.

______________________________________________________________________

## Provenance

- **Source:** Go with the Domain, Three Dots Labs (R. Laszczak, M. Smółka), 2026
