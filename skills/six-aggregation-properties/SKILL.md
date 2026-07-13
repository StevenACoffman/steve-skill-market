---
name: six-aggregation-properties
description: |
  Use this skill when a user needs to verify that an aggregate metric is structurally
  safe before it ships to any production consumer — dashboard, API endpoint, ML feature,
  or executive report. This is a PRE-SHIPPING checklist. Run it on every metric that
  will be consumed in production. Do not run it on ad-hoc exploratory queries where
  correctness is evaluated informally by the analyst.

  Trigger signals:
  - "Is this aggregation correct before we ship it?"
  - "Why are the dashboard numbers wrong?"
  - "The rollup totals don't match the raw data"
  - "How do I know this metric is trustworthy?"
  - "We're about to deploy a new dashboard / metric / ML feature"
  - Any question about verifying aggregate metric correctness before production deployment
tags: [aggregation, checklist, pre-shipping, grain, disjointness, additivity, decomposability, closure, boundedness]
---

# Six Structural Properties of Safe Aggregation

## R — Original Text (Reading)

> **Structural Principles of Safe Aggregation**
> There are structural rules that determine whether an aggregation is safe and
> valid — and these rules hold across all forms of data: tables, documents, graphs,
> events, vectors, images, and more. If these rules aren't respected, aggregation
> produces contradictions, double counting, or mathematically invalid results.
>
> The root cause is always one of the six structural principles:
>
> 1. If you're constantly deduping data to get a count, you've failed **Disjointness**.
> 2. If your sums change depending on which server runs the query, you've failed
>    **Decomposability**.
> 3. If your averages produce values outside the domain (an "average zip code"),
>    you've failed **Closure**.
> 4. If nobody can tell you what time range a metric covers, you've failed
>    **Boundedness**.
> 5. If a dashboard shows impossible numbers after a table join, you've failed
>    **Grain alignment**.
>
> Treat aggregation as data model verification. If you can cleanly count your
> entities, align grains, reason about additivity, and predict the behavior of
> your aggregates across different data shapes, your model is structurally sound.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 9

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The six properties form a complete structural theory of aggregation correctness. They
are not stylistic guidelines — each property corresponds to a specific mathematical
requirement, and violating any one of them produces a result that is silently wrong.
The numbers come out, they look plausible, and they are incorrect. That is the
defining danger: no exception is raised, no pipeline fails, but every downstream
decision that consumes the metric is compromised.

The properties have a natural ordering that matches logical dependency:

**Property 1 — Grain Alignment** is the prerequisite for all five others. If records
in the aggregated dataset do not share a single, consistent grain, every subsequent
property is undefined. You cannot check disjointness if you do not know what a single
instance is. Grain alignment is the output of grain-decision-four-questions applied
correctly; if that skill was not used at design time, property 1 is the first thing
to verify here.

**Property 2 — Disjointness** is violated whenever a single instance can appear in
more than one group. Many-to-many relationships are the most common trigger: a product
assigned to multiple categories, a user counted in multiple cohorts, a ticket tagged
with multiple labels. When groups overlap, any SUM or COUNT across groups
double-counts the overlapping instances. The fix is not in the query; it is in the
model — either make groups exclusive, or use COUNT(DISTINCT) explicitly and document
that the result is not additive.

**Property 3 — Additivity** classifies every measure into one of three categories.
Additive measures (revenue, quantity) can be summed across all dimensions. Semi-additive
measures (balances, headcount) can be summed across some dimensions but not time — you
can sum all customers' balances today, but you cannot add Monday's balance to Tuesday's
balance and get a meaningful result. Non-additive measures (averages, ratios,
percentages, COUNT DISTINCT) cannot be directly summed at all; they must be stored
and computed as their additive components (numerator and denominator) and only divided
at the final step. Misclassifying a non-additive measure as additive is the source of
the average-of-averages trap (see ce03).

