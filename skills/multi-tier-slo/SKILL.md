---
name: multi-tier-slo
description: |
  Use this skill when a single SLO target for a service is insufficient — either because
  different consumer groups have different requirements, different request types have
  different tolerance, or a monthly SLO allows an incident concentration that consumers
  would find unacceptable.

  **When to call:**
  - A service needs to express different reliability commitments for different request types
    (e.g. query vs. mutation vs. subscription in a GraphQL API)
  - A single monthly SLO would permit a 3-day outage that technically "meets" the budget
    while infuriating consumers
  - You want to cap the maximum allowable incident duration without lowering the monthly
    SLO target
  - There is an aspirational performance target AND a guarantee threshold that must coexist
    (e.g. "we aim for 200ms but we guarantee 850ms")
  - An SLO needs to constrain both frequency and duration of incidents simultaneously
tags: [slo, multi-tiered, window-slo, threshold-tiers, incident-duration, sli, error-budget]
---

# Multi-Tiered SLO Design (Threshold Tiers + Window Tiers)

## R — Original Text (Reading)

> Multi-tier SLOs don't require a parameterized SLI. You can also parameterize the SLO to
> have more control over the objective. A useful example is the window.
>
> For example, if the SLI is uptime, a SLO of 99%, allows for 7 hours and 14 minutes of
> downtime. This error budget can be consumed in one chunk or multiple smaller downtimes.
> Obviously the longer the outage, the more annoying it will be for the consumers. But
> there's nothing in the SLI formula to optimize the distribution of the error budget.
>
> Parameterizing the window allows us to have some control over the incident frequency and
> length.
>
> 99% uptime, translates to an error budget of: 14m 24s downtime per day, 1h 40m 48s
> downtime per week, 7h 14m 41s downtime per month.
>
> Depending on what the business and consumers can tolerate, we can define a multi-tier SLO
> that has the month and week or day (or all 3 of them).

— Alex Ewerlöf, 20231120_211502_multi-tiered-slos.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

A single SLO applied over a single time window creates a mathematical problem: all the
budget can be burned in one extended incident and the SLO is technically met while consumers
experience a catastrophic, sustained failure.

Multi-tiered SLOs fix this by adding dimensions to the reliability commitment. There are
two distinct types of tiering:

**Type 1 — Threshold Tiers** (parameterizing the SLI threshold)

The same SLI is measured against multiple performance thresholds simultaneously. This is
appropriate when you want both an aspirational optimization target and a firm guarantee
threshold, or when different quality levels carry different consequences.

Example: A latency SLI with two tiers:

- 90% of requests must respond in under 400ms (aspirational, optimization target)
- 99% of requests must respond in under 850ms (guarantee, based on client timeout)

Breaching the 850ms tier is more serious than breaching the 400ms tier. Each tier can have
its own alert severity. The tiers overlap — if 90% are under 400ms, certainly more than 99%
are under 850ms — but violating the higher threshold means near-universal consumer impact.

**Type 2 — Window Tiers** (parameterizing the SLO compliance window)

The same SLI threshold is measured over multiple time windows simultaneously. This is the
fix for the "technically-met but consumer-furious" problem.

Example: Uptime SLO at 99%, applied across three windows:

- 99% over 30 days (monthly budget: 7h 14m 41s total downtime)
- 99% over 7 days (weekly budget: 1h 40m 48s per week)
- 99% over 1 day (daily budget: 14m 24s per day)

These are three separate SLOs, each independently breachable. If all three are met, the
service has not been down more than ~14 minutes in any single day, which prevents the
scenario where the entire monthly budget is consumed in one multi-day incident.

**Complexity cost:** Multi-tiered SLOs require multiple alert rules (one per tier), more
sophisticated dashboards, and consumer communication of multiple commitments. Adopt tiering
when the cost of the added complexity is justified by the consumer tolerance problem being
solved — when the "technically-met SLO but furious consumers" scenario is a real risk.

**The lagom principle applies here too:** Do not add tiers speculatively. Each tier must
be grounded in a real consumer requirement or a real business constraint. Adding tiers
without that grounding produces alert noise and dashboard complexity without reliability
benefit.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: GraphQL Endpoint — Query Segmentation by Operation Type

- **Problem:** A GraphQL endpoint serves queries, mutations, and subscriptions with
  fundamentally different response time characteristics and consumer expectations.
- **Application:** Rather than one latency SLO for the entire endpoint, the team defined
  threshold tiers by operation type: 99.5% of queries under 150ms; 90% of mutations under
  400ms; 95% of subscriptions under 100ms.
