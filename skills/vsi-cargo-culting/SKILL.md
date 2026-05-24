---
name: vsi-cargo-culting
description: |
  Use this skill to diagnose whether an adoption decision — for a tool, process, methodology, or organizational model — is being driven by genuine fit-to-context analysis or by cargo culting. The VSI framework identifies the three-element mechanism that explains why intelligent practitioners adopt practices that don't fit: Value dominance, Shallow understanding, and Imitation.

  Call this skill when: (1) A team or leader is proposing to adopt something because "Google/Netflix/Spotify does it" or because a prestigious speaker endorsed it. (2) A practice is being adopted wholesale without analysis of the conditions that made it work elsewhere. (3) Rituals and processes have been installed but outcomes haven't improved. (4) You need to explain to leadership why a technically sophisticated adoption effort failed. (5) You want to audit an existing practice to see if it's cargo-culted.

  Do not call this skill when: (a) The goal is to evaluate whether a *specific* practice fits the current context — use `fit-practice` for that evaluation. (b) The adoption decision has already been made and the team needs an execution framework. (c) The question is about optimization timing rather than practice adoption.

  Key trigger signal: Justification for an adoption decision that relies on the source's prestige rather than an explicit analysis of why the practice would work in the current environment.
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20241110_160839_cargo-culting.md, 20241204_163905_best-practice.md, 20240524_130358_service-level-adoption-obstacles.md
tags: [cargo-culting, vsi, critical-thinking, best-practice, organizational-failure, mindset]
related_skills:
  - slug: fit-practice
    relation: contrasts-with
  - slug: fit-practice
    relation: composes-with
  - slug: 3ts-premature-optimization
    relation: contrasts-with
---

# VSI Framework for Cargo Culting Diagnosis

## R — Original Text (Reading)

> Cargo cults are very diverse but they all share these 3 elements:
>
> 1. **Value dominance**: judging others by our own value system. e.g., if someone from Google preaches something, it carries more weight because we all know how hard it is to get a job at Google, and most people dream of solving Google-level problems and earning Google-level salary/profit. This is halo effect bias where one's association gives them an unfair advantage.
>
> 2. **Shallow understanding**: critical thinking is replaced by superstition and magical thinking. "Best practices" are often someone's interpretation of why something worked at a certain time and environment. This interpretation is often exaggerated to make a point.
>
> 3. **Imitation:** going through superficial motions, processes, and rituals.
>
> — Alex Ewerlöf, 20241110_160839_cargo-culting.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The VSI framework is a diagnostic that explains *why* technically capable people adopt practices that fail in their context. It identifies three interlocking mechanisms, not just a vague accusation of "copying without thinking."

**V — Value Dominance** is the entry point. A practice gains credibility because of where it came from, not what it is. When a Google engineer presents at a conference, the audience evaluates the practice through the lens of Google's prestige (engineering talent, scale, revenue) even when that prestige has no bearing on whether the practice applies to their context. Halo-effect bias does the work. Value dominance is amplified by name-dropping, slick presentations, and deliberate demonstrations of high-value associations. It creates the *urge* to adopt.

**S — Shallow Understanding** is what fills the gap once the urge to adopt exists. Instead of asking "what problem does this solve, and do we have that problem?", practitioners accept the surface explanation and move to implementation. Best practices are typically someone's exaggerated interpretation of why something worked once. The generalization is intentional — it makes the practice applicable to more organizations, which increases adoption. Shallow understanding is boosted by charismatic advocates, low critical thinking norms, and cultures that have blocked feedback loops (if the practice isn't working, the feedback is suppressed or blamed on execution rather than fit).

**I — Imitation** is the execution phase. Teams install the visible artifacts: job titles are renamed, ceremonies are scheduled, dashboards are built, architecture diagrams match the reference material. The forms are correct. The substance — the organizational conditions, cultural prerequisites, control structures — that made the practice work at the source is absent. Imitation is reinforced by collectivism ("everyone else is doing Kubernetes"), false hope ("once we have this in place, everything will improve"), and leadership that confuses visible process with real change.

Together, V establishes the credibility that bypasses critical evaluation; S ensures the evaluation gap is not noticed; I converts the uncritical adoption into installed but ineffective forms. When all three are present, a practice has been cargo-culted regardless of how technically sophisticated the implementation appears.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Big Tech Hiring + London Office (C04)

