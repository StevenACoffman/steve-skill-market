---
name: composite-slo
description: |
  Use this skill when a system's SLO must be derived from multiple dependent components, or when someone asks "what is the overall availability of our system?" and the system has serial or parallel dependencies. The two rules are: multiply SLOs for serial dependencies; multiply *error budgets* (1 - SLO) for parallel dependencies. Most engineers get the parallel case wrong by multiplying SLOs rather than error budgets.

  WHEN TO CALL:
  - An architect or engineer needs to calculate or predict the end-to-end SLO for a multi-component system.
  - A team owns a service with multiple upstream dependencies and needs to know what SLO they can realistically commit to.
  - Someone is evaluating whether adding redundancy (parallel instances) actually improves overall reliability and by how much.
  - A consumer's SLO requirement must be decomposed into SLO budgets for each dependent team.
  - A discussion involves third-party SLAs and the question is whether those vendor commitments are compatible with an overall system SLO.

  WHEN NOT TO CALL:
  - The question is what SLO to *target* rather than what SLO is *achievable* — use slo-definition-calibration-framework for calibration.
  - The question is which metric to use as an SLI — use sli-compass or sli-monitoring-design-maturity.
  - All components are owned and controlled by a single team — the calculation is trivial and the real problem is probably SLI design.
  - Components have correlated failure modes (shared infrastructure, shared deployment pipeline) — the independence assumption required by the probability multiplication breaks down.

  KEY TRIGGER SIGNAL: "What's our system availability?" or "We have X redundant servers — how does that improve our SLO?" or any question involving a dependency graph and reliability numbers.
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20240325_053017_composite-slo.md, 20250803_112619_service-level-topology.md, 20240220_185447_responsible-for-control.md
tags: [composite-slo, serial-dependencies, parallel-dependencies, error-budget, system-reliability, probability]
related_skills:
  - slug: sli-formula-measurement
    relation: depends-on
  - slug: responsibility-control-slo
    relation: composes-with
  - slug: multi-tier-slo
    relation: contrasts-with
---

# Composite SLO Calculation (Serial/Parallel Rules)

## R — Original Text (Reading)

> Complex systems are made of many components. System engineering has two simple rules for calculating composite SLO:
>
> - Multiply **SLOs** for **serial** dependencies
> - Multiply **error budgets** for **parallel** dependencies
>
> Both use a basic concept in probability theory: the probability of two *independent* events happening at the same time is the result of multiplying the probability of each one happening individually.
>
> As you can see, the availability of a system with serial dependencies is worse than its least reliable dependency, which is expected. For parallel dependencies, the availability is better than the most reliable dependency — also expected.
>
> — Alex Ewerlöf, 20240325_053017_composite-slo.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The composite SLO framework applies probability theory to multi-component systems. Its core insight is that the *direction* of the math depends on the *topology* of the dependencies, not just the numbers.

**Serial dependencies** (A must work AND B must work for C to work): The system can only be available when all its dependencies are simultaneously available. The composite availability is the product of all individual SLOs: `SLO_composite = SLO_A × SLO_B × ...`. This always yields a number *worse* than the least reliable dependency. Every serial dependency is a reliability tax.

**Parallel dependencies** (A must fail AND B must fail for C to fail): The system fails only when all parallel paths simultaneously fail. The calculation works on the *failure* (error budget) side: `error_budget_composite = EB_A × EB_B × ...`, then `SLO_composite = 1 - error_budget_composite`. This always yields a number *better* than the most reliable parallel path. Redundancy dramatically improves availability because independent failures are unlikely to coincide.

The critical error most engineers make is applying the serial rule (multiply SLOs) to parallel cases. Multiplying SLOs for parallel dependencies gives a number that is worse than the individual components — precisely backwards. The reason the error is common: both cases involve multiplication, but one multiplies the availability numbers and the other multiplies the unavailability numbers.

For real systems, the calculation recurses: first resolve the inner topology (e.g., three CDN nodes in parallel), treat the result as a single component, then multiply it with the remaining serial dependencies.

A practical constraint: the math assumes independence between failures. If two "parallel" services share the same database, cloud region, or deployment pipeline, they are not truly independent and the error budget multiplication overstates the reliability benefit.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Worked Example — Website with CDN, API, and IDaaS (From Composite-Slo Chapter)

