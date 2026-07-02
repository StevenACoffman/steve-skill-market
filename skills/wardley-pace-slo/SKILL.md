---
name: wardley-pace-slo
description: |
  Use this skill when an organization or team needs a strategic starting point for SLO levels across multiple systems, especially when those systems serve different business purposes and change at different rates. The core heuristic: Systems of Innovation (SOI) ~95%, Systems of Differentiation (SOD) ~99.6%, Systems of Record (SOR) ~99.99%. Evolution stage determines appropriate SLO level — not organizational prestige, not competitor benchmarking, not historical performance.
tags: [wardley-maps, pace-layering, slo, soi, sod, sor, strategic-reliability, system-evolution]
---

# Wardley Maps + Pace Layering for Strategic SLO Setting

## R — Original Text (Reading)

> Pace layering is particularly useful for Service Levels. Change is the number one enemy of reliability: any time you change a system, its likelihood of breaking spikes up. The unsung hero of the Service Level model is the error budget: it allows the teams to take risks (changing the system) in a controlled manner.
>
> In practice, this means Pace Layering can set different levels of SLO for different systems and make a deliberate decision about the reliability vs speed tradeoff:
>
> - **SOI (Systems of Innovation):** could use a lower SLO (e.g. 95%) to support a faster rate of change.
> - **SOD (Systems of Differentiation):** could use medium SLO requirements (e.g. 99.6%) to balance reliability and speed.
> - **SOR (Systems of Record):** could set high SLO expectations (e.g. 99.99%) to guarantee a stable base for business-critical services.
>
> Setting SLOs: components early in their evolution stage can use lower SLO. Higher reliability commitments create frictions against the experimentation and flexibility that these solutions need to evolve rapidly.
>
> — Alex Ewerlöf, 20250606_111644_wardley-maps-and-pace-layering-for.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Wardley Maps and Pace Layering are two complementary strategic lenses that, when applied together, give SLO decisions a business rationale rather than a technical or aspirational one.

**Wardley Maps** situate each component on a two-dimensional plane: the Y-axis represents how visible the component is to users (value chain position); the X-axis represents evolutionary maturity, from Genesis (novel, uncertain, experimental) through Custom-Built, Product/Rental, to Commodity. The key insight for SLOs: components in the Genesis stage need to change rapidly; high reliability commitments create friction against that change. Commodity components, by contrast, should be stable and their SLOs should be held by vendors via SLAs.

**Pace Layering** (Stewart Brand / Gartner adaptation) classifies systems by their required rate of organizational change:

- **SOI (Systems of Innovation):** fastest-changing, experimental, closest to Genesis on the Wardley map. Think hackathon projects, A/B test engines, AI model integrations. ~95% SLO gives a generous error budget (5% failure space) that supports rapid iteration.
- **SOD (Systems of Differentiation):** medium rate of change, implements unique competitive advantage. Custom pricing engines, recommendation systems, proprietary CRM integrations. ~99.6% SLO balances stability with ongoing development velocity.
- **SOR (Systems of Record):** slowest-changing, foundational, manages critical business data. Core financials, HR databases, authentication infrastructure. ~99.99% SLO (52 minutes of downtime per year) reflects the extreme cost of these systems failing.

The critical connection: **SLO determines error budget, which determines how aggressively a system can change.** An SOI with a 95% SLO has a 5% error budget — it can be changed and experimented with far more aggressively than an SOR with a 0.01% error budget. The three levels therefore encode the business's explicit decision about how much stability versus velocity each system class needs.

When combined: Wardley Maps identify what a component *is* in the market landscape; Pace Layering determines how fast *your business needs it to change*. The intersection gives SLO guidance that is grounded in strategic purpose, not arbitrary numbers.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: News Site Architecture — Clean Pace Layer Separation (C18)

