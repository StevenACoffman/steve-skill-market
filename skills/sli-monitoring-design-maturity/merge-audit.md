# Merge Audit — Sli-Monitoring-Design-Maturity

## Convergence Map

Both sources independently identify the symptom-vs-cause distinction as the central monitoring design principle. The SRE book establishes this structurally (four golden signals are symptom-level; CPU/memory are cause-level, belonging in debugging dashboards). Ewerlöf confirms the same principle as the defining characteristic of Stage 3 advancement: SLIs grounded in consumer task failures (symptoms) rather than system state (causes).

The SRE book's own cases (Bigtable, Gmail) are confirmed examples of Stage 1 failure modes. Bigtable's mean-latency alert storm is a measurement quality problem at Stage 1. Gmail's cause-based alerting on de-scheduled tasks is a Stage 1 failure of alerting on internal system state rather than consumer-visible symptoms. The SRE book documents these as problems to fix; Ewerlöf's model provides the systematic diagnosis for why they occur. This is genuine convergence: the SRE book's cases validate Ewerlöf's stage model, and Ewerlöf's stage model explains the SRE book's cases.

## Divergence Map

**Real tension (not contradiction):** The SRE book says "if you measure all four golden signals and page a human when one signal is problematic, your service will be at least decently covered by monitoring." Ewerlöf says Stage 1 SLIs (which include golden signals) have "poor signal quality" and "likely" produce alert fatigue. This is a direct tension about sufficiency.

The tension resolves as a conditional: golden signals are sufficient for simple request-response APIs with a single consumer class and no correctness requirements. They are insufficient for services with complex consumer tasks, correctness dimensions, or multiple consumer classes. The SRE book's claim is correct for the narrow case it addresses; Ewerlöf's critique is correct for the broader case that includes the GitHub correctness failure.

**Ewerlöf-only (absent from SRE book):**

- The GitHub data inconsistency case: data correctness failures are invisible to all four golden signals. No golden signal catches "service responds correctly but data is stale." This is a genuine gap in the SRE book's four-signal framework.
- The explicit Stage 1-to-Stage 4 maturity ladder with advancement criteria.
- The Stage 3 SLI formula (`good_task_executions / valid_task_executions`).
- The "not worth being on-call for" determination for Stage 1 and 2 SLIs.

**SRE book-only (absent from Ewerlöf):**

- The canonical definitions of each golden signal with their structural distinctions (error latency tracked separately, traffic as denominator not pager, saturation as leading indicator).
- The specific measurement guidance: percentile not mean, most-constrained resource for saturation, policy errors as an error type.
- The "rote page response" diagnostic: if response is always a scripted command, automate or fix root cause.

## A2 Sharpness Check

**SRE source A2 trigger:** Catches "we get paged all the time but most pages don't matter," "which metrics should we alert on," and "service looks fine but users complain." Does not catch the Stage 1 classification problem or the correctness failure gap.

**Ewerlöf source A2 trigger:** Catches "our SLI shows 99.9% but users complain," "we have availability and latency SLIs but they don't capture real user pain," "on-call pages are mostly noise," "we copied golden signals but they don't seem right." Does not provide the canonical golden signal definitions that practitioners need as a starting point.

**Merged A2 trigger:** "We implemented the four golden signals from the SRE book but on-call is still noisy — what's wrong?" This is the exact failure that falls in the gap between both source A2s. It requires the SRE book's signal definitions (to confirm the Stage 1 implementation is correct as far as it goes) plus Ewerlöf's stage model (to diagnose why it is insufficient without consumer task mapping). Neither source alone catches this compound question.

## Quote Accuracy Notes

All quotes verified in Phase 1.5 source verification:

- SRE "The four golden signals of monitoring are latency, traffic, errors, and saturation..." — VERIFIED verbatim in ch011.xhtml
- SRE "If you measure all four golden signals and page a human when one signal is problematic...your service will be at least decently covered by monitoring" — VERIFIED in ch011.xhtml
- Ewerlöf Stage 1/2/3/4 descriptions — VERIFIED in 20250827_123438_sli-evolution-stages.md with exact phrases: "rebrand," "consumer enters the scene," "failures are identified where usage meets task," "dissects each failure into Symptom, Consequence, and Business Impact"
- Ewerlöf "A good SLI is worth being on-call for..." — VERIFIED in 20250827_123438_sli-evolution-stages.md
- SRE Bigtable case — VERIFIED in ch011.xhtml
- SRE Gmail Workqueue case — VERIFIED in ch011.xhtml
- Ewerlöf GitHub 2018 case — real public incident; Ewerlöf's application plausibly verified as consistent with the stage model

## Synthesis-Specific Failure Mode Justification

"The SRE book compliance trap" applies specifically to the merged framing because the SRE book provides positive validation ("at least decently covered") while Ewerlöf provides the critique ("Stage 1, insufficient for on-call"). A practitioner who has read only the SRE book has positive validation for their golden-signal implementation and no prompt to continue to Stage 3. A practitioner who has read only Ewerlöf's model knows to advance to Stage 3 but does not have the canonical signal definitions as a starting point. The trap — stopping at Stage 1 because the SRE book validates it as "decent" — can only be identified as a trap by seeing both sources simultaneously and recognizing that "decent" in the SRE book means "minimum viable for the simple case" while Ewerlöf means "insufficient for on-call in the complex case." This failure mode cannot be warned against in either source alone.
