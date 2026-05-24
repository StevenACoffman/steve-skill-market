# Test Results: Project Complexity Source Diagnosis

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description provides two well-scoped triggers: (1) a program consistently failing standard PM interventions with unclear cause — competent team, correct tools, degrading outcomes — and (2) governance approach selection at program initiation where the methodology debate is contested. The "waterfall vs. Agile" framing as a trigger is a clever and practical diagnostic cue — it flags that stakeholders are picking a methodology without first diagnosing the quadrant, which is exactly when the 2-axis assessment adds value.

The skill must correctly exclude: routine schedule recovery questions (clear quadrant, no methodology confusion), Agile team scaling questions (SAFe and topology questions are within-quadrant operational questions, not quadrant-selection questions), and individual risk governance questions. The B section honestly notes that axis placement involves judgment and that practitioners can score the same project differently, particularly on the uncertainty axis. The binary scoring (Low/High) is acknowledged as a simplification of a continuous reality, and the quadrant-shift dynamic (projects moving quadrants over time) is noted. These are honest boundary conditions that strengthen rather than weaken the skill.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                                                                                                       | Result | Notes                                                                                                                                                                                                                 |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-01 | National identity verification modernization: 14 agencies, 6 vendors, novel biometric standard, shifting legislative objectives                                                      | PASS   | Compounded quadrant; both axes clearly high; WBS + EVM tool mismatch named explicitly; matches A2 bullet 5 (novel technology + multi-org + unclear policy objectives)                                                 |
| tp-02 | Successful Agile transformation now asked to run multi-year ERP across 11 business units, 3 acquired companies, 2 regulatory jurisdictions                                           | PASS   | Quadrant shift from Experimental (prior program) to likely Complicated or Compounded (ERP); Agile toolkit not designed for this structural complexity level; A2 bullet 2 (waterfall vs. Agile debate framing) applies |
| tp-03 | Post-mortem: digital health platform, 3 years, 2x budget, cancelled; had detailed WBS, critical path baseline, monthly steering, quarterly stage-gates; everything looked controlled | PASS   | Retrospective diagnostic; San Cristóbal finding directly applicable — tools functioning as designed for wrong domain; reframes failure as structural tool mismatch not execution failure                              |
| tp-04 | Steering committee split: half want strict waterfall with locked requirements, half want full Agile; debate blocking initiation for 2 months                                         | PASS   | A2 bullet 2 directly covers methodology deadlock; 2-axis diagnostic reframes from values debate to evidence; if compounded, neither approach is adequate                                                              |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                                                                           | Result | Notes                                                                                                                                                                                                                   |
| ----- | -------------------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-05 | Data center networking hardware upgrade, 4 locations, known vendor, done before, vendor delivery delayed | PASS   | Simple/Complicated quadrant by easy consensus; schedule recovery and vendor management question; B section notes "the tool is designed for contested or uncertain governance situations, not as a mandatory checkpoint" |
| tp-06 | 40 engineers, 5 squads, growing inter-team dependencies, considering SAFe                                | PASS   | Agile scaling question within established product development context; B section explicitly distinguishes this from "program governance selection question"                                                             |
| tp-07 | Risk on risk register not progressing in 4 months, risk owner says it's being worked                     | PASS   | Escalation and risk governance question; single stalled risk item; no complexity-source or quadrant-selection relevance                                                                                                 |

### Blurred_boundary

| ID    | Prompt summary                                                                                                                   | Result | Notes                                                                                                                                                                                                                |
| ----- | -------------------------------------------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-08 | AI-enabled fraud detection: ML components highly experimental, surrounding infrastructure straightforward                        | PASS   | Split-quadrant condition; ML in Experimental, infrastructure in Complicated; parallel governance tracks rather than single-quadrant classification; integration layer as concentration point                         |
| tp-09 | Inheriting 18-month program, original scope mostly done, but accumulated added scope is now larger than original program         | PASS   | Mid-program quadrant-shift diagnosis; program has moved toward compounded through scope expansion; governance that worked initially is now mismatched; quadrant reassessment not PMO augmentation                    |
| tp-10 | New hospital campus, 800k sq ft, 5 contractors, completely defined scope, fixed-price contract, coordination complexity enormous | PASS   | Correctly lands in Complicated, not Compounded; structural complexity high, uncertainty low; expert decomposition and coordination architecture are right tools; cascade failure risk is a Complicated-quadrant risk |

## Issues Found

None. The 2-axis scoring provides a clean and executable diagnostic. The four quadrant descriptions include both the correct tool and the common error for each — this is a practical execution feature that the skill benefits from. The San Cristóbal academic grounding gives the compounded-quadrant claim empirical standing rather than just being an opinion. The B section's acknowledgment of binary simplification and quadrant-shift dynamics is appropriate.

One observation: the Execution section (Step 5 and Step 6) provides good guidance for the compounded condition but is lighter on concrete next steps for the Experimental quadrant. The guidance says "evaluate Agile or iterative approaches; the key design question is feedback loop cadence" but doesn't give the practitioner much to work with on the specific design questions. This is minor and within normal skill scope constraints.

## Verdict

PASS — The 2-axis diagnostic (structural complexity vs. uncertainty) provides a clear and memorable quadrant map; the methodology-debate reframe is a practical and recognizable trigger condition; the San Cristóbal finding anchors the compounded-quadrant diagnosis with empirical support; all should_invoke, should_not_invoke, and blurred_boundary cases are handled correctly by the skill's framework.
