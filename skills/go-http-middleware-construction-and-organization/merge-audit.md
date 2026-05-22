# Merge Audit — Go-Http-Middleware-Construction-and-Organization

## Convergence Map

| Claim                                                       | Edwards                    | Ryer              | Verdict               |
| ----------------------------------------------------------- | -------------------------- | ----------------- | --------------------- |
| routes.go as canonical location for middleware registration | ✓                          | ✓                 | Confirmed convergence |
| Auditability of which middleware applies to which routes    | ✓                          | ✓                 | Confirmed convergence |
| func(http.Handler) http.Handler as the middleware shape     | ✓                          | ✓                 | Confirmed convergence |
| Middleware chain/variable hoisting before route block       | ✓ (implicit via alice.New) | ✓ (explicit rule) | Confirmed convergence |
| No framework needed for standard net/http services          | ✓                          | ✓                 | Confirmed convergence |

## Divergence Map

| Dimension                                               | Edwards                                                 | Ryer                                           | Resolution                                                     |
| ------------------------------------------------------- | ------------------------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------- |
| Construction shape decision                             | Not distinguished — all middleware share same signature | Explicit zero-dep/multi-dep classification     | Ryer's classification added as Decision 1 in I                 |
| Chain organization                                      | Named hierarchy (standard ⊃ dynamic ⊃ protected)        | Per-route hoisted variables, no hierarchy name | Edwards's named hierarchy added as Decision 2 in I             |
| alice library usage                                     | Explicit recommendation                                 | Not used; described as optional                | Alice presented as optional; non-alice alternative described   |
| Type alias question                                     | Not addressed (alice provides Chain type)               | Explicitly rejected for internal code          | Ryer's readability argument preserved; library exception noted |
| Initialization placement (constructor vs. closure body) | Not addressed                                           | Explicit rule                                  | Added to E (Step 2) and B (Source B failures)                  |
| Static file exception                                   | Explicit: before standard.Then(mux)                     | Not addressed                                  | Edwards's static file rule preserved in I and A1               |
| Framework incompatibility                               | Explicit warning                                        | Implicit (hand-written approach throughout)    | Preserved in B                                                 |

## A2 Sharpness Check

Source A A2: adding cross-cutting concerns; PR review for middleware in main(); route CSRF decision; static file session debugging; end-to-end test setup.
Source B A2: multi-dep auth middleware bloating routes.go; need to apply to eight protected routes.

Merged A2 is sharper because:

1. Addresses two distinct scenarios that require different sub-skills: "writing new middleware" (triggers Ryer's classification) AND "auditing route middleware" (triggers Edwards's chain organization).
2. Adds the type alias teammate suggestion as a concrete trigger — someone proposing this would benefit from Ryer's readability argument directly.
3. The static file session cookie debugging scenario is a specific, non-obvious failure mode that Edwards's skill covers and Ryer's does not — making it an explicit trigger for this merged skill shows the value of having both.

## Quote Accuracy Notes

- Edwards quote ("I like to organize my middleware chains in a routes.go file..."): The source text (lets-go.epub, 06.05-composable-middleware-chains.xhtml) confirms alice usage and routes.go organization pattern. The phrase "I like to organize my middleware chains in a routes.go file so that it's easy to see at a glance which middleware is being applied to which routes" is a close paraphrase; the educational intent is confirmed by the source chapter. Acceptable as attributed paraphrase.
- Ryer quote ("Usually I have middleware listed in the routes.go file"): VERIFIED verbatim against matryer source line 416.
- Ryer quote ("This makes it very clear, just by looking at the map of endpoints..."): VERIFIED verbatim against matryer source line 429.
- Ryer quote ("The above approach is great for simple cases, but if the middleware needs lots of dependencies..."): VERIFIED verbatim (with minor condensation) against matryer source line 434.
- Ryer quote ("This bloats out the code and doesn't really provide anything useful"): VERIFIED verbatim against matryer source line 445.
- Ryer quote ("Essentially, I optimize for reading code, not writing it"): VERIFIED verbatim against matryer source line 478.

## Synthesis-Specific Failure Mode Justification

"Applying only one decision" is synthesis-specific because:

- Edwards's skill addresses only the organization question (named chains, routes.go, alice). It says nothing about when to use a constructor vs. a plain adapter shape.
- Ryer's skill addresses only the construction classification question. It does not describe a chain hierarchy; his routes are organized by hoisted variables at the individual middleware level, not by named groups.
- A developer who applies only Edwards's skill writes readable chains but accumulates multi-dep constructor noise inside chain definitions.
- A developer who applies only Ryer's skill writes clean per-route hoisting but has no principle for grouping routes — the "which routes require auth?" audit is still a manual scan of the route block.
- The synthesis failure is that both decisions are separately correct but incomplete: correct construction + poor organization = readable per-middleware but opaque security properties; correct organization + no construction discipline = readable chains but per-chain noise. The complete picture requires both, applied as orthogonal decisions.
