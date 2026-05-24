---
name: sli-compass
description: |
  Use this skill when evaluating the signal quality and cost-efficiency of an existing SLI,
  comparing SLI implementation options, or deciding how to evolve measurement infrastructure.
  The skill answers: "Is this SLI worth what it costs? Is it measuring real consumer experience
  or a proxy? How should we evolve our measurement approach?"

  WHEN TO CALL: (a) A user needs to evaluate whether a synthetic health-check SLI is sufficient
  or whether organic measurement is required; (b) a user is comparing simple endpoint pings vs.
  full user journey monitoring; (c) the SLI is too expensive for the signal quality it provides;
  (d) a user asks "should we invest in RUM (real user monitoring)?"; (e) the SLI fires on noise
  or misses real incidents and you need to diagnose why from the measurement dimension; (f)
  the user wants to plan an SLI investment roadmap from cheap/simple to expensive/high-fidelity.

  WHEN NOT TO CALL: Do not call when the question is about what the SLI should measure (consumer
  tasks, failure modes) — that is `sli-monitoring-design-maturity`. Do not call for questions about
  SLO target levels. Do not call when the question is purely about metric scope and control
  boundaries — that is `responsibility-control-slo`.

  KEY TRIGGER SIGNAL: "Should we use Pingdom or instrument real traffic?", "our synthetic check
  is green but users are failing", "is it worth investing in end-to-end journey monitoring?",
  "how much does real-user monitoring cost compared to what we get?", "our SLI is too noisy."
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20250808_111403_sli-compass.md, 20250827_123438_sli-evolution-stages.md, 20230809_201014_sli-measurement-location.md
tags: [sli, measurement, signal-quality, investment, evolution, fidelity, granularity]
related_skills:
  - slug: sli-monitoring-design-maturity
    relation: depends-on
  - slug: service-level-topology
    relation: composes-with
---

# SLI Compass (Fidelity × Granularity)

## R — Original Text (Reading)

> All SLIs can be mapped in a 2D axis:
>
> - **Fidelity:** how closely does the SLI represent the consumer experience?
> - **Granularity:** how many variables and parameters are aggregated in a single data point?
>
> We can combine these two dimensions to get a powerful but familiar quadrant model.
>
> As a general rule of thumb: the closer to the top-left, the easier and cheaper it is to measure
> the SLI but the lower the quality it has. The more you move to the bottom-right corner of the
> compass, the harder it is to measure and more costly it gets but the quality improves.
>
> Over time, you may want to carefully move your measurement from the top-left to the bottom-right
> corner considering the ROI.
>
> — Alex Ewerlöf, 20250808_111403_sli-compass.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The SLI Compass is a 2D evaluation model that separates two orthogonal quality dimensions of any
SLI implementation:

**Fidelity** (vertical axis: Synthetic → Organic):

- **Synthetic**: artificial/simulated load. A tool pings an endpoint every minute. Easy to
  implement, consistent, works even at low traffic volumes. Does not represent real consumer
  behavior — the probe may show green while actual user journeys fail because the probe only
  tests a trivial path (health endpoint).
- **Organic**: data from real consumer traffic. API gateway logs, RUM (real user monitoring),
  event tracking. Represents exactly what consumers experience. Requires higher traffic volume
  to produce statistically meaningful percentages. Can be expensive to collect and store at
  high traffic scales.

**Granularity** (horizontal axis: Simple → Complex):

- **Simple**: measures one thing. A single endpoint returning 200, one API call's latency below
  a threshold. Acts as a basic proxy for service health. Easy to reason about; easy to debug
  when it fires.
- **Complex**: measures many things simultaneously. A Playwright script traversing a full
  purchase journey. Tells a richer story about consumer experience. Higher maintenance burden;
  can introduce measurement lag (waits for all variables to resolve). Harder to debug — when
  it fires, which step failed?

Combining the two axes produces four quadrants:

|               | Simple                                                  | Complex                                                    |
| ------------- | ------------------------------------------------------- | ---------------------------------------------------------- |
| **Synthetic** | Q1: cheap, low quality (health endpoint ping)           | Q2: medium cost, better proxy (synthetic journey)          |
| **Organic**   | Q3: medium cost, good signal (API gateway per-endpoint) | Q4: high cost, highest quality (RUM with journey tracking) |

**Investment direction**: Start top-left (Q1) to establish a baseline. Evolve toward bottom-right
(Q4) as signal quality requirements and budget allow. The evolution is not linear — you can move
along either axis independently. A team might go Q1 → Q2 (add synthetic journey) before Q1 → Q3
(add organic traffic), or vice versa, depending on traffic volume and maintenance capacity.

**Three use cases for the Compass**:

1. **Evaluation**: given an existing SLI, plot it on the compass — is it in Q1 when Q3 is needed?
2. **Investment**: estimate the ROI of moving from current quadrant to an adjacent one.
3. **Evolution**: plan the incremental path toward higher-signal measurement.

