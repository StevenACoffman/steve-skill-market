---
name: temporal-depth-selection
description: |
  Use this skill when a user needs to decide how many time axes a data model must
  track — i.e., choosing between non-temporal, unitemporal, bitemporal, or tritemporal
  modeling depth — for any table, entity, or feature store.

  Trigger signals:
  - "We need to track historical changes to this entity"
  - "We need to know what the record looked like before someone edited it"
  - "Our ML model needs the feature values at a specific past date, not current values"
  - "We have late-arriving data — records that arrive after the fact date"
  - "We need an audit trail"
  - Any schema design question where corrections, overwrites, or retroactive amendments
    are possible
tags: [time, temporal-modeling, bitemporal, unitemporal, SCD, data-modeling,
       audit-trail, ML-features]
---

# Temporal Depth Selection — Non/Uni/Bi/Tritemporal Decision Path

## R — Original Text (Reading)

> **Non-temporal data** represents a single moment or "current" state.
>
> **Unitemporal data** is data with a single timeline, typically the valid time
> (also known as "business time" or "effective time"), the period during which
> something is true in the real world. Most data is unitemporal.
>
> [With unitemporal,] if you fix this historical price error, the original incorrect
> record is overwritten, and the history of what your database previously thought is
> lost.
>
> **Bitemporal data** adds a second layer: one for valid time and another for the
> time the system records the event... transaction time, which is an immutable ledger
> of data changes... you don't overwrite the old record. Instead, you close out the
> old record by setting its transaction date to the current moment, then insert a new
> record with the correct price. With this bitemporal data, you can ask: "What was
> the product's price for July 15th as we knew it on July 6th?"
>
> **Tritemporal data** adds a third dimension: decision time. This is when was a
> decision made? — helpful in regulated industries or complicated logistics where
> the timing of a decision is as important as the data itself.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 10

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Temporal depth is the number of independent time axes a model tracks. Each additional
axis answers a class of business question that the previous level cannot. The four
levels are ordered by complexity and query power:

**Non-temporal**: The model stores current state only. No history. No "as of" queries.
No corrections without data loss. Use only when history is genuinely irrelevant — when
no stakeholder will ever ask "what was the value on date X?" and when no correction
will ever need to be audited.

**Unitemporal** (valid time): The model tracks when facts were true in the world using
`valid_from` / `valid_to` columns. This answers "what was the state on date X?" —
point-in-time queries against real-world history. It cannot answer "what did the
system believe on date X?" because corrections made via UPDATE or DELETE overwrite
the prior value, erasing the system's belief history. Valid time is a forward-looking
record of facts, not a backward-recoverable audit ledger.

**Bitemporal** (valid time + transaction time): The model adds a second axis —
transaction time — representing when the system recorded each version of the fact.
Every correction generates a new row with updated transaction timestamps; old rows are
never deleted or overwritten. This makes the ledger immutable. Bitemporal answers
both questions simultaneously: "what was true on date X?" (valid time) and "what did
we know on date X, before a subsequent correction?" (transaction time). Required for
auditable corrections, late-arriving data reconciliation, and point-in-time ML feature
retrieval from a feature store.

**Tritemporal** (valid time + transaction time + decision time): Adds a third axis
for when a decision was authorized — legally distinct from when it was recorded and
when it took effect. Required only in regulated contexts where a regulator needs to
know not just when a fact was entered and when it was effective, but when the
underlying decision was made. Rare outside financial services, government, and
healthcare compliance.

**Selection rule**: Default to unitemporal for most analytical work. Upgrade to
bitemporal when corrections must be auditable OR late-arriving data exists OR ML
training requires historical feature values. Upgrade to tritemporal only when a
regulatory requirement mandates tracking decision authorization time as a legally
distinct axis.

The key distinction from `four-types-of-time`: that skill identifies which time types
exist in a dataset. This skill decides how many of those axes to track in the model.
They are sequential: use `four-types-of-time` first to name the axes, then use this
skill to decide which ones to store.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Product Price Correction via UPDATE — the Canonical Bitemporal Failure

