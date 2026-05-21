---
name: slo-definition-calibration-framework
allowed-tools: Bash, Read, Edit
id: slo-definition-calibration-framework
description: Use this skill when setting up SLOs for the first time and the team must simultaneously answer three interdependent questions — what are the SLI/SLO/SLA artifacts and how do they differ, what number should the SLO target be (calibrated to consumer tolerance from both directions), and where should the SLA buffer sit below the SLO — rather than any single question in isolation.
type: merged-skill
source_skills:
  - slug: site-reliability-engineering/sli-slo-sla-tier-framework
    book: "Site Reliability Engineering"
    author: Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.)
  - slug: reliability-engineering-mindset/lagom-slo
    book: "Reliability Engineering Mindset"
    author: Alex Ewerlöf
related_skills:
  - slug: site-reliability-engineering/sli-slo-sla-tier-framework
    relation: supersedes
    note: This merged skill adds lagom bidirectional calibration and consumer tolerance elicitation that the source skill lacks
  - slug: reliability-engineering-mindset/lagom-slo
    relation: supersedes
    note: This merged skill adds the SLA buffer design and the definitional SLI/SLO/SLA structure that the source skill lacks
tags: []
---

# SLO Definition and Calibration Framework

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

SLO definition files:
!`find . \( -name '*slo*' -o -name '*objective*' \) -not -path './.git/*' 2>/dev/null | head -10`

### R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 4):**

> An SLI is a service level indicator — a carefully defined quantitative measure of some aspect of the level of service that is provided. An SLO is a service level objective: a target value or range of values for a service level that is measured by an SLI. SLAs are service level agreements: an explicit or implicit contract with your users that includes consequences of meeting (or missing) the SLOs they contain. An easy way to tell the difference between an SLO and an SLA is to ask "what happens if the SLOs aren't met?": if there is no explicit consequence, then you are almost certainly looking at an SLO.
>
> Users build on the reality of what you offer, rather than what you say you'll supply. If your service's actual performance is much better than its stated SLO, users will come to rely on its current performance.

**From Ewerlöf (Reliability Engineering Mindset, lagom-slo):**

> A lagom SLO is not too high or too low. It's just right for the service consumers!
>
> An SLO should define the lowest level of reliability that you **can get away with** for each service. — Jay Judkowitz and Mark Carter (Google PMs)
>
> When the service level is too low, your service consumer can do their own preparation, share the risk with their consumers, and renegotiate with you. Just beware that by committing to a poor SLO, you are outsourcing the expense to your service consumer and the company takes the total bill. Sometimes it's cheaper to improve your SLO than forcing your service consumers to deal with it.

**Convergence note:** Both sources independently warn that SLOs set without grounding in what consumers actually need produce identical symptoms — the SRE book through the Chubby over-dependency case (wrong in the upward direction), Ewerlöf through the too-low case (wrong in the downward direction). The SRE book contributes the definitional structure (SLI/SLO/SLA tiers and the SLA buffer requirement); Ewerlöf contributes the bidirectional calibration methodology and the too-low failure mode that the SRE book does not address.

---

### I — Unified Framework (Interpretation)

Setting up SLOs for the first time requires three simultaneous decisions. They are interdependent: the target number (decision 2) cannot be set without knowing what artifact you are setting (decision 1), and the SLA buffer (decision 3) cannot be sized without a stable SLO (decision 2).

## R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 4):**

> An SLI is a service level indicator — a carefully defined quantitative measure of some aspect of the level of service that is provided. An SLO is a service level objective: a target value or range of values for a service level that is measured by an SLI. SLAs are service level agreements: an explicit or implicit contract with your users that includes consequences of meeting (or missing) the SLOs they contain. An easy way to tell the difference between an SLO and an SLA is to ask "what happens if the SLOs aren't met?": if there is no explicit consequence, then you are almost certainly looking at an SLO.
>
> Users build on the reality of what you offer, rather than what you say you'll supply. If your service's actual performance is much better than its stated SLO, users will come to rely on its current performance.

**From Ewerlöf (Reliability Engineering Mindset, lagom-slo):**