- **Problem:** The news site needed to support multiple daily front-end releases while maintaining stable content delivery infrastructure. The author needed to justify different SLO expectations for different layers.
- **Application:** Using Wardley Mapping, the front-end was positioned in the Genesis/Custom-Built stage (rapidly changing storytelling features), the business logic layer in the Custom-Built stage (changes every 2-3 days), and the headless CMS in the SOR layer (only a handful of API-breaking changes in five years). The SLO levels appropriate to each layer followed directly from their pace: SOI front-end supports multiple daily releases at ~95%, SOD business logic at ~99.6%, SOR CMS at ~99.99%.
- **Conclusion:** The headless CMS was built in-house (rather than bought) because no market product matched the storytelling requirements at the time — a legitimate Genesis/Custom-Built investment. The cloud infrastructure (managed Kubernetes cluster) was treated as Commodity with vendor SLA, not requiring internal SLO.
- **Result:** The pace layer classification justified different engineering practices and reliability investments per layer. The front-end could be released multiple times per day precisely because its error budget (SOI, ~95% SLO) allowed experimentation at speed. The CMS was stable and rarely touched precisely because its SOR designation made any change high-cost.

### Case 2: CTO Five-Nines Demand — Misclassifying SOI as SOR (C01, Reframed)

- **Problem:** A streaming media service CTO demanded five-nines (99.999%). The streaming product was in active development with frequent releases, new features, and ongoing UX iteration — clearly an SOD or even SOI context, not SOR.
- **Application:** Using the pace layering lens: a consumer streaming product with active feature development and a direct-to-consumer growth mandate should be classified as SOD (99.6%) at most — not SOR (99.99%) and certainly not five-nines. The CTO was applying SOR-level reliability expectations to an SOD product.
- **Conclusion:** The mismatch between the product's evolutionary stage (active differentiation, rapid change) and the SLO target (ultra-stable SOR levels) made the target incoherent. A streaming consumer product at five-nines would require freezing feature development to protect the error budget.
- **Result:** The Wardley/Pace Layering framing provided a principled, business-grounded way to negotiate the SLO down: "This system is SOD, not SOR. SOD systems are appropriately held to ~99.6%. Here is why our product's pace of change is incompatible with SOR-level reliability investment."

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An organization has five product teams each setting their own SLOs and there is no consistency — one team is at 99% for a critical authentication service while another is at 99.9% for an experimental recommendation feature. The SLO levels are inverted relative to the strategic importance of the systems.
2. A platform team is asked why their infrastructure services require 99.99% SLOs while product teams operate at 99.5% — Wardley/Pace Layering provides the strategic justification.
3. An engineering leader wants to use SLOs to communicate the difference between "this service is in experimentation mode" and "this service is mission-critical" to the rest of the organization, and needs a framework that product managers and finance teams can understand.

### Language Signals (Activate When These Appear)

- "What SLO should our new [feature / product / service] have?"
- "Why does the platform team need such a high SLO?"
- "This service has been around for years but we've never set an SLO for it"
- "We're building an experimental AI feature — what level of reliability do we need?"
- "Our SLO is 99.9% but we're shipping new features every day and always burning through the error budget"
- "How do we justify different SLO levels across our portfolio to leadership?"

### Distinguishing from Adjacent Skills