A Products table stores `price`, `valid_from`, and `valid_to` columns (unitemporal).
A data entry error sets the price at $99 when it should be $89. A correction is made
via an UPDATE statement that overwrites the original row.

After the correction, the system can answer "what is the current price?" ($89) and
"what was the price between July 10 and July 20?" (also $89, correctly). But it
cannot answer: "What did we believe the price was on July 6th, before the correction
was entered on July 8th?"

That question requires transaction time. The system's prior belief — $99 for that
period — is permanently gone. Any downstream invoice, report, or ML model generated
on July 6th using the $99 price cannot be reconciled against the corrected system.
The audit trail is broken.

A bitemporal model prevents this by never overwriting: when the correction is entered,
the July 5th record's `transaction_to` is set to July 8th, and a new record is
inserted with `transaction_from` = July 8th. Both records coexist. The query "price
for July 15th as known on July 6th" returns $99. The query "price for July 15th as
known today" returns $89. The system's full belief history is preserved. (Counter-
example ce07.)

### Case 2: ML AS OF Join — Unitemporal Vs. Bitemporal for Feature Retrieval

An ML team is training a churn prediction model. They join training labels (churn
events with dates) to a customer feature table to retrieve the customer's account
balance, product tier, and activity score at the time of churn.

If the feature table is **non-temporal** (current values only): the join retrieves
today's feature values, not the values at label date. The model trains on future
information. High training accuracy, collapse in production.

If the feature table is **unitemporal** (valid time only, with preserved history):
the AS OF join retrieves the valid record at label date using
`valid_from <= label_date AND valid_to > label_date`. This works correctly for
features that were never retroactively corrected.

If the feature table is **bitemporal** (valid time + transaction time): the AS OF
join can additionally exclude corrections that were entered after the label date —
ensuring the model trains only on information that genuinely existed at prediction
time, not on retroactively amended values. This is the correct level for high-stakes
ML training when feature values are subject to amendment.

The selection: unitemporal is sufficient for features that are never retroactively
corrected. Bitemporal is required when corrections exist and ML training must be
reproducible against the system's historical belief state.

### Case 3: Insurance Policy Retroactive Amendment — the Worked Bitemporal Example

An insurance company tracks policy coverage amounts. Two requirements exist:

- **(a) Actuarial query**: "What was the coverage amount when this claim was filed
  on March 15th?" — requires valid time. The policy's valid_from / valid_to on March
  15th answers this. Unitemporal suffices.

- **(b) Audit query**: "Before the retroactive amendment entered on April 3rd, what
  did the system record as the coverage amount on the day the claim was filed?" —
  this question requires transaction time. The April 3rd amendment changed the
  valid-time record retroactively. After the amendment, the unitemporal model shows
  only the corrected value for March 15th. The system can no longer report what it
  believed on the day the claim was filed — before the amendment was entered.

Bitemporal is required: the transaction-time axis preserves the immutable record of
what was in the system at every past moment, independent of subsequent corrections.
The auditor can now ask: "for the claim filed on March 15th, what coverage amount did
the system show on March 15th?" and get the pre-amendment value.

Tritemporal is not needed here unless the regulatory filing date of the amendment
decision (legally distinct from the entry date and the effective date) must itself be
auditable — a requirement that arises in specific regulatory contexts but not in
routine insurance claims processing.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **New entity with correction requirements**: A user is designing an entity whose
   values may be retroactively corrected (prices, coverage amounts, ratings, scores)
   and needs to decide whether corrections should be auditable.
2. **Late-arriving data**: A user has data sources that send records after the event
   date — corrections, restatements, out-of-order arrivals — and needs to model the
   reconciliation.
3. **ML feature store design**: A user is building or selecting a feature store and
   needs to know whether it must support point-in-time (AS OF) queries for training.
4. **Audit trail requirement**: A stakeholder asks "what did the record look like
   before the change was made?" — this is a direct request for transaction time.
