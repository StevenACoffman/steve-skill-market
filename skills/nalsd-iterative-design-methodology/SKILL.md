---
name: nalsd-iterative-design-methodology
description: |
  Use this skill when designing any large distributed system that will run on real hardware with real cost constraints. Call it when a design discussion has remained at the whiteboard level — components and arrows, no machine counts, no RAM estimates, no cost basis. Whiteboard architecture without resource estimates is not design.

  Trigger scenarios: system design interviews or reviews where proposals say "we'll scale horizontally," pre-production capacity planning, architecture reviews for new services, or any design where the team doesn't know what the bottleneck is at each scale tier.

  Do not use for single-machine applications or scripts where scale is not a design concern. Do not use as a replacement for post-production profiling — NALSD is a pre-production design discipline. Do not use the AdWords CTR worked example numbers as templates; derive your own from your actual traffic and data volumes.

  Key trigger: "We'll handle scale by adding more machines" — this is the specific anti-pattern NALSD addresses.
source_book: "The Site Reliability Workbook" by Betsy Beyer et al. (Google)
source_chapter: "Chapter 12 - Introducing Non-Abstract Large System Design; Chapter 11 - Managing Load"
tags: [system-design, capacity-planning, resilience, iterative, distributed-systems, feasibility]
related_skills: []
---

# NALSD Iterative Design Methodology

## R — Original Text (Reading)

> "In broad strokes, the NALSD process has two phases, each with two to three questions. In the basic design phase, we try to invent a design that works in principle. We ask two questions: Is it possible? Can we do better? In the next phase, we try to scale up our basic design... We ask three questions: Is it feasible? Is it resilient? Can we do better? Then we iterate. One design may successfully pass most of the phases, only to flounder later. When that happens, we start again, modifying or replacing components."
>
> "All systems will eventually have to run on real computers in real datacenters using real networks. Google has learned (the hard way) that the people designing distributed systems need to develop and continuously exercise the muscle of turning a whiteboard design into concrete estimates of resources at multiple steps in the process. Without this rigor, it's too tempting to create systems that don't quite translate in the real world."
>
> — Google SRE Workbook, Chapter 12

______________________________________________________________________

## I — Methodological Framework (Interpretation)

NALSD enforces a specific discipline: before moving to the next design stage, you must answer the current stage's question with real numbers — machine counts, RAM, disk IOPS, network bandwidth, cost per unit. "We'll scale horizontally" does not answer "Is it feasible?"

## Phase 1 — Basic Design

*Question 1: Is it possible?*
Ignore scale. If you had unlimited resources, would the design work in principle? This is the pure correctness question. Sketch the simplest design that satisfies the requirements. The answer establishes the logical correctness of the approach before physical constraints enter.

*Question 2: Can we do better?*
Given the basic design, is there a simpler, faster, or cheaper form? Can O(N) become O(ln N)? This is the optimization question at the algorithm/architecture level, before capacity estimation.

## Phase 2 — Scaled Design

*Question 3: Is it feasible?*
Apply real machine counts, RAM, disk, network, and cost. Does the basic design fit within physical constraints at the required scale? This is the checkpoint that eliminates whiteboard architectures that cannot be built. If feasibility fails, return to Phase 1 with the constraint as input.

*Question 4: Is it resilient?*
What happens when each component fails? What happens when an entire datacenter fails? This is the fault tolerance question. A design that is feasible but not resilient requires a new iteration.

*Question 5: Can we do better?*
After establishing feasibility and resilience, is there a cheaper or simpler form of the scaled design? This is the optimization question at the distributed-systems level.

**Iteration rule**: When a design flounders — fails feasibility, fails resilience, or reveals a prohibitive bottleneck — start again, modifying or replacing the components that failed. The final design is the end of a story of twists and turns, not a first-draft conclusion.

**The "non-abstract" constraint**: Each iteration must produce concrete estimates. Early assumptions heavily influence results; perfect assumptions are not required. The value is in combining many imperfect-but-reasonable estimates into a better understanding of the design.

