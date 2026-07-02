---
name: 3ts-premature-optimization
description: |
  Use this skill to assess whether a proposed optimization is premature before the work begins, or to diagnose why a completed optimization failed to produce the expected outcome. The 3T framework tests three independent conditions: Thing (is the target the real bottleneck?), Time (is this the right moment in the lifecycle?), and Trade-offs (are all costs accounted for?). Failing any one test means the optimization is premature.

  Call this skill when: (1) A team is proposing a rewrite, refactor, migration, or performance initiative and the justification is intuition or anecdote rather than measured data. (2) An optimization has been completed but user-perceived outcomes didn't improve. (3) Leadership is proposing a structural change (reorg, platform migration, process overhaul) and there is no explicit analysis of timing or trade-offs. (4) A team is planning to adopt a new technology on the basis that it is "better" without confirming it addresses the actual constraint.
tags: [optimization, premature-optimization, 3ts, decision-making, engineering-judgment, trade-offs]
---

# 3T's of Premature Optimization Diagnosis (Thing, Time, Trade-Offs)

## R — Original Text (Reading)

> Good optimization improves the right **things**, at the right **time**, and with reasonable **trade-offs**.
>
> Premature optimization is when at least one of the following is true:
>
> 1. Changing the wrong **thing**. The team takes 6 months to rewrite a Java micro-server to Rust to improve response time. After the rollout, they learn that the biggest source of delay was cross-region network dependencies.
>
> 2. Picking the wrong **time**. A nerdy startup founder burns the budget to create Google-level infrastructure for its one-endpoint API. The startup fails before discovering product market fit.
>
> 3. Choosing the wrong **trade-offs**. Leadership decides to switch observability provider to save cost. After 3 months of migration, the team learns that the new provider has poor data quality and the support is crap.
>
> — Alex Ewerlöf, 20250224_181737_premature-optimization.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The 3T framework operationalizes Donald Knuth's observation that "premature optimization is the root of all evil" by turning a binary label into three distinct, independently testable failure modes — each with its own diagnostic questions and its own remedy.

**T1 — Thing:** Is the optimization targeting the confirmed bottleneck? This test catches the most common failure mode: optimizing a component that is not the system's limiting factor. The question is not "would this component be faster if we changed it?" but "is this component the reason for the outcome we care about?" A test for T1 requires data, not belief. The distinction between fact, assumption, and belief (FAB) is the relevant check: if the bottleneck identification is an assumption or a belief rather than a measurement, T1 fails. Failing T1 means the optimization will succeed technically (the thing being changed genuinely improves) but produce no consumer-perceivable result, because the constraint lives elsewhere.

**T2 — Time:** Is this the right moment in the product or system lifecycle to invest in this optimization? This test catches two distinct timing errors. Too early: the problem being optimized is real in theory but hasn't been confirmed as a constraint by the current system state. Startups building Google-scale infrastructure before product-market fit exemplify this. Too late: the optimization is started during a phase where absorbing its disruption cost (the J-curve of any significant change) is structurally impossible. Organizations initiating reorgs during contraction exemplify this. T2 is a lifecycle test, not a technical one.

**T3 — Trade-offs:** Is the full cost of the optimization — not just the obvious cost, but the hidden costs (migration effort, knowledge transfer, reduced operability, constraints on future change) — explicitly acknowledged and judged to be worth it? This test catches optimizations where the technical improvement is real but the total system cost makes it a net negative. Switching to a cheaper observability provider and discovering the migration took three months and the new product is worse is a T3 failure. The game-engine Assembly rewrite — 20% performance improvement at 2x development cost — is another. T3 is passed only when someone has explicitly listed what will be hurt by the optimization and confirmed the trade is favorable.

The tests are independent: an optimization can pass T1 and T2 but fail T3. Each failed test points to a distinct corrective action: wrong Thing → measure first; wrong Time → confirm lifecycle stage and constraint evidence; wrong Trade-offs → produce an explicit cost-benefit analysis including hidden costs.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Rust Rewrite — Wrong Thing (C05)