5. **SCD Type 2 upgrade decision**: A user has an SCD Type 2 model and is being asked
   whether it is "truly bitemporal." (Usually: it is not. See B section.)
6. **Regulatory compliance**: An auditor or compliance team asks for the system's
   belief state at a specific past moment, not just the current valid-time view.

### Language Signals (Activate When These Appear)

- "We need to track historical changes to this entity"
- "We need an audit trail of all changes"
- "We have late-arriving data that corrects past records"
- "Our ML model needs the feature values as they were on a past date"
- "What did the record look like before someone edited it?"
- "The regulator needs to know when the decision was made, not just when it took
  effect"
- "We're using SCD Type 2 — is that good enough?"

### Distinguishing from Adjacent Skills

- Difference from `four-types-of-time`: That skill identifies which time type each
  column represents (event vs. ingestion vs. processing vs. valid). This skill decides
  how many time axes to track once the types are named. Sequence: four-types-of-time
  first, then this skill.
- Difference from `ml-pipeline-integrity-pre-training`: That skill is the
  operational rule for constructing ML training datasets (always use AS OF joins).
  This skill is the architectural decision that determines whether the underlying
  feature store *can* support AS OF queries. These compose: this skill chooses the
  architecture; that skill dictates how to use it.
- Difference from `process-to-model-translation`: That skill translates business
  process steps into state transition records. This skill chooses the temporal
  tracking depth for those state records.

______________________________________________________________________

## E — Execution Steps

Work through these questions in order. Do not skip to implementation before answering
the architectural questions.

1. **Determine whether history is needed at all**

   - Ask: Will any stakeholder ever ask "what was the value of this field on a past
     date?" or "what was the state of this entity at time T?"
   - If no: non-temporal is sufficient. Document the decision explicitly: "this
     entity does not track history by design." Stop here.
   - If yes: proceed to Step 2.
   - Completion criteria: A binary decision — history needed / not needed — is
     recorded.

2. **Assess whether corrections will exist**

   - Ask: Can the values in this entity ever be retroactively amended, corrected, or
     restated after the fact?
   - Examples: price corrections, coverage amendments, rating adjustments,
     retroactive reclassifications.
   - If no corrections: unitemporal is sufficient. Implement `valid_from` / `valid_to`
     on the entity. Proceed to Step 4.
   - If corrections exist: proceed to Step 3.
   - Completion criteria: The presence or absence of retroactive corrections is
     explicitly documented for this entity.

3. **Assess whether the system's prior belief state must be recoverable**

   - Ask any of: "Is there an audit requirement to show what the system believed before
     a correction?" / "Are there ML training pipelines that need point-in-time
     feature values?" / "Are there downstream reports that relied on the pre-correction
     value that must be reconcilable?"
   - If yes to any: bitemporal is required. Add `transaction_from` / `transaction_to`
     (system time) as immutable columns alongside `valid_from` / `valid_to`. Enforce
     that corrections never overwrite — they close the old row and insert a new one.
   - If no: unitemporal with a correction policy (documented overwrite procedure)
     may be acceptable, accepting the audit gap.
   - Completion criteria: The auditability requirement is documented and the temporal
     depth decision is recorded.

4. **Assess whether decision authorization time is a regulatory requirement**

   - Ask: Does the regulatory context require proving not just when a fact was entered
     and when it took effect, but when the underlying decision was authorized?
   - This applies in financial services (approval timestamps for credit decisions),
     government (authorization vs. effective dates for regulations), and healthcare
     (prescribing authorization vs. dispensing date).
   - If yes: tritemporal is required. Add `decision_time` as a third axis.
   - If no: stop at bitemporal.
   - Completion criteria: The regulatory requirement is either confirmed or ruled out.

