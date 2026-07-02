---
name: 10x9-cost-reliability
description: |
  Use this skill when a conversation involves setting, challenging, or justifying an SLO target and the cost of achieving it has not been made explicit. The canonical trigger is a leader or stakeholder demanding a high-nines SLO ("we need five-nines") without having modeled what that actually costs. The skill translates the abstract SLO number into an economic argument: each additional "9" makes the system 10x more reliable but costs roughly 10x more to deliver.

  WHEN TO CALL:
  - Someone proposes a specific SLO level (e.g., "99.999%") without a cost justification.
  - A team is debating whether to upgrade from 3-nines to 4-nines and needs a framework to evaluate that decision.
  - Leadership is treating high reliability as a prestige signal rather than a cost/benefit question.
  - An engineer needs to push back on an unrealistic SLO mandate from above.
  - A cost-of-reliability conversation needs a quantitative anchor.
tags: [slo, cost-of-reliability, 10x9, error-budget, reliability-economics]
---

# 10X/9 Cost-of-Reliability Reasoning

## R — Original Text (Reading)

> For every 9 you add to SLO, you're making the system 10x more reliable but also 10x more expensive. I call it the **10x/9** (read ten exes per nine). The first time I heard it, I was suspicious, but when looking at the math and reflecting on my experience, it surprisingly holds up.
>
> Not only is being perfect all the time impossible, but trying to be so becomes incredibly expensive very quickly. The resources needed to edge ever closer to 100% reliability grow with a curve that is steeper than linear. Since achieving 100% perfection is impossible, you can spend infinite resources and never get there.
>
> In practice, however, there are some hurdles. The biggest one is that senior leaders often think they should be driving their teams toward perfection (100% customer satisfaction, zero downtime, and so forth). In my experience, this is the biggest mental hill to get senior management over.
>
> — Alex Ewerlöf, 20231201_053017_10x9.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The 10x/9 rule is a rule of thumb for translating SLO levels into economic intuition. Each "nine" appended to an SLO (99% → 99.9% → 99.99%) makes the error budget 10x smaller and the system 10x more reliable by the uptime metric. The cost side mirrors this: to deliver that 10x reliability improvement, you must make roughly 10x more investment across a range of dimensions — refactoring, architecture redundancy, on-call infrastructure, automation, tooling, migration, and team bandwidth.

The cost is not linear because the easy wins (adding a second server, enabling retry logic) come first. Each subsequent order of magnitude requires progressively more sophisticated interventions: geographic redundancy, automatic failover, automated error recovery, 5–8 person on-call rotations with extra compensation, and ultimately removing humans from the incident response loop entirely. At five-nines, only 26 seconds of downtime per month is permitted — faster than any human can even be paged.

This framework reframes SLO debates from technical to economic. The question is not "how reliable can we be?" but "what does the consumer need and what is it worth to them?" If the answer to the second question does not justify the cost implied by the SLO, the target is wrong. The 10x/9 rule gives engineers a concrete bridge from the abstract percentage on a dashboard to a real conversation with finance and leadership about investment priority.

It also establishes a ceiling argument: beyond a certain point, the marginal cost of reliability exceeds the marginal revenue value of that reliability. That ceiling is the lagom SLO (see related skill).

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Media Company CTO Demands Five-Nines (C01)

- **Problem:** The CTO of a direct-to-consumer media company (similar in function to Netflix) mandated a 5-nines SLO (99.999%) for the streaming platform. The author had just joined as an SRE to address the company's reliability problems.
- **Application:** The author applied the 10x/9 reasoning: 5-nines allows only 26 seconds of downtime per month, a threshold that makes human-in-the-loop incident response structurally impossible. The company's engineering organization was a fraction of Netflix's size, yet it was expected to meet a Netflix-equivalent reliability standard. The cost — in people, architecture, automation, and on-call infrastructure — was not factored into the mandate.
- **Conclusion:** The demand was driven by prestige and aspirational framing rather than consumer tolerance analysis or cost modeling. The 10x/9 rule made this visible.
- **Result:** The author used this reasoning to negotiate down the CTO's expectations, translating the abstract "five-nines" into a concrete cost and operational constraint argument that leadership could evaluate economically.

### Case 2: Premium E-Commerce Fallback Vs. Adding a Nine (C15)

- **Problem:** A company selling high-value products online had sub-98% platform availability but could not justify the cost of adding another nine to reach 99%.
- **Application:** Rather than investing in a higher SLO directly, the company used a manual phone-call fallback for failed orders — a business-process approach that achieved near-100% order completion at a much lower cost than architectural improvement.
- **Conclusion:** For low-volume, high-value transactions, an operational fallback can be more cost-effective than buying an additional nine through architectural investment.
- **Result:** Near-100% effective order completion was achieved at the cost of manual intervention per failure, demonstrating that the 10x/9 rule does not mandate infrastructure investment — it clarifies when cheaper alternatives are more rational.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An engineering manager arrives at a planning meeting and says "our target should be 99.99% — that's what our competitors have," and the team needs to respond with a cost framing rather than a purely technical one.
2. A startup is building its first reliability program and leadership wants to commit to a high SLO to win enterprise customers, without modeling whether the engineering team can sustain it.
3. An SRE team is asked to justify budget for redundancy infrastructure, and the 10x/9 rule provides the economic logic for why the current 99% SLO is costing the company less than 99.9% would.

