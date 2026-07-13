---
name: process-to-model-translation
description: |
  Use this skill when a user has a business process diagram or a documented five-
  component process description (triggering event, outcome, business object in motion,
  actors, sequence) and needs to convert it into data model components: primary entity,
  event records, state history table, and relationship changes.

  Trigger signals:
  - "How do I model this workflow?"
  - "We need to track the history of changes to this entity"
  - "We need to know which step a request is currently in"
  - "We have a process diagram — how do we turn it into a schema?"
  - Any schema design question for a workflow, approval process, or state machine
tags: [process-modeling, event-sourcing, state-history, data-modeling, schema-design]
---

# Process-to-Model Translation — Four Mapping Rules

## R — Original Text (Reading)

> **From Process Flow to Data Model**
>
> First, something triggers a process against some business object, which is our
> **entity** (Order, Claim, or Ticket). This entity is what drives the process forward.
> Second, every action in the workflow becomes a discrete **event**. These events are
> the verbs of your model, capturing the "who, what, and when." Third, the workflow
> execution steps drive **state changes** to the entity. The data model must capture
> not just the current state (e.g., Shipped), but the history of how it got there.
> Finally, the **actors** dictate the relationships. As ownership passes from sales to
> fulfillment, the relationships between the core entity and the actors shift.
>
> As the entity moves through the process, it accumulates context. Attributes are
> added, statuses are updated, and timestamps are recorded. The data model is the
> process's cumulative memory.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 13

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Process-to-model translation is the bridge between business discovery and technical
schema design. Its input is a completed five-component process description (from
`business-process-discovery`). Its output is a set of model components: a primary
entity, event records, a state history table, and relationship change records. Four
mapping rules govern the translation.

**Rule 1: Business object in motion → primary entity.** The central thing being
transformed through the process becomes the primary entity in the data model. This
is a concept, not a table name — the Loan Application, the Support Ticket, the
Purchase Order. It is the anchor to which all events, states, and relationships attach.
The entity accumulates context as the process progresses: attributes are added, statuses
are updated, and timestamps are recorded. The entity is the through-line of the model.

**Rule 2: Every workflow action → event record.** Each step in the process sequence
is a workflow action that produces an event record. An event record captures three
things: who performed the action (actor), what changed (state or attribute change),
and when (event timestamp). Event records are immutable — they are never updated.
They are the model's factual log of what happened. This is not a trigger on a table;
it is a first-class entity: a table whose grain is "one row per action taken on the
business object."

**Rule 3: Each state transition → timestamped row, not an overwrite.** The state of
the business object changes at each workflow step. A current-state-only model stores
the current status and overwrites it at each transition. A process-derived model
stores each transition as a new timestamped row in a state history table. The
resulting model can answer both "what is the current state?" (by querying the most
recent row) and "how did it get there?" (by querying all rows in sequence). The
current-state-only model permanently cannot answer the latter question once a
transition has occurred. This is the load-bearing rule — the one that most
practitioners violate by default.

**Rule 4: Actor hand-offs → relationship changes with their own event records.** When
ownership moves from one actor to another — loan officer to underwriter, tier-1 support
to tier-2 escalation, fulfillment team to shipping carrier — that transition is not just
a status update. It is a foreign-key change (the relationship between the primary entity
and the actor changes) and it warrants its own event record: who transferred ownership,
who received it, when, and under what conditions. Without this rule, the model knows
the current owner but cannot reconstruct the hand-off history.

The non-obvious design principle underlying all four rules: "The model is a cumulative
memory of the process, not a snapshot of current state." Most practitioners design for
current-state queries because those are the queries the original stakeholders articulate.
The gap appears later — when someone asks a historical question that the model cannot
answer. At that point, the history is gone: it was overwritten at every state transition.
The process-to-model translation rules prevent this by treating state history as the
primary design goal, with current state as a derived view.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Order Processing Workflow — Mapping Four Actor Hand-Offs to Event Records

- **Situation**: A typical order fulfillment process: a customer places an order
  (Sales), the order is picked and packed (Fulfillment), shipped by a carrier
  (Shipping), and delivered (Delivery/Customer). Four swimlanes, three hand-offs.
- **Rule 1 applied**: Business object in motion is the Order. Primary entity: Order,
  with a unique order_id and accumulating attributes.
