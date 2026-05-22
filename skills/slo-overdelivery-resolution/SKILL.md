---
name: slo-overdelivery-resolution
allowed-tools: Bash, Read, Edit
id: slo-overdelivery-resolution
description: Use this skill when a service is chronically delivering significantly above its stated SLO and the team must decide whether to raise the SLO to match actual capability or introduce synthetic outages to bring observed availability down to the committed level — a decision fork that neither source skill answers alone.
type: merged-skill
source_skills:
  - slug: site-reliability-engineering/dont-overachieve-slo-chubby-principle
    book: Site Reliability Engineering
    author: Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.)
  - slug: reliability-engineering-mindset/lagom-slo
    book: Reliability Engineering Mindset
    author: Alex Ewerlöf
related_skills:
  - slug: site-reliability-engineering/dont-overachieve-slo-chubby-principle
    relation: supersedes
    note: This merged skill adds the raise-the-SLO alternative and the decision criterion for choosing between the two remedies
  - slug: reliability-engineering-mindset/lagom-slo
    relation: supersedes
    note: This merged skill adds the operational execution mechanics for synthetic outages when raising the SLO is not feasible
tags: []
---

# SLO Overdelivery Resolution

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

SLO definition files:
!`find . \( -name '*slo*' -o -name '*objective*' \) -not -path './.git/*' 2>/dev/null | head -10`

### R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 4):**

> The Chubby service was consistently achieving much higher availability than its stated SLO, which caused other teams to design systems that depended on that higher availability. To address this, the team began deliberately taking Chubby down for scheduled maintenance, which trained users to build systems that could tolerate interruptions and brought the observed availability in line with the stated SLO.
>
> Users build on the reality of what you offer, rather than what you say you'll supply, particularly for infrastructure services. If your service's actual performance is much better than its stated SLO, users will come to rely on its current performance. You can avoid over-dependence by deliberately taking the system offline occasionally, throttling some requests, or designing the system so that it isn't faster under light loads.

**From Ewerlöf (Reliability Engineering Mindset, lagom-slo):**

> A lagom SLO is not too high or too low. It's just right for the service consumers!
>
> An SLO should define the lowest level of reliability that you **can get away with** for each service. — Jay Judkowitz and Mark Carter (Google PMs)
>
> Change is the number one enemy of reliability. It is tempting to aim for the highest SLO. But it reduces the error budget which in turn slows down the pace of development. Besides, higher reliability has a higher cost. The point is not to be perfect, but good enough.

**Convergence note:** Both sources independently cite the Google Chubby planned outage as the canonical proof that over-delivery creates systemic consumer over-dependency — this is the strongest cross-book convergence in the SRE cluster, with the same concrete case confirming the same principle from different authorship traditions. The SRE book focuses entirely on the synthetic outage remedy. Ewerlöf adds the alternative remedy (raise the SLO if the lower SLO was incorrectly set), plus the too-low failure mode that the SRE book does not address.

______________________________________________________________________

### I — Unified Framework (Interpretation)

When a service consistently delivers significantly above its stated SLO, two alternative remedies exist. Choosing the wrong one is costly. The correct choice depends on a single diagnostic question: was the current SLO correctly calibrated to consumer tolerance, or was it set from historical data, aspiration, or organizational inertia?

**Why overdelivery is a problem regardless of remedy:**

The mechanism is behavioral. Consumers — especially engineering teams building on infrastructure services — calibrate their defensive engineering to what they observe, not to what is contractually committed. A service that has never experienced a real outage will have consumers who have not built circuit breakers, retry logic, fallback paths, or graceful degradation. This is rational optimization from the consumer's perspective. When the inevitable maintenance window, hardware failure, or dependency outage arrives, cascading failures propagate across every consumer that removed their defensive engineering.

**The two remedies and when each applies:**

*Remedy A: Raise the SLO to match actual capability.* This is the correct remedy when the lower SLO was incorrectly calibrated — set from historical data without consumer input, or set aspirationally ("let's be conservative") without reasoning about what consumers actually need. Ewerlöf's lagom principle identifies this: if consumers cannot tolerate the current SLO, and the service is already delivering far above it, the SLO was simply set too low. Raising it closes the gap between commitment and delivery, converts the overdelivery from a risk into an honest commitment, and eliminates the consumer complacency problem by making the higher level the explicit target.

*Remedy B: Introduce synthetic outages to bring observed availability down to the committed SLO level.* This is the correct remedy when the SLO is correctly calibrated to consumer tolerance — the team set the SLO at the right level but actual delivery has drifted substantially above it. The synthetic outage policy: in any period where organic failures have not consumed sufficient error budget, schedule controlled maintenance windows to bring observed availability within a narrow band of the SLO. The windows must be short (5–30 minutes), communicated well in advance, and used as a forcing function for consumer defensive engineering.

