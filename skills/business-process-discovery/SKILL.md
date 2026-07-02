---
name: business-process-discovery
description: |
  Use this skill when a user needs to understand the business process that generates
  data BEFORE designing any data model — whether building a new model from scratch,
  diagnosing why an existing model produces wrong numbers, or inheriting a schema
  with unknown origins.

  Trigger signals:
  - "We're starting a new data model for [business process]"
  - "The schema we have doesn't answer the questions stakeholders are asking"
  - "We inherited this data but don't know what the business process was"
  - "Multiple teams are getting different numbers from the same source"
  - Any new data model design where the source is a human-facing business workflow
tags: [business-process, discovery, data-modeling, schema-design, domain-modeling]
---

# Business Process Discovery — Five-Component Framework

## R — Original Text (Reading)

> **Capture the Process Flow**
>
> First, identify the boundaries of a process's start and end. Every process must
> have a definitive moment when it begins: the **triggering event**, which could be
> an action, request, or specific condition that initiates the process. Every process
> must eventually end. What's the terminating event where the process finishes, and
> how is that communicated? This is the process's **outcome**.
>
> Equally important is the **business object in motion**, the central "thing" that is
> being acted upon and fundamentally changed as the process unfolds. This could be a
> tangible item, such as a shipment, a record, such as a customer profile, or an
> administrative entity, such as an order, claim, ticket, or request. Most business
> processes serve one purpose: to transition a core object from one state to the next.
>
> We must also identify the **actors** involved: the humans, automated systems, AI
> agents, or other components responsible for executing the work. Different actors
> have different implications for their responsibilities, inherent constraints, and
> levels of authority within the process.
>
> Finally, we map the **sequence of steps**: what actions occur, in what order, and
> what conditions govern the path between them.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 13

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Business process discovery is a precondition for data modeling, not an optional
preparatory step. The five-component framework — triggering event, outcome, business
object in motion, actors, sequence — produces the raw material from which every
subsequent modeling decision is derived. Without it, modelers work from schemas,
which encode what the current system does, not what the business requires.

Each component does specific work:

**Triggering event** must be precise enough to be unambiguous. "Someone decides to
start the process" is not a triggering event; "a completed loan application is
submitted" is. Vague triggers produce ambiguous grain: if you cannot identify exactly
when the process starts, you cannot identify the first event record your model must
capture.

**Outcome** sets the scope boundary. It prevents the model from expanding indefinitely
and establishes the definition of done for the process — which becomes the terminal
state in the state history table.

**Business object in motion** is the load-bearing component for data modeling purposes.
This is the concept — not the table name — that becomes the primary entity in the
model. The distinction matters: the table name encodes a system decision; the concept
encodes the business reality. A modeler who starts from the schema discovers the table
name and works backward. A modeler who discovers the business object in motion starts
from the business concept and works forward.

**Actors** determine relationships and ownership transitions. When a loan application
moves from the loan officer to the underwriter, the actor change is a foreign-key
change with its own event record. Actors also surface authority levels: an automated
credit scoring system has different authority and auditability requirements than a
human underwriter. Both must be modeled explicitly.

**Sequence** reveals grain. The step-by-step mapping — including conditional branches
and unhappy paths — exposes all the state transitions the primary entity can undergo.
Each state transition is a candidate event record. The unhappy paths are particularly
important: exceptions often create states that the happy path never surfaces, and
those states are frequently where the real grain decision lives.

The counterintuitive design principle: begin from the business process, not from an
existing schema. Schemas encode what the current system does; they do not capture what
the business requires. The Hellta airline case illustrates this directly — two years of
technically excellent schema work produced wrong numbers because the process was never
mapped. The engineering team modeled the systems; they never modeled the business.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Hellta Airline — Two Years of Technical Work, Wrong Numbers

- **Problem**: A major airline spent nearly two years migrating to a new data platform.
  The data team built optimized lakehouse schemas, complex ETL/ELT pipelines, and
  ensured all systems could connect and scale. The launch was a disaster. Numbers did
  not make sense. Business trust in the engineering team evaporated.