> A lagom SLO is not too high or too low. It's just right for the service consumers!
>
> An SLO should define the lowest level of reliability that you **can get away with** for each service. — Jay Judkowitz and Mark Carter (Google PMs)
>
> When the service level is too low, your service consumer can do their own preparation, share the risk with their consumers, and renegotiate with you. Just beware that by committing to a poor SLO, you are outsourcing the expense to your service consumer and the company takes the total bill. Sometimes it's cheaper to improve your SLO than forcing your service consumers to deal with it.

**Convergence note:** Both sources independently warn that SLOs set without grounding in what consumers actually need produce identical symptoms — the SRE book through the Chubby over-dependency case (wrong in the upward direction), Ewerlöf through the too-low case (wrong in the downward direction). The SRE book contributes the definitional structure (SLI/SLO/SLA tiers and the SLA buffer requirement); Ewerlöf contributes the bidirectional calibration methodology and the too-low failure mode that the SRE book does not address.

---

## I — Unified Framework (Interpretation)

Setting up SLOs for the first time requires three simultaneous decisions. They are interdependent: the target number (decision 2) cannot be set without knowing what artifact you are setting (decision 1), and the SLA buffer (decision 3) cannot be sized without a stable SLO (decision 2).

## Decision 1: Define the Three Tiers and Their Boundaries

Three distinct artifacts are routinely conflated:

- **SLI** answers "what are we measuring?" — a precise quantitative metric of user-visible service behavior (e.g., "99th percentile latency of HTTP GET requests, measured at the load balancer, excluding health-check traffic"). The SLI must reflect user experience, not engineering convenience.
- **SLO** answers "what value must the SLI achieve?" — the internal engineering target with no automatic external consequences for breach. It is the input to error budget calculation and the engineering team's performance commitment.
- **SLA** answers "what do we promise customers with consequences for breach?" — a contractual commitment that must always sit below the SLO.

The distinguishing test: if there is no explicit consequence for missing it, it is an SLO, not an SLA.

## Decision 2: Calibrate the SLO Target (The Lagom Point)

SLO calibration is a bidirectional problem. Both directions of error are harmful:

*Too high:* An SLO above consumer tolerance shrinks the error budget aggressively. Normal feature development burns through the budget. Consumers, receiving near-perfect reliability, stop building defensive systems — no retries, no circuit breakers, no fallbacks. When the SLO is eventually breached, their systems cascade. The Google Chubby case is the canonical proof: over-reliability breeds hidden tight coupling.

*Too low:* An SLO below consumer tolerance transfers the cost of unreliability to every consumer. Each consumer team independently builds fallback logic, caching, and retry layers. The total organizational cost of N independent mitigation implementations often exceeds the cost of the provider simply improving their SLO. A low provider SLO is not a local decision — it distributes costs invisibly across consumers.

The calibration process:

1. Start with the consumer tolerance question: "What is the worst reliability level you could live with for this service?" This is the ceiling. Do not substitute engineering judgment or historical data for this answer — it requires a direct conversation with consumers.
2. Apply the cost side: how much does it cost to deliver at that tolerance level, given the 10x/9 exponential cost scaling of reliability?
3. The lagom point is where consumer tolerance and cost of delivery converge. If they do not converge, the gap is a business priority decision, not a technical one.

Avoid two common anti-patterns:

- Setting the SLO based on historical performance ("we've been at 99.9% for 18 months, so let's commit to that") — this locks the team into a target that may have been achieved through heroic effort and may not reflect what consumers actually need.
- Setting the SLO aspirationally ("we want to be a five-nines service") — this sets a target no consumer required, exhausts error budget, and breeds consumer complacency.

## Decision 3: Set the SLA Buffer Below the SLO

The SLA must always be set below the SLO. The buffer is the response window: the gap between SLO and SLA is the time the team has to detect an SLO breach and remediate before it becomes a contractual violation with financial consequences.

If the SLO is 99.9% (allows ~43 minutes downtime/month), the SLA might be 99.5% (allows ~220 minutes/month), giving the team approximately 177 minutes of response window. The buffer is typically 10–50% of the total allowed error rate, calibrated to the team's realistic detection-and-response time.

## Ongoing: Prevent Overachievement

After the SLO is set, monitor the actual-vs-committed gap. If a service consistently delivers significantly above its SLO (e.g., 99.99% actual against 99.9% SLO), two remedies exist:

- If the lower SLO was correctly calibrated to consumer tolerance: introduce synthetic outages to bring observed availability within a narrow band of the committed SLO, preventing consumer over-dependency from accumulating.
- If the lower SLO was set aspirationally or historically without consumer input: raise the SLO to reflect actual capability rather than degrading delivery.

