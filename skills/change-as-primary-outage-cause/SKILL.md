---
name: change-as-primary-outage-cause
description: |
  Use this skill when designing a release or deployment process, when a team is experiencing frequent production outages of unclear origin, or when management is debating change control policies (change freezes, approval gates, deployment windows).

  The framework begins from the empirical finding that approximately 70% of production outages originate from changes in a live system — config, code, or traffic changes. The engineering response is not to prohibit change but to make every change smaller, slower, more observable, and more reversible. Progressive rollouts, canarying, and automatic rollback are the primary instruments.

  Key trigger signal: a team proposes a change freeze as a reliability strategy, or a team has frequent outages but blames hardware, external systems, or bad luck rather than examining their change management process.
tags: [change-management, progressive-rollout, canarying, rollback, release-engineering, outages, reliability]
---

# Change as Primary Outage Cause Framework (70% Rule)

## R — Original Text (Reading)

> SRE has found that roughly 70% of outages are due to changes in a live system. Best practices in this domain use automation to accomplish the following:
>
> - Implementing progressive rollouts
> - Quickly and accurately detecting problems
> - Rolling back changes safely when problems arise
>
> This trio of practices effectively minimizes the aggregate number of users and operations exposed to bad changes. By removing humans from the loop, these practices avoid the normal problems of fatigue, familiarity/contempt, and inattention to highly repetitive tasks. As a result, both release velocity and safety increase.
> — Google SRE, Chapter 1: Introduction

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The 70% finding reframes the entire question of production reliability. If most outages originate from change, then the primary lever for improving reliability is not better hardware, more redundancy, or more rigorous testing in isolation — it is better change management.

The non-obvious insight is directional: the correct response to "changes cause outages" is not "do fewer changes." Fewer changes does not make individual changes safer. It may even make them more dangerous by increasing the batch size and therefore the blast radius of each deployment. Change freezes reduce change frequency while leaving change risk per unit unchanged or increasing it.

The correct response is to make every change:

- **Smaller in blast radius** — affect fewer users or instances at each step.
- **Slower in propagation** — allow observation time between each step.
- **More observable** — detect problems at the earliest possible moment after deployment, ideally at the 1% canary stage.
- **More reversible** — automated rollback triggered by monitoring, not by human decision.

**Progressive rollout** is the primary implementation of this principle. Deploy to 1% of production, observe the four golden signals, deploy to 10%, observe, continue. At each stage, the observation window catches defects before they reach full blast radius.

**Canarying** is a specific form of progressive rollout where a subset of production instances serves the new version while the rest serve the old, allowing direct comparison. A canary is not a test — it is structured user acceptance in a real production environment.

**Automatic rollback** removes the human decision-making bottleneck. A rollback triggered by a monitoring threshold fires in seconds. A rollback triggered by a human who must first notice the alert, diagnose its significance, and authorize the action takes minutes to hours. Automation increases both the reliability of detecting the need to roll back and the speed of the rollback itself.

The paradox the framework resolves: shipping changes more frequently, in smaller batches with automated safety mechanisms, results in fewer outages per change than shipping large batches infrequently with manual controls.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Global Chubby Outage from Config Change (Book Chapter 14, Rollback Case)

