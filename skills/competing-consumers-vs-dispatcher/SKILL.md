---
id: competing-consumers-vs-dispatcher
title: Competing Consumers vs. Message Dispatcher
description: Invoke when a team wants to add more workers to speed up message processing and is deciding how to structure that parallelism, when different message subtypes require different processing logic, when transactional message processing is required, or when the team asks whether to let the queue handle load balancing or write their own dispatcher logic.
source: Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003)
---

## Competing Consumers Vs. Message Dispatcher

**Source:** Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003) — Chapter 10 (Messaging Endpoints), §"Competing Consumers" and §"Message Dispatcher" patterns

______________________________________________________________________

### R — Reading (Original Source)

> "One difference between Message Dispatcher and Competing Consumers is the ability to distribute across multiple applications. Whereas a set of competing consumers may be distributed amongst multiple applications, a set of performers typically all run in the same application as the dispatcher. The question is really whether you wish to let the messaging system do the dispatching or whether you want to implement it yourself."

______________________________________________________________________

### I — Interpretation

When a single consumer can't keep up with message volume, the natural answer is to add workers. But there are two distinct ways to do this — and they make fundamentally different tradeoffs about who is in control.

**Competing Consumers** put the messaging system in charge. Multiple independent consumers all listen on the same Point-to-Point Channel. The messaging system delivers each message to exactly one consumer, load-balancing across the pool. The application code is unaware that parallelism is happening — each consumer just processes whatever it receives.

**Message Dispatcher** puts the application in charge. A single consumer (the Dispatcher) receives all messages from the channel, then explicitly routes each one to a Performer — a thread within the same process — based on whatever logic the application requires. The messaging system sees only one consumer; the parallelism happens inside the application.

The choice between them is a question of where specialization and coordination logic should live:

- **If all workers are interchangeable** and you want unlimited horizontal scale across machines: Competing Consumers.
- **If different messages need different handlers** (e.g., a bond trading system has specialists for equities vs. options vs. fixed income): Message Dispatcher, because only the application knows how to match message to performer.
- **If transaction control matters**: Competing Consumers + Polling Consumer is the safest combination. Message Dispatcher requires a more complex implementation: a separate JMS/messaging session per Performer to keep each Performer's transaction independent. Getting this wrong produces a Dispatcher that unknowingly shares a transaction across all Performers.
- **If the messaging system's multi-consumer support is unreliable**: Message Dispatcher eliminates the problem — there is only one consumer as far as the messaging system is concerned.

The tradeoff is structural: Competing Consumers scale across machines because each consumer is an independent process. Message Dispatcher performers are threads in one process; they cannot spread to another machine.

______________________________________________________________________

### A1 — Past Application (Author's Cases)

