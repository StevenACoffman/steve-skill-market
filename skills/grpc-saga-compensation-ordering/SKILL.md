---
id: grpc-saga-compensation-ordering
title: Saga Compensation Ordering — Bottom-Up Rollback and Choreography vs. Orchestration Trade-offs
description: Trigger when designing distributed transaction rollback across multiple microservices, or when choosing between choreography-based and orchestrator-based saga implementations.
source: [gRPC Microservices in Go, Hüseyin Babal, Manning, 2023]
---

## R — Reading

> "Whenever you send a create order request to the Order service, it initiates a saga responsible for running a series of steps to complete the operations... If it fails in the Payment service, the saga runs a compensation transaction to undo the operation, which is a refund in this step... Remember that if the saga fails at any specific step, it runs compensation transactions from the bottom up."

## Ch2 (Microservice Architecture Patterns)

## I — Interpretation

A saga is a sequence of local transactions across distributed services. Because no distributed transaction coordinator exists to atomically commit all steps, consistency is achieved by designing compensating transactions that undo each completed step in reverse order on failure.

The **bottom-up ordering rule** is non-negotiable: if the saga fails at step N, compensation runs from step N-1 back to step 1. For an Order → Payment → Shipping sequence: a Shipping failure triggers `Payment:refund()` then `Order:cancel()`. Compensation must not attempt to undo steps that have not yet executed; attempting to cancel an order that was never created is at best a no-op and at worst an error. Compensating transactions must be **idempotent** — they may be retried due to network failures or orchestrator restarts, and applying a refund twice must have the same effect as applying it once.

**Choreography-based sagas** use pub/sub events: Order publishes `order_created`, Payment consumes it and publishes `payment_created` or `payment_failed`, Shipping consumes `payment_created`. Each service is responsible for consuming failure events from prior services and self-compensating. Advantages: no central coordinator, fully decentralized. Disadvantages: the saga's global state is implicit and distributed across event logs; debugging failures requires reconstructing the event sequence; cyclic dependencies between services are possible.

**Orchestrator-based sagas** use a central coordinator (typically the initiating service) that issues explicit commands and waits for responses. The orchestrator maintains saga state persistently, enabling recovery after crashes. It knows the complete compensation sequence explicitly. Advantages: the failure paths are centralized and explicit; debugging is straightforward. Disadvantages: the orchestrator is a single point of coupling; domain logic about compensation lives in the orchestrator rather than the participant services.

For the book's Order/Payment/Shipping scenario, a Shipping failure in the orchestrator triggers two compensation calls in sequence: `paymentClient.Refund(order)` then `orderRepo.Cancel(orderId)`. The orchestrator does not proceed until each compensation step confirms success.

## A1 — Past Application

Ch2 of the book describes both saga variants for the e-commerce checkout flow. The choreography variant shows the event chain: `order_created` → Payment publishes `payment_created` → Shipping consumes and publishes `shipping_created`. The orchestrator variant makes the Order service the saga coordinator: it calls Payment, handles failure by calling `Payment:Refund` then updating its own order status to FAILED. Ch4's case study (c04) shows the concrete orchestrator implementation with the compensation sequence explicitly coded and the PENDING/SUCCESS/FAILED order states tracked in the database.

## A2 — Future Trigger ★

- You are implementing a checkout flow that involves multiple services and need to handle partial failure (e.g., payment succeeds but shipping fails)
- A team is debating whether to use event-driven choreography or an orchestrator for a new saga
- A saga implementation is missing compensation transactions — you need to explain what should happen when step 3 of a 5-step saga fails
- You need to explain why compensating transactions must be idempotent and what happens if they are not

## E — Execution

1. Map the saga as an ordered sequence of local transactions: (1) `Order:create(PENDING)`, (2) `Payment:charge()`, (3) `Shipping:start()` — identify the compensation for each step: (1') `Order:cancel()`, (2') `Payment:refund()`
2. For orchestrator-based: implement the saga state machine in the coordinator; persist saga state to the database after each step so a coordinator crash can resume compensation
3. On failure at step N, execute compensations from N-1 down to 1: call step (N-1)' then step (N-2)' and so on; never skip a compensation step
4. Make each compensation idempotent: `Payment:refund(orderId)` checks if a refund already exists before issuing a new one; `Order:cancel(orderId)` is a no-op if already cancelled
5. For choreography-based: define failure events (`payment_failed`, `shipping_failed`) and subscribe each prior service to the failure events for the step immediately after it
6. Test the compensation path explicitly: write a test that injects a failure at step N and verifies the compensation sequence completes correctly and leaves the system in a consistent state

## B — Boundary

Sagas guarantee eventual consistency, not strong consistency — there is a window between committing step N and completing compensations where the system is in an intermediate state. If your business domain cannot tolerate this window (e.g., financial double-spend), sagas are insufficient; consider a two-phase commit or a reserved resource model. Choreography-based sagas are harder to monitor and debug; always add correlation IDs to all events so the full saga sequence can be reconstructed from event logs. The book's running e-commerce implementation uses synchronous calls rather than true sagas — the saga theory is presented as an architectural pattern for the reader to apply, not as a fully implemented feature in the sample code.

## Related Skills

- **[grpc-service-decomposition-by-capability](../grpc-service-decomposition-by-capability/SKILL.md)** — depends on: sagas only exist because services are decomposed; the decomposition determines the saga participants, step ordering, and compensation ownership
