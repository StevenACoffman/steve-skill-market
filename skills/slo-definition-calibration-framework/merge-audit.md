# Merge Audit — Slo-Definition-Calibration-Framework

## Convergence Map

Both books independently confirm that SLO targets set without consumer input produce characteristic failure modes. The SRE book establishes this through the Chubby over-delivery case (consumers build hidden dependencies when a service chronically delivers above its SLO). Ewerlöf confirms the same principle from the opposite direction (too-low SLO outsources cost to consumers). The shared Chubby evidence — the same Google case cited in both skills as canonical proof — is the strongest convergence evidence: independent corroboration that over-delivery creates systemic risk.

Both books independently warn against setting SLOs from historical performance. The SRE book states "choosing a target based on current performance" is explicitly listed as an anti-pattern. Ewerlöf labels this ce10 ("SLO set by looking at historical data without consumer input"). The convergence is not coincidental — both arrived at the same critique from different analytical angles.

## Divergence Map

**What the SRE book contributes that Ewerlöf does not:**

- The three-tier definitional structure (SLI as measurement, SLO as engineering target, SLA as external contract with consequences)
- The SLA buffer requirement: SLA must sit below SLO with a margin sufficient for detection-and-response before contractual breach
- The SLO/SLA conflation failure mode (publishing the same number in both engineering docs and contracts)

**What Ewerlöf contributes that the SRE book does not:**

- The consumer tolerance elicitation methodology (the consumer question as the primary calibration input)
- The too-low failure mode with organizational cost calculus: N × consumer mitigation cost vs. cost of improving provider SLO
- The lagom framing: calibration is bidirectional; both too-high and too-low are wrong for different reasons
- The aspirational SLO anti-pattern (five-nines without consumer research)

**No contradictions.** These are complementary scope gaps: the SRE book answers "what are these artifacts and how do they relate?" while Ewerlöf answers "what target number should the SLO be?" The merged skill addresses both.

The one asymmetry: lagom-slo explicitly addresses the too-low failure mode with cost reasoning. The SRE book does not address SLO-too-low at all — it focuses exclusively on the too-high/overachievement direction.

## A2 Sharpness Check

**SRE source A2 trigger:** Catches SLO/SLA conflation ("we target 99.9% uptime" in both engineering docs and contracts), overachievement scenarios, and "which metrics to track" questions. Does not catch miscalibrated targets set from historical data or consumer-unaware aspirational SLOs.

**Ewerlöf source A2 trigger:** Catches aspirational SLOs, historical-data SLOs, too-low SLOs generating consumer mitigation costs, and "what should our SLO be?" questions. Does not catch SLA buffer design errors or SLI/SLO/SLA conflation.

**Merged A2 trigger:** Catches the compound failure: a team simultaneously confused about what an SLO is (SRE domain), setting it at the wrong number from historical data (Ewerlöf domain), and with no designed SLA buffer (SRE domain). This compound failure — the "first SLO setup" scenario — is exactly what falls between both source A2s. The merged A2 is sharper because it catches the simultaneous three-decision failure that neither source independently detects.

## Quote Accuracy Notes

All quotes verified in Phase 1.5 source verification:

- SRE "Users build on the reality of what you offer..." — VERIFIED verbatim in ch009.xhtml
- SRE SLI/SLO/SLA definitions ("An SLI is a service level indicator...") — VERIFIED verbatim in ch009.xhtml
- Ewerlöf "A lagom SLO is not too high or too low..." — VERIFIED verbatim in 20231211_053037_lagom-slo.md
- Ewerlöf "An SLO should define the lowest level of reliability that you can get away with..." — VERIFIED verbatim in 20231211_053037_lagom-slo.md (citing Google PMs Jay Judkowitz and Mark Carter)
- Ewerlöf too-low reasoning ("When the service level is too low...") — VERIFIED in 20231211_053037_lagom-slo.md

## Synthesis-Specific Failure Mode Justification

The "completed-one-decision trap" is specific to the merged framing because neither source alone presents all three decisions as a set. A practitioner using only the SRE skill completes decisions 1 and 3 (definitional structure and SLA buffer) without a methodology for decision 2 (target calibration). A practitioner using only Ewerlöf's skill completes decision 2 (calibration) without knowing the SLA buffer requirement exists. The trap — completing the visible decisions while skipping the less-obvious middle one — requires both sources to be visible simultaneously for a practitioner to notice it. This failure mode cannot be warned against in either source skill alone; it is a failure of the interaction between the two incomplete frameworks.
