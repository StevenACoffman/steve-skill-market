---
name: fit-practice
description: |
  Use this skill to evaluate whether an externally-sourced practice, methodology, or technical approach is appropriate for the current context — and to derive a context-specific alternative when it is not. The fit-practice framework replaces the binary "best practice / not best practice" judgment with a four-question evaluation that exposes the conditions required for a practice to work and tests whether those conditions are present.

  Call this skill when: (1) A team or leader wants to adopt a practice that originated elsewhere and the justification relies on the source's reputation rather than an explicit fit analysis. (2) An existing practice is producing poor results and you need to diagnose whether it was ever appropriate. (3) You want to help a team extract the underlying wisdom from a "best practice" and apply that wisdom in a way that fits their actual context. (4) A practice is being applied uniformly across teams with very different contexts and needs.
tags: [best-practice, fit-practice, critical-thinking, cargo-culting, decision-making, context]
---

# Fit Practice Decision Framework (Vs. Best Practice)

## R — Original Text (Reading)

> Best practices are often someone's **interpretation** of why something worked at a certain **time** and **environment**. This interpretation is often **exaggerated** to make a point.
>
> What makes a *fit practice*?
>
> - It is specific to the problem at hand. This requires understanding the problem.
> - It is easy to understand. No need for complex acronyms.
> - It is good enough to stand on its own without the need to attach it to other names.
> - It doesn't need advertisement to convince a potential buyer of the solution. Use logical reasoning instead of manipulation.
>
> Best practice is absolute and ideal. Fit practice is pragmatic and relative to the problem at hand given all constraints. Put your critical thinking hat and ask: Where does that best practice come from? What are the nuances for that best practice to work? And more importantly where doesn't it apply?
>
> — Alex Ewerlöf, 20241204_163905_best-practice.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The fit-practice framework starts from a specific diagnosis: "best practice" as a label suppresses the situational analysis that determines whether a practice is appropriate. The label implies universality ("best" is absolute). Fit practice makes context explicit and replaces the prestige-based justification with four questions that anyone can ask.

**Question 1 — Origin:** Where did this practice come from, and what was the problem it was designed to solve? This question strips away the generalization that made the practice famous and returns to the specific circumstance where it produced results. The answer exposes the problem definition, the constraints that shaped the solution, and the organizational and technical context at the source.

**Question 2 — Enabling Conditions:** What organizational, cultural, technical, and resource conditions had to be in place for this practice to work at its source? This is the hardest question because enabling conditions are rarely documented — they are assumed as baseline. A team adopting the "Spotify model" without asking what Spotify's talent density, funding runway, and product-market clarity were at the time of adoption is skipping this question. Enabling conditions include: team size and composition, technology stack maturity, decision-making authority structure, feedback loop quality, and market position.

