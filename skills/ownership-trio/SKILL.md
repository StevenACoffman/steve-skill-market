---
name: ownership-trio
description: |
  Use this skill when diagnosing why a team, individual, or org structure is failing to deliver
  reliable software — or when designing a team structure, role, or accountability model from scratch.

  WHEN TO CALL: A user describes a situation where (a) a team is responsible for a system but cannot
  fix it; (b) a manager is making architectural calls but not bearing the consequences; (c) a
  knowledgeable engineer has no authority to act; (d) you need to argue for or against a DevOps,
  SRE, or "you build it you own it" model; (e) an on-call rotation is widely described as
  punishment rather than ownership.

  WHEN NOT TO CALL: Do not call when the question is purely about SLO targets, SLI formula design,
  or cost-of-reliability reasoning — those have dedicated skills. Do not call when the question is
  about individual career development rather than team/org structure.

  KEY TRIGGER SIGNAL: Any phrasing that contains "who is responsible for X", "we know what to fix
  but cannot get approval", "the team that gets paged can't fix the problem", "we are being held
  accountable for things we don't control", or "you build it you run it" versus "you build it
  you own it."
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20230617_174506_you-build-it-you-own-it.md, 20230801_171054_broken-ownership.md, 20240220_185447_responsible-for-control.md
tags: [ownership, accountability, organizational-design, devops, reliability]
related_skills:
  - slug: oncall-ownership-sustainability
    relation: composes-with
  - slug: responsibility-control-slo
    relation: composes-with
  - slug: ephemeral-taskforce
    relation: composes-with
---

# Ownership Trio (Knowledge + Mandate + Responsibility)

## R — Original Text (Reading)

> You cannot be **responsible** for something you don't control. You need the **mandate**.
>
> You cannot use that **mandate** effectively over something you don't understand. You need **knowledge**.
>
> You gain **knowledge** only if you are fully **responsible** for the consequences of your **mandate**.
>
> You can see how knowledge, mandate and responsibility feed each other and are inseparable. Only through
> full ownership can the team reach autonomy, mastery and purpose. There's no shortcut to quality and
> reliability other than putting smart people fully in charge of implementing the vision.
>
> — Alex Ewerlöf, 20230617_174506_you-build-it-you-own-it.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Genuine ownership of a service or system requires three elements to be present simultaneously in the
same entity (team or individual):

- **Knowledge**: understanding how the system works and fails — earned through operating it, being
  on-call for it, and debugging its incidents.
- **Mandate**: the authority to make decisions that change the system — architecture, tooling,
  deployment frequency, dependency choices.
- **Responsibility**: accountability for outcomes, including the on-call burden when things break
  at 3 AM.

The three elements form a self-reinforcing loop: responsibility creates the urgency to develop
knowledge; knowledge makes mandate effective; mandate is what converts knowledge into action.
Remove any single element and the loop breaks. The result is not partial ownership — it is a
specific, named failure mode (see the 6 Broken Ownership Archetypes skill).

Werner Vogels's 2006 phrase "you build it, you run it" captures the responsibility element but
omits mandate and knowledge. Ewerlöf's formulation "you build it, you own it" is the correction:
ownership is the full triad, not just operational accountability.

Practical tests: Does the on-call engineer have the commit rights to fix what they're being paged
about? Does the architect live with the consequences of their design decisions? Does the manager
who sets technical direction also bear the operational cost of that direction?

When all three are present, teams naturally build toward autonomy, mastery, and purpose. When any
is missing, expect one of the six broken ownership failure patterns to manifest.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Front-End Team Blamed for Latency They Cannot Control

- **Problem:** In a mobile/backend/database architecture, the mobile team was regularly blamed and
  pressured whenever user-facing latency exceeded targets — despite the mobile team having no
  control over backend response time or network latency.
- **Application:** The author applied the Ownership Trio diagnostic. The mobile team had
  knowledge (they understood their own code) and responsibility (they were paged), but lacked
  mandate over the latency variables that were outside their code boundary. This is the Foot
  Soldier archetype.
- **Conclusion:** The correct fix was to decompose the total latency budget into the portions
  each team actually controlled, then assign SLOs scoped to each team's control boundary.
- **Result:** Each team received a latency target they could actually influence, eliminating the
  unfair accountability pattern. The teams were able to negotiate the budget split based on
  measured baselines.

### Case 2: Developers Throw Code Over the Wall

- **Problem:** Developers pushed code to an IT operations team responsible for running and
  keeping it alive. The operations team had responsibility (they were on-call) but no knowledge
  (they didn't build or understand the code) and no mandate (they couldn't change the
  architecture or implementation).
- **Application:** This matches the Baby Parent archetype — responsibility without knowledge
  or mandate. The author's diagnosis: this is the structural outcome of separating "build" from
  "run," the inverse of "you build it, you own it."
- **Conclusion:** The only fix is to reunite the three elements — typically by making the
  development team responsible for production operations, which forces them to acquire operational
  knowledge and motivates them to use their mandate to prevent recurring incidents.
- **Result:** Teams that adopt full ownership develop radically better feedback loops: production
  incidents directly inform architectural decisions, and the urgency of on-call pain motivates
  investment in prevention.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An engineering manager is setting technical direction and making architectural decisions, but
   the engineers who implement and operate those decisions are the ones getting paged when things
   break.
2. A platform or SRE team is responsible for keeping a service running but was not involved in
   designing it, cannot change its code, and must escalate every incident to the development team
   to get anything fixed.
