---
id: messaging-observability-design
title: Messaging Observability Design
description: Invoke when you don't know where a message went, when the system looks healthy but messages aren't being processed, when designing a new async integration from scratch, when a packaged application is in the integration path and cannot be modified, or when debugging an incident in a live async system.
source: Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003)
---

## Messaging Observability Design

**Source:** Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003) — Chapter 11 (System Management): Wire Tap, Message History, Message Store, Smart Proxy patterns; Chapter 11 introduction

______________________________________________________________________

### R — Reading (Original Source)

> "The architectural benefits of loose coupling actually make testing and debugging a system harder... [Wire Tap:] Insert a simple Recipient List into the channel that publishes each incoming message to the main channel and a secondary channel... The Message History is a list of all applications that the message passed through since its origination."
>
> "The Wire Tap, Message History, and Message Store help us analyze the asynchronous flow of a message. In order to track messages sent to request-reply services, we need to insert a Smart Proxy into the message stream."

______________________________________________________________________

### I — Interpretation

Asynchronous messaging systems are paradoxical: the architectural properties that make them excellent for production — loose coupling, no direct connections between components, fire-and-forget delivery — are the same properties that make them difficult to observe, test, and debug.

In a synchronous system, a call stack tells you exactly what happened. In an async messaging system, a message leaves the producer and you have no natural mechanism to follow it. There is no stack. The consumer may process the message seconds or hours later, in a different process on a different machine. If something goes wrong — the message is malformed, routed incorrectly, processed twice, or never processed — the default diagnostic toolkit gives you nothing except, eventually, the Dead Letter Channel.

Hohpe's insight is that observability is not a monitoring problem to be solved by adding APM tools later. It is an integration design problem that must be solved at design time, using the same pattern language as the integration itself. The four patterns form a selection framework, each addressing a different observability need:

**Wire Tap** is for passive inspection of a Point-to-Point channel. It is implemented as a fixed two-output Recipient List: one output continues the message to its original destination, the other sends a copy to a secondary channel for observation. The message is not consumed — the primary flow continues unaffected. The Wire Tap solves "I need to see what's on this channel without touching the primary flow."

**Message History** is for tracing the path a single message takes. Each component that processes the message appends its identifier to a list carried in the message header. By the time the message reaches its final destination (or lands in the dead letter channel), its header contains a full routing trace. Message History solves "which components did this specific message pass through, and in what order?"

**Message Store** is for cross-message, cross-time reporting. Where Message History traces a single message's path, Message Store enables questions like: what is our message throughput over the last hour? What is the P95 processing latency? Which messages failed last Tuesday? It works by pairing a Wire Tap (or self-publishing by components) with a durable store that persists relevant message fields — often headers and key business fields rather than full bodies. Message Store solves "report on message flow patterns across many messages over time."

**Smart Proxy** addresses a specific and subtle problem: tracking request-reply latency through a service that uses a dynamic Return Address. Normally the requester specifies where the reply should go (a dynamic reply channel, not a fixed address). A Smart Proxy intercepts the request, replaces the Return Address with its own channel, records the original Return Address and a correlation ID, receives the reply, and forwards it to the original requester — while measuring the round-trip time. Smart Proxy solves "how do I measure latency through a service I cannot modify, when that service uses dynamic reply addressing?"

The selection algorithm is clean: P2P channel inspection → Wire Tap; single-message path trace → Message History; multi-message reporting and SLAs → Message Store; request-reply latency tracking → Smart Proxy. These patterns are composable: Wire Tap + Message History together give you both passive capture and path tracing. Wire Tap feeding a Message Store gives you a persistent audit log.

The organizing principle is that all four patterns are non-invasive by design — they observe without modifying the primary message flow. This is the architectural discipline that makes them usable in production without changing the behavior being observed.

______________________________________________________________________

### A1 — Past Application (Author's Cases)

**WGRUS order-status queries** (c02): The Widget-Gadget order processing system used a Message Store (fed by a Wire Tap on the order channel) to enable order-status queries. Because each order message was captured at the point of entry, the customer service representative could query the store for any order regardless of where it was in the processing pipeline. Without the Message Store, the only way to determine order status would have been to query each downstream system independently.