**Property 4 — Decomposability** is the technical foundation of the decompose-averages
rule. A measure is decomposable if computing partial aggregates on separate data
partitions and combining the partials produces the same result as aggregating the full
dataset at once. SUM, COUNT, MIN, and MAX are decomposable because they are associative
and commutative: (a + b) + c = a + (b + c). AVG is NOT decomposable because it is not
associative — the average of (AVG of partition A) and (AVG of partition B) is not the
overall average unless the partitions are equal in size. This matters for distributed
systems, pipeline retries, and any multi-tier rollup architecture. The fix is always
the same: store SUM and COUNT separately, divide at the end.

**Property 5 — Closure** requires that the result of an aggregation remains a valid
member of the original value domain. Summing integers yields an integer (closed).
Averaging categories — "Red" and "Blue" — yields a number that is not a color (not
closed). Averaging zip codes yields a zip code that corresponds to no real location.
Averaging word embeddings from semantically unrelated documents yields a vector
that represents no coherent concept. Closure is the bridge from numeric aggregation
to semantic and AI contexts: mean pooling of unrelated embeddings in a RAG system is
a closure failure in the embedding space.

**Property 6 — Boundedness** requires that every aggregation declares its explicit
scope: time range AND dimensional constraints. "Total Revenue" is not a valid metric.
"Total Revenue for North America, calendar year 2025" is. An undeclared time boundary
is nearly always a hardcoded date left over from a past period that nobody updated,
producing a stale aggregate that changes meaning silently. Dimensional unboundedness
produces aggregates that cannot be compared across periods, regions, or business units.

Together, the six properties form a complete pre-shipping gate. A metric that passes
all six is structurally sound. A metric that fails any one is silently incorrect,
regardless of how the downstream query is written.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Smartwatch Category Revenue — Disjointness Violation (Ce04)

- **Scenario**: A product analytics team builds a "Revenue by Category" report. A
  smartwatch is tagged under three categories: Electronics, Fitness, and Accessories.
- **How the checklist applies**: Property 1 (Grain) passes — one row per order line
  item. Property 2 (Disjointness) fails: the product-to-category relationship is
  many-to-many via a junction table. When the query GROUP BY Product Category, each
  order line item fans out to three rows — one per category. SUM(revenue) across
  categories counts the $300 smartwatch three times: $900 reported, $300 actual.
- **The failure is silent**: The query returns without error. The number is plausible.
  No pipeline alarm fires.
- **Fix required**: Property 2 violation cannot be repaired at the query level by
  adding DISTINCT — you must either (a) define a primary category for each product
  (enforcing disjointness in the model), or (b) explicitly redesign the report to
  show revenue-per-category-assignment (not revenue-per-sale) and document that the
  category total exceeds company revenue by design.

### Case 2: Retail AOV — Decomposability Violation (Ce03)

- **Scenario**: A retail analytics team computes company-wide average order value (AOV)
  by averaging the per-store AOVs: Store A ($45, 100 orders), Store B ($75, 10 orders),
  Store C ($80, 5 orders). Result: ($45 + $75 + $80) / 3 = $66.67.
- **How the checklist applies**: Property 4 (Decomposability) fails: AVG is not
  associative. The three store averages are given equal weight, but Store A has 100
  orders and Store C has 5. The true company-wide AOV is $5,650 / 115 = $49.13 — a
  26% gap. Property 3 (Additivity) also flags this: AOV is a non-additive measure
  (a ratio). The fix is to store SUM(order_value) and COUNT(orders) at the store
  level, compute company-wide AOV as SUM(all store sums) / SUM(all store counts).
- **Organizational consequence**: If this metric feeds a pricing or bonus calculation,
  the executive team is making decisions against a number that overstates actual
  average order value by $17.54. The error is proportional to size disparity between
  stores — it gets worse as the size distribution becomes more unequal.

### Case 3: Customer Support Synthesis — All Six Properties Applied (From Ch. 12)

- **Scenario**: An online retailer builds a customer support analytics model covering
  tickets from email, chat, and phone. They want to track first-contact resolution
  rate, resolution time percentiles, and agent effectiveness.