3. A team knows exactly what is wrong and how to fix it but cannot get approval or budget from
   leadership to make the change — so incidents keep recurring.

### Language Signals (Activate When These Appear)

- "We know what's broken but we can't get approval to fix it"
- "The ops team / SRE is responsible but the devs own the code"
- "Developers aren't on-call so they don't care about reliability"
- "Management keeps making decisions that make our lives harder"
- "We're being held accountable for latency / errors that come from another team's service"

### Distinguishing from Adjacent Skills

- Difference from `oncall-ownership-sustainability`: ownership-trio is the diagnostic foundation —
  it identifies whether all three elements are present. oncall-ownership-sustainability uses the
  same Venn diagram to name the six specific failure patterns when elements are missing. Use
  ownership-trio first to check presence/absence; use oncall-ownership-sustainability to name the
  specific dysfunction and recommend a targeted fix.
- Difference from `responsibility-control-slo`: responsibility-control-slo applies the mandate
  principle to SLI/SLO scoping — it is the technical instrument (metric boundary = control
  boundary). ownership-trio is the organizational principle (the triad must be co-located).

______________________________________________________________________

## E — Execution Steps

1. **Identify the entity under evaluation (team, individual, or role)**

   - Completion criteria: You can name one specific team, person, or role to evaluate.

2. **Test for Knowledge: does this entity deeply understand the system's failure modes?**

   - Ask: Are they on-call? Can they explain recent incidents? Do they debug production issues?
   - Completion criteria: Explicit yes/no. If no, note that knowledge is the missing element.
   - Stop condition: If knowledge is absent, document this as a Foot Soldier or Coma archetype
     candidate — proceed to step 3 to test the other two.

3. **Test for Mandate: does this entity have authority to change the system?**

   - Ask: Can they merge code? Can they change the architecture? Can they choose or reject
     dependencies? Do they control deployment frequency?
   - Completion criteria: Explicit yes/no. If no, note that mandate is the missing element.

4. **Test for Responsibility: does this entity bear the consequences of outcomes?**

   - Ask: Are they on-call? Are they evaluated on reliability? Do they see user complaints?
   - Completion criteria: Explicit yes/no. If no, note that responsibility is the missing element.

5. **Identify which elements are present and absent**

   - Completion criteria: You have a clear {Knowledge: Y/N, Mandate: Y/N, Responsibility: Y/N}
     assessment.

6. **Name the pattern and prescribe the fix**

   - All three present: full ownership — no structural fix needed, look elsewhere for the problem.
   - One or more missing: consult the `oncall-ownership-sustainability` skill to name the specific
     archetype and target the intervention.
   - Completion criteria: A concrete structural recommendation (e.g., "give the platform team
     commit access to the services they operate" or "include developers in the on-call rotation").

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is about choosing between SLO targets or calibrating the right SLO level for a
  service — use `responsibility-control-slo` or the Lagom SLO framework instead.
- The question is about an individual engineer's career development or promotion readiness —
  ownership-trio is an organizational diagnostic, not a personal performance model.
- The organization is in a regulated context (financial, medical, government) where legal
  accountability genuinely requires separating "accountable" from "responsible" roles — this
  is the one domain where the separation is legitimate.

### Failure Patterns Warned by the Author

- **ce01 (Monkey with a Gun)**: Manager calls shots without operational knowledge or on-call
  responsibility. The most common broken ownership pattern in hierarchical organizations.
- **ce02 (Foot Soldier)**: Engineer has knowledge and responsibility but cannot get approval to
  change the system. Leads to attrition of the most capable engineers.
- **ce03 (Baby Parent)**: Ops team is responsible for incidents in systems they did not build
  and cannot change. Common in IT/NOC teams labeled "SRE" but operating as pure firefighters.
- **ce26 (Responsibility-Accountability Separation as Blame Tool)**: When organizations formally
  separate accountability (manager) from responsibility (engineer) primarily to create a blame
  target rather than close a feedback loop.

### Author's Blind Spots / Limitations

- The framework assumes organizational access: presenting the ownership-trio analysis and
  proposing restructuring requires Staff+/Principal-level organizational authority. Junior and
  mid-level engineers often diagnose the problem correctly but cannot prescribe the fix.
- The triad is presented as sufficient for reliability — but incentive misalignment can break
  ownership even when all three are formally present. A team can have full ownership and still
  deprioritize reliability if feature velocity exclusively drives performance reviews.
- The framework does not address external dependencies: a team may have knowledge, mandate, and
  responsibility for their service but depend on another team's service over which they have
  none of the three. The inter-team version requires the `responsibility-control-slo` skill.

### Easily Confused With

- **RACI matrix**: RACI separates Responsible/Accountable/Consulted/Informed. Ewerlöf argues
  that separating Accountable from Responsible in most organizational contexts is itself a
  broken-ownership signal — the Ownership Trio is not a finer-grained RACI; it is a claim that
  the separation is usually harmful.

______________________________________________________________________

## Related Skills

- **composes-with** → `oncall-ownership-sustainability`: The archetypes are the diagnostic application of the Ownership Trio — they name the specific failure mode when one or more elements are missing.
- **composes-with** → [`responsibility-control-slo`](../responsibility-control-slo/SKILL.md): Responsibility-Control SLO is the technical instrument that operationalizes the Ownership Trio's mandate principle at the metric scope level.
- **composes-with** → [`ephemeral-taskforce`](../ephemeral-taskforce/SKILL.md): ETF composition requirements follow directly from the Ownership Trio — each ETF member must hold all three elements for their slice.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
