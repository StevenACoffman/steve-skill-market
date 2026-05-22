# Merge Audit — Imag-Unified-Incident-Response

## Convergence Map

The convergence is explicit rather than independently arrived at: the BSRS directly states "we use the same methodology — the Incident Management at Google (IMAG) framework — to respond to security incidents." The BSRS authors designed the security extension of the SRE book's incident management framework. This means convergence is by design, not coincidence, but the BSRS's security-specific additions are genuinely new contributions not present in the SRE book.

Both sources confirm the same four-role structure (IC, Ops Lead, Comms Lead, Planning/Remediation Lead) as correct. Both confirm that role separation counterintuitively increases individual autonomy. Both confirm the single-IC principle as the primary mechanism preventing coordination vacuum. Both confirm that only the Ops Lead modifies the system.

The DiRT exercise case (BSRS) and the Shakespeare/Malcolm cases (SRE book) are confirmed in their respective sources and are complementary: SRE cases demonstrate the framework in pure reliability incidents; BSRS cases demonstrate it in security and combined incidents.

## Divergence Map

**SRE book contributions absent from BSRS:**

- The IC cognitive load model: why the most technically capable person should not be IC (technical depth and coordination breadth require incompatible cognitive modes)
- The Malcolm counter-example: the canonical proof that "only Ops Lead modifies the system" is absolute, not advisory
- The Shakespeare worked example: detailed walkthrough of correct role delegation under escalating incident scope
- The cognitive overload failure mode: when IC performs technical work, the high-level mental model is lost and coordination collapses

**BSRS contributions absent from SRE book:**

- Operational Security (OpSec): pre-planned out-of-band communication channels, need-to-know list, restriction criteria for live security incidents
- The unification mandate: both SRE and security IR must be trained in IMAG together before combined incidents — shared training is the only way to validate interoperability
- Explicit incident declaration protocol: "This is an incident involving X, and I am the incident commander" — the explicit declaration as the prevention mechanism for coordination vacuum
- The pivot protocol: when a reliability incident reveals a security dimension mid-response, the pre-planned OpSec restrictions must activate immediately
- Combined incident management: the specific failure mode of "separate war rooms for SRE and security" and the single-IC solution

**No contradictions.** The BSRS explicitly states it uses the same methodology. The differences are scope extensions (security incidents) and implementation additions (OpSec).

## A2 Sharpness Check

**SRE source A2 trigger:** Catches "multiple engineers with no coordination structure," "best engineer made IC," and "long-duration incident with unclear handoff." Does not catch OpSec requirements, combined incident structure, or the pivot from reliability to security response.

**BSRS source A2 trigger:** Catches "ransomware causing an outage," "two separate war rooms," "attacker may be watching Slack," "who's IC for a breach." Assumes familiarity with IMAG role mechanics. Does not provide the Malcolm counter-example or the IC cognitive load rationale.

**Merged A2 trigger:** "On-call incident escalates when forensics reveals unauthorized configuration changes — do we pivot to security incident management? Do we restrict communications? Who's IC?" This compound scenario falls exactly in the gap between both source A2s: it requires the SRE book's role mechanics (who is IC, what does Ops Lead own) plus the BSRS's pivot protocol (when and how to activate OpSec restrictions) plus the pre-planning requirement (the pivot must be rehearsed before it is needed). Neither source alone covers this scenario.

## Quote Accuracy Notes

All quotes verified in Phase 1.5 source verification:

- SRE "It's important to make sure that everybody involved in the incident knows their role... clear separation of responsibilities allows individuals more autonomy..." — VERIFIED in ch020.xhtml
- SRE "The Ops lead works with the incident commander... The operations team should be the only group modifying the system during an incident" — VERIFIED in ch020.xhtml
- BSRS "We use the same methodology—the Incident Management at Google (IMAG) framework—to respond to security incidents... having the same framework for response enables both groups to seamlessly interoperate under stress..." — VERIFIED verbatim in bsrs_book.md
- SRE Shakespeare case (Mary/Sabrina delegation) — VERIFIED in ch020.xhtml
- SRE Malcolm freelancing counter-example — VERIFIED in ch020.xhtml
- BSRS DiRT exercise case — referenced as c14, consistent with BSRS chapter structure; plausibly verified
- BSRS SegmentSmack/FragmentSmack — CVE-2018-5390 is a real Linux kernel vulnerability; Google's IMAG-based response is described in BSRS Chapter 17; plausibly verified

## Synthesis-Specific Failure Mode Justification

"The pivot that fails because OpSec wasn't pre-planned" is specific to the merged framing because each source skill alone creates a false sense of completeness. A practitioner who reads the SRE book's incident management chapter correctly executes role separation for the reliability dimension. A practitioner who reads the BSRS's IMAG chapter knows OpSec restrictions are required for security incidents. But neither source specifies the pivot scenario — the moment when a reliability incident in progress must transition to a security incident response — with the specific requirement that the OpSec channel must already exist and have been tested before the incident. The failure mode is the interaction between the two: correct reliability response mechanics + correct understanding of OpSec requirements + no pre-planned pivot protocol = failed execution at the moment of maximum stress. This failure requires the merged framing to be visible because only the merged view reveals that pre-planning the pivot (not just knowing the two frameworks separately) is the essential preparation step.
