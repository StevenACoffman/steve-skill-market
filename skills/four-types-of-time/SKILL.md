---
name: four-types-of-time
description: |
  Use this skill when a user needs to identify, name, or separate the distinct types
  of time present in a dataset, schema, or system — before designing any time-based
  feature, column, or query.

  Trigger signals:
  - "We have a timestamp column and need to filter by date"
  - "The numbers change depending on when I run the query"
  - "We need to know what the data looked like on a specific past date"
  - "Our ML model degrades in production" (temporal issue as root cause)
  - Any schema design question involving more than one time-related column
  - A column named "created_at", "timestamp", or "date" is being used to answer
    multiple distinct time-based questions
tags: [time, temporal-modeling, event-time, valid-time, data-modeling, ML-features]
---

# Four Types of Time — Identification and Separation

## R — Original Text (Reading)

> **Event time** is when something actually happened in the real world. It's the
> moment the fighter threw the punch, the customer clicked buy, and the system
> crashed. This is the truth. Everything else is a variation on when that truth
> made it into your system.
>
> **Ingestion time** represents the point at which information reaches your system.
> Effectively, it is the marker recorded right at the moment of entry... Ingestion
> time can lag far behind event time, or it can happen before.
>
> **Processing time** is when your system actually works on the data — parsing,
> validating, transforming, and loading data. It's when computation happens, and it
> can be totally disconnected from when the data arrived.
>
> **Valid time** [is] when a fact is actually true in the real world. A customer's
> address isn't just one event. It's a series... Valid time tracks the actual
> lifespan of that truth.
>
> Companies have been destroyed in minutes because their systems confused one type
> of time with another — deployment time, execution time, market time — all tangled
> together with no safeguards.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 10

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Every data system captures at least four temporally distinct facts about any given
event. These four facts diverge from each other in routine operation, and conflating
any two produces queries that return different results depending on when they are run
— a silent correctness failure that looks like "flaky data" but is actually a design
error.

The four types are not interchangeable:

**Event time** is the ground truth anchor. It is the moment the real-world fact
occurred, independent of any system. If event time is not captured when the event
occurs, it is permanently lost — no pipeline rerun, no correction, no backfill can
recover it. Missing event time is permanent data loss, not a recoverable gap.

**Ingestion time** reflects the data's arrival at the system boundary. It is always
present (the database or pipeline sets it automatically) but it is not event time.
Ingestion time can lag event time by milliseconds in real-time systems or by hours or
days in batch systems. It can even precede event time when clocks are misconfigured or
when records are pre-dated. Never use ingestion time to answer "when did this happen."

**Processing time** captures when computation ran — the parsing, transformation, or
loading step. In simple systems, ingestion and processing time look identical. In
batch pipelines, a file ingested at 3:00 PM may not be processed until midnight.
Processing time tells you about the pipeline; it tells you nothing about reality.

**Valid time** is the interval — not a point — during which a fact was true in the
world. An address is valid from move-in to move-out. A price is valid from
announcement to change. A policy is valid from effective date to expiry. Valid time
is a range that enables "as of" queries: "what was the state of the world on date X?"
A single timestamp cannot answer this question; a valid_from / valid_to pair is
required.

The critical operational insight: practitioners name a column "created_at" and believe
they have handled time. But `created_at` is almost always ingestion time, not event
time. A schema that has one time column conflates at minimum two types — often three.
Before designing any time-based feature or query, explicitly identify which type of
time each column represents and whether the business question requires a different
type than the one being stored.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: the Kettlebell Order — Four Types Across Five Systems

A single e-commerce purchase of a kettlebell triggers a cascade of distinct temporal
facts across systems:

- **Event time (customer)**: 10:42 AM — the customer clicks "buy."
- **Ingestion time (order system)**: 10:42:03 AM — three seconds later, due to
  network latency and queue processing.
- **Processing time (verification pipeline)**: 10:45 AM — after batching orders
  for efficiency.
- **Valid time (order pending)**: 10:42 AM to 10:43 AM — the interval during which
  the order was in "pending" state before payment cleared.

Then the payment system introduces its own timestamps: transaction time (when the
payment system recorded the event) and event time (when the bank confirmed the
transaction). Shipping records "shipped at 2:30 PM" (event time) with ingestion at
2:31 PM. Delivery occurs at 4:15 PM but is recorded in the carrier system at 4:20 PM.
The data warehouse batch-loads everything at 11:00 PM.

One kettlebell: five systems, at least five event times, six ingestion times, multiple
processing times, and multiple valid-time intervals. A single `timestamp` column on
the order record cannot represent this. A schema that does not explicitly separate
these types will return different query results depending on which timestamp is used
for the same business question.

### Case 2: Knight Capital — Event Time / Valid Time Collapse