- **Root cause**: The engineers perfectly modeled the physical systems. They never
  modeled the business process. Specifically, they never mapped the "Flight Arrival"
  process across the two bounded contexts that each consumed it. Flight Operations and
  Customer Compensation both used the term "On-Time Arrival," but the process had never
  been traced through both domains, so the two different triggering conditions
  (wheels-down vs. gate-door-open) were never discovered and never explicitly modeled.
- **What discovery would have revealed**: The triggering event for Flight Operations
  is wheels-down. The triggering event for Customer Compensation is gate-door-open.
  The business object in motion — the Flight Arrival Record — needed both timestamps
  explicitly captured. The actors (cockpit crew, ground systems, compensation rules
  engine) operated under different authority levels and captured different data.
  None of this was in the schema because the process was never discovered.
- **Result**: Customer Compensation calculated $42M owed to passengers for Q3 delays.
  Finance reported $18M in delay liability. Accounts Payable disbursed $29M. The $24M
  gap could not be explained. The model was built on ambiguity because the business
  process was never the starting point.

### Case 2: E-Commerce JSON Blob — Three Teams, Three Incompatible Models

- **Problem**: An e-commerce company stored a product catalog as a JSON blob. The
  application team chose the structure and grain before any business process was
  documented. The analytics team and the ML team each extracted the data independently
  and made different incompatible assumptions about what the JSON represented.
- **Root cause**: The application team treated the data modeling decision as a
  system design decision. They optimized for application convenience without asking
  what business process generated the product catalog data, what the business object
  in motion was, or what the actors and sequence looked like. The analytics team
  assumed one grain; the ML team assumed another. Both were wrong relative to the
  actual business process.
- **How discovery would have changed the outcome**: Had someone mapped the product
  catalog management process first — identifying the triggering event (a buyer submits
  a new product listing), the business object in motion (the Product Listing concept),
  the actors (buyer, review system, category manager), and the sequence (draft → review
  → approved → published → deprecated) — the grain would have been explicit before any
  JSON schema was chosen. Three teams would have had one process map and one grain
  declaration rather than three incompatible implementations.

### Case 3: Mortgage Loan Approval Workflow — Executing the Five-Component Framework

- **Scenario**: A team is building a data model for a mortgage loan approval workflow.
  They have access to the loan origination system's database schema.
- **Why the schema is the wrong starting point**: The schema encodes what the system
  does, not what the business requires. The business process has actors, authority
  levels, conditional branches, and exception paths that the schema may partially
  capture but cannot make explicit.
- **Five-component discovery applied**:
  - **Triggering event**: A completed loan application is submitted by the borrower.
    (Not "the loan officer reviews an application" — that is a downstream step.)
  - **Outcome**: The loan is approved, declined, or withdrawn, with all required
    documentation executed and the file closed.
  - **Business object in motion**: The Loan Application concept — not the
    "Application" table in the schema. The concept has a lifecycle that spans the
    entire process; the table may only capture a snapshot.
  - **Actors**: Borrower, loan officer, underwriter, automated credit scoring system,
    compliance reviewer. Each has different authority levels: the automated system
    cannot override a compliance reviewer; the underwriter can conditionally approve
    with conditions the loan officer must then satisfy.
  - **Sequence**: Application intake → document verification → credit scoring →
    underwriter review → conditional approval → borrower document execution → closing.
    Unhappy path: what happens when the credit score is borderline? When a document is
    missing? When the borrower withdraws? Each unhappy path is a state that must be
    captured as its own event record.
- **Modeling output from discovery**: The grain becomes "one row per state transition
  per loan application," not whatever the schema currently stores. Actor hand-offs
  (loan officer to underwriter, underwriter to compliance reviewer) generate
  relationship change records. The five-component framework produced the model
  structure; the schema is now a downstream implementation artifact, not the source
  of truth.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **New data model design for a business workflow**: Any time a user is designing
   a schema for a process that involves people, systems, or decisions — before any
   table structure is chosen.
2. **Inherited schema with wrong numbers**: "We have a data model but the numbers
   it produces don't match what the business reports" — the process was never
   discovered and the schema encodes incorrect or incomplete assumptions.
3. **Multiple teams reporting different numbers from the same source**: The symptom
   of context collapse, which is caused by different teams making different
   incompatible process assumptions from the same schema.
