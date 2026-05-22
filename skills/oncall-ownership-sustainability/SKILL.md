---
name: oncall-ownership-sustainability
allowed-tools: Bash, Read, Edit
id: oncall-ownership-sustainability
description: Use this skill when an on-call rotation is overwhelmed and the correct response is unclear — specifically when management proposes hiring more engineers, which requires first diagnosing whether the on-call team has full ownership (Knowledge + Mandate + Responsibility all present) before applying the quantitative sustainability model, because hiring into a broken ownership archetype makes the structural problem worse rather than better.
type: merged-skill
source_skills:
  - slug: site-reliability-engineering/on-call-sustainability-model
    book: Site Reliability Engineering
    author: Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.)
  - slug: reliability-engineering-mindset/broken-ownership-archetypes
    book: Reliability Engineering Mindset
    author: Alex Ewerlöf
related_skills:
  - slug: site-reliability-engineering/on-call-sustainability-model
    relation: supersedes
    note: This merged skill adds the ownership archetype diagnostic that determines whether the safety valve can fire before applying the quantitative model
  - slug: reliability-engineering-mindset/broken-ownership-archetypes
    relation: supersedes
    note: This merged skill adds the quantitative sustainability bounds that Ewerlöf's structural diagnosis prescribes but does not specify
tags: []
---

# On-Call Ownership and Sustainability

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

On-call / PagerDuty docs:
!`find . \( -name '*oncall*' -o -name '*on-call*' -o -name '*pagerduty*' -o -name '*runbook*' \) -not -path './.git/*' 2>/dev/null | head -10`

### R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 11):**

> We strongly believe that the "E" in "SRE" is a defining characteristic of our organization, so we strive to invest at least 50% of SRE time into engineering: of the remainder, no more than 25% can be spent on-call, leaving up to another 25% on other types of operational, nonproject work.
>
> We've found that on average, dealing with the tasks involved in an on-call incident — root-cause analysis, remediation, and follow-up activities like writing a postmortem and fixing bugs — takes 6 hours. It follows that the maximum number of incidents per day is 2 per 12-hour on-call shift.
>
> An operational underload is undesirable for an SRE team. Being out of touch with production for long periods of time can lead to confidence issues, both in terms of overconfidence and underconfidence, while knowledge gaps are discovered only when an incident occurs.

**From Ewerlöf (Reliability Engineering Mindset, broken-ownership-archetypes):**

> Only Mandate (no Knowledge, no Responsibility): monkey with a gun — calls shots without understanding or consequences.
>
> Knowledge + Responsibility, no Mandate: foot soldier — knows best, responsible for outcomes, but cannot drive change.
>
> Only Responsibility: baby parent — accountable for failures they cannot understand or prevent.
>
> Mandate + Responsibility, no Knowledge: gambler — makes decisions and bears consequences without understanding what they're deciding.

**Convergence note:** Both sources independently identify the same root failure: paging engineers who cannot fix what they're paged for is the primary cause of on-call unsustainability. The SRE book addresses this through the safety valve mechanism (redirect excess operational work to the development team that built the system). Ewerlöf addresses the same symptom through the Baby Parent archetype diagnosis (ops teams responsible for systems they cannot understand or change). The convergence is on the cause; the divergence is on the mechanism and the preconditions for the remedy to work.

______________________________________________________________________

### I — Unified Framework (Interpretation)

On-call sustainability has two failure layers — structural and operational — that must be addressed in sequence. Applying the quantitative operational model to a structurally broken organization produces the wrong remedy.