- **Conclusion:** This is Type 1 tiering (threshold tiers) applied by segmenting the SLI
  by request type. Each tier has a different objective because each operation type has
  different consumer expectations and consequences.
- **Result:** Enables the team to optimize and alert per operation type rather than against
  an averaged metric that would mask degradations in one category while another performs well.

### Case 2: Latency with Two Thresholds — Aspiration + Guarantee (From the Book)

- **Problem:** A service has a client-side timeout of 850ms. The team also wants to optimize
  toward a 400ms response time as a performance goal.
- **Application:** Two simultaneous SLOs on the same latency SLI: 90% of requests under
  400ms (aspirational/optimization), and 99% of requests under 850ms (guarantee/alert-worthy).
- **Conclusion:** This is the Google SLO document example. The 850ms tier protects consumers
  from actual failures; the 400ms tier drives engineering improvement without triggering
  high-severity alerts.
- **Result:** Alert severity can be differentiated: breaching 850ms is P1 (consumer impact);
  breaching 400ms is P3 (performance degradation warning). Teams can optimize proactively
  without over-alerting on the aspirational target.

### Case 3: Window Tiers Preventing Monthly Budget Burndown in One Incident

- **Problem:** A 99% monthly SLO allows 7h 14m of downtime. Without window tiers, this can
  be consumed in a single 3-day outage that technically meets the SLO.
- **Application:** Three simultaneous SLOs: 99% monthly, 99% weekly (1h 40m cap per week),
  99% daily (14m 24s cap per day). The monthly SLO alone would permit a catastrophic single
  incident; the daily and weekly SLOs prevent it.
- **Conclusion:** Window tiering constrains incident duration without lowering the monthly
  commitment. A 3-day outage would breach the daily and weekly SLOs even if it left the
  monthly SLO intact.
- **Result:** Consumers are protected from sustained outages. The team must respond to the
  daily SLO breach quickly rather than waiting for the monthly budget to be exhausted.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A team's post-incident review reveals that their SLO was technically met for the month
   but they had a 72-hour degradation that caused significant consumer complaints and
   potential churn. They want to prevent this from being "acceptable" under the SLO framework.

2. A service team is setting up SLOs for a new API that serves different operation types
   (reads vs. writes, premium vs. free, synchronous vs. background). A single latency
   or availability target does not capture the different tolerance levels for each type.

3. An engineering manager wants to set an optimization target (aspirational) alongside a
   firm consumer guarantee, and needs to know how to express both as formal SLOs without
   creating alert fatigue or conflating the two levels.

### Language Signals (Activate When These Appear)

- "We met our SLO but had a [long] outage that consumers hated"
- "We want to aim for X but guarantee Y"
- "Our SLO allows too much downtime in a single incident"
- "Different parts of our API have different requirements"
- "We need to cap how long any single outage can last"
- "The monthly budget doesn't prevent a 3-day outage"

### Distinguishing from Adjacent Skills

- Difference from `composite-slo`: `composite-slo` calculates the SLO of a system as a
  combination of its dependencies. `multi-tier-slo` designs multiple SLO targets for the
  *same* service. They address orthogonal questions and often need to be applied together.
- Difference from `slo-definition-calibration-framework`: `slo-definition-calibration-framework` determines *what* the SLO target should be
  (calibration to consumer tolerance and cost). `multi-tier-slo` determines *how many*
  SLO targets are needed and at what thresholds/windows. Use `slo-definition-calibration-framework` first to set
  each individual tier value; use `multi-tier-slo` to decide whether multiple tiers are
  warranted.
- Difference from `sli-formula-measurement`: `sli-formula-measurement` designs the SLI
  formula (what counts as good/valid). `multi-tier-slo` applies multiple targets to that
  formula. They stack — you need a well-designed SLI before applying tiered SLOs.

______________________________________________________________________

## E — Execution Steps

1. **Identify the specific problem that single-tier SLO fails to solve**

   - Option A: Consumers have different tolerance for different request types → threshold
     tiering by request type
   - Option B: There is both an aspirational target and a firm guarantee → threshold tiering
     by performance level
   - Option C: A single compliance window allows incident concentration that consumers would
     not accept → window tiering
   - Completion criteria: You can state which problem (A, B, or C) is being solved.

2. **For threshold tiers: segment by the dimension that matters**

   - Identify the parameterizable dimension: request type, user tier, endpoint, operation
     type, or performance threshold
   - For each tier, determine the appropriate target value using `slo-definition-calibration-framework` principles
     (consumer tolerance + cost)
   - Define which tiers trigger which severity of alert
   - Completion criteria: Each tier has a threshold, a target percentage, and an alert
     severity.

