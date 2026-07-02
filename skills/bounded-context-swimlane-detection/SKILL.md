---
name: bounded-context-swimlane-detection
description: |
  Use this skill when a user is designing a data model that must serve multiple
  departments, roles, or systems — and needs to determine whether shared terms mean
  the same thing on both sides of each organizational hand-off.

  Trigger signals:
  - "We're building a unified [entity] table that multiple teams will use"
  - "Team A and Team B disagree on what '[term]' means"
  - "We're doing a data platform consolidation"
  - "The same concept appears in multiple systems with different definitions"
  - Any cross-team or cross-system data integration design
tags: [bounded-context, domain-driven-design, swimlane, integration, data-modeling]
---

# Bounded Context Detection via Swimlane Crossing Analysis

## R — Original Text (Reading)

> **From Business Process Swimlanes to Bounded Contexts**
>
> In a process view, you use swimlanes to indicate which department or role performs
> each step. In the data world, these swimlanes often represent Bounded Contexts.
>
> A **Bounded Context** is a linguistic boundary where terms have specific,
> unambiguous meanings.
>
> In the Sales Context, a "Customer" is a lead who has expressed interest. In the
> Fulfillment Context, a "Customer" is a shipping address and a recipient name. In the
> Finance Context, a "Customer" is a tax ID and a credit ledger.
>
> If you try to create a single, global "Customer" model that satisfies all these
> contexts, you are likely doing more harm than good. You might end up with a table
> containing dozens or hundreds of columns, each a slight nuance on "Customer," half
> of which are null, because the Shipping team doesn't care about the customer's credit
> score, and the Sales team doesn't care about the loading dock number.
>
> Process modeling highlights these boundaries. Every time a process arrow crosses
> a swimlane (e.g., Sales hands off to Fulfillment), you are likely crossing a Bounded
> Context. This is a data quality risk zone.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 13

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Bounded context detection is a diagnostic procedure applied to a business process
map. The input is a process swimlane diagram (or an equivalent understanding of
which roles and departments perform which steps). The output is a set of confirmed
context boundaries — each of which dictates a different design decision.

The procedure has two phases: **candidate identification** and **verification**.

**Candidate identification** uses a single structural heuristic: every swimlane
crossing in the process map is a candidate boundary. A swimlane crossing is any
hand-off — any moment when work moves from one department, role, or system to
another. The hand-off does not need to be contentious or unusual; the mere structural
fact that the process crosses an organizational line is sufficient to flag it as a
candidate. This heuristic is deliberately over-inclusive: it produces false positives
(some crossings will not turn out to be boundaries) but ensures no real boundary is
missed.

**Verification** uses one diagnostic question, applied to domain experts on each side
of each crossing: "What is a [shared entity name] to you?" The shared entity name is
typically whatever the primary business object in motion is called as it crosses the
boundary (Customer, Order, Patient, Flight Arrival). If both sides produce the same
definition, the crossing is not a bounded context boundary — it is simply a handoff
within a shared context. If the definitions diverge, the boundary is confirmed.

The decision at a confirmed boundary is binary:

- **Within a bounded context**: use the domain's ubiquitous language directly in
  column names and entity names. The term means what this domain says it means; encode
  that precisely.
- **At a boundary**: build explicit translation or mapping logic. Do not force one
  definition to serve both contexts. Model the two contexts separately and build a
  mapping table or translation layer that links equivalent entities across contexts.

The anti-pattern that this skill prevents is the global model: a single table for a
shared entity that attempts to satisfy all bounded contexts simultaneously. Such a
table will contain dozens of context-specific columns, half null for any given consumer.
Two teams querying the same table will apply different implicit filters to exclude the
nulls irrelevant to their context — and will produce different counts from the same
table for the same question. This is not a data quality problem; it is a modeling
problem caused by not detecting the boundary before design.

