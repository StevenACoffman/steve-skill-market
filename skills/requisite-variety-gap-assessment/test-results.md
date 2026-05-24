# Test Results: Requisite Variety Gap Assessment

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description is well-targeted: it names "management or governance system visibly failing to regulate an environment" and specifies the structural framing — "why was the management system structurally unable to catch this." This distinguishes the skill from execution-level failures (bad decisions, bad actors) and from EVM-based corrective loop problems. The A2 section provides five concrete patterns: multi-tier governance with integration surprises, expert-import stabilization failures (Zenefits pattern), new standardized framework rollout with mixed results, post-mortem on risk-register misses, and regulator capacity assessment. These cover a useful range without being so broad that the skill fires on unrelated governance questions.

The key boundary that must hold is separation from sv-trend-diagnostic (EVM corrective pathways) and from governance-variety-lever-selection (prescriptive follow-on). Both boundaries are explicitly named in the B section and are represented in the should-not-invoke set. The description's emphasis on "structurally unable to catch this" (emphasis on structural diagnosis rather than execution) provides reasonable discrimination.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                                           | Result | Notes                                                                                                                                 |
| ----- | ------------------------------------------------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| tp-01 | 5-tier governance structure, kept getting surprised by integration failures, governance looks solid on paper             | PASS   | Sensing/model variety deficit; governance tiers lack integration-layer visibility; matches A2 bullet 1 directly                       |
| tp-02 | Startup hired experienced COO from stable company, now looks more organized but still missing targets, engineers leaving | PASS   | Zenefits pattern — variety reduction disguised as stabilization; A2 bullet 2 and A1 case analysis apply                               |
| tp-03 | Post-mortem: risk was in register, categorized medium likelihood / high impact, materialized undetected                  | PASS   | Sensing/response variety audit; A2 bullet 4 covers this; passive vs. active detection question is in Step 2                           |
| tp-04 | PMO rolling out standardized governance framework across 40-project portfolio; half benefiting, half worse               | PASS   | Standardized framework reducing management variety below environmental variety for complex projects; A2 bullet 3 directly covers this |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                                                                                    | Result | Notes                                                                                                                                                 |
| ----- | ----------------------------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-05 | SV worsening for 6 weeks, nobody taking corrective action, sponsor says we'll recover                             | PASS   | EVM corrective pathway problem — sv-trend-diagnostic applies; description requires structural governance mismatch, not known-signal suppression       |
| tp-06 | Small 8-person team, well-understood data migration, familiar technology — should we add more complex governance? | PASS   | B section explicitly excludes simple, stable, low-variety environments; description requires "visibly failing" management system                      |
| tp-07 | Variety gap assessment already done, model variety deficit found — what governance changes to make?               | PASS   | Diagnostic complete; B section defers prescriptive follow-on to governance-variety-lever-selection; skill correctly identifies its own scope boundary |

### Blurred_boundary

| ID    | Prompt summary                                                                                                  | Result | Notes                                                                                                                                                                       |
| ----- | --------------------------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-08 | Experienced team with great informal communication, minimal formal governance, being told to add more structure | PASS   | B section explicitly covers informal systems as variety contributors; assessment must account for informal regulatory capacity before recommending formalization            |
| tp-09 | FAA reviewing modernization of aircraft certification for AI-assisted flight systems                            | PASS   | Sensing and model variety audit at regulatory level; A2 bullet 5 covers regulator-supervising-evolving-domain scenario; prescriptive question is out of scope per B section |
| tp-10 | Considering decentralizing decision authority to workstream leads — evaluating authority variety dimension      | PASS   | Authority variety audit directly addressed in Step 4; accountability concern is a separate dimension; skill can clarify the tradeoff without making the political decision  |

## Issues Found

None. The four-dimension audit structure (sensing, response, authority, model) provides clear coverage of all should_invoke scenarios. The B section's explicit deferrals to sv-trend-diagnostic and governance-variety-lever-selection are correctly placed and reflected in the should-not-invoke prompts. The informal-system boundary condition (tp-08) is explicitly called out in B. No execution gaps found.

## Verdict

PASS — The skill reliably distinguishes structural governance variety diagnosis from execution-level failures and from EVM corrective pathway problems; the four-dimension audit framework produces a useful deficit profile for all should_invoke scenarios; boundary conditions are well-specified.
