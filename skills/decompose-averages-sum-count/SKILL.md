---
name: decompose-averages-sum-count
description: |
  Use this skill when a user is computing any ratio metric (average, rate, percentage)
  by rolling up pre-computed segment or group averages rather than recomputing from
  atomic data — or when designing a pipeline that will need to aggregate such metrics
  across tiers.

  Trigger signals:
  - "We're averaging our store/segment/cohort averages to get the company total"
  - "The company-wide conversion rate doesn't match what I'd expect from the segments"
  - "We compute NPS per region, then average the regions for a global NPS"
  - "Our AOV rollup looks higher than the raw transaction data suggests"
  - Any mention of "average of averages", "weighted average", "rolling up averages"
  - Any ratio metric (conversion rate, return rate, session duration, error rate)
    being rolled up from a pre-aggregated summary table

  Do NOT use this skill when:
  - The metric is additive (SUM of revenue, COUNT of orders) — additive measures roll
    up correctly without decomposition
  - All groups being averaged have identical sizes — the single exception where
    averaging averages produces a correct result (see B section)
  - The question is about aggregation structural properties in general (use
    six-aggregation-properties instead)

  Based on: "Practical Data Modeling" by Joe Reis (2026), Ch. 9 — Counting and
  Aggregation.
source_book: "Practical Data Modeling" by Joe Reis
source_chapter: Ch. 9 — Counting and Aggregation — Controlling the Grain
tags: [aggregation, averages, decomposability, ratio-metrics, pipeline-design]
related_skills:
  - slug: six-aggregation-properties
    relation: depends-on
---

# Never Aggregate Pre-Computed Averages — Decompose into SUM + COUNT

## R — Original Text (Reading)

> **The Average of Averages Trap**
>
> Here's a classic aggregation mistake that trips up even experienced analysts. A
> retail analytics team wants to compute the company-wide average order value (AOV).
> They calculate AOV for each store separately:
>
> | Store   | Orders | AOV |
> | ------- | ------ | --- |
> | Store A | 100    | $45 |
> | Store B | 10     | $75 |
> | Store C | 5      | $80 |
>
> The team averages these three numbers: ($45 + $75 + $80) / 3 = **$66.67**.
>
> But the true company-wide AOV, computed from all 115 individual orders, is
> **$49.13**. Why? Stores B and C, with their handful of high-value orders, have an
> outsized influence on the store-level averages. When you average those averages,
> small stores with a few big orders pull the overall metric upward. You've implicitly
> given Store C (5 orders) the same weight as Store A (100 orders). That's
> mathematically wrong.
>
> This is a decomposability violation. AVERAGE is not associative. You cannot safely
> aggregate pre-computed averages into a global average.
>
> The fix: never aggregate from pre-computed averages. Decompose the average into its
> components — SUM and COUNT — track them separately, and compute the final average
> only at the end. Here, the total sum divided by the total count is $5,650 / 115 =
> **$49.13**. This is why distributed systems like Spark and BigQuery decompose
> averages during aggregation: they preserve correctness across partitions.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 9

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The core principle is mathematical: AVERAGE is not associative. SUM and COUNT are.

Associativity means: `(a + b) + c = a + (b + c)` — you can group partial results and
combine them without changing the answer. This is why SUM and COUNT are safe to
decompose across partitions, pipeline tiers, or pre-aggregated tables: add the partial
sums, add the partial counts, and the result equals what you would have gotten by
computing over all records at once.

AVERAGE does not have this property. `AVG(AVG(a, b), AVG(c))` does not equal
`AVG(a, b, c)` unless all groups have the same count. When group sizes differ, the
naive average of averages gives equal weight to small groups and large groups — which
is a claim about reality that is almost always false.

**The fix is a pipeline design rule, not a query fix.** This is the critical
architectural implication. If a summary table stores only pre-computed `avg_order_value`
per store, there is no way to compute the correct company-wide AOV from that table — the
component parts (SUM and COUNT) are gone. A query-level correction that re-calculates
from the summary table is mathematically impossible. The only correct fix requires either
storing `sum_order_value` and `order_count` alongside the average in every summary table,
or returning to the atomic transaction data to recompute.

This means the decision point is at pipeline design time, not query time. Every summary
table that will be aggregated further must carry SUM and COUNT — not just the pre-divided
average — through every tier. The final division (SUM / COUNT = average) is performed
only at the last step, at the consumer that needs to display the number.

**The Air Force cockpit principle** extends the insight: it is not just that the
aggregate number is "wrong" in some abstract sense. The aggregate may correspond to no
real instance in the dataset. Zero of 4,000 pilots fit the "average" cockpit designed
around averaged measurements. A company-wide AOV of $66.67 may not correspond to any
store's actual average. When an aggregate is the result of averaging pre-computed averages
with unequal group sizes, the resulting number is a mathematical artifact — not a
description of any real unit in the data.

