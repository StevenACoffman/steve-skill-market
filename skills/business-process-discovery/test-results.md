# Test Results — Business-Process-Discovery

**Skill version**: 0.1.0
**Source book**: Practical Data Modeling — Joe Reis
**Evaluation date**: 2026-05-03
**Evaluator**: Phase 4 stress test agent

______________________________________________________________________

## Summary

| Test ID        | Type               | Expected                   | Self-Eval         | Pass? |
| -------------- | ------------------ | -------------------------- | ----------------- | ----- |
| bpd-trigger-01 | should_trigger     | trigger                    | trigger           | PASS  |
| bpd-trigger-02 | should_trigger     | trigger                    | trigger           | PASS  |
| bpd-trigger-03 | should_trigger     | trigger                    | trigger           | PASS  |
| bpd-decoy-01   | should_not_trigger | no trigger                 | no trigger        | PASS  |
| bpd-decoy-02   | should_not_trigger | no trigger                 | no trigger        | PASS  |
| bpd-edge-01    | edge_case          | trigger + compose with TKE | trigger + compose | PASS  |

**Pass rate**: 6/6 (100%)
**Minimum required**: 0.80 (4.8/6)
**Status**: PASS

______________________________________________________________________

## Case-by-Case Evaluation

### Bpd-Trigger-01 — Insurance Claims, Legacy Schema Starting Point

## Verdict: PASS

The prompt places the user at exactly the Hellta failure mode entry point: a new model, a workflow that involves people, and the temptation to start from the existing schema. All trigger signals are present: "starting a new data model for [business process]" and "not sure if it [the schema] captures all the steps." The A2 section is unambiguous. The five-component framework should activate immediately and should explicitly warn against using the legacy schema as the starting point (the B failure pattern "physical-first modeling" is directly relevant).

No boundary exceptions apply. The process is not yet discovered, not machine-generated, and not in production with the question being about grain validation.

______________________________________________________________________

### Bpd-Trigger-02 — Finance Vs. Operations Order Count Gap

## Verdict: PASS

"Multiple teams getting different numbers from the same source" is explicitly listed as trigger scenario #3 in A2 and as a language signal. The 400-order gap (4,200 vs. 3,800) matches the Hellta $24M gap pattern at reduced scale — the symptom of process never having been discovered and different teams making incompatible implicit assumptions.

The correct response is not query debugging but process discovery: what does each team's process definition actually include? Are they counting the same events? This is the context collapse failure mode (ce10) that discovery prevents.

______________________________________________________________________

### Bpd-Trigger-03 — Inherited Healthcare Schema, No Documentation

## Verdict: PASS

Trigger scenarios #2 and #4 together. "Inherited this data but don't know what the business process was" is a direct language match. "Schema doesn't answer stakeholder questions" is a second direct match. The five-component framework should guide the modeler to treat the inherited tables as clues, not sources of truth — the schema is an artifact of decisions made by the departed team, not a description of the business.

Important nuance: the skill should note that tacit knowledge extraction techniques (specifically Artifact Archaeology applied to any surviving documentation, runbooks, or Slack history from the original team) may help reconstruct the original process alongside the five-component framework.

______________________________________________________________________

### Bpd-Decoy-01 — Five-Component Map Complete, Ready to Design Tables

## Verdict: PASS (Correct No-Trigger)

The B boundary section is explicit: "If a complete, verified process map exists with triggering event, outcome, business object in motion, actors, and sequence all explicitly documented and validated with domain experts, proceed directly to process-to-model-translation. Do not re-run discovery for a process that has already been discovered."

The prompt confirms all five components with specifics (triggering event = complete application submitted; outcome = approval/decline/withdrawal; business object = Loan Application; actors = borrower/loan officer/underwriter/compliance; sequence with unhappy paths). This is the exact handoff to process-to-model-translation. Re-running discovery would be wasteful and redundant.

______________________________________________________________________

### Bpd-Decoy-02 — Three Teams with Three Definitions of "Customer"

## Verdict: PASS (Correct No-Trigger)

Three teams with diverging definitions of a shared entity is a bounded context collision problem, not a discovery problem. The process is understood (each team has a functioning workflow); the problem is that the shared term "Customer" carries three incompatible meanings. This calls for bounded-context-swimlane-detection: identify the swimlane crossings, apply the diagnostic question ("What is a Customer to you?"), confirm the boundaries, and design three context-specific models with a mapping layer.

Business process discovery would produce, at best, one team's process — it would not resolve the cross-context vocabulary conflict. This is the A2 distinguishing case explicitly called out.

______________________________________________________________________

### Bpd-Edge-01 — Documentation Exists but Shows Staleness Signals

## Verdict: PASS

This is the composition case. The documentation exists (pointing toward BPD directly) but carries two staleness signals: two years since last update (exceeds the 12-month warning threshold from the B section's ce11 failure pattern) and an unexplained external vendor with no name (a gap that suggests the documented process has drifted from reality).

The correct behavior:

1. Activate business-process-discovery (documentation IS available as a starting point for the five-component framework).
2. Flag the staleness signals as warning indicators for ce11.
3. Recommend applying tacit-knowledge-extraction techniques alongside — specifically Gemba Walk to observe the background check step in practice, and Artifact Archaeology to find if the unnamed vendor has left any shadow artifacts (intake forms, email chains, tracking spreadsheets).
4. Do NOT just "fill in the gaps as you go" — each gap is a modeling finding, not an editorial judgment.

The skill correctly identifies this as BPD + TKE composition, not a choice between them.

______________________________________________________________________

## Boundary Stress Observations

**Strength**: The boundary between BPD and process-to-model-translation (decoy-01) is well-defined and unambiguous in the B section. Any prompt that specifies all five components is a clear handoff.

**Strength**: The boundary between BPD and bounded-context-swimlane-detection (decoy-02) relies on whether the problem is "we don't know what the process is" versus "we know what each team's process is but the terms conflict." The skill handles this distinction clearly.

**Watch point**: The composition case (edge-01) requires the skill to hold two things simultaneously: BPD is the right framework (because documentation exists) AND tacit-knowledge-extraction is needed (because the documentation is stale). A skill that routes exclusively to one or the other would be wrong. The SKILL.md handles this correctly in the A2 distinguishing section and the B section's ce11 warning sign language.

**Watch point**: Trigger scenario #5 in A2 says "even with documentation in hand, a modeler should run through the five components explicitly to verify completeness." This is mildly in tension with the B boundary that says "if complete, verified process map exists, proceed to translation." The resolution is clear in context (A2 #5 applies to documentation that hasn't been verified against the five-component checklist; B applies to documentation that has been verified and validated with domain experts), but an imprecise reading could create confusion.

______________________________________________________________________

## Overall Assessment

The skill boundaries are well-defined and internally consistent. The five-component framework is concrete enough that trigger/no-trigger decisions are reliably derivable from the prompt content. The most important design decision — starting from the process, not the schema — is reinforced across all three trigger scenarios. The composition pattern with tacit-knowledge-extraction is handled correctly in both the SKILL.md and the edge case.

**Recommended improvement**: Add an explicit note in A2 trigger scenario #5 clarifying that "documentation in hand" means unverified documentation — to prevent confusion with the B boundary's "complete, verified process map" language.