**The decision criterion:**

```text
IF the SLO was set without consumer tolerance input (from historical data, 
    aspiration, or copying another team's target):
    → Fix the calibration first (use lagom process: ask consumer tolerance question)
    → If raised SLO matches actual delivery: no further action needed
    → If raised SLO is still below actual delivery: apply Remedy B

IF the SLO was correctly calibrated to consumer tolerance:
    → Apply Remedy B directly: introduce synthetic outages

IF the SLO cannot be raised (contractual SLA already committed below the 
    current SLO, with financial consequences):
    → Remedy A is constrained; apply Remedy B within the SLO-to-SLA buffer
    → Synthetic outages must stay above the SLA commitment level
```

**Shared principle underlying both remedies:** The goal is honesty — the observed availability should reflect what the service commits to, in both directions. An SLO too high is dishonest to consumers who depend on it. An SLO too low is dishonest to consumers who deserve to know what the service can actually deliver. Both the SRE book and Ewerlöf converge on this principle from different angles.

______________________________________________________________________

### A1 — Past Application

## R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 4):**

> The Chubby service was consistently achieving much higher availability than its stated SLO, which caused other teams to design systems that depended on that higher availability. To address this, the team began deliberately taking Chubby down for scheduled maintenance, which trained users to build systems that could tolerate interruptions and brought the observed availability in line with the stated SLO.
>
> Users build on the reality of what you offer, rather than what you say you'll supply, particularly for infrastructure services. If your service's actual performance is much better than its stated SLO, users will come to rely on its current performance. You can avoid over-dependence by deliberately taking the system offline occasionally, throttling some requests, or designing the system so that it isn't faster under light loads.

**From Ewerlöf (Reliability Engineering Mindset, lagom-slo):**

> A lagom SLO is not too high or too low. It's just right for the service consumers!
>
> An SLO should define the lowest level of reliability that you **can get away with** for each service. — Jay Judkowitz and Mark Carter (Google PMs)
>
> Change is the number one enemy of reliability. It is tempting to aim for the highest SLO. But it reduces the error budget which in turn slows down the pace of development. Besides, higher reliability has a higher cost. The point is not to be perfect, but good enough.

**Convergence note:** Both sources independently cite the Google Chubby planned outage as the canonical proof that over-delivery creates systemic consumer over-dependency — this is the strongest cross-book convergence in the SRE cluster, with the same concrete case confirming the same principle from different authorship traditions. The SRE book focuses entirely on the synthetic outage remedy. Ewerlöf adds the alternative remedy (raise the SLO if the lower SLO was incorrectly set), plus the too-low failure mode that the SRE book does not address.

______________________________________________________________________

## I — Unified Framework (Interpretation)

When a service consistently delivers significantly above its stated SLO, two alternative remedies exist. Choosing the wrong one is costly. The correct choice depends on a single diagnostic question: was the current SLO correctly calibrated to consumer tolerance, or was it set from historical data, aspiration, or organizational inertia?

**Why overdelivery is a problem regardless of remedy:**

The mechanism is behavioral. Consumers — especially engineering teams building on infrastructure services — calibrate their defensive engineering to what they observe, not to what is contractually committed. A service that has never experienced a real outage will have consumers who have not built circuit breakers, retry logic, fallback paths, or graceful degradation. This is rational optimization from the consumer's perspective. When the inevitable maintenance window, hardware failure, or dependency outage arrives, cascading failures propagate across every consumer that removed their defensive engineering.

**The two remedies and when each applies:**

*Remedy A: Raise the SLO to match actual capability.* This is the correct remedy when the lower SLO was incorrectly calibrated — set from historical data without consumer input, or set aspirationally ("let's be conservative") without reasoning about what consumers actually need. Ewerlöf's lagom principle identifies this: if consumers cannot tolerate the current SLO, and the service is already delivering far above it, the SLO was simply set too low. Raising it closes the gap between commitment and delivery, converts the overdelivery from a risk into an honest commitment, and eliminates the consumer complacency problem by making the higher level the explicit target.

*Remedy B: Introduce synthetic outages to bring observed availability down to the committed SLO level.* This is the correct remedy when the SLO is correctly calibrated to consumer tolerance — the team set the SLO at the right level but actual delivery has drifted substantially above it. The synthetic outage policy: in any period where organic failures have not consumed sufficient error budget, schedule controlled maintenance windows to bring observed availability within a narrow band of the SLO. The windows must be short (5–30 minutes), communicated well in advance, and used as a forcing function for consumer defensive engineering.

**The decision criterion:**