- **Rule 2 applied**: Each workflow action becomes an event record. Order Placed is
  an event: actor = customer, state_change = Created, timestamp = order_placed_at.
  Order Fulfilled is an event: actor = fulfillment_system, state_change = Fulfilled,
  timestamp = fulfilled_at. Order Shipped is an event: actor = shipping_carrier,
  state_change = Shipped, timestamp = shipped_at. Order Delivered is an event:
  actor = delivery_driver, state_change = Delivered, timestamp = delivered_at.
- **Rule 3 applied**: Each of these transitions produces a new row in an
  OrderStateHistory table: (order_id, from_state, to_state, event_at). Not an UPDATE
  to the Order table's status column. The Order table carries a current_state column
  as a derived convenience, but the authoritative record of how the order got there
  is the state history table.
- **Rule 4 applied**: Each hand-off (Sales → Fulfillment, Fulfillment → Shipping,
  Shipping → Delivery) is a relationship change — who currently owns the order shifts.
  Each hand-off generates an ownership change event record: (order_id, from_actor_id,
  to_actor_id, handed_off_at, handoff_reason). Without this, the model knows who
  delivered the order but cannot reconstruct when it left the fulfillment team or why.
- **Capability produced**: The model can answer "where is this order right now?"
  (query OrderStateHistory for the most recent row) and "how long did it sit in
  fulfillment before being shipped?" (query the time between the Fulfilled and Shipped
  event rows). Neither question requires rebuilding or re-ingesting data.

### Case 2: Customer Support Ticket Synthesis — Bitemporal State History Preserves Both History and Corrections

