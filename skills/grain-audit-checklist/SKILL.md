---
name: grain-audit-checklist
description: |
  Use this skill when a user has already decided what grain a dataset should have
  and needs to verify the implementation is correct before deploying to production.

  Trigger signals:
  - "We're about to deploy this table — how do we verify the grain is right?"
  - "I designed the grain as one row per X, but I want to double-check before shipping"
  - "How do I know if my primary key is actually unique?"
  - "Are there any checks I should run before this goes live?"
  - Any pre-deployment validation question where the grain has already been declared

  Do NOT use this skill when:
  - The grain has not yet been decided (use grain-decision-four-questions instead)
  - The table is already in production and queries have been running on it (the
    audit can identify the problem but cannot fix it — fixing requires a redesign
    from raw source data)
  - The question is about how to aggregate correctly over a correctly-grained table
    (use six-aggregation-properties or aggregation-workflow-four-steps instead)

  Based on: "Practical Data Modeling" by Joe Reis (2026), Ch. 8 — Grain.
source_book: "Practical Data Modeling" by Joe Reis
source_chapter: Ch. 8 — Grain — Getting the Level Right
tags: [grain, data-modeling, validation, pre-deployment, checklist]
related_skills:
  - slug: grain-decision-four-questions
    relation: depends-on
  - slug: six-aggregation-properties
    relation: composes-with
---

# Grain Audit Checklist — Pre-Deployment Validation

## R — Original Text (Reading)

> **The Grain Audit Checklist**
>
> Because structured data is so prevalent and the backbone of many mission-critical
> systems, before deploying any new dataset to production, run through this checklist
> to verify your grain is solid.
>
> 1. Is the primary key unique? Run SELECT COUNT(\*) vs. SELECT COUNT(DISTINCT pk).
>    If they don't match, you have duplicates, and your assumed grain is wrong.
>
> 2. Are there NULLs in grain-defining columns? NULLs in your primary key or
>    grain-defining columns break uniqueness guarantees and cause join anomalies.
>
> 3. Does the grain handle late-arriving data? For time-series or event data, what
>    happens when data arrives out of order?
>
> 4. Have you documented the grain? Can someone unfamiliar with the data understand
>    what a single row represents by reading the documentation?
>
> 5. Does the grain support your use cases? Can you answer the business questions at
>    this grain, or will you need to transform it?
>
> This checklist won't catch every grain problem, but it will catch the most common
> ones.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 8

______________________________________________________________________

## I — Methodological Framework (Interpretation)

This checklist is the execution gate between grain decision and production deployment.
The grain has already been declared — the four-question framework was already applied.
This checklist asks: was it implemented correctly?

The five checks map to five distinct failure modes. Check 1 (COUNT vs COUNT DISTINCT)
is the only purely mechanical test — it either passes or fails, and a failure means the
implementation does not match the declared grain regardless of the intent. Check 2
(NULLs in grain-defining columns) catches a subtler failure: even if counts match, a
NULL in a grain-defining column means that row cannot be uniquely identified and cannot
participate in reliable joins. NULLs in grain columns are not a data quality issue —
they are a grain contract violation.

Check 3 (late-arriving data) is often skipped because it requires thinking beyond
current data to the process that generates it. A table with a grain of "one row per
user per day" may look clean today, but if a late-arriving event for yesterday arrives
tomorrow, the handling rule must be declared before deployment — not discovered after
a pipeline retry creates duplicates. Check 4 (documentation) is load-bearing
infrastructure, not overhead. A grain statement is the contract that every downstream
analyst, join, and aggregate depends on. If no one can read the grain from documentation,
the grain is a private assumption held in one person's head. Check 5 (use-case coverage)
closes the loop: grain decisions are only as good as their ability to answer the
questions that motivated them.

Failing any check before deployment is substantially cheaper than discovering the
failure after queries have been running on corrupted grain assumptions. At deployment
time, the raw source data still exists and a redesign is possible. After production
operation, the downstream damage (bad dashboards, wrong metrics, incorrect ML features)
accumulates and may be irreversible.

**The key distinction from grain-decision-four-questions:** that skill decides what
grain to use. This skill confirms the chosen grain was implemented correctly. Run
grain-decision-four-questions first; run this checklist immediately before production
release.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: SaaS Customer Health Dashboard — Fan-Out Undetected Until Production (Ce01)

