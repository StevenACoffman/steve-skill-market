# Merge Audit: Structural-Diagnosis-Smells-Depth

## Sources

- Source A: `fowler-refactoring/fowler-code-smells` (Fowler & Beck, Refactoring Ch. 3)
- Source B: `jousterhout/deep-module-classitis-diagnosis` (Ousterhout, APoSD Ch. 4)
- Phase 1 input: `candidates/pair-021-phase1.md`

## R — Quote Verification

| Quote                                                                      | Source                                           | Verification Status                                                           |
| -------------------------------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------------------------- |
| "Smells, you say..." / "no set of metrics rivals informed human intuition" | Fowler & Beck, Ch. 3 (lines 3944–3981 in source) | Verified in Phase 1.5 audit; quote is condensed from longer passage, accurate |
| "The best modules are those whose interfaces are much simpler..."          | Ousterhout, Ch. 4 (lines 787–793, 876–883)       | Verified exact match in Phase 1.5 audit                                       |
| Classitis definition                                                       | Ousterhout, Ch. 4 (lines 997–1011)               | Verified exact match in Phase 1.5 audit                                       |

## A1 Case Attribution

| Case                              | Attribution                                                                                               | Verification Status                                                                                             |
| --------------------------------- | --------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Feature Envy / PaymentGateway     | Fowler's Feature Envy pattern (Ch. 3); specific PaymentGateway framing is the skill author's illustration | Noted in Phase 1.5 — pattern confirmed at lines 4199–4204; framing is pedagogical, not a direct Fowler case     |
| Java three-object file open       | Ousterhout, Ch. 4 (lines 1009–1014)                                                                       | Verified: "to open a file in order to read serialized objects from it, you must create three different objects" |
| Unix I/O (mentioned in I section) | Ousterhout, Ch. 4 (lines 932–934)                                                                         | Verified: "Five basic kernel calls have not changed"                                                            |

**Note on Case 1:** The PaymentGateway framing is a pedagogical illustration, not a verbatim Fowler case. The merged SKILL.md uses it as a worked example constructed from Fowler's Feature Envy pattern definition, which is accurate to the source material.

## Convergence Claim

Both authors independently identify the same meta-failure: mechanical application of their own vocabulary systems becomes counterproductive dogma. Fowler warns against "smell police"; Ousterhout warns against classitis corrective becoming large-class dogma. This convergence is genuine — it is each author identifying the same failure mode in their own vocabulary system, not surface agreement.

## Two-Pass Workflow

The key synthesis — smell scan for candidate identification, depth ratio for treatment validation — is explicitly encoded in the I section, E section (Steps 1–3), and the A2 trigger conditions. The override rule (depth overrides smell when split produces shallow modules) is the non-obvious synthesis insight that neither source provides.

## RIA++ Gate Check

| Gate                                                           | Status | Evidence                                                                                                         |
| -------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------- |
| R: attributed quotes + convergence note                        | PASS   | Both authors quoted; convergence note in R section                                                               |
| I: unified framework, no "Author A says/B says"                | PASS   | I section encodes two-pass workflow without attribution framing                                                  |
| A1: one case per book, different domains                       | PASS   | Case 1 = payment module / method-class level (Fowler); Case 2 = Java library API / API design level (Ousterhout) |
| A2: sharper than union; "instead of X or Y, use this when"     | PASS   | Explicit "instead of" condition; distinguishes when to use this vs. source skills alone                          |
| E: reconciled with conditionals, not longer than longer source | PASS   | 6 steps; source A had 5 steps; source B had 6 steps; merged is equivalent to longer                              |
| B: source A failures, source B failures, synthesis-specific    | PASS   | Three labeled sections; synthesis failure explicitly names smell-without-depth failure                           |
| B: contradictions surfaced                                     | PASS   | Override rule and testability exception both explicitly flag where depth and smell conflict                      |

## Notes

- Scale awareness is a key organizational insight: smells at method/class scope; depth at class/module/API scope. The two tools cover different levels of abstraction and are often complementary without conflict.
- The synthesis-specific failure mode (extract Large Class into shallow sub-classes that always appear together) is the most actionable contribution — it names the exact mistake a developer who knows only Fowler would make, and explains why depth validation would have caught it.