- **Situation**: A customer support system tracks tickets through states: Open →
  Assigned → Escalated → Resolved. Tickets are sometimes re-assigned between agents;
  SLA tiers can change mid-ticket (Medium → High priority). The model must support
  both historical analysis ("how long did this ticket spend in each state?") and
  corrections ("we discovered the ticket was miscategorized; what did the system
  believe its state was before the correction?").
- **Rule 2 applied**: Every ticket state transition is an event record. The
  TicketEvent table carries: (ticket_id, event_type, from_state, to_state, actor_id,
  event_at). Event types include: Created, Assigned, Escalated, Resolved,
  Reopened, Recategorized.
- **Rule 3 applied**: SLA tier changes are state transitions. An escalation from
  Medium to High priority produces a new row in TicketStateHistory: (ticket_id,
  sla_tier_from, sla_tier_to, effective_at). When a correction is entered
  retroactively — "this ticket was always High priority but was miscategorized" —
  a bitemporal model preserves both the original belief (the Medium tier row as
  recorded at system time) and the corrected state (the retroactive High priority
  with a different valid_from). A current-state-only model would overwrite and lose
  what the system believed at the time.
- **Rule 4 applied**: Agent reassignments are actor hand-offs. Each reassignment
  generates a TicketOwnershipChange record: (ticket_id, from_agent_id, to_agent_id,
  reassigned_at, reason). When the HR team later asks "how many tickets changed
  agents in the first 7 days and what was the reason?" — this table answers directly.
- **Capability produced**: The model answers both "what is the current state of
  this ticket?" and "what did we believe its priority was on the day it was first
  escalated, before the correction was entered?" — a requirement that a
  current-state-only model permanently cannot satisfy.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **New workflow schema design**: A user has a process diagram (or a five-component
   process description) and is designing a schema for the first time.
2. **"We need to track history" request**: A stakeholder has asked for the ability
   to query how an entity reached its current state, or to see the full audit trail.
   This is the direct application of Rule 3.
3. **"Which step is it currently in?" requirement**: Real-time or near-real-time
   status tracking for in-flight process instances. This requires an event records
   table (Rule 2) and a state history table (Rule 3) to reconstruct the current
   position in the workflow.
4. **Approval process or state machine schema**: Any multi-step process with
   conditional branches and actor decisions — loan approvals, compliance workflows,
   procurement approvals, onboarding checklists.
5. **Historical question that the current model cannot answer**: "We need to know how
   long orders sat in fulfillment last quarter" — a question the current model cannot
   answer because it only stores the current state. This is the retroactive
   recognition that Rule 3 was violated. The fix requires rebuilding from upstream
   source data if available.

### Language Signals (Activate When These Appear)

- "How do I model this workflow?"
- "We need to track the history of changes to this entity"
- "We need to know which step a request is currently in"
- "We have a process diagram — how do we turn it into a schema?"
- "We need an audit trail for [entity]"
- "How did this [entity] get to its current state?"
- "We need to know when [actor] handed off to [actor]"

### Distinguishing from Adjacent Skills

- Difference from `business-process-discovery`: Discovery produces the five-component
  process description (what the process IS — triggering event, outcome, business object
  in motion, actors, sequence). This skill takes that description and applies the four
  mapping rules to convert it into model components. They are strictly sequential:
  discovery first, translation second. If the five-component description does not yet
  exist, apply `business-process-discovery` first.
- Difference from `grain-decision-four-questions`: Rule 3 of this skill implies a grain
  of "one row per state transition of the business object." The four grain questions
  apply after the initial grain candidate is established — they validate whether this
  grain is fine enough for all known analytical requirements and test the storage cost.
  Grain decision is applied to the output of translation, not before it.
- Difference from `temporal-depth-selection`: Rule 3 produces a state history table
  that is unitemporal by default (tracks valid time — when each state was true in the
  world). The temporal depth decision — whether to add transaction time (bitemporal)
  to track when the system recorded each state — is a separate, downstream decision
  made with `temporal-depth-selection`. The case 2 example above (customer support
  with retroactive corrections) is the trigger for upgrading to bitemporal.

______________________________________________________________________

## E — Execution Steps

Once activated, work through the four mapping rules in order for the documented process.

1. **Apply Rule 1 — Identify the primary entity**

   - Input: the business object in motion from the five-component process description.
   - Action: declare the primary entity as a concept (not a table name). State what
     it represents: "The Loan Application is the thing being transformed through the
     mortgage approval process."
   - Define: what attributes does the entity accumulate as it moves through the
     process? List the attributes that appear or change at each step.
   - Completion criteria: primary entity named as a concept; accumulating attributes
     listed; entity's unique identifier defined.

2. **Apply Rule 2 — Map each workflow action to an event record**

   - Input: the sequence of steps from the five-component process description.
   - Action: for each step in the sequence (including unhappy paths), define one
     event record type: (actor who performed it, what changed, event timestamp).
   - Design the event records table: (entity_id, event_type, actor_id, change_detail,
     event_at). Every row is immutable — never updated after insert.
   - Completion criteria: every step in the process (happy path + documented unhappy
     paths) maps to exactly one event type. Event types are named as past-tense actions:
     LoanApplicationSubmitted, DocumentVerificationCompleted, CreditScoreComputed.

3. **Apply Rule 3 — Map each state transition to a timestamped row**

   - Input: the state changes implied by the sequence (each step changes the entity's
     status or a key attribute).
   - Action: design a state history table: (entity_id, from_state, to_state,
     effective_at). Every state transition produces a new row — never an UPDATE to
     the primary entity's status column.
   - Decide on temporal depth: if corrections must be auditable (what did the system
     believe before the correction?), upgrade to bitemporal: add recorded_at to
     capture when the system recorded each state row.
   - Completion criteria: state history table designed. Every possible state transition
     from the process sequence has a corresponding row structure. Primary entity table
     may carry a current_state column as a derived convenience, but state history table
     is the authoritative record.

4. **Apply Rule 4 — Map actor hand-offs to relationship change records**

   - Input: the actor transitions identified in the process sequence — each moment
     when ownership moves from one actor to another.
   - Action: design a relationship change records table: (entity_id, from_actor_id,
     to_actor_id, handed_off_at, handoff_reason). Every hand-off produces one row.
   - Completion criteria: every swimlane crossing in the process sequence (from
     `bounded-context-swimlane-detection` or identified during this translation) maps
     to a hand-off event record type.

**Verify the model's capability**: After applying all four rules, confirm the model
can answer both classes of question:

- Current state: "What is the current state of this entity?" — answered by querying
  the state history table for the most recent row.
- Historical reconstruction: "How did it get to its current state?" — answered by
  querying all state history rows for this entity in sequence.

If either class of question cannot be answered, identify which rule was partially
applied and complete it.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **No five-component process description exists**: If the business process has not
  been discovered and documented with its five components, there is no valid input
  for the four mapping rules. Applying translation rules to an undiscovered process
  produces the same failure mode as starting from the schema — encoding assumptions
  rather than reality. Run `business-process-discovery` first.
- **Machine-generated or sensor data with no human-interpretable state machine**: For
  IoT sensor streams or purely automated telemetry, the "state transitions" and "actor
  hand-offs" may not exist as discrete business events. Rule 2 and Rule 4 still apply
  in principle (which component triggered what change?), but the process is different
  enough that a sensor-specific modeling approach may be needed.
- **The existing model is in production and the historical data is gone**: Rule 3
  requires that state transitions be captured as new rows. If the current model uses
  in-place updates and the historical states are overwritten, applying these rules to
  the existing model does not recover the lost history. The question becomes "can we
  recover the history from upstream source systems?" — an infrastructure question
  outside the scope of this skill.

### Failure Patterns Warned About by the Author

- **Overwrite-in-place state updates** (Rule 3 violation): The most common failure.
  A model stores the current status in a single column and updates it at each
  transition. The history is permanently lost. Warning sign: the primary entity table
  has a status or state column but no state history table; a historical question like
  "when did this entity enter state X?" cannot be answered. The fix requires rebuilding
  from upstream source data if available.
- **Missing actor hand-off records** (Rule 4 violation): The model knows who currently
  owns an entity but cannot reconstruct the hand-off history. Warning sign: there is
  no table recording ownership transitions; the "assigned_to" column on the primary
  entity is overwritten at each reassignment. The failure becomes visible when someone
  asks "how many times did this entity change owners and why?" — a question the model
  cannot answer. (See V2 novel question: the EmployeeManagerHistory case.)
- **Physical-first modeling** (ce13): Applying these rules to a schema that was built
  to fit a storage system rather than to model a business process produces a model that
  adds history tracking on top of a structurally wrong foundation. The correct order
  is: discover the process → set boundaries → apply translation rules → choose storage
  technology. Technology choice is the last step, not the first.

### Author's Blind Spots / Limitations of the Era

- **Event sourcing vs. derived state**: The four mapping rules produce an event-sourced
  model — the authoritative record is the event log; the current state is derived.
  This is the correct design for auditability and historical queries. However, the
  chapter does not address the performance tradeoffs of event sourcing at scale (very
  long event logs requiring snapshot materialization) or the query complexity for
  applications that need current state frequently. These tradeoffs are acknowledged as
  real but the resolution is left to the physical modeling chapter (volume 2's scope).
- **AI agent process actions**: For processes where an AI agent is an actor, Rule 2
  requires capturing the input context (prompts, available tools, model version) that
  led to each agent action — not just the action itself. This is noted in the chapter
  but the full event record schema for AI agent actions is not specified.

### Easily Confused Adjacent Methodologies

- **CRUD-based entity modeling** (standard database practice): The default for most
  relational modeling is to store current state and update in place. This violates Rule
  3 by design. CRUD modeling optimizes for write simplicity and current-state queries
  at the cost of all historical reconstruction capability. Reis's rules are the event-
  sourced alternative: optimize for historical reconstruction and treat current state
  as a derived view. The choice is not arbitrary — CRUD models produce permanent data
  loss at every state transition; event-sourced models preserve history indefinitely.
- **SCD Type 2 (Slowly Changing Dimension)**: The standard data warehousing technique
  for preserving attribute history using effective_from / effective_to date columns.
  SCD Type 2 is a partial implementation of Rule 3 — it captures the history of
  attribute changes but typically does not capture the event (who changed it, why) or
  the relationship changes (Rule 4). It also uses CRUD updates to close out the
  previous row, which means corrections can silently overwrite the prior belief state.
  Upgrading SCD Type 2 to bitemporal (adding a recorded_at column) and adding event
  records completes the four-rule translation.

______________________________________________________________________

## Related Skills

- **depends-on** `business-process-discovery`: The four mapping rules require the five-component process description as their input — without a completed discovery, there is no valid artifact for this skill to translate into model components.
- **composes-with** `temporal-depth-selection`: Rule 3 of this skill produces a state history table that is unitemporal by default; temporal-depth-selection determines whether an upgrade to bitemporal is needed based on whether corrections must be auditable or ML training requires historical feature values.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f19
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 13 — Seeing the Business
