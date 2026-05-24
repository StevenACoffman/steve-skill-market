---
name: degradation-disruption
description: |
  Use this skill when you need to classify the severity of a service failure, decide whether
  to keep a degraded service running or deliberately take it down, or determine how to report
  an incident's business impact accurately.

  **When to call:**
  - Classifying an active incident as degradation vs. disruption vs. outage
  - Deciding whether a partial failure is "good enough to leave running" or actively harmful
  - Auditing severity models that treat partial availability as automatically lower severity
  - Framing stakeholder communications about an incident's business consequences
  - Designing SLI targets that capture quality failures (not just availability drops)

  **When NOT to call:**
  - Calculating SLO targets numerically (use `slo-definition-calibration-framework` or `multi-tier-slo`)
  - Designing fallback/failover mechanisms to prevent failures (use `fallback-failover`)
  - Defining which SLI metric to measure (use `sli-formula-measurement`)

  **Key trigger signal:** Someone says "at least the service is partially up" or classifies
  a severe degradation as low-severity because "it's not fully down." The counter-intuitive
  finding — degradation can exceed disruption in business impact — is the entry point for
  this skill.
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20240710_134959_service-degradation-vs-disruption.md, 20230531_195944_why-bother-with-sli-and-slo.md
tags: [incident-classification, severity, degradation, disruption, service-levels, slo]
related_skills:
  - slug: sli-formula-measurement
    relation: depends-on
  - slug: fallback-failover
    relation: contrasts-with
  - slug: multi-tier-slo
    relation: composes-with
---

# Degradation Vs Disruption Severity Classification

## R — Original Text (Reading)

> Think about an online retail store. Which one has a **more negative business impact**?
>
> A degradation which leads to showing the wrong prices to the customers?
>
> Or a disruption where the site is not accessible at all?
>
> If you guessed degradation, you guessed right. While intuitively we may think that a
> degraded experience is better than total outage, showing wrong prices may literally
> cost the business more than the site being down and losing potential customers. If
> customers buy the products below the price, the business loses money. If the site is
> down, customers cannot buy the products for the wrong price.
>
> Sometimes, it is better to disrupt a service than degrading it.

— Alex Ewerlöf, 20240710_134959_service-degradation-vs-disruption.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Three terms define a spectrum of failure severity, and they are not always ordered the way
intuition suggests.

**Degradation** means the service's core capabilities still function, but quality has dropped
— errors are higher, latency is elevated, data is stale, or functionality is reduced. The
service is usable by at least some users, at least some of the time. In SLI terms,
degradation shows up as accelerated error budget burn: the SLS (service level status) drops
below the SLO target.

**Disruption** means the core capabilities have completely stopped. No users can complete the
primary task. In SLI terms, disruption burns the error budget at maximum rate — all valid
events are bad events.

**Outage** is a disruption that has persisted long enough, or carries severe enough
consequences (SLA penalties, legal exposure, human safety), that the word "disruption" feels
too clinical.

The counter-intuitive finding is the skill's center: degradation is not automatically lower
severity than disruption. The correct question is **what are the consequences of partial
operation?** Four factors determine this:

1. **Which capabilities are affected?** Core capabilities that define the service differ from
   peripheral ones. AWS documentation going offline is a degradation; S3 operations failing
   is a disruption.

2. **Blast radius:** How many users, and which users (paying, free, by region, by platform)?
   Partial availability that affects 100% of paying customers may be more severe than a
   disruption in a single region.

3. **Consequences of the degraded state:** Wrong prices, misleading data, or silently failed
   orders can cause active, compounding harm. A site that is simply down loses potential
   customers; a site showing wrong prices loses money on every transaction completed.

4. **Cascading direction:** One team's disruption can appear as the other team's degradation.
   A dependency going fully down may only degrade the consuming service, if that consumer
   has a fallback. Classify from the consumer's perspective, not the provider's.

The engineering implication: severity models that automatically assign "partial availability
= lower severity" are wrong. Sometimes the correct response to a harmful degradation is to
deliberately trigger a disruption — take the service down — to stop the active damage.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: AWS S3 2017 — Disruption with Cascade (C12)