```text
IF the SLO was set without consumer tolerance input (from historical data, 
    aspiration, or copying another team's target):
    → Fix the calibration first (use lagom process: ask consumer tolerance question)
    → If raised SLO matches actual delivery: no further action needed
    → If raised SLO is still below actual delivery: apply Remedy B

IF the SLO was correctly calibrated to consumer tolerance:
    → Apply Remedy B directly: introduce synthetic outages

IF the SLO cannot be raised (contractual SLA already committed below the 
    current SLO, with financial consequences):
    → Remedy A is constrained; apply Remedy B within the SLO-to-SLA buffer
    → Synthetic outages must stay above the SLA commitment level
```

**Shared principle underlying both remedies:** The goal is honesty — the observed availability should reflect what the service commits to, in both directions. An SLO too high is dishonest to consumers who depend on it. An SLO too low is dishonest to consumers who deserve to know what the service can actually deliver. Both the SRE book and Ewerlöf converge on this principle from different angles.

______________________________________________________________________

## A1 — Past Application

### Case A: Google Chubby — Synthetic Outages Resolve Accumulated Over-Dependency (SRE Book, Chapter 4)

- **Problem:** Google's global Chubby lock service had such high actual availability that service teams began building dependencies assuming Chubby would never be unavailable. When Chubby experienced true global outages, cascading failures were disproportionately severe — services that should have had fallback modes had none. The SLO was correctly set; delivery had drifted chronically above it.
- **Methodology (Remedy B):** The SRE team identified that actual availability substantially exceeded the stated SLO. They introduced a policy: in any quarter where true failures had not consumed sufficient error budget, a controlled outage would be synthesized intentionally to bring observed availability to the SLO threshold. Each outage was communicated in advance, used to flush out unreasonable dependencies, and required consumer remediation.
- **Conclusion:** Planned outages "flushed out unreasonable dependencies on Chubby shortly after they were added," forcing service owners to reckon with distributed systems realities while the stakes were low.
- **Result:** Consumers were retrained to build properly defensive clients. The impact of subsequent unplanned outages was substantially reduced.

### Case B: Media Company Streaming — Correctly Raising an Aspirational SLO (Ewerlöf, Lagom-Slo)

- **Problem:** A streaming service had been delivering 99.99% availability against a 99.9% SLO commitment. The engineering team was considering synthetic outages. On investigation, the 99.9% SLO was set because it was "conservative" — not because any consumer research showed consumers would tolerate that level of unavailability. Consumer tolerance research revealed that users expected and required close to the 99.99% level they had been receiving.
- **Methodology (Remedy A):** The lagom calibration reframed the question: rather than introducing artificial degradation, the SLO was raised to 99.99% to match actual capability and actual consumer expectation. The 10x/9 cost analysis confirmed the service was already provisioned to sustain this level.
- **Conclusion:** The original 99.9% SLO was incorrectly set by aspiration rather than consumer tolerance. Raising it was the correct remedy; applying synthetic outages would have been unnecessary degradation of a service correctly delivering what consumers needed.
- **Result:** The SLO aligned with consumer expectation and actual delivery, eliminating the overdelivery gap without any artificial degradation.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Instead of dont-overachieve-slo-chubby-principle or lagom-slo, use this when:** a service has a sustained gap between actual availability and its SLO commitment and the team needs to choose between raising the SLO and introducing synthetic outages — a decision that requires both calibration reasoning (lagom) and operational execution mechanics (dont-overachieve).

**Scenario 1:** An infrastructure team reports their service has been at 99.99% availability for 18 months against a 99.9% SLO. Downstream teams appear to have removed circuit breakers. The team's first instinct is to schedule synthetic outages. The correct first question: was the 99.9% SLO calibrated from consumer tolerance research, or was it "conservative"? The answer determines which remedy applies.

**Scenario 2:** A platform team is operating at 99.95% against a 99.5% SLO. The SLO was originally set conservatively because the service was new. Consumer teams have adapted to the higher availability and are now building integrations that assume it. The team needs to decide: raise to 99.95% (matching actual capability), or introduce degradation to bring delivery closer to the original 99.5% commitment.

**Scenario 3:** A team has correctly calibrated their SLO at 99.9% from consumer research. Their actual delivery is 99.99%. They have confirmed that consumers have stopped building fallback logic. Remedy A (raise SLO) is not appropriate — the 99.9% was correctly calibrated. Apply Remedy B: systematic synthetic outage policy.

**Language signals:**

- "We've never had downtime in 18 months"
- "Our actual availability is much better than our SLO"
- "Consumers don't seem to be implementing circuit breakers"
- "Should we raise our SLO or introduce planned downtime?"
- "We're planning our first maintenance window and worried about cascading failures"

______________________________________________________________________

## E — Execution Steps

1. **Measure the gap.** Calculate actual availability over the past 3–6 months versus the stated SLO. If actual availability is more than 10× better than the SLO allows (e.g., 99.99% actual vs. 99.9% SLO), the skill applies.

