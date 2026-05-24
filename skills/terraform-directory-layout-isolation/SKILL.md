---
id: terraform-directory-layout-isolation
title: 'Terraform Environment Isolation: File Layout Over Workspaces'
description: Invoke when a user asks how to manage multiple environments (staging, production) with Terraform, whether workspaces are sufficient for environment isolation, or how to prevent a staging change from reaching production.
source: "Terraform: Up and Running (3rd Edition), Yevgeniy Brikman, 2022 (O'Reilly)"
---

## R — Reading

> "The whole point of having separate environments is that they are isolated from each other, so if you are managing them all from a single Terraform working directory, you're breaking that isolation... Workspaces do not provide strong isolation between environments... if you make a mistake, it's very easy to accidentally deploy to the wrong workspace. I recommend using file layout for isolating environments."

## Chapter 3 — How to Manage Terraform State

## I — Interpretation

Terraform workspaces are a naming mechanism, not an isolation mechanism. When you run `terraform workspace new prod`, Terraform stores state in a separate key within the same S3 bucket, using the same backend configuration, the same IAM credentials, and the same variable files. The only thing that changes is the string returned by `terraform.workspace`. There is no structural barrier between environments.

The consequence is that credential isolation — keeping staging and production runs from sharing access — is impossible with workspaces. A developer who has production credentials, selects the wrong workspace, and runs `terraform destroy` will destroy production. The workspace name is a runtime string that Terraform does not validate against the caller's intent; it accepts whatever the developer types.

File layout isolation is structural. Each environment lives in its own directory (`live/stage/`, `live/prod/`) with its own `backend` block pointing to a separate S3 bucket and a separate state key. In CI, the deployment pipeline for staging uses one IAM role; the pipeline for production uses a different one with a higher approval gate. A developer cannot run the production pipeline from the staging directory — the state file literally does not exist there. The isolation is enforced by the file system and the CI configuration, not by developer discipline.

The practical recommendation is to use workspaces only for short-lived, throwaway test environments where a single engineer is rapidly iterating on new infrastructure code. For anything that maps to a named, durable environment (staging, production, DR), use file layout.

## A1 — Past Application

Brikman's canonical antipattern: a single `main.tf` uses `terraform.workspace == "prod" ? "m4.large" : "t2.micro"` to control instance sizing. The backend block is shared with `key = "workspaces/terraform.tfstate"`. All engineers share the same AWS credentials. The failure mode: a developer runs `terraform workspace select prod && terraform destroy` without realizing the workspace was switched. Production is destroyed. No structural control prevented it.

The correct layout for the same two environments:

```text
live/
  stage/
    services/webserver-cluster/
      main.tf          # backend "s3" { key = "stage/services/.../terraform.tfstate" }
      terraform.tfvars # instance_type = "t2.micro"
  prod/
    services/webserver-cluster/
      main.tf          # backend "s3" { key = "prod/services/.../terraform.tfstate" }
      terraform.tfvars # instance_type = "m4.large"
```

CI enforces separate IAM roles per directory: the staging pipeline assumes `arn:aws:iam::STAGING_ACCOUNT:role/TerraformStaging`; the production pipeline assumes a separate role requiring manual approval.

## A2 — Future Trigger ★

- A user asks whether HashiCorp's workspace documentation pattern is appropriate for their staging/production setup.
- A user reports that someone accidentally applied staging configuration to production and asks how to prevent recurrence.
- A user asks how to give different IAM permissions to different environments in Terraform.
- A team is evaluating whether to add a new environment and whether to use a workspace or a new directory.
- A user asks why their `terraform.workspace` conditional expressions are getting complex and hard to maintain.

## E — Execution

1. Create a `live/` directory tree with a subdirectory per environment: `live/stage/` and `live/prod/`. Mirror the same service structure under each (e.g., `live/stage/services/webserver-cluster/`, `live/prod/services/webserver-cluster/`).
2. In each environment directory, write a distinct `backend` block with a unique `key` path and, ideally, a separate S3 bucket per environment (or at minimum, IAM bucket policies that restrict each CI role to its own prefix).
3. Store environment-specific variable values in a `terraform.tfvars` or `*.auto.tfvars` file in each directory — no `terraform.workspace` conditionals in the shared module code.
4. In CI, configure the staging pipeline to assume an IAM role with staging-only permissions, and the production pipeline to assume a separate role, gated behind a manual approval step or merge-to-main trigger.
5. Remove or stop using any workspace-selection steps from CI pipelines that manage durable environments.

## B — Boundary

- Workspaces are appropriate for creating ephemeral, short-lived test environments — e.g., a developer spins up a workspace to test a refactor, then destroys it. The risk is low because the workspace is expected to be deleted.
- This file layout approach requires each environment directory to have its own copy of backend configuration. The duplication is an intentional tradeoff for isolation. The `terraform-backend-bootstrap-problem` skill addresses how to reduce that duplication using partial backend configuration or Terragrunt.
- In Terragrunt, the equivalent pattern is `terragrunt.hcl` files per environment that generate backend blocks from variables — this achieves file-layout isolation without copy-pasting the backend block.
- This pattern assumes infrastructure code lives in a monorepo or a structured multi-repo setup. Teams using Terraform Cloud or HCP Terraform can achieve similar isolation through workspace-per-environment with separate variable sets and separate variable sets with RBAC — but that is a platform capability, not native OSS Terraform workspace isolation.

## Related Skills

- **[terraform-backend-bootstrap-problem](../terraform-backend-bootstrap-problem/SKILL.md)** — informs: file-layout isolation requires a backend block per environment directory; the bootstrap skill explains how to provision those backends and keep them DRY.
- **[terraform-secrets-in-state](../terraform-secrets-in-state/SKILL.md)** — combines: per-environment state buckets with separate IAM roles (this skill) pair with state bucket encryption and access controls (secrets skill) to fully protect secrets at rest.
- **[terraform-module-size-smell](../terraform-module-size-smell/SKILL.md)** — combines: environment directory layout and small focused modules are complementary — the directory tree isolates environments while module decomposition isolates concerns within each environment.
- **[terraform-no-cluster-app-same-module](../terraform-no-cluster-app-same-module/SKILL.md)** — informs: the two-apply separation required for EKS cluster + app follows the same isolation principle that drives per-environment directory layout.
