---
name: sre-team-lifecycle-tuckman
description: |
  Use this skill when forming, diagnosing, or intervening in an SRE team — specifically when the team is struggling to become effective, experiencing internal resistance, or when a manager is applying the wrong intervention for the team's formation type.

  Call when: A new SRE team is being assembled (by any formation method), a team appears stuck and not making progress toward the Norming or Performing milestones, or a manager is applying generic team management advice to an SRE team context.

  Do not call when: The problem is a specific reliability or technical issue (not a team formation or organizational issue), or when the team is clearly Performing and the question is about sustaining performance rather than reaching it.

  Key trigger: Resistance to SRE practices — especially automation — is the most common misdiagnosed symptom. Generic team management wisdom treats resistance as a personnel problem. This skill treats it as a formation-type-specific Storming phase behavior with a prescribed intervention that depends on how the team was formed.
source_book: "The Site Reliability Workbook" by Betsy Beyer et al. (Google)
source_chapter: "Chapter 20 - SRE Team Lifecycles; Chapter 18 - SRE Engagement Model"
tags: [team-formation, tuckman, sre-team, organizational-change, lifecycle, converted-ops, storming]
related_skills: []
---

# SRE Team Lifecycle by Formation Type (Tuckman Applied to SRE Team Formation)

## R — Original Text

> "The following sections walk through the stages of building a team, using Tuckman's performance model and stages of forming, storming, norming, and performing. You might start an SRE team in a number of ways. Approaches we've used at Google, from least to most complex, include: Creating a new team as part of a major project, Establishing a horizontal SRE team, Converting an existing team (for example, an operations team)."
>
> "A team converted in place: Risks — Perceives that the conversion process is the start of a slow journey to job losses as automation replaces humans. Doesn't support the change to an SRE team. Has no slack capacity they can leverage to change the team's day-to-day activities... Mitigations: Deals with the concern about job losses head on. In a lot of environments, automation eliminates portions of work, but not jobs as a whole."
>
> "Horizontal SRE team: Risks — The team is perceived as a new 'gating' organization that does no real work or adds no real value. Mitigations: Is seeded with respected engineers who have relevant subject matter expertise. Undertakes project work that focuses on delivering tools. Sees themselves as enablers, not gatekeepers."
>
> — Google SRE Workbook, Chapter 20 - SRE Team Lifecycles

______________________________________________________________________

## I — Framework (Interpretation)

SRE teams follow Tuckman's four-stage model (Forming, Storming, Norming, Performing), but with a critical elaboration: the Storming-phase failure mode depends entirely on how the team was formed. Applying the wrong Storming intervention — or applying the right intervention to the wrong formation type — causes teams to stall or fail. A manager unfamiliar with this framework applies the same intervention to all three types and fails with two of them.

The three formation types and their type-specific Storming risks:

## Type 1: New SRE Team for a Major Project

- Storming risk: The team firefights before it can instrument. It becomes consumed with perfect SLO definition while the service burns, or it is paged 100 times a day and ignores pages, or reliability improvements are deferred because they set back development timelines.
- Correct intervention: Engage on a single important service. Do not expect operational responsibility on day one — it stays with the development team initially. Have the SRE team input on design with a reliability focus, not on crisis response.

## Type 2: Horizontal SRE Team

- Storming risk: The team is perceived as a new gating organization that blocks rather than enables. Other teams view them as doing no real work.
- Correct intervention: Seed with respected engineers who have credibility. Deliver tools with short-term beneficial impact on at least two other teams. Communicate successes explicitly. Frame all interactions as enablement, not gating.

## Type 3: Converted Ops Team

- Storming risk: Engineers fear automation will eliminate their jobs. They resist automation projects and avoid postmortem action items because completing them produces evidence that their role is reducible.
- Correct intervention: Address job security concerns directly and explicitly — not obliquely. Frame automation as job enhancement (freeing time for higher-value work) not elimination. Change performance evaluation metrics to align with SRE skills, not operational throughput. Involve engineers in designing the automation, not just executing it.

