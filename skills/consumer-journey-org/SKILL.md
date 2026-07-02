---
name: consumer-journey-org
description: |
  Use this skill when evaluating, diagnosing, or designing an organizational structure
  and you need a principled method for determining team boundaries. The core insight is
  that the consumer journey — the sequence of steps a user takes to accomplish a goal
  with the service — should be the primary driver of how teams are structured, not the
  technology they produce or the function they perform.

  Call this skill when: reliability problems persist despite strong individual team
  performance (individual SLOs are green but the end-to-end experience is broken);
  incidents consistently occur at the handover point between two teams; leadership is
  considering a reorg and needs a non-arbitrary basis for new team boundaries; a team
  cannot clearly articulate who their consumer is or what journey they own.
tags: [organization, conways-law, consumer-journey, reliability, team-topology]
---

# Consumer Journey as Organizational Architecture Driver

## R — Original Text (Reading)

> The reliability of a service is directly impacted by the shape of the organization
> providing it. The shape, not the budget, headcount, or maturity level — as irresponsible
> leaders like to frame it!
>
> A system is not the sum of its parts, it's the product of their interactions. If we have
> a system of improvement that's directed at improving the parts you can be absolutely sure
> that the performance of the whole will not be improved. — Russell L. Ackoff
>
> Poor organization architecture ignores these obstacles: every team dependency increases
> the risk of misunderstanding. Every point of handover opens a miscommunication crack for
> things to fall into. Every unclear or broken ownership is a vulnerability for the blame game.
>
> The key perspective to unlock the answer is the consumer journey. Consumer journey is a
> generalized term that applies to services that have internal or external consumers. It is
> concerned with the high-level journeys as opposed to low-level flows. The high-level view
> is more useful in the context of organization design.
>
> — Alex Ewerlöf, 20240726_212043_organization-architecture.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The consumer journey framework for organizational architecture is an application of Conway's
Law in reverse (the Inverse Conway Maneuver): instead of letting technical architecture
dictate organizational structure, deliberately design organizational structure to match the
consumer journey, and the system architecture will follow.

**The fundamental diagnostic:**
Two organizations can have identical technology and identical team-level quality metrics and
still produce wildly different end-to-end reliability. The differentiating factor is whether
the team boundaries align with the consumer journey or cut across it. When a consumer journey
crosses multiple team boundaries, every crossing is a potential incident waiting to happen —
not because individuals are incompetent, but because the structure creates miscommunication
channels, ownership ambiguity, and finger-pointing incentives.

**The Kebab vs. Cake spectrum:**

