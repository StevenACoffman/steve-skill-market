---
name: grain-decision-four-questions
description: |
  Use this skill when a user needs to decide what level of detail a dataset should
  capture — i.e., "what does one row represent?" — for any new table, stream, feature
  set, document store, or cross-form data model.

  Trigger signals:
  - "What grain should this table be?"
  - "Should I store one row per X or one row per Y?"
  - "How granular should this dataset be?"
  - "We might need more detail later — what should we do now?"
  - Any schema or model design question where the unit of measurement is ambiguous

  Do NOT use this skill when:
  - The grain is already defined and the question is about validating it before
    deployment (use grain-audit-checklist instead)
  - The question is about how to aggregate correctly over an already-designed grain
    (use six-aggregation-properties or aggregation-workflow-four-steps instead)
  - The question is purely about storage technology or query performance with no
    ambiguity about what the rows represent

  Based on: "Practical Data Modeling" by Joe Reis (2026), Ch. 8 — Grain.
tags: [grain, data-modeling, schema-design, decision-framework]
---

# The Four Questions for Grain Decision-Making

## R — Original Text (Reading)

> **What Is Grain?**
> Grain represents the fundamental level of detail captured in a dataset. The core
> question for any data modeler is always: *what, precisely, does one row or record
> represent?*
>
> **The Four Questions: When You're Stuck on a Grain Decision**
>
> 1. What is the lowest level of detail any stakeholder needs today?
> 2. Can you aggregate up from this grain to answer all known analytical questions?
> 3. What is the storage and performance cost of this grain level?
> 4. Is there a foreseeable future need that would require going finer?
>
> If the answer to #2 is yes and #3 is acceptable, you have your grain.
>
> And the single most important thing to remember about grain: **grain works in
> one direction.** *You can always aggregate up from fine-grained data. You can
> never deterministically disaggregate from coarse-grained data.* When in doubt —
> at least for human or business-level events — go finer.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 8

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Grain is the declaration of what one record represents. Every other modeling decision — how to aggregate, how to join, which time type to track, which relationships to encode — is downstream of this one. Get grain wrong at design time and the only fix is to rebuild from raw source data; the alternative (disaggregating a coarse-grained dataset) is mathematically impossible.

The four questions force the decision into a structured sequence. Question 1 anchors the grain to real stakeholder need, not to what seems convenient to store. Question 2 checks whether the proposed grain is fine enough — can every currently-known analytical question be answered by grouping up from this level? Question 3 applies the practical ceiling — finer grain costs more; if the cost is prohibitive, find a compromise. Question 4 extends the horizon — if there is any credible future requirement that needs finer grain than what question 1 identified, go there now, because you cannot go back later.

The asymmetry insight is the load-bearing principle: aggregation is always possible; disaggregation is permanently impossible without source data. This means the cost of storing too much detail is paid once at build time; the cost of storing too little is paid repeatedly, at every future query that cannot be answered, and ultimately in a full rebuild. When questions 2 and 3 are both satisfied, stop — do not go finer than needed. When questions 2 and 3 conflict (question 2 requires finer, question 3 resists it), question 2 wins for human/business events; storage is expandable, lost detail is not.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Fighter Title Shot — Wrong Level of Analysis

- **Problem**: A fighter's coaching team assessed an opponent using career aggregate statistics. The career stats said the opponent "couldn't wrestle."
- **How the framework applies**: The question "what grain do I need?" was never asked. Career stats are aggregated-grain data. The question being answered — "has this specific opponent changed their defensive wrestling in the last three fights?" — requires round-by-round or fight-by-fight grain. Q2 fails: the analytical question cannot be answered by aggregating up from career-level grain; you need to disaggregate to recent-fight level, which the career aggregate cannot support.
- **Conclusion**: The grain was coarser than the question required.
- **Result**: The fighter lost the title shot. The missed grain decision had an irreversible outcome — once the fight is scheduled and the game plan is set from the wrong level, there is no disaggregating the past.

### Case 2: E-Commerce Order — Two Distinct Grains in One Purchase Event