- **Setup**: A SaaS company builds a Customer Health dashboard. The data model joins
  three tables: Customers (one row per customer), Subscriptions (one row per
  subscription), and Support Tickets (one row per ticket). A customer can have
  multiple subscriptions and multiple tickets.
- **What the grain audit would have caught**: Check 1 — run SELECT COUNT(\*) vs.
  SELECT COUNT(DISTINCT customer_id) on the joined result. The counts would not
  match. A customer with 3 subscriptions and 5 tickets produces 15 rows in the join
  result, not 5. The assumed grain ("one row per customer") is not what the
  implementation delivers.
- **What actually happened**: The checklist was not run. The numbers looked plausible.
  A customer with two subscriptions showed twice as many tickets as expected. The fan-out
  was not caught until production, when the ticket counts were already informing customer
  success decisions. The fix required redesigning the query: aggregate tickets at the
  ticket grain grouped by customer, aggregate subscriptions at the subscription grain
  grouped by customer, then join the two aggregates at the customer grain — grain
  alignment after compression, not before.
- **Why Check 1 alone catches this**: The join creates fan-out invisibly. No SQL error
  is raised. The result contains a positive, plausible number. Only the comparison of
  COUNT(\*) to COUNT(DISTINCT pk) exposes the grain mismatch.

### Case 2: E-Commerce Join — Result Grain Changes Silently (Ce01 / Ch. 8)

- **Setup**: A Customers table (one row per customer) is joined to an Orders table
  (one row per order). Alice has two orders.
- **What the grain audit would have caught**: Check 1 — COUNT(\*) of the join result
  is 3 (one row per Alice-order pair, plus one row for the other customer). COUNT
  (DISTINCT customer_id) is 2. Mismatch confirmed: the result grain has changed from
  "one row per customer" to "one row per order." Any aggregate on a customer-level
  attribute (e.g., signup_bonus) from this result will double-count Alice's.
- **Critical insight**: The join is syntactically correct and the result is semantically
  correct for order-level analysis. The audit does not prohibit the join — it forces
  explicit acknowledgment that the result grain is now "one row per order," so that
  anyone who counts customers or sums customer-level metrics from this result knows to
  handle the grain change.
- **Documentation requirement (Check 4)**: If this join result is materialized as a
  table, the grain statement must read "one row per order, carrying customer attributes
  — not suitable for customer-level aggregation without a prior GROUP BY on customer_id."

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

A data engineer ships a new `daily_active_sessions` table. The primary key is
`user_id + session_date`. Does it pass the grain audit?

**Run the five checks in order:**

1. **Check 1 — Uniqueness**: `SELECT COUNT(*) vs. COUNT(DISTINCT user_id, session_date)`.
   If a user can have multiple sessions per day and all are collapsed into one row by an
   aggregation upstream, these counts will match and the grain is "one aggregated row per
   user per calendar day." If the upstream aggregation was accidentally skipped, raw
   session-level rows may be loaded without deduplication, and the counts will diverge —
   exposing the fact that the grain claim is wrong.

2. **Check 2 — NULLs**: Are there rows where `user_id` is NULL or `session_date` is NULL?
   A NULL `user_id` means the row cannot be attributed to any user — it violates the grain
   claim and will corrupt any per-user aggregate. A NULL `session_date` means the temporal
   boundary is undefined. Both are disqualifying.

3. **Check 3 — Late data**: The rule for late-arriving sessions must be declared. If a
   session event from yesterday arrives today, does it upsert yesterday's row or create
   a new row? Without a declared rule, a pipeline retry will create duplicate rows and
   fail Check 1 on the next run.

4. **Check 4 — Documentation**: The grain statement must explicitly say: "One aggregated
   row per user per calendar day, representing the sum of all session activity for that
   user on that date. Not suitable for per-session-duration or per-click-path analysis."

5. **Check 5 — Use-case coverage**: If stakeholders need session-count per user per day,
   this grain works. If they need per-session duration, click paths, or session start/end
   times, this grain destroys that detail and the table cannot serve those questions. The
   audit requires confirming which use cases are in scope before deployment.

### Additional Language Signals That Activate This Skill