- **Problem:** A team spent six months rewriting a Java microservice in Rust to improve response time.
- **Application:** T1 test would have required measuring where the latency actually lived before committing to the rewrite. No such measurement was done. The team believed (not confirmed) that the Java application code was the bottleneck.
- **Conclusion:** After deployment, they discovered the dominant source of latency was cross-region network dependencies — entirely outside the scope of the language-level change. T1 failed: wrong Thing optimized.
- **Result:** Six months of engineering effort produced negligible consumer-perceivable improvement. The constraint was in the network layer, which the rewrite did not touch.

### Case 2: Startup Burns Budget on Google-Level Infrastructure — Wrong Time (C07)

- **Problem:** A technically proficient startup founder invested heavily in enterprise-grade infrastructure for a single-endpoint API before validating product-market fit.
- **Application:** T2 test: the problem being solved (scale) was theoretical rather than confirmed. The product hypothesis was unvalidated. The correct time for scale infrastructure is after product-market fit is confirmed.
- **Conclusion:** The startup ran out of budget and failed before reaching product-market fit. The infrastructure investment that would have been appropriate at scale caused premature death.
- **Result:** Startup failure. Demonstrates that "first make it work, then make it better" is a T2 principle.

### Case 3: Observability Provider Switch — Wrong Trade-Offs (C08)

- **Problem:** Leadership approved switching observability providers to reduce licensing costs. The three-month migration effort was not included in the cost-benefit calculation.
- **Application:** T3 test: the visible trade-off (lower licensing cost) was real, but the hidden costs (three months of engineering time, context switching, re-instrumentation, degraded data quality post-migration) were not accounted for.
- **Conclusion:** After migration, the team had a worse observability stack despite spending three months migrating. The cost-benefit calculation that justified the switch was incomplete.
- **Result:** Net negative outcome. The lesson: the cost of migration is always a trade-off that must be explicitly counted.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A team proposes to rewrite a service in a different language or framework because the current one is "slow" — but no measurement has been done to confirm the service is the bottleneck.
2. Leadership proposes a significant organizational restructuring or platform migration during a period of declining performance or budget pressure, without modeling the J-curve.
3. An optimization is proposed that has an obvious upside (cost savings, performance gain) but the proposal contains no explicit list of what will be sacrificed or made harder.

### Language Signals (Activate When These Appear)

- "We should rewrite [X] in [Y] — it would be much faster"
- "We need to migrate to [platform] now, before we scale"
- "We're spending too much on [tooling], let's switch to save money"
- "This is technically better so we should do it"
- "First, let's get the infrastructure right, then build the product"

### Distinguishing from Adjacent Skills

- Difference from `vsi-cargo-culting`: VSI diagnoses why something is being adopted because of prestige rather than fit. 3T diagnoses whether the *timing, target, and trade-offs* of a specific optimization decision are sound. They can overlap (a cargo-culted practice can also be a wrong-Time optimization) but address different root causes.
- Difference from `fit-practice`: `fit-practice` evaluates whether an externally-sourced methodology is appropriate for the current context. 3T evaluates whether any optimization effort (including home-grown ones) is targeting the right thing at the right time with appropriate trade-off awareness.
- Difference from `service-level-topology`: The topology skill derives *what to measure*; 3T diagnoses *whether a proposed change is justified* by what has been measured.

______________________________________________________________________

## E — Execution Steps

1. **State the optimization proposal explicitly**

   - Write down: "We propose to change [X] to achieve [Y], which will improve [consumer outcome Z]."
   - Completion criteria: The proposal is concrete — a specific change, a specific improvement metric, a stated connection to consumer outcome.

2. **Apply T1 — Thing test**

   - Ask: "Do we have data confirming that X is the dominant contributor to the current gap in outcome Z?"
   - Classify the evidence: is it a fact (measured), assumption (plausible but unmeasured), or belief (intuition, analogy, or precedent from elsewhere)?
   - Completion criteria: The bottleneck claim is supported by measurement, not assumption. If the claim is an assumption or belief, the optimization fails T1.
   - Stop condition: If T1 fails, stop and measure first. Do not begin the optimization until the bottleneck is confirmed by data.

3. **Apply T2 — Time test**

   - Ask: "Is the problem confirmed as a current constraint, or is it anticipated? Is the organizational or product context ready to absorb the disruption cost?"
   - Check for two failure modes: too early (optimizing for a scale or quality level not yet needed) and too late (initiating disruptive change during contraction or at the trough of a J-curve).
   - Completion criteria: The lifecycle stage is explicitly named and the timing rationale is documented. If the problem is not yet a confirmed constraint, T2 fails.

