---
name: fallback-failover
description: |
  Use this skill when you need to select or design a resilience mechanism that keeps a
  service operational when a primary system or dependency fails.

  **When to call:**
  - Choosing between failover and fallback for a specific reliability requirement
  - Evaluating whether to use a homogeneous or heterogeneous backup strategy
  - Designing resilience for a service that has a dependency with a lower SLO than required
  - Reviewing existing fallback/failover architecture for common-cause failure risks
  - Deciding whether partial service (with degradation) is preferable to no service

  **When NOT to call:**
  - Classifying the severity of an ongoing incident (use `degradation-disruption`)
  - Calculating the combined SLO of parallel or serial dependencies (use `composite-slo`)
  - Setting the SLO target for a service (use `slo-definition-calibration-framework`)
  - Designing the SLI formula for the service (use `sli-formula-measurement`)

  **Key trigger signal:** The user is deciding what happens when a service or dependency
  fails — should the backup be the same type (failover) or a different type (fallback)?
  Or: "We need higher availability but our dependency isn't reliable enough." Or: "Our
  failover system keeps failing at the same time as the primary."
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20230726_113038_fallback.md, 20230712_231043_failover.md, 20240325_053017_composite-slo.md
tags: [failover, fallback, resilience, availability, degradation, common-cause-failure, heterogeneous]
related_skills:
  - slug: degradation-disruption
    relation: depends-on
  - slug: composite-slo
    relation: composes-with
  - slug: slo-definition-calibration-framework
    relation: composes-with
---

# Fallback Vs Failover Selection Framework

## R — Original Text (Reading)

> Where failover uses **the same type of solution** to achieve the same outcome, fallback
> uses a **different type of solution** to maintain the **essential system functionality**.
>
> Change is the number one enemy of reliability. If we decouple the lifecycle of the two
> alternative solutions, we can improve reliability.
>
> If the primary system fails due to some faulty code commit, bad data or misconfiguration,
> a heterogeneous fallback is more likely to be ready than a homogeneous fallback with its
> lifecycle tied to the primary system. Non-simultaneous failure translates to more
> reliability.
>
> A common side effect of this mitigation strategy is that the end user may notice a
> difference between when the primary or the fallback systems are in charge. This contrasts
> with failover which aims for seamless mitigation from the users' point of view.

— Alex Ewerlöf, 20230726_113038_fallback.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Failover and fallback are both backup strategies, but they differ along one critical axis:
**whether the backup is the same type as the primary**.

**Failover** uses a same-type replica of the primary system. The replica runs the same
code, serves the same requests, and from the consumer's perspective the switch is
seamless — they cannot tell the difference. This seamlessness is the key benefit. The
key risk is **common-cause failure**: if a code bug, misconfiguration, or dependency
failure takes down the primary, it is likely to take down the replica at the same time
or shortly after, because they share the same lifecycle.

**Fallback** uses a different type of solution for the backup — different technology,
architecture, or level of functionality. The consumer will notice a difference (reduced
features, stale data, slower responses), so fallback accepts degradation. The key benefit
is **decoupled failure lifecycle**: a code push that breaks the primary does not break a
heterogeneous fallback, because they have independent change cycles. Non-simultaneous
failure is the reliability gain.

The selection framework distils to one question: **Can the consumer tell the difference?**

- If the consumer cannot perceive any difference: use failover (same-type, seamless)
- If degradation is tolerable: prefer heterogeneous fallback (different-type, decoupled)

**Failover taxonomy** (three independent dimensions):

- Active-Active (both systems share load) vs. Active-Passive (primary carries load;
  secondary is on standby)
- Hot (secondary is immediately ready) vs. Cold (secondary needs startup time)
- Hard (primary is killed on failure) vs. Soft (primary is left running for diagnosis)

**Fallback taxonomy** (degradation type):

- Limited functionality: reduced feature set (e.g. Windows Safe Mode)
- Poor data: stale cache, secondary DB with reduced data (e.g. mobile app serving cached
  content when backend is down)
- Lower performance: the backup runs slower than primary (e.g. serving from backend when
  CDN dies)
- Higher cost: a different provider at higher per-unit cost (e.g. alternative payment
  processor)
- Manual: human intervention replaces automated flow (e.g. phone call as order fallback)

**The heterogeneous preference rule:** When both failover and fallback are viable, prefer
a heterogeneous fallback over homogeneous failover if: (a) common-cause failure is a
concern, (b) degraded service is acceptable, and (c) the cost difference justifies it.
For high-frequency failures where consumers require seamlessness, failover remains the
right choice.