- **Problem:** All S3 GET, LIST, PUT, and DELETE operations failed in US-EAST-1, triggered
  by a single DNS configuration error.
- **Application:** The failure eliminated all core S3 capabilities — the definition of
  disruption. But because many other AWS services had serial dependencies on S3, their
  disruption cascaded as their own disruptions.
- **Conclusion:** A single configuration change caused a global disruption that was
  non-linear in magnitude relative to its cause. The cascading nature means composite
  SLOs collapsed in chains.
- **Result:** Demonstrates that disruptions propagate through serial dependency graphs and
  that the disruption/degradation distinction must be applied at each dependency layer.

### Case 2: GitHub 2018 Data Inconsistency — Degradation Without Disruption (C13)

- **Problem:** GitHub's internal systems experienced data inconsistency, causing users to
  see out-of-date or incorrect information for over 24 hours.
- **Application:** Because core git operations (push, pull, clone) continued to work, this
  was a degradation — not a disruption. However, it would have burned an error budget for
  a data-correctness SLI at high rate for 24 hours.
- **Conclusion:** A standard availability-only SLI would have missed this incident entirely.
  The degradation was significant and long-lived, yet technically below the threshold of
  "disruption."
- **Result:** Shows that availability-only SLIs are insufficient; quality-of-data SLIs are
  needed to detect degradations that standard severity models would classify as minor.

### Case 3: Online Retail Wrong-Price Degradation (From the Book)

- **Problem:** An online retail store shows incorrect prices due to a degraded pricing
  service.
- **Application:** Applying the degradation/disruption classification: core capability
  (browsing, purchasing) is still available — this is technically a degradation. But
  customers completing purchases at wrong prices creates direct financial loss.
- **Conclusion:** The degradation has worse business impact than a full disruption would.
  When the site is down, customers can't purchase at wrong prices. When the site is up with
  wrong prices, they can and do.
- **Result:** This is the author's canonical counter-example to the "partial availability
  = lower severity" assumption. The correct response may be deliberate disruption.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An incident is declared, the service is partially functioning, and the on-call team is
   deciding the severity level. They are considering "P3 — degradation" but have not
   evaluated the consequences of the degraded state.

2. A team is designing an incident severity matrix and wants to map degradation, disruption,
   and outage to P1/P2/P3 tiers correctly — particularly to avoid the default assumption
   that partial availability is always lower severity.

3. A service is showing wrong, stale, or misleading data. The question is whether to keep
   it running (preventing a disruption) or take it down (stopping active harm from the
   degraded state).

### Language Signals (Activate When These Appear)

- "At least it's partially working"
- "It's a degradation, not a full outage — it's P3"
- "Some users are affected but the service is up"
- "The site is accessible, just showing [wrong/stale/inconsistent] data"
- "Better degraded than down"

### Distinguishing from Adjacent Skills

- Difference from `fallback-failover`: This skill is about *classifying* the severity of
  what's happening. `fallback-failover` is about *designing* mechanisms to respond to it.
  Use this skill first (is this degradation or disruption? is the degraded state harmful?)
  then use `fallback-failover` to decide how to architect the response.
- Difference from `sli-formula-measurement`: This skill uses the conceptual distinction
  between degradation and disruption to make operational decisions. `sli-formula-measurement`
  focuses on how to construct the SLI formula itself so that quality failures (not just
  availability) are detected.
- Difference from `multi-tier-slo`: This skill is reactive (classifying an incident).
  `multi-tier-slo` is proactive (designing SLO structures that constrain incident duration).

______________________________________________________________________

## E — Execution Steps

1. **Identify which capabilities are affected**

   - List the service's core capabilities (the ones that drive business value)
   - Classify: are core capabilities fully stopped (disruption) or partially impaired
     (degradation)?
   - Completion criteria: You can state "Core capability X is \[fully stopped / partially
     impaired\] for [scope of users]."

2. **Determine the blast radius**

   - Who is affected: all users, subset (by region, tier, platform, configuration)?
   - Are affected users the most business-critical (paying customers, high-value segment)?
   - Completion criteria: You can quantify "N% of [user tier] are experiencing [failure type]."