The diagnostic question is the key tool. It must be asked to people who actually do
the work in each domain — not to managers who believe the concept is shared, but to
the analysts, coordinators, and systems that consume the entity day to day. The
definition "Customer = lead who has expressed interest" and "Customer = shipping
address and recipient name" will not surface in an executive meeting; they emerge only
when the people who actually process customers are asked directly.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Hellta $24M Gap — Unanalyzed Swimlane Crossing Between Two Contexts

- **Situation**: Hellta's "Flight Arrival" process flows through two swimlanes: Flight
  Operations and Customer Compensation. The hand-off occurs at the moment the flight
  arrives. Both contexts care about "On-Time Arrival."
- **What the crossing analysis would have revealed**: Flight Operations and Customer
  Compensation are adjacent swimlanes. The process arrow crosses from one to the other
  at the flight arrival event. This is the candidate boundary. Applying the diagnostic
  question — "What is an On-Time Arrival to you?" — to each side produces:
  - Flight Operations: wheels-down time. This drives runway occupancy, taxi time,
    and gate assignment metrics. The operational system records the wheels-down timestamp
    as the arrival event.
  - Customer Compensation: gate-door-open time. This determines whether a passenger
    was delayed. The compensation rules engine evaluates the gate-door-open timestamp
    against the scheduled arrival window. The difference between these two timestamps
    can be several critical minutes.
- **What happened without the analysis**: No one asked the diagnostic question. Both
  contexts used the same term — "On-Time Arrival" — but consumed different underlying
  data. A shared model was built that collapsed the two definitions into a single
  arrival_timestamp column, destroying the distinction.
- **Result**: Customer Compensation calculated $42M owed for Q3 delays. Finance
  reported $18M in delay liability. Accounts Payable disbursed $29M. The $24M gap
  could not be explained. To this day, no one can identify who was paid by mistake
  or which delayed passengers were ignored. The flight arrival entity needed, at
  minimum: wheels_down_timestamp (owned by Flight Ops), gate_door_open_timestamp
  (owned by Customer Compensation), and scheduled_arrival_timestamp (shared reference).
  The swimlane crossing was discoverable; it was simply never analyzed.

### Case 2: Healthcare Patient Unification — Three Confirmed Boundaries, One Wrong Approach

- **Situation**: A healthcare system wants to unify patient data across an outpatient
  clinic, an inpatient hospital, and a billing department into a single "Patient" table.
  Before schema design begins, the swimlane structure must be analyzed.
- **Candidate identification**: Three swimlanes (Outpatient, Inpatient, Billing) with
  two crossings: Outpatient-to-Inpatient hand-off (when a patient transitions from
  clinic to hospital admission) and Inpatient-to-Billing hand-off (when a hospitalized
  patient generates a billable account).
- **Verification — diagnostic question applied to each context**:
  - Outpatient: "A patient is anyone with an active care plan."
  - Inpatient: "A patient is anyone currently admitted or within 30 days post-discharge."
  - Billing: "A patient is a billing account tied to an insurance policy and a guarantor."
- **Result of verification**: Three diverging definitions confirm three bounded
  contexts. The same real-world person is a Patient in all three senses, but the
  concept has three different meanings, three different lifecycles, and three different
  sets of required attributes.
- **Correct design**: Do not build one unified Patient table. Build three
  context-specific models: ClinicalPatient (outpatient), AdmittedPatient (inpatient),
  BillingAccount (billing). Build a mapping table that links entities with the same
  real-world person across contexts (linked by a durable real-world identifier such as
  a medical record number). Build translation logic at each swimlane crossing — a
  trigger that creates an AdmittedPatient record when a ClinicalPatient is admitted
  inpatient, and a BillingAccount when that admission generates a billable encounter.
- **What a unified Patient table would have produced**: A table with columns for
  care_plan_status, days_post_discharge, insurance_policy_id, guarantor_id, and
  hundreds of others — half null for any given context — with three teams producing
  different "patient count" figures from identical queries.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Cross-team data integration**: Any time two or more teams will share a table or
   platform for a concept that each team uses independently in their own processes.