**Connection to measurement location**: The six measurement locations (client app, third-party
synthetic, cloud-provider external, edge, cluster-internal, instance-internal) map to the
Fidelity axis. Measuring from the client (left) is highest fidelity; measuring from inside the
instance (right) is lowest fidelity. Moving the measurement point closer to the consumer improves
fidelity but increases cost and noise.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Availability SLI — Four Quadrant Implementations Compared

- **Problem:** A team asked "how should we measure availability?" The author used the availability
  SLI as a worked example to illustrate all four compass quadrants.
- **Application:**
  - Q1 (Simple + Synthetic): Ping the health endpoint every minute; calculate percentage of
    successful pings. Cheapest. Used by Pingdom, UptimeRobot. Misses all failures that don't
    affect the health endpoint.
  - Q2 (Complex + Synthetic): Use a Playwright script to simulate a critical user flow (e.g.,
    purchase journey); calculate successful execution percentage. Better proxy; higher
    maintenance cost; can miss organic edge cases.
  - Q3 (Simple + Organic): Count minutes where the API endpoint handled valid requests from
    real users. Uses real traffic. Better fidelity than synthetic; requires sufficient organic
    load to avoid statistical instability.
  - Q4 (Complex + Organic): RUM data identifying broken user journeys; calculate successful
    user sessions. Highest quality; most expensive to instrument and store; most accurate
    representation of what consumers experience.
- **Conclusion:** The right quadrant depends on product maturity, traffic volume, and budget.
  New products with low traffic should use Q1 or Q2 (synthetic fills the gap where organic
  data is insufficient). Mature high-traffic consumer products should aim for Q3 or Q4.
- **Result:** Teams can use the compass to defend their current position and plan the
  incremental investment path toward higher signal quality.

### Case 2: Synthetic SLI Masking Consumer Failure

- **Problem:** A team used a Q1 health-endpoint ping as their primary SLI. The endpoint
  consistently returned 200. Users were experiencing failures because the authentication
  service was down and the search index was stale — but neither was exercised by the health
  endpoint probe.
- **Application:** The SLI compass diagnosis: Q1 (simple + synthetic) has low fidelity by
  design. It tests a trivial path. Real consumer failures on non-trivial paths are invisible.
  Incidents were discovered only when user support tickets arrived, by which time the error
  budget had been burning silently.
- **Conclusion:** For this team, the minimum acceptable fidelity required at least Q3 (organic
  traffic data showing real API call success rates) or Q2 (synthetic journey that traversed
  the authentication path).
- **Result:** The team moved to Q3 by adding organic success rate measurement at the API
  gateway, which immediately surfaced the authentication failure pattern that Q1 had been
  hiding.

### Case 3: Low-Traffic Service Requiring Synthetic Fallback

- **Problem:** A service receiving 50 requests per month needed a 99% SLI. With only 50 organic
  events per month, a single failure reduced SLS to 98% — making a 99% SLO mathematically
  impossible to achieve consistently even with an excellent service.
- **Application:** The author recommended using synthetic load (Q1 or Q2) to supplement the
  organic baseline. Synthetic probes add enough denominator events to make the percentage
  statistically meaningful, allowing the SLO to function as intended.
- **Conclusion:** Organic-only measurement at low traffic volumes produces statistically
  unstable SLIs. Synthetic load is not merely a cheaper alternative — it is the correct choice
  when organic load is insufficient.
- **Result:** The team used a synthetic probe running every minute (1,440 probes/month) to
  supplement the 50 organic events, stabilizing the SLI computation and making the SLO target
  achievable.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A user says "we have a Pingdom check on our home page — is that sufficient as our SLI?" —
   this is a Q1 evaluation question: is the fidelity and granularity appropriate for the
   alerting use case?
2. A user asks "should we invest in Playwright-based synthetic monitoring or instrument our
   production API gateway for organic data?" — this is an investment decision between Q2 and
   Q3, requiring ROI comparison.
3. An SLI has been in production for a year, always shows green, but incidents are discovered
   via support tickets — this is a fidelity diagnosis: the SLI is likely Q1 and needs to move
   toward Q3 or Q4.

### Language Signals (Activate When These Appear)

- "We use Pingdom / UptimeRobot / health endpoint as our SLI"
- "Should we invest in real user monitoring?"
- "Our SLI never fires but users complain"
- "How accurate is a synthetic check compared to real traffic?"
- "Is it worth adding full user journey monitoring?"

### Distinguishing from Adjacent Skills

- Difference from `sli-monitoring-design-maturity`: sli-monitoring-design-maturity assesses whether the SLI
  is grounded in consumer tasks and failure modes (what is measured). sli-compass assesses
  how the data is collected — the measurement technology and its accuracy (how it is measured).
  A Stage 3 SLI (task-aware) can still be measured in Q1 (synthetic health check proxy),
  which means the task-awareness may not actually be verified by the measurement. Both
  dimensions must be evaluated for a full SLI quality assessment.
- Difference from `responsibility-control-slo`: responsibility-control-slo determines which
  team owns which metric and how the valid denominator should be scoped. sli-compass
  determines how that metric should be instrumented. They address orthogonal aspects of
  the same SLI.

______________________________________________________________________

## E — Execution Steps

