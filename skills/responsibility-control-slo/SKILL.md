---
name: responsibility-control-slo
description: |
  Use this skill when designing SLI/SLO assignments for teams in multi-team architectures, or
  when diagnosing why a team is being paged for incidents they cannot resolve. The core question
  this skill answers: "Which team should own this metric, and how should it be scoped?"

  WHEN TO CALL: (a) A user is running an SLO workshop and needs to decide which team owns which
  metric; (b) a team is responsible for an end-to-end metric that aggregates variables from
  multiple teams; (c) you need to decompose a top-level SLO target across dependent teams; (d)
  a composite metric (latency, availability, error rate) spans a control boundary; (e) a team is
  being held accountable for a dependency they don't control; (f) the user asks "how do we
  split the latency budget?" or "which team should own the availability SLO?"

  WHEN NOT TO CALL: Do not call for questions purely about SLO numeric targets or error budgets
  (use the Lagom SLO framework). Do not call when the question is about whether a team should
  exist at all or how to restructure the organization (use `ownership-trio` and
  `oncall-ownership-sustainability`). Do not call for SLI measurement tooling selection.

  KEY TRIGGER SIGNAL: "The team gets paged but has to escalate because the issue is in another
  team's service", "we measure end-to-end latency but the frontend team controls only part of
  it", "how do we assign the SLO when the metric includes network we don't control."
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20240220_185447_responsible-for-control.md, 20230808_153608_valid-vs-total.md, 20250803_112619_service-level-topology.md
tags: [ownership, slo, team-boundaries, accountability, organizational-design, sli]
related_skills:
  - slug: ownership-trio
    relation: depends-on
  - slug: composite-slo
    relation: composes-with
---

# Responsibility-Control Alignment for SLO Assignment

## R — Original Text (Reading)

> You should never be responsible for what you don't control. That is because most metrics usually
> aggregate a bunch of variables, not all of which are in your control. It is unfair and unrealistic
> to hold someone responsible for what they can't control.
>
> The reverse is also true: you should take control of what you are responsible for. This is a great
> opportunity to rethink the team boundaries and fix broken ownership. Ideally you want the teams to
> have control over all the variables that contribute to the metrics that are important for their
> service consumer. The Service Level Objectives should trickle down through the organization.
>
> — Alex Ewerlöf, 20240220_185447_responsible-for-control.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Every metric aggregates multiple variables. In multi-team architectures, those variables are owned
by different teams. Assigning a composite metric to a single team as their SLO creates a structural
mismatch: the team is accountable for behavior they cannot change. The fix has two directions:

**Direction 1 — Scope the SLI to what the team controls.**
Use the `valid` denominator in the SLI formula (`good / valid`, not `good / total`) to exclude
events caused by variables outside the team's control. Examples: exclude traffic from dependencies
that failed, exclude DDoS traffic the team did not invite, exclude network latency the team cannot
influence. The valid filter scopes the optimization target to what the team can actually improve.

**Direction 2 — Decompose top-level SLOs into per-team budgets.**
When a consumer-facing target exists (e.g., 500ms end-to-end latency), subtract the uncontrollable
portion (network latency measured empirically), then allocate the remaining budget across the teams
that contribute to it. Allocation options: keep one team's budget fixed and force the other to meet
the remainder; split proportionally to current measured values; or negotiate based on where
improvement is feasible. Always communicate the budget decomposition transparently and let the
teams negotiate the split — do not impose from above without their input.

**Direction 3 — Rethink team boundaries when the mismatch cannot be scoped away.**
Sometimes a dependency is so entangled that no scoping can cleanly separate the variables.
This is a signal to examine the team architecture: the dependency may need to be moved,
rewritten, or merged into the responsible team's ownership. Conway's Law implies that systems
reflect org structure; if a single-consumer service lives in a separate team for historical
reasons, consolidating it removes the SLO mismatch and simplifies the ownership model.

The service level topology (Offer → Use → Risk → Metrics) provides the graph for mapping which
teams contribute which variables to each consumer-facing failure mode — this is the analytical
scaffold for making the decomposition.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Mobile/Backend Latency Budget Decomposition

