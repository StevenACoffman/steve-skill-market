---
name: canary-as-error-budget-arithmetic
description: |
  Use this skill when sizing a canary deployment or evaluating whether a canary process is epistemically sound.

  Call when: A team is deciding what percentage of traffic to route to a canary, how long to run it, or whether to use blue/green deployment as a canary mechanism.

  Do not call when: The deployment is a full rollout with no partial population control, or when the decision is purely about rollback speed rather than defect detection.

  Key trigger: Someone proposes a canary size by convention ("we always do 5%") or proposes blue/green as a canary evaluation strategy. The correct frame is arithmetic, not convention. Canary size × estimated defect rate × duration = budget consumed. If the team cannot state that calculation, they have not sized the canary.

  Before/after canaries — including blue/green — are structurally unsound for defect attribution because time is itself a confound. Concurrent canaries (control and canary populations simultaneously active) are required for valid comparison.
source_book: "The Site Reliability Workbook" by Betsy Beyer et al. (Google)
source_chapter: "Chapter 16 - Canarying Releases; Chapter 2 - Implementing SLOs"
tags: [canary, release-engineering, error-budget, deployment, slo, blue-green]
related_skills: []
---

# Canary Sizing as Error Budget Arithmetic (With Before/After Invalidation)

## R — Original Text

> "The canary process risks only a small fragment of our error budget, which is limited by time and the size of the canary population. Global deployment can place the SLO at risk fairly quickly. If we deploy the candidate from our trivial example, we would risk failing 20% of requests. If we instead use a canary population of 5%, we serve 20% errors for 5% of traffic, resulting in a 1% overall error rate. This strategy allows us to conserve our error budget—impact on the budget is directly proportional to the amount of traffic exposed to defects."
>
> "A before/after canary process is an extension of the attribution problem. In this process, the old system is fully replaced by the new system, and your canary evaluation compares system behavior before and after the change over a set period of time. Because time is one of the biggest sources of change in observed metrics, it is difficult to assess degradation of performance with before/after evaluation. Blue/green deployment maintains two instances of a system. In this setup, you are effectively performing a before/after canary."
>
> — Google SRE Workbook, Chapter 16 - Canarying Releases

______________________________________________________________________

## I — Framework (Interpretation)

Canary deployment is not risk management theater — it is error budget arithmetic. The key insight is that canary size is not a convention ("5% is standard") but a calculated decision derived from three inputs: the estimated worst-case defect rate of the candidate release, the canary traffic fraction, and the canary duration.

The core equation: `budget_consumed = canary_fraction × defect_rate × window_duration / total_period`

This means a 5% canary with a 20% defect rate running for 1 hour in a 30-day window consumes a specific, calculable fraction of the monthly budget. The team must state that number before starting the canary, not discover it afterward.

Before/after canaries are structurally unsound because time is a confound, not a control variable. Traffic patterns, user behavior, downstream state, and infrastructure load all change between the "before" and "after" measurement windows. This makes it impossible to attribute metric changes to the new code versus normal temporal variation. Blue/green deployment, despite its operational convenience, is a before/after canary in disguise — you switch from green to blue and compare post-switch metrics to pre-switch metrics.

Concurrent canaries — where control (old version) and canary (new version) populations handle traffic simultaneously — eliminate time as a confound. Both populations experience the same traffic mix, the same downstream conditions, and the same infrastructure state at the same moment. Metrics can be split by population (canary vs. control) to yield a valid comparison.

Canary metrics must be SLI-correlated (user-visible error rates, latency ratios) rather than system health proxies (CPU, memory), which can appear normal while user experience degrades.

______________________________________________________________________

## A1 — Past Application

**Case 1 — PagerDuty progressive canary sizing**
PagerDuty's deployment pipeline uses explicit percentage-based rollout stages (1% → 5% → 25% → 100%) with automated SLI evaluation gates between stages. Each gate checks whether the error rate in the canary population — measured against the simultaneous control population — has exceeded a threshold derived from the remaining monthly error budget. A deployment with a high estimated defect risk is held at 1% until enough signal accumulates, then advanced. This is the arithmetic framework applied: the gate threshold is budget-derived, not a fixed number.

**Case 2 — Waze release canarying for maps data**
Waze deploys map data updates to a geographic canary region before global rollout. Because the canary region and the control regions serve simultaneously, Waze can compare navigation success rates, rerouting frequency, and turn-by-turn error rates between the updated and non-updated populations at the same moment in time. This eliminates time-of-day and traffic-volume confounds that would corrupt a before/after comparison. The canary region size is calibrated so that a worst-case data quality defect does not consume more than a defined fraction of the weekly SLO budget.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: Canary size chosen by habit**
The team says "we'll canary to 5% as usual." Trigger: ask them to state the worst-case defect rate of this specific build and compute the budget impact. If they cannot, the canary size has not been chosen — it has been defaulted.