In 2012, Knight Capital Group lost $440 million in under 45 minutes because a legacy
trading module — no longer valid for live execution — was accidentally reactivated on
some servers during a deployment. The module had no temporal safeguard: there was no
`valid_to` boundary marking it as expired, and no check against event time to verify
that the execution context was current.

The module treated its own deployment state as perpetually valid. It had no way to ask
"is this code still the authorized version for this execution context at this moment?"
That question requires valid time on the code artifact itself. Without it, stale code
executed as if it were current, flooding the market with unintended orders.

This is the event-time / valid-time collapse at system scale: the "event" (deployment
of new code) was not temporally separated from the "validity period" (the window
during which each module version should execute). The absence of temporal typing on
the system's own state produced a catastrophic, irreversible failure.

### Case 3: ML Data Leakage — Event Time / Processing Time Conflation

A churn prediction model uses the customer's current account balance as a feature to
predict whether that customer churned last month. The balance figure comes from a
feature table joined by `customer_id` — no time constraint.

The current balance is a processing-time artifact: it reflects the state of the
feature table at model training time. The event time of the churn decision is the
label date — last month. These are different time types: the feature's processing time
(now) is being treated as if it were the feature's valid time at the label date (then).

The model trains on future information relative to the label, achieves artificially
high accuracy, and collapses in production where only past features are available at
prediction time. The failure appears as "model degradation" rather than the temporal
conflation it actually is. (Addressed fully in `ml-pipeline-integrity-pre-training`.)

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Schema design with time columns**: A user is adding a `timestamp` or `date`
   column to a table and has not asked which of the four types this column represents.
2. **Query results change over time**: A user reports that rerunning a historical
   query for a "closed" period returns different results. The root cause is almost
   always ingestion time being used where event time is required.
3. **"As of" query design**: A user needs to reconstruct the state of a record at a
   past date. This requires valid time (a range), not a single timestamp.
4. **ML feature engineering**: A user is joining training labels to a feature table
   without a time constraint. This is event-time / processing-time conflation.
5. **Late-arriving data**: A user is asking how to handle records that arrive after
   their event date. This requires understanding the ingestion-time / event-time gap.
6. **AI/RAG system temporal accuracy**: A user's AI system returns outdated
   information. The root cause is that retrieval does not filter on valid time.

### Language Signals (Activate When These Appear)

- "The numbers change depending on when I run the query"
- "We need to know what the data looked like on a specific past date"
- "We have a `created_at` column — is that the event date?"
- "Our ML model performs great in training but poorly in production"
- "We need to handle late-arriving records"
- "Our RAG agent is returning outdated policy information"
- Any question about a column named: `timestamp`, `date`, `created_at`, `updated_at`,
  `loaded_at`, `processed_at` that is being used to answer a business question about
  when something happened

### Distinguishing from Adjacent Skills

- Difference from `temporal-depth-selection`: This skill identifies WHICH time types
  exist in a dataset and what each column represents. `temporal-depth-selection`
  decides HOW MANY time axes to track in the model (non/uni/bi/tritemporal). These
  are sequential: use this skill first to name the axes; use `temporal-depth-selection`
  to decide which ones to store.
- Difference from `ml-pipeline-integrity-pre-training`: That skill is a specific
  operational rule for ML training pipelines (use AS OF joins). This skill is the
  upstream diagnostic that identifies whether the feature table is capturing the right
  time type in the first place.
- Difference from `aggregation-workflow-four-steps`: That skill assumes time columns
  are already correctly typed and focuses on the aggregation operation. This skill
  resolves what the time columns mean before aggregation design begins.

______________________________________________________________________

## E — Execution Steps

When activated, work through these steps before designing any time-based column,
query, or feature.

1. **Inventory every time-related column in scope**

   - List all existing or proposed columns that represent any form of timestamp,
     date, or temporal range.
   - Include columns named `created_at`, `updated_at`, `date`, `timestamp`,
     `valid_from`, `valid_to`, and any system-generated audit fields.
   - Completion criteria: A complete list of all temporal fields exists.

2. **Classify each column by time type**

   - For each column, answer: "What real-world moment or interval does this value
     represent?"
   - **Event time**: The moment the real-world fact occurred. Column should be named
     `event_time` or `occurred_at`. If not present: flag as missing.
   - **Ingestion time**: When the record arrived at the system boundary. Column should
     be named `ingested_at` or `arrived_at`. This is never event time.
   - **Processing time**: When a computation or pipeline step ran. Column should be
     named `processed_at` or `computed_at`. This is never event time.
   - **Valid time**: The interval during which a fact was true. Requires two columns:
     `valid_from` and `valid_to` (not a single timestamp).
   - Completion criteria: Every temporal column has an explicit assigned type.