- **How the checklist applies across all six properties**:
  - **Property 1 (Grain)**: One row per conversation. Chat messages that belong to the
    same conversation are NOT separate grain instances. The bitemporal model captures
    both when priority changed (transaction time) and what the priority was at any
    moment (valid time) — enabling correct SLA reporting even when a ticket is
    escalated mid-period.
  - **Property 2 (Disjointness)**: Ticket category taxonomy (Technical → Software → Bug;
    Billing → Refund Request) uses a tree structure where each ticket belongs to
    exactly one leaf node. The taxonomy enforces disjoint groups, enabling clean
    COUNT by category without double-counting.
  - **Property 3 (Additivity)**: First-contact resolution rate is a ratio (non-additive).
    The correct storage is COUNT(CASE WHEN reopened_at IS NULL THEN 1 END) and COUNT(\*)
    separately per agent per week. The rate is computed at query time, never stored as
    a pre-computed ratio.
  - **Property 4 (Decomposability)**: Because numerator and denominator are stored
    separately (not as a pre-computed rate), the metric can be correctly aggregated
    across agents, across weeks, across teams. The fix is structural — in the model,
    not in the query.
  - **Property 5 (Closure)**: "Resolved" has an explicit semantic definition locked
    to the model: "customer confirmed satisfaction via feedback, OR 14 days passed
    without reopening." Without this definition, any count of "resolved tickets" could
    produce any number depending on which interpretation is applied. The aggregation
    result is a count of events that satisfy a specific, bounded condition — the result
    is always a non-negative integer, which is the valid domain.
  - **Property 6 (Boundedness)**: The 14-day window in the resolution definition is
    an explicit dimensional bound. Every metric is computed per agent per week — both
    agent and week are explicit dimensional and temporal scope declarations.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Pre-deployment metric review**: A new dashboard, API metric, or ML feature is
   about to go to production and the team wants to verify it will not silently produce
   wrong numbers.
2. **Numbers that don't match**: An existing metric produces values that differ from
   what analysts expect, or two reports showing "the same" number disagree with each
   other.
3. **Post-join aggregation confusion**: A query JOINs multiple tables and the results
   look inflated — row counts are higher than expected, or revenue exceeds the known
   total.
4. **Rollup architecture review**: A team is building a multi-tier rollup (store →
   region → company) and wants to verify the rollup is correct at each tier before
   production.
5. **Ratio or rate metric review**: Any metric that is a ratio, average, percentage,
   or rate — these are non-additive by definition and require decomposability verification.
6. **Distributed system correctness**: A metric is computed in a distributed processing
   system (Spark, BigQuery, Redshift) and the team wants to verify partial aggregates
   combine correctly.

### Language Signals (Activate When These Appear)

- "Is this aggregation correct?"
- "Why does this metric change when I rerun it?"
- "The category totals add up to more than the company total"
- "These two reports show different numbers for the same thing"
- "We're shipping this dashboard next week"
- "The rollup doesn't match the detail"
- "Can we trust this metric?"

### Distinguishing from Adjacent Skills

- Difference from `aggregation-workflow-four-steps`: That skill is a DESIGN PROCEDURE
  — the sequential steps to correctly specify an aggregation BEFORE code is written.
  This skill is a VALIDATION CHECKLIST — the six-property verification to run on an
  already-designed aggregation BEFORE it ships to production. The correct sequence is:
  use aggregation-workflow-four-steps to design the aggregation, then use this skill
  to validate it before deployment.
- Difference from `grain-decision-four-questions`: That skill decides what grain the
  dataset should use. This skill assumes the grain has been decided and checks that
  the aggregation built on top of that grain is structurally correct.
- Difference from `grain-audit-checklist`: The grain audit validates that the grain
  implementation is correct (uniqueness, nulls, documentation). This skill validates
  that the AGGREGATION BUILT ON TOP OF the grain is correct. Both should be run before
  production deployment; grain-audit-checklist runs first.

______________________________________________________________________

## E — Execution Steps

Once activated, work through all six properties in order. Do not skip any. A violation
of any single property invalidates the metric regardless of whether the other five pass.

