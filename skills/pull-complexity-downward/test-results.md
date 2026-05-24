# Test Results — Pull Complexity Downward

## Overall: PASS (10/10 Prompts Correct)

| ID   | Category          | Prompt (abbreviated)                                                                                     | Result | Notes                                                                                                                                                                                          |
| ---- | ----------------- | -------------------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp01 | should_invoke     | Cache class requires `maxSize` parameter; most callers pass 1000                                         | PASS   | Canonical trigger: "all callers pass the same value" — E step 5 says eliminate the parameter; A1 case 1 (retry interval) is an exact structural parallel                                       |
| tp02 | should_invoke     | HTTP client exposes five timeout/retry constructor parameters; callers want "sensible retry behavior"    | PASS   | Trigger fires: "config object with many fields where most callers leave most at zero value"; SKILL provides direct guidance to absorb retry policy                                             |
| tp03 | should_invoke     | Team defaults to "let the caller decide"; every module has a dozen knobs; callers copy-paste same values | PASS   | Describes the exact anti-pattern in the I section; SKILL names this and provides the corrective procedure                                                                                      |
| tp04 | should_invoke     | Logger: expose `flushOnEveryWrite` boolean or always buffer and flush periodically?                      | PASS   | Uncertainty about pushing config choice to callers; E step 2 ("does any caller have information the module does NOT have?") resolves this                                                      |
| tp05 | should_not_invoke | SaaS product user notification preferences UI — email digest vs. instant, quiet hours, channel           | PASS   | User-facing configuration; B section boundary 1 ("callers have genuine context the module cannot access") is the exact reason this must be exposed                                             |
| tp06 | should_not_invoke | Environment variables vs. config file for debug mode                                                     | PASS   | Deployment/ops mechanism question; not an API interface design question about complexity distribution                                                                                          |
| tp07 | should_not_invoke | Feature flags for A/B testing — SDK vs. server-side evaluation                                           | PASS   | Product/infrastructure architecture concern; SKILL is about module-level parameter design, not system-level flag distribution architecture                                                     |
| tp08 | boundary          | Database connection pool: expose `minConnections` setting or manage internally based on load?            | PASS   | SKILL's B section boundary 4 ("legitimately variable by use case") applies; `minConnections` may reflect operational deployment constraints callers must own; SKILL provides the right framing |
| tp09 | boundary          | Library needs to be testable; must expose internal dependencies as constructor parameters                | PASS   | SKILL's B section boundary 2 ("hiding defaults prevents testing") directly addresses this; answer is: expose with sensible defaults, not un-overridable constants                              |
| tp10 | boundary          | gRPC client `deadline` parameter on every call — default in constructor or per-call?                     | PASS   | Boundary correctly handled: per-call deadlines may be legitimately caller-specific (microservice SLAs); SKILL suggests sensible constructor default with per-call override as the resolution   |

## Issues Found

None. All 10 prompts correctly handled.

The three should_not_invoke cases are well-differentiated: tp05 involves user-visible product preferences (the module cannot access user intent); tp06 is an ops/deployment mechanism, not an API design choice; tp07 is a system architecture question, not a module interface question.

The three boundary cases all receive genuine analysis from the SKILL. Notably, the B section covers all three boundary tensions (callers with genuine context, testability, legitimately variable decisions) with sufficient specificity to resolve the boundary prompts.

## Verdict

PASS — skill is well-scoped and handles all test cases correctly. The decisive question ("does any caller have information the module does NOT have?") is sharp enough to separate legitimate parameter exposure from complexity offloading, and the boundary section covers the main counter-cases.