3. **Identify the time type required by each business question**

   - For each query or downstream use case, ask: "Which time type answers this
     question?"
   - "What happened and when did it happen?" → event time
   - "What was the state of the world as of date X?" → valid time
   - "When did we learn about this?" → ingestion time
   - "What did our system believe at time T?" → transaction time (bitemporal)
   - "When did our pipeline run?" → processing time
   - Completion criteria: Each business question is mapped to a specific time type.

4. **Detect mismatches between required type and stored type**

   - Compare the time type each question requires (Step 3) against the type each
     column stores (Step 2).
   - Flag every mismatch: a question requiring event time answered by `created_at`
     (ingestion time) is a silent correctness error.
   - Flag every missing type: a question requiring valid time but the schema has only
     a single timestamp is structurally unanswerable.
   - Completion criteria: All mismatches and missing types are documented.

5. **Prescribe column additions or renames**

   - For each mismatch: rename the column to its correct type; add the missing column
     if event time is absent.
   - For valid time: replace a single `date` or `timestamp` with `valid_from` /
     `valid_to` pair. Document what "valid" means for this entity.
   - Use explicit names: `event_time`, `ingested_at`, `processed_at`, `valid_from`,
     `valid_to`. Never use ambiguous names like `timestamp` or `date`.
   - Completion criteria: Every column has a name that unambiguously declares its
     time type.

**Tie-breaking rule**: When event time is absent and there is no way to recover it
from upstream source systems, document the permanent data loss explicitly. Do not
substitute ingestion time for event time. The gap is real and the consumers of this
data must know it exists.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Only one time axis and no corrections possible**: For a pure append-only event log
  that answers only "when did X occur?" with no historical reconstruction or correction
  requirement, a single `event_time` column may be all that is needed. The four-type
  separation is most critical when (a) corrections or late-arriving data exist, (b)
  "as of" queries are required, or (c) ML/AI features require temporal correctness.
- **The question is about time zone formatting**: If the question is about UTC storage,
  timezone conversion, or ISO 8601 formatting, the temporal-type framework is not the
  right tool. The column naming and type classification in this skill assume UTC is
  already the storage standard.
- **Processing-time-only systems**: For pure monitoring or observability systems where
  the only question is "when did the pipeline run?" and real-world event time is
  genuinely irrelevant, only processing time needs to be tracked.

### Failure Patterns Warned About by the Author

- **Event/ingestion conflation (ce06)**: Using `created_at` or `inserted_at` in WHERE
  clauses and GROUP BY instead of `event_time`. Historical queries for closed periods
  return different results when reruns occur. The root cause is always a missing or
  unnamed event time column. Warning signs: schema has no `event_time` column;
  rerunning a historical query returns different numbers.
- **Processing time conflation (ce08)**: Storing timestamps without a UTC offset
  ("floating timestamps") causes the same event to resolve to different absolute
  moments depending on which server reads the record. Warning signs: TIMESTAMP columns
  instead of TIMESTAMPTZ; daily aggregations vary across servers.
- **RAG temporal staleness (ce21)**: AI retrieval systems that do not filter on valid
  time return semantically similar but temporally outdated documents. A RAG agent
  answering "what is our current return policy?" may retrieve a 2022 policy with high
  semantic similarity and no time penalty. Warning signs: document corpus has no
  `valid_from` / `valid_to` metadata; retrieval query does not filter on date range.

### Author's Blind Spots / Limitations of the Era

- **Ingestion time preceding event time**: The book acknowledges this edge case
  (misconfigured clocks, pre-dated records) but does not provide a resolution protocol.
  In practice, this requires a separate "source-reported time" column alongside the
  ingested value, with explicit documentation of clock trust levels per source system.
- **Streaming grain**: The book defers detailed treatment of tumbling windows and
  session windows to volume 2. The four-type framework applies to streaming grain in
  principle; the cost analysis and materialization strategy for high-velocity event
  streams require additional tooling knowledge not covered here.

### Easily Confused Adjacent Methodologies

- **"Just add a created_at and updated_at column"** (universal default): This covers
  ingestion time and last-update time, but misses event time entirely and provides no
  valid-time range for "as of" queries. It is the minimum viable temporal schema, not
  a complete one.
- **SCD Type 2** (effective/expiry dates as slowly-changing dimensions): SCD Type 2
  captures valid time but is not bitemporal — the transaction-time axis (when the
  system recorded each version) is absent, meaning corrections can silently overwrite
  the history. See `temporal-depth-selection` for the distinction.

______________________________________________________________________

## Related Skills

- **composes-with** `temporal-depth-selection`: This skill identifies which time types exist in a dataset; temporal-depth-selection then decides how many of those axes to store — the two skills run in sequence whenever a new temporal schema is designed.
- **composes-with** `synthesis-checklist-cross-form`: Question 5 of the synthesis checklist (time alignment) is answered by applying this skill's classification across all data forms being integrated to designate a common event-time reference.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f12+p23+p24 (framework + two principles merged at Phase 1.5)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 10 — Why Time Matters in Data Modeling