1. **Check Property 1 — Grain Alignment**

   - Ask: Does every record in this dataset represent one instance of the same declared
     grain? Are there any rows at a different level of detail (header rows mixed with
     line-item rows, daily summaries mixed with atomic transactions)?
   - Diagnostic: Run COUNT(\*) vs COUNT(DISTINCT pk). If they differ, the grain is
     violated or there are duplicates. If the table has a row_type column with multiple
     values, investigate mixed-grain trap (ce02).
   - Completion criteria: A written grain statement exists ("one row per \_\_\_") and
     COUNT(\*) = COUNT(DISTINCT pk).

2. **Check Property 2 — Disjointness**

   - Ask: When this aggregation groups records into buckets, does each record appear
     in exactly one bucket? Are there any many-to-many relationships between the fact
     entity and the grouping dimension?
   - Diagnostic: If the data model contains a junction table linking the fact entity
     to the grouping dimension (e.g., products-categories), assume overlap and verify
     explicitly. Run the aggregation on a known subset and check if the group totals
     sum to the overall total.
   - Completion criteria: Groups are confirmed disjoint, OR the aggregation is
     explicitly documented as intentionally overlapping (e.g., "total exposures, not
     unique reach") and labeled accordingly.

3. **Check Property 3 — Additivity**

   - Ask: Is this measure additive (can be summed across all dimensions), semi-additive
     (can be summed across some dimensions but not time), or non-additive (ratio,
     average, percentage, COUNT DISTINCT)?
   - For non-additive measures: Is the measure stored as its additive components
     (numerator SUM and denominator COUNT)? Is the ratio computed only at query time?
   - Completion criteria: Every measure in the aggregation is classified. Non-additive
     measures are decomposed into additive components in the model. No pre-computed
     ratio is stored as a column that will be further aggregated.

4. **Check Property 4 — Decomposability**

   - Ask: If this aggregation is computed on two separate data partitions (different
     servers, different time windows, different pipeline runs), and the partial results
     are combined, is the final result the same as computing the aggregation on the
     full dataset at once?
   - Test: If the aggregation function is AVG, or any function derived from AVG, it
     fails decomposability by default. Verify the fix: SUM and COUNT are stored and
     combined separately; division happens last.
   - Completion criteria: Every aggregation function in the metric is confirmed as
     decomposable (SUM, COUNT, MIN, MAX), OR non-decomposable functions are replaced
     by decomposed form (SUM + COUNT) and the final division is documented.

5. **Check Property 5 — Closure**

   - Ask: Is the result of this aggregation a valid member of the original value
     domain? Can the output be interpreted as the same type of thing as the inputs?
   - Common closure failures: averaging categorical values (zip codes, status codes,
     category names); mean-pooling semantically unrelated embeddings; computing a
     "typical" value for a bimodal distribution where the mean represents no real
     instance.
   - Completion criteria: The aggregated result is confirmed to be a meaningful value
     in the original domain. If the result is a derived domain (e.g., a ratio is in
     [0,1] while inputs are in [0, N]), the new domain is explicitly documented.

6. **Check Property 6 — Boundedness**

   - Ask: Does this metric have an explicit time range? An explicit dimensional scope
     (region, product line, business unit)? Are both declared in the metric definition,
     not assumed or implicit?
   - Diagnostic: Is there a hardcoded date in the WHERE clause that was set
     historically and may no longer be current? Does the dashboard card that displays
     this metric show the boundary conditions alongside the number?
   - Completion criteria: The metric definition includes: "this metric measures [what]
     over [explicit time range] for [explicit dimensional scope]." Any implicit filters
     or hardcoded dates are surfaced and verified as intentional.

**Final gate**: All six properties must pass. Shipping a metric with any failed property
means shipping a silently incorrect number. The checklist does not prescribe the fix
for each violation — each violation requires a different remedy (grain redesign,
model restructuring, storage change, semantic definition update).

______________________________________________________________________

## B — Boundary ★

### This Is a PRE-SHIPPING Checklist — Use It Correctly

This checklist is designed for one specific moment: before a metric enters a production
consumer (dashboard, API, ML feature, report). It is NOT an exploratory analysis tool.
Running all six checks on an ad-hoc query you are writing for a one-time analysis is
overkill and wastes time. Run it on anything that will be seen by a decision-maker,
consumed by a downstream system, or used in a model.

### When NOT to Use This Skill

- **For ad-hoc exploratory queries**: If you are exploring data informally to understand
  its shape, you do not need to verify all six properties. Verify informally and move on.
- **For designing an aggregation from scratch**: If no aggregation exists yet, use
  aggregation-workflow-four-steps first to design the correct aggregation, then bring
  it here for verification before shipping.
- **For grain design**: If the fundamental question is "what should one row represent?",
  use grain-decision-four-questions. That decision must happen before any aggregation
  can be checked here.

### What the Checklist Does NOT Provide

The six-property checklist identifies violations. It does NOT prescribe the fix for
each violation type — the fix for each failed property is different:

- A Grain failure requires rebuilding the dataset at the correct grain.
- A Disjointness failure requires either redefining the grouping dimension (model
  change) or redesigning the report to handle overlap explicitly.
- An Additivity/Decomposability failure requires changing how the measure is stored
  (structural pipeline change, not a query fix).
- A Closure failure requires redefining the aggregation operation entirely.
- A Boundedness failure requires adding explicit scope declarations to both the
  query and the metric definition visible to consumers.

### Author's Failure Pattern Diagnostics

From Ch. 9, the six failure modes have specific observable symptoms in production:

| Property Failed | Observable Symptom                                                                 |
| --------------- | ---------------------------------------------------------------------------------- |
| Grain           | Dashboard shows impossible numbers after a table JOIN                              |
| Disjointness    | Deduplication required to get correct counts; category totals exceed company total |
| Additivity      | Ratio metrics stored as columns and then re-averaged; non-additive rollups         |
| Decomposability | Sums change depending on which server runs the query; AVG of AVG trap              |
| Closure         | Aggregated result is not a meaningful value in the original domain                 |
| Boundedness     | Nobody can tell what time range or scope a metric covers                           |

### Counter-Examples from the Book

- ce03: Average-of-averages (AOV example) — Decomposability + Additivity failure
- ce04: Smartwatch category revenue — Disjointness failure (many-to-many junction)
- ce20: Null aggregation silently altering results — Boundedness and Additivity edge case
  (NULL treated as zero vs. excluded silently by AVG())

### Author's Blind Spots / Limitations

- **Streaming systems**: The chapter notes that streaming introduces stateful aggregation
  with window semantics (tumbling, sliding). Sliding windows create intentional overlap
  (a single event belongs to multiple windows) — this is a designed Disjointness
  exception, not a failure. The checklist applies in principle but requires adaptation
  for window-type specification in streaming contexts.
- **Semantic and AI aggregation**: Properties 4 and 5 (Decomposability and Closure)
  apply to vector aggregation in ML systems (mean pooling of embeddings), but the
  "fix" in that context is different from the tabular fix — it requires architectural
  changes to the retrieval system, not pipeline changes. The checklist signals the
  failure correctly but the remediation path is outside the scope of this skill.
- **Approximation algorithms**: At scale, exact COUNT(DISTINCT) is computationally
  expensive; HyperLogLog and similar probabilistic data structures trade precision for
  performance. The checklist cannot tell you when approximation is "good enough" for
  the business — that is a judgment call requiring stakeholder alignment on acceptable
  error bounds.

______________________________________________________________________

## Related Skills

- **depends-on** `aggregation-workflow-four-steps`: This checklist validates an aggregation that was designed using the four-step workflow — the workflow produces the artifact; this skill confirms it is structurally safe before shipping.
- **composes-with** `decompose-averages-sum-count`: Properties 3 (Additivity) and 4 (Decomposability) of this checklist are precisely what the decompose rule implements — when those properties fail, that rule provides the structural fix.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f10 (framework extractor) + p19 (principle extractor) — merged at Phase 1.5
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 9 — Counting and Aggregation: Controlling the Grain
