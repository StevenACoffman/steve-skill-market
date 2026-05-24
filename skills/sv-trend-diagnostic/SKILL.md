---
id: sv-trend-diagnostic
title: Schedule Variance Trend Diagnostic
description: Invoke when a project is reporting EVM Schedule Variance (SV) that is negative, flat, or worsening and the team or stakeholders are treating it as a status data point rather than a corrective trigger. Specifically useful when SV has been consistently negative across multiple reporting periods without a visible corrective response, or when a PM needs to diagnose *why* a program is not recovering despite visible schedule pressure.
source: Project Management Research and the Critical Path, Nicole Williams, 2026
---

## R — Reading

> "EVM was designed as a control system. A control system that receives a feedback signal and takes no corrective action is not a control system. It is a measurement system wearing a control system's name badge."

*Source: 20260503_schedule-variance-as-a-signal-not (main framework post); organizational suppression pattern at p07; EVM control system framing at p26*

## I — Interpretation

Schedule Variance is almost always treated as a performance score — a number on a dashboard that tells you how behind you are. This framework reframes it as a feedback signal in a control system. The distinction matters: a score invites explanation; a signal demands a response. When SV is negative and nothing changes, the problem is not the number — it is that the feedback loop is not closing.

The framework introduces three trend patterns that carry distinct diagnostic meaning. An improving trend (SV is negative but narrowing week-over-week) means the feedback loop is functioning — the organization is receiving the signal and correcting. A stable-negative trend (SV is consistently negative and flat) means the signal is being received but not acted on — something is blocking the corrective pathway. A worsening trend (SV is negative and deepening) means the feedback loop is broken: the system is not correcting at all.

The more important insight is what Williams calls corrective pathway health. When a program fails to correct deteriorating SV, the reason is almost never missing technical capability. The corrective options typically exist: resequencing, reallocation, scope renegotiation. What is absent is corrective permission. The pathway is blocked, usually by one of three organizational forces: surfacing the trend would establish a failure narrative that no one wants to own; sponsors resist the conversations that corrective action would require; PMOs satisfy reporting compliance without creating the conditions for action. The measurement gets filed, the narrative stays recoverable, and six months later the program ends in failure that was visible in trend data all along.

Meadows identified information flows as a high-leverage intervention point in complex systems — not because changing them is easy, but because they determine what the system can respond to. A program with broken corrective pathways is not missing a PM tool. It is missing the structural conditions for information to trigger action. This framework makes that structural diagnosis explicit so the right problem can be named.

## A1 — Past Application

Williams documents a pattern she calls the c15 case: a near-universal finding across her research programs. SV is measured, noted in status decks, explained as recoverable, acknowledged by sponsors, and filed. No corrective action is triggered. The explanation is always some variant of "we have a plan." The plan does not materialize into changed work. Programs routinely reach the final 20% of their timeline still carrying the same SV gap they had at 50%, with recovery now mathematically impossible. In retrospect, the failure was visible six months before deadline in the trend data that everyone had seen and none had acted on.

The diagnostic power of this case is not the outcome — late programs are common. It is the pattern: the measurement system was functioning, the data was present, and the corrective loop was structurally absent. The program had EVM; it did not have a control system.

## A2 — Future Trigger ★

- A PM is preparing a schedule status report and SV has been negative for four consecutive periods. Before presenting it as "we're tracking to recover," this skill applies to assess whether the trend is improving, stable-negative, or worsening — and what that pattern says about whether recovery is actually occurring.
- A PMO director is reviewing a program portfolio and multiple programs are showing flat negative SV. The programs all have recovery plans. This skill applies to determine whether those recovery plans represent genuine corrective action or compliance theater.
- A program is approaching a major milestone and the sponsor is asking whether the team "has a handle on it." SV has been worsening for six weeks. This skill applies to prepare an honest assessment of whether the feedback loop is functioning before the conversation happens.
- A post-mortem is underway on a late program. The retrospective is focused on what went wrong technically. This skill applies to reframe the question: was the corrective pathway healthy, and if not, what organizational forces were blocking it?
- An executive is evaluating whether to invest in a new EVM tooling system. The current programs are not recovering despite having EVM data. This skill applies to diagnose whether the problem is tool quality or pathway health — because better tooling will not fix a blocked corrective pathway.

## E — Execution

1. **Collect the SV trend series.** Pull at least 6 consecutive reporting periods of SV data. Raw numbers are required — a single current-period SV tells you nothing about trend.

2. **Classify the trend pattern.** Plot or inspect the series:

   - SV is negative AND the magnitude is decreasing week-over-week → Improving trend
   - SV is negative AND the magnitude is approximately flat (within ±10% variance) → Stable-negative trend
   - SV is negative AND the magnitude is increasing week-over-week → Worsening trend

3. **Assess corrective pathway health.** For each of the three blocking forces, ask the diagnostic question:

   - *Failure narrative suppression:* Has the trend been characterized in status reports as "recoverable" or "being managed" without quantified corrective commitments? If yes, the narrative pathway is blocked.
   - *Sponsor avoidance:* Have corrective options (resequencing, reallocation, scope renegotiation) been identified but not brought to the sponsor for decision? If yes, the authority pathway is blocked.
   - *PMO compliance loop:* Is the SV being reported, acknowledged, and filed without generating a formal corrective action item with owner and due date? If yes, the process pathway is blocked.

4. **Match trend pattern to pathway diagnosis:**

   - Improving trend + pathway appears open → control system is functioning; monitor
   - Stable-negative trend → one or more pathways are blocked; identify which
   - Worsening trend → multiple pathways are blocked or pathway has been blocked long enough that corrective options are now exhausted; escalate the structural diagnosis

5. **Name the structural problem explicitly.** The output is not "we need to recover schedule." It is a specific statement: "We have a [improving/stable-negative/worsening] SV trend. The corrective pathway is blocked at [failure narrative / sponsor authority / PMO process]. The corrective options that exist are [X, Y, Z]. What is absent is corrective permission."

6. **Separate the diagnostic output from the political navigation.** This framework tells you what is broken and names it precisely. How to open the pathway is a separate problem requiring organizational read and stakeholder strategy — do not conflate the two.

## B — Boundary

- **Not applicable to Agile or sprint-based programs** where EVM is not used. Velocity, burn-down, and cycle time have their own feedback loop diagnostics. Do not translate this framework onto those metrics by analogy.
- **Requires an EVM baseline.** If no performance measurement baseline exists, there is no SV to trend. The framework does not apply; the prior problem is getting measurement in place.
- **Does not diagnose how to navigate the blocked pathway.** This skill identifies where the pathway is blocked and names the organizational force. It does not prescribe how to bring a reluctant sponsor into a corrective conversation, how to reframe a failure narrative, or how to create PMO process that triggers action. That is a stakeholder influence and organizational change problem, not a trend diagnostic problem.
- **Not reliable in the first 15% of a program's timeline.** SV in early phases reflects start-up variance, ramp-up effects, and baseline uncertainty rather than systemic feedback loop failure. Trend classification requires the program to have stabilized into its execution rhythm.
- **Does not predict when failure will occur.** A worsening trend indicates that failure is likely; it does not specify the crossing point. Corrective urgency must be assessed separately based on remaining float, critical path slack, and contractual milestones.

## Related Skills

- **[program-governance-ecological-design](../program-governance-ecological-design/SKILL.md)** — *informs*: SV suppression is a symptom of the interaction layer being unowned; ecological design addresses the structural cause
- **[emergence-conditions-audit](../emergence-conditions-audit/SKILL.md)** — *compares*: both diagnose feedback loop dysfunction at the program level, different entry points
