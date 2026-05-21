---
name: sli-monitoring-design-maturity
allowed-tools: Bash, Read, Edit
id: sli-monitoring-design-maturity
description: Use this skill when a team has implemented the four golden signals but on-call is still noisy or missing real incidents — the exact failure that falls between "we followed the SRE book" and "we have good SLIs," which requires both the canonical signal definitions (SRE book) and the maturity ladder that diagnoses why golden signals are insufficient for on-call alerting without consumer task grounding (Ewerlöf).
type: merged-skill
source_skills:
  - slug: site-reliability-engineering/four-golden-signals-monitoring
    book: "Site Reliability Engineering"
    author: Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.)
  - slug: reliability-engineering-mindset/sli-4-stage-evolution
    book: "Reliability Engineering Mindset"
    author: Alex Ewerlöf
related_skills:
  - slug: site-reliability-engineering/four-golden-signals-monitoring
    relation: supersedes
    note: This merged skill adds the maturity escalation path and the Stage 1 critique that the source skill lacks
  - slug: reliability-engineering-mindset/sli-4-stage-evolution
    relation: supersedes
    note: This merged skill adds the canonical golden signal definitions as the correct Stage 1 starting point that the source skill assumes without specifying
tags: []
---

# SLI Monitoring Design Maturity

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Alert / SLO config files:
!`find . \( -name '*.yaml' -o -name '*.yml' \) -not -path './.git/*' 2>/dev/null | xargs grep -l 'alert\|slo\|sli' 2>/dev/null | head -5`

### R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 6):**

> The four golden signals of monitoring are latency, traffic, errors, and saturation. If you can only measure four metrics of your user-facing system, focus on these four.
>
> If you measure all four golden signals and page a human when one signal is problematic (or, in the case of saturation, nearly problematic), your service will be at least decently covered by monitoring.

**From Ewerlöf (Reliability Engineering Mindset, sli-4-stage-evolution):**

> Stage 1 — Traditional SLI: rebranded existing metrics or golden signals; no research into consumers. The iconic characteristic of stage 1 SLIs is the absence of research into consumers and/or the reason they use the service. There might be some guesses but no solid verification.
>
> Stage 3 — Task-aware SLI: adds consumer Goals and Tasks; failures are identified where usage meets task. Good SLIs connect to the consumer's perspective.
>
> A good SLI is worth being on-call for whether 24/7 or just during working hours.

**Convergence note:** Both sources independently identify the symptom-vs-cause distinction as the central principle: alert on user-visible failures, not internal system state. The SRE book presents this as the rationale for the four golden signals (symptom-level metrics vs. CPU/memory debugging metrics). Ewerlöf presents the same principle as the Stage 1-to-Stage 3 advancement: golden signals without consumer task mapping are Stage 1 SLIs with poor signal-to-noise that should not drive on-call alerting. The productive tension is that the SRE book says golden signals = "at least decently covered"; Ewerlöf says golden signals = Stage 1 baseline that is "likely inadequate for on-call." The SRE book's own cases (Bigtable, Gmail) are Stage 1 failure modes that Ewerlöf's model explicitly predicts.

---

### I — Unified Framework (Interpretation)

The four golden signals are the correct starting point for SLI design. They are not the ending point.

**The four signals and their structural roles:**

The signals are not arbitrary — each plays a distinct role:

- **Latency:** The primary user-experience signal. Track error latency separately from success latency — a fast error is bad; a slow error is worse. Never use mean latency as a paging threshold; use percentiles (p50, p95, p99). Mean latency hides tail experience from the worst-affected users.
- **Traffic:** The demand context necessary to interpret the other three. A 5% error rate on 100 requests/hour differs fundamentally from 5% on 1,000,000 requests/hour. Traffic alone rarely pages, but is always the required denominator.
- **Errors:** Correctness at multiple levels: explicit failures (HTTP 500s), implicit semantic failures (200 with wrong content), and policy failures (correct response but SLO breach by latency). Errors are the most direct measurement of user impact.
- **Saturation:** The leading-indicator signal — predicts approaching failure before it happens. Monitor the most-constrained resource; set the paging threshold below 100% utilization at the point where performance visibly degrades.

The sharp distinction: alert on symptoms (what is broken — appropriate for paging), not causes (why it is broken — appropriate for debugging dashboards). CPU spike is a cause; elevated error rate is a symptom. Pages must fire on symptoms.

**The maturity ladder:**

