---
name: sli-formula-measurement
description: |
  Use this skill when designing or reviewing the formula and measurement location for a
  Service Level Indicator — deciding what counts as a "good" event, what counts as a
  "valid" event, and where in the system architecture to collect the data.

  **When to call:**
  - Writing a new SLI formula and needing to decide good/valid boundaries
  - Reviewing an existing SLI that uses "total" in the denominator instead of "valid"
  - Choosing where in the architecture to measure (client, edge, load balancer, inside
    the service, inside the instance)
  - Determining whether an existing metric is worth waking someone up for
  - Scoping an SLI to what one team actually controls (control boundary alignment)
  - Deciding between event-based and time-based SLI formulas

  **When NOT to call:**
  - Setting the SLO target percentage (use `slo-definition-calibration-framework`)
  - Designing multiple SLO tiers (use `multi-tier-slo`)
  - Choosing between failover and fallback as resilience mechanisms (use `fallback-failover`)
  - Classifying an incident as degradation vs. disruption (use `degradation-disruption`)

  **Key trigger signal:** The SLI denominator includes events the team does not control
  (e.g. DDoS traffic, dependency failures, planned maintenance). Or: "We're getting paged
  for things that don't affect users." Or: "Our availability metric doesn't match what
  users are experiencing." Or: "We measure from inside the container — is that good enough?"
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20230808_153608_valid-vs-total.md, 20231126_051120_sli.md, 20230808_214447_sli-good.md, 20230809_201014_sli-measurement-location.md
tags: [sli, formula, valid-vs-total, measurement-location, consumer-perception, good-events, fidelity]
related_skills:
  - slug: sli-monitoring-design-maturity
    relation: composes-with
  - slug: slo-definition-calibration-framework
    relation: composes-with
  - slug: composite-slo
    relation: composes-with
  - slug: degradation-disruption
    relation: composes-with
  - slug: multi-tier-slo
    relation: composes-with
---

# SLI Formula and Measurement Design Principles

## R — Original Text (Reading)

> Service level indicator guides the optimization. The definition of *valid* gives a scope
> to that optimization.
>
> There are a few reasons to use *valid* instead of *total*:
>
> You should only be responsible for what you control. It's only fair. Example: ❌ User
> facing API success rate (our API may fail due to our dependencies). ✔️ User facing API
> success rate for errors that are not due to failure in our dependencies or content that
> the team doesn't control. Another example: ❌ All API calls. ✔️ Authenticated API calls
> (we don't want to be punished for DDoS attacks or any other unintended usage of the API
> surface).
>
> As a rule of thumb, the closer you are to the consumer, the better the data quality, but
> the harder it is to measure.

— Alex Ewerlöf, 20230808_153608_valid-vs-total.md and 20230809_201014_sli-measurement-location.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

An SLI formula has two components: the numerator (good events or good time slots) and the
denominator (valid events or valid time slots). Getting both right is the core discipline
of SLI design.

## Rule 1: good/VALID, Not Good/total

"Total" includes events the team does not control: DDoS traffic, dependency failures,
planned maintenance windows, requests from automated health-check tools, unauthenticated
API calls. Using "total" in the denominator punishes the team for things outside their
scope, dilutes the signal, and produces an SLI that does not map to optimization levers the
team actually has.

"Valid" scopes the denominator to events that are meaningful to the consumer and within the
team's control to improve. Valid is defined along dimensions like:

- Request type (e.g. authenticated API calls, not health check pings)
- Endpoint (e.g. `/api`, not static assets)
- User tier (e.g. premium users, breaking news articles only)
- Time window (e.g. exclude planned maintenance, though this is discouraged for consumers
  who still experience the downtime)
- Resource type (e.g. orders database, not logging database)

## Rule 2: Measure at the Consumer Boundary, Not Internal Vitals

The SLI measures how reliability is *perceived by the consumer*. Internal metrics —
CPU usage, memory, container health, DB connections — do not directly represent consumer
experience. They may be useful for root cause analysis after an incident, but they are
not SLIs.

Six measurement points exist, from closest to farthest from the consumer:

1. Client application (highest fidelity, hardest to collect, most noise from network/device)
2. Third-party synthetic monitoring (controlled, predictable, but may not represent real users)
3. Outside the account but same cloud provider (good balance for availability)
4. Edge/load balancer (good boundary: "our responsibility" ends here)
5. Inside the cluster (easy to collect, misses edge-to-internet failures)
6. Inside the instance (easiest, but least correlated with consumer experience)

**Trade-off:** Measuring closer to the consumer gives higher fidelity but also more noise
(network jitter, device performance, CDN issues) and more data volume. Measuring further
from the consumer (inside the service) is easier but can produce false negatives: the
service reports "up" while consumers are actually unable to reach it.

## Rule 3: "Would This Wake Someone Up?" Litmus Test

If an alert fired on this SLI and it did not correspond to a consumer-visible failure,
it is not a good SLI. Metrics that do not pass the wake-up test (CPU spikes, internal
queue depth, DB connection count in isolation) are valuable for diagnosis but should not
be the primary SLI. The question to ask: "If this metric is bad right now, does that
definitely mean consumers are experiencing a failure?" If the answer is "not necessarily,"
the metric is not a good SLI.

## Rule 4: Good Event Definition Depends on SLI Type

There are four types of "good" declarations:

- **Upper bound**: event is good if metric is below a threshold (e.g. response time < 400ms)
- **Lower bound**: event is good if metric is above a threshold (e.g. GPU utilization > 80%)
- **Range bound**: event is good if metric is within a window (e.g. temperature between
  -10°C and 43°C)
- **No bound (set membership)**: event is good if it belongs to a defined set
  (e.g. orders processed with settled payment)

The vast majority of SLIs use upper bound (latency < threshold) or no-bound (request
succeeded = yes/no).

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: News Site Freshness SLI — Scoping Valid to What the Team Controls (C25)

- **Problem:** A media company wanted to measure news freshness (time from editorial
  "Publish" to article visible on site). The full end-to-end path included CMS, CDN, BFF,
  and browser rendering — but the front-end team only controlled BFF and above.
- **Application:** Instead of "all articles on the site" as the valid set, the team scoped
  valid events to: articles in the breaking news section published in the last 24 hours,
  measured at the BFF cache layer. Good: time from CMS publish to BFF cache < 1 minute.
- **Conclusion:** By using "valid" (breaking news, last 24h, BFF layer) instead of "total"
  (all articles, full pipeline), the SLI excluded CMS behavior and CDN layers the team did
  not control, and excluded non-time-sensitive sections where freshness was less critical.
- **Result:** The front-end team could optimize the SLI without being penalized for editorial
  delays or CMS failures. The SLI was actionable and accurate to their scope.

### Case 2: Front-End Team Blamed for Latency They Cannot Control (C09)

- **Problem:** In a mobile/backend/database architecture, total latency includes mobile
  processing time, network transit, and backend response time. When latency exceeded
  targets, the mobile team was blamed because they owned the user-facing layer.
- **Application:** The correct SLI design requires decomposing latency by team ownership.
  The mobile team should only be held accountable for their portion of the latency budget —
  the part they can actually optimize.
- **Conclusion:** Using "total end-to-end latency" as the mobile team's SLI violates the
  valid principle: network latency and backend latency are not valid events for the mobile
  team's optimization. They cannot be controlled by that team.
- **Result:** Decomposing the latency budget across teams, with each team's SLI scoped to
  what they control, eliminates blame assignment for uncontrollable factors and focuses
  optimization correctly.

### Case 3: Rust Rewrite Discovers Real Bottleneck Was Network Latency (C05)

- **Problem:** A team spent 6 months rewriting a Java microservice in Rust to improve
  response time. After deployment, the latency improvement was negligible.
- **Application:** The team's implied SLI was total response time, but they optimized only
  the application processing layer. The actual dominant latency component was cross-region
  network dependencies — outside the application and outside their control.
- **Conclusion:** Without first measuring which component contributed most to the SLI,
  the optimization was directed at the wrong "valid" scope. The SLI did not help them
  identify what to optimize before they spent the budget.
