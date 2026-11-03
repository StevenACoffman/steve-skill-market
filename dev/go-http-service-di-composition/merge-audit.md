# Merge Audit — Go-Http-Service-Di-Composition

## Convergence Map

| Claim                                         | Edwards  | Ryer     | rednafi (third source) | Verdict                                                  |
| --------------------------------------------- | -------- | -------- | ---------------------- | -------------------------------------------------------- |
| All dependencies must be explicit, not global | ✓        | ✓        | ✓                      | Confirmed convergence (three sources)                    |
| Testability is the primary motivation         | ✓        | ✓        | ✓                      | Confirmed convergence                                    |
| main() constructs and wires dependencies      | ✓        | ✓        | ✓                      | Confirmed convergence                                    |
| No DI framework needed                        | implicit | implicit | ✓ (explicit)           | rednafi adds the explicit anti-framework argument        |
| Compiler enforces the dependency graph        | implicit | implicit | ✓ (explicit)           | rednafi contributes "call order is the dependency graph" |
| Global state prevents t.Parallel()            | ✓        | ✓        | n/a                    | Confirmed convergence                                    |

## Divergence Map

| Dimension                                | Edwards                                                                | Ryer                                                      | Resolution                                                   |
| ---------------------------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------ |
| Architectural scope                      | Handler layer (struct fields, per-request access)                      | Entrypoint layer (run() parameters, startup testability)  | Both layers preserved; presented as composing, not competing |
| Mechanism                                | Struct receiver (handlers are methods on `*application`)               | Function parameter injection (OS fundamentals into run()) | Different mechanisms at different levels; both correct       |
| Testing target                           | Handler logic via newTestApplication(t)                                | Startup logic via go run(ctx, ...) directly               | Both testing strategies documented in A2 and E               |
| Specific quote                           | "a neat way" (source text) vs "the cleanest way" (SKILL.md paraphrase) | All quotes verified verbatim                              | Corrected to "a neat way" in merged R section                |
| signal.NotifyContext placement           | Not addressed                                                          | Inside run(), not main() — subtle placement rule          | Added to B as Source B failure                               |
| Signature drift (run() parameter growth) | Not addressed                                                          | Acknowledged without hard limit                           | Added to B as Source B failure                               |

## A2 Sharpness Check

Source A A2: new service with multiple shared dependencies; retrofitting globals; PR review for function-argument handler pattern; integration test mock setup; split-struct evaluation.
Source B A2: os.Getenv in main breaks parallel; flag.Parse shared state causes test panic; CLI tool with main() locking out table-driven tests; slow sequential test suite.

Merged A2 is sharper because:

1. Names three distinct testing scenarios (handler-level mocks, end-to-end run() calls, getenv isolation) — neither source alone provides all three.
2. The "flag redefined" panic is the most concrete symptom of the problem Ryer solves; adding it as a trigger makes the skill self-selecting for the right problem.
3. The framing "starter → you need both patterns simultaneously" is the synthesis insight that neither source's A2 expresses.

## Quote Accuracy Notes

- Edwards quote in source SKILL.md: "The cleanest way to make the logger..." — this is a paraphrase. Source text (lets-go.epub, 03.03-dependency-injection.xhtml) says: "a neat way to inject dependencies is to put them into a custom application struct, and then define your handler functions as methods against application." Corrected in merged R section.
- Edwards quote "chicken-and-egg problem": Not found verbatim in epub source. Excluded from merged R; the structural explanation in I covers the concept accurately without the unverified phrase.
- Ryer quote ("The run function is like the main function..."): VERIFIED verbatim against matryer source line 179.
- Ryer quote ("If you keep away from any global scope data..."): VERIFIED verbatim against matryer source line 217.
- Ryer quote (`getenv` beats `t.SetEnv`): VERIFIED verbatim against matryer source line 267.

## Synthesis-Specific Failure Mode Justification

"Treating run() and the application struct as alternatives rather than layers" is synthesis-specific because:

- Neither source presents both patterns together or explains how they compose.
- Edwards's book does not mention run() or entrypoint-level dependency injection.
- Ryer's article does not describe the application struct pattern or handler-level mock injection.
- A developer reading either source in isolation would have no reason to think the other pattern exists, let alone that they compose.
- The failure mode — accumulating handler dependencies as locals in run(), or leaving startup in main() — is invisible until the developer needs both kinds of test simultaneously and finds one is blocked.
- rednafi's "call order is the dependency graph" independently confirms the composition: run() constructs the application struct; the struct carries dependencies to handlers; both are part of the same explicit, ordered, compiler-checked graph.

## Rednafi Third-Source Provenance Note

rednafi's manual-dependency-injection skill independently confirms:

1. "DI basically means passing values into a constructor instead of creating them inside it" — the core principle both Edwards and Ryer implement.
2. "The call order is the dependency graph" — maps directly to Edwards's struct assembly and Ryer's run() parameter list.
3. Anti-DI-framework argument — "No reflection, no generated code, no global state" — consistent with both sources' explicit wiring philosophy.
4. "If a constructor changes, the compiler points straight at every broken call" — describes the compile-time safety both sources rely on.
   rednafi is credited in the R convergence note and the I section but does not contribute distinct A1 cases or E steps to the merged skill.