5. **Verify the implementation pattern for the chosen depth**

   - Non-temporal: current-state table, no history columns.
   - Unitemporal: `valid_from` (NOT NULL), `valid_to` (nullable or sentinel 9999-12-31).
     Corrections overwrite in place (document explicitly).
   - Bitemporal: `valid_from`, `valid_to`, `transaction_from` (NOT NULL),
     `transaction_to` (nullable or sentinel). Rows are NEVER updated or deleted;
     corrections insert a new row and close the old one by setting `transaction_to`.
   - Tritemporal: above plus `decision_time` column.
   - Completion criteria: The schema includes the correct columns for the chosen depth,
     and the write path enforces the immutability constraint for bitemporal and above.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The time types are not yet named**: If it is not yet clear whether the entity has
  valid time, transaction time, or both, run `four-types-of-time` first to identify
  which axes exist before deciding how many to track.
- **Streaming / event-sourced systems**: Event sourcing (append-only immutable logs)
  provides bitemporality by default — each event has its event time and its append
  time. For these systems, the temporal depth decision is made at the architecture
  level, not the table level. The four-level framework applies conceptually but not
  operationally.
- **The decision is about querying an existing bitemporal model**: If the model is
  already bitemporal and the question is how to write an AS OF join, use
  `ml-pipeline-integrity-pre-training` for ML contexts or the direct SQL pattern
  from Ch. 10.

### Key Anti-Pattern: SCD Type 2 Is Not Bitemporal

SCD Type 2 (Slowly Changing Dimension Type 2) tracks history by adding `effective_from`
and `effective_to` columns, closing the current row and inserting a new one on change.
This captures valid time — when each version of the fact was effective in the world.

However, SCD Type 2 is NOT bitemporal unless the implementation enforces row
immutability at the system level. Most SCD Type 2 implementations allow direct UPDATE
statements on existing rows — for data corrections, backfills, or pipeline reruns.
When an UPDATE fires on a row with an `effective_from` / `effective_to` pair, the
transaction-time axis does not exist to record what the row previously contained.
The system's prior belief is silently overwritten.

The test: if a DBA can issue `UPDATE dim_product SET price = 89 WHERE surrogate_key = 1`
and the previous value of 99 is not preserved anywhere, the model is unitemporal,
not bitemporal. True bitemporal requires immutable rows enforced at the write layer —
not just the schema convention.

### Failure Patterns Warned About by the Author

- **Unitemporal overwrite (ce07)**: Correcting a product price via CRUD UPDATE destroys
  the system's prior belief state. The model is unitemporal, the correction creates a
  silent audit gap. Warning signs: schema has `valid_from` / `valid_to` but no
  `transaction_from` / `transaction_to`; corrections are applied via UPDATE.
- **Non-temporal ML feature store**: Feature tables that store only current values
  cannot support AS OF joins. ML training pipelines against these tables will produce
  data leakage. Warning signs: feature table has no `valid_from` column; joins use
  only entity key without time constraint.

### Author's Blind Spots / Limitations of the Era

- **Enforcement mechanism not specified**: The book defines bitemporal and states
  that rows should not be overwritten, but does not specify enforcement mechanisms
  (database triggers, application-layer write guards, event sourcing as an alternative
  implementation). In practice, ensuring immutability requires an explicit enforcement
  decision at the infrastructure level.
- **Tritemporal thresholds are context-dependent**: The book gives the government
  tax rate example for tritemporal but does not enumerate all regulated contexts that
  require it. Practitioners in financial services, healthcare, and legal domains
  should verify with their compliance function whether decision time is legally
  required in their context.

______________________________________________________________________

## Related Skills

- **depends-on** `four-types-of-time`: The four time types must be identified and named before this skill can decide which axes to track — running four-types-of-time first ensures the temporal vocabulary is unambiguous before the depth decision is made.
- **composes-with** `ml-pipeline-integrity-pre-training`: This skill determines whether the feature store is unitemporal or bitemporal (and therefore whether AS OF joins are architecturally possible); that skill then mandates that AS OF joins must always be used in ML training pipelines.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f13 (framework extractor — Phase 1.5)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 10 — Why Time Matters in Data Modeling
