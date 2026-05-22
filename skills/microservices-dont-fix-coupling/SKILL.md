---
id: microservices-dont-fix-coupling
title: Microservices Do Not Automatically Reduce Coupling
description: Invoke when a team is planning a monolith-to-microservices migration, evaluating whether their microservices are delivering promised independence, or diagnosing why coordinated deployments are still required after service splitting.
source: Go with the Domain, Three Dots Labs (R. Laszczak, M. Smółka), 2026
---

## R — Reading

> "If you start with poorly separated services, you're likely to end up with the same monolith you tried to avoid, with added network overhead and complex tooling to manage this mess (also known as a distributed monolith). You will just replace highly coupled modules with highly coupled services. And because now everyone runs a Kubernetes cluster, you may even think you're following the industry standards. Serverless solves only infrastructure challenges. It doesn't stop you from building an application that is hard to maintain."

## Chapter 5: When to Stay Away from DRY

## I — Interpretation

Microservices are an infrastructure pattern: separate deployments, separate processes, separate databases. They do not alter the logical coupling between domain concepts. If two modules in a monolith share a data model, call each other's internal APIs, or must be released together to maintain consistency, splitting them into two services produces the same dependencies — now across a network instead of a function call. The coupling was always structural; the services make it more expensive without removing it.

The book names this pattern the "distributed monolith": the same deployment dependencies as a monolith, with the added costs of network latency, service discovery, distributed tracing, and complex tooling. The distinguishing indicator is deployment coupling: if releasing a feature requires coordinating changes and deployments across multiple services, the service boundaries are wrong.

The root cause is not the decision to use microservices — it is the decision to split without identifying Bounded Contexts. Services split by technical convenience (one service per DB table, one service per team) rather than by domain analysis preserve the coupling from the original monolith. The cure is Strategic DDD: identify Bounded Contexts through Event Storming, then draw service lines along context boundaries, not table or team boundaries.

Serverless, containers, and Kubernetes are infrastructure choices. They solve deployment, scaling, and operations problems. They do not solve domain modeling problems. A poorly bounded Kubernetes pod is still a distributed monolith.

## A1 — Past Application

Wild Workouts was initially split into three services: trainings, trainer, users. The split was made at the start of the project for infrastructure reasons (separate teams, separate deployment cadences). Chapter 16 reveals that the Bounded Context analysis through Event Storming produced different boundaries than the initial technical split. Some domain events crossed service boundaries in ways that required synchronous gRPC calls for simple user-facing operations, creating runtime coupling between services that mirrored the logical coupling of the original design.

The book uses this as the foundation for introducing Strategic DDD: the infrastructure (three separate Go services, separate Firestore collections, separate Kubernetes deployments) was correct; the domain model boundaries were not yet informed by a proper Bounded Context analysis. The services were independently deployable in theory but not in practice for certain feature changes.

Counter-example ce07 extends this: a team can have excellent tactical DDD within each service — private fields, repositories, CQRS — and still have wrong service boundaries because Bounded Context analysis was skipped. The quality of code within services does not compensate for wrong boundaries between services.

## A2 — Future Trigger ★

- A team has split their monolith into 8 microservices but every feature deployment still requires releasing 3-4 services simultaneously.
- Management is planning a microservices migration to "reduce coupling" without specifying what domain analysis will inform the service boundaries.
- A team's microservices are independent at the infrastructure level (separate repos, separate CI pipelines, separate databases) but have a shared internal domain model distributed via a shared Go module.
- A developer argues that moving to serverless functions will solve the scaling and coupling issues in their monolith.
- A new service split is proposed and the team is debating where the boundary should be — by team ownership, by database table, or by some other criterion.

## E — Execution

1. Before splitting any service, run an Event Storming session to identify domain events, commands, actors, and their natural clustering into Bounded Contexts.
2. Draw explicit Bounded Context boundaries based on which events/commands are understood by the same vocabulary and owned by the same business subdomain — not by team ownership or database tables.
3. Validate proposed service boundaries against the deployment coupling test: can each service be deployed independently without requiring coordinated changes to other services?
4. Identify inter-context dependencies and make them explicit: prefer asynchronous integration (events) over synchronous calls (gRPC) for cross-context communication to reduce runtime coupling.
5. If the team is already in a distributed monolith, do not merge services back; instead, redraw the Bounded Contexts and gradually migrate domain logic to the correct service boundaries.

## B — Boundary

Some coupling across services is unavoidable and acceptable. An orchestrated business process (book a training → check trainer availability → charge payment) requires coordination between services. The question is whether the coordination is explicit and asynchronous (domain events + sagas) or implicit and synchronous (direct gRPC calls that fail together). The goal is not zero inter-service communication; it is coupling along domain event channels, not internal model dependencies.

Microservices do deliver genuine independent-deployability benefits when bounded correctly. The book is not arguing against microservices; it is arguing that the benefits require correct boundary decisions that infrastructure alone cannot provide.

For teams with a simple, single-domain product and a small team, a well-structured monolith may be the correct choice. Microservices add operational complexity; they are justified when team autonomy, independent scaling, or independent deployability provide concrete business value.

## Related Skills

- **[strategic-before-tactical-ddd](../strategic-before-tactical-ddd/SKILL.md)** — depends on: the solution to a distributed monolith is Bounded Context analysis via Event Storming; this skill diagnoses the problem, strategic-before-tactical provides the remedy.
- **[anti-dry-separate-read-write-models](../anti-dry-separate-read-write-models/SKILL.md)** — compares: both skills address coupling at different granularities — this skill at service-boundary level, anti-dry at struct/model level within a service; recognizing both prevents coupling at every scale.