**This applies to any ratio metric:**

- Average order value (AOV): SUM(order_value) / COUNT(orders)
- Conversion rate: SUM(conversions) / COUNT(sessions)
- NPS: SUM(promoters - detractors) / COUNT(respondents)
- Average session duration: SUM(session_seconds) / COUNT(sessions)
- Error rate: SUM(errors) / COUNT(requests)
- Return rate: SUM(returns) / COUNT(orders)

Each must be stored as numerator + denominator, not as a pre-divided float, in any
summary table that will itself be aggregated.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Retail AOV — the Numerical Gap (Ce03 / Ch. 9)

- **Setup**: A retail company has three stores. The analytics team pre-computes AOV per
  store: Store A ($45, 100 orders), Store B ($75, 10 orders), Store C ($80, 5 orders).
  To produce the company-wide AOV, an analyst runs `AVG(avg_order_value)` over the
  store summary table.

- **The wrong answer**: ($45 + $75 + $80) / 3 = **$66.67**

- **The correct answer**: SUM of all order values / COUNT of all orders =
  $5,650 / 115 = **$49.13**

- **The gap**: $66.67 vs. $49.13 — a **26% inflation** from the naive calculation.
  The inflation occurs because Store C (5 orders, $80 AOV) is given the same weight
  as Store A (100 orders, $45 AOV). The company's order volume is dominated by
  Store A's low-value orders, but the average-of-averages approach makes Store A's
  experience equivalent to Store C's.

- **What the pipeline stored wrong**: The summary table stored only `avg_order_value`.
  SUM and COUNT were discarded as "redundant" since the average was already computed.
  The fix requires adding `sum_order_value` and `order_count` columns to every summary
  table tier. The final AOV display query computes `SUM(sum_order_value) / SUM(order_count)`.

- **Why the wrong number looks plausible**: $66.67 is a number in the expected range.
  It does not trigger an error. It is returned without warning by any standard BI tool
  or SQL query that runs `AVG(avg_order_value)`. The error is invisible until someone
  independently recomputes from the atomic order table and finds the discrepancy.

### Case 2: the Air Force Cockpit — the Aggregate Corresponds to No Real Instance

- **Setup**: In the 1950s, the U.S. Air Force designed cockpits around the "average
  pilot" — averaged measurements of arm length, torso height, leg reach, and seven
  other dimensions — taken from over 4,000 airmen. The assumption: build for the
  mean, and most pilots will fit.

- **What researcher Lt. Gilbert S. Daniels found**: Zero of the 4,000 pilots measured
  fell within the average range on all ten dimensions simultaneously. The cockpit built
  for the "average pilot" fit nobody.

- **The data modeling principle this illustrates**: The average is not merely an
  approximation — it can be a value that does not correspond to any real instance in
  the dataset. When groups are aggregated across multiple independent dimensions, the
  probability that any individual matches the combined average on all dimensions drops
  toward zero as the number of dimensions grows.

- **Why this matters for data modeling**: When a company-wide AOV of $66.67 appears
  in a dashboard but no store actually has that AOV, the metric is not a description
  of business reality. Decisions made from the metric — pricing changes, bonus
  structures, inventory targets — are made against a number that corresponds to no
  actual store. The Air Force fixed this by designing for variability (adjustable
  seats, pedals, harnesses) rather than the mean. The data modeling equivalent: store
  the distribution (SUM + COUNT, or percentiles at atomic grain) rather than discarding
  it into a single mean.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

A product team reports weekly "average session duration" per feature by taking the
mean of daily average session durations for each feature. A VP questions why the
company-wide average looks higher than the median session time in the raw logs.

**What this is**: A decomposability violation. The team is computing AVG(daily average
session duration) — an average of averages. On low-traffic days, a few long sessions
produce a high daily average that receives equal weight to a high-traffic day with
thousands of sessions. The weekly average is inflated.

**The correct pipeline**:

1. Store `daily_sum_session_seconds` and `daily_session_count` per feature per day.
2. Weekly average = `SUM(daily_sum_session_seconds) / SUM(daily_session_count)` for
   the 7-day window.
3. Never divide until the final consumer display step.

### Language Signals That Activate This Skill

- "We're averaging our store/segment/cohort averages to get the company total"
- "The company-wide conversion rate doesn't match what I'd expect from the segments"
- "We compute NPS per region, then average the regions"
- "Our error rate rollup from the service summary seems off"
- "We have a weekly average that we roll up into a monthly average"
- Any mention of "average of averages", "weighted average", "rolling up averages"
- Any ratio metric (conversion rate, return rate, AOV, session duration, error rate,
  NPS) being derived from a pre-aggregated summary table