- **Result:** Six months of engineering produced negligible improvement. The prior step
  should have been to decompose the latency SLI to identify the real constraint before
  committing to the rewrite.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An on-call engineer is getting paged for CPU spikes or DB connection counts that rarely
   correspond to user-visible failures. The team needs to replace infrastructure metrics with
   consumer-grounded SLIs that only alert on real consumer impact.

2. A team is setting up SLOs for the first time. They have pulled an availability metric
   from their monitoring tool that divides "successful requests" by "all requests" — but
   "all requests" includes automated health checks, DDoS traffic, and unauthenticated calls.
   They need to define "valid" before setting any SLO target.

3. A team measures availability "from inside the container" and their SLI shows 99.9%
   availability, but users are reporting frequent errors. They need to move the measurement
   location toward the consumer boundary to capture the actual failure.

### Language Signals (Activate When These Appear)

- "Our SLI looks fine but users are complaining"
- "We keep getting paged for things that aren't really incidents"
- "We measure uptime by pinging our health endpoint every minute — is that enough?"
- "We're being blamed for latency our team doesn't control"
- "Our error rate spikes whenever our dependency goes down — that shouldn't count, right?"
- "What should we put in the denominator of our SLI formula?"

### Distinguishing from Adjacent Skills

- Difference from `slo-definition-calibration-framework`: This skill designs the *measurement formula and location*
  for the SLI. `slo-definition-calibration-framework` calibrates *what target percentage* the SLO should be set to
  once the SLI formula is defined. You must complete the SLI formula before setting the SLO.
- Difference from `multi-tier-slo`: This skill designs the SLI formula (what is
  good/valid). `multi-tier-slo` applies multiple targets to that formula. They stack in
  sequence.
- Difference from `degradation-disruption`: This skill is about designing the SLI to
  *detect* both quality failures (degradation) and complete failures (disruption). The
  distinction between the two is made in `degradation-disruption`.

______________________________________________________________________

## E — Execution Steps

1. **Draft the initial SLI formula using good/total**

   - Start with the obvious metric: what is the consumer's primary experience? (Availability?
     Latency? Data freshness? Order success rate?)
   - Write an initial formula: `good_events / total_events` or `good_time / total_time`
   - Completion criteria: You have an initial formula, even if imprecise.

2. **Apply the "wake-up test" to the denominator**

   - Ask: Does every event in the denominator represent a case where a failure would be
     consumer-visible and worth waking someone up for?
   - Identify events that should NOT be in the denominator: health check pings, DDoS
     traffic, unauthenticated requests, dependency-caused failures, planned maintenance
   - Remove those events: replace "total" with "valid"
   - Completion criteria: The denominator contains only events where a failure would
     represent a real consumer impact.

3. **Apply the control boundary test to the denominator**

   - Ask: Can the team optimize every component that contributes to failures in this set?
   - If not, decompose the metric: identify which portion the team controls and scope
     "valid" to that portion
   - Example: Total latency → latency of requests handled by this service excluding
     dependency calls outside the team's control
   - Completion criteria: The team can point to at least one concrete optimization they
     could make to improve the SLI.

4. **Define "good" precisely**

   - Choose the appropriate bound type: upper bound (latency < threshold), lower bound
     (utilization > threshold), range bound, or no-bound (succeeded = yes/no)
   - The threshold value must correspond to something the consumer actually cares about,
     not an arbitrary round number
   - Completion criteria: "Good" is defined as a specific, measurable condition tied to
     consumer experience.

5. **Select the measurement location**

   - Apply the fidelity-vs-cost trade-off:
     - High traffic volume + no existing RUM infrastructure: measure at edge/load balancer
     - Existing data pipeline or client SDK: measure from client or third-party synthetic
     - Inside a Kubernetes cluster with known consumer boundary: measure at edge or cluster
       boundary
   - Avoid measuring from inside the instance as the sole SLI — it misses external
     connectivity failures
   - Stop condition: If the measurement location cannot observe failures that consumers
     report, it is too far inside the system. Move it outward.
   - Completion criteria: A specific measurement location is chosen with a rationale
     explaining what it captures and what it misses.