2. **Platform consolidation**: Merging data from multiple systems that previously
   operated in separate organizational domains, even if they nominally track the same
   entities.
3. **"One source of truth" initiatives**: A mandate to build a unified model for
   Customer, Order, Product, or any other shared entity across departments. This is
   precisely the scenario that produces bounded context collisions if the boundary
   analysis is skipped.
4. **Conflicting numbers from the same table**: If two teams query the same table and
   get different numbers without any query difference, a boundary was not detected
   before the model was built. This skill diagnoses what went wrong and what the
   correct design should have been.
5. **New entity design for a cross-department process**: Any schema design task where
   the entity travels through more than one organizational swimlane.

### Language Signals (Activate When These Appear)

- "We're building a unified [entity] table that multiple teams will use"
- "Team A and Team B disagree on what '[term]' means"
- "We need a single source of truth for [entity]"
- "Multiple systems have different definitions of [shared concept]"
- "Two teams are getting different numbers from the same table"
- "We're consolidating our CRM / ERP / data platform"

### Distinguishing from Adjacent Skills

- Difference from `business-process-discovery`: Business process discovery maps the
  five components of a process; this skill is applied to the output of that discovery.
  Specifically, the sequence map produced by discovery is the input to swimlane
  crossing analysis. The two skills are sequential: discover the process first, then
  analyze the crossings.
- Difference from `semantic-vocabulary-ladder`: Swimlane crossing detection confirms
  whether a boundary exists and which entities require separate models. The vocabulary
  ladder is the tool for resolving vocabulary differences once boundaries are known —
  it selects the appropriate level of formalization (controlled vocabulary, thesaurus,
  taxonomy, ontology) for the translation layer. Detection comes first; vocabulary
  resolution comes second.
- Difference from `process-to-model-translation`: Translation applies the four mapping
  rules within a bounded context. This skill determines whether a single context exists
  or whether translation logic is needed between contexts. Determine context boundaries
  first; then apply translation rules within each context.

______________________________________________________________________

## E — Execution Steps

Once activated, execute in three phases. Do not proceed to schema design before phase 3.

1. **Draw the swimlane map**

   - Input: a business process map (from `business-process-discovery`) or equivalent
     understanding of which department, role, or system performs each step.
   - Action: draw or annotate the map with explicit swimlane boundaries. Each lane
     represents one organizational actor (department, role, external system).
   - Completion criteria: every step in the process is assigned to exactly one
     swimlane. Every hand-off between steps in different swimlanes is explicitly marked.

2. **Identify all swimlane crossings as candidates**

   - Action: list every hand-off point in the map where work moves from one swimlane
     to another. Each crossing is a candidate bounded context boundary.
   - Note the shared entity name at each crossing — this is the term whose definition
     will be tested in phase 3.
   - Completion criteria: every crossing is listed. Do not filter at this stage;
     include every crossing regardless of whether it seems significant.

3. **Verify each candidate with the diagnostic question**

   - For each crossing: ask domain experts on each side, "What is a \[shared entity
     name\] to you?" Ask people who do the work, not managers.
   - Compare answers:
     - **Same definition**: crossing is not a bounded context boundary. The two
       swimlanes operate in a shared context. Document the shared definition as the
       ubiquitous language for this entity in this context.
     - **Different definitions**: boundary is confirmed. Document both definitions
       as distinct concepts requiring separate models and translation logic.
   - Completion criteria: every crossing has been verified. Each confirmed boundary
     has documented definitions from each side.