______________________________________________________________________

## A1 — Past Application (From the Book)

## Case 1 — AdWords CTR Measurement System (Chapter 12)

- **Problem**: Design a system capable of measuring and reporting accurate click-through rates for every AdWords ad by joining click logs and impression logs. Requirements: 500,000 search queries/second, 10,000 ad clicks/second; 99.9% of dashboard queries < 1 second; 99.9% of data < 5 minutes old.
- **Application**: The NALSD process walked through one machine (feasible in principle, fails at scale), MapReduce (feasible at scale, batch latency violates the 5-minute freshness SLO), LogJoiner (streaming, feasible, then: what happens when it fails?), sharded LogJoiner (resilience via sharding), multi-datacenter (resilience via geographic redundancy). Each iteration identified the cheapest bottleneck that forced the next design.
- **Conclusion**: The final multi-datacenter design was not the first design proposed — it was the fifth iteration, each forced by the previous design's failure at a specific question. Whiteboard-first design would have stopped at MapReduce and discovered the latency violation in production.
- **Result**: The methodology produces designs that are affordable because the bottleneck at each iteration is always the cheapest resource to fix.

## Case 2 — Niantic/Pokémon GO (Chapter 11)

- **Problem**: Pokémon GO launched expecting X users and received 50X within the first week. The architecture used Google's regional Network Load Balancer with client-side SSL termination in Nginx instances. This choice was not evaluated against a 50× scale scenario — the feasibility question was not answered before launch.
- **Application**: Abstracted scaling assumptions (autoscaling handles it) failed because the Nginx SSL termination became the bottleneck under buffer pressure. The feasibility question "Is it feasible at 50× projected load?" was never asked with real resource estimates. Only after the crisis did the Traffic SREs migrate to GCLB, gaining anycast routing and connection termination at the edge.
- **Conclusion**: The Pokémon GO incident is the direct case study for what happens when Phase 2 Question 3 (Is it feasible?) is skipped. The autoscaler hit its ceiling because the underlying architecture had a resource bottleneck that was not identified before launch.
- **Result**: Within two days of migrating to GCLB, Pokémon GO became the single largest GCLB service. The structural architectural change (not more autoscaling) was the fix — which is what NALSD would have surfaced pre-launch.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — "We'll just scale horizontally"**
Language signals: "The design is simple — we'll add more instances." "We can always throw more hardware at it." "Autoscaling will handle the load."
Action: Apply NALSD Phase 2 Question 3 immediately. How many instances? At what cost? What is the bottleneck that limits horizontal scaling (network, shared database, coordination overhead)? "Horizontal scaling" is an answer to Question 3 only if it comes with machine counts and a bottleneck analysis.

**Scenario 2 — "The system failed at 10× the projected load"**
Language signals: "We didn't expect this much traffic." "The system handled our load tests but fell over in production." "Autoscaling didn't respond fast enough."
Diagnosis: Phase 2 Question 3 was answered with assumptions rather than estimates, or the test load was abstract (10× projected, not 10× observed peak). Apply NALSD retroactively to find the resource that became the bottleneck and design around it.

**Scenario 3 — Rate limiter design**
NALSD Phase 1 application: A centralized Redis rate limiter handling 50,000 RPS at P99 < 5ms. Is it possible? Single-node Redis handles ~100K ops/sec at \<1ms — yes, possible in principle. Can we do better? A centralized rate limiter is a SPOF and a network hop on every request. Better: token bucket per region with gossip synchronization. Phase 2: Is it feasible at 50K RPS globally? What is the replication lag budget? How many tokens per window? How many gossip rounds per second? These questions require real numbers before the design is valid.

**Distinguishing from adjacent skills**: NALSD is a pre-production design discipline. It does not govern how to respond to a production system that is already overloaded (use load management and load shedding techniques for that). It is not a postmortem methodology (use postmortem culture for that). It answers "can this design work?" before the design is built.

______________________________________________________________________

