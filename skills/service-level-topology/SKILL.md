---
name: service-level-topology
description: |
  Use this skill when a team needs to derive meaningful SLIs and SLOs for a service from first principles — starting from system architecture and working through to metrics worth alerting on. The core trigger is a service that has no SLIs yet, has only Stage 1 (vanity/infrastructure) SLIs, or whose SLIs are consistently ignored because they don't map to real consumer failures.

  Call this skill when: (1) You are running or preparing a service level workshop. (2) A team asks "what should our SLI actually measure?" (3) Existing alerts are noisy and generate no meaningful action. (4) There is disagreement about which team owns which metric. (5) An SLO is being set and no one has identified the consumers or their tasks.
tags: [sli, slo, service-topology, consumer-journey, assessment, ownership]
---

# Service Level Topology Assessment (Offer → Use → Risk → Metrics)

## R — Original Text (Reading)

> Good SLIs connect quantify the service from its consumer's perspective. Great SLIs tie that to the business impact.
>
> This graph uses the service level terminology to visualize the service consumption and measurement topology in 4 sections: (1) What offers the service? (2) What uses those services and why? (3) How do those usages fail and what are the symptoms, consequences and business impact of those failures? (4) What metrics can be used to measure those failures?
>
> A good assessment takes quite some time to get right and we highly recommend to have the service consumer in the room to make sure that you understand their goals (tasks), what services they use (usage), and how they perceive failure.
>
> — Alex Ewerlöf, 20250803_112619_service-level-topology.md / 20250827_123438_sli-evolution-stages.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The Service Level Topology assessment is a structured graph-traversal that turns system architecture into a prioritized list of metrics worth alerting on. It works in four sequential sections, each building on the last.

**Section 1 — Offer:** Identify every service provider (backend, database, microservice, hardware) and enumerate the distinct services each one exposes. A service is a capability or feature with a consumer, not an internal component. This step makes explicit what can actually be measured.

**Section 2 — Use:** Identify who consumes each service (end users, other teams, automated processes) and — critically — what tasks those consumers are trying to accomplish. Tasks matter because reliability is only perceived when a task fails. A consumer who cannot complete their task is experiencing unreliability, regardless of what internal metrics report.

**Section 3 — Risks (Usage → Failures):** Model each usage as a node connecting a service to a task. For each usage, enumerate the failure modes from the consumer's perspective. Each failure has three parts: Symptom (how the consumer notices it), Consequence (how it impacts the task), and Business Impact (the bottom-line effect). The number of identified failures per usage node is a visible signal of where risk is concentrated. Triage failures by business impact to avoid instrumenting every theoretical failure mode.

**Section 4 — Metrics:** For each prioritized failure, identify the metric that would detect it earliest. Metrics connect to SLOs, which connect to alerts. An alert on a metric that doesn't measure a consumer-task failure is noise; an alert that does is signal worth waking someone for.

The graph makes the chain visible: provider → service → consumer → task → failure → metric. Responsibility for each metric should only fall on a team that controls the variables driving it.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Front-End Team Blamed for Latency They Cannot Control (C09)

- **Problem:** In a mobile/backend/database architecture, stakeholders blamed the mobile team every time end-to-end latency was bad — even though the mobile team had no control over backend or network latency components.
- **Application:** The topology graph decomposed user-perceived latency into its contributing segments: mobile processing time, network latency (uncontrollable), and backend response time. Each segment was traced to the team that owned it. The latency budget (500ms target minus 131ms uncontrollable network latency) was then allocated between mobile and backend as separate SLOs.
- **Conclusion:** Holding one team responsible for a metric that aggregates variables owned by other teams produces misdirected blame and misdirected optimization. The topology assessment makes ownership gaps visible before metrics are set.
- **Result:** Three allocation options were produced (fix mobile, fix backend, share equally) and the correct answer depended on which team had more headroom. The point is that this negotiation became possible only after decomposing the topology.

### Case 2: GitHub 2018 Data Inconsistency — Degradation Without Disruption (C13)

- **Problem:** GitHub experienced a 24-hour data consistency degradation in 2018. Because core git capabilities (push, pull, clone) continued working, the service was technically available — but consumers experienced incorrect data.
- **Application:** A topology-grounded SLI would have identified "data correctness" as a consumer task failure mode distinct from availability. The Usage node connecting the git service to the consumer task of "viewing current repository state" would have surfaced this failure type in Stage 3 or 4.
- **Conclusion:** Stage 1 availability-only SLIs completely missed this incident. Only task-aware SLI design would have detected the error budget burn.
- **Result:** 24 hours of consumer-facing degradation went undetected by conventional monitoring, demonstrating the direct cost of stopping at Stage 1.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A team is setting up SLOs for the first time and doesn't know which metrics to use or how to tie them to consumers.
2. An on-call team is drowning in alerts that turn out not to correspond to real consumer impact — and needs to audit and replace existing SLIs.
3. Two teams are arguing over who should own an alert for an end-to-end metric that aggregates both their services.

### Language Signals (Activate When These Appear)

- "We monitor availability and latency but no one looks at the dashboards"
- "We don't really know who uses our service"
- "Our alerts fire all the time but most of them aren't real incidents"
- "We don't know what to put as our SLI"
- "Which team should own this metric?"

### Distinguishing from Adjacent Skills

