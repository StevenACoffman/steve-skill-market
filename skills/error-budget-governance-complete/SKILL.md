---
name: error-budget-governance-complete
allowed-tools: Bash, Read, Edit
id: error-budget-governance-complete
description: Use this skill when implementing error budget governance end-to-end — from establishing the conceptual mechanism through to a written, causally-attributed, tri-party-ratified policy with named escalation authority — particularly when the team is adopting error budget governance for the first time or when an existing governance system is failing due to buy-in collapse, disputed freezes, or unchecked overachievement.
type: merged-skill
source_skills:
  - slug: site-reliability-engineering/error-budget-conflict-resolution
    book: Site Reliability Engineering
    author: Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.)
  - slug: site-reliability-workbook/error-budget-policy-framework
    book: The Site Reliability Workbook
    author: Betsy Beyer et al. (Google)
related_skills:
  - slug: site-reliability-engineering/error-budget-conflict-resolution
    relation: supersedes
    note: This merged skill adds causal attribution, tri-party ratification, and specific thresholds that the source skill lacks
  - slug: site-reliability-workbook/error-budget-policy-framework
    relation: supersedes
    note: This merged skill adds the overachievement warning and the conceptual control-loop framing that the source skill lacks
tags: []
---

# Error Budget Governance (Complete Implementation)

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

SLO / error-budget docs:
!`find . \( -name '*slo*' -o -name '*error-budget*' -o -name '*errorbudget*' \) -not -path './.git/*' 2>/dev/null | head -10`

### R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 3):**

> In order to base these decisions on objective data, the two teams jointly define a quarterly error budget based on the service's service level objective, or SLO. The error budget provides a clear, objective metric that determines how unreliable the service is allowed to be within a single quarter. This metric removes the politics from negotiations between the SREs and the product developers when deciding how much risk to allow. When the budget is large, the product developers can take more risks. When the budget is nearly drained, the product developers themselves will push for more testing or slower push velocity, as they don't want to risk using up the budget and stall their launch. In effect, the product development team becomes self-policing.

**From the SRE Workbook (Google SRE Workbook, Chapter 2 and Appendix B):**

> In order to use this error budget, you need a policy outlining what to do when your service runs out of budget. Getting the error budget policy approved by all key stakeholders—the product manager, the development team, and the SREs—is a good test for whether the SLOs are fit for purpose... you need to start with a written policy.
>
> The team must work on reliability if: A code bug or procedural error caused the service itself to exceed the error budget. A postmortem reveals an opportunity to soften a hard dependency... The team may continue to work on non-reliability features if: The outage was caused by a company-wide networking problem. The outage was caused by a service maintained by another team, who have themselves frozen releases.

**Convergence note:** Both books establish that error budget governance requires pre-negotiated, shared, pre-written agreement — the SRE book at the conceptual level (the "self-policing" control loop mechanism), the Workbook at the operational level (the written policy, causal attribution rules, and ratification requirement). Both warn that budget without enforcement is paperwork. The SRE book contributes the mechanism and the overachievement warning (Chubby); the Workbook contributes the causal attribution distinction (team-caused vs. externally-caused exhaustion) and the tri-party ratification protocol, neither of which appears in the SRE book.

______________________________________________________________________

### I — Unified Framework (Interpretation)

Error budget governance is a single design problem with two failure layers — structural and operational — that must both be addressed for the governance to work.

**The mechanism (structural layer):** Budget = 1 - SLO. Both SRE and dev co-own this finite resource. The control loop has two directions:

- When budget is plentiful: SRE has no data-based argument to block releases. Shipping is the correct use of available budget.
- When budget is exhausted: dev has no data-based argument to override a freeze. The shared metric is the blocking condition — not SRE's opinion.

This removes negotiating-skill asymmetry from the features-vs-reliability conflict. The dev team becomes self-policing because they co-own and co-spend the budget.

Two preconditions must hold before the mechanism functions: (1) the SLO must be defined before any conflict arises — defining it under pressure produces a number that satisfies neither party; (2) SRE must have organizational authority to actually halt launches — without this, the budget is a metric with no teeth.

**The overachievement failure mode:** Chronically not consuming the budget is also a governance failure. When a service delivers well above its SLO, consumers build hard dependencies assuming the service will never fail. The Chubby case is the canonical proof. If the budget is never spent, schedule controlled degradation to bring observed availability within a realistic band of the committed SLO. This is not optional — it is part of governance.

**The policy (operational layer):** A policy is the pre-written, pre-approved decision tree that specifies exactly what engineering actions are mandatory when budget is exhausted or at risk. Its purpose is to eliminate post-incident negotiation — the decision was made before pressure existed.

Four mandatory policy components:

1. **Freeze trigger:** budget exhausted → halt all non-P0 releases and data changes until the service is back within SLO.
2. **Must-work-on-reliability conditions:** team's own code or process caused the exhaustion; postmortem reveals a hardenable dependency; miscategorized errors masked a real miss.
3. **May-continue-on-features conditions:** company-wide network failure; upstream team caused the outage and has themselves frozen; out-of-scope traffic (load testers, pen testers) consumed the budget.
4. **Escalation path:** a named authority who resolves disputes about budget calculation or policy application.

**The causal attribution distinction** is the most commonly missed element: if a team's own code caused budget exhaustion, they must work on reliability. If an external dependency caused it, they may continue. Without this distinction, every freeze feels punitive for failures the team could not control — which destroys buy-in within one or two cycles. Teams that implement error budgets without causal attribution universally encounter this: the policy fails on the first externally-caused incident.

**Ratification:** All three parties — product manager, dev lead, SRE lead — must explicitly sign the policy before any incident. Retroactive agreement fails: parties negotiate under duress with asymmetric information, and the resulting agreement is unstable. A diagnostic signal: if any party refuses to ratify, treat the refusal as evidence the SLO needs revision, not the policy.

**Quantitative thresholds:** A single incident consuming more than 20% of the four-week budget triggers a mandatory postmortem with at least one P0 action item. A class of outage recurring at 20%+ per quarter must appear in quarterly planning.

______________________________________________________________________

### A1 — Past Application

## R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 3):**

> In order to base these decisions on objective data, the two teams jointly define a quarterly error budget based on the service's service level objective, or SLO. The error budget provides a clear, objective metric that determines how unreliable the service is allowed to be within a single quarter. This metric removes the politics from negotiations between the SREs and the product developers when deciding how much risk to allow. When the budget is large, the product developers can take more risks. When the budget is nearly drained, the product developers themselves will push for more testing or slower push velocity, as they don't want to risk using up the budget and stall their launch. In effect, the product development team becomes self-policing.

**From the SRE Workbook (Google SRE Workbook, Chapter 2 and Appendix B):**

> In order to use this error budget, you need a policy outlining what to do when your service runs out of budget. Getting the error budget policy approved by all key stakeholders—the product manager, the development team, and the SREs—is a good test for whether the SLOs are fit for purpose... you need to start with a written policy.
>
> The team must work on reliability if: A code bug or procedural error caused the service itself to exceed the error budget. A postmortem reveals an opportunity to soften a hard dependency... The team may continue to work on non-reliability features if: The outage was caused by a company-wide networking problem. The outage was caused by a service maintained by another team, who have themselves frozen releases.

**Convergence note:** Both books establish that error budget governance requires pre-negotiated, shared, pre-written agreement — the SRE book at the conceptual level (the "self-policing" control loop mechanism), the Workbook at the operational level (the written policy, causal attribution rules, and ratification requirement). Both warn that budget without enforcement is paperwork. The SRE book contributes the mechanism and the overachievement warning (Chubby); the Workbook contributes the causal attribution distinction (team-caused vs. externally-caused exhaustion) and the tri-party ratification protocol, neither of which appears in the SRE book.

______________________________________________________________________

## I — Unified Framework (Interpretation)

Error budget governance is a single design problem with two failure layers — structural and operational — that must both be addressed for the governance to work.

**The mechanism (structural layer):** Budget = 1 - SLO. Both SRE and dev co-own this finite resource. The control loop has two directions:

- When budget is plentiful: SRE has no data-based argument to block releases. Shipping is the correct use of available budget.
- When budget is exhausted: dev has no data-based argument to override a freeze. The shared metric is the blocking condition — not SRE's opinion.

This removes negotiating-skill asymmetry from the features-vs-reliability conflict. The dev team becomes self-policing because they co-own and co-spend the budget.

Two preconditions must hold before the mechanism functions: (1) the SLO must be defined before any conflict arises — defining it under pressure produces a number that satisfies neither party; (2) SRE must have organizational authority to actually halt launches — without this, the budget is a metric with no teeth.

**The overachievement failure mode:** Chronically not consuming the budget is also a governance failure. When a service delivers well above its SLO, consumers build hard dependencies assuming the service will never fail. The Chubby case is the canonical proof. If the budget is never spent, schedule controlled degradation to bring observed availability within a realistic band of the committed SLO. This is not optional — it is part of governance.

**The policy (operational layer):** A policy is the pre-written, pre-approved decision tree that specifies exactly what engineering actions are mandatory when budget is exhausted or at risk. Its purpose is to eliminate post-incident negotiation — the decision was made before pressure existed.

Four mandatory policy components:

1. **Freeze trigger:** budget exhausted → halt all non-P0 releases and data changes until the service is back within SLO.
2. **Must-work-on-reliability conditions:** team's own code or process caused the exhaustion; postmortem reveals a hardenable dependency; miscategorized errors masked a real miss.
3. **May-continue-on-features conditions:** company-wide network failure; upstream team caused the outage and has themselves frozen; out-of-scope traffic (load testers, pen testers) consumed the budget.
4. **Escalation path:** a named authority who resolves disputes about budget calculation or policy application.

**The causal attribution distinction** is the most commonly missed element: if a team's own code caused budget exhaustion, they must work on reliability. If an external dependency caused it, they may continue. Without this distinction, every freeze feels punitive for failures the team could not control — which destroys buy-in within one or two cycles. Teams that implement error budgets without causal attribution universally encounter this: the policy fails on the first externally-caused incident.

**Ratification:** All three parties — product manager, dev lead, SRE lead — must explicitly sign the policy before any incident. Retroactive agreement fails: parties negotiate under duress with asymmetric information, and the resulting agreement is unstable. A diagnostic signal: if any party refuses to ratify, treat the refusal as evidence the SLO needs revision, not the policy.

**Quantitative thresholds:** A single incident consuming more than 20% of the four-week budget triggers a mandatory postmortem with at least one P0 action item. A class of outage recurring at 20%+ per quarter must appear in quarterly planning.

______________________________________________________________________

## A1 — Past Application

### Case A: YouTube SLO Calibration at Acquisition — Budget as Explicit Trade-off (SRE Book, Chapter 3)

- **Problem:** When Google acquired YouTube, the availability target had to be set. Defaulting to Google's highest reliability targets would have imposed a cost structure mismatched to YouTube's growth-phase velocity needs.
- **Methodology:** Google deliberately set a lower availability target for YouTube than for enterprise products. The lower SLO created a larger error budget, explicitly permitting higher release velocity. The decision was framed as a product choice: "We are choosing to accept X% downtime risk in exchange for Y feature velocity."
- **Conclusion:** The error budget framing made the trade-off explicit and legible. Neither team needed to argue about "too conservative" or "too risky" — the arithmetic governed.
- **Result:** YouTube's rapid feature development phase was protected without internal conflict about the lower availability target.

### Case B: Evernote Error Budget Adoption — Policy Structure Makes Governance Stick (Workbook, Chapter 3)

- **Problem:** Evernote introduced SLOs but developers initially resisted the error budget culture. When SLOs were missed, the features-vs-reliability debate was relitigated from scratch each time. The SLO existed as a measurement but produced no consistent action.
- **Methodology:** Working with Google's CRE team, Evernote moved from informal SLO discussions to a structured policy with escalation triggers and shared language. The SLO became the governance instrument, not a vanity metric. The policy iterated from v1 to v3 in nine months as causal attribution rules were refined.
- **Conclusion:** The iterative policy maturation was only possible because the policy was pre-written and treated as a living governance document rather than a one-time negotiation.
- **Result:** Data-driven conversations about outage impact replaced subjective debates. Both teams viewed reliability as a shared, measurable responsibility rather than an SRE opinion to be overridden.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Instead of error-budget-conflict-resolution or error-budget-policy-framework, use this when:** a team has or is adopting error budgets and needs the full governance implementation — not just the conceptual mechanism (SRE book) and not just the policy template (Workbook), but both, because governance failures arise from any of four causes: no enforcement authority, causal attribution failure destroying buy-in, overachievement creating hidden dependencies, or single-party policy without ratification.

**Scenario 1:** A team has SLOs and tracks error budget consumption, but the budget governance is failing: the dev team resists freezes on the grounds that "the CDN outage wasn't our fault." The freeze policy exists but treats all budget exhaustion identically. This is causal attribution failure — the Workbook's primary contribution. Applying only the SRE book framework will not resolve it.

**Scenario 2:** A service team has operated well above its SLO (delivering 99.99% against a 99.9% commitment) for eight months. Downstream consumers have removed circuit breakers. A planned maintenance window is approaching. The error budget governance does not address overachievement. Applying only the Workbook framework will not resolve it.

**Scenario 3:** An engineering manager wants to implement error budget governance. The SRE team is drafting a policy. Product management has not been involved. The SRE team plans to present the policy to the product manager after it is complete. This is the single-party policy failure mode — the Workbook warns this produces an unstable agreement and predicts the policy will fail on the first freeze attempt.

**Language signals:**

- "We need to ship but SRE keeps blocking us"
- "The CDN outage wasn't our fault — why are we frozen?"
- "We have an error budget policy but nobody follows it"
- "We've been reliable for months — why can't we launch?"
- "The SRE team wrote an error budget policy and now wants us to sign it"