- **Problem:** A web application depends on three components: a CDN with three parallel edge nodes (each backed serially by a static server), an API server, and a third-party identity-as-a-service (IDaaS) provider. How available is the browser application?
- **Application:** The calculation proceeds recursively. Each CDN node's availability = `CDN_node_SLO × static_server_SLO = 0.999 × 0.98 = 0.97902`. Error budget per CDN node = `1 - 0.97902 = 0.02098`. Three parallel CDN nodes: composite error budget = `0.02098³ ≈ 0.0000092`. CDN availability = `1 - 0.0000092 ≈ 99.999%`. API availability given IDaaS dependency = `0.95 × 0.99 = 0.9405`. Browser app availability (CDN × API × IDaaS) = `0.99999 × 0.9405 × 0.99 ≈ 93.1%`.
- **Conclusion:** Despite having a highly redundant CDN, the overall system availability is only 93.1% because of serial dependencies downstream — particularly the API server at 95%.
- **Result:** The calculation reveals that the weak point is not the infrastructure but the API server and its upstream dependencies. Reliability investment should be directed there, not at the already-excellent CDN.

### Case 2: News Site Varnish Cache Fallback (C14)

- **Problem:** A news site's backend was not highly reliable, but the site needed high availability SLO.
- **Application:** The Varnish reverse proxy cache introduced a parallel path: if the backend failed, the cache served stale content. This created a parallel dependency — the site failed only when both the cache *and* the backend failed simultaneously. Each failure mode had its own error budget; multiplying those error budgets (both low-probability events) yielded a composite error budget far smaller than either component alone.
- **Conclusion:** The composite SLO of the CDN + backend system significantly exceeded the SLO of the backend alone. The cache was a cheap reliability multiplier.
- **Result:** Extremely high effective availability was achieved without requiring the backend to be itself highly reliable — by modeling the parallel topology correctly.

### Case 3: AWS S3 2017 Disruption — Cascading Serial Dependencies (C12)

- **Problem:** A single DNS configuration error in AWS US-EAST-1 caused all GET/LIST/PUT/DELETE S3 requests to fail, and this disruption cascaded to all other AWS services that depended on S3 internally.
- **Application:** Every service that had a serial dependency on S3 inherited S3's failure. The composite SLO of any service with a hard S3 dependency was capped by S3's SLO at that moment (effectively zero during the disruption). The breadth of impact demonstrated how serial dependency chains multiply across an ecosystem.
- **Conclusion:** Services that assumed S3 was a background commodity had not modeled the serial dependency's impact on their composite SLO.
- **Result:** The incident illustrated that composite SLO analysis is not optional for services with critical serial dependencies on third-party infrastructure.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An architect is proposing to add a second database replica "for reliability" and needs to quantify how much improvement the redundancy actually provides — the parallel error budget multiplication will show the dramatic improvement from even a second independent replica.
2. A team's SLO review reveals they are consistently missing their 99.5% commitment and they cannot understand why — tracing the composite SLO of their serial dependencies reveals the math was never done and the target was never achievable given their upstream dependencies.
3. An organization is setting internal SLO budgets per team and needs to decompose a consumer-facing 99.9% SLO into per-team targets — the serial multiplication rule tells them what each dependency must contribute.

### Language Signals (Activate When These Appear)

- "What is our system's overall availability?"
- "We have two servers in different regions — how much does that improve our reliability?"
- "Our SLO is 99.9% but we depend on a vendor who only guarantees 99% — is that a problem?"
- "We keep missing our availability target even though each individual service seems fine"
- "If we add redundancy, what SLO can we commit to?"

### Distinguishing from Adjacent Skills

- Difference from `slo-definition-calibration-framework`: Composite SLO calculates what availability level a system can *achieve* given its topology; slo-definition-calibration-framework determines what level it *should* commit to given consumer tolerance and cost.
- Difference from `10x9-cost-reliability`: Composite SLO is a calculation tool for deriving achievable SLOs from component reliability; 10x9-cost-reliability is an economic argument about the cost of raising SLO levels.
- Difference from `responsibility-control-slo`: The responsibility/control skill determines which team should own which part of a decomposed SLO; composite SLO is the mathematics for how those parts combine.

______________________________________________________________________

## E — Execution Steps