4. **Apply T3 — Trade-offs test**

   - Ask: "What list of things will be hurt, made harder, or made more expensive by this optimization? Is that list explicitly acknowledged?"
   - Common hidden trade-offs: migration effort (engineering time), knowledge transfer cost, operability changes, constraints on future change (lock-in), regression risk.
   - Completion criteria: A written list of trade-offs exists. Each item on the list has been judged to be worth the optimization's benefit. If the list is empty or the judgment has not been made, T3 fails.

5. **Verdict and action**

   - All three tests pass: proceed with the optimization.
   - One or more tests fail: do not proceed until the failed test's gap is resolved.
     - T1 fail: instrument and measure first; return to step 2 with data.
     - T2 fail: define the condition that would make the time right; wait for that condition; revisit.
     - T3 fail: produce a complete trade-off analysis; include hidden costs; get explicit agreement that the trade is net positive.
   - Completion criteria: A written verdict exists that references all three tests by name, with the evidence for each pass/fail determination.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- There is a confirmed emergency (production incident, security breach, regulatory deadline) where the constraint is known and the time imperative is real — in emergencies, the 3T framework would produce false T2 failures. Act first, then do the retrospective diagnosis.
- The optimization is trivially small (a 2-line performance improvement in a non-critical code path) — the overhead of the 3T analysis would exceed its value. Apply the framework to decisions with non-trivial investment or risk.
- The question is "are we measuring the right thing?" — that is a `service-level-topology` / `sli-evolution-stages` question, not an optimization diagnosis question.

### Failure Patterns Warned by the Author

- **Metric gaming (T1 failure variant):** A non-technical manager focused on DORA Lead Time used carrots and sticks to push faster PR reviews. The team gamed the metric with meaningless PRs. The T1 test would have caught this: the optimization target was the metric, not the underlying delivery behavior.
- **J-curve impatience (T2 failure variant):** A company initiated a reorg during contraction, then panicked at the productivity dip (the J-curve trough) and chose layoffs instead of waiting for the recovery. T2 would have flagged the timing as wrong: the context was not ready to absorb the change cost.
- **Hidden migration cost blindness (T3 failure variant):** Any migration (technology, vendors, infrastructure) where the cost of the migration itself is not counted in the trade-off analysis. The observability provider switch is the canonical example.

### Author's Blind Spots / Limitations

- The framework assumes measurement is feasible before the optimization. In greenfield or early-stage contexts, data to confirm the bottleneck (T1) may not yet exist. The author's answer ("first make it work, then make it better") is sound but doesn't give guidance on when "it working" is confirmed enough to justify measurement investment.
- Cost quantification in T3 is expected to be "engineering judgment" rather than precise accounting. This is intentionally pragmatic but may be insufficient in contexts where financial justification is required for capital allocation decisions.
- The framework is primarily designed for engineering optimization decisions. Applying it to organizational or people-system changes (reorgs, team restructuring) requires translating "measurement" into organizational equivalents (e.g., delivery velocity data, incident attribution data) that are harder to obtain.

### Easily Confused With

- **Knuth's original aphorism:** "Premature optimization is the root of all evil" is often used to dismiss optimization effort entirely. The 3T framework is more precise: it does not say don't optimize; it says confirm Thing, Time, and Trade-offs first. Mature optimization is explicitly valued.
- **Analysis paralysis:** Requiring data before optimizing can become an excuse to never optimize. The 3T tests are designed to be lightweight — they can typically be resolved in a single focused conversation using existing data, not multi-month measurement projects.

______________________________________________________________________

## Related Skills

- **contrasts-with** → `vsi-cargo-culting`: VSI diagnoses prestige-driven adoption decisions; 3Ts diagnoses whether the timing, target, and trade-offs of a specific optimization are sound. They address different root causes of engineering misjudgment.
- **composes-with** → `fit-practice`: 3Ts validates whether an optimization is justified; fit-practice evaluates whether the approach being optimized fits the context — use together when evaluating both the timing and the fit of a proposed change.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Reliability Engineering Mindset" by Alex Ewerlöf
