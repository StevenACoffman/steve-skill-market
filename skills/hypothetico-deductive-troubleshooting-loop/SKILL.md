---
name: hypothetico-deductive-troubleshooting-loop
description: |
  Use this skill when an engineer is responding to a production incident, alert, or system anomaly and must determine its root cause. The framework imposes a four-phase discipline: (1) Triage — stop the bleeding before root-causing; (2) Examine — gather telemetry and logs to understand current state; (3) Diagnose — form ranked hypotheses from evidence; (4) Test — seek disconfirming evidence before treating.

  Call this skill whenever an on-call or incident response situation requires systematic diagnosis. The key trigger is the impulse to act before examining: when an engineer says "let's just roll back the last deploy" or "this looks like the X problem we had last week," the loop has been skipped.

  Do not call this skill when the mitigation is obvious from monitoring (e.g., a known alert with an established playbook — use the playbook skill instead), or when triage dictates immediate action to prevent data loss before any diagnosis is possible.
tags: [troubleshooting, incident-response, debugging, on-call, diagnosis, root-cause-analysis]
---

# Hypothetico-Deductive Troubleshooting Loop

## R — Original Text (Reading)

> Formally, we can think of the troubleshooting process as an application of the hypothetico-deductive method: given a set of observations about a system and a theoretical basis for understanding system behavior, we iteratively hypothesize potential causes for the failure and try to test those hypotheses.
>
> Your first response in a major outage may be to start troubleshooting and try to find a root cause as quickly as possible. Ignore that instinct! Instead, your course of action should be to make the system work as well as it can under the circumstances... Stopping the bleeding should be your first priority; you aren't helping your users if the system dies while you're root-causing.
>
> Common pitfalls: latching on to causes of past problems, reasoning that since it happened once, it must be happening again. Hunting down spurious correlations that are actually coincidences or are correlated with shared causes.
> — Google SRE, Chapter 12: Effective Troubleshooting

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The troubleshooting loop has four distinct phases that must be executed in order, not skipped or merged.

**Triage first.** Before any diagnosis, assess user impact and take whatever mitigation makes the system work better right now — traffic diversion, load shedding, disabling subsystems. This is not avoidance of root-causing; it is the correct priority ordering. You cannot help users while the system is dying.

**Examine second.** Gather the system's current state through telemetry, logs, and distributed traces. Time-series graphs expose when behavior changed. Cross-component tracing exposes where a request degrades. Do not form hypotheses before completing this step.

**Diagnose third.** Generate ranked hypotheses from evidence, ordered by prior probability. Prefer simpler explanations. Remember that not all failures are equally likely — common failures are common. The pitfall here is confirmation bias: an alert that fired three times last week for reason X does not mean this week's alert has the same cause.

**Test before treating.** Actively seek disconfirming evidence. Compare system state against each hypothesis. If you can make a controlled change and observe the result without causing collateral damage, do so. Only after a hypothesis survives disconfirmation attempts should you treat.

The critical non-obvious step: the loop requires you to try to prove your hypothesis wrong before acting on it. Under incident stress, engineers skip directly from "hypothesis" to "treatment," which prolongs incidents when the hypothesis is incorrect.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: App Engine Latency Mystery (C11)

- **Problem:** An internal App Engine customer reported a latency spike across all endpoints, including static content served from memory. Initial hypotheses (traffic spike, infrastructure change, suboptimal datastore indexing) were all plausible and were pursued first.
- **Application:** The team applied the loop: triage (increase instance resources to allow the scheduled launch to proceed), examine (Dapper distributed tracing across the full RPC stack), diagnose (static-content slowness ruled out indexing — each hypothesis progressively narrowed the cause space), test (code inspection to find memory-local behavior).
- **Conclusion:** The actual cause — a security scanner had triggered a whitelist cache bug, creating thousands of superfluous database objects — was invisible to standard tracing. It was discovered only after exhausting all other hypotheses systematically.
- **Result:** Root cause found and mitigated. The case demonstrates that symptom-to-cause distance can be large and that skipping the systematic loop would have led the team to spend weeks on incorrect hypotheses.

### Case 2: Shakespeare Black-Box Probe Failure (Book Chapter 12 Worked Example)