**Bond trading system — production Dead Letter Channel overflow.** The Wall Street bond trading system went to production and MQSeries crashed, brought down by a Dead Letter Channel queue that had grown too large. Root cause: market-data messages were expiring (consumers processing too slowly) and routing to the DLQ faster than anything drained it. Competing Consumers could not be used because the channel was Publish-Subscribe (which doesn't support multiple competing receivers). An Aggregator could not be used because messages had to be forwarded immediately. The solution was a Message Dispatcher: a single JMSListener (the Dispatcher) that maintained a pool of Performer JMSListeners. The Dispatcher's onMessage method always returned immediately after delegating to a Performer, guaranteeing steady throughput regardless of individual message processing time. The Dispatcher pattern solved the throughput problem without changing the channel topology.

**JMS EJB Message-Driven Beans as a ready-built combination.** The EIP book notes that Java EE EJB Message-Driven Beans provide a pre-built Event-Driven + Transactional + Competing Consumers combination. The container manages the consumer pool and coordinates transactions with the messaging session. This is the practical escape hatch when implementing Competing Consumers with transactional semantics in a JMS environment — the container handles the session-per-consumer complexity that would otherwise fall on the developer.

**Simpler alternatives to Message Dispatcher.** When the goal is to route different message subtypes to different handlers, a simpler alternative is to use Competing Consumers on a Datatype Channel (one channel per message type) or to use Selective Consumers that filter by message type. These eliminate the need for a Dispatcher component while achieving the specialization goal, at the cost of more channels or more filtering overhead.

**Polling Consumer + Transactional Client as the safest combination.** The authors explicitly identify this pairing as the "safest bet" for transactional messaging. Event-Driven Consumer + Transactional Client is problematic in JMS because the transaction lifecycle is tied to the message receipt event, making rollback behavior unpredictable outside container-managed transactions. This is why Message Dispatcher — which should itself be a Polling Consumer — requires careful per-Performer session design to preserve transactional correctness.

______________________________________________________________________

### A2 — Future Trigger ★

Invoke this skill when:

- A team wants to "add more workers" to speed up message processing and is deciding how to structure that parallelism
- Different message subtypes require different processing logic and you need to decide whether to use separate channels, selective consumers, or a dispatcher
- Transactional message processing is required and the team is debating between event-driven and polling consumers
- A messaging system deployment has unreliable support for multiple consumers on a single channel (observed duplicate processing, lost messages)
- A design requires horizontal scaling across machines — verify the chosen parallelism approach actually supports cross-machine distribution
- A message processing bottleneck is traced to a single consumer that can't return fast enough, causing queue backup (the bond trading DLQ scenario)
- The team asks "should we let the queue handle load balancing, or should we write our own dispatcher logic?"

______________________________________________________________________

### E — Execution (Steps)

1. **Determine whether all message handlers are interchangeable.** Ask: can any worker process any message on this channel without first inspecting the message content to decide whether it applies? If yes: Competing Consumers is the default choice. If no (messages route to specialists): proceed to step 2.

2. **Determine whether cross-machine horizontal scaling is required.** Ask: must the parallel workers run on different servers, VMs, or cloud instances? If yes: only Competing Consumers supports this. Message Dispatcher performers are threads in one process — they cannot span machines. If cross-machine scale is not required, both options remain viable.

3. **Evaluate messaging system reliability for multi-consumer scenarios.** Ask: does the messaging system reliably deliver each message to exactly one consumer when multiple consumers share a channel? If the answer is uncertain (known bugs, limited documentation, production history of duplicate delivery): prefer Message Dispatcher — a single consumer eliminates the risk.

4. **Assess transaction requirements.** If message processing must be atomic with a database update:

   - Competing Consumers + Polling Consumer + Transactional Client: each consumer manages its own session/transaction. Cleanest option if consumers are independent processes.
   - Message Dispatcher + Transactional Client: each Performer needs a separate messaging session. The Dispatcher must not share its own session with Performers. This is architecturally correct but requires careful implementation.
   - Avoid Event-Driven Consumer + Transactional Client outside of container-managed transactions (e.g., EJB MDBs).

5. **Consider simpler alternatives before building a Dispatcher.** If specialization is the goal, evaluate:

   - Separate Datatype Channels per message type, each with its own Competing Consumer pool
   - Selective Consumers that filter for the message types they handle
     Both avoid the complexity of building and operating a Dispatcher while achieving per-type specialization.

6. **If choosing Message Dispatcher, design the session boundary explicitly.** The Dispatcher should be a Polling Consumer with its own session. Each Performer must have an independent session so that a Performer's transaction rollback affects only that Performer's message, not the Dispatcher's session or other Performers' sessions.

______________________________________________________________________

### B — Boundary (When Not to Apply)

**Competing Consumers destroys message order.** If downstream logic requires messages to be processed in the order they were produced, multiple consumers will break this — even if the channel itself is FIFO. Each consumer races to process its assigned message, and completion order is non-deterministic. For ordered processing, use a single consumer (one thread, one process) or a Driver-based approach (see queue-control-flow-model skill).

**Message Dispatcher is a throughput ceiling.** Because all Performers run in a single process, the Dispatcher's throughput is bounded by that process's resources (memory, CPU, thread count). If load exceeds what one machine can handle, Competing Consumers is the only option that scales out. Building a Dispatcher first and assuming it can be distributed later is an architectural dead end.

**The "dispatch yourself" path adds maintenance burden.** A Message Dispatcher requires the application to implement routing, thread management, error handling, and session management that the messaging system would otherwise provide for free with Competing Consumers. Before choosing Dispatcher, verify that the specialization or reliability requirement genuinely warrants this complexity — the simpler alternatives (Datatype Channels, Selective Consumers) may solve the same problem at lower cost.

**EJB MDB context may not exist.** The "safest" Competing Consumers + Transactional combination relies on EJB Message-Driven Beans (or their equivalent in a modern container). In serverless, lambda-based, or containerized environments without a managed transaction coordinator, the transactional guarantees may require different architectural patterns entirely (e.g., outbox pattern, saga choreography).

**The patterns are 2003 vintage.** Both were designed for JMS-era middleware. In Kafka, the consumer group mechanism provides the competing-consumer semantics natively; there is no direct analog to Message Dispatcher in a streaming log context. In cloud functions (AWS Lambda, GCP Cloud Functions) triggered by queues, the platform implements competing-consumer semantics automatically. In these contexts, the choice between the two patterns is made by selecting the platform, not by application design.

______________________________________________________________________

### Related Skills

- **[Queue Control Flow Model](../queue-control-flow-model/SKILL.md)** — *depends-on* → The order-preservation rule from the control-flow model — Queue + Competing Consumers destroys order; only a single Driver preserves it — is the prerequisite for choosing Competing Consumers safely.
- **[Queue Flow Control Decision](../queue-flow-control-decision/SKILL.md)** — *composes-with* → Adding more competing consumers changes the queue drain rate and flow control threshold; the two skills are applied together when both throughput and overload behavior must be designed.
- **[Messaging Observability Design](../messaging-observability-design/SKILL.md)** — *composes-with* → Competing Consumers creates non-deterministic processing order that Message History must account for; Wire Tap placement and Message Store design must reflect the parallel consumer topology.
- **[Multidimensional Coupling Assessment](../multidimensional-coupling-assessment/SKILL.md)** — *depends-on* → Competing Consumers introduces conversation coupling (is each message independently processable?) and order coupling (does downstream logic break if messages arrive out of sequence?); coupling assessment should precede the parallelism decision.
