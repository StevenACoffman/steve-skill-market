# Merge Audit: Design-Stamina-Strategic-Investment

## Sources

- Source A: `fowler-refactoring/fowler-design-stamina` (Fowler, Refactoring Ch. 2)
- Source B: `jousterhout/strategic-vs-tactical-programming` (Ousterhout, APoSD Ch. 3)
- Phase 1 input: `candidates/pair-020-phase1.md`

## R — Quote Verification

| Quote                                     | Source                                              | Verification Status                                                                                    |
| ----------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Design Stamina Hypothesis paragraph       | Fowler, Ch. 2, p. 49–50                             | Verified verbatim (Phase 1.5 audit)                                                                    |
| "Most dangerous way" / clean code trap    | Fowler, Ch. 2, p. 57                                | Verified exact match (Phase 1.5 audit)                                                                 |
| "Don't tell" passage                      | Fowler, Ch. 2, p. 57–58                             | Verified in source                                                                                     |
| 10–20% investment / strategic programming | Ousterhout, Ch. 3 (composite of lines 611, 636–637) | Accurate in substance; composite of two passages, not single verbatim block — noted in Phase 1.5 audit |
| Tactical tornado description              | Ousterhout, Ch. 3, line 588                         | Verified in source; SKILL.md paraphrase is faithful                                                    |

**Composite quote note:** The Ousterhout R-section quote as it appears in the source SKILL.md merges two passages from Chapter 3. The merged SKILL.md presents the key claims separately and attributed — this avoids the composite-as-verbatim issue.

## Convergence Claim

Both books independently invoke the same two-curve velocity model (quality vs. no-quality). Fowler writes from the context of existing codebases and manager communication; Ousterhout writes from the context of moment-to-moment developer decisions and institutional culture. Neither cites the other. The convergence is genuine across independent domains.

## Divergence Encoding

| Divergence                                                             | Resolution in SKILL.md                                                                                                                          |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Fowler: embed and hide; Ousterhout: name and budget                    | Audience-conditional in I section and E step 3: technical audiences get explicit budget; non-technical audiences get embedded-invisible framing |
| Fowler: applies to existing codebases; Ousterhout: applies to new work | E section splits into two sub-flows: steps 1–5 (existing code) and steps 6–7 (new work and culture)                                             |
| Tornado not named by Fowler                                            | Added to I and A1 Case 2; synthesis-specific B failure names the combined risk                                                                  |

## Genuine Tension Surfaced

B section explicitly surfaces: "Fowler says 'don't justify refactoring on aesthetics, use economics'; Ousterhout says 'invest in design from the start.'" Resolution: these apply to different situations (existing codebase vs. new work). The E section encodes this as a conditional rather than claiming the two authors agree.

## RIA++ Gate Check

| Gate                                                           | Status | Evidence                                                                                       |
| -------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------- |
| R: attributed quotes + convergence note                        | PASS   | Both authors quoted; one-sentence convergence note in R section                                |
| I: unified framework, no "Author A says/B says"                | PASS   | I section synthesizes without attribution framing; divergences encoded as conditionals         |
| A1: one case per book, different domains                       | PASS   | Case 1 = organizational communication (Fowler); Case 2 = engineering culture (Ousterhout)      |
| A2: sharper than union; "instead of X or Y, use this when"     | PASS   | Explicit "instead of" trigger condition included                                               |
| E: reconciled with conditionals, not longer than longer source | PASS   | 7 steps; source A had 6 steps; source B had 5 steps; merged is not longer                      |
| B: source A failures, source B failures, synthesis-specific    | PASS   | Three labeled sections; synthesis failure explicitly names tornado + communication interaction |
| B: contradictions surfaced                                     | PASS   | "Genuine tension" paragraph names the Fowler/Ousterhout framing conflict and resolution        |

## Notes

- The tactical tornado insight is the key synthesis contribution: tornado outputs look like high velocity (what Fowler's savvy manager celebrates), but are invisible as a failure mode without Ousterhout's vocabulary. Neither source alone provides both the vocabulary (Ousterhout) and the communication framing for raising it with different audiences (Fowler).
- The audience-conditional (name internally / potentially hide externally) is the operational synthesis not provided by either source alone.