- **Problem:** On-call engineer receives `ShakespeareBlackboxProbe_SearchFailure` — search results unavailable for five minutes.
- **Application:** The book walks through the full loop explicitly: triage (assess scope — is this one user or all users?), examine (check serving logs, frontend errors, backend errors, dependency status), diagnose (form hypotheses ranked by component proximity to the symptom), test (compare each layer's health against the expected state before changing anything).
- **Conclusion:** The worked example demonstrates that reverting the most recent deployment without examining logs first would be incorrect — the cause might be a dependent service regression, a traffic shift, or a data issue.
- **Result:** The loop produces a correct diagnosis regardless of the actual cause, whereas an intuitive "rollback first" approach succeeds only when the most recent deployment happens to be guilty.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: The "same problem as last time" shortcut**
An on-call engineer receives a payment service error-rate alert. The alert fired three days ago and was resolved by restarting the cache layer. The engineer's first instinct is to restart the cache layer again.
_Language signals:_ "This is probably the same thing as..." / "We've seen this before, just..." / "Last time we had this alert it was..."
_Apply the loop:_ Triage (is the error rate still climbing?), Examine (are cache metrics actually anomalous this time?), Diagnose (form hypotheses — cache, upstream, database, traffic shift), Test (look for disconfirming data before restarting cache).

**Scenario 2: The correlated-but-unrelated symptom**
A deployment happened 2 hours ago. An unrelated database alert fires. The team assumes the deployment caused the database issue.
_Language signals:_ "The deploy must have..." / "It started right after we pushed..."
_Apply the loop:_ Examine database telemetry independently of the deployment timeline. Correlation is not causation — confirm that the deployment touched code paths exercised by the database workload.

**Scenario 3: The instinct to roll back**
An engineer proposes rolling back a 3-day-old configuration change because it's the most recent change.
_Language signals:_ "Let's just roll back while we investigate" / "Rolling back can't hurt."
_Distinguishing from adjacent skills:_ If a playbook explicitly prescribes rollback for this alert, use the playbook (playbook-as-mttr-reduction). If no playbook exists, do not roll back before the Examine phase — rolling back an innocent change delays finding the real cause and introduces new change risk.

______________________________________________________________________

## E — Execution Steps

1. **Triage (complete before step 2):** Quantify user impact (how many users, which operations, what degradation level). Apply the smallest mitigation that stops the bleeding — traffic diversion, feature disable, capacity increase. Preserve evidence (snapshot logs, trace samples) for subsequent root-cause analysis. Completion criterion: system is no longer actively degrading users at the current rate, or you have confirmed no immediate mitigation is available.

2. **Examine and Diagnose:** Pull telemetry for the four golden signals (latency, traffic, errors, saturation) at each system layer. Identify the layer where behavior first diverges from expected. Generate 2–4 ranked hypotheses ordered by prior probability. For each hypothesis, identify what observable evidence would disprove it. Completion criterion: you have at least one hypothesis with identified confirming and disconfirming evidence.

3. **Test and Treat:** For each hypothesis (highest-probability first), seek disconfirming evidence — check the observable state that the hypothesis predicts exists. Only when a hypothesis survives disconfirmation should you apply treatment. Document each test and its result in the incident document in real time. Completion criterion: a hypothesis has survived disconfirmation and treatment has been applied; schedule postmortem.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- A well-tested playbook already prescribes the mitigation for this exact alert — follow the playbook (playbook-as-mttr-reduction skill). The loop is for novel or complex incidents.
- The triage step determines that immediate action (e.g., freeze to prevent unrecoverable data corruption) must happen before any examination is possible. Act first, then start the loop from Examine.
- The incident is fully within the scope of the incident-management-role-separation skill — use that to structure the team response; the troubleshooting loop applies to the individual Ops Lead's work within that structure.

**Failure patterns:**

- Jumping from Observe directly to Treat, skipping hypothesis formation and testing. Results in treatments applied to wrong causes, which both delay resolution and introduce new changes.
- Running hypothesis tests that are not safe to perform under production load (e.g., testing a theory by making a production configuration change without rollback). The test must not cause collateral damage.
- Applying the loop individually when the incident requires coordinated team action — use incident-management-role-separation to ensure only the Ops Lead is making system changes while others run the loop.

**Author blind spots:**

- The framework assumes engineers have deep system knowledge to form valid hypotheses. Teams with shallow familiarity with a system cannot apply step 3 effectively — playbooks and architecture docs must compensate.
- Written for Google-scale systems with rich telemetry infrastructure (Dapper, Borgmon, structured logs). Teams with minimal observability cannot complete the Examine step reliably.
- The 2016 text does not address how the loop applies to distributed systems where causality is non-local and where distributed traces may not exist.

**Easily confused with:**

- **Playbook-as-MTTR-reduction:** Use the playbook when one exists for the alert. Use the troubleshooting loop when no playbook applies or when the playbook's treatment has not resolved the issue.
- **Incident-management-role-separation:** Role separation governs who does what during a team incident. The troubleshooting loop governs how the Ops Lead diagnoses within their role.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: four-golden-signals-monitoring (Examine step requires golden signal telemetry)
- contrasts-with: playbook-as-mttr-reduction (playbook replaces the loop for known failure modes)
- composes-with: incident-management-role-separation (the loop is the Ops Lead's inner method within the IC framework)
- composes-with: blameless-postmortem-process (the loop's documented output becomes the postmortem timeline)

______________________________________________________________________

## Related Skills

- **depends_on**: four-golden-signals-monitoring — the Examine phase requires golden signal telemetry (latency, traffic, errors, saturation) to generate valid hypotheses
- **contrasts_with**: playbook-as-mttr-reduction — a playbook replaces the loop for known, previously-solved failure modes; the loop applies when no playbook exists or when the playbook's prescribed steps do not match observed symptoms
- **composes_with**: incident-management-role-separation — the loop is the Ops Lead's inner diagnostic method within the IC's coordination structure
- **composes_with**: blameless-postmortem-process — the loop's documented test-and-disconfirm record becomes the incident timeline in the postmortem

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Site Reliability Engineering" by Betsy Beyer et al. (Google) — Chapter 12: Effective Troubleshooting
