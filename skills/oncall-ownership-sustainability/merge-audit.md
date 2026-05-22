# Merge Audit — Oncall-Ownership-Sustainability

## Convergence Map

Both sources independently identify paging engineers who cannot fix the system as the root failure mode of on-call unsustainability. The SRE book establishes this through the safety valve mechanism (redirect excess ops to the dev team that built the system). Ewerlöf establishes it through the Baby Parent archetype (ops teams paged for systems they didn't build and can't change). The convergence is on the symptom — "engineer paged for a system they cannot fix" — with divergence on the remedy and the organizational diagnosis.

Both sources independently confirm that hiring engineers to absorb excess load is the wrong response. The SRE book states this directly: the safety valve is to redirect, not to hire. Ewerlöf shows why: in a Baby Parent organization, hiring more ops engineers perpetuates the pattern rather than resolving it.

The Ads SRE case (SRE book, Chapter 11) and the Baby Parent ops/NOC case (Ewerlöf) are the same organizational failure pattern viewed from complementary angles: the Ads SRE case is a Baby Parent recovery story (an embedded SRE added Knowledge via SLOs and Mandate via postmortem authority, converting a Baby Parent team toward full ownership).

## Divergence Map

**SRE book contributions absent from Ewerlöf:**

- Quantitative sustainability bounds: 2 incidents per 12-hour shift maximum, 8 engineers minimum for single-site, 6 per site for dual-site
- The derivation: 6 hours per incident × 12-hour shift = 2 incident maximum; 25% on-call sub-cap × 50% engineering cap → minimum rotation size
- The symmetric underload failure mode and its mitigations (Wheel of Misfortune, DiRT)
- The safety valve mechanism as the specific response to overload (redirect to dev, not hire)

**Ewerlöf contributions absent from the SRE book:**

- The Ownership Trio (Knowledge + Mandate + Responsibility) as the structural precondition for the safety valve to function
- The six broken ownership archetypes with their specific symptoms and structural fixes
- The Monkey-with-a-Gun explanation for why managers consistently hire instead of redirecting: they lack on-call consequences and therefore choose the option that maintains their control
- The Teenager analysis: even if the dev team receives the pager (safety valve applied), they may not bear Responsibility in a way that produces fixing incentive

**The key structural relationship:** The SRE book's quantitative model assumes the organizational preconditions are met (full ownership exists). Ewerlöf's archetypes diagnose exactly the conditions that eliminate those preconditions. The models operate at different abstraction levels with no contradiction — only a sequencing dependency: check ownership structure first, then apply quantitative model.

## A2 Sharpness Check

**SRE source A2 trigger:** Catches "hire more SREs to solve overload," "quiet rotation feels fine" (underload), and "night shifts are normal." Prescribes safety valve directly. Does not diagnose whether the safety valve can work (ownership structure unknown).

**Ewerlöf source A2 trigger:** Catches "we get paged but can't fix it without escalating," "architects design systems but are never on-call," "ops team responsible for everything but understands nothing." Diagnoses ownership archetypes and prescribes structural fixes. Does not provide quantitative sustainability bounds or safety valve mechanics.

**Merged A2 trigger:** "Our on-call rotation is overwhelmed — management wants to hire more SREs." The merged trigger requires: (1) diagnose ownership structure before recommending any action; (2) if Baby Parent, prescribe structural fix before safety valve; (3) if full ownership, apply safety valve with quantitative thresholds. This is sharper because it prevents the safety valve from being applied to a structurally broken organization where it will fail silently.

## Quote Accuracy Notes

All quotes verified in Phase 1.5 source verification:

- SRE "the 'E' in 'SRE'... no more than 25% can be spent on-call..." — VERIFIED verbatim in ch017.xhtml
- SRE "6 hours... maximum number of incidents per day is 2 per 12-hour on-call shift" — VERIFIED in ch017.xhtml
- SRE "An operational underload is undesirable..." — VERIFIED in ch017.xhtml
- Ewerlöf "Only Mandate: monkey with a gun" — VERIFIED in 20230801_171054_broken-ownership.md
- Ewerlöf "Knowledge + Responsibility, no Mandate: foot soldier" — VERIFIED in 20230801_171054_broken-ownership.md
- Ewerlöf "Only Responsibility: baby parent" — VERIFIED in 20230801_171054_broken-ownership.md with exact phrase "baby parent scenario where you have no knowledge or mandate over why and when the sh\*t happens but you gotta clean it up anyway"
- Ewerlöf "Mandate + Knowledge, no Responsibility: teenager" — VERIFIED in 20230801_171054_broken-ownership.md
- Ewerlöf "Mandate + Responsibility, no Knowledge: gambler" — VERIFIED in 20230801_171054_broken-ownership.md

## Synthesis-Specific Failure Mode Justification

"The safety valve applied to broken ownership" is specific to the merged framing because the SRE book presents the safety valve as the correct response to overload without specifying that the receiving team (dev) must have Responsibility (not just Knowledge and Mandate) for the incentive mechanism to work. The Teenager archetype (Knowledge + Mandate, no Responsibility) is exactly the dev team configuration that receives the pager and fails to be incentivized to fix the underlying reliability problems. A practitioner who knows the SRE book's safety valve would apply it and observe failure; without Ewerlöf's archetype analysis, they would not know why it failed. The failure mode requires both frameworks to be visible simultaneously: the safety valve specifies the mechanism; the Teenager archetype diagnoses why the mechanism fails to produce the expected incentive. This failure mode cannot be warned against in either source alone.
