# Test Results: Governance Variety Lever Selection

**Date:** 2026-05-05
**Status:** PASS

## Invocation Boundary Analysis

The description correctly positions this as a post-diagnosis skill: "Invoke after a variety deficit has been located." The prerequisite requirement is explicit in both the description and in Step 1 of Execution ("This skill is not usable without knowing where the deficit lives"). This is a critical boundary — the skill must not fire when the diagnosis hasn't been done (tp-05, tp-06) and should not be invoked just because governance is struggling. The two-lever structure (amplify vs. attenuate) maps cleanly to deficit locations, and the Zenefits test provides a named decision rule for rejecting misapplied attenuation.

The A2 triggers are well-constructed: they all presuppose a prior audit either explicitly ("governance body has just received a requisite-variety-gap-assessment") or implicitly through the framing ("governance board is overwhelmed," "debating whether to hire a process-oriented COO or redesign the architecture"). The main discrimination risk is that someone might invoke this skill when they haven't done a variety audit — the description and Step 1 guard against this, but the should-not-invoke prompts are specifically designed to test that guard.

## Prompt-by-Prompt Results

### Should_invoke

| ID    | Prompt summary                                                                                                                                          | Result | Notes                                                                                                                                                        |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| tp-01 | Prior variety audit done; three deficits identified (sensing, authority, response); one significant change available this quarter                       | PASS   | Lever 1 for all three; sequencing rule for multiple simultaneous deficits applies; sensing and authority before response per Step 2                          |
| tp-02 | Portfolio governance board overwhelmed by 14 workstreams, rubber-stamping everything; variety deficit identified; expand board capacity vs. restructure | PASS   | Lever 2 or Lever 3; Zenefits test applied to restructuring option; attenuation targets environmental variety (fewer concurrent programs), not board capacity |
| tp-03 | Startup hired Fortune 500 COO, added approval layers and reviews, team frustrated, things moving slower                                                 | PASS   | Zenefits anti-pattern; Lever 2 misuse; approval layers are attenuating management variety not environmental variety; Step 4 Zenefits test applied explicitly |
| tp-04 | Variety gap assessment showing deficits in all four areas simultaneously; program actively in trouble; what to do first                                 | PASS   | Lever 3 with sequencing; sensing and authority first per Step 5; model-building and response second; attenuation may also be needed for tractability         |

### Should_not_invoke (Decoys)

| ID    | Prompt summary                                                                                                 | Result | Notes                                                                                                                                  |
| ----- | -------------------------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| tp-05 | Governance failing but not sure where — missing milestones, adversarial vendors, disengaged steering committee | PASS   | No prior variety audit; description and Step 1 both require deficit location first; route to requisite-variety-gap-assessment          |
| tp-06 | Preparing governance chapter of program management plan for new $50M federal IT program from blank slate       | PASS   | Governance design from scratch, not lever selection for diagnosed deficit; no prior audit; route to general governance design guidance |
| tp-07 | CPI 0.78, SPI 0.84, month 8 of 24; what corrective actions to consider                                         | PASS   | EVM and schedule/cost recovery question; no variety audit; execution-level problem, not governance variety lever selection             |

### Blurred_boundary

| ID    | Prompt summary                                                                                                                       | Result | Notes                                                                                                                                                                                                                                                      |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp-08 | Sensing deficit identified; debating mid-month check-in (Lever 1) vs. scope reduction (Lever 2); finance pushing for scope reduction | PASS   | Genuine Lever 1 vs. Lever 2 evaluation; Zenefits test applied to scope reduction; finance-driven scope reduction risk (hidden integration complexity) is correctly flagged in expected behavior                                                            |
| tp-09 | Authority is formally present but functionally unavailable; committee conflict-averse; decisions deferred                            | PASS   | Behavioral/political constraint vs. structural authority deficit; skill partially relevant as functional response deficit; SKILL.md correctly acknowledges framework primarily addresses structural deficits; political constraints are boundary condition |
| tp-10 | Model variety deficit; debating systems integrator (Lever 1) vs. contractor reduction from 11 to 5 (Lever 2)                         | PASS   | Both options are structurally valid; differentiation based on whether deficit is integration complexity vs. capability; Lever 3 sequencing applies if program is in active trouble                                                                         |

## Issues Found

None. The two-lever framework with Zenefits test provides clean decision rules. The prerequisite requirement (prior variety audit) is explicit and consistently enforced in the should-not-invoke set. The blurred-boundary cases are handled with appropriate nuance — particularly tp-09 where behavioral constraints on using existing authority are correctly distinguished from structural authority deficits. The B section's note that "the organizationally feasible lever may not match the structurally correct lever" is an honest and important boundary acknowledgment.

## Verdict

PASS — The prerequisite enforcement (requires prior variety audit) is correctly designed and consistently holds; the Zenefits test provides a named, executable decision rule for detecting lever misuse; the three-lever structure with sequencing rules covers all should_invoke scenarios including the all-four-deficits case.