2. **Diagnose the SLO calibration.** Was the current SLO set by: (a) direct consumer tolerance research, or (b) historical data, aspiration, organizational convention, or copying another team's target? If the answer is (b), apply the lagom calibration process before proceeding: ask consumers "what is the worst reliability level you could live with?" and compare to actual delivery.

3. **Choose the remedy based on calibration diagnosis.**

   - If the SLO was incorrectly set (answer b above) AND consumer tolerance matches or exceeds actual delivery: raise the SLO. Document the consumer research that supports the new target.
   - If the SLO is correctly calibrated to consumer tolerance AND actual delivery substantially exceeds it: proceed to Remedy B (synthetic outages).
   - If SLA commitments constrain raising the SLO: Remedy A is limited to the gap between SLO and SLA; apply Remedy B within that band.

4. **If applying Remedy B — establish a synthetic outage policy.** In any period where organic failures have not brought actual availability within the SLO band, schedule a controlled maintenance window. The window must be: (a) short (5–30 minutes), (b) communicated to all downstream consumers weeks in advance, (c) preceded by a requirement that consumers validate graceful degradation in staging.

5. **Notify and require consumer remediation.** Before each planned window, require downstream teams to demonstrate their service handles the planned outage gracefully. Use the window as a forcing function. After the first window, assess which consumers experienced cascading failures — those consumers must implement defensive patterns before the next window.

6. **Repeat on cadence.** Continue the planned outage policy on a regular schedule (quarterly, or as needed to maintain observed availability within the SLO band). This is an ongoing management practice, not a one-time fix.

______________________________________________________________________

## B — Boundary ★

### Failure Patterns from the SRE Book (Dont-Overachieve)

- Interpreting the principle as permission to be unreliable: synthetic outages must be scheduled, communicated in advance, and modest in frequency. This is not a license for arbitrary downtime.
- Applying synthetic outages without consumer notification: unannounced synthetic outages produce the same cascading failures the principle is designed to prevent, without the retraining benefit.
- Failing to require consumer remediation after the first synthetic outage: outages continue causing cascades indefinitely if consumers are not required to implement defensive patterns.

### Failure Patterns from Ewerlöf (Lagom-Slo)

- Demanding five-nines without cost modeling: aspirational SLO set above actual and sustainable capability; the team chases a target that exhausts error budget and blocks feature velocity.
- SLO too high — consumer complacency: consumers build tightly coupled systems assuming infinite availability; the same Chubby mechanism, but triggered by incorrect SLO-setting rather than over-delivery.
- SLO too low — outsourcing cost to consumers: N consumer teams each pay mitigation costs independently; total organizational cost exceeds the cost of improving the SLO.
- Premature SLO from historical data: SLO set without consumer input; often creates the calibration error that leads teams to apply Remedy B when Remedy A was correct.

### Synthesis-Specific Failure Mode

**Applying Remedy B to a miscalibrated SLO:** A team whose SLO was set from historical data (not consumer research) detects the overdelivery gap and immediately applies synthetic outages — the remedy the SRE book prescribes. But the correct first step was to determine whether the lower SLO was correctly calibrated. If it was not, synthetic outages are unnecessary degradation of a service that should simply raise its SLO to match actual capability and consumer expectation. This failure is invisible from within the dont-overachieve skill alone: the skill correctly identifies the gap and the remedy, but does not ask whether the SLO itself was correctly set. The merged framing makes the calibration diagnostic question the mandatory first step, preventing unnecessary degradation when Remedy A was always available.

### Do Not Use When

- The service is already at or below its SLO. This skill applies only to chronic over-delivery.
- The over-delivery is recent (less than one quarter). Hidden consumer dependencies require time to accumulate; a short period of exceptional reliability does not create the same structural risk.
- The service has no downstream consumers who could accumulate hidden dependencies (e.g., pure internal tooling with a single, well-tested consumer).

______________________________________________________________________

## Related Skills

- **supersedes**: site-reliability-engineering/dont-overachieve-slo-chubby-principle — use this merged skill when the calibration question (was the SLO correctly set?) must be answered before choosing a remedy; use the source skill when the SLO is known to be correctly calibrated and only the synthetic outage mechanics are needed
- **supersedes**: reliability-engineering-mindset/lagom-slo — use this merged skill when over-delivery has already been detected and operational resolution is needed; use the source skill when calibrating the SLO target from scratch without an existing overdelivery situation
- **depends-on**: slo-definition-calibration-framework — the SLO must be defined and the calibration must be understood before the overdelivery gap can be correctly diagnosed
- **composes-with**: site-reliability-engineering/error-budget-governance-complete — synthetic outages deliberately consume error budget; the error budget governance policy must account for intentional budget consumption