- Difference from `slo-definition-calibration-framework`: Wardley/Pace SLO provides *strategic range* (SOI=~95%, SOD=~99.6%, SOR=~99.99%) as a starting point; slo-definition-calibration-framework provides the *detailed calibration* of exactly where within that range a specific service should land, based on actual consumer tolerance.
- Difference from `10x9-cost-reliability`: Wardley/Pace SLO uses the cost-of-reliability argument to explain why higher evolutionary stages require higher SLOs; 10x9-cost-reliability is the mechanism (why it's expensive) rather than the classification system (which tier applies).

______________________________________________________________________

## E — Execution Steps

1. **Classify the system using Pace Layering**

   - Ask: What is the expected rate of change for this system? Is it experimental and iterating rapidly (SOI), delivering competitive business value with regular updates (SOD), or providing foundational stability that changes rarely (SOR)?
   - If in doubt: ask "how would the business react if this system could not be changed for 6 months?" SOI: business would miss opportunities. SOD: business would lose competitive edge. SOR: business would not notice feature-wise, but would expect high stability.
   - Completion criteria: The system is classified as SOI, SOD, or SOR with a brief business justification.

2. **Validate using Wardley Map positioning (optional but recommended)**

   - Where does this component sit on the Genesis → Custom-Built → Product → Commodity spectrum? Genesis/Custom-Built components should be SOI or SOD. Product/Commodity components should be SOD or SOR.
   - Check for mismatches: if a Genesis component is being held to SOR-level SLO, this is a red flag — the reliability obligation will strangle its evolutionary velocity.
   - Completion criteria: The pace layer classification is consistent with the Wardley evolution stage, or the mismatch is explicitly acknowledged and justified.

3. **Assign the SLO range**

   - SOI: ~95% (5% error budget — permits aggressive experimentation)
   - SOD: ~99.6% (~3.5 days/year error budget — permits regular releases)
   - SOR: ~99.99% (~52 minutes/year — near-zero tolerance for unplanned downtime)
   - These are starting points, not final targets. Use slo-definition-calibration-framework to calibrate within the range.
   - Completion criteria: A target SLO range is assigned with the tier justification documented.

4. **Check the error budget implications for development pace**

   - What is the error budget at this SLO? How many deployments can the team reasonably make per month without exhausting it?
   - If the team plans to deploy more frequently than the error budget permits, reconsider whether the classification is correct or whether the error budget needs to be managed differently.
   - Stop condition: If the team's development pace is fundamentally incompatible with the SOR classification, escalate — the organization may need to choose between the system's evolutionary stage and its reliability obligations.
   - Completion criteria: The team can state how many incidents or deployments the error budget permits per compliance period.

5. **Communicate the classification to stakeholders**

   - Use the Wardley/Pace framing to explain why this system gets this SLO, not a competitor's SLO or an aspirational target. "This is SOD — it changes monthly and competes on features. SOD systems are appropriately held to ~99.6%."
   - Completion criteria: Stakeholders understand the classification rationale and the SLO is accepted or a principled counter-argument is raised.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The exact SLO number needs precise consumer-tolerance calibration — use slo-definition-calibration-framework after establishing the range.
- The system does not cleanly fit one of the three pace layers — mixed-pace systems (e.g., an API that is both foundational and rapidly evolving) need separate SLOs for different capabilities, not a single tier classification.
- The organization does not have the strategic context to classify systems by pace — this skill requires business-level understanding that engineers may not have access to.

### Failure Patterns Warned by the Author

- **ce13 (Demanding 5-nines without cost modeling):** The classic mismatch: applying SOR-level SLO expectations to a SOI or SOD product. The CTO demanding five-nines for a streaming product is demanding SOR reliability from an SOD system.
- **ce10 (Premature SLO implementation):** Setting all systems at the same SLO regardless of their pace layer. A "one-size-fits-all availability SLO" violates the core principle that SLO should reflect the system's evolutionary context.
- **ce08 (Best practice as context-free recipe):** Copying SLO levels from a competitor or from Google's SRE book without checking whether those systems occupy the same evolutionary stage.

### Author's Blind Spots / Limitations

- The SOI=95%, SOD=99.6%, SOR=99.99% numbers are heuristic guidelines, not empirically derived from a broad study. The exact percentages are illustrative of the tier structure. A reasonable SOI might be 90% or 99% depending on the specific consumer base and business context.
- Wardley Mapping itself requires significant skill to apply accurately. The evolution axis (Genesis → Commodity) is often contested — teams disagree about where a component sits. The framework is only as useful as the quality of the initial classification.
- Pace Layering was originally a concept about building architecture, not software systems. The application to software requires judgment calls that the original framework does not provide.

### Easily Confused With

- **Lagom SLO calibration**: Wardley/Pace SLO gives the strategic tier and a starting range; lagom SLO gives the precise target within that range based on consumer tolerance and cost.
- **Wardley Maps in general**: Wardley Maps are a broad strategic tool; this skill is specifically about their application to SLO setting, not the full strategic analysis capability.

______________________________________________________________________

## Related Skills

- **depends-on** → `slo-definition-calibration-framework`: Wardley/Pace provides the strategic tier range as the starting point; slo-definition-calibration-framework calibrates precisely within that range based on actual consumer tolerance and cost.
- **composes-with** → `10x9-cost-reliability`: The 10x/9 rule explains why different evolutionary tiers require different SLO levels; Wardley/Pace provides the classification system that applies the cost argument across a portfolio of systems.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Reliability Engineering Mindset" by Alex Ewerlöf