Choosing between these depends on whether the SLO target was correctly calibrated in the first place — which is why calibration (Decision 2) precedes the overachievement question.

---

## A1 — Past Application

### Case A: AdWords Vs. AdSense — Consumer-Driven Differentiated SLOs (SRE Book, Chapter 4)

- **Problem:** Two Google ad products needed latency SLOs. Defaulting to the same tight target for both would have imposed over-provisioning costs on the geographically distributed AdSense infrastructure.
- **Methodology:** The team derived each SLO from its user context, not from engineering convention. AdWords must not slow search responses (tight single-digit millisecond budget). AdSense competes with the publisher's own page render (hundreds of milliseconds more lenient). Two different user contexts produced two different lagom SLOs.
- **Conclusion:** SLOs derived from user context, not engineering convention, enabled geographic consolidation and substantial cost savings for AdSense without degrading AdWords user experience.
- **Result:** The AdSense SLO, set correctly (not at the tightest achievable level), enabled infrastructure savings that "match the tightest target" would have precluded.

### Case B: Media Company CTO Demanding Five-Nines (Ewerlöf, Lagom-Slo)

- **Problem:** The CTO of a media company demanded five-nines availability for a consumer streaming product without asking whether consumers could notice — let alone tolerate — the difference between 99.9% and 99.999%.
- **Methodology:** The lagom calibration reframed the question from "how reliable can we be?" to "what is the worst reliability consumers could live with?" For consumer streaming, users tolerate occasional buffering; they do not require the sub-26-second failure budget of hospital information systems. The 10x/9 cost argument was applied to show the financial absurdity of five-nines for this product category.
- **Conclusion:** The SLO was aspirational prestige, not consumer-grounded calibration. The cost of five-nines was unjustifiable because no consumer required it.
- **Result:** A more appropriate target was negotiated, reducing engineering investment to a level the organization could sustain without the SLO being a development tax.

---

## A2 — Trigger Scenario ★

**Instead of sli-slo-sla-tier-framework or lagom-slo, use this when:** a team is setting SLOs for the first time and must simultaneously resolve definitional confusion (what is an SLO vs. SLA?), calibration confusion (what number should the SLO be?), and buffer design (how far below the SLO should the SLA sit?) — a compound scenario that neither source skill handles alone.

**Scenario 1:** A cloud database team publishes "we target 99.9% uptime" in both engineering documentation and customer contracts. A customer demands a service credit after a 99.8% availability month. The team argues they never agreed to credits. The SLO/SLA conflation is the root cause — and they are simultaneously unsure whether 99.9% was the right target or just what they historically achieved.

**Scenario 2:** A platform team is setting SLOs for an internal API used by 12 product teams. They want to commit to 99%, but several product teams are already building redundant caching layers to compensate. They have not asked those product teams what failure levels they can tolerate. The team suspects 99% may be too low, but stakeholders are pushing for 99.9%.

**Scenario 3:** A new service needs monitoring thresholds, a reliability target, and a customer contract. The team is conflating all three. They need to understand the SLI/SLO/SLA structure, calibrate a number from consumer research, and then set the SLA buffer — three sequential decisions they are treating as one.

**Language signals:**

- "What should our SLA be?" (when the speaker means "what should we alert on?")
- "We've been at 99.9% historically so let's just commit to that"
- "Our uptime is 99.99%, so our SLA should be 99.99%"
- "Our consumers want five-nines" (without consumer research)
- "Why does our team have to build all this retry logic just because their API is flaky?"

---

## E — Execution Steps

1. **Separate the three artifacts before setting any numbers.** Confirm: what is the SLI (the measurement), what will be the SLO (the engineering target with no external consequence), and will there be an SLA (the contract with financial consequence)? If the team cannot answer "what happens if we miss the SLO?" they likely have no SLA yet.

2. **Identify user-facing behaviors that define service health.** The team must articulate 2–5 behaviors users directly experience (e.g., "users can complete a search in under 100ms 99% of the time"). SLI selection follows from this — not from what is easy to measure. Each SLI needs a defined measurement window, aggregation method, data source, and request scope.

