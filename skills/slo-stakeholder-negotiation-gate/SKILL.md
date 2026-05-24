---
name: slo-stakeholder-negotiation-gate
description: |
  Use this skill when an SLO is being set, revised, or validated for fitness — specifically when determining whether the SLO number is appropriate, defensible, and agreed upon by all parties who will be bound by its consequences.

  Call when: A team is setting an initial SLO, revising an existing one after a post-incident review, or there is disagreement about whether an SLO is achievable or appropriate. Also call when the error budget policy cannot be ratified because one or more parties refuses to sign.

  Do not call when: The SLO is already ratified and the question is about what to do now that the budget has been exhausted (use error-budget-policy-framework) or about whether to adjust alerting thresholds (use multiwindow-multi-burn-rate-alerting).

  Key trigger: Any situation where one party sets an SLO without involving the others, or where the SLO is being debated after an incident. The negotiation gate must happen before incidents, not during or after. Disagreement at the approval stage is not a negotiating failure — it is a diagnostic signal that the SLO needs revision.
source_book: "The Site Reliability Workbook" by Betsy Beyer et al. (Google)
source_chapter: "Chapter 2 - Implementing SLOs; Chapter 18 - SRE Engagement Model"
tags: [slo, negotiation, stakeholder-alignment, error-budget-policy, governance, toil]
related_skills: []
---

# SLO Stakeholder Negotiation Gate (Tripartite Policy Approval as SLO Fitness Test)

## R — Original Text

> "Getting the error budget policy approved by all key stakeholders—the product manager, the development team, and the SREs—is a good test for whether the SLOs are fit for purpose: If the SREs feel that the SLO is not defensible without undue amounts of toil, they can make a case for relaxing some of the objectives. If the development team and product manager feel that the increased resources they'll have to devote to fixing reliability will cause feature release velocity to fall below acceptable levels, then they can also argue for relaxing objectives. If the product manager feels that the SLO will result in a bad experience for a significant number of users before the error budget policy prompts anyone to address an issue, the SLOs are likely not tight enough. If all three parties do not agree to enforce the error budget policy, you need to iterate on the SLIs and SLOs until all stakeholders are happy."
>
> — Google SRE Workbook, Chapter 2 - Implementing SLOs

______________________________________________________________________

## I — Framework (Interpretation)

An SLO is not valid until three distinct parties have approved the error budget policy that governs it. The three parties are: (1) the product manager, who represents user needs and the business consequence of reliability failures; (2) the development team, who will be accountable for reliability work when the budget is exhausted; and (3) the SRE team, who must defend the SLO operationally without exceeding the 50% toil cap.

The fitness test is not whether the SLO number is technically achievable. It is whether all three parties can sign the error budget policy — the pre-written document that specifies what happens when the budget is exhausted. Each party holds a different veto:

- **SRE veto:** "This SLO requires toil that would exceed our 50% cap. We cannot defend it without burning out the team." This is not a negotiating tactic — it is an engineering assessment.
- **Dev team veto:** "Complying with the error budget policy when the budget is exhausted would eliminate feature velocity entirely, which the business cannot accept at this SLO level." This signals the SLO may be too tight for the current reliability state.
- **Product manager veto:** "The SLO threshold is loose enough that users will experience significant degradation before the policy requires any action. We cannot accept that user experience." This signals the SLO may be too loose.

When any party refuses to sign, the correct response is to revise the SLO, not to override the veto. Disagreement is diagnostic. It reveals that the SLO as written cannot be simultaneously user-acceptable, operationally defensible, and business-compatible. That is exactly the information the team needs before an incident forces the question.

The alternative — setting the SLO and debating consequences when the budget is exhausted — always favors the party with more organizational power at crisis time, not the technically correct decision.

______________________________________________________________________

## A1 — Past Application

**Case 1 — Evernote: retroactive negotiation fails**
When Evernote introduced SLOs without developer buy-in, developers initially circumvented the error budget policy because they had never agreed to its consequences. When budgets were exhausted, the debate about whether to freeze releases recurred at every incident as if the policy did not exist. The error budget policy had been written, but it had not been ratified. The fix was to restart the approval process — going back to developers and product management to negotiate the policy before any future incident. After tripartite approval, the policy held: developers accepted the freeze because they had agreed to it in advance.

**Case 2 — Home Depot VALET framework: VP sponsorship as the organizational enabler**
Home Depot's VALET SLO framework required VP-level sponsorship to become effective. Until senior leadership endorsed the error budget policy, individual development teams could opt out of consequences without organizational recourse. The VP sponsorship converted the policy from a suggestion into a governance instrument. This is the "company leadership commitment" that the workbook identifies as a prerequisite: without an authority structure that can enforce the policy, tripartite approval at the team level is insufficient.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: SLO set unilaterally by product management**
A product manager declares the service must have 99.99% availability "because that's what enterprise customers expect." The SRE team has not evaluated whether this is defensible within toil constraints. The development team has not agreed to a feature freeze when the budget is exhausted. Trigger: run the negotiation gate. The first question to the SRE team is whether they can defend 99.99% without exceeding the toil cap. If not, the conversation is about what automation investment is required before the tighter SLO can be adopted.