**Message History for loop detection in Pub-Sub** (p14): In a system where an event published by System A could be routed back to System A after processing by System B, Message History allows the receiving component to check whether it had already processed this message (its identifier appears in the history) and discard it, preventing infinite loops. This is especially important in Pub-Sub topologies where cycle detection is non-obvious.

**Smart Proxy to retrofit legacy systems** (c02, WGRUS SOA evolution): When the WGRUS system evolved toward a Service-Oriented Architecture, some legacy services did not support the Return Address pattern. Smart Proxies were inserted to add dynamic Return Address capability to those services without modifying them — simultaneously enabling service-to-service response routing and providing round-trip latency measurement as a side effect.

**Wire Tap with Control Bus for test-only capture** (f08): Hohpe notes that a Wire Tap can be connected to a Control Bus so that the tap is only active during testing or debugging. In production, the secondary channel is inactive; when an incident requires investigation, the Control Bus activates the Wire Tap without redeploying the application. This is the observability equivalent of a feature flag.

**Bond Trading Dead Letter overflow** (c04, c15): The bond trading system production crash traced to Dead Letter Channel overflow was exactly the "developer's nightmare" scenario. Expired market-data messages were accumulating in the dead letter queue because consumers were too slow. Message History would have made the routing path and expiry behavior visible before the crash; a Message Store would have surfaced the accumulation trend. The post-mortem identified both Wire Tap and monitoring of the Dead Letter Channel as missing infrastructure.

______________________________________________________________________

### A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- **"We don't know where the message went"** — Message History is the direct fix; each component should be recording its step
- **"The system looks healthy but messages aren't being processed"** — Message Store provides the cross-message view; combine with Wire Tap to capture the evidence
- **"We need to audit all messages passing through this channel"** — Wire Tap feeding a Message Store is the canonical answer
- **Designing a new async integration from scratch** — ask at design time: which of the four observability patterns are in the design? If none, add them before the system goes to production
- **A packaged application is in the integration path and cannot be modified** — Wire Tap and Smart Proxy are designed precisely for this: they observe without touching the application
- **"We need to prove our integration meets the SLA"** — Message Store is the mechanism; define what fields to capture and what queries the SLA reporting will require
- **A Pub-Sub topology with potential routing cycles** — Message History as loop detection is the standard answer
- **A request-reply service has unclear latency** — Smart Proxy measures round-trip time without modifying the service
- **Debugging an incident in a live async system** — identify which of the four patterns are already in place; the missing ones define the diagnostic gap
- **"Our integration is the architect's dream but the developer's nightmare"** — this phrase is the canonical signal that observability was not designed in from the start

______________________________________________________________________

### E — Execution (Steps)

1. **Identify the observability need.** For each integration path, determine which diagnostic questions matter in production:

   - Do you need to inspect message content on a channel? → Wire Tap
   - Do you need to trace a single message's routing path? → Message History
   - Do you need cross-message reporting, SLA measurement, or audit logs? → Message Store
   - Do you need to measure request-reply latency through a dynamic-reply-address service? → Smart Proxy

2. **Place Wire Taps at boundary channels.** For every Point-to-Point channel that crosses an important system boundary, insert a Wire Tap. The secondary channel feeds either a log aggregator or a Message Store. Wire Taps should be togglable via Control Bus for production use — active during incidents and testing, inactive otherwise.

3. **Add Message History headers to all custom components.** Each component you write should append its identifier and timestamp to the Message History header when it processes a message. For packaged components you cannot modify, insert a thin wrapper or proxy that performs this append. Define the header name as a convention across the integration.

4. **Design the Message Store schema.** Decide which fields to persist per message type: at minimum, message ID, correlation ID, channel name, timestamp, and status. For business audit requirements, add key business fields. Avoid storing full message bodies unless compliance requires it — storage costs compound quickly. Define a purge schedule upfront.

