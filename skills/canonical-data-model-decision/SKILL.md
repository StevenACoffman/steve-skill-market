---
name: canonical-data-model-decision
description: |
  Invoke when N ≥ 3 applications must exchange data with each other, when a team is building translators for every pair of systems, when a legacy system is expected to be replaced and its replacement should not force rewrites in all connected systems, or when application field names disagree across systems and semantic disputes are slowing integration work.
---
# Canonical Data Model Decision

## Canonical Data Model Decision

**Source:** Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003) — Chapter 8 (Message Transformation): Canonical Data Model pattern

______________________________________________________________________

### R — Reading (Original Source)

> "Design a Canonical Data Model that is independent from any specific application. Require each application to produce and consume messages in this common format... A solution consisting of 6 applications requires 30 Message Translators without a Canonical Data Model and only 12 Message Translators when using a Canonical Data Model. The best advice is to use the more maintainable solution (i.e., the Canonical Data Model) unless performance requirements do not allow it."

______________________________________________________________________

### I — Interpretation

The Canonical Data Model (CDM) is a decision about translation architecture, not a data modeling exercise. The core problem it solves is combinatorial: if N applications must exchange data with each other, and each pair of applications speaks a different format, you need N×(N-1) translators. For six applications that's 30 translators. Add a seventh application and you must write six new translators immediately — one for each existing application. The system gets harder to extend with every addition.

The CDM collapses this to 2N translators: every application gets exactly one inbound translator and one outbound translator, connecting it to the shared canonical format. The seventh application still needs exactly two translators. Break-even is at N=3; with fewer than three applications the CDM requires more translators than direct translation (4 vs. 2 for a two-application system).

The cost of this simplification is double translation per message: source format → canonical → target format. This adds latency. For most integration scenarios this latency is acceptable — translation is stateless and can be parallelized. For extremely latency-sensitive paths the overhead may be prohibitive, but Hohpe's advice is to measure before ruling out the CDM rather than assuming it's too expensive.

The deeper and harder cost is governance. Defining the canonical format requires answering questions like: What does "account" mean? Is it a billing account, a login account, a relationship? Is it the same concept as what the ERP calls "payer" and the CRM calls "contact"? These are business-level semantic disputes that tooling cannot resolve. The CDM design meeting is where integration projects slow down — not because the technology is hard but because the semantics are contested. The governance burden is ongoing: every time a participating application changes its internal model, the canonical format may need updating, requiring negotiation across all stakeholders.

Two implementation choices matter: if you control the application's source code, a Messaging Mapper inside the application is preferable because it can resolve object-reference complexity before the message is serialized. For packaged applications (ERP, CRM, legacy systems) you cannot modify, an external Message Translator in the integration layer is the only option. Many real systems use both: a Messaging Mapper resolves object-relationship issues within the application, and a Message Translator handles structural field mappings in the channel.

The CDM belongs to the integration layer, not to application storage. This is a common confusion: the canonical format is not an enterprise data model that all applications must adopt internally. Applications keep their own storage schemas. Only the messages exchanged across application boundaries are expected to conform to the canonical format.

______________________________________________________________________

### A1 — Past Application (Author's Cases)

**WGRUS order processing** (c02): Widget-Gadget 'R Us integrated web, call-center, and fax order channels using three Message Translators feeding a single canonical NEW_ORDER channel. The Message Translators converted each channel's proprietary format to the shared canonical message, allowing all downstream order processing to be written once and reused across channels. Adding a new intake channel required exactly one new translator.

**Insurance company post-merger integration** (c03): After corporate mergers, an insurer had separate applications for life, health, auto, and home insurance. A Message Bus with a Canonical Data Model was introduced to allow new GUI applications to connect once to the bus rather than separately to each product system. Once the CDM was established for the agent GUI, adding the claims processor GUI, customer service GUI, and web interface required no changes to backend systems — exactly 2 translators per new GUI application.

**Pay-per-view viewership normalization** (c05): A provider received data from over 1,700 cable affiliates in dozens of formats (EDI, CSV, XML, Excel). Without a canonical format, any processing logic would need to handle every variant directly. The Normalizer pattern (a router dispatching to format-specific translators) reduced the variety problem to a well-defined set of inbound translators feeding a single canonical message downstream.

**The N² translator problem explicitly quantified** (f07): Hohpe provides the direct comparison — 6 applications × 5 targets = 30 translators without CDM; 6 applications × 2 (in/out) = 12 translators with CDM. The 7th application costs 12 new translators without CDM (one per existing app, bidirectional) versus 2 translators with CDM.

______________________________________________________________________

### A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- **N ≥ 3 applications must exchange data with each other** — this is the break-even point where CDM saves translator count
- **"Every time we add a new system we have to write a ton of integrations"** — the N² problem is present; CDM is the structural fix
- **A legacy system is expected to be replaced in 2–3 years** — CDM insulates all other applications from the replacement; without it, the replacement forces N-1 translator rewrites
- **Application field names disagree across systems** — "account" vs. "payer" vs. "contact" semantic conflicts are best resolved in the CDM design, not in every pairwise translator
- **An integration project is slowing down at the schema design phase** — this is likely the governance cost of CDM; naming it as such helps stakeholders understand it's unavoidable work, not a technical failure
- **A high-latency requirement is being cited to avoid CDM** — measure the actual translation overhead before ruling it out; stateless translation is parallelizable
- **A team is building translators for every pair of systems** — count the translators; if N×(N-1) is the current trajectory, introduce the CDM decision explicitly
- **A "shared enterprise data model" is being proposed for application storage** — distinguish CDM (integration format only) from application storage schema; conflating them creates a Shared Database anti-pattern