- **Problem:** A configuration change is pushed to Chubby (Google's distributed lock service). The change begins causing failures across dependent services. The outage is detected through alerts.
- **Application:** The on-call SRE, recognizing the correlation with the configuration push, immediately rolls back the change. The book notes that "the SRE had the presence of mind to roll back the change immediately, averting a much longer and larger-scale outage."
- **Conclusion:** The swift rollback — available because the change was tracked, attributed, and reversible — directly shortened the outage. The book uses this as a case for why rollback capability is not optional.
- **Result:** The outage that would have required extended troubleshooting to diagnose and manually fix instead resolved in minutes. The SRE received recognition specifically for the rollback decision, reinforcing that fast rollback is the correct response when a change correlates with a problem.

### Case 2: App Engine Feature Push — Canary Process Failure (Book Chapter 14 Section)

- **Problem:** An App Engine feature had previously been pushed with a thorough canary and no issues. A subsequent push of the same feature area was judged lower-risk and followed a less stringent canary process. The change caused an outage.
- **Application (failed):** The team applied progressive rollout for the first push but relaxed the process for the second, reasoning that the first push had validated the risk level. The second push affected all instances simultaneously.
- **Conclusion:** The outage "reinforced the need for thorough canarying, regardless of the perceived risk." The 70% rule does not have an exception for "low-risk" changes — those changes are exactly where confirmation bias creates vulnerability.
- **Result:** Outage. The book explicitly states the team's subsequent policy: all changes require the same canary discipline regardless of perceived risk classification. Risk perception is not a substitute for observation.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: The change freeze proposal**
A team that has been experiencing frequent outages proposes a 2-week change freeze before every major holiday. Management endorses it as a reliability measure.
_Language signals:_ "We should lock down before the holiday" / "No changes after [date]" / "A freeze will prevent incidents during peak traffic."
_Apply:_ The 70% rule predicts that change freezes are counterproductive: (a) they do not address the blast radius of individual changes; (b) they create a pre-freeze rush of changes that are deployed at higher risk just before the freeze window; (c) the majority of uptime exposure occurs during normal working days, not holidays. The correct intervention is progressive rollout and automated rollback on every deployment, including during the holidays. A team with good change management has fewer outages on high-change days than this team has on low-change days.

**Scenario 2: The all-at-once config push**
A team pushes a configuration change to all 10,000 production instances simultaneously. A bug in the config causes all instances to fail.
_Language signals:_ "We just pushed the config update" / "It was just a config change, not a code change."
_Apply:_ The 70% rule explicitly includes configuration changes. A config change pushed to 10,000 instances simultaneously has maximum blast radius. The mitigation: push to 1% (100 instances), observe error rates for 10 minutes, push to 10%, observe, continue. The key insight is that config changes are indistinguishable from code changes in their risk profile — both modify the live system.

**Scenario 3: The "rollback after diagnosis" instinct**
After an outage, a team debates whether to roll back immediately or diagnose first to avoid "wasting the rollback." The change has been in production for 20 minutes and error rates are climbing.
_Language signals:_ "Let's diagnose before we roll back" / "We don't want to roll back if it's not the cause."
_Apply:_ Roll back first, diagnose second. The cost of a correct rollback is losing 20 minutes of production time for the new version. The cost of an incorrect decision to hold while diagnosing is the full duration of the elevated error rate during diagnosis. The 70% prior means the change is the most likely cause. Rollback and diagnose in parallel; re-deploy when confirmed safe.

**Distinguishing from adjacent skills:**

- **Hypothetico-deductive troubleshooting loop:** The troubleshooting loop applies after an incident has started. Change management prevents the incident by catching defects before they reach full blast radius.
- **Error budget conflict resolution:** Error budget governs the policy question of when to slow releases. Change management governs the engineering question of how to make each individual release safer.

______________________________________________________________________

## E — Execution Steps

1. **Establish the change attribution baseline.** For the last quarter of incidents, classify the proximate cause as: code change, configuration change, traffic change, dependency change, or other. If change-origin incidents represent fewer than 50% of the total, the 70% finding may not apply at your current scale or system complexity — investigate other categories. If they represent 70%+ (as the book finds at Google scale), proceed to step 2. Completion criterion: you know what fraction of your outages originate from change.

2. **Implement progressive rollout with automated detection.** For every category of change identified in step 1, design a staged deployment process: stage 0 (1% or 1 instance or 1 region), observe for a defined window against alert thresholds, then proceed. The observation window must include the four golden signals monitored at alert-threshold sensitivity. Completion criterion: no change category allows deployment to more than 10% of production without an observation window between stages.

3. **Implement automated rollback triggers.** For each deployment stage, define the monitoring conditions that trigger automatic rollback (e.g., error rate increase > 0.1% sustained for 5 minutes, latency p99 increase > 50%). Automate the rollback — do not rely on human decision-making to notice, diagnose, and authorize. Test rollback procedures in staging before relying on them in production. Completion criterion: automated rollback is exercised successfully in a test environment before it is needed in production.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The primary source of outages is capacity-related (hardware failure, traffic spikes beyond provisioned capacity). Change management does not address capacity. Use capacity planning methodology for those cases.
- Applying automated rollback to stateful changes (database migrations, data schema changes). Automated rollback of a schema migration may cause data loss or corruption. These changes require manual, carefully designed rollback procedures, not automated triggers.
- The team is pre-deployment (no production system exists yet). The 70% finding applies to live systems under continuous change, not to initial deployments.

**Failure patterns:**

- Treating "low-risk" changes as exempt from progressive rollout. The App Engine counter-example demonstrates that perceived risk is not a reliable predictor of actual outage risk. The process must be applied uniformly.
- Using canarying only for code changes, not for configuration changes. At Google scale, configuration changes are one of the most common outage causes. Infrastructure-as-code and configuration management systems must participate in the same canary process.
- Implementing progressive rollout without automated rollback. Progressive rollout without rollback detection only narrows the blast radius of the initial deployment — if the defect is detected in the 10% stage but rollback requires a human decision, the outage duration is not improved.
- Conflating rollback speed with rollback availability. A system that supports rollback but requires 45 minutes of manual steps to execute it provides limited benefit compared to one with 30-second automated rollback.

**Author blind spots:**

- Written in 2016 for Google's internal deployment infrastructure. Teams without Borg, Kubernetes, or equivalent infrastructure-as-code tooling must implement progressive rollout and automated rollback from scratch — the principles apply but the implementation effort is non-trivial.
- The 70% figure is a Google internal measurement. The correct percentage at any given organization depends on the ratio of change frequency to other failure modes (hardware failure, dependency failures, traffic events). The specific number matters less than the directional insight.
- Does not address modern continuous deployment practices (feature flags, dark launches, A/B testing at the feature level) that implement the same principles with different mechanisms.
- No coverage of the specific challenge of database migrations, which have the highest rollback cost and therefore require the most conservative change management discipline.

**Easily confused with:**

- **Blameless postmortem process:** Postmortems investigate what happened after an incident. Change management prevents the incident. Both are necessary; change management reduces MTTF (fewer outages), postmortems reduce MTTR and improve MTTF through learning.
- **Four golden signals monitoring:** Monitoring is the detection mechanism that makes automated rollback possible. The monitoring system must be configured before the progressive rollout process can function.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: four-golden-signals-monitoring (progressive rollout requires monitoring at each stage to detect problems before proceeding)
- contrasts-with: error-budget-conflict-resolution (error budget governs release policy decisions; change management governs per-release engineering safety)
- composes-with: blameless-postmortem-process (postmortems on change-originated outages produce the specific changes to rollout process and blast-radius design that close future gaps)
- composes-with: hypothetico-deductive-troubleshooting-loop (when a change causes an outage, the troubleshooting loop is the diagnostic method; the 70% prior means change is the first hypothesis to test)

______________________________________________________________________

## Related Skills

- **depends_on**: four-golden-signals-monitoring — progressive rollout requires signal-based detection at each stage to determine whether to proceed or roll back
- **contrasts_with**: error-budget-conflict-resolution — error budget governs the policy decision of when to release; change management governs the engineering mechanics of how to make each individual release safer
- **composes_with**: blameless-postmortem-process — postmortems on change-originated outages produce the specific rollout-process improvements that reduce future blast radius
- **composes_with**: hypothetico-deductive-troubleshooting-loop — when a change correlates with an outage, the loop is the diagnostic method and the 70% prior makes change the first hypothesis to test

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Site Reliability Engineering" by Betsy Beyer et al. (Google) — Chapter 1: Introduction / Chapter 8: Release Engineering
