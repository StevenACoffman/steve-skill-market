---
name: aggregation-workflow-four-steps
description: |
  Use this skill when a user is about to DESIGN an aggregation — before writing any
  SQL GROUP BY, before building a dashboard metric, before engineering an ML feature.
  This is a DESIGN-TIME workflow, not a validation tool. Activate it the moment a user
  articulates an aggregation requirement, before any code exists.

  Trigger signals:
  - "I need to write a GROUP BY query for..."
  - "How do I aggregate this metric?"
  - "The numbers from the rollup don't add up"
  - "We need a weekly/monthly/quarterly version of this metric"
  - Any aggregation design request before SQL is written
  - "How do I count unique users across channels?"
  - "How do I roll up store-level metrics to company-wide?"

  Do NOT use this skill when:
  - An aggregation is already designed and built, and the question is about verifying
    it before shipping to production (use six-aggregation-properties instead)
  - The grain of the dataset has not yet been determined (use grain-decision-four-questions
    first — grain declaration is Step 1 of this workflow; that skill resolves it)
  - The question is purely about SQL syntax with no ambiguity in what is being measured

  Based on: "Practical Data Modeling" by Joe Reis (2026), Ch. 9 — Counting and
  Aggregation: Controlling the Grain.
source_book: "Practical Data Modeling" by Joe Reis
source_chapter: Ch. 9 — Counting and Aggregation: Controlling the Grain
tags: [aggregation, workflow, design-framework, grain, disjointness, additivity, closure, boundedness]
related_skills:
  - slug: grain-decision-four-questions
    relation: depends-on
  - slug: six-aggregation-properties
    relation: composes-with
  - slug: decompose-averages-sum-count
    relation: composes-with
---

# Aggregation Workflow — Grain → Group → Operation → Bounds

## R — Original Text (Reading)

> **The Aggregation Workflow**
> To make [the structural principles] actionable, here's a four-step workflow to apply
> whenever you design an aggregation, whether you're writing a SQL query, designing a
> dashboard, or building features for an ML model.
>
> **Step 1: Define the "One" (Identity & Grain).** Before you count anything, ask:
> What is the fundamental unit here? Are you counting users, sessions, or page views?
> If you're aggregating revenue, does "one" row represent a line item, an order, or a
> daily summary? Check that the grain is consistent across all records. Before writing
> any COUNT, SUM, or AVG, explicitly define what constitutes a unique instance.
>
> **Step 2: Define the "Many" (Grouping & Disjointness).** How are you organizing
> these units? Are you grouping by Customer, by Region, or by Product Category? Are
> the groups disjoint? If an item belongs to two groups (e.g., a product in multiple
> categories), summing the groups will double-count.
>
> **Step 3: Select the Aggregation Operation (Additivity & Closure).** What math are
> you applying? Is the measure additive (like sales) or non-additive (like
> temperature)? Does the operation preserve meaning? If you average a list of zip
> codes, you get a number that isn't a zip code — that's a closure violation.
>
> **Step 4: Define the Bounds (Time & Dimension).** What is the scope of this
> calculation? "Total Revenue" is meaningless without boundaries.
>
> **Grain → Group → Operation → Boundaries → Aggregate.**
> Follow this sequence, and your aggregates will be trustworthy.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 9

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The four-step workflow is a SPECIFICATION PROCEDURE, not a calculation. The insight
is the sequence: most aggregation errors occur not because practitioners choose the
wrong math, but because they skip a definitional step and proceed as if it had been
answered. The workflow forces each step to be explicitly answered before the next
step is reached. Each step, if skipped, produces a specific diagnosable failure mode.

**Step 1 — Grain / Identity** establishes what constitutes one unique instance and
confirms that all records share that grain. This is not the same as knowing what
table to query. It is the declaration: "one record in this dataset represents one
\[X\]." If the grain is unclear or mixed — some rows represent orders, some represent
line items — every aggregation built on top of it inherits undefined behavior. The
most common symptom of a skipped Step 1 is fan-out: a JOIN between two tables at
different grains causes the result set to have more rows than either source, and
any COUNT or SUM on the result is inflated. This step connects directly to
grain-decision-four-questions — if grain is not yet settled, resolve it there before
proceeding.