**Question 3 — Underlying Wisdom:** What is the core insight or mechanism that makes this practice effective when its conditions are met? This question extracts the transferable element — the thing that is true across contexts — from the context-specific implementation. DRY (Don't Repeat Yourself) has wisdom about maintenance burden; its specific instantiation may not fit every codebase. Extracting the wisdom enables the next step.

**Question 4 — Boundary:** Where does this practice fail? Under what conditions does applying it produce harm rather than benefit? Every practice has a boundary condition. Practices that claim to have no boundary are best practices in name only. Finding the boundary converts a blunt instrument into a precise tool.

If the current context matches the enabling conditions (Q2) and the problem matches the origin (Q1), the practice may be a fit — but the mechanism (Q3) should still be understood so it can be adapted as context changes. If the enabling conditions are absent, the practice is not fit as-is. The wisdom extracted in Q3 can then be used to derive a fit alternative that solves the same underlying problem within the actual constraints.

A fit practice has four properties: it is specific to the problem at hand; it is easy to understand without insider jargon; it stands on its own merits without name-dropping; and it can be justified with logical reasoning rather than authority or advertising.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Google SRE Book → SLO Cargo Culting (C24)

- **Problem:** Organizations read Google's SRE book and adopted SLOs, dashboards, and APM tooling — but the expected reliability improvements did not materialize.
- **Application:** Fit-practice analysis would have revealed: Origin — Google built SLOs to align a massive engineering organization with consumer reliability commitments at web scale. Enabling Conditions — Google had full ownership models, embedded SREs with mandate, a culture of blameless postmortems, and engineering orgs of thousands. Boundary — SLOs without the accompanying ownership model and consumer-grounded SLI derivation produce vanity metrics.
- **Conclusion:** Most adopters had the tooling form but not the enabling conditions. A fit-practice derivation would have concluded: the wisdom (measure consumer-perceived reliability, use error budgets to regulate risk) is transferable; the specific implementation (dedicated SRE team, Google-scale SLO system) is not.
- **Result:** Dashboards gathered dust. The fit alternative: smaller, consumer-grounded SLI workshops with team-owned SLOs — the practice the author actually recommends.

### Case 2: Kubernetes Migration (C04)

- **Problem:** Around 2018, teams frustrated with Amazon EC2 convinced non-technical leadership to migrate to Kubernetes. The migration went poorly.
- **Application:** Fit-practice analysis: Origin — Kubernetes was created by Google to solve container orchestration at Google's scale, with full-time dedicated platform teams. Enabling Conditions — large engineering org, dedicated platform team, engineers already fluent in containerization, infrastructure budget for the platform overhead. Boundary — Kubernetes is not a fit for teams without containerization maturity and a dedicated platform team; it adds complexity rather than reducing it.
- **Conclusion:** The enabling conditions were absent. The wisdom — container orchestration and automated scaling — could have been applied through a fit alternative (managed container service, PaaS, or a more gradual containerization path).
- **Result:** Budget burned, memes created. The Kubernetes installation was technically present but organizationally unsupported.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An engineering leader wants to adopt a methodology (SRE, SLO, DORA, SAFe, Team Topologies) after reading a book or attending a conference, and is framing it as "best practice" without contextual analysis.
2. A senior engineer is pushing back on a team's technical approach with "that's not best practice" — and neither they nor the team can articulate the conditions under which the practice applies.
3. You are joining a new organization and trying to determine which of the inherited practices are actually fit for the current context and which are historical artifacts that no longer serve a function.

### Language Signals (Activate When These Appear)

- "This is best practice"
- "We should do it the way [company] does it"
- "It says so in the [book/RFC/standard]"
- "That's not how it's supposed to be done"
- "If we just follow the process correctly, it will work"

### Distinguishing from Adjacent Skills

- Difference from `vsi-cargo-culting`: VSI identifies *why* an adoption decision is prestige-driven (the V, S, I mechanism). Fit-practice provides the *evaluation method* to determine whether a specific practice is appropriate and how to derive an alternative. Use VSI to diagnose the adoption dynamic; use fit-practice to evaluate the specific practice.
- Difference from `3ts-premature-optimization`: 3T evaluates *optimization decisions* (is this the right thing to optimize, at the right time, with the right trade-offs). Fit-practice evaluates *methodology adoptions* (does this approach work in this context). The distinction: 3T applies when you're deciding whether to invest; fit-practice applies when you're deciding whether an approach is appropriate.

______________________________________________________________________

## E — Execution Steps

1. **State the practice under evaluation**

   - Write down the practice's name, source, and the stated justification for adopting it.
   - Completion criteria: The practice is named, its origin is identified, and the justification is in writing. If the justification is only "it's best practice" or a company name, flag for Q1 analysis.

2. **Answer Q1 — Origin**

   - Research or reconstruct: What specific problem was this practice designed to solve? What was the state of the art before this practice existed? What made someone document and generalize it?
   - Completion criteria: The original problem can be stated in a single sentence without reference to the practice's name. If the team cannot answer Q1, the understanding is shallow — stop and research.

3. **Answer Q2 — Enabling Conditions**

   - List the organizational, cultural, technical, and resource conditions that were present at the origin. Then map each condition to the current environment: present, absent, or partially present.
   - Completion criteria: A conditions table exists. At least one person who knows the current environment has reviewed each condition mapping.
   - Stop condition: If more than half the enabling conditions are absent, the practice is not fit as-is. Extract the wisdom (Q3) and derive an alternative that doesn't require the absent conditions.

4. **Answer Q3 — Underlying Wisdom**

   - Ask: "If we strip away the specific implementation — the names, ceremonies, roles, tools — what is the core insight that makes this effective when conditions are right?"
   - Write the wisdom in one or two sentences that don't use the practice's name.
   - Completion criteria: The wisdom statement can be explained to someone who has never heard of the practice. It is the transferable element.

5. **Answer Q4 — Boundary**

   - Ask: "Under what conditions does this practice produce harm, waste, or the opposite of its intended outcome?"
   - Seek examples: Has the practice been reported to fail? Under what circumstances?
   - Completion criteria: At least one concrete boundary condition is documented. Practices described as "universally applicable" are flagged as suspected exaggeration — the boundary has not been found yet, not that it doesn't exist.

6. **Render verdict and derive fit alternative if needed**

   - If conditions match and wisdom is understood: adopt with explicit acknowledgment of where the boundary lies and a plan to monitor for boundary conditions.
   - If conditions don't match: use the wisdom (Q3) to derive a fit alternative. A fit alternative: solves the same underlying problem (from Q1); works within the actual enabling conditions; can be justified by logical reasoning without name-dropping.
   - Completion criteria: A written decision exists. If a fit alternative was derived, it has been reviewed by at least one practitioner familiar with the current environment.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The practice in question has demonstrably context-independent properties (a sorting algorithm, a cryptographic primitive, a well-tested mathematical formula). Fit analysis is for sociotechnical practices, not laws of nature.
- The team is under a hard regulatory or contractual obligation to implement a specific practice. Fit analysis can inform *how* it's implemented but cannot replace the obligation.
- The evaluation is being used as a delay tactic. Fit-practice analysis should take hours to days, not months. If the analysis has no end in sight, it has become its own form of premature optimization.

### Failure Patterns Warned by the Author

- **Fit practice as intellectual vanity:** Replacing "best practice" cargo culting with "fit practice" cargo culting — performing the four questions as a ritual without genuinely investigating the answers. The form of the framework is not the same as its function.
- **Best practice as conversation terminator:** Using "that's not best practice" to shut down a team's contextually sound decision without going through the four questions. This is the inverse failure — the framework should be used to investigate, not to dismiss.
- **Exaggeration in the source material:** Best practices are often exaggerated at the point of documentation to make a strong claim. Part of Q3 (extracting wisdom) requires discounting the exaggeration and finding the core kernel that is actually defensible.
- **SLO premature adoption (ce10):** Organizations read Chapter 2 of the Google SRE book, immediately provisioned tooling, built dashboards, and called it SLO implementation. A fit-practice evaluation would have identified the missing enabling conditions (consumer ownership model, team-level SLI derivation, error budget culture) before the tooling was purchased.

### Author's Blind Spots / Limitations

- The framework is primarily diagnostic — it identifies misfit, but it does not guarantee that a derived "fit alternative" will succeed. Deriving a genuinely fit practice requires domain expertise that the four questions alone cannot substitute for.
- The framework assumes the team can identify and access the information required to answer Q1 and Q2. For new or novel practices with limited public documentation of failures, Q4 (boundary conditions) may be genuinely unknown.
- The framework is premised on individual or small-group critical thinking. In organizations where "best practice" functions as a political shield — an appeal to authority to prevent challenge — fit-practice analysis will be rejected not on its merits but on its implications for the authority structure.

### Easily Confused With

- **Being contrarian:** Questioning every best practice is not the same as applying fit-practice analysis. The framework is designed to extract and preserve the wisdom while refusing the uncritical wholesale adoption. It is skeptical of universality claims, not skeptical of learning from others.
- **Junior rule-following vs. expert judgment:** The author's framing ("junior follows rules, senior makes rules, expert knows when to break rules") positions fit-practice as the expert layer. The framework helps practitioners develop that expert layer by making the reasoning explicit rather than leaving it to tacit pattern-matching.

______________________________________________________________________

## Related Skills

- **contrasts-with** → `vsi-cargo-culting`: VSI diagnoses the mechanism of prestige-driven adoption; fit-practice is the corrective evaluation framework that determines what would actually fit the context.
- **composes-with** → `vsi-cargo-culting`: When VSI diagnosis reveals cargo culting, fit-practice provides the four-question framework to extract the underlying wisdom and derive a context-appropriate alternative.
- **composes-with** → `3ts-premature-optimization`: 3Ts tests whether an optimization is justified in this moment; fit-practice tests whether the approach is appropriate for this context — together they cover both timing and fit.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Reliability Engineering Mindset" by Alex Ewerlöf