**Scenario 2: Error budget policy cannot be ratified**
The team has a written error budget policy but cannot get all three parties to sign. The SRE team says the SLO is too tight given current infrastructure. Trigger: this is the negotiation gate working correctly. The refusal is a design signal. Options: relax the SLO threshold, add an automation investment roadmap as a precondition for adopting the tighter SLO, or adopt an aspirational SLO (measured but not enforced) while the automation is built.

**Scenario 3: Post-incident SLO debate**
After a major outage, the post-incident review produces a recommendation to tighten the SLO. Trigger: any new SLO — even one set in a post-incident context — must pass the tripartite gate. A tightened SLO set unilaterally by the SRE team during a high-pressure post-incident period has not been validated for developer and product manager acceptability.

**Language signals:** "the product team says we need five nines," "the SRE team says we can't hit that without burning out," "let's just set the SLO and see what happens," "we can negotiate the consequences when we get there."

**Distinguishing from adjacent skills:** The negotiation gate is about whether the SLO is valid before any incident. The error budget policy framework is about what to do when the budget is exhausted. The SLO decision matrix is about diagnosing the current state (SLO met/missed × toil × satisfaction). These are sequential: negotiate and ratify the SLO → measure it against the matrix → respond per the policy.

______________________________________________________________________

## E — Execution Steps

1. **Draft the error budget policy first, before finalizing the SLO number.** The policy draft forces all parties to confront the consequences of the SLO before agreeing to the target. Appendix B of the workbook provides a production-ready policy template.

2. **Convene a tripartite review.** Schedule a meeting with the product manager, a technical lead from the development team, and the SRE lead. All three must be decision-makers, not representatives who need to "check with someone."

3. **SRE operational defensibility assessment.** The SRE lead states whether the proposed SLO can be defended within the 50% toil cap given the current system state. If not, they must specify: (a) what the maximum defensible SLO is today, and (b) what automation investment would enable the tighter target.

4. **Development team consequence acceptance.** The development team lead states whether they accept the policy consequences — specifically, the feature freeze when the budget is exhausted. If not, they must specify: (a) what freeze conditions they can accept, or (b) what SLO relaxation makes the policy acceptable.

5. **Product manager user experience assessment.** The product manager states whether the SLO threshold (and the policy's response time) will result in acceptable user experience. If not, they must specify what threshold is required.

6. **Iterate on the SLO, not the policy.** If any party refuses, revise the SLO target, the SLI definition, or the measurement window — not the policy consequences. The policy should be as strong as possible; the SLO target is the variable.

7. **Document disagreement explicitly.** If the team adopts an aspirational SLO (measured but not enforced) while waiting for automation investment, document this explicitly: what the aspirational target is, what investment is required to make it enforceable, and the timeline for revisiting.

8. **Ratify with signatures.** All three parties sign the error budget policy. This is not ceremonial — it creates the organizational commitment that makes the policy hold under pressure.

**Completion criteria:** All three parties have signed the error budget policy. The SLO target has been set at a level that each party can defend and accept. The policy specifies what happens when the budget is exhausted, with no post-hoc negotiation required.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The SLO is aspirational only and explicitly not enforced — no policy can be ratified against an aspirational target, and this is correct. Document the aspirational status and the conditions for promotion to enforced.
- The service is pre-GA and does not yet have sufficient production data to calibrate an SLO. Use the engagement model phase structure instead (Chapter 18): SLOs should be defined before GA, not after.
- The dispute is purely technical (e.g., which SLI measurement point is most accurate) rather than about the organizational fitness of the SLO. Technical disputes go to the SLI specification layer, not the negotiation gate.

**Failure patterns:**

- Treating tripartite approval as a checkbox rather than a genuine negotiation. If all three parties agree immediately without pushback, the SLO is probably too loose — real negotiation involves tension.
- Ratifying the policy but not enforcing it when the budget is exhausted. Post-hoc exemptions from a ratified policy erode the policy's credibility for all future incidents.
- Allowing the most organizationally powerful party to override the others' veto. This defeats the diagnostic function of the gate.

**Author blind spots:**

- The engagement model assumes the SRE team has organizational authority to refuse to sign — this is a structural prerequisite that does not exist in all organizations. Without leadership support for the SRE veto, the gate becomes a formality dominated by the product manager.
- The framework is designed for services where SRE is a distinct team. In organizations where engineers do their own operations (DevOps model), the "three parties" may be the same people wearing different hats. The gate still applies but requires explicit hat-switching.
- Non-Google case studies in the workbook (Evernote, Home Depot) are thinner than Google's internal examples; the Home Depot case shows VP sponsorship as the enabling mechanism but does not detail the negotiation process itself.

**Easily confused with:**

- Error budget policy framework (what to do when the budget is exhausted, not how to set the SLO).
- SLO document structure (how to write an SLO document, not how to negotiate the target).

______________________________________________________________________

## Related Skills

- **depends_on**: slo-consequences-governance-principle — the negotiation gate is only meaningful if the organization has committed to the principle that SLOs must have real consequences; without that commitment, tripartite approval is a formality
- **composes_with**: error-budget-policy-framework — drafting the error budget policy and presenting it to all parties IS the mechanism of the negotiation gate; they are executed together
- **contrasts_with**: slo-decision-matrix — the negotiation gate sets and validates the SLO before any incident; the decision matrix calibrates an existing SLO during ongoing operation

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04