**Step 2 — Group / Disjointness** asks how instances are organized into the buckets
that the aggregation will collapse. The critical question is whether groups are
mutually exclusive. Disjoint groups (each instance belongs to exactly one group)
allow safe SUM and COUNT across groups — the group totals add up to the overall
total. Overlapping groups (an instance belongs to multiple groups via a many-to-many
relationship) require explicit handling: either enforce a primary group assignment in
the model, or use COUNT(DISTINCT) and label the result as "exposures" not "unique
instances." Skipping Step 2 is the source of the smartwatch category double-count
(ce04) and the multi-channel reach problem. The failure is detectable when group
totals exceed the known overall total.

**Step 3 — Operation / Additivity + Closure** selects the aggregation function and
verifies two constraints. First, additivity: is the measure additive (SUM is safe
across all dimensions), semi-additive (SUM is safe across some dimensions but not
time), or non-additive (ratios, averages, percentages, COUNT DISTINCT — which require
decomposition into SUM + COUNT components)? Second, closure: does the result of the
operation remain a valid member of the original value domain? A correct Step 3 answer
explicitly names the function AND verifies both constraints. If the measure is non-
additive, Step 3 also specifies how it will be decomposed and at what tier the final
division will occur. Skipping Step 3 produces the average-of-averages trap (ce03)
when pre-computed averages are re-averaged at a higher tier.

**Step 4 — Bounds / Scope** declares the explicit time range and dimensional
constraints within which the aggregation holds meaning. "Last 30 days" is a time
bound. "North America region" is a dimensional bound. Both must be explicit. An
aggregation without declared bounds is technically computable but semantically
undefined — a reader cannot know what period it covers, whether it is comparable to
a prior period, or whether a filter applied earlier in the pipeline is silently
constraining it. Skipping Step 4 produces the "Total Revenue" card with a hardcoded
two-year-old date that nobody updated.

The load-bearing insight of the workflow: each step not only answers its own question
but also constrains the answer to the next step. Grain (Step 1) determines what counts
as a valid grouping key (Step 2). The grouping (Step 2) determines which aggregation
functions are valid (Step 3). The operation (Step 3) determines what boundary
declarations are required (Step 4). Skipping any step introduces an unconstrained
degree of freedom that is filled by implicit assumptions — and those assumptions are
where the errors live.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: SaaS Customer Health Dashboard — Step 1 Skipped (Grain Failure, Ce01)

- **Scenario**: A SaaS company builds a "Customer Health" dashboard. The data model
  joins Customers (one row per customer) with Subscriptions (one row per subscription)
  and Support Tickets (one row per ticket). A customer can have multiple subscriptions
  and multiple tickets. The team writes a query that joins all three tables and counts
  tickets per customer.
- **What Step 1 would have revealed**: Step 1 asks: "What is the fundamental unit
  here?" The query needs ticket counts per customer — so the grain of the result
  should be one row per customer. But the JOIN mixes three different grains in a
  single operation without a prior GROUP BY. A customer with 3 subscriptions and
  5 tickets produces 15 result rows (3 × 5 fan-out). COUNT(tickets) per customer
  from this result is 15, not 5. The grain of the JOIN result is "one row per
  customer-subscription-ticket combination" — not what anyone intended.
- **The fix**: Step 1 specifies: aggregate tickets at ticket grain (GROUP BY
  customer_id, COUNT tickets), aggregate subscriptions at subscription grain
  (GROUP BY customer_id, COUNT subscriptions), then JOIN the two aggregated results
  at customer grain. The JOIN happens after compression, not before. This is the
  standard aggregate-then-join pattern.
- **Why skipping Step 1 is the root cause**: If the team had answered "one row in
  the result set represents one [customer]" before writing any SQL, the fan-out would
  have been immediately detectable — the intermediate JOIN result has more rows than
  the Customers table, which violates the stated grain.

### Case 2: Smartwatch Category Revenue — Step 2 Skipped (Disjointness Failure, Ce04)

- **Scenario**: An e-commerce analytics team needs "Total Daily Revenue by Product
  Category." The data model has a products-categories junction table (many-to-many).
  A smartwatch is tagged under Electronics, Fitness, and Accessories.
- **What Step 2 would have revealed**: Step 2 asks: "Are the groups disjoint?" The
  answer here is no — the product-to-category relationship is many-to-many. A single
  product order appears in three category groups simultaneously. If the team proceeds
  without resolving the overlap, GROUP BY category_name fans out each product to
  every matching category row in the junction table. A $300 smartwatch sale is counted
  three times: $900 in the "Total Daily Sales" aggregation.