1. **Draw the dependency topology**

   - Identify all components the system depends on. For each, determine: is it serial (system fails if this component fails) or parallel (system fails only if this AND at least one other fail simultaneously)?
   - Completion criteria: A dependency graph showing all serial and parallel relationships.

2. **Collect availability numbers for each component**

   - Use SLA commitments for third-party services, historical SLS data for internal services, or target SLOs for services under design.
   - Completion criteria: A number in the 0–1 range for each leaf node in the dependency graph.

3. **Calculate serial composite SLOs (working inward to outward)**

   - For each set of serial dependencies: multiply all SLO values together.
   - Example: `SLO_composite = 0.998 × 0.953 = 0.951094`
   - Completion criteria: A single composite SLO for each serial chain.

4. **Calculate parallel composite SLOs**

   - For each set of parallel dependencies: convert each SLO to an error budget (`EB = 1 - SLO`), multiply all error budgets together, then subtract from 1.
   - Example: `EB_composite = (1-0.998) × (1-0.953) = 0.002 × 0.047 = 0.000094; SLO = 1 - 0.000094 = 99.9906%`
   - Stop condition: If parallel components share infrastructure (same cloud region, same database), flag this — independence assumption is violated; the calculation will overstate reliability.
   - Completion criteria: A single composite SLO for each parallel group.

5. **Combine resolved subgraphs into the full system SLO**

   - Treat each resolved serial or parallel group as a single node and repeat Steps 3–4 until one final composite SLO remains.
   - Completion criteria: A single composite SLO for the full system.

6. **Interpret the result relative to the target SLO**

   - If composite SLO < target SLO: identify the serial dependency with the lowest SLO — that is the reliability bottleneck. Improving parallel redundancy elsewhere will not fix this.
   - If composite SLO > target SLO: the architecture has reliability headroom; an SLO above the target may be achievable at lower cost than previously assumed.
   - Completion criteria: A statement of the bottleneck component and the next recommended action.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- Components are not independent (shared infrastructure, correlated failures) — the probability multiplication assumes independence; violating this assumption produces overoptimistic results.
- The question is what SLO to *target* — use slo-definition-calibration-framework; composite SLO tells you what is *achievable*, not what is *appropriate*.
- The system has feedback loops or retry behavior that can cascade load (e.g., retry storms) — the static probability model does not capture dynamic failure modes.

### Failure Patterns Warned by the Author

- **ce21 (SLO too low — outsourcing cost to consumers):** Without composite SLO reasoning, a team does not know that their low SLO is causing N consumer teams to each pay mitigation costs. The aggregate cost becomes visible only when composite SLO economics are modeled.
- **ce20 (SLO too high — false security):** A team commits to an SLO higher than their composite dependencies can support. The SLO is consistently breached not because of team performance but because the math was never done.

### Author's Blind Spots / Limitations

- The composite SLO formula assumes component failures are statistically independent. In practice, services sharing a cloud region, a CDN provider, or a database cluster will experience correlated failures. The model gives an optimistic lower bound on failure probability, not an accurate one.
- The model treats availability as a binary (up/down) dimension. It does not capture partial degradation, latency SLOs, or correctness SLOs that are more complex to compose across dependencies.

### Easily Confused With

- **Multi-tiered SLO**: A multi-tiered SLO sets multiple targets for the same service (e.g., 99.9% for p50 latency, 99% for p99 latency). Composite SLO combines SLOs from different services in a dependency graph.
- **SLA negotiation**: An SLA is a legal/financial contract between external parties; composite SLO is an internal engineering calculation about achievable reliability given a component graph.

______________________________________________________________________

## Related Skills

- **depends-on** → [`sli-formula-measurement`](../sli-formula-measurement/SKILL.md): Each component SLI formula must be defined before composing them into a system-level SLO; the good/valid design is the input to the serial/parallel composition math.
- **composes-with** → [`responsibility-control-slo`](../responsibility-control-slo/SKILL.md): Responsibility-Control SLO decomposes a target top-level SLO into per-team budgets; composite-slo provides the inverse direction — calculating what system SLO is achievable from those per-team numbers.
- **contrasts-with** → [`multi-tier-slo`](../multi-tier-slo/SKILL.md): Composite-slo combines SLOs from different services in a dependency graph; multi-tier-slo applies multiple targets to the same service. They are orthogonal and often applied together.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
