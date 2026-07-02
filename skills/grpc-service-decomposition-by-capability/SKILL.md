---
name: grpc-service-decomposition-by-capability
description: Trigger when deciding how to decompose a monolith into gRPC microservices, or when evaluating the boundaries between services in a microservice system.
---
# Service Decomposition by Business Capability — Y-Axis Scale Cube, Team Ownership, and When to Decompose

## R — Reading

> "Dividing microservices by business capabilities is one of the options, and we will use that distinction as we focus on real-life use cases... There are five business capabilities: product, cart, checkout, payment, and shipping. They connect using their generated stubs... Microservice architecture also helps you to construct different small teams to assign code ownership to a specific pool of services."

## Ch1–Ch2 (Microservice Architecture)

## I — Interpretation

The **scale cube** from Abbott and Fisher provides a framework for decomposition decisions. X-axis scaling (horizontal duplication behind a load balancer) solves throughput by running multiple identical copies. Z-axis scaling (data partitioning) solves data volume by having each instance own a subset of data. Y-axis scaling (functional decomposition) solves complexity by splitting the application into independent services — this is the microservices axis.

Decompose by **business capability**, not by technical layer. A business capability is a discrete function the business performs: take an order, process payment, manage inventory, initiate shipping. Each capability maps to one service boundary. Do not decompose by technical layer (all database access in one service, all business logic in another) — this creates distributed coupling without independent deployability.

Each service owns its **own data**. Shared databases across services re-create monolithic coupling at the data layer, defeating the purpose of decomposition. Services communicate through their gRPC APIs, never by reading each other's database tables.

**Team ownership** follows service boundaries. Conway's Law predicts that system architecture mirrors the communication structure of the teams that build it. Aligning service boundaries with team boundaries ensures each team can deploy its service independently without coordination. Two teams sharing one service creates deployment coupling regardless of the service's internal architecture.

The **timing of decomposition** matters: start with a monolith to learn the business domain. Premature decomposition creates services with the wrong boundaries that are expensive to merge or re-split. Decompose when services become independently scalable, when teams are blocked by each other's deployment cadence, or when a domain boundary has stabilized.

The five capabilities in the book's e-commerce system — Product, Cart, Checkout/Order, Payment, Shipping — each have distinct business rules, data, and failure modes. Payment requires PCI compliance that would be unnecessary overhead if bundled with Order. Shipping has external dependencies (carrier APIs) that require independent scaling and failure isolation.

## A1 — Past Application

Ch1 introduces the e-commerce system with five microservices communicating via gRPC. Ch2 uses the scale cube to frame the architectural rationale: the five services represent Y-axis decomposition along business capability boundaries. Each service in Ch4–Ch8 has its own MySQL schema, its own Kubernetes Deployment, its own Protobuf-defined API, and its own test suite. The Order service calls Payment and Shipping through their gRPC stubs — it has no knowledge of their internal implementation, database schema, or deployment configuration. The counter-example (ce01) shows the coupling failure when domain types are shared across service boundaries instead of using generated stubs.

## A2 — Future Trigger ★

- You are splitting a monolith and need to decide where the service boundaries should be
- Two teams are blocked by each other's release cycles and you suspect the service boundary is in the wrong place
- A service has grown too large and you need criteria for identifying sub-boundaries within it
- A design review is evaluating whether to decompose "users and orders" into one service or two

## E — Execution

1. Map the business capabilities by listing what the business _does_ (not what the software does): "accept orders", "charge customers", "track inventory", "ship packages" — each verb-noun pair is a candidate service boundary
2. Verify each candidate service has distinct data that other services do not need to read directly; if two services would share a database table, they belong in the same service
3. Assign team ownership: each service should have a clear owning team of 2–8 people with full-stack responsibility for that service's API contract, implementation, deployment, and SLO
4. Define the API contract in a separate proto repository before implementing either service; consumers get a stable gRPC stub, not an import from the provider's codebase
5. Implement inter-service communication using only generated gRPC stubs; never import domain types across service boundaries
6. For each new service boundary, evaluate the decomposition decision explicitly: is the capability independently deployable? Can it fail independently without taking down unrelated capabilities? Does it have a distinct scaling profile?

## B — Boundary

Business capability decomposition is not always the right granularity. A payment processing capability may warrant splitting into payment initiation, payment authorization, and payment settlement if they have different compliance, scaling, or team requirements. The scale cube does not prescribe how many services to create — it frames the rationale. "Microservice" does not mean "small" — it means independently deployable with a well-defined API contract. Services that share release cycles, that are always deployed together, or that require transactional consistency across their boundaries are not yet ready for decomposition. The book recommends starting with a monolith and decomposing incrementally; a brownfield decomposition from a working monolith is safer than greenfield microservices for a domain that is not yet well understood.

## Related Skills

- **grpc-saga-compensation-ordering** — prerequisite for: sagas arise from decomposition; the step sequence, compensation ownership, and orchestrator location all follow directly from which services own which capabilities
- **grpc-kubernetes-deployment-topology** — prerequisite for: each service in the decomposition maps to one Deployment + ClusterIP Service + Ingress path rule; the topology directly encodes the capability boundaries

______________________________________________________________________

## Provenance

- **Source:** [gRPC Microservices in Go, Hüseyin Babal, Manning, 2023]