- **Problem**: A relational data model for an e-commerce order needs to capture the order as a whole and the individual line items within it.
- **How the framework applies**: Q1 reveals two distinct analytical needs: stakeholders need both "how many orders?" (order-header grain) and "which products were bought?" (order-line grain). These are different grains and cannot coexist in a single table without introducing a fan-out problem. Q2 confirms: a line-item grain table can always be aggregated up to an order-header grain; an order-header grain table cannot be disaggregated to expose individual line items without a separate source.
- **Conclusion**: The correct design is two tables — Order_Header (one row per transaction) and Order_Line (one row per product per transaction) — each with its own declared grain.
- **Result**: The grain distinction between header and line items is one of the most common early design errors Reis identifies; teams that collapse both into one table reliably produce fan-out inflation.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **New dataset design**: A user is designing a table, stream, or document schema from scratch and has not yet defined what one record represents.
2. **Grain conflict during integration**: A user is trying to join two datasets and getting unexpected row counts — more rows than either source — indicating a fan-out from mismatched grains.
3. **Future-proofing a new system**: A user is arguing with stakeholders about whether to store daily summaries or transaction-level detail, and the team is defaulting to coarser grain for storage reasons.
4. **Analytical question cannot be answered**: A user has a business question that the current dataset cannot answer, and the reason is that the data was pre-aggregated at a coarser level than the question requires.
5. **Cross-form model design**: A user is combining relational, semi-structured, or ML feature data and needs to establish a common grain before integration.

### Language Signals (Activate When These Appear)

- "What should one row represent?"
- "Should I aggregate this or keep it raw?"
- "We're storing daily totals — is that granular enough?"
- "The numbers double when I do this join"
- "We might need to drill down into this later"
- "How fine-grained should the feature table be?"

### Distinguishing from Adjacent Skills

- Difference from `grain-audit-checklist`: This skill **decides** what the grain should be; grain-audit-checklist **validates** that a grain decision already made was implemented correctly before production deployment. Use this skill first; use the audit after.
- Difference from `aggregation-workflow-four-steps`: That skill assumes grain is already declared and focuses on the correctness of the aggregation operation. This skill resolves what the grain is before any aggregation is designed.
- Difference from `business-process-discovery`: Business process discovery is the upstream method for understanding what the grain should represent in terms of real-world events; the four questions are the grain-setting tool applied once you have that understanding. For a new data model with no existing source, run business-process-discovery first, then apply these four questions.

______________________________________________________________________

## E — Execution Steps

Once activated, work through these four questions in order. Do not skip to question 3 (cost) before answering questions 1 and 2.

1. **Answer Q1 — The stakeholder floor**

   - Ask: What is the most granular question any known stakeholder will ever ask of this data?
   - State the answer as a grain candidate: "one row per \_\_\_."
   - Completion criteria: A specific, declarative grain statement exists. "One row per customer transaction" is complete. "Fairly granular" is not.

2. **Answer Q2 — The aggregation test**

   - Ask: Can every currently-known analytical question be answered by grouping rows up from this grain candidate?
   - Test each question explicitly: can question A be answered by GROUP BY + SUM/COUNT/AVG from this grain? Can question B?
   - If any question requires *disaggregation* (splitting a row into finer parts), the grain candidate is too coarse — go back to Q1 and find a finer candidate.
   - If all questions can be answered by aggregating up, Q2 passes.
   - Completion criteria: Every stated analytical question has a confirmed aggregation path from the grain candidate.

3. **Answer Q3 — The cost gate**

   - Ask: What is the approximate storage volume and query cost at this grain level?
   - If cost is prohibitive, find the coarsest grain that still passes Q2. That is the compromise grain.
   - If cost is acceptable, Q3 passes.
   - Stop condition: If Q2 passes and Q3 passes, **the grain decision is made**. Do not go finer without a specific reason from Q4.
   - Completion criteria: A cost estimate (rough order of magnitude is sufficient) exists and the team has accepted it.

