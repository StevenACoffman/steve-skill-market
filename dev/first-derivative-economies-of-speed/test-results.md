# First-Derivative Thinking: Economies of Speed — Phase 4 Test Results

**Overall**: PASS

| Prompt ID | Category          | Expected           | Result | Notes                                                                                                                                                                                                    |
| --------- | ----------------- | ------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp01      | should_invoke     | INVOKE             | PASS   | Fixed annual cloud budget is textbook Economies of Scale absolute thinking applied to a per-second billing platform. A2 trigger: "budgets cloud as a fixed annual line item."                            |
| tp02      | should_invoke     | INVOKE             | PASS   | Percentage migrated is an absolute position metric. A2 trigger: "migration is measured by percentage of servers migrated."                                                                               |
| tp03      | should_invoke     | INVOKE             | PASS   | Per-instance price comparison treats cloud as a capital asset; the A2 trigger fires on "comparing per-unit server prices across providers."                                                              |
| tp04      | should_invoke     | INVOKE             | PASS   | Project/finish-line mental model is Economies of Scale thinking. A2 trigger: "frames cloud adoption as a one-time transformation project with a target end state."                                       |
| tp05      | should_invoke     | INVOKE             | PASS   | Reserved vs. consumption billing is the canonical first-derivative vs. Economies of Scale cultural tension. A2 trigger: "resists per-consumption billing and insists on reserved capacity."              |
| tp06      | should_invoke     | INVOKE             | PASS   | Features per sprint is an absolute count. A2 trigger: "measures developer productivity in lines of code or features completed rather than cycle time or throughput rate."                                |
| tp07      | should_not_invoke | SKIP               | PASS   | Kubernetes vs. managed container service is a platform lock-in decision. No A2 trigger fires; skill correctly abstains.                                                                                  |
| tp08      | should_not_invoke | SKIP               | PASS   | This triggers principles-quality-checklist (opposite test, wishful thinking), not first-derivative. No A2 trigger fires.                                                                                 |
| tp09      | should_not_invoke | SKIP               | PASS   | Serverless vs. containers is a runtime architecture question with no Economies of Speed framing trigger.                                                                                                 |
| tp10      | should_not_invoke | SKIP               | PASS   | SOC 2 security policy is outside the A2 trigger conditions entirely.                                                                                                                                     |
| tp11      | blurred_boundary  | INVOKE             | PASS   | Reserved vs. on-demand for a fast-growing startup fires the "resists per-consumption billing" trigger; the rate-vs-absolute framing is the primary analytical lens even if cost modeling supplements it. |
| tp12      | blurred_boundary  | INVOKE (secondary) | PASS   | Primary signal is value-gap-migration-metrics; first-derivative contributes the absolute-vs-rate diagnostic. Correctly secondary here.                                                                   |

## Rework Notes

None. All 12 prompts produce the correct invoke/skip decision. The blurred-boundary cases are correctly handled: tp11 invokes primarily (rate vs. absolute billing decision), tp12 invokes secondarily with value-gap as the primary skill.