______________________________________________________________________

### E — Execution (Steps)

1. **Count the applications and integration relationships.** List every application that must exchange data with at least one other application in the integration scenario. Count N. Calculate N×(N-1) for the no-CDM case and 2N for the CDM case. If N < 3, direct translation is cheaper; if N ≥ 3, CDM reduces translator count now and every future addition costs 2 instead of 2(N-1).

2. **Identify the break-even and growth trajectory.** Is N expected to grow? If the system will add applications over time, CDM's advantage increases with each addition. A current N=2 that is expected to grow to N=6 within two years is a CDM candidate now; retrofitting CDM later is harder than designing it upfront.

3. **Assess the latency budget.** Determine whether the integration path is latency-sensitive. For most enterprise integrations (batch processing, order fulfillment, customer data sync), double translation latency is negligible. For real-time trading systems, payment confirmations under SLA, or streaming analytics pipelines, measure the translation overhead against the budget before deciding. Note that translation is stateless and can be parallelized.

4. **Identify the semantic conflicts.** For each major entity type exchanged (customer, order, account, product), list the field names and semantics in each participating application. Map the conflicts. The number and severity of semantic conflicts is the primary indicator of CDM governance effort. If "account" means three different things across three systems, that governance conversation must happen regardless of whether CDM is adopted — CDM just forces it to happen once rather than per-translator.

5. **Choose the implementation approach per application.** For applications you control, evaluate whether a Messaging Mapper inside the application is feasible (can handle object-graph complexity). For packaged or legacy applications, plan external Message Translators in the integration layer. Most real systems need both: Messaging Mappers in custom applications, Message Translators for packaged ones.

6. **Define the CDM as integration-layer format, not application storage.** Communicate explicitly to all stakeholders that the canonical format governs only messages exchanged across application boundaries. Internal storage schemas remain each application's own responsibility. This prevents the CDM from being conflated with a Shared Database schema and the political battles that follow.

7. **Establish a governance process.** Assign ownership of the canonical format. Define how changes to the format are proposed, reviewed, and versioned. This process does not need to be heavyweight, but it must exist — without it, applications will drift the format independently, negating the CDM's value.

______________________________________________________________________

### B — Boundary (When Not to Apply)

**N ≤ 2, unlikely to grow.** If only two applications need to exchange data and there is no credible plan to add a third, direct translation requires two translators and CDM requires four. Skip the CDM.

**Extremely tight latency budgets where double translation is prohibitive.** High-frequency trading, real-time pricing systems, and streaming analytics pipelines may not tolerate the additional translation hop. Measure before deciding — translation is often faster than assumed — but if the budget is tight enough, direct translation is the right choice.

**Simple, stable schemas where translation complexity is trivial.** If all participating applications already use nearly identical field names and structures, the CDM's governance overhead is not offset by translator simplification. A CDM that adds process without adding clarity is overhead without benefit.

**The CDM is not an enterprise data model.** Do not use the CDM pattern as justification for defining a single database schema that all applications must store data in — that is the Shared Database anti-pattern and recreates all its coupling problems. The CDM governs message format at application boundaries only.

**Schema governance can stall projects indefinitely.** The real cost of CDM is political: getting representatives from all application teams to agree on field semantics across organizational boundaries. In organizations with strong application silos and no integration governance function, this cost can exceed the translator-reduction benefit. In this context, a pragmatic starting point is a Normalizer (per-system translators routing to a common channel) without a fully resolved canonical format, evolving toward CDM as governance matures.

**The addenda do not address schema versioning strategy.** Hohpe defines the CDM pattern and its benefits but does not provide a versioning strategy for evolving the canonical format over time. In practice, you need an explicit schema evolution strategy (backward/forward compatibility, version tags in message headers, deprecation windows) to avoid simultaneous cutover requirements across all participating applications.

______________________________________________________________________

### Related Skills

- **Multidimensional Coupling Assessment** — *depends-on* → Coupling assessment identifies tight data-format coupling across N applications; the CDM decision follows as the structural remedy once that coupling is diagnosed.
- **EDA Coupling Diagnosis** — *depends-on* → EDA coupling diagnosis reveals that data-format coupling persists regardless of channel type; CDM is the pattern that addresses this dimension specifically when N ≥ 3 systems are involved.
- **Integration Style Selection** — *depends-on* → CDM is only relevant after Messaging (or Shared Database avoidance) is selected as the style; style selection is the prerequisite that creates the multi-translator problem CDM solves.
- **Messaging Observability Design** — *precedes* → After a CDM is in place, each translator becomes an integration component that should be instrumented; observability patterns (Wire Tap, Message History) apply at the canonical channel boundary.

______________________________________________________________________

## Provenance

- **Source:** Enterprise Integration Patterns, Gregor Hohpe & Bobby Woolf (2003)