## E — Execution Steps

1. **State all requirements explicitly**: Traffic volume (requests/second), data volume (bytes/day), latency SLOs, freshness requirements, geographic scope. These are inputs to every subsequent calculation.

2. **Phase 1 — Basic design**:
   a. Sketch the simplest design that satisfies the requirements ignoring scale. Answer: Is it logically correct?
   b. Ask: Can we do better? Is there a simpler algorithm or architecture that satisfies the same requirements?

3. **Phase 2 — Scale the design**:
   a. **Feasibility**: Attach real numbers. How many machines? How much RAM? How much disk? At what network bandwidth? What is the cost per unit of load? Identify the cheapest bottleneck.
   b. **Resilience**: Enumerate failure modes for each component. What happens when this component fails? What happens when an entire datacenter fails? Does the design degrade gracefully?
   c. **Can we do better?** Given the feasible, resilient design, is there a cheaper or simpler form?

4. **Iterate on failure**: When the design fails at any question, name the specific constraint that caused the failure. Modify or replace the component that created the bottleneck. Return to Phase 1 with the new constraint as a given.

5. **Document the iteration story**: The final design is only credible if the path of failed iterations is documented. Each iteration establishes why the previous design was insufficient. Without the story, the final design looks arbitrary.

6. **State assumptions explicitly**: Every resource estimate involves assumptions. Document them. Future engineers must be able to identify which assumptions to challenge as scale changes.

**Completion criteria**: The final design has passed all five questions with concrete numbers, has a documented iteration path showing what failed at each stage, and has explicit assumptions that can be revisited as requirements change.

______________________________________________________________________

## B — Boundary ★

**Do not use when**:

- The system is small enough that scale is not a design concern (single machine, internal tool, sub-1000 RPS). NALSD overhead is not justified.
- The system is already in production and you're doing performance optimization. Use profiling and bottleneck analysis directly. NALSD is a pre-production discipline.
- You need a quick design proposal in a 45-minute interview. NALSD is the full discipline; the interview context requires a compressed version that still produces numbers but may skip some iterations.

**Failure patterns**:

- **Stopping at Phase 1**: Many design reviews produce a logically correct Phase 1 design and stop. The design is never validated for feasibility or resilience at real scale.
- **Abstract numbers**: "We'll need N machines" without specifying what N is. The forcing function is attaching actual estimates, even rough ones.
- **Single-iteration thinking**: Proposing a design without iterating. The iteration rule is the core discipline — when the design flounders, start again.
- **Missing the cheapest bottleneck**: The iteration should target the bottleneck that is cheapest to fix, not the most impressive to solve. Over-engineering a non-bottleneck while ignoring the real one is a common failure mode.

**Author blind spots**:

- The AdWords CTR example is Google-specific infrastructure. Teams outside Google must substitute their own cost basis, hardware assumptions, and infrastructure primitives. The methodology is transferable; the specific numbers are not.
- NALSD focuses heavily on compute and storage capacity. Network topology, latency between regions, and cross-datacenter replication costs are mentioned but not fully developed as design constraints.
- The methodology assumes the designer has access to infrastructure cost data. In organizations without a clear cost basis for compute, NALSD feasibility questions are harder to answer concretely.

**Easily confused with**:

- **Capacity planning**: Capacity planning is an ongoing operational activity for existing systems. NALSD is a design-time discipline for new systems.
- **System design interviews**: Interview-format system design often remains at Phase 1. NALSD requires Phase 2 with real numbers, which is rarely completed in a 45-minute interview.
- **Architecture documentation**: Documenting the final design is not NALSD. NALSD is the iterative process that produces the design.

______________________________________________________________________

## Related Skills

- **contrasts_with**: overload-recovery-sequencing — NALSD prevents production overload by validating capacity feasibility before build; overload recovery addresses a team and system already in distress
- **composes_with**: error-budget-policy-framework — the SLO targets established as NALSD feasibility criteria become the targets that the error budget policy enforces in production

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04