### The Five Metric Categories Where This Applies

1. **Volume-weighted averages**: AOV, average session duration, average handle time,
   average ticket value. The denominator is count of events; different segments have
   different event counts.

2. **Rate metrics**: Conversion rate (conversions / sessions), error rate (errors /
   requests), return rate (returns / orders). Rates must carry both numerator and
   denominator SUM, not a pre-divided float.

3. **Score-based metrics**: NPS (promoters minus detractors, divided by total
   respondents), CSAT score. Both the net score SUM and the COUNT of respondents
   must be preserved.

4. **Time-averaged metrics**: Daily averages rolled into weekly averages rolled into
   monthly averages. Traffic-day volume varies; equal-weight averaging of unequal
   time periods is a decomposability violation.

5. **Multi-tier rollups**: Segment → Region → Country → Global. At every tier where
   the aggregation is an average, the SUM and COUNT must pass through. The division
   happens only at the tier where the average is displayed.

### Distinguishing from Adjacent Skills

- Difference from `six-aggregation-properties`: Six-aggregation-properties covers all
  six structural properties of safe aggregation (grain, disjointness, additivity,
  decomposability, closure, boundedness). This skill is a deep-dive into the single
  most common decomposability failure: AVERAGE is not associative. Use this skill when
  the specific problem is an average being rolled up from pre-computed averages; use
  six-aggregation-properties for a broader review of an aggregation's structural
  correctness.

- Difference from `aggregation-workflow-four-steps`: That workflow is the sequenced
  design procedure (grain → group → operation → bounds). This skill is applied to
  Step 3 (operation selection) specifically for the case where the operation is an
  average and the source is a pre-aggregated table.

______________________________________________________________________

## E — Execution Steps

Once activated, apply this procedure to any ratio metric in a pipeline.

1. **Identify every ratio metric in scope**

   - A ratio metric is any metric that requires division: AOV, conversion rate,
     error rate, NPS, average session duration, return rate, any percentage.
   - List each one. For each, identify: numerator (what is being summed?) and
     denominator (what is being counted?).
   - Completion criteria: A written list of ratio metrics with explicit numerator
     and denominator labeled for each.

2. **Trace the pipeline tiers for each metric**

   - Map the data flow from atomic source to final display:
     atomic events → daily summary → weekly rollup → regional rollup → dashboard.
   - Identify every tier where a pre-computed average exists (i.e., where division
     has already occurred before the final display tier).
   - Completion criteria: A pipeline diagram or table showing at which tier(s) the
     division currently happens.

3. **Apply the decomposition rule to each tier**

   - For every summary table that will be further aggregated, remove the pre-divided
     average column and replace it (or supplement it) with:
     - `sum_<metric_numerator>` — the additive SUM
     - `count_<metric_denominator>` — the additive COUNT
   - Example: Replace `avg_order_value FLOAT` with `sum_order_value DECIMAL` and
     `order_count INT` in every intermediate summary table.
   - The final display query (the only place where the average is shown to a human)
     computes: `SUM(sum_order_value) / SUM(order_count)`.
   - Completion criteria: No intermediate pipeline tier stores a pre-divided average
     for any metric that will be further aggregated. Division is performed only at
     the display layer.

4. **Verify the fix with a numerical check**

   - Run the corrected calculation from atomic data and compare to the pre-fix
     average-of-averages result.
   - If the two numbers diverge: the pre-fix number was wrong and the fix is correct.
     Document the delta for stakeholders.
   - If the two numbers are identical: the groups happened to have equal sizes (the
     one safe exception — see B section). The fix is still correct and has no
     downside.
   - Completion criteria: The numerically correct value is confirmed from atomic data
     and the pipeline now produces that value at every tier.

5. **Document the metric definition**

   - For each ratio metric, write the definition in the metric catalog or schema
     documentation: "AOV = SUM(order_value) / COUNT(orders). Never computed by
     averaging pre-computed store AOV values."
   - This prevents future developers from reverting to the average-of-averages pattern.
   - Completion criteria: Every affected metric has a written definition that specifies
     numerator, denominator, and the tier at which division is performed.

**The governing rule**: SUM and COUNT are associative — carry them everywhere. AVERAGE
is not associative — compute it nowhere except the final display step.

______________________________________________________________________

## B — Boundary ★

### When Averaging Averages IS Acceptable

There is exactly one condition under which averaging pre-computed averages produces a
correct result: **all groups have identical sizes.** If every store had exactly the same
number of orders, giving each store equal weight would be mathematically equivalent to
computing the true population average. In practice, equal group sizes are rare and
should never be assumed — the safe universal rule is to always carry SUM and COUNT.