**Scenario 2: Blue/green proposed as canary evaluation**
The team proposes flipping from green to blue and monitoring for 30 minutes. Trigger: this is a before/after canary. The 30-minute comparison window is confounded by whatever changed in traffic or system state during those 30 minutes. If there is a concurrent option (split traffic between green and blue simultaneously), that is the correct form.

**Scenario 3: "We canary on system metrics"**
The team monitors CPU and memory on the canary pod. Trigger: system metrics that look healthy can mask user-visible error rate spikes. The canary must be evaluated on SLI-correlated metrics (request success rate, latency ratio at the Nth percentile) broken out by population.

**Language signals:** "we'll do our standard canary," "blue/green gives us easy rollback," "the canary machines look healthy," "we just watch it for a bit."

**Distinguishing from adjacent skills:** This is not the SLO decision matrix (which governs engineering action given SLO state) and not the error budget policy (which governs release freezes). This skill governs the sizing and structural validity of a single deployment experiment, before any budget has been consumed.

______________________________________________________________________

## E — Execution Steps

1. **State the worst-case defect rate.** Estimate the percentage of requests the new version will fail if the defect is present. Use data from staging, load tests, or prior incidents as anchors. If unknown, use 100% (worst case).

2. **Determine acceptable budget spend for this canary.** Check the remaining error budget for the current window. Decide what fraction of remaining budget is acceptable to spend on this experiment (e.g., 10% of remaining budget).

3. **Compute maximum canary fraction.**
   `max_canary_fraction = acceptable_budget_minutes / (defect_rate × canary_duration_minutes)`
   Example: 5 minutes budget available, 20% defect rate, 30-minute canary → max fraction = 5 / (0.20 × 30) = 83%. If the calculation shows the canary is safe even at 50%, consider a larger canary for faster signal.

4. **Verify concurrent population design.** Confirm that the control population (old version) and canary population (new version) will serve traffic simultaneously during the evaluation window. Reject before/after designs, including blue/green where traffic is switched rather than split.

5. **Instrument canary-vs-control metric split.** Ensure monitoring breaks out SLI metrics (error rate, latency) by population tag. A canary with a 5% population and 20% defect rate will show only 1% in the aggregate metric — insufficient signal. Only the per-population view reveals the canary's true error rate.

6. **Set evaluation criteria before launch.** Define the SLI threshold that terminates the canary (e.g., canary error rate > 2× control error rate). Do not evaluate post hoc.

7. **Monitor and gate.** At the end of the canary window, compare canary vs. control on SLI metrics. If within tolerance, advance to the next stage. If not, roll back and treat as a confirmed defect.

**Completion criteria:** The canary size and duration were derived from budget arithmetic (not convention), the design is concurrent (not before/after), metrics are SLI-correlated and split by population, and evaluation criteria were written before launch.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The deployment has no partial-population capability (all-or-nothing rollout) — in this case, a feature flag or traffic-splitting proxy must be introduced before this skill can be applied.
- The change is a schema migration or other deployment where canary population isolation is not possible (shared state invalidates the canary/control comparison).
- The canary is being used to evaluate user behavior (A/B testing) rather than defect detection — different analysis methods apply.

**Failure patterns:**

- Treating canary success as proof of absence of defects. A 5% canary with a 10% defect rate affecting only certain user segments may not produce detectable signal if the segment is underrepresented in canary traffic.
- Advancing on system metrics that look healthy (CPU/memory normal) while the canary error rate is elevated but subthreshold in the aggregate view.
- Running the canary without a pre-set termination criterion, then negotiating the result post hoc.

**Author blind spots:**

- The book's arithmetic assumes uniform load across canary and control populations. In practice, load balancers may route disproportionate traffic to one population. The team must verify traffic distribution.
- The book does not address stateful canarying (e.g., database schema changes, session state). The framework applies cleanly only to stateless or independently stateful components.
- Jsonnet-specific config examples in adjacent chapters age poorly; the canary arithmetic itself is language-agnostic.

**Easily confused with:**

- Error budget policy (governs what to do after budget is exhausted, not how to size a canary).
- Progressive delivery (broader continuous delivery pattern; this skill is the reliability-measurement layer within progressive delivery).

______________________________________________________________________

## Related Skills

- **depends_on**: error-budget-policy-framework — canary fraction arithmetic requires knowing the remaining error budget to compute the maximum safe canary size
- **composes_with**: multiwindow-multi-burn-rate-alerting — burn-rate alerting monitors the canary population's live error rate; canary arithmetic pre-sets the threshold at which the canary must be halted
- **contrasts_with**: configuration-hermeticity-framework — both address deployment safety, but canary targets code-defect detection via traffic splitting while hermeticity targets config reproducibility via evaluation isolation

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04