Implementing the four golden signals produces a Stage 1 SLI configuration. Stage 1 is necessary but not sufficient:

- **Stage 1 — Traditional SLI:** golden signals applied to service endpoints without consumer research. Signal-to-noise is poor: the metric often fires when the consumer is fine (false positive) and stays silent when the consumer is failing in ways the metric doesn't measure (false negative). Do not use for on-call alerting without advancing to Stage 3.
- **Stage 2 — Consumer-aware SLI:** the consumer is identified and named. Many teams discover their assumed consumer is wrong, or that they have multiple consumer classes with different needs. Knowing the consumer does not yet tell you what a failed consumer experience looks like.
- **Stage 3 — Task-aware SLI:** consumer tasks are mapped, and the SLI formula is built around task failure, not system errors. The formula becomes `good_task_executions / valid_task_executions`. This is the minimum stage for on-call alerting to be worthwhile.
- **Stage 4 — Business-aware SLI:** each failure is dissected into Symptom (how the consumer notices), Consequence (impact on their task), and Business Impact (revenue or legal cost). Stage 4 allows prioritizing SLIs by business importance and setting SLO stringency proportional to cost.

**The conditional for when golden signals are sufficient:**

IF the service is a simple request-response API with straightforward user experience and a single identifiable consumer class → four golden signals correctly implemented (with percentile latency, separated error latency, and symptom-based paging) provide adequate monitoring coverage for that service.

IF the service has complex consumer tasks, data correctness requirements, multiple consumer classes, or streaming/batch workloads → Stage 1 golden signals are insufficient. Consumer-task failures invisible to latency, error rate, and saturation metrics will not page, and golden signals applied without consumer research will generate false-positive alerts. Advance to Stage 3.

**Why the SRE book's own cases are Stage 1 failure examples:**

The SRE book's Bigtable case (mean latency producing noise) and Gmail case (cause-based alerting on de-scheduled tasks rather than user inability to access Gmail) are exactly the Stage 1 failure modes that Ewerlöf's model predicts. The SRE book documents these as problems to fix; Ewerlöf's model explains why they occur systematically (golden signals without consumer task grounding) and provides the diagnostic ladder for escaping them.

The GitHub 2018 case (no analog in the SRE book) demonstrates the most important Stage 1 limitation: data correctness failures are invisible to all four golden signals. Availability showed green throughout a 24-hour data inconsistency incident. No golden signal — latency, traffic, errors, saturation — would have detected this failure because the service was technically "responding correctly" while consumers received stale and inconsistent data. This gap is not a corner case; it is structural to golden-signal monitoring.

---

### A1 — Past Application

## R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 6):**

> The four golden signals of monitoring are latency, traffic, errors, and saturation. If you can only measure four metrics of your user-facing system, focus on these four.
>
> If you measure all four golden signals and page a human when one signal is problematic (or, in the case of saturation, nearly problematic), your service will be at least decently covered by monitoring.

**From Ewerlöf (Reliability Engineering Mindset, sli-4-stage-evolution):**

> Stage 1 — Traditional SLI: rebranded existing metrics or golden signals; no research into consumers. The iconic characteristic of stage 1 SLIs is the absence of research into consumers and/or the reason they use the service. There might be some guesses but no solid verification.
>
> Stage 3 — Task-aware SLI: adds consumer Goals and Tasks; failures are identified where usage meets task. Good SLIs connect to the consumer's perspective.
>
> A good SLI is worth being on-call for whether 24/7 or just during working hours.

**Convergence note:** Both sources independently identify the symptom-vs-cause distinction as the central principle: alert on user-visible failures, not internal system state. The SRE book presents this as the rationale for the four golden signals (symptom-level metrics vs. CPU/memory debugging metrics). Ewerlöf presents the same principle as the Stage 1-to-Stage 3 advancement: golden signals without consumer task mapping are Stage 1 SLIs with poor signal-to-noise that should not drive on-call alerting. The productive tension is that the SRE book says golden signals = "at least decently covered"; Ewerlöf says golden signals = Stage 1 baseline that is "likely inadequate for on-call." The SRE book's own cases (Bigtable, Gmail) are Stage 1 failure modes that Ewerlöf's model explicitly predicts.

---

## I — Unified Framework (Interpretation)

The four golden signals are the correct starting point for SLI design. They are not the ending point.

**The four signals and their structural roles:**

The signals are not arbitrary — each plays a distinct role:

- **Latency:** The primary user-experience signal. Track error latency separately from success latency — a fast error is bad; a slow error is worse. Never use mean latency as a paging threshold; use percentiles (p50, p95, p99). Mean latency hides tail experience from the worst-affected users.
- **Traffic:** The demand context necessary to interpret the other three. A 5% error rate on 100 requests/hour differs fundamentally from 5% on 1,000,000 requests/hour. Traffic alone rarely pages, but is always the required denominator.
- **Errors:** Correctness at multiple levels: explicit failures (HTTP 500s), implicit semantic failures (200 with wrong content), and policy failures (correct response but SLO breach by latency). Errors are the most direct measurement of user impact.
- **Saturation:** The leading-indicator signal — predicts approaching failure before it happens. Monitor the most-constrained resource; set the paging threshold below 100% utilization at the point where performance visibly degrades.

The sharp distinction: alert on symptoms (what is broken — appropriate for paging), not causes (why it is broken — appropriate for debugging dashboards). CPU spike is a cause; elevated error rate is a symptom. Pages must fire on symptoms.

**The maturity ladder:**

Implementing the four golden signals produces a Stage 1 SLI configuration. Stage 1 is necessary but not sufficient:

- **Stage 1 — Traditional SLI:** golden signals applied to service endpoints without consumer research. Signal-to-noise is poor: the metric often fires when the consumer is fine (false positive) and stays silent when the consumer is failing in ways the metric doesn't measure (false negative). Do not use for on-call alerting without advancing to Stage 3.
- **Stage 2 — Consumer-aware SLI:** the consumer is identified and named. Many teams discover their assumed consumer is wrong, or that they have multiple consumer classes with different needs. Knowing the consumer does not yet tell you what a failed consumer experience looks like.
- **Stage 3 — Task-aware SLI:** consumer tasks are mapped, and the SLI formula is built around task failure, not system errors. The formula becomes `good_task_executions / valid_task_executions`. This is the minimum stage for on-call alerting to be worthwhile.
- **Stage 4 — Business-aware SLI:** each failure is dissected into Symptom (how the consumer notices), Consequence (impact on their task), and Business Impact (revenue or legal cost). Stage 4 allows prioritizing SLIs by business importance and setting SLO stringency proportional to cost.

**The conditional for when golden signals are sufficient:**

IF the service is a simple request-response API with straightforward user experience and a single identifiable consumer class → four golden signals correctly implemented (with percentile latency, separated error latency, and symptom-based paging) provide adequate monitoring coverage for that service.

IF the service has complex consumer tasks, data correctness requirements, multiple consumer classes, or streaming/batch workloads → Stage 1 golden signals are insufficient. Consumer-task failures invisible to latency, error rate, and saturation metrics will not page, and golden signals applied without consumer research will generate false-positive alerts. Advance to Stage 3.

**Why the SRE book's own cases are Stage 1 failure examples:**

The SRE book's Bigtable case (mean latency producing noise) and Gmail case (cause-based alerting on de-scheduled tasks rather than user inability to access Gmail) are exactly the Stage 1 failure modes that Ewerlöf's model predicts. The SRE book documents these as problems to fix; Ewerlöf's model explains why they occur systematically (golden signals without consumer task grounding) and provides the diagnostic ladder for escaping them.

The GitHub 2018 case (no analog in the SRE book) demonstrates the most important Stage 1 limitation: data correctness failures are invisible to all four golden signals. Availability showed green throughout a 24-hour data inconsistency incident. No golden signal — latency, traffic, errors, saturation — would have detected this failure because the service was technically "responding correctly" while consumers received stale and inconsistent data. This gap is not a corner case; it is structural to golden-signal monitoring.

---

## A1 — Past Application

### Case A: Gmail Workqueue — Cause-Based Alerting as Stage 1 Failure (SRE Book, Chapter 6)

- **Problem:** Early Gmail ran on Workqueue, which de-scheduled tasks in ways that generated one alert per de-scheduled task. With thousands of Gmail tasks, this produced thousands of alerts for each scheduler bug. Engineers built a manual "poke" tool to restart tasks — a perfectly rote, algorithmic response.
- **Methodology — Stage 1 failure:** The monitoring system was alerting on causes (de-scheduled tasks) rather than symptoms (users unable to access Gmail). This is exactly what Ewerlöf calls a Stage 1 SLI: internal system state metrics with no consumer task grounding. The rote response was the diagnostic signal — if a human's response to a page is always "run this command," either automate the response or fix the root cause.
- **Conclusion:** Stage 1 monitoring (cause-based) produces alert noise that masks real user-visible failures. The correct monitor is a consumer-task-level SLI: "users can access their Gmail inbox within X seconds."
- **Result:** The case became the canonical illustration that cause-oriented monitoring creates noise while symptom-oriented monitoring catches real incidents.