- "We ran the migration — is this ready to go live?"
- "How do I verify the PK is actually unique?"
- "We documented the grain — what else do we need to check?"
- "Something looks off with the row counts after the join"
- "Do we have duplicates in this table?"
- "What happens if data arrives late for this table?"

### Distinguishing from Adjacent Skills

- Difference from `grain-decision-four-questions`: That skill is upstream — it decides
  what grain a dataset should have. This skill is downstream — it validates that the
  decided grain was implemented correctly. Use this skill after grain-decision-four-questions
  has been applied, immediately before production deployment.
- Difference from `aggregation-workflow-four-steps`: That skill assumes a correctly-grained
  table already exists and designs aggregations over it. This skill verifies the table is
  correctly grained before any aggregation is designed.
- Difference from `six-aggregation-properties`: Six-aggregation-properties is a broader
  framework covering how aggregations behave (additivity, decomposability, closure,
  boundedness). This checklist is specifically scoped to pre-deployment grain validation.

______________________________________________________________________

## E — Execution Steps

Once activated, work through the five checks in order. Do not shortcut: Check 1 failing
does not mean skipping Checks 2–5. Each check targets a different failure mode.

1. **Check 1 — Uniqueness (COUNT test)**

   - Run: `SELECT COUNT(*), COUNT(DISTINCT <pk_column(s)>) FROM <table>;`
   - For composite PKs: `COUNT(DISTINCT <col1>, <col2>)` or equivalent for the platform.
   - Pass condition: Both counts are equal.
   - Failure condition: Counts diverge. This means the assumed grain is wrong — either
     duplicate rows were loaded, or the aggregation step upstream that was supposed to
     collapse rows did not run or ran incorrectly.
   - Action on failure: Do not deploy. Investigate the upstream pipeline for missing
     deduplication or GROUP BY logic. Identify the source of duplicates before proceeding.

2. **Check 2 — NULLs in grain-defining columns**

   - Run: `SELECT COUNT(*) FROM <table> WHERE <grain_col1> IS NULL OR <grain_col2> IS NULL;`
   - Pass condition: Zero rows returned.
   - Failure condition: Any non-zero count.
   - Action on failure: Treat NULLs in grain-defining columns as a grain contract
     violation, not a data quality issue. Determine whether the NULL represents a
     legitimate unknown (which means the row cannot be assigned to a grain and must be
     excluded or handled separately) or a pipeline bug (a join failed to populate the
     grain column). In either case: do not deploy until the handling rule is explicit.

3. **Check 3 — Late-arriving data rule**

   - Ask: For each time-bounded or event-based grain column, what is the declared
     behavior when a record arrives after the relevant window has closed?
   - Pass condition: A written rule exists and the pipeline implements it. Example rules:
     "upsert by (user_id, session_date) — late arrivals update the existing row,"
     or "reject arrivals older than 48 hours."
   - Failure condition: No rule exists. Pipeline behavior on late data is undefined.
   - Action on failure: Define the rule before deployment. Undeclared late-data handling
     means the first pipeline retry or out-of-order delivery will create duplicates and
     fail Check 1 on the next audit.