The Norming milestone is defined by four observable conditions: SLOs with error budget policies in place and exercised, sustainable on-call rotation with tooling and training, toil documented and bounded, and postmortem culture established. The Performing milestone adds: architecture partnership, full workload self-determination (Principle 3), and the right to hand back unmanageable services.

______________________________________________________________________

## A1 — Past Application

**Case 1 — New York Times: converted ops team in Storming phase**
The New York Times Delivery and SRE department documented (in the workbook) a team that had organically accumulated ownership of core site-wide architecture configuration and was in continuous reactive mode — ticket-driven, unable to make improvements, overloaded with institutional knowledge that created constant interrupt pressure. This is a classic converted ops team in Storming. The intervention: embed an SRE in the development team to relieve immediate pressure; break service configs into team-owned repos so the product teams take ownership; use office hours to batch interrupts. The Norming milestone was reached when project work exceeded 50% of the team's time. The Storming intervention did not involve imposing automation quotas — it involved restructuring the interrupt pattern and inverting the responsibility model.

**Case 2 — PagerDuty: horizontal SRE team seeding with credibility**
PagerDuty's reliability engineering team was established as a horizontal function consulting across product teams. The initial Storming risk — being perceived as a gating organization — was mitigated by seeding the team with engineers who already had strong relationships with the product teams and by making the first deliverable a monitoring improvement that had immediate visible impact on two product teams. The team led with enablement tools (alerting templates, runbooks, on-call rotation setup) before it engaged in any gating function (PRR review, SLO approval). Credibility was established through demonstrated utility, not authority.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: Converted ops team resisting automation**
Six months into the conversion, the team avoids automation projects and drags on postmortem action items. Manager diagnosis without this framework: "performance issue, apply pressure." Correct diagnosis: Storming phase, converted ops type, job security anxiety. Prescribed intervention: address job losses directly in a team meeting, restructure performance metrics away from operational throughput toward SRE skill acquisition, involve engineers in automation design rather than assigning automation as tasks.

**Scenario 2: New project team firefighting instead of instrumenting**
The new SRE team for a major cloud migration is spending 80% of time on incident response and cannot make progress on SLO definition or reliability architecture. Correct diagnosis: Storming phase, new project type, scope-too-broad / no production separation risk. Intervention: transfer operational responsibility back to the development team temporarily; have the SRE team engage on design and SLO definition rather than incident response; set explicit conditions for operational responsibility transfer.

**Scenario 3: Horizontal team resented as gatekeepers**
Development teams complain that the horizontal SRE team blocks launches without contributing engineering work. Correct diagnosis: Storming phase, horizontal type, gating perception risk. Intervention: have the horizontal team deliver at least one enabling tool to each team they interact with before engaging in review functions; make successes visible; reframe every review as a consultation, not an approval.

**Language signals:** "the SRE team just adds process," "we're worried about our jobs once the automation is done," "the SREs are always fighting fires and can't help with anything strategic," "nobody takes the SRE reviews seriously."

**Distinguishing from adjacent skills:** This skill is about the SRE team itself as an organizational entity moving through formation stages. The overload recovery skill is about a team in crisis that has already formed but is overwhelmed. The SRE engagement model is about how an SRE team relates to a specific service lifecycle. These can overlap: a team in Storming can also be in operational overload, but the interventions are different (formation-type-specific Storming intervention vs. psychological safety first).

______________________________________________________________________

## E — Execution Steps

1. **Identify the formation type.** Determine which of the three types applies: new project team, horizontal team, or converted ops team. This is the first diagnostic question. Mixed formations (e.g., some new hires plus some converted ops engineers) require attention to the dominant Storming risk.

2. **Identify the current Tuckman stage.** Use behavioral indicators:

   - Forming: team assembled, roles unclear, skill gaps visible.
   - Storming: type-specific resistance pattern is active (firefighting, gating perception, or automation resistance).
   - Norming: SLOs with policies in place, sustainable on-call, toil documented, postmortem culture present.
   - Performing: architecture partnership, workload self-determination, handback authority exercised.

