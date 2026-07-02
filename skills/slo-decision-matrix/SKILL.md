---
name: slo-decision-matrix
description: |
  Use this skill when a team needs to determine the right engineering action from SLO state alone is insufficient. Call it when you know whether the SLO is being met, but still don't know what to do — because you need two additional dimensions: toil level and user satisfaction.

  Trigger scenarios: SLO is met but users are still complaining, SLO is met but the team is burning out on operational work, SLO is missed but users don't seem to notice, or a service review where the team needs to decide whether to tighten, relax, automate, or hand back a service.

  Do not use as a real-time incident response tool (use incident command for that). Do not use when you don't have data on at least two of the three dimensions — the matrix requires all three inputs to prescribe the right action. Do not use to justify inaction: the "met / low / high" cell (everything looks good) still has a prescribed action (increase velocity or reduce engagement).
tags: [slo, decision-making, toil, customer-satisfaction, prioritization, calibration]
---

# SLO × Toil × Satisfaction Decision Matrix

## R — Original Text (Reading)

> "Table 2-5 provides suggested courses of action based on three key dimensions: Performance against SLO, The amount of toil required to operate the service, The level of customer satisfaction with the service... SLO Met, Toil Low, Satisfaction High: Choose to (a) relax release and deployment processes and increase velocity, or (b) step back from the engagement... SLO Missed, Toil High, Satisfaction Low: Offload toil and fix product and/or improve automated fault mitigation."
>
> — Google SRE Workbook, Chapter 2

______________________________________________________________________

## I — Methodological Framework (Interpretation)

SLO state alone is insufficient to prescribe engineering action. A service meeting its SLO with high toil is not in a good state — it is unsustainable. A service missing its SLO with satisfied users may have an SLO that is too strict relative to what users actually need. The matrix provides a complete decision framework by adding toil and satisfaction as required inputs.

The eight-cell matrix:

| SLO    | Toil | Satisfaction | Prescribed Action                                                                                                                   |
| ------ | ---- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| Met    | Low  | High         | Increase velocity or reduce SRE engagement — the service is in the best possible state                                              |
| Met    | Low  | Low          | **Tighten the SLO** — users are unhappy despite compliance; you are measuring the wrong thing                                       |
| Met    | High | High         | If false-positive alerts: reduce sensitivity. Otherwise, loosen SLO or fix automation — the service is over-engineered for this SLO |
| Met    | High | Low          | **Tighten the SLO** — same diagnosis as Met/Low/Low; high toil confirms the SLI is not capturing what users care about              |
| Missed | Low  | High         | **Loosen the SLO** — users are satisfied at current performance; the SLO is stricter than user needs require                        |
| Missed | Low  | Low          | Increase engineering investment to improve the product                                                                              |
| Missed | High | High         | Loosen SLO and/or reduce toil — the service is operationally expensive but users don't need the current target                      |
| Missed | High | Low          | Offload toil and fix the product — the worst cell; requires structural intervention                                                 |

The two counterintuitive cells drive the most value:

**Met / Low / Low (or Met / High / Low)**: SLO compliance combined with user dissatisfaction is diagnostic of a wrong SLI. The service is measuring backend success rate while users experience frontend latency, or measuring availability while users experience correctness failures. The correct action is to revisit the SLI specification — not to do more engineering work on reliability.

**Missed / Low / High**: SLO non-compliance combined with user satisfaction means the SLO is stricter than necessary. Relaxing the SLO is not a failure — it is a calibration that unlocks engineering time and error budget that was being over-spent.

The matrix requires honest measurement of all three dimensions. User satisfaction is the hardest: support ticket counts, NPS surveys, public forum posts, and direct user sampling are all valid proxies. At least one satisfaction signal must be collected before the matrix can be applied.

______________________________________________________________________

## A1 — Past Application (From the Book)

## Case 1 — Home Depot VALET Framework (Chapter 3)

- **Problem**: The Home Depot needed a reliability framework that could govern 800+ services across microservices teams with varying reliability needs. Single-metric SLO assessment was insufficient — a service could be highly available but generating enormous support ticket volume.
- **Application**: THD developed VALET (Volume, Availability, Latency, Errors, Tickets) as a five-dimension framework. The Tickets dimension is a direct proxy for user satisfaction — it captures user-visible failures that the other four dimensions miss. This independently instantiates the same insight as the three-dimensional matrix: availability alone is insufficient to determine the right engineering action.
- **Conclusion**: Adding the Tickets dimension to availability and latency measurement gave THD teams a multi-dimensional view that correlated with actual user experience rather than just system health metrics.
- **Result**: Within one year, THD tracked SLOs for 800 services, with VP-sponsored integration into performance reviews. The Tickets dimension prevented teams from hiding behind green SLOs while their services generated support load.

## Case 2 — SRE Engagement Model (Chapter 20)

- **Problem**: Google SRE teams needed a framework to decide when to reduce engagement with a service, tighten involvement, or hand back the service to the developer team — without relitigating the decision service by service.
- **Application**: The three SRE principles (SLOs with consequences; time to make tomorrow better; workload self-regulation) map directly to the same three dimensions: SLO state governs whether consequences apply; toil level governs whether the team has time to improve; satisfaction provides the user-facing signal. The engagement decision matrix is the organizational-level instantiation of the same three-dimensional framework.
- **Conclusion**: When a service sits in the Met/Low/High cell consistently, stepping back from the engagement or handing back the service is the prescribed action — not continued investment.
- **Result**: Handback becomes a normal, data-driven outcome rather than an organizational failure.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — "SLO is green but NPS is down"**
Language signals: "We're meeting our 99.9% target but users keep complaining about performance." "Support tickets are up even though our metrics look fine."
Matrix cell: Met / (Low or High) / Low.
Prescribed action: The SLI is measuring the wrong thing. The service measures backend success rate but users experience frontend loading time. Revisit the SLI specification to find the measurement gap. Do not do more reliability work until the SLI is corrected.

