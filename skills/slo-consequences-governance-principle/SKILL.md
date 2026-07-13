---
name: slo-consequences-governance-principle
description: |
  Use this skill when diagnosing why an SLO is not improving reliability behavior, when establishing whether an organization has real SRE practice or just SRE vocabulary, or when designing the organizational commitment structure required to make SLOs function as a governance instrument rather than a reporting metric.

  Call when: An executive asks why the SLO hasn't improved reliability. A team has had SLOs for a year and outage frequency is unchanged. Engineers discuss SLO numbers but don't change priorities when the budget is exhausted. The SLO exists but the error budget policy does not, or exists but has never been invoked.

  Do not call when: The SLO and error budget policy are already ratified and enforced — the question is about implementing the policy's specific consequences (use error-budget-policy-framework) or about whether the SLO number is correct (use slo-stakeholder-negotiation-gate).
tags: [slo, error-budget, governance, principle-1, consequences, policy, leadership-commitment]
---

# SRE Principle: SLOs with Consequences Are the Governance Mechanism

## R — Original Text

> "SRE needs SLOs with consequences. The performance of your service relative to SLOs should guide your business decisions. We believe that the following practices—which you can achieve without even having a single SRE—are the crucial steps toward implementing SRE practices: Acknowledge that you don't want 100% reliability. Set a reasonable SLO target. Measure the SLO and commit to following the error budget policy. This commitment requires agreement from company leadership."
>
> "Otherwise, you won't be able to adopt an error budget–based approach to reliability. SLO compliance will simply be another KPI (key performance indicator) or reporting metric, rather than a decision-making tool."
>
> — Google SRE Workbook, Chapter 20 - SRE Team Lifecycles and Chapter 2 - Implementing SLOs

______________________________________________________________________

## I — Framework (Interpretation)

The specific claim of this principle: an SLO without a written, pre-approved error budget policy with organizational consequences is operationally equivalent to having no SLO. The SLO measures a thing. Consequences change behavior. Measurement without consequences produces dashboards, not reliability.

"Consequences" has a precise meaning here. It does not mean vague pressure to do better. It means a written policy — approved before any incident occurs — that specifies what the team MUST do (not may do, not should consider) when the error budget is exhausted. The policy must have been approved by company leadership. Without leadership commitment, the policy will be re-litigated at every incident by the party with the most organizational power, which is almost never the SRE team.

Three structural properties make an SLO a governance instrument rather than a reporting metric:

1. **Pre-written policy.** The consequences are documented before the crisis, not negotiated during it. Post-hoc negotiation always favors the party with more organizational power, not the technically correct decision.

2. **Pre-approved policy.** All three parties (product manager, dev team, SRE) have signed the policy before any incident. This creates a binding organizational commitment that is much harder to override than a post-incident recommendation.

3. **Leadership commitment.** The policy is endorsed by someone with organizational authority to enforce it — a VP, CTO, or equivalent. Without this, any individual team can opt out under pressure.

The Evernote case study demonstrates the failure mode: developers circumvented the error budget policy because they had not agreed to its consequences. The Home Depot case study demonstrates the enabling mechanism: VP sponsorship converted the policy from an SRE recommendation into an organizational requirement that development teams could not override.

An implicit 100% SLO — the absence of any explicit SLO — makes every deviation an emergency and leaves the team permanently reactive. Setting any SLO below 100% and writing a policy is the minimum viable implementation of SRE practice, achievable without any dedicated SRE staff.

______________________________________________________________________

## A1 — Past Application

**Case 1 — Evernote: SLO without consequences becomes a vanity metric**
Evernote introduced SLOs before introducing the error budget policy that gave them consequences. Developers did not change behavior when the budget was exhausted because they had not agreed to the policy and did not feel bound by it. The SLO became a reporting metric — discussed in monthly reviews, not acted upon. The fix was not to tighten the SLO number but to go back and get tripartite approval on the error budget policy. Once developers agreed in advance to the consequences, the debates stopped: when the budget was exhausted, the policy executed without re-litigation. The SLO had not changed; the organizational commitment had.

**Case 2 — Home Depot: VP sponsorship as the enabling mechanism**
Home Depot's move to the VALET SLO framework required explicit VP-level endorsement to function as a governance instrument. Before VP sponsorship, individual development teams could ignore SLO violations or argue that their service was an exception. After VP sponsorship, the error budget policy had organizational authority: a team could not unilaterally override a feature freeze without escalating to the VP who had endorsed the policy. This is leadership commitment as the workbook defines it — not just agreement from the SRE team, but agreement from the organizational authority that can enforce consequences against any team.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: "We have SLOs but reliability hasn't improved"**
An executive reports the team has had 99.9% SLOs for a year and outage frequency is unchanged. Diagnosis: check whether a written error budget policy exists. If no policy exists, the SLOs are reporting metrics. If a policy exists, check whether it has ever been invoked — whether a release freeze was actually executed when the budget was exhausted. If not, the policy exists on paper but has no organizational teeth. The fix is not to tighten the SLO; it is to ratify the policy with leadership commitment.

**Scenario 2: Post-incident SLO discussion**
After a major outage, the SRE team recommends a feature freeze based on budget exhaustion. The product manager overrides the recommendation citing business urgency. This is the post-hoc negotiation failure mode — it always favors the party with more organizational power. The correct structural fix is to ensure that the error budget policy was pre-approved before this incident, so the freeze is not a recommendation but a pre-agreed consequence that requires a documented exception to override.