4. **Schema doesn't answer the questions stakeholders are asking**: The schema was
   built to serve one use case; a new analytical requirement cannot be answered.
   The original process discovery (if it happened at all) did not anticipate this
   requirement.
5. **Process documentation is available**: Even with documentation in hand, a
   modeler should run through the five components explicitly to verify completeness,
   not assume the documentation is accurate.

### Language Signals (Activate When These Appear)

- "We're starting a new data model for [business process]"
- "The schema we have doesn't answer the questions stakeholders are asking"
- "We inherited this data but don't know what the business process was"
- "Multiple teams are getting different numbers from the same source"
- "What should one row represent in this table?" (for a process-origin table)
- "We need to model [workflow name]"

### Distinguishing from Adjacent Skills

- Difference from `process-to-model-translation`: Business process discovery is the
  DISCOVERY phase — producing the five-component description of the process through
  interviews, observation, and documentation review. Process-to-model-translation is
  the TRANSLATION phase — taking the completed five-component description and applying
  four mapping rules to convert it into model components (entity, event records, state
  history table, relationship changes). They are strictly sequential: discovery first,
  translation second.
- Difference from `tacit-knowledge-extraction`: Discovery is the goal; tacit knowledge
  extraction is the method used when standard documentation and interviews are
  insufficient. If process documentation is available and reliable, proceed directly
  to the five-component framework. If documentation is missing, stale, or contradicted
  by reality, apply the three field-research techniques (Gemba Walk, Artifact
  Archaeology, Unhappy Path Interviews) to recover the tacit knowledge before completing
  the five-component framework.
- Difference from `grain-decision-four-questions`: Grain decision applies the
  four questions once the business object in motion and sequence are known. Business
  process discovery is the upstream step that identifies what the grain-setting entity
  is. For any new model where the source is a human-facing workflow, run discovery
  first, then apply the four grain questions.

______________________________________________________________________

## E — Execution Steps

Once activated, work through the five components in order. Do not begin schema or
table design until all five components are documented.

1. **Identify the triggering event**

   - Ask: What is the specific condition, action, or request that definitively starts
     this process? Test for precision: can two people independently agree that this
     event has occurred at the same moment? If not, the trigger is too vague.
   - State the trigger as a declarative event: "A completed loan application is
     submitted by the borrower." Not "someone decides to start processing."
   - Completion criteria: One unambiguous triggering event statement exists.

2. **Define the outcome**

   - Ask: What is the terminating event? How is completion communicated? What are
     the possible terminal states (success, rejection, cancellation)?
   - Completion criteria: All terminal states are enumerated. The definition of done
     for the process is explicit.

3. **Identify the business object in motion**

   - Ask: What single thing is being transformed as this process unfolds? What concept
     — not what table — accumulates context (attributes, statuses, timestamps) at each
     step?
   - State it as a concept: "The Loan Application" (not "the applications table").
   - Completion criteria: One primary concept is named. If multiple objects are
     competing, the process likely spans more than one bounded context — which is
     itself a discovery finding.

4. **Enumerate the actors**

   - Ask: Who or what performs each step? Include humans, automated systems, and AI
     agents. For each actor, identify their authority level: Can they approve? Override?
     Escalate? Delegate?
   - Note where authority changes between actors — those transitions are candidate
     relationship changes in the data model.
   - Completion criteria: All actors named, authority levels noted, hand-off points
     identified.

5. **Map the sequence including unhappy paths**

   - Ask: What steps occur, in what order? What conditions trigger each branch?
   - Map the happy path first, then explicitly ask: "What happens when \[required
     input\] is missing?" "What happens when [actor] is unavailable?" Each answer
     is a state or branch to add.
   - Completion criteria: Happy path fully mapped. At least three unhappy paths
     documented. All state transitions — including exception states — listed.

**Hand-off to downstream skills**: Once all five components are documented:

- Use `process-to-model-translation` to apply the four mapping rules that convert
  the five components into entity, event records, state history table, and
  relationship changes.
- Use `bounded-context-swimlane-detection` if the sequence reveals swimlane crossings
  (hand-offs between departments, roles, or systems) that may represent bounded context
  boundaries.
- Use `grain-decision-four-questions` to set the grain once the business object in
  motion and full sequence are known.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The process is already fully documented with all five components**: If a complete,
  verified process map exists with triggering event, outcome, business object in
  motion, actors, and sequence all explicitly documented and validated with domain
  experts, proceed directly to `process-to-model-translation`. Do not re-run discovery
  for a process that has already been discovered.
