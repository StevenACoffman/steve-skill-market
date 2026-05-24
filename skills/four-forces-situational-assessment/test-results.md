# Test Results: Four Forces Situational Assessment

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description targets two situations: (1) multiple concurrent problems that standard diagnostic isn't resolving, and (2) preparing to take on a new complex assignment before selecting initial governance posture. Both are concrete and recognizable. The emphasis on "standard diagnostic not producing actionable insight" provides a useful threshold — this is not a first-response tool for every struggling program, it's a second-order tool for when the first-order explanations (scope creep, resource gaps, stakeholder issues) are insufficient or already tried.

The A2 section is well-designed: it covers inherited programs (Entropy-dominant), all-green dashboards with failing integration (Complexity-dominant), fast-changing priorities outpacing governance cycles (Velocity-dominant), incoming executive briefing, and the specific Ambiguity+Velocity danger combination. These trigger patterns are distinct enough from each other that a practitioner can recognize them in actual conversations without requiring framework vocabulary.

The skill must correctly exclude: short bounded projects on track (no forces meaningfully present), presentation design questions, and individual technical disputes. The B section is appropriately modest about the Ambiguity+Velocity "most dangerous combination" claim — acknowledging it as "analytically plausible and experientially grounded" but without strong independent empirical support. This is honest and does not undermine the skill's utility.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                                                        | Result | Notes                                                                                                                                                                                                                                    |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-01 | Just inherited 18-month organizational change program: tired team, disengaged sponsor, leadership attrition, re-litigated decisions   | PASS   | Entropy dominant; Ambiguity likely present (re-opened decisions suggest contested success understanding); Velocity may also be present; A2 bullet 1 directly covers this; re-enrollment before re-acceleration is the correct first move |
| tp-02 | All workstreams green, but keep missing integration milestones; senior stakeholders say program doesn't feel like it's going anywhere | PASS   | Complexity force dominant; component health not predicting system health; Williams' definition applies directly; interaction layer unowned; matches A2 bullet 2                                                                          |
| tp-03 | 3-year digital transformation, business changes priorities every quarter, governance cycle is monthly steering committee              | PASS   | Velocity dominant; environmental change rate (quarterly) faster than governance cycle (monthly); shorten feedback loop and design for reversibility; matches A2 bullet 4 and A1 organizational change case                               |
| tp-04 | Preparing briefing for incoming executive sponsor inheriting complex 2-year program with significant scope growth and team turnover   | PASS   | Four Forces as diagnostic structure for briefing; Complexity and Entropy from scope growth and runtime; Ambiguity risk from turnover-eroded shared understanding; Step 2 through Step 5 structure the briefing content                   |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                                                                 | Result | Notes                                                                                                                                                                                               |
| ----- | ---------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-05 | Taking over six-month software implementation in month four, on track, need to get up to speed | PASS   | Bounded short-duration implementation on track; B section explicitly notes the tool requires forces meaningfully present; practical handover steps are the right response                           |
| tp-06 | Need to structure an executive status presentation for the board next week                     | PASS   | Communication and presentation design question; Four Forces is a diagnostic, not a presentation structure; the Forces might be referenced as content but the skill itself is not the right tool     |
| tp-07 | Two team leads disagree about technical architecture (microservices vs. monolith)              | PASS   | Individual technical dispute; the skill "does not operate at the level of individual technical disputes between team members" per expected behavior; facilitate the architectural decision directly |

### Blurred_boundary

| ID    | Prompt summary                                                                                                                                        | Result | Notes                                                                                                                                                                                                        |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| tp-08 | Cloud migration technical work on track, but different business units have completely different expectations about what the migrated platform enables | PASS   | Ambiguity dominant; technical success vs. political contest at delivery; Force assessment fires correctly; the ambiguity is in the definition of success, not in technical scope                             |
| tp-09 | 18 months into 4-year program, no red flags, CDIO wants proactive risk assessment for next (more interdependent) phase                                | PASS   | Forward-looking diagnostic rather than current-state; Complexity will intensify with more interdependence; Entropy risk grows with timeline; proactive governance additions rather than waiting for symptoms |
| tp-10 | Program has high Ambiguity and high Velocity; sponsor wants committed delivery date and scope baseline                                                | PASS   | Ambiguity+Velocity confirmation and sponsor conversation directly addressed; A2 bullet 5 names this as most operationally dangerous combination; staged commitment conversation is the correct response      |

## Issues Found

None. The Dominant/Present/Minimal scoring schema for each force is simple and actionable. The force interaction analysis (Step 6) provides explicit guidance for the two most dangerous combinations, which are the cases where practitioners most need structured help. The B section's acknowledgment that "the Four Forces does not address political and organizational dynamics that determine whether identified mechanisms can actually be implemented" is honest and important — diagnosing Entropy and re-enrollment mechanisms doesn't help if the PM lacks sponsor relationship to implement them.

Minor observation: the Execution section doesn't explicitly address the scenario where all four forces are simultaneously dominant (mentioned in Step 6 as a case requiring design for all four with explicit bandwidth sequencing). The expected behavior for tp-01 (which is Entropy + Ambiguity + possible Velocity) handles it implicitly, but a practitioner facing the all-four case might benefit from slightly more structured guidance on sequencing than Step 6 currently provides.

## Verdict

PASS — The four-force taxonomy with Dominant/Present/Minimal scoring provides a practical and fast situational read; the high-risk combination analysis (Ambiguity+Velocity, Complexity+Entropy) adds decision value beyond simple classification; invocation boundary correctly targets complex multi-force programs and excludes simple bounded projects and operational/presentation questions.
