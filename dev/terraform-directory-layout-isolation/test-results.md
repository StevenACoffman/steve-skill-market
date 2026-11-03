# Test Results: Terraform-Directory-Layout-Isolation

## Verdict: PASS (10/10)

## Should_invoke

| ID       | Prompt (abbreviated)                                                                 | Result | Notes                                                                                                                                                    |
| -------- | ------------------------------------------------------------------------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| dl-si-01 | Using workspaces for staging/production — good pattern?                              | PASS   | A2 trigger exact match. I section explains structural vs naming isolation. E steps give concrete layout.                                                 |
| dl-si-02 | Team member ran terraform destroy against prod instead of staging — how to prevent?  | PASS   | A2 trigger ("someone accidentally applied staging config to production"). E steps provide structural prevention via file layout + separate CI IAM roles. |
| dl-si-03 | IAM credentials for staging cannot affect production — how to enforce?               | PASS   | A2 trigger ("how to give different IAM permissions to different environments"). E step 4 covers separate CI IAM roles per directory.                     |
| dl-si-04 | Recommended Terraform directory structure for multiple AWS accounts and environments | PASS   | A2 trigger direct match. E steps provide the full live/stage/prod directory tree.                                                                        |

## Should_not_invoke

| ID        | Prompt (abbreviated)                                                                | Result | Notes                                                                                                                                                               |
| --------- | ----------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| dl-sni-01 | Quickly test a Terraform change without affecting main environment — use workspace? | PASS   | B section explicitly endorses workspaces for ephemeral throwaway test environments. Skill correctly defers.                                                         |
| dl-sni-02 | Pass output values from one Terraform module to another                             | PASS   | No A2 trigger. Cross-module outputs are unrelated to environment isolation strategy.                                                                                |
| dl-sni-03 | Difference between Terraform Cloud workspaces and OSS workspaces                    | PASS   | A2 triggers don't match a platform comparison question. B section notes TFC has RBAC making it different. Skill correctly stays silent on pure platform comparison. |

## Blurred_boundary

| ID       | Prompt (abbreviated)                                                                                 | Result | Notes                                                                                                                                                                                       |
| -------- | ---------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| dl-bb-01 | Using Terraform Cloud with separate workspace per env, own variable set — equivalent to file layout? | PASS   | B section explicitly addresses this: TFC workspace-per-env with RBAC is meaningfully different from OSS workspaces. Nuanced response distinguishing platform from OSS.                      |
| dl-bb-02 | 5 environments, don't want to copy-paste backend config into each directory                          | PASS   | B section explicitly bridges to the backend bootstrap problem skill and Terragrunt. Handled with nuance — acknowledges the duplication tradeoff as intentional.                             |
| dl-bb-03 | HashiCorp docs show workspaces for environments — why do differently?                                | PASS   | A2 trigger explicit ("asks whether HashiCorp's workspace documentation pattern is appropriate"). I section directly addresses the naming-not-isolation argument even against official docs. |