Even when group sizes happen to be equal today, they may not be equal next month after
business growth. The correct pipeline design carries SUM and COUNT regardless, so that
correctness does not depend on an assumption about group size that could silently
become false.

### This Skill Addresses the Data Model and Pipeline — Not the Downstream Query

A query-level fix that recalculates the correct company-wide average by joining back to
the atomic data solves the display problem for one report, but leaves every other
consumer of the summary table — every other dashboard, every downstream ML feature
pipeline, every automated report — still reading the wrong pre-computed average.

The fix must be applied where the data is stored. Every summary table that will be
further aggregated must carry SUM and COUNT. A query-level workaround is not a fix;
it is a patch that creates two different answers to the same question depending on
which consumer is used.

### Do Not Use This Skill for Additive Measures

SUM and COUNT do not need decomposition — they are already the additive components.
`SUM(total_revenue)` across stores correctly produces company-wide revenue; each store's
contribution is already weighted by its actual transaction volume. This skill applies
only to non-additive ratio metrics where pre-computed averages are being further
aggregated. If the metric in question is a raw sum or count, standard aggregation
is correct and this skill does not apply.

### Failure Patterns Warned About by the Author

- **Implicit equal-weight assumption** (ce03): The most common manifestation. An analyst
  runs `AVG(avg_order_value)` on a store summary table without checking whether stores
  have different order volumes. Most BI tools will execute this query without warning.
  The result is silently wrong when group sizes differ. Warning sign: the query source
  is a pre-aggregated table, the metric is a ratio, and the query does not weight by
  a count column.

- **Multi-tier average propagation**: A daily average is stored in a daily summary
  table. A weekly summary table computes `AVG(daily_avg)` over the 7 daily rows. A
  monthly summary computes `AVG(weekly_avg)` over 4 or 5 weekly rows. The error
  compounds at each tier. By the time the monthly number reaches a dashboard, it may
  be far from the true value with no visible indication of the distortion. Warning sign:
  a pipeline with more than two summary tiers where each tier stores only the average,
  not the component SUM and COUNT.

- **Plausibility masking**: The wrong number is in the expected range. $66.67 is not
  obviously wrong for a company with stores averaging $45–$80 per order. A conversion
  rate of 3.2% (wrong) is not obviously different from 2.8% (right) without an
  independent calculation. The error does not announce itself. Warning sign: no
  independent recomputation from atomic data has been performed to validate the
  summary table value.

### Author's Blind Spots / Limitations of the Era

- **Approximation approaches not covered**: For very large datasets, exact SUM and
  COUNT at atomic grain may have cost or latency constraints. Reis mentions HyperLogLog
  for COUNT(DISTINCT) approximations and T-Digest for percentiles in Ch. 9, but does
  not provide a prescriptive framework for when approximation is acceptable for ratio
  metric rollups. The SUM + COUNT decomposition rule is the exact solution; the
  practitioner must apply judgment about when an approximation approach is acceptable
  for a given use case.

- **Streaming aggregation mechanics deferred**: The same decomposability principle
  applies to windowed aggregations in streaming systems, but Reis notes that streaming
  grain and aggregation get dedicated treatment in volume 2. The SUM + COUNT rule is
  correct in principle for streaming, but the implementation mechanics (state
  management, watermarks, late-arriving events) are not covered here.

### Easily Confused Adjacent Approaches

- **Weighted average as a manual fix**: Multiplying each group's average by its count
  before summing, then dividing by total count — `SUM(avg_order_value * order_count) / SUM(order_count)` — produces the correct result but requires the count to be
  available in the summary table. This is equivalent to the SUM + COUNT approach when
  `avg * count = sum`. The cleaner prescription is to store SUM directly rather than
  storing `avg` and `count` separately and requiring the consumer to know about the
  weighting correction. Store SUM, not AVG × COUNT.

- **Median and percentiles**: These are non-decomposable in the stronger sense —
  there is no two-component decomposition that allows exact median computation from
  partitioned data. The SUM + COUNT fix does not apply to median. For median and
  percentile rollups, the options are: return to atomic data, use approximation
  algorithms (T-Digest), or accept that the metric cannot be safely rolled up from
  a pre-aggregated summary. This is a harder problem than the average case.

______________________________________________________________________

## Related Skills

- **depends-on** [`six-aggregation-properties`](../six-aggregation-properties/SKILL.md): Properties 3 and 4 of that checklist (Additivity and Decomposability) are the structural justification for this rule — understanding why AVG is non-additive and non-decomposable is the prerequisite for applying the SUM + COUNT fix correctly.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: p20 (principle extractor)
- **Counter-examples used**: ce03 (average-of-averages retail AOV example)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03