**Scenario 2 — "SLO is red but nobody cares"**
Language signals: "We missed the SLO last quarter but I haven't heard any user complaints." "Our error budget policy says we should freeze but the product team says users are happy."
Matrix cell: Missed / (Low) / High.
Prescribed action: Loosen the SLO. The current target is stricter than user needs require. Relaxing the SLO is not capitulating — it is returning error budget to the team for engineering work that matters.

**Scenario 3 — "SLO is met but the team is burning out"**
Language signals: "We're hitting our SLO numbers but the on-call is getting crushed." "We're spending 70% of our time on operations."
Matrix cell: Met / High / (High or Low).
Prescribed action: If satisfaction is high, either loosen the SLO (which relaxes the alerting sensitivity and operational burden) or invest in automation to reduce toil while maintaining the SLO. Do not celebrate the green SLO — toil at this level is unsustainable.

**Distinguishing from adjacent skills**: The slo-decision-matrix answers "what should we do given our current SLO state?" The error-budget-policy-framework answers "what are we required to do when the budget is exhausted?" The slo-stakeholder-negotiation-gate answers "is this the right SLO target?" The matrix is the diagnostic; the policy is the enforcement mechanism.

______________________________________________________________________

## E — Execution Steps

1. **Measure SLO state**: Determine whether the service is currently meeting its SLO over the measurement window (typically four-week rolling). Met or Missed — binary input.

2. **Measure toil level**: Estimate the percentage of SRE time spent on operational work (toil by the six-property test: manual, repetitive, automatable, tactical, no enduring value, scales with service). High = above 30-40% of SRE time; Low = below. Note: the 50% cap is the structural limit; "high" should be flagged well before that threshold.

3. **Measure user satisfaction**: Choose at least one proxy: support ticket counts per week, NPS or CSAT scores, public forum posts, direct user sampling. Determine the trend (improving, stable, declining) and whether it correlates with SLO events.

4. **Map to the matrix cell**: Combine the three binary inputs to identify the prescribed action.

5. **Diagnose the non-obvious cells**:

   - If Met + satisfaction Low: investigate SLI coverage. What user-visible failures are not captured by the current SLI? Where is the measurement gap?
   - If Missed + satisfaction High: calculate what SLO target would have been met over the historical window. That target is likely the correct one.

6. **Act on the prescription**: Do not override the matrix judgment with organizational inertia ("we can't loosen the SLO — it looks bad"). The matrix output is a calibration recommendation, not a performance evaluation.

7. **Revisit quarterly**: SLO state, toil level, and satisfaction all change. The matrix should be applied at regular service review cadence.

**Completion criteria**: All three dimensions are measured with at least one data source each, the cell is mapped, and the prescribed action is translated into a specific engineering task with an owner.

______________________________________________________________________

## B — Boundary ★

**Do not use when**:

- You don't have data on user satisfaction. Without it, you can only observe two dimensions — and the two counterintuitive cells (SLO met but users unhappy; SLO missed but users happy) are invisible. Collect at least one satisfaction proxy before applying the matrix.
- The service has no SLO. Fix that first.
- In the middle of an active incident. The matrix is a strategic calibration tool, not an incident triage tool.

**Failure patterns**:

- **Ignoring the Met/Low/Low cell**: Teams celebrate green SLOs and don't investigate user dissatisfaction. The matrix explicitly prescribes the diagnosis: wrong SLI.
- **Treating Missed/Low/High as a failure**: Loosening an SLO when users are satisfied is the correct action. Teams that resist this waste error budget on reliability that users don't need.
- **Using toil as a binary without measurement**: "Toil feels high" is not a measurement. Track the percentage of SRE time on operational work. The 50% cap gives a concrete upper bound; "high" should be operationally defined before the matrix is applied.
- **Applying the matrix once and declaring done**: SLO state, toil, and satisfaction shift. Quarterly application is the minimum cadence.

**Author blind spots**:

- Satisfaction measurement is harder than SLO measurement and the book does not provide a specific methodology for it. The Home Depot VALET Tickets dimension is the most concrete proxy in the book, but it captures only one failure mode (visible enough to generate a ticket).
- The matrix does not account for services where toil is high because the SLO target is unreachable without toil — a circular problem that requires the slo-stakeholder-negotiation-gate skill to resolve.
- The matrix is presented as a table without explicit probability weights for each cell. In practice, the Met/Low/High cell (all good) is the rarest state; the matrix is most valuable for the six other cells.

**Easily confused with**:

- **SLO performance reporting**: Reporting is a measurement activity. The matrix is a decision activity that uses measurement as input.
- **error-budget-policy-framework**: The policy governs responses to budget exhaustion events. The matrix governs ongoing calibration of whether the SLO target is correct. They operate at different timescales and with different triggers.

______________________________________________________________________

## Related Skills

- **depends_on**: slo-stakeholder-negotiation-gate — when the matrix prescribes tightening or loosening the SLO, that change must pass through the tripartite negotiation gate to be valid
- **contrasts_with**: error-budget-policy-framework — the policy mandates a fixed response when the budget is exhausted; the matrix provides calibration guidance based on ongoing SLO × toil × satisfaction state
- **composes_with**: multiwindow-multi-burn-rate-alerting — alerting determines how quickly the team learns the SLO is at risk; the matrix determines what engineering action to take in response to that information

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "The Site Reliability Workbook" by Betsy Beyer et al. (Google) — Chapter 2 - Implementing SLOs, Chapter 3 - SLO Engineering Case Studies