6. **Validate the complete SLI formula**

   - Write the complete formula in plain language:
     `[good definition] / [valid definition] measured at [location]`
   - Apply the wake-up test one more time to the complete formula
   - Ask: If this SLI drops significantly, is that always consumer-visible? If yes, the
     formula is ready.
   - Completion criteria: The complete formula passes the wake-up test.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- You already have a consumer-grounded SLI formula and the question is what percentage
  target to set — that is `slo-definition-calibration-framework`.
- The question is whether to apply multiple SLO tiers to the SLI — that is `multi-tier-slo`.
- You need to combine SLIs from multiple dependent services into a composite reliability
  number — that is `composite-slo`.

### Failure Patterns Warned by the Author

- **Infrastructure metrics as SLIs (ce09, ce15)**: CPU, memory, network throughput, and
  DB connection count are not SLIs unless they are directly and always correlated with
  consumer experience. They are valuable for root cause analysis but should not drive
  alerts. Alert fatigue from infrastructure-metric SLIs is the most common failure mode
  in SLI adoption programs.
- **Senior engineer resistance — relabeling existing metrics (ce09)**: Engineers with years
  of experience with traditional monitoring often adopt SLI vocabulary while retaining
  their infrastructure-metric mental model. They rename CPU-% as "SLI" without changing
  what they measure. The result: dashboards that look like SLIs but fire on noise.
- **Synthetic SLI masking real failures (ce23)**: A health endpoint ping every minute shows
  99.9% availability while actual user journeys are failing. If the measurement location
  is inside the service and does not traverse authentication, authorization, and critical
  business logic, it does not represent consumer experience.
- **SLI out of team's control (ce18)**: Assigning an end-to-end metric to a team that
  only controls one layer creates broken ownership. The team is paged for failures caused
  by other teams and cannot act on the alert. Always align SLI scope with team control
  boundary.

### Author's Blind Spots / Limitations

- The measurement location framework (6 points from client to instance) is described for
  request-driven, synchronous services. For event-driven architectures (queues, stream
  processors, batch jobs), the "consumer boundary" may be a downstream topic consumer,
  a scheduled job trigger, or a data freshness check — not a request/response API boundary.
  The 6-point model needs adaptation for async workloads.
- The "valid" scoping discussion assumes that the team has enough system knowledge to
  know what they control and what they don't. In organizations with broken ownership
  (Baby Parent, Foot Soldier archetypes), the team may not know the system well enough
  to correctly scope validity.
- For large platform APIs serving heterogeneous consumers, "the consumer" may not be a
  monolithic group with a single tolerance level. The framework does not fully address
  multi-consumer platforms where different consumers have radically different use cases
  for the same API surface.

### Easily Confused With

- **KPI (Key Performance Indicator)**: KPIs measure business outcomes (revenue, MAU,
  conversion rate). SLIs measure technical reliability as perceived by consumers. Engineers
  do not control demand, market conditions, or purchase intent. An SLI that aggregates
  variables outside engineering control is not a good SLI — it is effectively a KPI mislabeled.
- **Monitoring metric**: Any metric you can collect from your system is a candidate for a
  monitoring metric. Only metrics that pass the wake-up test (consumer-visible failure when
  bad, team-controllable) qualify as SLIs. Most monitoring metrics are not SLIs.

______________________________________________________________________

## Related Skills

- **composes-with** → `sli-monitoring-design-maturity`: The formula design (good/valid) is the technical implementation of the task-awareness Stage 3 requires; both are needed for a complete SLI design.
- **composes-with** → `slo-definition-calibration-framework`: The SLI formula must be defined before setting the SLO target; slo-definition-calibration-framework calibrates the target against consumer tolerance once the formula is correct.
- **composes-with** → [`composite-slo`](../composite-slo/SKILL.md): Each component SLI formula feeds into the composite SLO calculation across dependency graphs.
- **composes-with** → [`degradation-disruption`](../degradation-disruption/SKILL.md): The SLI formula's good/valid design is what allows it to detect quality failures (degradation) vs. total failures (disruption).
- **composes-with** → [`multi-tier-slo`](../multi-tier-slo/SKILL.md): Multi-tier SLO applies multiple threshold targets to a well-designed SLI formula; the formula design comes first.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