- **Problem:** User-facing latency of 602ms exceeded a 500ms target. Stakeholders blamed the
  mobile team. But the total included mobile processing (285ms), backend processing (186ms), and
  network latency (131ms — outside both teams' control).
- **Application:** The author subtracted the uncontrollable network component: 500ms − 131ms =
  369ms total budget for both teams. The current consumption by mobile + backend was 471ms.
  Three decomposition options were evaluated: fix mobile only (183ms target), fix backend only
  (84ms target), or distribute proportionally (mobile 78% of 285ms = 222ms; backend 78% of
  186ms = 145ms). Measurement baselines were used to check feasibility.
- **Conclusion:** The correct decomposition required knowing current performance per team and
  what improvements were feasible — not political negotiation. Transparent communication of the
  budget to both teams was essential.
- **Result:** Each team received an SLO scoped to variables they controlled. The mobile team
  stopped being unfairly blamed for backend latency. The uncontrollable network component was
  explicitly excluded from both teams' SLOs.

### Case 2: Service X Single-Consumer Dependency Creating Ownership Ambiguity

- **Problem:** A backend team's latency SLO was materially affected by an external dependency
  (Service X) owned by a separate team, with no other consumers, using a different programming
  language, and existing only as a historical reorg artifact.
- **Application:** The backend team had responsibility for the end-to-end SLO but no mandate
  over Service X's behavior. The author identified three resolution options: move Service X's
  ownership to the backend team; create a new service in the backend's language that replaces
  Service X; or merge Service X's functionality directly into the backend.
- **Conclusion:** The mismatch between control boundary and SLO scope was a Conway's Law
  symptom: the org structure had not caught up with the actual service consumption pattern.
  The resolution was to align the team boundary with the metric boundary.
- **Result:** Whichever consolidation path was chosen would give the backend team full ownership
  of all variables contributing to their latency SLO, enabling them to commit to and achieve it.

### Case 3: News Site Freshness SLI Scoped to Front-End Team's Control Boundary

- **Problem:** A media company wanted a freshness SLI measuring time from CMS publish to
  article appearing on the site. The full path included the CMS (owned by editorial, not tech),
  BFF and CDN (owned by the front-end team), and browser rendering (also front-end). The
  front-end team could not control CMS behavior, editorial decisions, or CDN infrastructure
  above the BFF.
- **Application:** Using the valid filter, the front-end team scoped their SLI to: articles in
  the breaking news section published in the last 24 hours, measured from BFF cache onward
  (excluding CMS → BFF transit), targeting under 1 minute from the API call to the BFF.
- **Conclusion:** The valid scope excluded everything the team could not control, leaving a
  metric the team could actually optimize.
- **Result:** The team's optimization efforts focused on the BFF cache layer and SSR pipeline,
  which they owned. They were not penalized for CMS delays or CDN infrastructure failures.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An SLO workshop discovers that a team's latency SLO includes response time from a downstream
   dependency they do not own — the team is being paged for that dependency's failures.
2. A multi-team system has a consumer-facing SLO of 99.9% availability but no one has calculated
   what each contributing team's individual SLO target should be to achieve it.
3. A team asks "can we exclude DDoS traffic from our success rate SLI?" — this is a valid-vs-total
   scoping question that this skill resolves.

### Language Signals (Activate When These Appear)

- "How do we split the SLO between the mobile team and the backend team?"
- "Our error rate includes errors from a dependency we don't control"
- "We're being paged for incidents that always turn out to be someone else's problem"
- "What should each team's SLO be if the end-to-end target is X?"
- "We don't want to be punished for our dependency's downtime"

### Distinguishing from Adjacent Skills

- Difference from `ownership-trio`: ownership-trio diagnoses whether knowledge, mandate, and
  responsibility are co-located in the same entity. responsibility-control-slo is the technical
  instrument that operationalizes the mandate principle at the metric level — it specifies
  exactly which metric scope matches a team's actual control boundary.
- Difference from `sli-monitoring-design-maturity`: sli-monitoring-design-maturity is about the maturity of SLI
  design (consumer-awareness, task-awareness). responsibility-control-slo is specifically about
  the control-boundary scoping of the valid denominator, regardless of what stage the SLI is at.

______________________________________________________________________

## E — Execution Steps

1. **Identify the composite metric and draw the contribution graph**

   - List all variables that contribute to the metric (e.g., for end-to-end latency: mobile
     processing, backend processing, network latency, database query time).
   - Map each variable to the team that controls it.
   - Completion criteria: A table of {variable, contributing team, measurable separately Y/N}.

2. **Identify uncontrollable variables and measure their baseline contribution**

   - Variables controlled by external parties (cloud provider, internet, third-party services)
     are candidates for exclusion from the valid scope.
   - Measure the uncontrollable component over a representative period.
   - Completion criteria: Quantified baseline for each uncontrollable component (e.g.,
     "network latency averages 131ms, range 90–200ms").

3. **Apply the valid filter to scope each team's SLI**

   - For event-based SLIs: define valid events as those where the failure mode is within the
     team's control boundary. Exclude: events caused by dependency failures, DDoS/invalid
     traffic, and events in components the team does not own.
   - For time-based or latency SLIs: subtract the uncontrollable component from the total
     budget.
   - Completion criteria: Each team has a scoped SLI formula where all failure modes in the
     denominator are within their control.

4. **Decompose the top-level SLO into per-team budgets**

   - Calculate the total budget after removing uncontrollable portions.
   - Present the allocation options (fix one team, fix both proportionally, negotiate).
   - Communicate the budget decomposition to all contributing teams.
   - Completion criteria: Each team has a numeric SLO target derived from the top-level target
     and their contribution, agreed to by the teams (not imposed unilaterally).

5. **Check for unresolvable control mismatches**

   - If a single-consumer dependency is owned by a separate team purely for historical reasons,
     flag this as a Conway's Law alignment opportunity.
   - Stop condition: If the valid scoping cannot cleanly exclude the uncontrollable variable
     (because it is deeply intertwined with the team's own component), escalate to the
     `oncall-ownership-sustainability` skill to recommend a team boundary change.
   - Completion criteria: Either a valid-scoped SLI is defined, or a structural recommendation
     is made to realign ownership with the SLO scope.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is about the right SLO target level (too high vs. too low) — use the Lagom SLO
  framework and 10x/9 cost reasoning.
- All variables contributing to a metric are owned by the same team — no decomposition needed;
  proceed directly to SLI stage assessment.
- The control mismatch is so deep that the team structure needs to change — use
  `oncall-ownership-sustainability` to recommend the structural fix first.

### Failure Patterns Warned by the Author

- **ce09 (Senior Engineer Resistance to SLI Mental Shift)**: Engineers use valid scoping
  incorrectly to exclude too many events and make their SLO trivially achievable — the valid
  filter must exclude only truly uncontrollable events, not just inconvenient ones.
- **ce18 (SLI That Is Not Under the Team's Control)**: The archetypal failure this skill
  prevents — a team assigned an SLI aggregating variables from multiple teams, paged for
  incidents they must escalate elsewhere.
- **ce27 (Metrics Weaponized)**: Valid scoping that excludes too broadly can be gamed to make
  metrics look better than reality — monitor for SLI scope changes that coincide with poor
  performance periods.

### Author's Blind Spots / Limitations

- **Cost quantification is hand-wavy**: The latency budget decomposition methodology shows
  how to split the budget but does not provide a rigorous method for deciding whether the
  resulting per-team targets are achievable without quantifying the cost of achieving them.
  The 10x/9 rule gives a rough cost multiplier but not engineering feasibility assessment.
- **Assumes consumer identity is knowable**: The service level topology requires identifying
  consumers and their tasks before determining which variables matter. For large platform APIs
  with heterogeneous consumers, the consumer identity and task set may require significant user
  research investment.
- **Assumes organizational access**: Running the decomposition workshop, negotiating per-team
  budgets, and recommending team boundary changes requires Staff+/Principal authority. Mid-level
  engineers can identify the mismatch but may not have the standing to resolve it.

### Easily Confused With

- **Composite SLO Calculation**: composite SLO computes the system-level SLO from component
  SLOs using serial/parallel rules. responsibility-control-slo works in the reverse direction
  — it decomposes a target system-level SLO into per-team budgets. They are complementary:
  composite SLO calculates what you get; responsibility-control-slo allocates what you need.

______________________________________________________________________

## Related Skills

- **depends-on** → [`ownership-trio`](../ownership-trio/SKILL.md): The Ownership Trio provides the organizational principle (mandate = control boundary); this skill operationalizes that principle as the SLI valid-denominator scoping rule.
- **composes-with** → [`composite-slo`](../composite-slo/SKILL.md): Responsibility-Control SLO decomposes a top-level target into per-team budgets; composite-slo provides the math for how those per-team SLOs recombine into a system-level number.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