- Difference from `sli-evolution-stages` (f02): The topology graph is the structural method for *deriving* SLIs from scratch; the evolution stages model is used to *assess the maturity* of an already-existing SLI and determine how to improve it.
- Difference from `slo-definition-calibration-framework`: This skill derives *what to measure*; `slo-definition-calibration-framework` calibrates *how high to set the target* once the right metric is identified.
- Difference from `fit-practice`: This skill addresses the technical methodology of SLI derivation; `fit-practice` is about evaluating whether an externally-sourced practice applies to the current context.

______________________________________________________________________

## E — Execution Steps

1. **Assemble the participants**

   - Who: the service team, at least one representative of each consumer type (end user proxy, downstream team engineers).
   - Completion criteria: At least one consumer is in the room or has provided written input. The assessment does not proceed with assumptions only.

2. **Map Section 1 — Offer**

   - List all service providers in scope.
   - For each provider, list the distinct services it exposes (not internal components — externally-consumable capabilities).
   - Completion criteria: Every service can be stated as "[Provider] offers [capability] to [consumer]."

3. **Map Section 2 — Use**

   - For each service, identify the consumers.
   - For each consumer, list the tasks they accomplish using the service. Ask: "Why do they come here? What does success look like for them?"
   - Completion criteria: Every consumer has at least one task documented. Tasks are stated from the consumer's perspective, not the system's.
   - Stop condition: If the team cannot identify any consumers, they are likely measuring a service provider, not a service. Return to step 2 and confirm what the consumer-facing capability actually is.

4. **Map Section 3 — Risks (Usages and Failures)**

   - For each (service, task) pair, create a usage node.
   - Enumerate failure modes at each usage: how can the service fail to support this task?
   - For each failure, record: Symptom (how the consumer notices), Consequence (effect on the task), Business Impact (bottom-line effect, even if approximate).
   - Triage failures by business impact. Select the top failures to instrument.
   - Completion criteria: Each selected failure has all three fields populated. Low-impact failures are explicitly deprioritized, not ignored.

5. **Map Section 4 — Metrics**

   - For each prioritized failure, identify the metric that would detect it. Prefer organic consumer-side signals over synthetic probes.
   - Verify ownership: is the metric controlled by the team who will be alerted on it? If not, either decompose the metric or fix the ownership boundary before proceeding.
   - Completion criteria: Each metric has an identified owner, a measurement method, and a direct mapping to a specific consumer failure.

6. **Produce the SLO draft**

   - For each metric, propose a threshold and compliance window. Validate against current measurements and consumer tolerance. (Lagom SLO calibration applies here.)
   - Completion criteria: Each SLO candidate is documented with the consumer failure it measures and the team accountable for it.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The team already has Stage 3 or Stage 4 SLIs and needs calibration work rather than derivation. Use `slo-definition-calibration-framework` calibration instead.
- The question is about composite SLO math across known dependencies — that is a `composite-slo` problem, not a topology derivation problem.
- The team needs to explain the *cost* of adding another nine to leadership — use the `10x/9` cost framework.
- There is no identifiable consumer: internal infrastructure components (shared job queues, internal caches) without named consumers should first confirm the service definition before topology work.

### Failure Patterns Warned by the Author

- **Stage 1 cargo-culting:** Reading the SRE book, picking golden signals (latency, traffic, errors, saturation), and calling them SLIs without ever speaking to consumers. The topology assessment is the antidote, but only if consumers are genuinely in the room.
- **Responsibility misalignment:** Assigning an end-to-end SLI to a team that controls only one segment. The topology makes it easy to accidentally create this pattern if the ownership step (step 5) is skipped.
- **Business impact inflation:** Teams sometimes list every conceivable failure mode, inflating the assessment scope. Explicit triaging by business impact is required.

### Author's Blind Spots / Limitations

- The methodology assumes the team can identify and access their consumers. For purely internal platform services or infrastructure components without clear consumer teams, "consumer" can be ambiguous or politically contested.
- Business impact quantification is described as "we don't have to be scientific here, as long as failures are sorted" — this is intentionally hand-wavy and will be insufficient for contexts that require rigorous cost justification.
- The framework targets Staff+ and SRE practitioner audiences. Teams without organizational access to downstream consumers (e.g., B2B contexts with privacy-constrained customers) will need proxy methods not covered by the source material.

### Easily Confused With

- **Traditional monitoring:** The topology assessment produces consumer-grounded SLIs; traditional monitoring instruments internal system vitals. The outputs look similar (both produce metrics and alerts) but the derivation path is fundamentally different.
- **Incident severity frameworks:** Both try to quantify business impact. The topology assessment uses business impact to *prioritize which metrics to set*; incident severity frameworks use it to *prioritize response during a live incident*. The author notes they are related but serve different decision moments.

______________________________________________________________________

## Related Skills

- **composes-with** → `sli-monitoring-design-maturity`: The topology methodology is the structural scaffold for Stage 3 and Stage 4 SLI design; traversing Offer→Use→Risk→Metrics is how you identify consumer tasks and failures.
- **composes-with** → `sli-compass`: The topology identifies which SLIs to derive; the compass evaluates how to instrument them and guides the fidelity/granularity investment.
- **composes-with** → `consumer-journey-org`: The consumer journey is the starting point for the topology's Use section; consumer-journey-org determines which topology to draw, while topology provides the SLI derivation methodology.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Reliability Engineering Mindset" by Alex Ewerlöf