4. **Check 4 — Grain documentation**

   - Write or verify a grain statement in the table's schema comment, data catalog entry,
     or README. The grain statement must answer in one sentence: "One row in this table
     represents \_\_\_."
   - The statement must include: the entity (what), the time scope if applicable (when),
     and any material exclusions (e.g., "excluding cancelled orders").
   - Pass condition: A person unfamiliar with this table can read the grain statement and
     know what aggregate operations are safe without asking anyone.
   - Failure condition: No grain statement exists, or it is vague ("this table contains
     session data").

5. **Check 5 — Use-case coverage**

   - List the stated downstream business questions this table must answer.
   - For each question, verify it can be answered by aggregating up from this grain
     (GROUP BY + SUM/COUNT/AVG).
   - For each question that requires disaggregating below this grain: document that this
     table cannot answer it and identify where the finer-grain source lives.
   - Pass condition: All in-scope questions have a confirmed aggregation path from this
     grain. Out-of-scope questions are explicitly documented as not answerable from this
     table.
   - Failure condition: A required in-scope business question requires detail that this
     grain destroys. Action: revisit grain-decision-four-questions — the grain may have
     been set too coarse.

**Completion criteria**: All five checks pass. The grain statement is written. The
late-data rule is documented. The table is ready for production.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The grain has not yet been decided**: If the question is "what should the grain be?"
  rather than "did we implement the grain correctly?", use `grain-decision-four-questions`
  first. This checklist requires a declared grain as its input — it cannot help decide
  what grain to use.

- **The table is already in production with downstream consumers**: The audit can identify
  that the grain is wrong, but it cannot fix it. Fixing a grain error in production
  requires rebuilding from raw source data — re-running aggregations, migrating downstream
  consumers, and backfilling history. The audit is a pre-deployment gate, not a
  production repair tool. If the table is already live and Check 1 fails, the remediation
  is a grain redesign project, not a checklist execution.

- **The grain is not a structured, row-based grain**: This checklist is written for
  structured tabular data (SQL tables, dataframes, columnar stores). Grain validation
  for streaming windows, graph triples, or document stores requires different diagnostic
  approaches. Ch. 8 explicitly notes that streaming and unstructured grain are covered
  in volume 2.

### Failure Patterns Warned About by the Author

- **Fan-out from unchecked joins** (ce01): Joining a customer-grain table to an
  order-grain table without a GROUP BY step produces a result where COUNT(\*) exceeds
  the number of customers. This is the most common grain implementation error. Check 1
  catches it directly. Warning sign: a query JOINs to a transactions or events table
  and the result is used for customer-level aggregation without an explicit grain
  normalization step.

- **Mixed-grain trap** (ce02): A single table contains both atomic transaction rows and
  pre-computed daily summary rows. A SUM() over the table double-counts revenue silently.
  Warning sign: a table has a `row_type` or `grain_level` column with multiple distinct
  values, or some rows have NULL in columns that are required for atomic records (such
  as `product_id`) while other rows do not.

- **Incompatible grain joins**: Two datasets with different grains are joined directly
  without a GROUP BY alignment step. Check 1 on the join result will expose the
  fan-out. Prevention: always run Check 1 on the result of any new join before
  materializing it as a table or using it for aggregation.

### Author's Blind Spots / Limitations of the Era

- **Streaming tables are explicitly deferred**: Reis notes that streaming grain
  (tumbling, sliding, session windows) and late-arriving data in streaming systems
  receive full treatment in volume 2. Check 3 (late-arriving data) applies conceptually
  but the specific implementation mechanics for watermarks and window state in stream
  processing are not covered by this checklist.

- **The checklist is necessary but not sufficient**: Reis explicitly states "this
  checklist won't catch every grain problem." Check 1 passing confirms the primary key
  is unique — it does not confirm the primary key is the *correct* primary key for the
  stated grain. A table with a surrogate auto-increment key will always pass Check 1
  trivially, even if the business grain (user_id + session_date) has duplicates that
  the surrogate key masks.

### Easily Confused Adjacent Practices

- **General data quality checks**: Data quality frameworks (Great Expectations,
  dbt tests, schema validation) check for null rates, type conformance, referential
  integrity, and value distributions. The grain audit checklist is narrower and more
  specific: it checks whether the implementation matches the declared grain contract,
  not whether the data values are clean. A table can pass all data quality checks and
  still fail Check 1.

- **Schema validation**: Schema validation confirms column types and constraints exist.
  It does not confirm the grain is what the designer intended. A CHECK CONSTRAINT on
  a primary key proves uniqueness at insert time but cannot detect whether the grain
  semantics are correct (e.g., that a `user_id + event_date` key actually represents
  the intended "one row per user per day" grain, or whether it is accidentally serving
  as "one row per pipeline batch per user per day").

______________________________________________________________________

## Related Skills

- **depends-on** [`grain-decision-four-questions`](../grain-decision-four-questions/SKILL.md): This checklist requires a declared grain as its input — grain-decision-four-questions is the upstream tool that produces the grain declaration this checklist then validates.
- **composes-with** [`six-aggregation-properties`](../six-aggregation-properties/SKILL.md): Property 1 of the six-aggregation-properties checklist (grain alignment) maps directly to Checks 1 and 2 here; running both pre-deployment closes the full structural validation loop.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f09 (framework extractor) + p16 (principle extractor) — merged at Phase 1.5
- **Counter-examples used**: ce01 (fan-out from mismatched grain join), ce02 (mixed-grain trap)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03