- **Problem:** A software-supported company wanted to improve its software capability to compete. Guided by McKinsey, they hired alumni from Facebook, Google, and Amazon and opened a London office.
- **Application:** The ex-Big Tech employees began installing their former employers' practices: tech committees, platform unification, tech radars, tech standards. This is a textbook V+S+I pattern. V: Big Tech prestige was the reason for the hiring and gave unquestioned credibility to the practices these employees brought. S: No one analyzed whether the enabling conditions (scale, talent density, revenue model, competitive landscape) that made these practices effective at Google/Amazon existed at the new company. I: The practices were installed as rituals without the underlying conditions.
- **Conclusion:** The practices rapidly burned budget without making the company closer to any objective. The company split in two; ex-Big Tech employees quit one after another; the London office was shut down.
- **Result:** Complete failure: company split, office closed, budget exhausted. The mechanisms: value dominance (Big Tech prestige) bypassed fit analysis; shallow understanding prevented adaption; imitation installed expensive forms with no substance.

### Case 2: SLO Adoption Without Cultural Shift (C24)

- **Problem:** After Google open-sourced its SRE books, organizations excited by the material began implementing SLOs. They provisioned APM platforms, built dashboards, and set alerts.
- **Application:** VSI pattern: V — Google's credibility as the SRE originator meant the book's prescriptions were adopted without critical filtering. S — organizations read Chapter 2 (implementation) rather than absorbing the cultural preconditions. I — tooling was installed; the mental shift (consumer-grounded measurement, full ownership, error budget as risk regulator) was not.
- **Conclusion:** Years later, dashboards gathered dust. The only people who cared about them were the SREs who built them. Leadership sometimes weaponized the metrics against teams.
- **Result:** The tooling form of SRE was present; the function was absent. The author observed this pattern across dozens of organizations.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An engineering leader returns from a conference or has been reading about a practice that a prominent tech company uses, and is now proposing to adopt it without a contextual analysis.
2. A team has been running a process for 12+ months, calling it SRE/SLO/DORA/SAFe, but outcomes (reliability, velocity, incident rate) haven't changed — and no one can explain why.
3. You are being asked to evaluate a proposal or hiring recommendation and the primary justification is "this is how [prestigious company] does it."

### Language Signals (Activate When These Appear)

- "Netflix does it this way"
- "We should adopt [methodology] — it's best practice"
- "We hired someone from Google/Spotify, let's implement what they did there"
- "This worked at [company], so it should work here"
- "Everyone is using Kubernetes/SLOs/DORA — we should too"

### Distinguishing from Adjacent Skills

- Difference from `fit-practice`: VSI is a *diagnostic* for understanding whether an adoption is cargo-culted and why; `fit-practice` is an *evaluation framework* for determining whether a specific practice fits the current context. VSI answers "is this cargo-culting?" — `fit-practice` answers "what would make this fit?"
- Difference from `3ts-premature-optimization`: The 3T framework diagnoses premature *optimization* decisions (wrong thing, time, trade-offs); VSI diagnoses prestige-driven *adoption* decisions. They can co-occur (e.g., a cargo-culted infrastructure practice can also be a premature optimization) but target different root causes.

______________________________________________________________________

## E — Execution Steps

1. **Identify the V element: source of credibility**

   - Ask: "Why are we considering this practice?" Document the answer.
   - Test: Is the justification primarily the reputation of who does it (company name, speaker prestige, conference badge), or is it a diagnosis that the practice solves a problem the team has confirmed they have?
   - Completion criteria: The primary justification has been explicitly stated. If it relies on prestige rather than diagnosed need, flag V as present.

2. **Identify the S element: depth of understanding**

   - Ask: "What problem does this practice solve? Under what conditions did it produce results at the source? Do those conditions apply here?"
   - Test: Can anyone in the room describe the underlying mechanism — not just the practice's form but why it works, what enables it, and what problem it was designed for?
   - Completion criteria: The enabling conditions have been listed and compared to current conditions. If the team cannot answer these questions, flag S as present.
   - Stop condition: If nobody in the room has read the source material or spoken to practitioners from the originating context, the understanding is by definition shallow. Do not proceed to adoption without closing this gap.

