# Test Results: Governance Model Adequacy Test (Conant-Ashby Good Regulator Audit)

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description is tightly framed: it requires a governance structure with formal authority, outcomes diverging from plan, and the specific hypothesis that the oversight layer is "governing on someone else's representation of reality." The phrase "reacting to information rather than anticipating it" is a useful differentiator from general governance improvement requests. The A2 triggers are well-composed: they name the three failure modes (model absence, staleness, capture) through concrete scenarios rather than abstract categories, making the trigger conditions more recognizable.

The key discriminations this skill must make: (a) from requisite-variety-gap-assessment, which addresses structural governance capacity broadly vs. this skill's specific focus on model adequacy at the oversight layer; (b) from sv-trend-diagnostic and general EVM/schedule questions; (c) from rollout strategy and stakeholder management questions. The description's emphasis on "suspect the oversight layer is governing on someone else's representation" provides the specific trigger. The B section correctly calls out that this applies to complex multi-component programs with meaningful separation between governing and operating layers, not to small co-located teams.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                                                                               | Result | Notes                                                                                                                                                         |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-01 | Federal IT modernization steering committee approves everything but can't describe integration risks; program team prepares all briefings                    | PASS   | Textbook model-capture; A2 bullet 1 directly covers "committee has authority but no model"; three diagnostic questions apply                                  |
| tp-02 | Board gets RAG dashboard, everything green for 6 months, then critical dependency failure; board asking why not warned                                       | PASS   | Model-staleness + model-capture; governance model updating slower than program changing; A2 bullet 3 ("why didn't we know earlier?") matches                  |
| tp-03 | Reviewing governance for multi-agency, 8-contractor, 3-year build — trying to assess structural adequacy before failure                                      | PASS   | Prospective application; Step 1-5 of Execution all apply; A2 bullets 1-2 cover this pattern; the diagnostic applies exactly                                   |
| tp-04 | Regulatory body's technical review relies on manufacturer documentation; regulatory staff can't do independent assessment; answers come from regulated party | PASS   | Boeing/FAA pattern; A2 bullet 4 directly covers federal delegation to contractor quality assurance; named in A1 and I section as the most severe failure mode |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                                                              | Result | Notes                                                                                                                                        |
| ----- | ------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-05 | Sponsor keeps changing priorities mid-sprint, team losing confidence, can't finish anything | PASS   | Stakeholder management / scope governance problem; no model-adequacy issue; description requires governance body failing due to model gap    |
| tp-06 | Choosing between phased rollout vs. big-bang launch — need analytical framework             | PASS   | Rollout strategy question; closer to requisite-variety or governance-lever-selection; model adequacy is not the central question here        |
| tp-07 | Project 6 weeks behind, SPI 0.82 trending down, need recovery plan for steering committee   | PASS   | EVM / schedule recovery question; functioning steering committee with active reporting is the opposite of the model-adequacy failure trigger |

### Blurred_boundary

| ID    | Prompt summary                                                                                                           | Result | Notes                                                                                                                                                                                                     |
| ----- | ------------------------------------------------------------------------------------------------------------------------ | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-08 | PMO runs monthly portfolio reviews, programs present to board; two programs blew up after showing green                  | PASS   | Classic model-capture pattern; "green before failure" is the signature; skill correctly invokes and acknowledges that risk management practices at program level may also need examination                |
| tp-09 | Assessing whether governance structure is "mature enough" before scaling from 3 to 11 contractors                        | PASS   | Correctly identified as boundary territory between this skill and requisite-variety-gap-assessment; model-adequacy should be applied first since model absence is most immediately disabling              |
| tp-10 | IQA contractor reviews artifacts and attends meetings but doesn't access technical working groups or interview engineers | PASS   | Model-capture question about whether IQA constitutes genuine independent model-building; third diagnostic question applies directly; SKILL.md correctly notes this is partly a scope-of-work question too |

## Issues Found

None. The three failure mode categories (absence, staleness, capture) provide clear diagnostic structure for all should_invoke scenarios. The B section correctly distinguishes governance of complex multi-component programs from simple co-located projects. The skill's relationship to requisite-variety-gap-assessment (complementary, not overlapping) is handled correctly in tp-09 blurred boundary.

One observation worth noting: there is meaningful overlap between this skill and requisite-variety-gap-assessment in the model-variety dimension. Both can be invoked on the same scenario (tp-09 blurred boundary). The SKILL.md correctly notes "model adequacy diagnostic should be applied first" but this could be made slightly clearer in the description. This is not a rework-required issue — it is a minor documentation opportunity.

## Verdict

PASS — The three-question diagnostic (where is the model held, update rate vs. change rate, whose model) provides a precise and executable framework; the Boeing/FAA and Healthcare.gov cases anchor the failure modes concretely; the invocation boundary correctly fires on model-adequacy failures and correctly excludes execution, EVM, and strategy questions.