- **Machine-generated or sensor processes with no human actors**: For IoT sensor
  streams, automated telemetry pipelines, or purely machine-driven processes with no
  human decision points, the five-component framework still applies in principle, but
  the actor analysis reduces to system component enumeration. The unhappy path
  analysis is replaced by failure-mode analysis. This is a different workflow.
- **The question is purely about aggregation or grain on an already-deployed model**:
  If the data model is in production and the question is about query correctness or
  grain validation, not about whether the model correctly captures the business process,
  use `grain-audit-checklist` or `aggregation-workflow-four-steps` instead.

### Failure Patterns Warned About by the Author

- **Physical-first modeling** (ce13): Beginning with "what database are we using?"
  rather than "what business process are we modeling?" produces a schema that encodes
  storage constraints rather than business requirements. The schema is an implementation
  artifact; the business process is the source of truth. Warning sign: the first
  decision in a modeling session is a technology choice.
- **Tacit knowledge gap** (ce11): Modeling from documentation instead of the real
  process produces a model of the idealized workflow, not the actual one. Key states,
  exception paths, and workarounds are missing. Dashboards systematically undercount
  real transactions. Warning sign: process documentation has not been updated in
  12+ months; shadow spreadsheets named FINAL_V[n] exist alongside official systems.
- **Context collapse** (ce10): Skipping process discovery and modeling directly from
  system logs or event streams without identifying actors and domain boundaries produces
  a flattened table that loses who did what, when, and in which domain context. Warning
  sign: a single "events" table is used by multiple departments with different
  definitions of the core entities.

### Author's Blind Spots / Limitations of the Era

- **AI-generated processes**: The chapter acknowledges that AI agents are increasingly
  actors within business processes and may eventually invent processes that no human
  designed. The five-component framework was designed for human-originated processes;
  applying it to AI-invented workflows requires extensions (recording the input context,
  prompts, and model version that led to each agent action) that are noted but not
  fully worked out in this chapter.
- **Scope definition for microservices**: The chapter notes that for microservice
  modeling, the scope is narrower — focused on a domain or subdomain rather than an
  end-to-end process. The five-component framework applies within the microservice
  boundary, but the process for determining that boundary (which subdomains warrant
  their own model) is covered under `bounded-context-swimlane-detection`, not here.

### Easily Confused Adjacent Methodologies

- **"Start from the schema"** (standard practice): The inverse of Reis's prescription.
  Most practitioners begin modeling by examining the existing schema or database and
  reverse-engineering what it represents. Reis explicitly identifies this as the
  Hellta failure mode: the schema encodes what the current system does; it does not
  capture what the business requires. Starting from the schema means starting from an
  implementation artifact rather than from the business reality the model is supposed
  to represent.
- **EventStorming**: A rapid, collaborative process-mapping technique aligned with
  DDD, where domain events (orange stickies), commands (blue stickies), and aggregates
  (yellow stickies) are mapped collaboratively. EventStorming produces the same
  five-component output as this framework — the triggering events are the commands,
  the business object in motion maps to the aggregates, and the domain events are
  the sequence steps. The five-component framework is the structured, interview-based
  equivalent for cases where a facilitated group session is not feasible.

______________________________________________________________________

## Related Skills

- **composes-with** `bounded-context-swimlane-detection`: The sequence map produced by discovery feeds directly into swimlane crossing analysis — every department hand-off in the sequence is a candidate bounded context boundary to verify.
- **composes-with** `process-to-model-translation`: Discovery produces the five-component process description that the four mapping rules of process-to-model-translation require as input — the two skills are strictly sequential.
- **composes-with** `tacit-knowledge-extraction`: When process documentation is missing or unreliable, the three field-research techniques (Gemba Walk, Artifact Archaeology, Unhappy Path Interviews) supply the raw evidence that completes the five-component description.
- **composes-with** `synthesis-checklist-cross-form`: Questions 1 and 2 of the synthesis checklist (business question and data forms inventory) are answered by the output of business process discovery before cross-form integration design begins.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f17+p35
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 13 — Seeing the Business
