# Test Results: Terraform-Module-Size-Smell

## Verdict: PASS (10/10)

## Should_invoke

| ID       | Prompt (abbreviated)                                                                 | Result | Notes                                                                                                   |
| -------- | ------------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------- |
| ms-si-01 | terraform plan takes 8 minutes, module has 250 resources                             | PASS   | A2 trigger exact match. I section names slow plan as harm #1. E steps give the decomposition procedure. |
| ms-si-02 | Nervous about small changes because plan shows dozens of unrelated potential changes | PASS   | A2 trigger exact match. I section names enormous blast radius as harm #2. E steps address extraction.   |
| ms-si-03 | Terratest tests take 25 minutes and cost $50 per run                                 | PASS   | A2 trigger exact match. I section names 20-30 minute test cycle as harm #4 ("difficult to test").       |
| ms-si-04 | When should I extract a Terraform resource group into its own module?                | PASS   | A2 trigger exact match. E step 6 gives the heuristic (10-15 resources, single responsibility).          |

## Should_not_invoke

| ID        | Prompt (abbreviated)                                        | Result | Notes                                                                           |
| --------- | ----------------------------------------------------------- | ------ | ------------------------------------------------------------------------------- |
| ms-sni-01 | How to publish a Terraform module to the Terraform Registry | PASS   | No A2 trigger. Module publishing is unrelated to module size and decomposition. |
| ms-sni-02 | Difference between root module and child module             | PASS   | No A2 trigger. Terminology question unrelated to module size harms.             |
| ms-sni-03 | How to pass a list of objects as a variable to a module     | PASS   | No A2 trigger. Variable type syntax is unrelated to module size.                |

## Blurred_boundary

| ID       | Prompt (abbreviated)                                                                             | Result | Notes                                                                                                                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ms-bb-01 | Just getting started, 20 resources in a single main.tf — split now or wait?                      | PASS   | B section explicitly says "In small teams or early-stage projects, a single module may be acceptable temporarily." Skill gives nuanced judgment: decompose when pain appears, not prematurely. |
| ms-bb-02 | Splitting creates dependency ordering and cross-module coordination — harder than one big apply? | PASS   | B section explicitly acknowledges "coordination overhead" and mentions Terragrunt run-all as mitigation. Skill handles the tradeoff honestly.                                                  |
| ms-bb-03 | Another team wants to reuse only the networking part of my large module                          | PASS   | A2 trigger — partial reuse harm is harm #6 explicitly named ("difficult to reuse partially"). This directly invokes the skill and leads to module extraction recommendation.                   |