**The structural layer (Ewerlöf's Ownership Trio diagnostic):**

Full on-call ownership requires three elements simultaneously:

- **Knowledge:** the on-call engineer understands the system being paged for — its architecture, failure modes, and dependencies.
- **Mandate:** the on-call engineer has the authority to make changes — commit rights, architectural decisions, escalation authority.
- **Responsibility:** the on-call engineer bears the operational consequences of failures in the system.

When one or more elements are absent, a specific broken ownership archetype emerges, each with a distinct symptom and a distinct structural fix:

| Archetype         | Present                    | Missing                   | On-call symptom                                                                     | Structural fix                                                                  |
| ----------------- | -------------------------- | ------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Baby Parent       | Responsibility only        | Knowledge, Mandate        | Paged for systems they can't understand or change; escalate everything; burnout     | Make the dev team own production operations                                     |
| Foot Soldier      | Knowledge + Responsibility | Mandate                   | Know what to fix but can't get approval; attrition of senior engineers              | Give knowledgeable team commit rights and architectural authority               |
| Teenager          | Knowledge + Mandate        | Responsibility            | Architects design systems but are never on-call; designs ignore operational reality | Add architects to on-call rotation for systems they designed                    |
| Gambler           | Mandate + Responsibility   | Knowledge                 | Infrastructure makes decisions without developer knowledge; "us vs them"            | Give developers production access; bring them into infrastructure decisions     |
| Monkey with a Gun | Mandate only               | Knowledge, Responsibility | Manager decides without on-call experience; engineers demoralized                   | Make managers bear operational consequences (on-call rotation or SLO ownership) |
| Coma              | Knowledge only             | Mandate, Responsibility   | Expert consulted but never followed; expertise wasted                               | Give expert commit rights and ownership of outcomes                             |

The Baby Parent and Foot Soldier archetypes are the most common on-call failure patterns. Baby Parent is endemic in organizations that have relabeled IT operations or NOC teams as SRE — they receive pages for systems they did not build and cannot change.

**The operational layer (SRE book's quantitative model):**

The quantitative model applies ONLY when full ownership (Knowledge + Mandate + Responsibility) is present. Two independent constraints must both be satisfied:

1. **Quality constraint (incidents per shift):** Each meaningful incident requires approximately 6 hours of complete work (detection, mitigation, root-cause analysis, postmortem writing, and bug filing). A 12-hour shift has capacity for exactly 2 incidents. Above 2 incidents per shift, postmortem and fix cycles are skipped, problems accumulate, and engineers cannot learn from incidents they cannot fully investigate.

2. **Quantity constraint (rotation size):** The 25% on-call sub-cap within the 50% engineering time cap requires a minimum of 8 engineers for a single-site team (week-long shifts, primary + secondary coverage). Below 8 engineers, individuals either exceed the 25% sub-cap or coverage gaps appear. For dual-site teams: minimum 6 per site. Night shifts cause measurable health damage — "follow the sun" eliminates them.

**The safety valve:** When incident load exceeds 2 per shift for a sustained period, the correct response is NOT to hire more engineers. Hiring absorbs excess load without generating the feedback that motivates the development team to fix the underlying reliability problems. The correct response: redirect excess operational work to the development team — give them the pager for the services generating the excess load. The dev team, now experiencing pages, has direct incentive to fix what they built.

**Why the safety valve fails in broken ownership organizations:**

The SRE book's safety valve assumes the dev team can receive the pager — that they have the knowledge to investigate incidents and the mandate to fix them. In a Baby Parent organization, "redirect to dev team" may not work because the org is structured to prevent dev teams from owning production operations. Managers in Monkey-with-a-Gun mode will hire more Baby Parent ops engineers rather than give dev teams operational responsibility, because giving dev teams operational responsibility threatens their control. Ewerlöf's archetypes explain exactly why the safety valve fails to fire in practice: the structural preconditions for it to work have been eliminated by the ownership pattern.

**The diagnostic sequence:**

```text
Step 1: Assess the Ownership Trio for the on-call team.
  → Knowledge: does the on-call engineer understand the systems they're paged for?
  → Mandate: can the on-call engineer make changes without approval chains?
  → Responsibility: does the on-call engineer bear the consequence of their decisions?

IF all three present (full ownership):
  → Apply the quantitative model directly:
    - Measure incidents per shift (target: ≤2 per 12-hour shift)
    - Measure rotation size (target: ≥8 engineers single-site, ≥6 per site dual-site)
    - If overloaded: apply safety valve (redirect excess to dev team)

IF any element missing:
  → Identify which archetype applies
  → Prescribe the structural fix (add the missing element to the correct entity)
  → Do not apply the quantitative model until structural fix is in place
  → Hiring more engineers before fixing the structural problem perpetuates the archetype
```

**The symmetric failure:** Too few incidents is also a failure state. Engineers on-call less than once or twice per quarter lose current mental models of production system behavior. Knowledge gaps are discovered only during incidents, at the worst possible time. Mitigate with deliberate production exposure: Wheel of Misfortune exercises, DiRT drills, joint game days. This underload failure mode exists only when the structural layer is healthy — Baby Parent teams rarely experience underload.

______________________________________________________________________

### A1 — Past Application

## R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 11):**

> We strongly believe that the "E" in "SRE" is a defining characteristic of our organization, so we strive to invest at least 50% of SRE time into engineering: of the remainder, no more than 25% can be spent on-call, leaving up to another 25% on other types of operational, nonproject work.
>
> We've found that on average, dealing with the tasks involved in an on-call incident — root-cause analysis, remediation, and follow-up activities like writing a postmortem and fixing bugs — takes 6 hours. It follows that the maximum number of incidents per day is 2 per 12-hour on-call shift.
>
> An operational underload is undesirable for an SRE team. Being out of touch with production for long periods of time can lead to confidence issues, both in terms of overconfidence and underconfidence, while knowledge gaps are discovered only when an incident occurs.

**From Ewerlöf (Reliability Engineering Mindset, broken-ownership-archetypes):**

> Only Mandate (no Knowledge, no Responsibility): monkey with a gun — calls shots without understanding or consequences.
>
> Knowledge + Responsibility, no Mandate: foot soldier — knows best, responsible for outcomes, but cannot drive change.
>
> Only Responsibility: baby parent — accountable for failures they cannot understand or prevent.
>
> Mandate + Responsibility, no Knowledge: gambler — makes decisions and bears consequences without understanding what they're deciding.

**Convergence note:** Both sources independently identify the same root failure: paging engineers who cannot fix what they're paged for is the primary cause of on-call unsustainability. The SRE book addresses this through the safety valve mechanism (redirect excess operational work to the development team that built the system). Ewerlöf addresses the same symptom through the Baby Parent archetype diagnosis (ops teams responsible for systems they cannot understand or change). The convergence is on the cause; the divergence is on the mechanism and the preconditions for the remedy to work.

______________________________________________________________________

## I — Unified Framework (Interpretation)

On-call sustainability has two failure layers — structural and operational — that must be addressed in sequence. Applying the quantitative operational model to a structurally broken organization produces the wrong remedy.

**The structural layer (Ewerlöf's Ownership Trio diagnostic):**

Full on-call ownership requires three elements simultaneously:

- **Knowledge:** the on-call engineer understands the system being paged for — its architecture, failure modes, and dependencies.
- **Mandate:** the on-call engineer has the authority to make changes — commit rights, architectural decisions, escalation authority.
- **Responsibility:** the on-call engineer bears the operational consequences of failures in the system.

When one or more elements are absent, a specific broken ownership archetype emerges, each with a distinct symptom and a distinct structural fix:

| Archetype         | Present                    | Missing                   | On-call symptom                                                                     | Structural fix                                                                  |
| ----------------- | -------------------------- | ------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Baby Parent       | Responsibility only        | Knowledge, Mandate        | Paged for systems they can't understand or change; escalate everything; burnout     | Make the dev team own production operations                                     |
| Foot Soldier      | Knowledge + Responsibility | Mandate                   | Know what to fix but can't get approval; attrition of senior engineers              | Give knowledgeable team commit rights and architectural authority               |
| Teenager          | Knowledge + Mandate        | Responsibility            | Architects design systems but are never on-call; designs ignore operational reality | Add architects to on-call rotation for systems they designed                    |
| Gambler           | Mandate + Responsibility   | Knowledge                 | Infrastructure makes decisions without developer knowledge; "us vs them"            | Give developers production access; bring them into infrastructure decisions     |
| Monkey with a Gun | Mandate only               | Knowledge, Responsibility | Manager decides without on-call experience; engineers demoralized                   | Make managers bear operational consequences (on-call rotation or SLO ownership) |
| Coma              | Knowledge only             | Mandate, Responsibility   | Expert consulted but never followed; expertise wasted                               | Give expert commit rights and ownership of outcomes                             |

The Baby Parent and Foot Soldier archetypes are the most common on-call failure patterns. Baby Parent is endemic in organizations that have relabeled IT operations or NOC teams as SRE — they receive pages for systems they did not build and cannot change.

**The operational layer (SRE book's quantitative model):**

The quantitative model applies ONLY when full ownership (Knowledge + Mandate + Responsibility) is present. Two independent constraints must both be satisfied:

1. **Quality constraint (incidents per shift):** Each meaningful incident requires approximately 6 hours of complete work (detection, mitigation, root-cause analysis, postmortem writing, and bug filing). A 12-hour shift has capacity for exactly 2 incidents. Above 2 incidents per shift, postmortem and fix cycles are skipped, problems accumulate, and engineers cannot learn from incidents they cannot fully investigate.

2. **Quantity constraint (rotation size):** The 25% on-call sub-cap within the 50% engineering time cap requires a minimum of 8 engineers for a single-site team (week-long shifts, primary + secondary coverage). Below 8 engineers, individuals either exceed the 25% sub-cap or coverage gaps appear. For dual-site teams: minimum 6 per site. Night shifts cause measurable health damage — "follow the sun" eliminates them.

**The safety valve:** When incident load exceeds 2 per shift for a sustained period, the correct response is NOT to hire more engineers. Hiring absorbs excess load without generating the feedback that motivates the development team to fix the underlying reliability problems. The correct response: redirect excess operational work to the development team — give them the pager for the services generating the excess load. The dev team, now experiencing pages, has direct incentive to fix what they built.

**Why the safety valve fails in broken ownership organizations:**

The SRE book's safety valve assumes the dev team can receive the pager — that they have the knowledge to investigate incidents and the mandate to fix them. In a Baby Parent organization, "redirect to dev team" may not work because the org is structured to prevent dev teams from owning production operations. Managers in Monkey-with-a-Gun mode will hire more Baby Parent ops engineers rather than give dev teams operational responsibility, because giving dev teams operational responsibility threatens their control. Ewerlöf's archetypes explain exactly why the safety valve fails to fire in practice: the structural preconditions for it to work have been eliminated by the ownership pattern.

**The diagnostic sequence:**

```text
Step 1: Assess the Ownership Trio for the on-call team.
  → Knowledge: does the on-call engineer understand the systems they're paged for?
  → Mandate: can the on-call engineer make changes without approval chains?
  → Responsibility: does the on-call engineer bear the consequence of their decisions?

IF all three present (full ownership):
  → Apply the quantitative model directly:
    - Measure incidents per shift (target: ≤2 per 12-hour shift)
    - Measure rotation size (target: ≥8 engineers single-site, ≥6 per site dual-site)
    - If overloaded: apply safety valve (redirect excess to dev team)

IF any element missing:
  → Identify which archetype applies
  → Prescribe the structural fix (add the missing element to the correct entity)
  → Do not apply the quantitative model until structural fix is in place
  → Hiring more engineers before fixing the structural problem perpetuates the archetype
```

**The symmetric failure:** Too few incidents is also a failure state. Engineers on-call less than once or twice per quarter lose current mental models of production system behavior. Knowledge gaps are discovered only during incidents, at the worst possible time. Mitigate with deliberate production exposure: Wheel of Misfortune exercises, DiRT drills, joint game days. This underload failure mode exists only when the structural layer is healthy — Baby Parent teams rarely experience underload.

______________________________________________________________________

## A1 — Past Application

### Case A: Ads SRE Ops Overload — Embedded SRE Restores Ownership (SRE Book, Chapter 11)

- **Problem:** An SRE team's operational work exceeded 50% of engineering time. The on-call rotation was implicitly absorbing excess load that should have triggered the safety valve. Viewed through Ewerlöf's model, the team was exhibiting Baby Parent symptoms: absorbing excess operational work from systems without the organizational authority to fix the root causes.
- **Methodology:** Rather than hiring more SREs, the intervention was an embedded SRE who shadowed on-call sessions, classified fires, and helped the team establish SLOs and postmortem habits. SLO definition gave the team knowledge of what mattered. Postmortem authority gave the team mandate to identify and escalate root causes. This was a structural ownership fix, not a headcount fix.
- **Conclusion:** Restoring the 50% cap was treated as a concrete objective with measurable milestones: tickets per day below 5, pages per shift below 2. The embedded SRE added the missing mandate elements (SLO authority, postmortem escalation) without adding headcount.
- **Result:** Teams that received embedded SRE intervention regained sustainable ratios by changing practices (SLO definition, postmortem culture), not by adding headcount. This is the Baby Parent → full ownership transition: adding Knowledge (SLOs) and Mandate (postmortem authority) to a team that had only Responsibility.

### Case B: IT Operations Team as Baby Parent (Ewerlöf, Broken-Ownership-Archetypes)

- **Problem:** IT operations and NOC teams labeled as SRE were being paged for every incident in systems they did not design and could not change. They had Responsibility (on-call burden) but neither Knowledge (application code understanding) nor Mandate (architecture change authority). Standard response: rollback, because fixing forward requires understanding they lacked.
- **Methodology:** Ewerlöf classified this as the Baby Parent archetype. The remedy is structural: not improving the ops team's process, but reuniting knowledge and mandate with responsibility by making the development team own production operations. The quantitative sustainability model cannot be applied until this structural fix is in place — hiring more Baby Parent ops engineers perpetuates the pattern.
- **Conclusion:** The fix is not to improve the operations team's skills or processes. The fix is to change who gets paged.
- **Result:** Teams that moved toward full ownership developed operational knowledge through direct incident exposure, used their mandate to prevent the incidents that had been burning them out, and reduced the overall incident volume — which then allowed the quantitative model to be applied to a healthy baseline.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Instead of on-call-sustainability-model or broken-ownership-archetypes, use this when:** an on-call rotation is overwhelmed and management proposes hiring more engineers — a response that requires first determining whether the on-call team has full ownership (in which case the safety valve applies) or is in a broken ownership archetype (in which case hiring perpetuates the pattern).

**Scenario 1:** A VP proposes solving on-call overload by hiring 3 more SREs. The current team is at 5 engineers with 5+ incidents per shift. Apply the diagnostic first: does the on-call team have Knowledge + Mandate + Responsibility for the systems they're paged for? If not, hiring 3 more Baby Parents does not solve the problem. If yes (full ownership), apply the safety valve: redirect excess ops work to dev, then address rotation size.

**Scenario 2:** An on-call engineer reports "we get paged but we can't fix it without escalating to another team." This is Baby Parent or Foot Soldier depending on whether the paged team also has Knowledge. The structural fix: identify which team has the missing elements and add them to the rotation for those systems. Do not measure incidents per shift until ownership is corrected.

**Scenario 3:** A team of 15 engineers shares on-call. Each engineer is on-call once every two months. They have 0–1 incidents per quarter and describe it as "very quiet." Apply the underload diagnostic: engineers on-call less than once per quarter lose production familiarity. The fix: Wheel of Misfortune exercises and DiRT drills. Check also for Baby Parent dynamics — a "very quiet" rotation may indicate the org has structured ops separately from development, preventing incidents from surfacing to the correct team.

**Language signals:**

- "We just need more bodies on rotation"
- "We get paged but we can't fix it without escalating"
- "Management keeps hiring ops engineers instead of giving dev teams the pager"
- "Our SRE team is responsible for everything but understands nothing"
- "The architects design systems but they're never on-call for them"
- "On-call is never a problem for us — it's very quiet" (possible underload)

______________________________________________________________________

## E — Execution Steps

1. **Diagnose the Ownership Trio before measuring anything quantitative.** For the on-call team, assess:

   - Knowledge: Can the on-call engineer investigate incidents in the systems they're paged for without escalating to another team?
   - Mandate: Can the on-call engineer make changes (commits, configuration, architecture) without approval chains?
   - Responsibility: Does the on-call engineer bear the operational consequence of failures — are they paged when their decisions produce incidents?
     Completion criterion: {Knowledge: Y/N, Mandate: Y/N, Responsibility: Y/N} explicitly assessed.

2. **If any element is missing, prescribe the structural fix before proceeding.** Match the missing element combination to the archetype table. Name the archetype and its distinctive symptom. The fix is structural:

   - Missing Knowledge → add the mandate-holder to on-call; bring decision-makers into incident reviews
   - Missing Mandate → give the knowledgeable/responsible party commit rights and architectural authority
   - Missing Responsibility → add decision-makers to the on-call rotation or tie their metrics to reliability outcomes
     Do not proceed to quantitative measurement until structural fix is implemented. Hiring engineers before fixing the structural problem perpetuates the archetype at larger scale.

3. **Apply the quantitative sustainability model once full ownership is present.** Measure:

   - Average incidents per 12-hour shift over the last quarter (target: ≤2)
   - Engineers in the active rotation (target: ≥8 single-site, ≥6 per site dual-site)
   - Night shift exposure (diagnostic for insufficient rotation size)
     Completion criterion: both constraints quantified with trend direction known.

4. **Address rotation size if below minimum.** A rotation below minimum cannot sustain the 25% on-call sub-cap regardless of incident volume. Grow to minimum or move to dual-site. Night shift exposure is the immediate indicator of insufficient rotation size.

5. **Address incident volume if above 2-incident threshold.** Do NOT hire to absorb excess load. Apply the safety valve: identify the top incident sources by frequency × severity; redirect those services' on-call to the development teams that built them. Simultaneously initiate postmortem reviews for recurring incident types to identify root causes. Set a quarterly gate: if load has not returned below threshold within one quarter, escalate to management for structural intervention.

6. **Address underload if below one incident per quarter per engineer.** Deploy deliberate production exposure: Wheel of Misfortune exercises, DiRT drills, joint game days. Engineers who are rarely on-call are a hidden reliability risk — their production mental models drift, and their first real incident will be harder, not easier, for the team's large size.

______________________________________________________________________

## B — Boundary ★

### Failure Patterns from the SRE Book (On-Call-Sustainability-Model)

- Treating the 2-incident threshold as a per-week or per-month average rather than per-shift. A team that has 0 incidents per shift for 3 weeks and 10 in one shift is not sustainable.
- Hiring to absorb excess load without triggering the safety valve. This removes the feedback loop that motivates reliability improvements and produces a larger, more expensive team at the same overload ratio within 6–12 months.
- Ignoring operational underload because "quiet is good." Engineers who are rarely on-call are a hidden reliability risk — their production mental models drift, and knowledge gaps surface only during incidents.

### Failure Patterns from Ewerlöf (Broken-Ownership-Archetypes)

- Baby Parent perpetuation: hiring more ops engineers into a Baby Parent org makes the Baby Parent pattern larger and more entrenched; the structural problem is not resolved.
- Monkey with a Gun response: managers who make operational decisions without on-call consequences will consistently choose to hire ops engineers rather than give dev teams operational responsibility, because the latter threatens their control.
- Metrics weaponized: on-call incident counts used as performance evaluations rather than diagnostic tools, triggering blame rather than structural fixes.
- Accountability-Responsibility Separation: formally separating accountability (managers) from responsibility (engineers) enables blame without closing the feedback loop that would prevent recurrence.

### Synthesis-Specific Failure Mode

**The safety valve applied to broken ownership:** A team correctly diagnoses that their on-call is overloaded and applies the SRE book's safety valve — "redirect excess ops work to the dev team." In a Baby Parent organization, the dev team is the Teenager archetype (Knowledge + Mandate but no Responsibility): they have the knowledge to fix what's failing, but the organizational structure prevents them from bearing on-call consequences. Redirecting the pager to Teenagers does not produce the incentive-to-fix outcome the safety valve predicts — Teenagers experience the pager as interference with feature development and have the mandate to route it back to ops. The safety valve fails silently: management sees the redirect as a failed experiment and returns to hiring ops engineers. This failure mode is invisible from within the SRE book alone (the book assumes the safety valve works when the redirect is made) and from within Ewerlöf's model alone (the model diagnoses the archetype but does not specify the safety valve mechanism). Only the merged framing makes visible that applying the safety valve requires the recipient dev team to have Responsibility, not just Knowledge and Mandate.

### Do Not Use When

- The team lacks organizational authority to redirect excess operational work to the development team. Without this authority, the safety valve cannot fire. Address organizational authority first.
- The situation is about SLI/SLO design or metric scoping — those are separate skills.
- The incident volume is below the threshold but incidents are genuinely complex, multi-hour, multi-system events. The 6-hour estimate is an average — adjust to measured actual incident cost before applying the threshold.

______________________________________________________________________

## Related Skills

- **supersedes**: site-reliability-engineering/on-call-sustainability-model — use this merged skill when the ownership structure is unknown or suspect; use the source skill when full ownership is confirmed and only the quantitative bounds need to be applied
- **supersedes**: reliability-engineering-mindset/broken-ownership-archetypes — use this merged skill when the on-call sustainability question is also in scope; use the source skill when only the archetype diagnosis and structural fix are needed without the quantitative model
- **composes-with**: site-reliability-engineering/fifty-percent-engineering-time-cap — the 25% on-call sub-cap is derived from the 50% parent cap; both must be enforced together to correctly calculate minimum rotation size
- **composes-with**: site-reliability-engineering/blameless-postmortem-process — postmortems are the essential follow-up within the 6-hour per-incident budget; skipping them is the leading indicator the 2-incident bound has been exceeded
