# Test Results: Terraform-Backend-Bootstrap-Problem

## Verdict: PASS (10/10)

## Should_invoke

| ID       | Prompt (abbreviated)                                                 | Result | Notes                                                                                                                    |
| -------- | -------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------ |
| bb-si-01 | "Variables not allowed" error using var.bucket_name in backend block | PASS   | A2 trigger exact match. I section explains the pre-evaluation phase constraint. E steps show the error and the fix.      |
| bb-si-02 | S3 bucket + DynamoDB chicken-and-egg bootstrap problem               | PASS   | A2 trigger exact match. E steps 1-2 give the two-step bootstrap procedure in detail.                                     |
| bb-si-03 | 6 environment directories, DRY backend config without copy-paste     | PASS   | A2 trigger exact match. E step 3 covers partial backend configuration with -backend-config flags and .hcl files.         |
| bb-si-04 | Set up S3 remote backend from scratch in new AWS account             | PASS   | A2 trigger ("setting up a new AWS account and asks what to create first"). E steps 1-2 give the full bootstrap sequence. |

## Should_not_invoke

| ID        | Prompt (abbreviated)                                                 | Result | Notes                                                                                                                                                                                                                               |
| --------- | -------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| bb-sni-01 | Configure Terraform to use Terraform Cloud as backend                | PASS   | B section explicitly says TFC manages backend config through platform UI, bypassing this limitation. Skill correctly defers.                                                                                                        |
| bb-sni-02 | Difference between terraform init and terraform apply                | PASS   | No A2 trigger. Basic command explanation unrelated to backend variable restriction.                                                                                                                                                 |
| bb-sni-03 | How to add state locking with DynamoDB to prevent concurrent applies | PASS   | The DynamoDB table appears in the bootstrap A1 example but the question is about adding locking to an existing setup. A2 triggers don't cover this narrowly. Skill correctly stays silent on a pure locking configuration question. |

## Blurred_boundary

| ID       | Prompt (abbreviated)                                         | Result | Notes                                                                                                                                                                                                                                                                                      |
| -------- | ------------------------------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| bb-bb-01 | Evaluating Terragrunt — only for backend limitation or more? | PASS   | B section acknowledges Terragrunt as the idiomatic solution and E step 4 covers it. Skill correctly handles the broader Terragrunt question by noting it solves more than just backend config.                                                                                             |
| bb-bb-02 | Can I use a data source in the backend block?                | PASS   | B section covers "the variable restriction applies only to the backend block inside terraform {}." A data source reference faces the same restriction — pre-evaluation phase applies to all expressions. Skill handles this correctly.                                                     |
| bb-bb-03 | Destroy the S3 bucket holding Terraform state — safest way?  | PASS   | This is the inverse bootstrap procedure. The I section explains migration in both directions implicitly via the two-step mechanism. Skill can correctly explain: migrate state back to local first (reverse of step 2), then destroy the bucket. The bootstrap mechanics apply in reverse. |