5. **Insert Smart Proxies for request-reply services that use dynamic Return Address.** For each such service, the Smart Proxy needs to: (a) intercept requests on the service's input channel, (b) record the original Return Address and a generated correlation ID in a local store, (c) replace the Return Address with its own channel address, (d) forward the reply to the original requester after recording round-trip time. Implement timeout handling — if a reply never arrives, the proxy must clean up its state to prevent memory leaks.

6. **Connect observability infrastructure to alerting.** The Message Store, Dead Letter Channel, and Wire Tap secondary channels are only useful if they are monitored. Define alerting thresholds: Dead Letter Channel accumulation rate, message processing latency P95, throughput drop. Treat the observability instruments as first-class infrastructure.

7. **Test observability in isolation.** For each Wire Tap and Smart Proxy, write tests that verify the primary message flow is unaffected by the observability instrument. Use the Control Bus to activate and deactivate taps during testing. Confirm that Message History headers accumulate correctly across all components.

______________________________________________________________________

### B — Boundary (When Not to Apply)

**Wire Tap adds latency to the primary path.** The Wire Tap implementation (consume → republish to two channels) is not free. It adds a consume-and-republish round-trip to every message on the tapped channel. For high-frequency, low-latency channels (streaming metrics, real-time pricing), this overhead may be unacceptable. Use selective tapping (Control Bus activation) rather than always-on tapping for these channels.

**Message History cannot track aggregator inputs.** An Aggregator receives multiple input messages and produces one output message. The output message's Message History can carry only one input's lineage — the others are lost unless you design a tree-structured history or explicitly merge them. For complex fan-in scenarios, Message Store (which captures all inputs independently) provides better cross-message traceability.

**Message Store grows without bound.** Every message captured adds to storage. Without an explicit purge strategy, the Message Store becomes a liability. Define retention windows, archival policies, and purge schedules at design time. Storing only headers (not full bodies) reduces volume significantly but may limit diagnostic capability for certain failure modes.

**Smart Proxy is stateful and can leak memory.** The Smart Proxy must store per-request state (Return Address, correlation ID, timestamp) between the request and reply. If a reply never arrives — due to a service failure, a lost message, or an unexpected error path — the stored state accumulates indefinitely. Implement explicit timeout-and-cleanup logic with logging when a request times out without a corresponding reply.

**These patterns are integration-layer tools, not application monitoring tools.** Wire Tap, Message History, Message Store, and Smart Proxy observe the integration infrastructure — what messages flow through channels, which components process them, how long service calls take. They do not replace application-level logging, distributed tracing (OpenTelemetry), or infrastructure monitoring (CPU, memory, network). In practice, you need both: integration observability for the message flow and standard APM for application internals. The two layers complement each other but serve different diagnostic questions.

**The 2003 patterns predate modern distributed tracing standards.** Message History is conceptually equivalent to trace context propagation in OpenTelemetry. In 2026, distributed tracing instrumentation (Jaeger, Zipkin, OpenTelemetry) may already provide much of what Message History offers through standard tooling, without custom header design. Apply the Message History pattern's principle, but consider whether your existing tracing infrastructure already implements it before writing custom header logic.

______________________________________________________________________

### Related Skills

- **[Integration Style Selection](../integration-style-selection/SKILL.md)** — *depends-on* → Observability design is only relevant after Messaging is selected as the integration style; the patterns (Wire Tap, Message History, Message Store, Smart Proxy) are specific to async messaging pipelines.
- **[Queue Control Flow Model](../queue-control-flow-model/SKILL.md)** — *composes-with* → Understanding who controls the cadence of a pipeline (Driver, Fetcher, Sender) determines where Wire Taps and Message Store capture points should be placed to observe real flow.
- **[Competing Consumers vs. Dispatcher](../competing-consumers-vs-dispatcher/SKILL.md)** — *composes-with* → When parallel workers are in use, Message History and Wire Tap placement must account for non-deterministic processing order; observability design must be adapted to the chosen parallelism pattern.
- **[Queue Flow Control Decision](../queue-flow-control-decision/SKILL.md)** — *enables* → Message Store and Wire Tap on the Dead Letter Channel are the primary instruments for detecting queue overflow and flow control triggering events before they cause the "all lights green, system is down" failure.