**Combining both:** Failover and fallback can and often should coexist. Failover handles
the common case (replica is available); fallback is the last resort (both replicas fail,
fall back to cache or manual).

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Stockholm-to-Ireland Failover — Active-Passive with Latency Cost (C16)

- **Problem:** A Scandinavian service needed high availability but a single region (Stockholm)
  was insufficient.
- **Application:** An active-passive hot failover was set up using AWS Route 53, with Ireland
  as the standby. When Stockholm failed, load shifted to Ireland automatically. However, a
  stateful dependency remained in Stockholm: Ireland-based requests had to return to Stockholm
  for data, increasing latency.
- **Conclusion:** Homogeneous failover (same stack, same code in both regions) achieved
  seamless handover for users. But it exposed a serial dependency that partially defeated the
  geographic separation — Ireland was not truly independent of Stockholm.
- **Result:** High availability was achieved, but with latency degradation during failover
  events. Demonstrates that failover architecture must account for stateful dependencies;
  seamless failover requires all dependencies to be replicated, not just the primary service.

### Case 2: News Site — Stale Cache and Paywall Bypass as Fallback (C14)

- **Problem:** A news site needed very high availability even when its backend or paywall
  service was down.
- **Application:** Two heterogeneous fallback mechanisms were in place: (1) Varnish cache
  served stale content (up to 5 minutes old) when the backend failed; (2) if the paywall
  service failed, the cache automatically bypassed the paywall and served content free.
  These were different-type solutions (cache vs. origin, paywall bypassed vs. enforced).
- **Conclusion:** The stale cache and paywall bypass are classic heterogeneous fallbacks.
  The lifecycle of the cache is decoupled from the backend lifecycle; a code push breaking
  the backend would not break the cache.
- **Result:** Extremely high composite availability was achieved, even though individual
  backend dependencies were less reliable. The company accepted the revenue loss from
  free paywalled content as a business decision — better than user-visible errors.

### Case 3: Premium Online Sales — Manual Phone Call as Fallback (C15)

- **Problem:** A high-value, low-volume e-commerce operation could not afford to lose orders
  even when the online store was down (sub-98% availability).
- **Application:** The fallback was a manual phone call. When the online order flow failed,
  staff called customers whose contact information had been collected early in the purchase
  journey. This is maximally heterogeneous: an entirely different technology (human + phone)
  with a completely decoupled failure mode.
- **Conclusion:** Near-100% order completion was achieved despite sub-98% platform
  availability. The extra per-order cost was acceptable given the high value of each order.
- **Result:** Demonstrates that fallback does not require automation. For high-value,
  low-volume transactions, a manual fallback can be more cost-effective than building
  and maintaining additional automated infrastructure.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A team has a dependency with a lower SLO than their own availability target requires.
   They need to decide whether to implement failover (same-type replica) or fallback
   (different-type alternative) to close the gap.

2. A system experienced an incident where both the primary and its same-type replica failed
   simultaneously (common-cause failure). The team is redesigning the resilience architecture
   and must decide whether to switch to a heterogeneous approach.

3. An architect is reviewing a new service design and needs to verify that the chosen
   redundancy strategy (failover vs. fallback) is appropriate for the traffic volume,
   consumer tolerance for degradation, and the failure modes of each dependency.

### Language Signals (Activate When These Appear)

- "Our primary and backup went down at the same time"
- "We need higher availability than our dependency provides"
- "What should happen when [dependency X] is unavailable?"
- "We have a replica — is that enough?"
- "Can we serve stale data / reduced functionality when the backend is down?"
- "We need 99.9% availability but our database only promises 99%"

### Distinguishing from Adjacent Skills

- Difference from `degradation-disruption`: `degradation-disruption` classifies *what is
  happening* during a failure. This skill designs *the mechanism* to respond to failure
  before or during it. Use `degradation-disruption` to decide whether a degraded fallback
  state is acceptable; use this skill to design the fallback itself.
- Difference from `composite-slo`: `composite-slo` calculates the *mathematical result*
  of combining parallel and serial dependencies. This skill selects *which architectural
  pattern* to use to achieve a target composite SLO.

______________________________________________________________________

## E — Execution Steps

1. **Determine whether consumers can tolerate degradation**

   - Ask: If the backup system provides reduced functionality, stale data, or slower
     performance, will consumers notice? Will that be acceptable?
   - If seamless, no-degradation handover is required: failover is the right category
   - If degradation is tolerable: fallback is the right category (and likely cheaper)
   - Completion criteria: A clear statement: "Consumers [can / cannot] tolerate degradation
     because [reason]."