### Case B: GitHub 2018 Data Inconsistency — the Stage 1 Blind Spot (Ewerlöf, Sli-4-Stage-Evolution)

- **Problem:** GitHub experienced data inconsistency for over 24 hours — users were seeing stale and incorrect repository state. However, the core git service (push, pull, clone) continued to function. A Stage 1 availability SLI (is the service responding?) would have shown green throughout.
- **Methodology — Stage 3 diagnosis:** A Stage 3 SLI would have measured consumer task failure: the task "read consistent state of my repository" was failing, even though the service was technically available. A correctness SLI — "percentage of repository reads returning data consistent with writes completed more than N seconds ago" — would have fired within minutes of the incident beginning.
- **Conclusion:** Data correctness is a consumer task dimension that golden signals cannot measure. Availability, latency, and error rate all show normal values while consumers experience incorrect data.
- **Result:** The prescription is Stage 3 SLI design for services with correctness requirements: identify the consumer task (read consistent data), define the failure mode (data staleness or inconsistency), and build the SLI formula around the task failure, not the system response code.

---

## A2 — Trigger Scenario ★

**Instead of four-golden-signals-monitoring or sli-4-stage-evolution, use this when:** a team has implemented the four golden signals and their on-call is still noisy or missing real incidents — the exact failure that the SRE book says shouldn't happen ("at least decently covered") but Ewerlöf predicts will happen (Stage 1 SLIs produce false positives and false negatives without consumer task grounding).

**Scenario 1:** A team implemented the four golden signals six months ago. Dashboards exist. But on-call engineers describe most pages as noise — the SLI fires when consumers are fine and does not fire when consumers report problems. This is Stage 1 failure. The merged diagnostic: classify each signal against the Stage 1/2/3 criteria to determine whether any signal reflects consumer task failure.

**Scenario 2:** A product manager asks "why does our system look healthy on dashboards but users keep complaining about data being stale?" The golden signals are all green. No golden signal can detect data staleness — this is the GitHub correctness gap. The merged diagnostic prescribes Stage 3 SLI design for the correctness dimension.

**Scenario 3:** A team is designing monitoring for a new service. The SRE book says use the four golden signals. A team member who has read Ewerlöf says golden signals are Stage 1. The merged answer: start with golden signals (correct Stage 1 baseline), then immediately classify the service against the Stage 2/3 criteria. If the service has complex consumer tasks or correctness requirements, advance the SLI design to Stage 3 before implementing on-call alerting.

**Language signals:**

- "We implemented the four golden signals from the SRE book but on-call is still noisy"
- "Our SLI shows 99.9% but users are complaining"
- "We have availability and latency SLIs but they don't capture the real user pain"
- "Our on-call pages are mostly false alarms"
- "The service looks fine but something is clearly wrong"
- "CPU is spiking — should we page on that?" (cause-based alerting instinct)

---

## E — Execution Steps

1. **Implement the four golden signals as Stage 1 baseline.** Measure latency (success and error latency separately, using percentiles — p50/p95/p99 — not mean), traffic (demand context), errors (explicit, implicit, and policy failures as fraction of total requests), and saturation (most-constrained resource, paging threshold below 100% utilization). This provides minimum viable coverage.

2. **Audit existing alerts against the symptom vs. cause distinction.** For each alert rule: is this a symptom (user-visible failure) or a cause (internal system state)? All cause-oriented alerts (CPU, memory, queue depth, connection pool size) are removed from the paging layer and placed in debugging dashboards. Completion criterion: no alert pages on a cause metric.

3. **Classify the current SLI stage.** For each SLI:
   - Stage 1: metric is a golden signal applied without consumer input.
   - Stage 2: consumer has been identified and named; metric is scoped to their usage; no task-level failure analysis.
   - Stage 3: consumer tasks enumerated; failure modes at the usage-task interface identified; metric fires when consumer task fails.
   - Stage 4: each failure has explicit Business Impact; SLI investment prioritized by bottom-line cost.
   If Stage 1 or 2: do not use for on-call alerting. Document as monitoring metric only.