3. **Apply the formation-type-specific Storming intervention.** Do not apply a generic team-building intervention. Apply the specific mitigations for the diagnosed formation type (see framework section above).

4. **Do not apply management pressure during Storming.** Imposing metrics, adding process, or treating resistance as a performance problem deepens the Storming dysfunction in all three types. The interventions are structural and relational, not punitive.

5. **Define the Norming milestone explicitly.** The team should know what the Norming milestone looks like: SLOs with error budget policies exercised, sustainable on-call with tooling and training, bounded toil, and active postmortem culture. This gives the team a visible destination during Storming.

6. **Seed with internal transfers where possible.** Internal transfers reduce Forming time by bringing existing relationships with other teams, existing familiarity with the organization's systems, and credibility that accelerates the Storming → Norming transition.

7. **Mark and celebrate the stage transitions.** When the team reaches Norming, pause and recognize it explicitly. Write a retrospective covering the journey (the workbook explicitly recommends this). Stage awareness reduces the disorientation of Storming.

**Completion criteria:** The team has been correctly classified by formation type and current stage. The formation-type-specific Storming intervention is in progress. The Norming milestone criteria are documented and shared with the team.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The team is in a crisis requiring immediate operational intervention (overload, imminent service failure). This skill is for formation and organizational dynamics, not operational crisis response. Address the crisis with the overload recovery skill first.
- The team is already Performing and the question is about sustaining performance or taking on new services. The lifecycle continues past Performing (service handback, engagement model decisions) — use the engagement model skill for those decisions.

**Failure patterns:**

- Misidentifying the formation type and applying the wrong Storming intervention. Applying horizontal-team mitigations (deliver tools, prove value) to a converted ops team (whose risk is job security anxiety) does not address the root cause.
- Skipping Storming and declaring the team is Performing because the team has been "SRE" for six months. The Norming milestone criteria are observable — check them.
- Treating the formation type as fixed. A team can have characteristics of multiple types (e.g., a converted ops team that is now serving a horizontal function). The dominant Storming risk must be diagnosed from observed behavior, not assumed from initial formation method.

**Author blind spots:**

- The engagement model and Tuckman framework assume the SRE team has organizational authority — leadership support for SRE principles. Without this, the Storming mitigations (especially for converted ops teams, which require "deals with the concern about job losses head on" and "changes how performance is evaluated") cannot be implemented by the team or its manager alone.
- Non-Google case studies (New York Times) in the workbook are thinner than Google's internal examples. The NYT case study documents the Storming → Norming transition for a converted ops team but does not describe what the team manager specifically did in 1:1s or team meetings to address job security concerns.
- The three formation types do not cover a fourth common real-world type: the acquired team (engineering team from an acquired company converted to SRE). Acquisition dynamics (culture clash, legacy system knowledge, career path uncertainty) introduce Storming risks that do not map cleanly to any of the three types.

**Easily confused with:**

- Overload recovery sequencing (a team in operational crisis; this skill is about formation dynamics, not crisis response).
- SRE engagement model (how an SRE team relates to a service lifecycle; this skill is about how the SRE team itself forms and matures).

______________________________________________________________________

## Related Skills

- **contrasts_with**: overload-recovery-sequencing — both address team dysfunction, but this skill diagnoses formation-stage Storming (root cause: organizational formation type) while overload recovery addresses teams crushed by accumulated operational load
- **composes_with**: overload-recovery-sequencing — a converted ops team in Storming is often simultaneously in operational overload; both interventions may be required in sequence (safety first, then formation-type Storming mitigation)
- **composes_with**: slo-consequences-governance-principle — the Norming milestone criterion "SLOs with error budget policies in place and exercised" is precisely what the consequences principle defines; reaching Norming requires this principle to be implemented

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04