1. **Plot the current SLI on the Fidelity axis**

   - Synthetic indicators: scheduled probe, health endpoint ping, Pingdom/UptimeRobot/Datadog
     synthetic, Playwright script run on a schedule.
   - Organic indicators: API gateway logs, real user traffic percentiles, RUM data, event
     tracking from actual consumer sessions.
   - Mixed: organic data supplemented with synthetic (appropriate for low-traffic services).
   - Completion criteria: Current SLI is labeled Synthetic, Organic, or Mixed on Fidelity axis.

2. **Plot the current SLI on the Granularity axis**

   - Simple indicators: single endpoint, single metric (is this URL returning 200?), single
     API call latency.
   - Complex indicators: multi-step journey, aggregation of multiple endpoints, full user
     session success rate.
   - Completion criteria: Current SLI is labeled Simple or Complex on Granularity axis.

3. **Name the current quadrant**

   - Q1 (Simple + Synthetic), Q2 (Complex + Synthetic), Q3 (Simple + Organic), Q4 (Complex + Organic)
   - Completion criteria: Named quadrant with brief justification.

4. **Evaluate signal quality for the on-call use case**

   - Q1: Appropriate only for early-stage products, low traffic services, or as a baseline
     supplement. Not sufficient as the sole on-call SLI for mature consumer-facing services.
   - Q2: Appropriate when organic traffic is too low for statistical stability, or as a
     complement to Q3 for critical journeys.
   - Q3: Appropriate as the primary SLI for most API-based services with sufficient traffic.
   - Q4: The highest quality option — appropriate for high-revenue consumer journeys where
     the cost of measurement is justified by the cost of missing a failure.
   - Completion criteria: Explicit assessment of whether the current quadrant is sufficient
     for the intended alerting use case.

5. **Design the investment/evolution path if current quadrant is insufficient**

   - Identify the most valuable adjacent quadrant given traffic volume, maintenance budget,
     and urgency.
   - For low-traffic services: move to Q2 (add synthetic journey) before Q3.
   - For high-traffic mature services: move to Q3 (add organic data) before Q4.
   - Estimate the cost delta: Q1 → Q3 typically requires API gateway instrumentation and
     log aggregation. Q1 → Q4 requires RUM implementation and session analysis infrastructure.
   - Stop condition: If the cost of the next quadrant exceeds the expected incident detection
     benefit, stay at current quadrant and accept the signal quality limitation.
   - Completion criteria: Named target quadrant with a brief implementation plan and cost
     estimate.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is about what the SLI should measure (which consumer task, which failure mode)
  — use `sli-monitoring-design-maturity` for that dimension.
- The question is about which team should own the metric or how the valid denominator should
  be scoped — use `responsibility-control-slo`.
- The team has no SLI at all — start with any Q1 SLI to establish a baseline before compass
  evaluation applies.

### Failure Patterns Warned by the Author

- **ce23 (Synthetic SLI Masking Real Consumer Failure)**: The canonical Q1 failure — a
  health endpoint ping shows the service is "up" while real user journeys fail on paths the
  probe doesn't exercise. The compass makes this failure mode visible and provides the upgrade
  path (Q1 → Q3).
- **ce15 (Alert Fatigue from Infrastructure-Metric SLIs)**: Complex metrics that aggregate
  system-internal variables (CPU, memory, connection pools) have low fidelity regardless of
  their granularity — they sit in Q2 but on the wrong axis (complex but synthetic in spirit
  because they measure system proxies, not consumer experience). The compass forces explicit
  classification of whether the complexity reflects consumer journey complexity or just
  technical metric aggregation.

### Author's Blind Spots / Limitations

- **Cost quantification is hand-wavy**: The compass correctly establishes that Q4 is more
  expensive than Q1, but does not provide a methodology for estimating the actual cost
  difference. The "ROI" language in the article is qualitative. Real investment decisions
  require vendor pricing, data storage estimates, and engineering hours for implementation.
- **Assumes consumer identity is knowable**: Moving to Q3 or Q4 requires knowing which
  organic traffic to measure and which user journeys to instrument. For platform APIs with
  heterogeneous consumers, the consumer journeys may be unknown or too diverse to instrument
  comprehensively.
- **Synthetic skewing of product metrics**: The author notes that synthetic load can skew
  MAU (monthly active users) and similar product metrics if synthetic users are not filtered
  out. This operational concern is mentioned but the mitigation approach (tagging/filtering
  synthetic traffic) is not fully developed.

### Easily Confused With

- **SLI Measurement Location (6-point scale)**: The measurement location spectrum (client
  app → third-party synthetic → cloud-provider external → edge → cluster-internal → instance)
  maps to the Fidelity axis of the compass but with more granular placement. The compass is
  the evaluation/decision model; the measurement location spectrum is the implementation
  taxonomy for the fidelity dimension.

______________________________________________________________________

## Related Skills

- **depends-on** → `sli-monitoring-design-maturity`: The stage model must be understood first to know what the SLI should measure; the compass then evaluates how the measurement is collected.
- **composes-with** → [`service-level-topology`](../service-level-topology/SKILL.md): The topology identifies which SLIs to create; the compass evaluates how to instrument them and guides investment toward higher fidelity.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
