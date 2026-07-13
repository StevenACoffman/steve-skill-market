---
name: integration-style-selection
description: |
  Invoke when designing a new integration point between two or more systems and the question is how they should communicate, when evaluating an existing integration that is misbehaving, when choosing between REST and a message queue, when designing a microservice architecture, or when auditing an architecture for hidden coupling.
---
# Integration Style Selection

## Integration Style Selection

**Source:** Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003) — Chapter 2 (Integration Styles)

______________________________________________________________________

### R — Reading (Original Source)

> "Messaging is more immediate than File Transfer, better encapsulated than Shared Database, and more reliable than Remote Procedure Invocation... The trick is not to choose the one style to use always, but to choose the best style for a particular integration opportunity."
>
> "One of the biggest difficulties with Shared Database is coming up with a suitable design for the shared database... Multiple applications using a Shared Database to frequently read and modify the same data can cause performance bottlenecks and even deadlocks as each application locks others out of the data."
>
> "Although the encapsulation helps reduce the coupling of the applications, by eliminating a large shared data structure, the applications are still fairly tightly coupled together. The remote calls each system supports tends to tie the different systems into a growing knot. In particular, sequencing — doing certain things in a particular order — can make it difficult to change systems independently."

______________________________________________________________________

### I — Interpretation

The four integration styles are not a hierarchy where Messaging always wins. They are four distinct trade-off profiles, and the correct choice depends on which integration criteria are most important at a specific integration point.

**File Transfer** is the least coupled and simplest to implement. It asks nothing of either application beyond reading and writing files in a format they can both understand. Its cost is freshness: the data is as old as the last file drop. When nightly or weekly synchronization is acceptable — and it often is for reporting, archiving, and cross-organizational batch exchange — this simplicity is a genuine advantage.

**Shared Database** eliminates the file-round-trip problem by giving all applications immediate read access to a common store. But it purchases that freshness by selling encapsulation. Every application can see — and write to — every table. Schema changes become politically and technically explosive because all teams must coordinate every change simultaneously. Deadlocks follow when multiple writers contend on the same rows. External packaged software usually refuses to use any schema but its own, making "unified schema" politically unachievable in most enterprises.

**Remote Procedure Invocation** (RPC, REST, SOAP) solves the schema visibility problem by exposing behavior, not data. Each application remains behind its own interface. But synchronous invocation means the caller blocks on the callee: slow callee, slow caller; unavailable callee, unavailable caller. Sequencing problems accumulate at scale — service A must call B before C, and the call graph becomes a growing knot of temporal dependencies.

**Messaging** breaks the temporal coupling by adding a store-and-forward intermediary. Sender and receiver do not need to be simultaneously available. Fan-out, routing, transformation, and retry are handled by infrastructure rather than code. The cost is real: asynchronous, event-driven programming is harder to build, debug, and test. It is the right choice for high-reliability, cross-application collaboration — not for every integration.

**The key architectural discipline:** each integration point deserves its own style selection. A system can use File Transfer for nightly reporting feeds, a Shared Database for tightly-controlled internal reference data, RPC for synchronous request-reply queries, and Messaging for event-driven workflows — all at once. The mistake is picking one style and applying it everywhere.

______________________________________________________________________

### A1 — Past Application (Author's Cases)

**Widget-Gadget Corp (WGRUS) order processing:** The authors use this running example across Chapters 1–4 to show integration style selection in practice. Order intake from web, call-center, and fax channels uses Channel Adapters (not Shared Database), because each channel has its own data format — Shared Database would require all channels to write to the same schema simultaneously. Downstream, the canonical NEW_ORDER channel uses Messaging because order processing requires reliable delivery, fan-out (credit check AND inventory check in parallel), and routing to two separate inventory systems. RPC would create a growing knot of sequential calls with no fan-out.

**File Transfer's legitimate use:** The authors use billing and address-update scenarios to show when File Transfer's staleness is genuinely acceptable. A customer changes their address; the billing system will send to the old address until tonight's file extract runs. If the business accepts this latency, File Transfer's simplicity is worth the tradeoff. When it is not — when the bill must go to the new address today — File Transfer's staleness becomes a defect.

**Shared Database's political problem:** The authors note that external packaged applications almost always refuse to use a schema other than their own. This makes Shared Database feasible only when all participating applications are custom-built, under shared ownership, and the teams can agree on a schema design. In post-merger enterprise integration — the Insurance Company EAI case — Shared Database was not viable; the teams agreed on a Message Bus with Canonical Data Model instead.

**RPC's sequencing trap:** The authors trace how Remote Procedure Invocation creates call-graph complexity as the number of participating services grows. Each new dependency adds a failure mode, a latency contributor, and a temporal constraint. The Bond Trading System used RPC for client-to-server calls (appropriate: a single synchronous request for a quote) and Messaging for server-to-client price updates (appropriate: high-frequency, fan-out to multiple trader workstations).

______________________________________________________________________

### A2 — Future Trigger ★

Invoke this skill when:

- **Designing a new integration point** between two or more systems, and the question is "how should they communicate?" The four styles are the canonical answer space.
- **Evaluating an existing integration that is misbehaving:** deadlocks in the database, slow callers blocking on slow callees, nightly batch data that is too stale for current business requirements, or messaging complexity that is unjustified for a simple two-party query.
- **Choosing between REST and a message queue** — this is the classic RPC vs. Messaging decision in modern clothing. The deciding criteria (synchronous required? fan-out needed? receiver reliability matters?) are unchanged.
- **Designing a microservice architecture** where each service needs to communicate with others. Each service-to-service integration point is a separate style selection, not a single architecture-wide mandate of "always REST" or "always Kafka."
- **Post-merger or cross-organizational integration** where different teams own different applications. Shared Database is almost never viable; the style selection determines how encapsulation and schema ownership will be managed.
- **Auditing an architecture for hidden coupling:** a system that claims to be "decoupled" via REST APIs is still using RPC and inherits all RPC's coupling properties. File Transfer hidden inside a microservice as a CSV export/import is still File Transfer.

______________________________________________________________________

### E — Execution (Steps)

1. **Enumerate each integration point separately.** For each pair (or group) of systems that must exchange data or invoke behavior, treat it as an independent selection. Do not import a global architecture decision.

2. **Apply the decision criteria in order:**

   - Is timeliness required? If updates can be infrequent (nightly, weekly), **File Transfer** is viable. Stop here if yes and staleness is acceptable.
   - Can all participating applications share a single, agreed schema, and are all apps under common control? If yes and the schema design is politically feasible, **Shared Database** may be appropriate. Stop here if yes.
   - Does the integration require invoking behavior (not just sharing data), and can the caller tolerate blocking while the callee responds? If yes, **Remote Procedure Invocation** (REST, gRPC, SOAP). Stop here.
   - Otherwise: **Messaging** — for async collaboration, fan-out, high reliability, or cross-organizational integration where neither party should block on the other.

3. **Check the counter-criteria for the selected style.** For File Transfer: is the update frequency actually acceptable for the business case? For Shared Database: are any of the applications packaged software that cannot use an external schema? For RPC: is the callee's availability required for the caller's availability to be acceptable? For Messaging: does the team have infrastructure, debugging tooling, and experience to manage asynchronous event-driven programming?

4. **Document the rationale at each integration point.** Record which criteria drove the selection and which alternatives were considered. This makes future re-evaluation possible when requirements change (e.g., when "nightly is fine" becomes "we need same-day updates").

5. **Verify that multiple styles coexist appropriately.** A single system legitimately uses all four styles at different integration points. The only error is applying one style everywhere by default.

______________________________________________________________________

### B — Boundary (When Not to Apply)

**The framework was designed before event streaming.** The four styles predate Kafka, event sourcing, and stream processing. Kafka is neither a simple message queue nor RPC — it combines high-durability storage, log-replay, consumer groups, and stream processing in a way the four-style framework does not cleanly accommodate. Apply the framework to identify the broad category (Messaging is the closest), then evaluate streaming-specific properties separately.

**Shared Database is more viable inside a single bounded context.** The authors' critique of Shared Database is strongest for cross-team or cross-organizational integration. Within a single team owning a tightly-scoped domain, a shared relational schema is often the correct choice — the coupling is manageable because one team controls schema changes. The anti-pattern is cross-team Shared Database, not all database sharing.

**RPC's synchronous coupling is addressable without switching styles.** Circuit breakers, timeouts, retries with idempotency, and async request-reply over HTTP (HTTP 202 + polling) all mitigate RPC's availability coupling. If the team is experienced with these patterns, the strict "caller blocks on callee" characterization is less absolute than the framework implies.

**The framework does not address security, compliance, or data sovereignty.** File Transfer across organizational boundaries may be mandated by compliance even when Messaging would be technically superior. Shared Database may be prohibited by data residency rules even when politically feasible. The style selection must be checked against legal, security, and regulatory constraints that the framework does not model.

______________________________________________________________________

### Related Skills

- **Multidimensional Coupling Assessment** — *enables* → Once you select an integration style, coupling assessment maps the precise coupling profile your choice introduces across all 8 dimensions.
- **EDA Coupling Diagnosis** — *enables* → When you select Messaging as the style, EDA coupling diagnosis verifies which specific coupling dimensions that choice actually reduces (and which it leaves unchanged).
- **Canonical Data Model Decision** — *enables* → Choosing Messaging at N ≥ 3 integration points creates the translator-proliferation problem that CDM solves; style selection precedes and motivates the CDM decision.
- **Queue Control Flow Model** — *enables* → After selecting Messaging as the style, the control-flow model determines whether components should push or pull, which shapes the pipeline's ordering and latency properties.
- **Queue Flow Control Decision** — *precedes* → After selecting Messaging, flow control design is required to define what happens when producers outpace consumers; this is the next design question after style selection.

______________________________________________________________________

## Provenance

- **Source:** Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003)