2. **Assess common-cause failure risk (for failover) or lifecycle coupling (for fallback)**

   - For failover: Do the primary and secondary share the same codebase, deployment pipeline,
     or configuration? If yes, they share a failure lifecycle — a single bad deployment
     can take both down simultaneously.
   - For fallback: Is the backup system truly heterogeneous (different tech, different
     change cadence)? Or is it a slightly different version of the same thing (homogeneous
     fallback with decoupled lifecycle)?
   - Completion criteria: You can name the shared failure modes between primary and secondary.
   - Stop condition: If the same failure event can simultaneously take out both primary and
     secondary, the architecture does not provide the intended resilience. Redesign required.

3. **Select the failover sub-type (if failover is chosen)**

   - Active-Active or Active-Passive? (Active-Active costs more but provides load distribution
     and can improve latency)
   - Hot or Cold? (Hot costs more but provides instant switchover)
   - Hard or Soft? (Soft preferred for stateful services where diagnosis is needed)
   - Completion criteria: A specific configuration is selected with a cost/benefit rationale.

4. **Select the fallback degradation type (if fallback is chosen)**

   - Choose the appropriate degradation mode from: limited functionality, poor data (stale
     cache), lower performance, higher cost (alternate provider), or manual
   - Evaluate: Is manual fallback viable? (Only when transaction value is high and volume
     is low)
   - Prefer heterogeneous (different technology) over homogeneous (same technology, older
     version) for maximum lifecycle decoupling
   - Completion criteria: The fallback mechanism is specified including the degradation type
     and the failure modes it does and does not cover.

5. **Plan fallback/failover testing**

   - Automation that is never exercised provides false confidence (ce29)
   - Define a regular test cadence — treat it like fire alarm testing
   - Completion criteria: A test plan exists with frequency and what "passing" looks like.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The service has no redundancy and the question is whether redundancy is worth the cost
  at all — that is a `slo-definition-calibration-framework` question (what SLO do you need vs. what does it cost?).
- The question is purely mathematical — what is the combined SLO of N parallel dependencies
  — that is `composite-slo`.
- The service must never degrade — for life-critical or financial systems where degradation
  is itself a safety failure, failover is mandatory and the design must be exhaustively
  specified by domain experts, not derived from this general framework.

### Failure Patterns Warned by the Author

- **Common-cause failure in homogeneous failover**: A same-type replica that shares the
  same deployment pipeline will be taken down by the same bad code push that kills the
  primary. "We have a replica" does not mean "we are protected" unless the replica has an
  independent lifecycle.
- **Untested fallback (ce29)**: A fallback mechanism that is never tested in realistic
  conditions will fail when needed. The fallback system evolves out of sync with the
  primary; automation drifts; runbooks become stale. Fallback tests must be scheduled, not
  optional.
- **Over-automation of rarely-used fallback**: Automating a fallback that triggers once a
  year may produce lower ROI than investing in primary system reliability. Automation of
  fallback should be proportional to the frequency and cost of failure.

### Author's Blind Spots / Limitations

- The framework is built around request-driven services. For event-driven architectures
  (queues, Kafka streams, batch pipelines), the concept of "switching load to a secondary"
  is more complex — replaying events, handling backpressure, and data ordering create
  failure modes not covered here.
- The manual fallback (human phone call) example scales only to low-volume, high-value
  transactions. The framework does not provide explicit guidance on where the manual-fallback
  threshold is — that judgment is left to business context.

### Easily Confused With

- **Circuit breaker**: A circuit breaker detects that a dependency is failing and stops
  sending requests to it (preventing cascade). Fallback and failover are about what
  happens *after* the circuit breaker trips — where do the requests go? Circuit breaker
  is a detection and containment pattern; fallback/failover is the routing-after-failure
  pattern.
- **Blue-green deployment**: Blue-green uses two environments for zero-downtime deployment,
  not for failure recovery. They share infrastructure concepts but different purposes.

______________________________________________________________________

## Related Skills

- **depends-on** → [`degradation-disruption`](../degradation-disruption/SKILL.md): Use degradation-disruption to decide whether a degraded fallback state is acceptable before designing the fallback mechanism itself.
- **composes-with** → [`composite-slo`](../composite-slo/SKILL.md): Fallback/failover introduces parallel paths; composite-slo provides the math for quantifying how much reliability improvement the parallel topology actually delivers.
- **composes-with** → `slo-definition-calibration-framework`: Lagom-slo determines the target SLO level; fallback-failover designs the resilience architecture required to achieve that level given the current dependency SLOs.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
