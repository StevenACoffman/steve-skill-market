# Test Results: Cynefin Domain Identification for PM Governance

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description identifies two specific trigger conditions: (1) governance mismatch — "doing everything right by the process but the situation keeps deteriorating," and (2) domain shift — "a significant event may have moved the underlying situation into a new domain without the governance structure following it." These are precise and experiential, meaning a practitioner reading an actual scenario can recognize them without needing the framework vocabulary. The A2 section strengthens this with five concrete patterns: Chaos indicator (major vendor failure with slow escalation chain), benefits-flat-despite-green-metrics (possible Complex misclassification), external context invalidation, sustained high confidence combined with consistent surprises (2008 pattern), and novel program being set up with standard stage-gate.

The skill correctly excludes: Clear domain questions (standard scheduling, repeated work), individual technical disputes, stakeholder management problems, and estimation calibration. The boundary between this skill and emergence-conditions-audit is handled in tp-08 (blurred boundary) where both are noted as potentially relevant — this is appropriate given the overlapping symptom profiles. The description is specific enough to avoid firing on routine governance questions while being broad enough to cover the range of domain misclassification patterns.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                                           | Result | Notes                                                                                                                                                                           |
| ----- | ------------------------------------------------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-01 | Large infrastructure modernization, 6 months of rigorous process, consistent unexpected effects despite strong expertise | PASS   | Classic Complicated-applied-to-Complex signature; A2 bullet 4 (expert confidence + consistent surprises) applies; Step 2 domain diagnostic runs correctly                       |
| tp-02 | Major supplier filed bankruptcy, board meeting in 3 weeks, standard 10-day change control, delivery in 6 weeks           | PASS   | Chaotic domain indicator; cause-effect severing event; counterintuitive Chaos rule (act first, understand second) is the correct response; A2 bullet 1 directly covers this     |
| tp-03 | Novel AI-assisted government system, CIO wants standard stage-gate framework                                             | PASS   | c16 pattern; Complex/Complicated boundary; split-domain governance design (parallel tracks) is the recommendation; A1 case analysis directly applicable                         |
| tp-04 | Technical leads consistently confident throughout, program now 40% over budget at month 9, still confident               | PASS   | 2008-type epistemic confidence failure signal; A2 bullet 4 and B section both specifically call this out as the most dangerous misclassification; domain reassessment warranted |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                                                                 | Result | Notes                                                                                                                                                                |
| ----- | ---------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-05 | Standard software deployment, done 8 times before, scheduling question                         | PASS   | Clear domain; B section explicitly notes the skill adds overhead without value in Clear domain; description requires governance mismatch signals                     |
| tp-06 | Stakeholder map shows three groups with conflicting priorities — how to manage this conflict   | PASS   | Stakeholder management problem; no governance-domain mismatch signal; description does not fire on normal program management challenges                              |
| tp-07 | Team consistently underestimating task effort (60-70% of actual) — how to get better estimates | PASS   | Estimation calibration problem within Complicated or Clear domain; no domain misclassification signal; description requires governance mismatch, not estimation bias |

### Blurred_boundary

| ID    | Prompt summary                                                                                                                                       | Result     | Notes                                                                                                                                                                                                                                        |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-08 | All projects green on dashboard, but program business outcomes flat 18 months in; steering committee asking why projects succeed but program doesn't | BORDERLINE | Symptom pattern overlaps emergence-conditions-audit (ungoverned interaction layer) and cynefin-domain-identification (may be Complex domain governed as Complicated); expected behavior correctly notes both skills are potentially relevant |
| tp-09 | New regulation with 90-day deadline, no industry best practice, legal says comply but can't define what compliance looks like                        | PASS       | Complex/Complicated split; domain diagnosis warranted; skill correctly invoked to structure the diagnostic while acknowledging genuine domain uncertainty; split-domain governance design likely                                             |
| tp-10 | Architecture assumptions from 3 months ago don't hold; team wants to redo architecture; sponsor resisting based on sunk cost                         | PASS       | Domain misclassification hypothesis: architecture failing because situation is Complex, not because analysis was wrong; Cynefin diagnosis changes the response to the sponsor completely; skill correctly applies                            |

## Issues Found

One minor gap: the B section notes that "Williams does not address the Disorder domain (not knowing which domain you're in)" but the A2 triggers don't include a scenario for this meta-uncertainty. This is a genuinely common situation where the framework currently offers "facilitated sense-making with diverse stakeholders" without elaborating. This is not a rework issue — the B section honestly names the gap — but a practitioner encountering genuine Disorder might not find the skill as useful as for the other four domains.

The tp-08 blurred boundary case correctly identifies overlap with emergence-conditions-audit. The SKILL.md does not have a Related Skills section populated, which means an agent using this skill without knowledge of the broader skill set might not pivot to emergence-conditions-audit when needed. This is a structural gap in the Related Skills section, though it doesn't break the execution of this skill itself.

## Verdict

PASS — The governance response table (gap type + appropriate response + how closure is achieved) provides a concrete execution framework that goes beyond domain labeling; the epistemic confidence signal and Katrina/2008 failure mode distinction give the skill diagnostic teeth; invocation boundary correctly excludes routine governance and management questions.
