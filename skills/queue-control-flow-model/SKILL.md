---
id: queue-control-flow-model
title: Queue Control Flow Model
description: Invoke when connecting two cloud services that don't seem to support direct connection, when a colleague draws an integration diagram with unlabeled arrows, when message ordering matters for a downstream consumer using parallel workers, when selecting between pull-based and push-based delivery, or when a serverless pipeline shows unexpectedly high P90 latency.
source: Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003) + Addendum 3 (Gregor Hohpe, ~2022)
---

## Queue Control Flow Model

**Source:** Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003) + "Control Flow — The Other Half of Integration Patterns" (Gregor Hohpe, addendum 3, ~2022) — Messaging Endpoints chapter + addendum §"Data Flow is only half the story"

______________________________________________________________________

### R — Reading (Original Source)

> "A queue inverts control flow. The sender can push messages at its preferred rate into the queue, meaning the control flow runs from the sender to the queue. Likewise, most queues support (or require) Polling Consumers, meaning the receiver's control flow points from right to left. Enterprise Integration Patterns only shows one half of distributed system design: the data flow. Control flow defines operational characteristics of a distributed system like scalability, robustness, or latency. Data and control flow may well point in opposite directions. When drawing an arrow, you should specify which flow it indicates. If your decision seems trivial, you are using the right model."

______________________________________________________________________

### I — Interpretation

Most integration diagrams show what data flows where but hide who is in charge of driving that flow. This invisibility causes architects to make control-flow decisions by accident — and then discover surprising ordering, latency, and scaling behavior at runtime.

The control-flow model gives every component a role on a single axis: does it actively push, or does it wait to be pulled?

- **Sender** — actively pushes to the next element (control flows left to right, same direction as data)
- **Sink** — passively receives from a Sender (no control-flow initiative)
- **Source** — passively holds data; does nothing until fetched
- **Fetcher** — actively requests (pulls) data from a Source (control flows right to left, opposite to data)
- **Driver** — active on both ends: fetches from a Source AND pushes to a Sink; controls the cadence of the whole pipeline

A **Queue** sits between a Sender and a Fetcher. The Sender pushes in; the Fetcher pulls out. The two control flows are completely independent. This independence is the mechanism that creates temporal decoupling, rate-matching, and backpressure tolerance — not merely a data buffer.

Two connection rules follow mechanically:

- Sender + Fetcher facing each other → insert a Queue to connect them
- Source + Sink facing each other → insert a Driver to connect them

The model makes a further consequence explicit: **only a Driver preserves message order end-to-end**, because it fetches sequentially from its Source and delivers sequentially to its Sink. A Queue + Competing Consumers breaks order because multiple workers race to process messages in parallel.

______________________________________________________________________

### A1 — Past Application (Author's Cases)

**AWS cloud service mapping.** Hohpe maps the four cloud primitives directly onto the vocabulary: AWS SQS is a Queue (pull model — consumers must fetch); AWS SNS is a Sender (push model — SNS drives delivery); AWS EventBridge Pipes is a Driver (it fetches from Sources like SQS or DynamoDB Streams and pushes to targets — it owns both ends). The consequence: SNS cannot feed directly into EventBridge Pipes because "two noses point at each other" — both are active pushers with no passive connector between them.

**Azure Event Grid pull delivery.** Azure added a pull-delivery mode to Event Grid alongside its existing push mode. Benchmarking showed pull delivery achieved lower P90 latency than push despite the apparent overhead of polling, because consumers could tune batch sizes and fetch exactly when ready.

**GCP Pub/Sub explicit documentation.** Google Cloud Pub/Sub is the clearest cloud provider in documenting the distinction: Push subscriptions (GCP drives delivery to an HTTPS endpoint — Sender role), Pull subscriptions (consumer polls — Fetcher role), and Export subscriptions (GCP acts as a Driver delivering directly to BigQuery or Cloud Storage with no user control-flow decision required).

**EventBridge Pipes and order preservation.** Because EventBridge Pipes acts as a Driver — fetching sequentially from a DynamoDB Stream and delivering sequentially to a target — it preserves source order end-to-end. A Queue feeding Competing Consumers would destroy that order, even if the queue itself maintained FIFO internally.

**Hidden queues inside serverless event routers.** Services that appear to be pass-through Pushers from the outside (because you send events in and they deliver events out) typically contain internal queues and competing consumer pools. AWS EventBridge P90 latency hovers around 250ms. These services sacrifice latency for throughput and operational stability — a consequence made visible only by the control-flow model.

______________________________________________________________________

### A2 — Future Trigger ★

Invoke this skill when:

- You are connecting two cloud services and they don't seem to support direct connection (SNS → EventBridge Pipes, S3 trigger → Lambda via SQS) — check whether both are active pushers requiring a Queue in between
- A colleague draws an integration diagram with unlabeled arrows and you can't tell whether a component polls or receives
- Message ordering matters for a downstream consumer and the design uses multiple parallel workers — determine whether order is destroyed
- You are selecting between pull-based and push-based delivery for a new queue consumer and latency vs. throughput is the deciding factor
- You need to rate-limit delivery to a downstream service — identify whether the active component is a Driver (can slow fetch rate) or a Sender (cannot self-throttle)
- A serverless pipeline is showing unexpectedly high P90 latency and you suspect internal queuing — trace the control flow to find the hidden buffers
- You are designing a new pipeline component and need to decide whether it should poll or wait for events to be pushed to it

______________________________________________________________________

### E — Execution (Steps)

1. **Label every component with its control-flow role.** For each component, ask: does it initiate data movement (Sender/Fetcher/Driver) or does it wait for something else to initiate (Sink/Source)? Write the role next to the component name.

2. **Check every interface for mismatches.** When two components are connected, verify that the roles are compatible:

   - Sender → Sink: direct connection is valid
   - Fetcher → Source: direct connection is valid (Fetcher drives; Source waits)
   - Sender + Fetcher facing: incompatible — insert a Queue
   - Source + Sink facing: incompatible — insert a Driver

3. **Identify who controls the cadence.** For each pipeline segment, find the component that determines how fast messages flow. If it's a Driver, it controls the rate and can be throttled. If it's a Sender, downstream consumers cannot slow it without a Queue as a buffer.

4. **Assess order requirements.** If message order matters to downstream logic:

   - Single-threaded Driver feeding a Sink: order preserved
   - Queue + multiple Competing Consumers: order destroyed, regardless of queue FIFO guarantees
   - Redesign required (single consumer, or explicit Resequencer) if order must be maintained with parallelism

5. **Map cloud services to roles.** Before designing a pipeline with cloud messaging services, explicitly label each: SQS = Queue, SNS = Sender, EventBridge Pipes = Driver, Lambda invoked via event = Sink, Lambda polling SQS = Fetcher. Verify that connections are between compatible roles.

6. **Annotate diagrams with flow direction.** On any integration diagram, mark each arrow as either data-flow or control-flow (and the direction each runs). Where data and control flow in opposite directions (a Fetcher pulling from a Source), both arrows should be drawn, not conflated into one.

______________________________________________________________________

### B — Boundary (When Not to Apply)

**The model was developed for the 2003 EIP context.** It fits messaging-based integration cleanly. Applying it to streaming systems (Kafka consumer groups, Flink pipelines), service meshes, or HTTP request/response APIs requires careful translation — some primitives (like Kafka's consumer groups) don't map directly onto the four-role vocabulary without extension.

**The vocabulary doesn't resolve all design decisions.** Knowing that a Sender requires a Queue before a Fetcher doesn't tell you which queue implementation to use, what the capacity should be, or what flow-control mechanism to apply when the queue fills. The model is a correctness check on component compatibility, not a full operational design.

**Order preservation via a single Driver may be a scalability ceiling.** A Driver that fetches sequentially and delivers sequentially preserves order but cannot parallelize. For high-throughput systems where order preservation is required, this model forces an explicit acknowledgment that throughput and order are in tension — it does not resolve that tension.

**The "two noses" visual affordance only works if teams use the notation.** If diagrams are drawn with unlabeled arrows (the default in most tools), the model's benefit disappears. Adoption requires a shared commitment to annotating diagrams with control-flow roles.

______________________________________________________________________

### Related Skills

- **[Integration Style Selection](../integration-style-selection/SKILL.md)** — *depends-on* → Control-flow modeling only applies after Messaging is selected as the integration style; this skill makes precise the operational properties that style creates.
- **[Queue Flow Control Decision](../queue-flow-control-decision/SKILL.md)** — *enables* → Identifying that a component is a Driver (controls fetch rate) vs. a Sender (cannot self-throttle) is the prerequisite for choosing the correct flow control mechanism — a Driver can implement backpressure; a Sender cannot.
- **[Competing Consumers vs. Dispatcher](../competing-consumers-vs-dispatcher/SKILL.md)** — *enables* → The control-flow model's order-preservation rule — a Queue with Competing Consumers destroys order; only a single-threaded Driver preserves it — directly determines which parallelism pattern is safe to use.
- **[Messaging Observability Design](../messaging-observability-design/SKILL.md)** — *precedes* → Annotating control-flow roles on a pipeline diagram (Sender, Driver, Fetcher, Sink) clarifies where to place Wire Taps and Message Store capture points for maximum diagnostic value.