______________________________________________________________________

## E — Execution Steps

1. **Define the SLO jointly before any conflict arises.** Product management and SRE agree on a quarterly SLO target, documented in a shared location. Management explicitly signs off on the enforcement policy (budget exhausted = releases halted) before the policy is drafted. If this step is skipped, all subsequent steps are at risk — the policy has no organizational legitimacy.

2. **Instrument neutral measurement.** An automated, non-partisan monitoring system measures actual error rate and computes remaining budget in real time. Neither SRE nor dev controls the measurement. Both teams see the same budget dashboard. Publish budget consumption weekly, not only when it becomes critical.

3. **Draft the four-component policy.** Write: (a) the freeze trigger; (b) must-work-on-reliability conditions including the causal attribution list; (c) may-continue-on-features conditions including the same causal attribution criteria; (d) the named escalation authority for disputed calculations. The non-goal statement is as important as the policy itself: the freeze is permission to focus on reliability, not punishment.

4. **Add quantitative thresholds.** Single incident consuming >20% of four-week budget → mandatory postmortem with at least one P0 action item. Single class of outage consuming >20% per quarter → mandatory quarterly planning inclusion.

5. **Obtain tri-party ratification.** Product manager, dev lead, and SRE lead all sign explicitly before any incident. Document names, dates, and next review date. If any party refuses: treat the refusal as a diagnostic signal that the SLO needs revision. Do not proceed with the policy until all three parties sign.

6. **Respond to budget exhaustion with the safety valve.** When budget is exhausted, the release halt is automatic and documented — not a case-by-case negotiation. Apply the causal attribution test before any other action: team-caused → reliability freeze; externally-caused → postmortem mandatory, release possible. Track the reliability investment as a concrete project with completion criteria.

7. **Address overachievement actively.** If the service consistently operates well above its SLO, schedule controlled degradation (planned outages or throttling) to prevent consumers from treating the service as infinitely reliable. This step is not optional — chronically unconsumed budget is a governance failure mode.

______________________________________________________________________

## B — Boundary ★

### Failure Patterns from the SRE Book

- Defining the SLO and tracking the budget without management mandate to enforce the freeze. Dev teams rationally ignore a constraint with no consequence.
- Setting the SLO at 100%, making the error budget zero and every incident a policy violation.
- Overachieving the SLO chronically without addressing the hidden dependency problem (Chubby pattern) — over-reliability is a governance failure, not a success.

### Failure Patterns from the SRE Workbook

- Retroactive policy drafting: writing the policy after an incident, with parties negotiating under duress with asymmetric information. The resulting agreement is unstable.
- Missing causal attribution: treating all budget exhaustion identically feels punitive for external-caused incidents and destroys developer buy-in within one or two cycles.
- Single-party policy: SRE writes the policy alone and presents it to product as a fait accompli. The product manager's agreement is a requirement, not a courtesy.
- No escalation path: disputed budget calculations stall indefinitely with no resolution authority.

### Synthesis-Specific Failure Mode

**The governance-by-half failure:** A team successfully implements the SRE book's conceptual framework (joint SLO, shared budget, management authority to freeze) but omits the Workbook's causal attribution rules because the SRE book does not mention them. The governance works correctly for team-caused incidents but collapses on the first externally-caused budget exhaustion: the team is frozen despite not being responsible, buy-in evaporates, and product management begins treating the freeze as SRE's power play rather than a shared governance mechanism. This failure is invisible from within the SRE book framework alone — the book's framework appears correctly implemented. Only the merged view makes the missing causal attribution visible as a structural gap that will predictably cause the governance to fail.

### Do Not Use When

- No SLO exists. An error budget cannot be calculated without a target. Define the SLO first.
- The organization lacks authority to enforce a release freeze. A policy without enforcement is theater; address organizational structure first.
- An incident is in progress. This is a pre-incident governance tool, not an in-incident response tool.

______________________________________________________________________

## Related Skills

- **supersedes**: site-reliability-engineering/error-budget-conflict-resolution — use this merged skill when implementing governance for the first time or diagnosing governance failures; use the source skill when only the conceptual mechanism needs to be introduced
- **supersedes**: site-reliability-workbook/error-budget-policy-framework — use this merged skill when the overachievement warning and full control-loop framing are also in scope; use the source skill when only the written policy template is needed
- **depends-on**: slo-definition-calibration-framework — the SLO produced by the definition framework is the mandatory input to budget calculation; no budget can exist without a defined, calibrated target
- **composes-with**: site-reliability-engineering/fifty-percent-engineering-time-cap — both are cross-team governance feedback loops: error budget governs release velocity, the cap governs SRE internal time allocation