### Language Signals (Activate When These Appear)

- "We need to be five-nines" / "We should aim for four-nines"
- "Our reliability isn't good enough — we need to improve it"
- "Why does it cost so much to be more reliable?"
- "Can we just add redundancy and get to 99.99%?"
- "The SLO should match [competitor / Google / AWS]"

### Distinguishing from Adjacent Skills

- Difference from `slo-definition-calibration-framework`: `10x9-cost-reliability` provides the economic argument for why SLOs cannot be set arbitrarily high; `slo-definition-calibration-framework` provides the full calibration methodology for finding the right level, including the too-low case and the consumer negotiation process.
- Difference from `wardley-pace-slo`: `wardley-pace-slo` gives strategic guidance on what SLO level is appropriate given a system's evolutionary stage; `10x9-cost-reliability` is the cost-reasoning tool applied once a candidate level is proposed.

______________________________________________________________________

## E — Execution Steps

1. **Identify the proposed SLO level in "nines" notation**

   - Completion criteria: You can state the proposed SLO as both a percentage (e.g., 99.99%) and its error budget (e.g., 52 minutes per year).

2. **Calculate the current SLO level and the delta in nines**

   - Express the gap: how many additional nines are being proposed? Each additional nine represents a 10x reliability improvement and a directional 10x cost increase.
   - Completion criteria: You can state "we are at X-nines and the proposal requires Y additional nines."

3. **Enumerate the cost drivers the new level requires**

   - Walk through the cost dimensions that become relevant at the new level: automation requirements (at 5-nines, human response is impossible in 26s), on-call structure, redundancy architecture, process friction, tooling investment, migration costs.
   - Completion criteria: At least 3 cost dimensions identified that are not currently in place.

4. **Check whether the reliability level matches the system's criticality**

   - Is this a life-critical system (hospital, aviation, banking core)? If not, is the proposed SLO level justifiable by consumer tolerance and revenue impact?
   - Stop condition: If the system is safety-critical, hand off to regulatory/compliance frameworks — the 10x/9 cost argument does not override legal obligations.
   - Completion criteria: A clear statement of whether the cost is justified by business value.

5. **Present the cost argument to the SLO proposer**

   - Frame as: "Raising from X-nines to Y-nines reduces error budget by 10x and requires roughly 10x more investment. Here is what that investment includes. Is the business value of the additional nines worth that cost?"
   - Completion criteria: The SLO debate moves from technical aspiration to economic decision.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The system is genuinely safety-critical (medical devices, aviation infrastructure, financial settlement systems) — cost arguments are secondary to regulatory requirements and failure consequence modeling.
- The SLO level has already been agreed by all stakeholders and the task is now implementation — apply composite-slo or sli-monitoring-design-maturity instead.
- The goal is to find the right SLO number, not challenge an existing one — use slo-definition-calibration-framework for calibration.

### Failure Patterns Warned by the Author

- **ce13 (Demanding 5-nines without cost modeling):** A senior leader mandates a 5-nines target for a non-critical service without understanding the 26-second error budget or the cost of fully automated incident response. Teams spend months building toward an unreachable target at enormous cost while consumers would have accepted 3-nines.
- **ce20 (SLO too high — false security):** A team commits to a higher SLO than consumer tolerance requires. The error budget is exhausted by normal feature shipping, feature velocity halts, and consumers who never needed that level of reliability cause cascading failures when the SLO is occasionally breached.

### Author's Blind Spots / Limitations

- The 10x/9 cost rule is intuitive and experientially validated but not formally derived. It will break down in specific architectural contexts — a stateless API behind a load balancer may go from 2-nines to 4-nines cheaply via horizontal scaling, breaking the 10x multiplier. The rule is directional, not precise.
- The book does not provide a methodology for actually estimating reliability costs in a specific engineering context. Without a cost model, "the next nine is 10x more expensive" is a rhetorical point that leaders can accept intellectually but cannot operationalize as a budget decision.

### Easily Confused With

- **Lagom SLO calibration**: The 10x/9 rule explains the cost scaling; lagom SLO is the full methodology for choosing the right target given that scaling, including consumer negotiation and the too-low case. The 10x/9 rule is an input to lagom SLO, not a replacement for it.

______________________________________________________________________

## Related Skills

- **composes-with** → `slo-definition-calibration-framework`: The 10x/9 rule provides the cost-scaling argument; slo-definition-calibration-framework uses that as one input and adds the consumer-tolerance side to find the calibrated target.
- **composes-with** → `wardley-pace-slo`: Wardley/Pace classifies the system's evolutionary tier; 10x/9 is the cost-reasoning tool applied when evaluating whether a candidate SLO level within that tier is economically justified.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Reliability Engineering Mindset" by Alex Ewerlöf