*Kebab org:* Teams organized by technical capability (frontend team, identity team, payment
team). The consumer journey runs perpendicular to team boundaries like a skewer through the
meat. Every consumer action requires multiple team handovers. Individual capabilities may be
high quality, but incidents at handover points are common, slow to resolve, and difficult to
assign. Adding QA, UX, and operations teams to "fix" the handover problem increases communication
overhead (Brooks's Law) without addressing the root cause.

*Cake org:* Teams organized by consumer journey (reader experience team, CMS team). Each team
owns the end-to-end consumer experience for their class of users. The team is vertically
integrated — it contains all the roles required to deliver its journey (frontend, backend,
DevOps, optionally UX). Cognitive load is managed by adding abstraction layers beneath
the journey team (platform layer, identity/payment SDK), not by splitting the journey
horizontally.

**The heuristic:**
When a new reliability symptom appears, ask: "Does this incident live entirely within one
team's ownership boundary?" If the answer is consistently "no" — if incidents repeatedly
require multiple teams to diagnose and resolve — the organizational architecture is the
root cause, not the teams' technical quality.

**Micro-optimization trap:**
TDD, CI/CD, SRE practices, refactoring, and tech debt payment are micro-optimizations with
bounded returns. They improve individual components. They cannot improve the interactions
between components that are owned by different teams. Investing in micro-optimizations while
the organizational architecture misaligns team boundaries with consumer journeys produces
diminishing returns at the system level.

**The generalist implication:**
Cake organizations require generalists (T-shaped or Π-shaped talent) because a journey team
needs to cover the full stack. Kebab organizations can accommodate specialists but produce
the internal handover problems specialists cannot solve alone.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Constant Reorg Without Understanding J-Curve — Org Architecture Failure (Ce11)

- **Problem:** Organizations in constant reorg mode exhibit the same symptoms regardless of
  how many times they restructure: engineering managers complain about "cat herding," team
  members complain about micromanagement, C-suite observes high operational cost and low
  productivity. The reorg is the intervention; the J-curve (productivity dip before recovery)
  is ignored; another reorg is initiated before the first one recovers.
- **Application:** The author identifies that the root cause is not the reorgs themselves but
  the failure to align organizational architecture with consumer journeys. Restructuring that
  doesn't change the consumer-journey ownership model just rearranges the problem. Each
  reorg is a J-curve the organization enters at the bottom of the previous one.
- **Conclusion:** Reorgs are only effective when they restructure team boundaries to reduce
  handovers in the consumer journey. Reorgs that keep the kebab structure but rename teams
  or change reporting lines produce churn without improvement.
- **Result:** Companies in constant reorg mode have typically never diagnosed the root cause
  (Conway's Law misalignment) and are treating the symptom (poor reliability, low velocity).

### Case 2: Adding Headcount as Reliability Fix — the Fallacy (Ce12)

- **Problem:** When reliability or velocity degrades, a common leadership response is to hire
  more engineers, add process layers, and create central babysitting teams (central QA, central
  ops, central UX). Each addition increases communication overhead (Brooks's Law) without
  addressing the root cause.
- **Application:** The author uses this as the canonical counter-example for the consumer
  journey org principle. Adding headcount to a kebab organization increases the number of
  handover points, not the quality of consumer journeys. The symptom (poor reliability) is
  a proxy for the root cause (organizational architecture mismatch). Central teams that
  "cover" the handover are themselves new handover points.
- **Conclusion:** The diagnostic question is not "do we have enough people?" but "do the team
  boundaries align with the consumer journey?" Headcount cannot fix a structural misalignment.
- **Result:** This is why large organizations (1000+ engineers) can still have poor end-to-end
  reliability while small cake-organized orgs (300 engineers) deliver better consumer experience
  with lower incident rates — the author's empirical comparison from two companies doing roughly
  the same product.

### Case 3: 14-Person Specialist Team Discovers Generalist Model (From When-a-Team-Is-Too-Big)

- **Problem:** A 14-person team was split by technical specialty (front-end and back-end task
  forces). The split created dependencies between task forces, increased standup time (both
  groups needed each other), and produced ownership ambiguity for cross-cutting concerns
  like CI/CD and on-call.
- **Application:** The team gradually evolved toward a generalist model where all engineers
  were expected to cover the full stack for their consumer journey. The catalyst was budget
  pressure ("scarcity breeds clarity") which removed the slack that had allowed specialists
  to avoid cross-training.
- **Conclusion:** Specialist teams organized by technology (front-end, back-end) are a kebab
  structure inside a single team. The same Conway's Law mismatch that affects org-level
  kebab also affects intra-team kebab.
- **Result:** Faster delivery, higher quality, and overall cheaper operation after the
  generalist transition. Some specialists left because the model didn't fit their career
  preferences, which the team absorbed without backfilling.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A company has high individual team SLOs (each team's service is meeting its reliability
   target) but customer-facing end-to-end reliability is poor. Incidents consistently involve
   multiple teams. The question is whether this is a technical problem or an organizational
   architecture problem.
2. A platform engineering leader is redesigning team boundaries after a failed product launch
   that required coordinating six kebab teams for three months. They need a principled basis
   for new boundaries that would allow future product launches without that coordination tax.
3. A new engineering leader is joining a 500-person org and needs a diagnostic framework for
   assessing whether the current org structure is causing the reliability problems they've
   been hired to fix.

### Language Signals (Activate When These Appear)

- "Each team's metrics are fine but the end-to-end experience is broken."
- "We need a central team to coordinate between the other teams."
- "Incidents always fall between teams — no one owns that piece."
- "We keep having to spin up special projects to get teams to work together."
- "Our DORA metrics are improving but customer satisfaction isn't."

### Distinguishing from Adjacent Skills

- Difference from `ephemeral-taskforce`: `ephemeral-taskforce` is a temporary delivery
  instrument that operates within the existing org structure. `consumer-journey-org` is about
  changing the org structure itself. If the structural root cause is misalignment with consumer
  journeys, an ETF is a workaround; this skill addresses the root cause.
- Difference from `ownership-trio`: `ownership-trio` diagnoses whether an individual or team
  has all three ownership elements. `consumer-journey-org` diagnoses whether the team boundaries
  themselves enable the ownership trio to exist — a team cannot own a journey it doesn't fully
  control.

______________________________________________________________________

## E — Execution Steps

1. **Map the consumer journeys**

   - Identify who the consumers of the service are (internal or external).
   - For each consumer class, map the high-level sequence of steps they take to accomplish
     their goal with the service.
   - Focus on journeys, not flows — high-level, cross-channel, including failure states.
   - Completion criteria: A documented list of 3–10 primary consumer journeys with the
     key steps in each.

2. **Map current team boundaries against consumer journeys**

   - For each consumer journey, identify which teams own which steps.
   - Count the number of team boundary crossings in each journey.
   - Completion criteria: A visual showing how many teams a consumer journey touches and
     where the handover points are.

3. **Diagnose the reliability impact of handovers**

   - Review incident history: what percentage of incidents involved multiple teams?
   - Review incident resolution time: are multi-team incidents slower to resolve?
   - Review postmortems: how often does "which team is responsible?" appear as a delay factor?
   - Completion criteria: A quantified answer to "what fraction of reliability problems
     are attributable to handover points rather than component failures?"

4. **Identify the target org model: kebab, cake, or hybrid**

   - Cake: align team boundaries with consumer journeys; manage cognitive load with
     abstraction layers below the journey team.
   - Kebab: retained only where specialization requirements (security-sensitive systems,
     highly regulated domains) justify the handover cost explicitly.
   - Hybrid: most real organizations — identify which journeys are high enough impact to
     justify full cake ownership and which can tolerate kebab structure.
   - Completion criteria: A target state with rationale for each team boundary decision.

5. **Model the reorg J-curve before proceeding**

   - Estimate the productivity dip duration and depth.
   - Ensure organizational stability and leadership patience to ride through the J-curve.
   - Do not initiate a reorg during a period of active contraction or crisis.
   - Completion criteria: Leadership explicitly acknowledges the J-curve and commits to
     not abandoning the reorg before recovery.

6. **Validate with consumer journey ownership assignments**

   - For each proposed team, assign: "this team owns these consumer journeys end-to-end."
   - Verify that every consumer journey has exactly one team with clear ownership.
   - Check that each team has the ownership trio (knowledge, mandate, responsibility) for
     their assigned journeys.
   - Completion criteria: Every consumer journey has one owning team; no journey has
     unresolved ownership gaps.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is about a temporary cross-team delivery initiative — use `ephemeral-taskforce`.
- Individual teams are already aligned with consumer journeys and the reliability problem is
  within a team's internal practices — use relevant technical skills (SLI design, on-call
  practices, etc.).
- The organization is too early-stage to have meaningful consumer journey complexity — a
  single team covering everything is appropriate until scale demands differentiation.
- The consumer cannot be identified — in very large platform services where the "consumer" is
  itself a diverse collection of hundreds of teams with different journeys, consumer journey
  alignment may not be definable at the platform level. The skill's assumption that consumer
  journeys can be enumerated may not hold.

### Failure Patterns Warned by the Author

- **Constant reorg without J-curve awareness (ce11):** Reorging before the previous reorg
  has recovered accumulates the worst effects of J-curves. Each reorg must be allowed to
  complete its recovery before the next is initiated.
- **Adding headcount as reliability fix (ce12):** Central babysitting teams (central QA,
  central ops, central UX) are a symptom of kebab organization dysfunction. They add
  communication overhead and new handover points without addressing the root cause.
- **Micro-optimization trap (ce30):** Investing in TDD, CI/CD, SRE practices, and tech
  debt while the organizational architecture remains a kebab produces bounded returns. When
  DORA metrics improve but end-to-end reliability does not, the org architecture is the
  constraint, not the engineering practices.

### Author's Blind Spots / Limitations

- The consumer identity assumption: the framework assumes that consumer journeys can be
  identified and enumerated. For large platform services (infrastructure platforms, data
  platforms) where the "consumer" is itself hundreds of internal teams with diverse needs,
  defining a coherent consumer journey may be impossible or may produce too many journeys
  to organize around.
- The framework favors the cake model but acknowledges that kebab has legitimate uses
  (specialization, regulatory requirements, loose coupling needs). The prescriptive framing
  may underweight the contexts where kebab is genuinely appropriate.
- The empirical comparison (300-engineer cake org vs. 1000-engineer kebab org) is from one
  author's direct experience. The causal claim is plausible but not established by controlled
  study.

### Easily Confused With

- **Team Topologies (Skelton & Pais):** Skelton and Pais define Stream-Aligned, Platform,
  Enabling, and Complicated-Subsystem teams. The consumer journey framework maps roughly to
  Stream-Aligned (cake) and Platform (abstraction layer) teams but uses different vocabulary.
  The author does not use Team Topologies terminology directly.
- **Conway's Law:** Conway's Law is the explanatory mechanism ("systems mirror organizational
  communication structure"). The consumer journey framework is the prescriptive application
  — use consumer journey analysis to design the communication structure you want to see in
  your systems.

______________________________________________________________________

## Related Skills

- **depends-on** → `ownership-trio`: Consumer journey org only produces reliability if each journey team holds all three ownership elements; a team cannot own a journey it doesn't fully control.
- **contrasts-with** → `ephemeral-taskforce`: ETF is a temporary execution instrument that operates within the existing org structure; consumer-journey-org permanently restructures team boundaries to align with consumer journeys.
- **composes-with** → `service-level-topology`: The consumer journey identifies the topology starting point (who uses what, for what task); service-level-topology provides the SLI derivation methodology for each journey the org redesign produces.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
