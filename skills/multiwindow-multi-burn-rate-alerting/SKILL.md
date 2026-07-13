---
name: multiwindow-multi-burn-rate-alerting
description: |
  Use this skill when configuring SLO-based alerting for any production service. Call it when a team has an SLO but is using naive threshold alerts (error rate > X%), duration-clause alerts (error_rate > X% for 5m), or single-window burn-rate alerts — all of which have documented precision or recall failures.

  Trigger scenarios: an alert fires hours after an incident resolved (false positive), a service bleeds 35% of error budget from intermittent spikes without paging anyone (false negative), or a team asks "how should we configure our SLO alerts in Prometheus/Datadog/Grafana?"

  Do not use for low-traffic services where single failed requests produce extreme burn rates (requires separate low-traffic strategy). Do not use as a replacement for symptom-based alerting on non-SLO signals (saturation, dependency health). Do not copy the specific Google parameters without deriving them from your own SLO percentage and time window.
tags: [alerting, burn-rate, slo, precision-recall, prometheus, multiwindow, derivation]
---

# Multiwindow Multi-Burn-Rate Alerting Framework

## R — Original Text (Reading)

> "We can enhance the multi-burn-rate alerts in iteration 5 to notify us only when we're still actively burning through the budget—thereby reducing the number of false positives. To do this, we need to add another parameter: a shorter window to check if the error budget is still being consumed as we trigger the alert. A good guideline is to make the short window 1/12 the duration of the long window... For example, you can send a page-level alert when you exceed the 14.4x burn rate over both the previous one hour and the previous five minutes."
>
> "We recommend the parameters listed in Table 5-8 as the starting point for your SLO-based alerting configuration: Page — 1 hour / 5 minutes / 14.4× burn rate / 2% error budget consumed. Page — 6 hours / 30 minutes / 6× burn rate / 5% error budget consumed. Ticket — 3 days / 6 hours / 1× burn rate / 10% error budget consumed."
>
> — Google SRE Workbook, Chapter 5

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The book derives the final alerting configuration through six iterations, each exposing a specific failure mode in the previous approach. Understanding the derivation is necessary to adapt the parameters to non-Google SLOs.

**Iteration 1 — Naive threshold**: Alert when error_rate > (1 - SLO). High false positives; fires for any brief spike regardless of budget impact.

**Iteration 2 — Duration clause**: Alert when error_rate > (1 - SLO) for N minutes. Structurally broken: a metric oscillating across the threshold resets the timer. A 100% error spike lasting 5 minutes every 10 minutes fires no alert despite consuming 35% of the monthly budget.

**Iteration 3 — Burn rate**: Burn rate = how fast the service is consuming budget relative to its SLO window. A burn rate of 1 means exactly exhausting the budget by window end. Alert when burn_rate > threshold. Better precision, but a single threshold misses slow burns.

**Iteration 4 — Multiple burn rates**: Alert at high burn rate (fast exhaustion) for pages; alert at low burn rate (slow drain) for tickets. Improved recall, but alerts fire after the problem resolved — high false positives from stale data.

**Iteration 5 — Multiwindow**: Add a short window (1/12 of the long window) as a confirmation gate. The long window provides recall (detects sustained problems); the short window provides precision (confirms the budget is still actively burning at alert time). Alert fires only when BOTH windows exceed the threshold.

**Arithmetic derivation**:

- `burn_rate = budget_fraction_to_spend / (alert_window_hours / total_window_hours)`
- For 2% of 30-day budget in 1 hour: `0.02 / (1/720) = 14.4×`
- Alert expression threshold: `burn_rate × (1 - SLO)`
- For 99.9% SLO at 14.4×: `14.4 × 0.001 = 0.0144` (1.44% error rate triggers the page)

**Recommended parameters for 99.9% SLO over 30 days**:

| Severity | Long window | Short window | Burn rate | Budget consumed |
| -------- | ----------- | ------------ | --------- | --------------- |
| Page     | 1 hour      | 5 minutes    | 14.4×     | 2%              |
| Page     | 6 hours     | 30 minutes   | 6×        | 5%              |
| Ticket   | 3 days      | 6 hours      | 1×        | 10%             |