4. **Answer Q4 — The future horizon**

   - Ask: Is there any credible, foreseeable requirement that would require going finer than the current grain?
   - If yes, and Q3 still permits it: go to the finer grain now.
   - If yes, but Q3 prohibits it: explicitly document the trade-off and the requirement that cannot be answered. Record where the source data lives so the finer grain can be reconstructed later if needed.
   - If no foreseeable need: document that the grain was a deliberate decision, not a default.
   - Completion criteria: A written grain statement exists — "one row per [unit], capturing [time scope], for [known use cases]" — with a note on foreseeable future needs and their disposition.

**Tie-breaking rule**: When Q2 and Q3 conflict for human/business-level events, Q2 wins. Go finer. Storage is expandable; disaggregation of lost detail is not.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The grain is already set and in production**: If the dataset is deployed and running, the four questions will not help — the data that would require a finer grain may no longer exist. The question becomes "can we recover the lost grain from upstream source systems?" which is an infrastructure question, not a modeling decision.
- **Machine-generated telemetry or high-frequency IoT data**: For sensor data, log streams, or telemetry pipelines, the practical grain is often driven by storage budget and sampling rate, not by analytical requirements. The tie-breaking rule ("Q2 beats Q3 for human/business events") does not apply here; aggressive pre-aggregation is often required.
- **The grain is already known and the question is about validation**: If the grain has already been declared, use `grain-audit-checklist` to verify the implementation is correct before production deployment.

### Failure Patterns Warned About by the Author

- **Fan-out inflation**: Joining two tables without recognizing that the result grain has changed produces inflated counts and double-counted metrics. Warning sign: COUNT(\*) of the JOIN result is larger than COUNT(\*) of the finer-grain source table. (See ce01)
- **Mixed-grain trap**: Storing both atomic transaction rows and pre-computed daily summary rows in the same table. Any SUM() over the table double-counts revenue. Warning sign: a row_type or grain_level column with multiple distinct values in a table that is used for direct aggregation. (See ce02)
- **Incompatible grain joins**: Combining two datasets at different grains without a GROUP BY step to align them first. The most common form: joining a customer-grain table to an order-grain table and then counting "customers" from the result. (See ce01)

### Author's Blind Spots / Limitations of the Era

- **Streaming and real-time systems are deferred**: The book explicitly notes that streaming grain (tumbling windows, session windows) and unstructured data grain are covered in volume 2. The four questions apply to streaming grain in principle, but the cost analysis (Q3) for high-velocity event streams requires additional tooling knowledge not covered here.
- **Physical modeling trade-offs are not addressed**: The four questions operate at the logical model level. Physical considerations — partitioning strategy, indexing, storage format, time-travel costs in lakehouse systems — can create additional constraints that force grain compromises the four questions alone do not surface.

### Easily Confused Adjacent Methodologies

- **"Start at the highest level and add detail later"** (common practice): The inverse of Reis's rule. The four questions explicitly reject this — going coarser first means losing the ability to go finer unless source data is preserved separately. The four questions always start from Q1 (finest needed today) and work toward coarsening only when Q3 requires it.
- **Dimensional modeling grain convention** (fact table grain = one row per event): This is a special case of Q1 where "the most granular analytical question" happens to be the atomic business event. The four questions are the general form; dimensional modeling grain convention is its most common instantiation in the analytics camp.

______________________________________________________________________

## Related Skills

- **composes-with** `grain-audit-checklist`: Once grain is declared using the four questions, run the audit checklist immediately before production deployment to verify the implementation matches the declaration.
- **composes-with** `aggregation-workflow-four-steps`: Step 1 of the aggregation workflow — defining the grain identity — must be resolved using this skill before aggregation design can proceed.
- **composes-with** `synthesis-checklist-cross-form`: Question 4 of the synthesis checklist (target grain) is answered by applying this skill's four questions to the integration anchor entity across all data forms.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f08 (framework extractor) + p17 (principle extractor) — merged at Phase 1.5
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 8 — Grain — Getting the Level Right