4. **Make the design decision for each confirmed boundary**

   - Within a context: use the domain's ubiquitous language directly in column names
     and entity names. Do not introduce generic or ambiguous names.
   - At a boundary: design separate entity models for each context and a mapping table
     or translation layer that links entities representing the same real-world object.
     The mapping table carries the durable cross-context identifier and the
     context-specific identifiers for each side.
   - Completion criteria: every confirmed boundary has an explicit design decision
     (separate models + mapping layer) documented before schema work begins.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Single-context processes**: If the entire process is performed within one
  department or system, with no swimlane crossings, bounded context analysis is not
  needed. Map the process with `business-process-discovery` and proceed directly to
  `process-to-model-translation`.
- **Crossings where definitions are already known to be shared**: If domain experts on
  both sides of a crossing have already validated that they share the same definition
  for the key term, the verification step confirms no boundary and the crossing
  requires no special design treatment. The diagnostic question still should be asked
  (to confirm rather than assume), but the design decision is straightforward.
- **Microservice boundary design as a software architecture question**: DDD bounded
  contexts are used in software architecture to determine service boundaries.
  This skill is specifically about data model boundary detection — it produces
  decisions about separate entity models and translation layers, not about microservice
  deployment topology or API design.

### Failure Patterns Warned About by the Author

- **Bounded context collision** (ce12): One term, two definitions, one table. The
  canonical failure: a global entity model is built for a concept shared across
  contexts. The table accumulates context-specific columns for each domain, half of
  which are null for any given consumer. Two teams querying the table apply different
  implicit null-exclusion filters and produce different counts. Warning sign: a core
  entity table has more than 50 columns and >30% null values across common queries; two
  teams querying the same table for the same entity count return different numbers.
- **Context collapse** (ce10): When event streams from different domains are merged
  into a single table without preserving domain-specific actor, timestamp, and semantic
  metadata, the distinctions are erased. Context collapse is bounded context collision
  applied to events rather than entities. Warning sign: a single "events" table is
  queried by multiple departments; zombie records exist with no traceable provenance.

### Author's Blind Spots / Limitations of the Era

- **AI agents as context consumers**: The chapter notes that bounded contexts are
  essential for RAG systems because they provide semantic boundaries indicating which
  definition of truth applies. The specific design patterns for encoding bounded context
  boundaries in vector stores, embedding metadata, and retrieval filters are noted as
  important but are not detailed in this chapter — they are in the AI-integration
  chapter and in volume 2.
- **Evolving boundaries**: The chapter describes bounded contexts as relatively stable
  but acknowledges that organizational restructuring, mergers, and process redesigns
  can shift context boundaries. No process for detecting and responding to boundary
  changes over time is specified.

### Easily Confused Adjacent Methodologies

- **"Single source of truth" consolidation** (common practice): The conventional
  response to conflicting numbers from multiple systems is to build a unified, canonical
  model that all teams share. Reis identifies this as the failure mode — the unified
  model collapses bounded context distinctions that exist for legitimate business
  reasons. The correct response to conflicting definitions is to confirm whether the
  conflict reflects a real boundary, and if it does, to formalize the boundary rather
  than suppress it. A single source of truth per bounded context is correct; a single
  source of truth across bounded contexts is the bounded context collision anti-pattern.
- **DDD in software architecture** (related but distinct): Domain-Driven Design uses
  bounded contexts to determine service boundaries in software systems. This skill
  applies the same concept specifically to data model boundaries — it produces decisions
  about entity model scope and translation layer design, not about microservice topology.
  The diagnostic question ("What is a [term] to you?") is Reis's operationalization of
  the DDD concept for data modeling practice.

______________________________________________________________________

## Related Skills

- **depends-on** `business-process-discovery`: The swimlane map used for crossing analysis is produced by business process discovery — the sequence of steps and actor hand-offs from discovery is the direct input to this skill's candidate identification phase.
- **composes-with** `semantic-vocabulary-ladder`: Each confirmed boundary identifies terms that carry different definitions on each side; the vocabulary ladder then determines what level of formal shared vocabulary (controlled vocabulary through ontology) the translation layer requires.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f18
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 13 — Seeing the Business
