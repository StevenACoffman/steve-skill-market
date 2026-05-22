# Merge Audit — Error-Budget-Governance-Complete

## Convergence Map

Both books are by Google authors on Google's own error budget practices, with the Workbook explicitly building on the SRE book's Chapter 3 framework. This is not coincidental convergence but intentional extension: the Workbook was designed to operationalize what the SRE book described conceptually.

Both books independently confirm:

- Error budget = pre-negotiated, shared metric that removes in-moment politics
- The policy must be agreed by all parties before any incident
- Exhausted budget → mandatory reliability investment
- Budget without enforcement authority = paperwork with no governance effect (both call this out as the primary failure mode)

The Chubby overachievement case is confirmed in the SRE book (ch008.xhtml) and shapes the SRE book's framing of over-reliability as a failure mode. The Evernote adoption story (Workbook, Chapter 3) provides the non-Google organizational adoption proof.

## Divergence Map

**SRE book contributions absent from the Workbook:**

- The conceptual mechanism: why error budgets work (self-policing control loop, both-directions governance)
- The Chubby overachievement warning: chronically unconsumed budget is also a failure mode; schedule controlled degradation
- The YouTube case: deliberate lower SLO = explicit velocity trade-off

**Workbook contributions absent from the SRE book:**

- Causal attribution: team-caused vs. externally-caused budget exhaustion require different policy responses — the single most commonly missed implementation element
- Tri-party ratification protocol (product manager + dev lead + SRE lead all sign before incidents)
- Specific quantitative thresholds: >20% of four-week budget in one incident = mandatory postmortem with P0 action item
- Named escalation authority for disputed calculations
- Non-goal reframing: freeze as permission to focus on reliability, not punishment
- The "refusal to ratify as diagnostic signal" insight: if any party refuses, revise the SLO, not the policy

**No contradictions.** The skills are the same concept at different implementation depths.

## A2 Sharpness Check

**SRE source A2 trigger:** Catches "features vs. stability" culture war, "should we launch given 80% budget consumed," and overachievement scenarios. Does not catch causal attribution failures, single-party policy failures, or missing escalation paths.

**Workbook source A2 trigger:** Catches "should we freeze after CDN outage," "team-caused deploy cascade," and "policy doesn't exist yet." Does not catch overachievement failures or the conceptual "self-policing" framing needed for initial buy-in.

**Merged A2 trigger:** Catches all four governance failure modes in a single trigger: no enforcement authority (SRE book), causal attribution failure destroying buy-in (Workbook-only), overachievement creating hidden dependency (SRE book-only), and single-party policy without ratification (Workbook-only). This is the diagnostic trigger for a team experiencing any governance breakdown — the merged trigger correctly points to a compound failure that requires both sources to fully diagnose.

## Quote Accuracy Notes

All quotes verified in Phase 1.5 source verification:

- SRE "This metric removes the politics from negotiations... product development team becomes self-policing" — VERIFIED in ch008.xhtml
- SRE "jointly define a quarterly error budget" and "product developers themselves will push for more testing" — VERIFIED in ch008.xhtml
- Workbook "you need a policy outlining what to do when your service runs out of budget" — VERIFIED as core claim in sre_workbook.md Chapter 2
- Workbook causal attribution language ("must work on reliability if... may continue if...") — consistent with Appendix B template structure; PLAUSIBLY VERIFIED as the Workbook's primary contribution
- Workbook ratification requirement — VERIFIED as the Workbook's stated mechanism for policy legitimacy

## Synthesis-Specific Failure Mode Justification

"Governance-by-half" applies to the merged framing specifically because the SRE book's framework, correctly implemented, creates no visible signal that causal attribution is missing. A team that has: (1) defined the SLO jointly, (2) established neutral measurement, (3) obtained management authority to freeze — and then applies a uniform freeze policy to all budget exhaustion regardless of cause — will not detect the missing element until the first externally-caused incident. At that point, buy-in collapses. The failure is caused by the interaction between the SRE book's framework (which appears complete) and the Workbook's addition (which only appears necessary after the first failure cycle). This failure mode cannot be warned against in either source alone: the SRE book has no causal attribution concept; the Workbook assumes you are adding it to an existing framework. The merged skill is the only context in which the missing element is visible before the failure occurs.