3. **Identify the I element: imitation surface area**

   - Ask: "What exactly are we planning to install? Which parts are the forms (naming, ceremonies, dashboards) and which parts are the underlying conditions (ownership model, feedback loops, incentive structures)?"
   - Test: Is the plan focused on the visible artifacts — job title changes, new tooling, process ceremonies — without a corresponding plan to change the organizational conditions those artifacts depend on?
   - Completion criteria: The plan distinguishes form from substance. If form dominates, flag I as present.

4. **Count the flags and assess severity**

   - One flag present: elevated risk, worth pausing to address the flagged element.
   - Two flags: strong signal of cargo culting; proceed only with explicit mitigation plan.
   - All three flags: diagnosis is cargo-culting. Recommend halting until the underlying problem is diagnosed independently and a context-fit evaluation (`fit-practice`) is run.
   - Completion criteria: A written verdict is produced, stating which elements are present and what evidence supports each.

5. **Prescribe next action**

   - For V-dominant cases: insist on a problem statement before evaluating the practice. Remove the prestige association from the conversation by asking "if no one had heard of this before, would we still adopt it?"
   - For S-dominant cases: invest time in understanding the conditions that made the practice work — read the source material critically, talk to practitioners, identify the prerequisite organizational conditions.
   - For I-dominant cases: use `fit-practice` to evaluate whether the practice's wisdom can be extracted and applied in a context-appropriate way without installing its surface forms.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The team has already done a genuine fit analysis and needs execution support — the diagnosis is complete, use the relevant practice framework instead.
- The adoption in question is of a technical tool with measurable, context-independent properties (e.g., a specific database technology with known performance characteristics) — technical fit analysis is different from VSI diagnosis.
- The criticism of a practice is purely motivated by personal preference or technical tribalism — VSI is a diagnostic, not a weapon for disagreeing with technology choices on aesthetic grounds.

### Failure Patterns Warned by the Author

- **Cargo culting the cargo-culting diagnosis:** Using the VSI label to dismiss any adoption proposal from a skeptical position rather than conducting the actual three-element analysis. The framework requires evidence, not assumption of bad faith.
- **Senior engineer resistance as inverse cargo culting:** Experienced engineers who resist new practices because they threaten existing expertise are exhibiting their own form of shallow understanding. VSI applies in both directions.
- **Installing the form of VSI analysis:** Asking the three V/S/I questions as a compliance ritual without genuinely investigating the answers. This is cargo-culting the cargo-culting framework.

### Author's Blind Spots / Limitations

- The framework primarily targets visible, named practices (SRE, DORA, SAFe, Spotify model). Subtler forms of cargo culting — inherited coding conventions, implicit design pattern preferences, unexamined architectural defaults — are harder to surface with VSI because they lack the "prestige source" trigger.
- The remediation path (stop, investigate, use fit-practice) assumes the team has organizational access to delay or reject a leadership-mandated adoption. In many contexts, the cargo culting is being driven by someone with enough authority that resistance is not a realistic option.
- Cost of non-adoption is not modeled. There are contexts where cargo-culting an industry standard is less costly than the engineering effort required to derive a fit practice from scratch.

### Easily Confused With

- **Legitimate learning from other organizations:** Studying what Google does is not cargo culting; adopting it uncritically without understanding the conditions is. The VSI framework is designed to make this distinction explicit, not to prohibit learning from others.
- **Best practice critique:** "Best practice is bad" is not the VSI conclusion; "best practice applied without fit analysis is bad" is. The source explicitly says best practices often contain real wisdom — the problem is the context-free generalization.

______________________________________________________________________

## Related Skills

- **contrasts-with** → [`fit-practice`](../fit-practice/SKILL.md): VSI diagnoses whether an adoption is cargo-culted (the mechanism); fit-practice provides the evaluation method to determine what would constitute a fitting alternative.
- **contrasts-with** → [`3ts-premature-optimization`](../3ts-premature-optimization/SKILL.md): 3Ts diagnoses premature optimization (wrong thing/time/trade-offs); VSI diagnoses prestige-driven adoption. They can co-occur but address different root causes.
- **composes-with** → [`fit-practice`](../fit-practice/SKILL.md): VSI identifies the adoption is cargo-culted; fit-practice is the remedy — use both together to diagnose and correct the adoption decision.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