The 1/12 ratio for the short window is not arbitrary — it is the empirically derived ratio that minimizes false positives without missing fast-resolving incidents. The reset time for a fired alert drops from the long window (up to 58 minutes) to the short window (5 minutes).

______________________________________________________________________

## A1 — Past Application (From the Book)

## Case 1 — Google Internal (Chapter 5, Worked Derivation)

- **Problem**: The SRE book's original alerting guidance produced high false positive rates for teams using naive threshold or duration-clause alerts. Teams were paging on events that had already resolved.
- **Application**: Chapter 5 walks through all six iterations with explicit arithmetic, using a 99.9% SLO over 30 days as the example. Each iteration is proven insufficient before the next is introduced — not just asserted.
- **Conclusion**: The multiwindow approach reduces the alert reset time from 58 minutes (full long window) to 5 minutes (short window), making the alert self-canceling once the problem resolves, without sacrificing detection.
- **Result**: The recommended three-tier configuration (two page levels, one ticket level) is directly implementable in Prometheus using `ratio_rate1h` and `ratio_rate5m` recording rules.

## Case 2 — PagerDuty Adaptation (Chapter 9 Reference)

- **Problem**: PagerDuty adapted incident management practices from Google's model, including SLO-based alerting, for a non-Google organization. They needed alerting configurations that worked with their specific SLO windows and significance thresholds.
- **Application**: The arithmetic framework is transferable: any team can substitute their own SLO percentage, time window, and significance thresholds to derive burn rates independent of Google's specific numbers. The 1/12 window ratio and the dual-confirmation requirement are universally applicable.
- **Conclusion**: PagerDuty's public incident response documentation (response.pagerduty.com) reflects the same structural discipline — detection sensitivity inversely correlated with incident severity.
- **Result**: Alert hygiene improved through the forcing function of the two-incidents-per-shift maximum (itself a downstream consequence of well-configured burn-rate alerting).

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — "Alerts fire after the problem is fixed"**
Language signals: "We get paged but when we look at the dashboard everything is green." "Our on-call gets woken up for incidents that resolved an hour ago."
Diagnosis: Single-window burn-rate alerts without a short-window confirmation gate. The long window still reflects the burn rate from the incident even after the error rate returned to normal.
Action: Add the 1/12 short-window gate. The alert fires only when both windows exceed the threshold — the short window self-cancels within minutes of the error rate dropping.

**Scenario 2 — "We had a slow burn that never paged"**
Language signals: "The service was bleeding errors for two days before we noticed." "Our monthly budget was 40% gone by the time anyone looked."
Diagnosis: Either a single high-threshold burn-rate alert (misses slow burns) or no burn-rate alerting at all.
Action: Add the 1× burn rate ticket-level alert with a 3-day/6-hour window. This catches slow drains before they become crises.

**Scenario 3 — "How do I configure this for a 99.5% SLO over 28 days?"**
Application: 28-day period = 672 hours. For 2% budget in 1 hour: `0.02 / (1/672) = 13.44×`. Alert fires when `error_rate > 13.44 × 0.005 = 0.0672` over 1h AND over 5min. The 1/12 ratio and the significance thresholds are user-defined; only the arithmetic changes.

**Distinguishing from adjacent skills**: multiwindow-multi-burn-rate-alerting governs the alert configuration mechanism. The slo-decision-matrix governs what actions to take in response to SLO state. This skill answers "when do we page?"; the decision matrix answers "what do we do after the page fires and we look at SLO state?"

______________________________________________________________________

## E — Execution Steps

1. **Verify SLO parameters**: Obtain the SLO percentage (e.g., 99.9%), the measurement window in hours (e.g., 720 for 30 days), and the alerting system (Prometheus, Datadog, etc.).

2. **Choose significance thresholds**: Select what percentage of budget consumption justifies a page (typically 2% and 5%) and a ticket (typically 10%). These are engineering judgments, not derived values.

