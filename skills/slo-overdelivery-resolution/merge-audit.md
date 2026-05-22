# Merge Audit — Slo-Overdelivery-Resolution

## Convergence Map

This pair has the strongest convergence in the SRE cluster. Both books independently cite the same Google Chubby planned outage as the canonical evidence that over-delivery creates consumer over-dependency. The SRE book generated the original case (ch009.xhtml verified). Ewerlöf's lagom-slo article cites the same pattern in the context of intentional SLO consumption — independent corroboration from a different authorship tradition that found the same case compelling enough to serve as the canonical example in his own calibration framework.

Both books independently arrive at the principle that observed availability should be kept within a narrow band of the stated SLO. Both independently prescribe planned outages as the operational mechanism. This is genuine convergence on the core principle with independent supporting evidence.

## Divergence Map

**Real tension, not contradiction:** The SRE book's dont-overachieve skill prescribes a single remedy: introduce synthetic outages to bring observed availability down to the committed level. Ewerlöf's lagom-slo skill implies an alternative: raise the SLO to match actual capability when the lower SLO was incorrectly set. These are alternative remedies for the same problem (observed >> committed), not compatible prescriptions.

The tension resolves into a conditional: synthetic outages are correct when the SLO is correctly calibrated; raising the SLO is correct when the SLO was incorrectly calibrated. The SRE book never asks whether the SLO was correctly calibrated before prescribing the remedy. Ewerlöf's framework is built on that question. The merged skill encodes the conditional explicitly.

**Scope difference:** dont-overachieve addresses what to do AFTER overdelivery is detected. lagom-slo addresses the calibration decision that should prevent incorrect SLO-setting in the first place. They are related as: correct calibration → correct SLO → dont-overachieve polices the gap if delivery drifts above commitment.

**Ewerlöf-only:** The too-low failure mode (SLO below consumer tolerance outsources cost to N consumer teams) has no analog in dont-overachieve. The SRE book only addresses the too-high/overachievement direction.

## A2 Sharpness Check

**dont-overachieve source A2 trigger:** Catches "we've never had downtime," "actual availability much better than SLO," "consumers not implementing circuit breakers," and "planning first maintenance window." Prescribes synthetic outages regardless of SLO calibration status.

**lagom-slo source A2 trigger:** Catches "SLO set historically," "SLO too high blocking features," "consumers building workarounds," "what should our SLO be?" Does not address the operational mechanics of overdelivery resolution.

**Merged A2 trigger:** Catches the decision fork: service is chronically above SLO — should we raise the SLO or introduce synthetic outages? This is the scenario that falls directly between both source A2s. dont-overachieve says "synthetic outages"; lagom says "maybe raise the SLO if it was wrongly set." Neither source provides the decision criterion. The merged trigger is sharper because it requires both sources to answer the actual question a team faces.

## Quote Accuracy Notes

All quotes verified in Phase 1.5 source verification:

- SRE "Users build on the reality of what you offer..." including "particularly for infrastructure services" and Chubby reference — VERIFIED verbatim in ch009.xhtml
- SRE Chubby case ("consistently achieving much higher availability than its stated SLO") — VERIFIED in ch009.xhtml "Global Chubby Planned Outage" section
- Ewerlöf "A lagom SLO is not too high or too low..." — VERIFIED verbatim in 20231211_053037_lagom-slo.md
- Ewerlöf "An SLO should define the lowest level of reliability that you can get away with..." — VERIFIED verbatim in 20231211_053037_lagom-slo.md
- Ewerlöf Media Company CTO case — VERIFIED in 20231211_053037_lagom-slo.md (discusses 5-nines problem and cost modeling explicitly)
- Ewerlöf too-low case — VERIFIED in 20231211_053037_lagom-slo.md ("When the service level is too low, your service consumer can do their own preparation...")

## Synthesis-Specific Failure Mode Justification

"Applying Remedy B to a miscalibrated SLO" is specific to the merged framing because the dont-overachieve skill correctly identifies the gap and correctly prescribes synthetic outages — but has no mechanism for detecting whether the lower SLO was correctly calibrated. A practitioner who reads only the dont-overachieve skill has no prompt to ask "was this SLO set correctly?" before applying the remedy. The harm from misapplying Remedy B (unnecessary degradation of a service that should simply raise its SLO) is real but subtle: the service degrades, consumers experience artificial outages, and no one asks whether the lower SLO was correct in the first place. This failure mode requires the merged framing to be visible — only by seeing both skills simultaneously does a practitioner know that calibration diagnosis is the mandatory first step.