4. **Evaluate whether Stage 3 advancement is required.** For simple request-response APIs with a single identifiable consumer class and no correctness requirements: Stage 1 golden signals may be sufficient. For services with: complex consumer tasks, data correctness requirements, multiple consumer classes, batch/streaming workloads, or any service where users regularly report problems not visible on the dashboard — Stage 3 advancement is required before on-call alerting is worthwhile.

5. **Advance to Stage 3 for on-call-worthy SLIs.** For each consumer class:
   - Identify who actually uses the service and what tasks they use it to accomplish.
   - For each task, identify how the service can fail the consumer: not just response codes, but data correctness, staleness, partial availability, and task-level failures.
   - Construct the SLI formula as `good_task_executions / valid_task_executions`.
   - Completion criterion: at least one task-level failure mode per consumer with a measurable metric that fires when the failure occurs.

6. **Validate on-call worthiness.** For each alert rule, the team must answer: "If this fires at 3am, is it urgent, actionable, and definitely a user-visible failure that cannot wait until morning?" If any alert has a rote algorithmic response, either automate the response or fix the root cause — the page should not exist.

---

## B — Boundary ★

### Failure Patterns from the SRE Book (Four-Golden-Signals)

- Mean-based monitoring that masks tail latency: false-negative alerts for user-impacting events and false-positive alerts for mean fluctuations. The Bigtable case is the canonical example.
- Alert fatigue from cause-based monitoring: paging on CPU, memory, queue depth, and connection pool states that have no direct user-visible consequence. The Gmail case is the canonical example.
- Monitoring complexity accumulating beyond comprehensibility: hundreds of derived metrics and ML-based anomaly detection create systems no one trusts during incidents.
- Rote page responses: if every alert response is a scripted command, either automate the response or fix the root cause.

### Failure Patterns from Ewerlöf (Sli-4-Stage-Evolution)

- Senior engineer resistance: relabeling existing monitoring metrics as SLIs without consumer research produces Stage 1 SLIs with SLO branding but no quality improvement. Alert fatigue follows.
- Premature SLO implementation: implementing SLO tooling and dashboards before completing Stage 2 — copying golden signals without consumer research — produces dashboards that gather dust because the metrics don't reflect consumer harm.
- Alert fatigue from infrastructure-metric SLIs: the operational consequence of remaining at Stage 1 — infrastructure metrics produce frequent alerts that don't correspond to consumer-visible incidents.
- Synthetic SLI masking real consumer failure: a synthetic health-endpoint ping shows green while actual user journeys fail. This is Stage 1 applied without task awareness.

### Synthesis-Specific Failure Mode

**The "SRE book compliance" trap:** A team implements the four golden signals exactly as described in the SRE book — percentile latency, separated error tracking, saturation on the most-constrained resource — and concludes their monitoring is complete because "the SRE book says this is at least decent coverage." They stop at Stage 1 and never conduct consumer research. For services with correctness requirements (like GitHub), complex consumer tasks, or multiple consumer classes, this produces monitoring that shows green while real consumer failures go undetected. The trap is specific to the merged framing: the SRE book validates the implementation; Ewerlöf's stage model exposes the gap. A practitioner reading only the SRE book has no prompt to continue to Stage 3. The harm is invisible until consumers report problems that the monitoring system never surfaced.

### Do Not Use When

- The team has no measurement infrastructure. Instrument the service before designing the monitoring layer.
- The monitoring goal is debugging a known problem. Cause-oriented metrics (CPU, queue depth) are the right tools for debugging — they belong in dashboards, not in the paging layer.
- The team has no SLIs at all. Start with Stage 1 golden signals to establish a baseline; then advance. Do not skip Stage 1 — it provides the historical data needed for Stage 3 calibration.

---

## Related Skills

- **supersedes**: site-reliability-engineering/four-golden-signals-monitoring — use this merged skill when the team needs the full maturity ladder to diagnose why golden signals are producing noise or missing incidents; use the source skill when only the canonical signal definitions are needed as a starting reference
- **supersedes**: reliability-engineering-mindset/sli-4-stage-evolution — use this merged skill when the team needs both the canonical golden signal definitions and the stage maturity diagnosis; use the source skill when only the maturity model classification is needed
- **composes-with**: slo-definition-calibration-framework — Stage 3 SLIs are the correct inputs to SLO target-setting; the definition framework wraps the maturity-advanced SLIs in targets and contracts
- **composes-with**: site-reliability-engineering/on-call-sustainability-model — symptom-oriented Stage 3 SLIs directly reduce alert noise and support the 2-incidents-per-shift sustainability bound