- **The fix requires a model decision (not a query fix)**:
  - Option A: Assign a primary category per product (enforcing disjointness in the
    data model). This makes the groups disjoint and allows clean SUM.
  - Option B: Accept the overlap and redesign the report explicitly as "Revenue by
    Category Assignment" (each assignment counted once), documented as intentionally
    exceeding company total. Use COUNT(DISTINCT order_id) for order counts.
- **Why skipping Step 2 is the root cause**: If the team had answered "groups are
  disjoint / overlapping" before writing SQL, they would have recognized that GROUP BY
  category_name produces an overlapping aggregation on a many-to-many relationship.
  The fix is a design decision, not a query patch.

### Case 3: Marketing Campaign Reach — Step 2 + Step 3 Interaction (V2 Novel Scenario)

- **Scenario**: A marketing team asks for "total campaign reach per week" across
  email, social, and display channels. A user can be reached by all three channels
  in the same week.
- **What Steps 2 and 3 would reveal**:
  - Step 1 (Grain): One record = one user-channel-week exposure event. The grain is
    defined at the exposure level, not the user level.
  - Step 2 (Disjointness): Groups are NOT disjoint. The same user_id appears in the
    email group, the social group, and the display group for the same week. Summing
    per-channel user counts (email: 10,000 users + social: 8,000 users + display:
    6,000 users = 24,000) overcounts users who were reached by multiple channels.
  - Step 3 (Operation): If the business question is "distinct users reached by at
    least one channel," the correct function is COUNT(DISTINCT user_id) across all
    channels — not SUM of per-channel counts. But COUNT(DISTINCT) is non-additive:
    Monday's 10,000 distinct users and Tuesday's 9,000 distinct users cannot be summed
    to get a two-day distinct user count. You must return to the user-channel-week
    grain and recount from atomic data.
  - Step 3 also resolves a semantic ambiguity: if the business question is "total
    exposures" (not unique users), SUM across channels is correct — but the metric
    must be labeled "exposures" not "users reached."
- **The workflow prevents the error**: Without the explicit Step 2 disjointness check
  and Step 3 function selection, the "natural" query is SUM(per_channel_counts), which
  produces an inflated figure presented as unique reach.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **New aggregation design**: A user is about to write a GROUP BY query and has not
   yet specified what the aggregation unit is, how the groups are organized, which
   function applies, or what the time scope is.
2. **Metric definition for a dashboard**: A user is defining a new KPI or metric for
   a dashboard and has the business question but not the structural specification.
3. **Rollup architecture design**: A user is building a multi-tier rollup (daily →
   weekly → monthly; store → region → company) and needs to verify each tier is
   correctly specified before building the pipeline.