3. **Ask the consumer tolerance question before proposing a target number.** Directly ask consumers: "What is the worst reliability level you could live with for this service?" Do not substitute historical data, engineering judgment, or aspirational targets for this answer. If consumers cannot articulate tolerance without experiencing a breach, run a workshop with hypothetical outage scenarios.

4. **Check both calibration failure modes:**
   - *Too-high check:* Is the proposed SLO above consumer tolerance? Will the error budget be exhausted by normal feature development? Are consumers building tight dependencies that assume this service never goes down?
   - *Too-low check:* Are N consumer teams independently building fallback, caching, or retry logic to compensate? Is N × (consumer mitigation cost) greater than the cost of raising the provider SLO?
   - If either failure mode is active, adjust the proposed target before proceeding.

5. **Set the SLO conservatively — the lagom point.** The target is the lowest level consumers can tolerate where the cost of delivery is justified by the business value. If consumer tolerance and affordable cost do not converge, escalate — this is a business priority decision. Document the SLO with explicit justification citing consumer tolerance input (not historical data, not aspiration).

6. **Set the SLA below the SLO with an explicit buffer.** The buffer must be large enough to give the team realistic time to detect an SLO breach and remediate before contractual violation. Calculate the buffer as a multiple of detection-and-response time converted to error rate. Typical range: 10–50% of total allowed error rate.

7. **Establish an overachievement policy.** If the service consistently delivers significantly above the SLO, document whether the response is to (a) raise the SLO if the current target was aspirational or historical, or (b) introduce synthetic outages if the target is correctly calibrated but actual delivery drifts above it. The choice depends on whether Step 3–5 produced a well-grounded calibration.

---

## B — Boundary ★

### Failure Patterns from the SRE Book

- Conflating SLO and SLA by publishing the same number in engineering documentation and customer contracts. A customer holding a 99.9% SLA is entitled to credit if availability drops to 99.8%, even if the team intended the number as an internal engineering target.
- Setting SLOs based on current performance without reflection. If the system currently achieves 99.99% through heroic manual effort, adopting 99.99% as the SLO locks the team into that effort level permanently.
- Using mean-based SLIs rather than percentile-based SLIs. Mean latency hides the tail experience of the worst-affected users.

### Failure Patterns from Ewerlöf

- Demanding five-nines without cost modeling: SLO set aspirationally; the team burns out chasing a target consumers never needed; error budget is structurally impossible to maintain.
- SLO too high — false security: consumers build tightly coupled systems that cascade on rare SLO breaches; error budget exhausted by feature shipping.
- SLO too low — outsourcing cost to consumers: N consumer teams each pay mitigation costs; total organizational cost exceeds the cost of improving the SLO.
- Premature SLO from historical metrics: SLO set by copying historical data or another company's book without consumer input; the SLO is a vanity metric no team acts on.

### Synthesis-Specific Failure Mode

**The completed-one-decision trap:** A team correctly defines the SLI/SLO/SLA structure (Decision 1) and correctly designs the SLA buffer (Decision 3), but sets the SLO target number using historical data or aspiration rather than consumer tolerance (skipping the lagom calibration of Decision 2). The resulting SLO has a well-formed structure and a properly sized SLA buffer — but at the wrong number. This failure is invisible from within either source skill: the SRE framework would validate the structure; Ewerlöf's framework would catch the calibration error. Only the merged framing makes the three decisions visible as interdependent steps that must all succeed.

### Do Not Use When

- No measurement infrastructure exists. SLI definition is meaningless without collection capability. Instrument first.
- The SLO is already set and the problem is meeting it — use the error budget framework, composite SLO design, or reliability architecture patterns.
- The system is life-critical and regulatory SLO floors override consumer tolerance — consumer elicitation still applies but the calibration result may be constrained by regulation.

---

## Related Skills

- **supersedes**: site-reliability-engineering/sli-slo-sla-tier-framework — use this merged skill when calibration and buffer design are both in scope; use the source skill when only the definitional structure question is needed
- **supersedes**: reliability-engineering-mindset/lagom-slo — use this merged skill when the SLI/SLO/SLA structure and SLA buffer are also undefined; use the source skill when only the target-number calibration question is needed
- **feeds-into**: site-reliability-engineering/error-budget-conflict-resolution — the SLO produced by this framework is the mandatory input to error budget calculation
- **composes-with**: site-reliability-engineering/four-golden-signals-monitoring — golden signals are the canonical SLI candidates; this framework wraps them in targets and contracts
