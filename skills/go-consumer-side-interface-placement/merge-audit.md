# Merge Audit — Go-Consumer-Side-Interface-Placement

## Convergence Map

| Claim                                         | GWTP                     | Johnson           | Verdict               |
| --------------------------------------------- | ------------------------ | ----------------- | --------------------- |
| Consumer package defines the interface        | ✓                        | ✓                 | Confirmed convergence |
| Producer package returns concrete types       | ✓ (implicit)             | ✓ (explicit)      | Confirmed convergence |
| Implicit satisfaction — no implements keyword | ✓                        | ✓                 | Confirmed convergence |
| Import cycle prevention                       | ✓ (explicit)             | ✓ (implicit)      | Confirmed convergence |
| Interface shrinks to actual usage             | ✓                        | ✓                 | Confirmed convergence |
| Inject concrete implementation in main.go     | ✓ (implicit in examples) | ✓ (explicit step) | Confirmed convergence |

## Divergence Map

| Dimension                    | GWTP                                         | Johnson                                           | Resolution in merged skill                        |
| ---------------------------- | -------------------------------------------- | ------------------------------------------------- | ------------------------------------------------- |
| Framing                      | Architectural necessity (cycle prevention)   | Caller-minimal design (exact needs)               | Both framings preserved in I; framing is additive |
| Placement forms              | One form: package-level in consuming package | Two forms: inline on struct + root domain package | Merged I presents all three as a decision table   |
| Root domain package          | Not mentioned                                | Explicitly "legitimate counter-case"              | Added as Placement 3 with trigger                 |
| Interface proliferation risk | Not mentioned                                | Explicit blind spot warning                       | Added to B as Source B failure                    |
| Interface guard assertions   | Mentioned as acceptable documentation        | Not mentioned                                     | Preserved in E step 5                             |
| Architectural context        | App/adapters boundary (DDD)                  | Inline, struct-level, root domain                 | All three contexts in A1                          |

## A2 Sharpness Check

Source A A2: generic placement question, import cycle scenario, mock scenario, code review question.
Source B A2: third-party mock question, interface size question, provider ownership question.

Merged A2 is sharper because:

1. It adds the explicit placement decision table to the trigger description — the reader knows which of three answers to look for before they read the skill.
2. It adds "not this skill when" to distinguish standard library interfaces (defined at provider by design).
3. The trigger condition "you are placing a new interface and are unsure whether it belongs inline, in the consuming package, or in a shared location" directly addresses the three-way ambiguity that neither source alone resolves.

## Quote Accuracy Notes

- GWTP quote: "Because the Go interfaces don't need to be explicitly implemented, we can define them next to the code that needs them. So the application service defines: 'I need a way to cancel a training with given UUID. I don't care how you do it, but I trust you to do it right if you implement this interface.'" — VERIFIED verbatim against go_with_domain_book.md line 3816.
- Johnson quote: "The biggest turning point for me was realizing that my caller should create the interface instead of the callee providing an interface. This makes sense because the caller can declare exactly what it needs." — VERIFIED verbatim against structuring-tests-in-go.md line 143.
- Inline interface example (`YoClient interface { Send(string) error }`) — VERIFIED at structuring-tests-in-go.md lines 154–155.

## Synthesis-Specific Failure Mode Justification

The "placement confusion across all three forms" failure mode is synthesis-specific because:

- GWTP presents only package-level placement (app/adapters boundary), not inline or root-package.
- Johnson presents inline and root-package but focuses on third-party client and small app contexts; his architectural consequence (import cycle prevention) is underdeveloped.
- Neither source alone would trigger a reader to recognize that applying "consumer-side" generically — without distinguishing the three placement contexts — produces interfaces in the wrong location.
- A developer who reads only GWTP would never define inline struct interfaces. A developer who reads only Johnson might not recognize that the root-package case is distinct from the consuming-package case. Only the merged skill gives the three-way decision table that makes the placement choice explicit.