3. **For window tiers: derive the per-window budgets**

   - Start from the monthly SLO (e.g. 99% = 7h 14m error budget per month)
   - Calculate the proportional weekly budget (1h 40m) and daily budget (14m 24s)
   - Ask: What is the maximum single-incident duration consumers can tolerate? Use that
     to select which windows to include (monthly + weekly, or all three)
   - Completion criteria: Window budgets are calculated and the maximum-incident-duration
     constraint is satisfied.

4. **Define independent alert rules for each tier**

   - Each tier is a separate SLO and must have its own alert. Do not collapse them into one.
   - Higher-threshold tiers (the guarantee) should trigger higher-severity alerts.
   - Shorter-window tiers (daily) should trigger faster response requirements.
   - Completion criteria: Alert rules are defined per tier with differentiated severity.

5. **Communicate the multi-tier structure to consumers**

   - If tiers represent different consumer-facing commitments (e.g. by user tier or operation
     type), communicate them to consumers explicitly
   - If tiers are internal (window tiers), consumers see the combined effect as "we don't
     have long outages" without needing to understand the mechanism
   - Completion criteria: Consumers and internal stakeholders understand what each tier
     means and which tier is the firm guarantee.

6. **Validate complexity is justified**

   - Multi-tier SLOs require more dashboard complexity and more alert maintenance
   - If the same result can be achieved by a single tighter SLO or by `composite-slo`
     calculation, prefer the simpler approach
   - Completion criteria: You have verified that each tier addresses a real consumer or
     business requirement that a single-tier SLO cannot address.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- You are setting a single SLO for the first time — use `slo-definition-calibration-framework` to calibrate the right
  target value before deciding whether multiple tiers are needed.
- The service has only one homogeneous request type and one consumer group with one tolerance
  level — a single SLO is sufficient.
- The complexity of managing multiple alert rules and dashboards outweighs the consumer
  protection benefit. More tiers = more maintenance. Only add tiers that solve real problems.

### Failure Patterns Warned by the Author

- **Alert fatigue from over-tiering**: Adding aspirational tiers that fire alerts without
  clear consumer impact trains on-call engineers to ignore them. Breaching an aspirational
  tier should generate a ticket, not a page.
- **Tiers without differentiated alert severity**: If all tiers trigger the same severity
  alert, the structure provides no benefit over a single alert — it only multiplies noise.
- **Window tiers without per-window budgets being communicated**: Teams sometimes add daily
  SLOs without calculating whether the derived daily budget is achievable given their actual
  incident history. A 14-minute daily budget is aggressive; validate before committing.

### Author's Blind Spots / Limitations

- The framework is calibrated for request-driven services with measurable response times
  or uptime. Applying window tiers to data pipeline SLOs (freshness, completeness) or
  batch job SLOs requires careful translation — "daily budget" may not map to a fixed
  14-minute window in a pipeline context.
- The author does not provide guidance on how many tiers is too many. The examples show
  2–3 tiers; beyond that, the complexity cost likely exceeds the benefit, but this is
  stated as intuition rather than a derived limit.

### Easily Confused With

- **Composite SLO**: Composite SLO calculates the reliability of the *whole* from the
  *parts*. Multi-tier SLO expresses multiple reliability commitments for the *same*
  service at different levels. A service can have both a multi-tiered SLO and participate
  in a composite SLO calculation — they are orthogonal.
- **Alerting burn rate (multi-window alerting)**: Google's alerting-on-SLO framework uses
  multiple burn rate windows to generate fast- and slow-burn alerts. Window tiers in this
  skill serve a similar structural purpose but the intent is to express different *consumer
  commitments*, not just to improve alerting sensitivity.

______________________________________________________________________

## Related Skills

- **depends-on** → `slo-definition-calibration-framework`: Use slo-definition-calibration-framework to calibrate each individual tier value (threshold and window) to consumer tolerance and cost before deciding whether multiple tiers are warranted.
- **contrasts-with** → `composite-slo`: Composite-slo combines SLOs from different services in a dependency graph; multi-tier-slo applies multiple targets to the same service. They solve different SLO complexity problems and are often applied together.
- **composes-with** → `sli-formula-measurement`: A well-designed SLI formula (good/valid) must exist before applying multi-tier thresholds or window structures to it.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Reliability Engineering Mindset" by Alex Ewerlöf