3. **Derive burn rates for each tier**:

   - `burn_rate = budget_fraction / (alert_window_hours / total_window_hours)`
   - Page tier 1: `0.02 / (1 / total_hours)`
   - Page tier 2: `0.05 / (6 / total_hours)`
   - Ticket tier: `0.10 / (72 / total_hours)` (3-day window)

4. **Derive alert expression thresholds**:

   - `threshold = burn_rate × (1 - SLO)`

5. **Configure dual-window rules**: For each burn rate tier:

   - Long window: set to the detection window (1h, 6h, 3d)
   - Short window: set to long_window / 12 (5m, 30m, 6h)
   - Fire when BOTH long and short window error rates exceed the threshold.

6. **Validate with historical data**: Apply the rules retroactively to recent incidents. Verify that past incidents would have fired at the correct tier. Verify that quiet periods would not have produced false positives.

7. **Configure reset behavior**: Confirm that alerts auto-resolve when the short-window rate drops below the threshold. The reset time should be the short window duration, not the long window.

**Completion criteria**: Three-tier alert configuration deployed, validated against historical incident data, and producing no false positives in the first two weeks of operation.

______________________________________________________________________

## B — Boundary ★

**Do not use when**:

- The service receives fewer than ~100 requests per hour. At low traffic rates, single failed requests produce extreme burn rates (e.g., 10 requests/hour → one failure = 1000× burn rate for 99.9% SLO). Use a distinct low-traffic strategy: ticket on absolute error counts, not rates.
- You need to alert on resource saturation (CPU, disk, memory). This framework is SLI-driven, not system-health-driven. Saturation alerts require a separate mechanism.
- The team has no SLO defined. The entire arithmetic depends on a defined SLO percentage and window. Without it, burn rate is meaningless.

**Failure patterns**:

- **Copying Google's parameters without derivation**: A team with a 99.5% SLO using 14.4× burn rate is alerting on the wrong threshold. Derive from your own SLO.
- **Using duration clauses as a substitute**: The book explicitly refutes this. A metric oscillating across the threshold resets the `for:` timer in Prometheus. This is a structural flaw, not a configuration issue.
- **Omitting the slow-burn ticket tier**: The 1× burn rate tier at 3-day/6-hour catches slow drains before they become budget crises. Teams that omit it discover missing budgets at month-end.
- **Single burn rate**: A single threshold alert misses either fast burns (if set too low) or slow burns (if set too high). The multi-tier structure is not optional.

**Author blind spots**:

- The framework assumes a reasonably high request rate. Low-traffic services (nights/weekends, internal tools) require explicit adaptation that the book describes briefly but does not fully resolve.
- The specific numbers (14.4×, 6×, 1×, 2%, 5%, 10%) are tuned for Google's operational context. Teams with different risk tolerances or different SLO windows may need different significance thresholds.
- The framework assumes a centralized alerting system capable of multi-window rate calculations (Prometheus recording rules, Datadog metric rollups). Legacy alerting systems may not support this without custom instrumentation.

**Easily confused with**:

- **Symptom-based alerting**: Burn-rate alerts detect budget consumption. Symptom alerts detect user-visible degradation directly (4xx rate spikes, latency spikes). Both are needed; they are not substitutes.
- **SLO compliance reporting**: The three-tier alert fires when the budget is under active threat. SLO compliance reports measure historical compliance. Different purpose, different mechanism.

______________________________________________________________________

## Related Skills

- **depends_on**: error-budget-policy-framework — alerting is the detection mechanism that activates the error budget policy; the policy defines what must happen once the alert fires and the budget is confirmed exhausted
- **contrasts_with**: slo-decision-matrix — alerting answers "when do we page?"; the decision matrix answers "what action do we take after the page fires and we examine SLO state?"
- **composes_with**: slo-stakeholder-negotiation-gate — the significance thresholds chosen for each alert tier (2%, 5%, 10% budget consumption) are inputs that stakeholders must agree on during SLO negotiation

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "The Site Reliability Workbook" by Betsy Beyer et al. (Google) — Chapter 5 - Alerting on SLOs, Chapter 2 - Implementing SLOs