4. **ML feature engineering**: A user is designing a feature (e.g., "average order
   value per customer in the last 30 days") and needs to specify grain, grouping,
   function, and bounds before writing the feature computation.
5. **Confusion about the right aggregation function**: A user knows what they want
   to measure but is unsure whether to use SUM, COUNT, AVG, COUNT(DISTINCT), or
   a ratio — Step 3 resolves this.
6. **Numbers from the rollup don't add up**: A user has an existing aggregation that
   produces wrong results and needs to diagnose which step was skipped or incorrectly
   specified.

### Language Signals (Activate When These Appear)

- "I need to write a GROUP BY query for..."
- "How do I aggregate this metric?"
- "The numbers from the rollup don't add up"
- "We need a weekly/monthly/quarterly version of this metric"
- "How do I count unique users across channels?"
- "How do I roll this up to the company level?"
- "What aggregation should I use for this?"
- Any aggregation design request before SQL is written

### Distinguishing from Adjacent Skills

- Difference from `six-aggregation-properties`: That skill is a POST-DESIGN validation
  checklist — it verifies that a completed aggregation is structurally safe before
  shipping to production. This skill is a PRE-DESIGN specification procedure — it
  produces the correct aggregation specification before any code is written. The
  sequence is: use this skill first to DESIGN the aggregation, then use
  six-aggregation-properties to VERIFY it before shipping. They are not interchangeable.
- Difference from `grain-decision-four-questions`: That skill resolves what the grain
  of a NEW dataset should be. Step 1 of this workflow assumes grain is known (declared)
  and verifies it is consistent. If Step 1 reveals grain is not yet settled, delegate
  to grain-decision-four-questions and return here once grain is declared.
- Difference from `decompose-averages-sum-count`: That is a specific rule about one
  failure type in Step 3 (non-additive measures / AVG of AVGs). This is the complete
  design workflow that catches ALL four categories of failure. The decompose rule is
  what Step 3 prescribes when the measure is non-additive; it is a sub-procedure of
  this workflow, not a replacement for it.

______________________________________________________________________

## E — Execution Steps

Once activated, work through all four steps in strict order. Each step must produce a
declarative written statement before proceeding to the next. Do not write any SQL,
query, or aggregation logic until Step 4 is complete.

1. **Answer Step 1 — Grain / Identity**

   - Ask: What is the fundamental unit of this aggregation? What does "one" mean here?
   - State the answer as: "One record in the source dataset represents one [X]."
   - Then verify: Is the grain consistent across all records? Are there records at a
     different level of detail (summaries mixed with atomic rows)?
   - Check for fan-out risk: Will any JOIN in this query change the grain of the
     result? If yes, specify when the grain change happens and whether the JOIN
     should happen before or after aggregation.
   - Completion criteria: A specific grain statement exists ("one row per customer
     transaction"). If grain is not settled, stop and apply grain-decision-four-questions
     before proceeding.

2. **Answer Step 2 — Group / Disjointness**

   - Ask: How are instances being grouped? What is the GROUP BY dimension?
   - Are the groups mutually exclusive? Can a single instance appear in more than one
     group?
   - Check for many-to-many relationships: Is the grouping dimension connected to the
     fact entity through a junction table?
   - If groups are overlapping: decide explicitly — (a) enforce disjointness in the
     model (assign a primary group per instance), or (b) accept overlap and design
     the aggregation to handle it explicitly (COUNT DISTINCT, labeled as "exposures"
     not "unique instances").
   - Completion criteria: A written statement declares whether groups are disjoint or
     overlapping. If overlapping, the explicit handling strategy is documented.

3. **Answer Step 3 — Operation / Additivity + Closure**

   - Ask: What aggregation function will be applied?
   - Classify the measure: additive (SUM safe across all dimensions), semi-additive
     (SUM safe across some dimensions, not time), or non-additive (ratio, average,
     percentage, COUNT DISTINCT)?
   - For non-additive measures: How will the measure be decomposed? State: "This
     measure will be stored as SUM([numerator]) and COUNT([denominator]). The ratio
     will be computed at [query tier / dashboard render time]."
   - Check closure: Is the result of the aggregation a valid, interpretable value in
     the original domain? Would the result be meaningful to a domain expert?
   - Completion criteria: The aggregation function is named. The additivity class is
     stated. Non-additive measures have a documented decomposition strategy. Closure
     is confirmed.

4. **Answer Step 4 — Bounds / Scope**

   - Ask: What is the explicit time range for this aggregation?
   - Ask: What are the explicit dimensional constraints (region, business unit, product
     line, customer segment)?
   - Document both: "This metric covers [time range] for [dimensional scope]."
   - Check for implicit filters: Are there hardcoded dates in the query? Are there
     upstream pipeline filters that silently constrain the scope? Is the scope visible
     to the metric's consumer?
   - Completion criteria: A complete metric definition exists: "This metric measures
     [what] over [explicit time range] for [explicit dimensional scope] with \[any
     documented filters\]." This definition must be visible alongside the metric in
     any production consumer.

**After all four steps are complete**: Write the aggregation. Every structural decision
is now explicit. Then apply six-aggregation-properties as the final validation gate
before shipping to production.

______________________________________________________________________

## B — Boundary ★

### This Is a DESIGN Workflow — Use It Before Writing Code

The four steps must be completed before any SQL, pipeline code, or dashboard metric
configuration is written. Using the workflow retroactively (after a metric is built
and wrong) converts it from a design procedure to a diagnostic tool — which is valid,
but less efficient. If applied retroactively, work through each step and identify which
step was not answered, or was answered incorrectly — the failed step is the root cause
of the incorrect metric.

### When NOT to Use This Skill

- **After an aggregation is already designed and needs validation before shipping**:
  Use six-aggregation-properties. That skill is the post-design validation gate; this
  skill is the pre-design specification procedure.
- **When the question is purely syntactic** (e.g., "how do I write a window function
  in BigQuery?"): This skill addresses structural design, not syntax.
- **When grain is genuinely undefined**: If the team has no answer to Step 1, stop
  and apply grain-decision-four-questions before returning here. Attempting to proceed
  through Steps 2–4 without a settled grain produces a specification built on an
  undefined foundation.

### Specific Failure Modes When Each Step Is Skipped

| Step Skipped          | Failure Mode                            | Observable Symptom                                                                                  |
| --------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Step 1 — Grain        | Fan-out from mixed-grain JOIN           | COUNT(*) of result exceeds COUNT(*) of finer-grain source; impossible numbers after JOIN            |
| Step 2 — Disjointness | Double-counting from overlapping groups | Category/tag totals exceed company total; COUNT without DISTINCT on non-disjoint groups             |
| Step 3 — Operation    | AVG of AVGs; non-additive rollup        | Company-wide average differs from true average; metric changes value depending on rollup path       |
| Step 4 — Bounds       | Undeclared or stale scope               | "Total Revenue" with no time range; hardcoded historical date; metric not comparable across periods |

### The Sequence Is the Insight

A practitioner who knows all four steps individually — grain, disjointness, additivity,
bounds — will still produce incorrect aggregations if they execute the steps out of
order or implicitly. The specific value of this workflow is the enforced sequence: each
step constrains the choices available in the next step. A model that cannot pass Step 1
cannot have its Step 2 disjointness evaluated. A Step 2 that produces overlapping groups
constrains which Step 3 functions are valid. A Step 3 that identifies a non-additive
measure constrains Step 4 to require explicit period-locking (because non-additive
measures particularly cannot be accumulated unboundedly). The sequence is not arbitrary
ordering; it is logical dependency.

### Author's Counter-Examples Relevant to This Workflow

- ce03: Average-of-averages (retail AOV) — Step 3 skipped: measure was non-additive
  but treated as additive in the rollup. The fix (SUM + COUNT separately) is the
  correct Step 3 answer.
- ce04: Smartwatch category revenue — Step 2 skipped: groups were not checked for
  disjointness before GROUP BY was written.
- ce05: Pre-aggregation without drill-down path — Step 1 and Step 4 interaction: the
  grain of the summary table was set at a coarser level than stakeholders later
  required, and the atomic data was discarded. The workflow would have forced Step 1
  to declare grain explicitly before building the summary table.

### Relationship to Simpson's Paradox and the Denominator Problem

The book names two additional failure modes relevant to Step 3 design:

- **Simpson's Paradox** occurs when a trend visible in sub-groups reverses when
  groups are combined. This is a Step 2 + Step 3 interaction: the grouping strategy
  conceals a confounding variable that reverses the aggregate result. Detection
  requires checking whether sub-group trends are consistent with the aggregate before
  reporting.
- **The Denominator Problem** requires careful tracking of what is in the denominator
  of any ratio metric, especially when filters are applied. Step 3 must specify
  the denominator explicitly: "COUNT of all tickets in scope" or "COUNT of tickets
  where [condition]"? A filter that changes the denominator but not the numerator
  produces a ratio that does not measure what it is labeled as measuring.

### Author's Blind Spots / Limitations

- **Non-tabular aggregations**: The four steps apply universally — to SQL GROUP BY,
  to dashboard metrics, to ML feature engineering, to graph aggregations, to streaming
  window aggregations. The workflow does not, however, provide specific guidance on
  streaming window type selection (tumbling vs. sliding vs. session) — that requires
  additional streaming-specific knowledge not fully covered in this chapter.
- **Probabilistic and approximation aggregations**: At scale, COUNT(DISTINCT) (Step 3)
  may require a probabilistic data structure (HyperLogLog). The workflow correctly
  identifies COUNT(DISTINCT) as non-additive, but does not prescribe when approximate
  counting is acceptable. That decision requires a separate stakeholder agreement on
  error tolerance.
- **AI-generated aggregations**: The chapter notes that AI systems perform implicit
  aggregation through learned parameters. The four-step workflow applies to explicit
  human-designed aggregations. For AI-generated metrics, the workflow should be used
  to specify the intended aggregation, which is then passed to the AI system as a
  constraint — not derived from the AI system's output.

______________________________________________________________________

## Related Skills

- **depends-on** [`grain-decision-four-questions`](../grain-decision-four-questions/SKILL.md): Step 1 of this workflow requires grain to be declared; if the grain is not yet settled, grain-decision-four-questions must be applied before this workflow can begin.
- **composes-with** [`six-aggregation-properties`](../six-aggregation-properties/SKILL.md): This workflow designs the aggregation; the six-property checklist then validates the result before production deployment — the two skills run in sequence on every aggregation.
- **composes-with** [`decompose-averages-sum-count`](../decompose-averages-sum-count/SKILL.md): When Step 3 of this workflow identifies a non-additive (ratio or average) measure, the decompose rule prescribes exactly how to store it as SUM and COUNT rather than a pre-divided float.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f11 (framework extractor) + p22 (principle extractor) — merged at Phase 1.5
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03