3. **Assess the consequences of operating in the degraded state**

   - Ask: Is the degraded state actively harmful, or just suboptimal?
   - Active harm examples: wrong prices, misleading data, silently failed transactions,
     security exposure, data corruption.
   - Suboptimal examples: slower responses, reduced feature set, higher error rate.
   - Completion criteria: You can answer "The degraded state causes \[active harm / suboptimal
     experience\] because [specific mechanism]."

4. **Apply the severity classification**

   - If core capabilities are fully stopped → disruption
   - If core capabilities partially work AND degraded state is actively harmful → treat
     as equal-to or higher-than disruption severity; consider deliberate disruption
   - If core capabilities partially work AND degraded state is merely suboptimal → degradation
     (lower severity than disruption)
   - Completion criteria: You have a severity classification with a documented rationale.

5. **Decide on disruption vs. continued degradation**

   - If the degraded state causes active harm: evaluate whether deliberate disruption
     (taking the service down) would stop the harm and is preferable.
   - Consider: Can consumers reach a clean error state rather than a misleading one?
   - Completion criteria: A deliberate decision is recorded: "We \[keep the degraded service
     running / take it down\] because [rationale]."

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The service is fully down with no partial functionality — disruption is already confirmed;
  the classification question is resolved. Move to incident response.
- You need to design the mechanisms that prevent or mitigate degradations and disruptions
  — that is `fallback-failover`.
- The question is about SLO target setting — that is `slo-definition-calibration-framework` or `multi-tier-slo`.
- The failure is in a dependency's infrastructure, not your service's core capabilities —
  apply this skill to your service's view of its own capabilities, not the dependency's
  internal state.

### Failure Patterns Warned by the Author

- **Equating "partially up" with "lower severity"**: The default intuition that degradation
  is always less severe than disruption is wrong when the degraded state causes active harm.
  This is the primary failure mode this skill exists to prevent.
- **Conflating outage and disruption carelessly**: "Outage" implies dramatic, longer duration
  consequences; using it to downplay vs. over-dramatize an incident introduces communication
  noise. Use terms precisely.
- **Provider vs. consumer perspective mismatch**: A provider reporting "we had a degradation"
  may have caused a disruption in their consumer's service. Always classify from the consumer's
  perspective.

### Author's Blind Spots / Limitations

- The framework is primarily calibrated for request-driven, user-facing services. For
  batch jobs, data pipelines, or event-driven workloads, "core capabilities" may not map
  cleanly to a real-time disruption/degradation distinction — a pipeline that produces
  wrong aggregates for hours before being caught may not register as a degradation at all
  until a downstream consumer notices.
- The "deliberate disruption" recommendation (take it down if degraded state is harmful) is
  a clean theoretical prescription, but it requires organizational authority and a clear
  fallback plan. It can be difficult to execute without prior alignment on this decision
  path.

### Easily Confused With

- **Incident severity (P1/P2/P3) frameworks**: Standard severity frameworks use blast
  radius and recovery time as the primary axes. Degradation vs. disruption adds a third
  axis: the *consequences of continued operation* in the degraded state. Severity frameworks
  that do not include this axis will systematically under-classify harmful degradations.

______________________________________________________________________

## Related Skills

- **depends-on** → [`sli-formula-measurement`](../sli-formula-measurement/SKILL.md): The SLI formula must be designed to detect both quality failures (degradation) and total failures (disruption); this skill uses those formula properties to classify ongoing incidents.
- **contrasts-with** → [`fallback-failover`](../fallback-failover/SKILL.md): This skill classifies the severity of what is happening during a failure; fallback-failover designs the mechanisms that respond to those failures in advance.
- **composes-with** → [`multi-tier-slo`](../multi-tier-slo/SKILL.md): Multi-tier SLO window tiers constrain incident duration — use degradation-disruption to classify the active incident severity, and multi-tier-slo's window structure to ensure alert thresholds catch prolonged degradations before they consume the full error budget.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
