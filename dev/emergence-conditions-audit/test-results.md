# Test Results: Emergence Conditions Audit for Program Governance

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description identifies two trigger conditions with good specificity: (1) strong component-level results with weak program-level outcomes, and (2) setting up governance for a new multi-project program to check whether the interaction layer has an owner. The "strong components / weak outcomes" pattern is distinctive enough to fire reliably — this is the structural signature Williams names across the Healthcare.gov and EVM cases. The A2 section adds three more trigger patterns: 12+ months of governance focused entirely on project status with no interaction-layer forum; request to add more oversight/reporting to a troubled program that already has extensive reporting; and early instability being treated as a problem to eliminate quickly.

The skill correctly excludes: single-project velocity problems (scale requirement), executive scope changes (single-project scope management), and generic benefits realization planning requests. The boundary with cynefin-pm-domain-identification is handled in tp-08 and tp-10 (blurred boundary), where both are noted as potentially relevant — this is appropriate since the "strong component / weak outcome" pattern can reflect either an ungoverned interaction layer or a domain misclassification (or both). The B section's honest note about misusing the disequilibrium reframe is important and represents a real failure mode.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                                                                    | Result | Notes                                                                                                                                                      |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-01 | Phase one complete, all 9 projects on schedule, 7 under budget; 6 months post go-live, operational metrics flat                                   | PASS   | Canonical structural signature; A1 Healthcare.gov and EVM pattern apply directly; interaction layer ownership audit is the primary diagnostic              |
| tp-02 | Setting up 6-workstream governance: each workstream has PM, PMO does consolidated reporting, monthly steering committee — something feels missing | PASS   | Governance complete at component level, silent on interaction layer; Step 2 ownership audit directly surfaces the gap; matches A2 bullet 2                 |
| tp-03 | Struggling program already has detailed weekly reports, biweekly risk reviews, monthly steering briefings; adding more oversight is suggested     | PASS   | More reporting cannot fix an interaction-layer gap; A2 bullet 4 directly covers this; the intuition is correct and the framework provides the articulation |
| tp-04 | 3 months in, infrastructure and application teams in conflict, data team doing unexpected things; steering committee wants to resolve quickly     | PASS   | Disequilibrium reframe; productive instability vs. dysfunction; Step 6 reframes the sponsor conversation; matches A2 bullet 5                              |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                              | Result | Notes                                                                                                                                                                                                 |
| ----- | ----------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-05 | Single project, sprint velocity declining for three sprints | PASS   | B section explicitly requires multi-project interaction scale; single-project performance problem                                                                                                     |
| tp-06 | Executive sponsor causing scope creep on a single project   | PASS   | Single-project stakeholder management; no interaction-layer or multi-project program dimension                                                                                                        |
| tp-07 | Building a benefits realization plan for my project         | PASS   | Single-project planning methodology request; skill would only be relevant if program-level benefits were not materializing despite strong project performance (the opposite of what's described here) |

### Blurred_boundary

| ID    | Prompt summary                                                                                                                     | Result     | Notes                                                                                                                                                                                                                                                                                         |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-08 | Program 1 year running, projects delivering but each optimizing its own outcomes, components not fitting together as designed      | BORDERLINE | Correctly identified as overlap between integration management (Complicated), emergence conditions (recombination/self-organization absent), and cynefin domain question; expected behavior appropriately invokes emergence-conditions-audit while acknowledging cynefin may also be relevant |
| tp-09 | PMO escalating cross-project dependency conflicts to program director who lacks context; project PMs not resolving with each other | PASS       | Stabilizing feedback absent; no mechanism owns boundary conditions at interaction layer so conflicts escalate; Step 4 (assign ownership) is directly applicable                                                                                                                               |
| tp-10 | About to start genuinely novel program; CIO wants governance to stabilize quickly in first 3 months                                | PASS       | Disequilibrium reframe applies; early stabilization instinct risks foreclosing emergence; cynefin-domain-identification also relevant for novel-program Complex domain question; both skills informing the response is correct                                                                |

## Issues Found

One structural concern: the B section warns that "the disequilibrium reframe is susceptible to misuse" and that it "does not mean instability is always productive." This is an important caution, but the Execution section (Step 6) does not give the practitioner explicit guidance on how to distinguish productive instability from genuine dysfunction that requires direct intervention. A practitioner using tp-04 in practice might struggle to give the sponsor a concrete answer about whether to stabilize or hold. This is a gap in the Execution section, not in the invocation logic — but it could produce unhelpful hedging in practice. A checklist or decision rule distinguishing "instability in the disequilibrium sense" from "dysfunction that needs immediate intervention" would strengthen Step 6.

The Related Skills section is empty, which creates a navigational problem when the skill reaches its boundary (e.g., in blurred-boundary cases where cynefin-pm-domain-identification is also relevant).

## Verdict

PASS — The interaction-layer ownership concept and four emergence conditions provide a distinctive and executable diagnostic framework; the should_invoke pattern (strong components / weak outcomes) is recognizable and specific; the B section correctly names the misuse risk for the disequilibrium argument. The gap in Step 6 (distinguishing productive vs. destructive instability) is worth addressing in a future revision but does not prevent the skill from producing useful output.