**Scenario 3: "We're just going to track it for now"**
A team sets up SLO dashboards but explicitly defers writing the error budget policy. They want to "see how we're doing before committing to consequences." Trigger: this is the reporting metric trap. Deferred consequences mean deferred behavior change. The correct move is to write and ratify a minimal policy (even a simple one) before going live with the SLO measurement.

**Language signals:** "we measure it but we haven't done much with it yet," "we couldn't enforce the freeze because of the release timeline," "our SLO numbers are good but we're still having outages," "we'll figure out the consequences when we get there."

**Distinguishing from adjacent skills:** This principle is the why — SLOs only work when they have consequences. The SLO stakeholder negotiation gate is the how — how to get the tripartite approval that creates the consequences. The error budget policy framework is the what — the specific structure of the policy that implements the consequences. These are nested: this principle motivates the other two.

______________________________________________________________________

## E — Execution Steps

1. **Audit the current SLO state.** For each SLO the team has: (a) Does a written error budget policy exist? (b) Has the policy been approved by product manager, dev team, and SRE? (c) Has the policy ever been invoked? (d) Does it have leadership endorsement? An SLO that fails any of these four checks is a reporting metric, not a governance instrument.

2. **Write the error budget policy before doing anything else.** If no policy exists, write it now using the Appendix B template as a starting point. The policy must specify: what triggers a freeze (budget exhaustion), what must be worked on during a freeze (reliability, not features), and what exemptions apply (third-party outages, out-of-scope traffic). See the error-budget-policy-framework skill for the full structure.

3. **Convene the tripartite approval.** Get sign-off from product manager, dev team lead, and SRE lead. If any party refuses, the SLO needs revision (see slo-stakeholder-negotiation-gate). Do not proceed without tripartite approval.

4. **Escalate to leadership for endorsement.** Present the ratified policy to the organizational authority (VP Engineering, CTO, or equivalent). The endorsement should be explicit: "when the budget is exhausted and the freeze is triggered, I will support the SRE team's authority to enforce it."

5. **Test the policy on the next budget exhaustion.** The first time the budget is exhausted after ratification is the critical test. Enforce the policy exactly as written. Any override must be documented as an explicit exception, not treated as normal operation. Post-hoc exemptions erode the policy's credibility for all future incidents.

6. **Do not mistake tighter SLOs for stronger governance.** Tightening the SLO number without strengthening the policy enforcement mechanism produces a metric that is harder to hit but still not a governance instrument. The lever is the policy, not the number.

**Completion criteria:** A written error budget policy exists. All three parties have signed it. Leadership has endorsed it. The policy has been invoked at least once and the freeze executed without post-hoc renegotiation.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The SLO and error budget policy are already ratified and functioning — the organization is asking "what do we do now that the budget is exhausted?" Use error-budget-policy-framework for that.
- The organization has no SLO at all and the question is how to create one — start with SLI specification and SLO document structure, then use the negotiation gate, then use this principle to ensure consequences are built in.

**Failure patterns:**

- Ratifying the policy but granting the first exception under pressure. The first exception sets the precedent that the policy is negotiable. Subsequent exceptions become easier to justify. Within six months, the policy is a formality.
- Leadership endorsement that is conditional ("I support the freeze unless there's a major business reason not to"). Conditional endorsement is not endorsement — it preserves the post-hoc negotiation failure mode.
- Treating this principle as applicable only to organizations with dedicated SRE teams. The workbook explicitly states: "which you can achieve without even having a single SRE." Any engineering team can set an SLO, write a policy, and get leadership endorsement. The principle is not SRE-team-specific.

**Author blind spots:**

- The workbook assumes leadership is willing to commit to the policy before seeing it applied in a high-pressure situation. In practice, leaders often agree in principle but override the policy the first time it conflicts with a major product deadline. The workbook does not provide a mechanism for handling this first-violation scenario.
- The principle is stated as Principle #1, implying it is the foundation for all other SRE practices. This is correct but creates an all-or-nothing impression: teams may conclude that SRE is inapplicable if they cannot get leadership commitment. In reality, writing and ratifying a minimal policy is meaningful even with imperfect leadership commitment — it is better than no policy.
- The Evernote and Home Depot case studies demonstrate the principle in organizations that eventually succeeded. There are no case studies in the workbook of organizations that failed to ratify the policy and never recovered, which would make the failure mode more viscerally clear.

**Easily confused with:**

- SLO stakeholder negotiation gate (how to get the tripartite approval; this principle is why the approval matters and what it enables).
- Error budget policy framework (the structure of the policy document and its four mandatory components; this principle is the organizational commitment that makes the policy function).

______________________________________________________________________

## Related Skills

- **contrasts_with**: error-budget-policy-framework — this principle is the WHY (SLOs require organizational consequences to function); the policy framework is the HOW (the specific four-component document structure that implements those consequences)
- **depends_on**: slo-stakeholder-negotiation-gate — the principle requires tripartite approval plus leadership endorsement; the negotiation gate is the process that produces that commitment
- **composes_with**: slo-decision-matrix — the principle motivates why matrix outputs must trigger real engineering action, not just be observed on a dashboard

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "The Site Reliability Workbook" by Betsy Beyer et al. (Google) — Chapter 20 - SRE Team Lifecycles (Principle #1), Chapter 2 - Implementing SLOs, Chapter 3 - SLO Engineering Case Studies
