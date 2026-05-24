---
id: terraform-backend-bootstrap-problem
title: 'Terraform Backend Bootstrap Problem: Variables Forbidden, Chicken-and-Egg Setup'
description: Invoke when a user tries to use variables in a backend block and gets an error, asks how to share backend configuration across environments without copy-pasting, or needs to set up an S3+DynamoDB remote backend for the first time.
source: "Terraform: Up and Running (3rd Edition), Yevgeniy Brikman, 2022 (O'Reilly)"
---

## R — Reading

> "There's a bit of a chicken-and-egg problem here: you need to deploy the S3 bucket and DynamoDB table before you can use them as a backend... The trick is to use Terraform to create the S3 bucket and DynamoDB table, and to configure Terraform to store its state locally. Terraform does not allow you to use any variables or references in the backend configuration... you have to hardcode the bucket name, key, and region."

## Chapter 3 — How to Manage Terraform State

## I — Interpretation

The Terraform backend block has a constraint that surprises almost every engineer who encounters it for the first time: no variables, no locals, no data sources, and no references of any kind are permitted inside it. Every value must be a literal string. The reason is architectural — Terraform must initialize the backend before it can evaluate anything else. Backend initialization happens in a separate pre-evaluation phase. Variable resolution, local evaluation, and data source reads all happen after backend init. There is no mechanism to defer backend initialization until variables are resolved.

This creates two distinct problems that engineers hit at different stages of maturity.

The first is the bootstrap problem. The S3 bucket and DynamoDB table that will store Terraform state must exist before Terraform can use them as a backend. But if you write Terraform code to create them, that code also needs a backend — and the bucket does not exist yet. The solution is a deliberate two-step procedure: apply the code that creates the bucket and table using the default local backend (state is stored in `terraform.tfstate` on disk), then add the `backend "s3"` block to the same code and run `terraform init -migrate-state` to move the local state into the newly created bucket.

The second problem is DRY configuration across environments. With five environment directories each requiring a backend block, you cannot factor out the bucket name, region, or key prefix into a shared variable. You can either accept the copy-paste, use partial backend configuration (leave values out of the `backend` block and supply them at `terraform init` time via `-backend-config` flags or a `.hcl` file), or use Terragrunt (which generates backend blocks from environment-level `terragrunt.hcl` config files).

## A1 — Past Application

Brikman's two-step bootstrap procedure for the S3 + DynamoDB backend:

**Step 1** — Create the backend resources with local state:

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute { name = "LockID"; type = "S" }
}
```

Run `terraform apply`. The bucket and table are created, state lives locally.

**Step 2** — Add the backend block and migrate:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"   # must be a literal
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

Run `terraform init -migrate-state`. Terraform moves the local state into the S3 bucket.

The failed attempt that produces an error:

```hcl
terraform {
  backend "s3" {
    bucket = var.bucket_name   # ERROR: Variables not allowed in backend config
    region = var.region        # ERROR: Variables not allowed in backend config
  }
}
```

## A2 — Future Trigger ★

- A user reports a Terraform error on `terraform init` saying variables or references are not allowed in the backend configuration.
- A user asks how to avoid copy-pasting the S3 bucket name and DynamoDB table name into five separate backend blocks.
- A user is setting up a new AWS account for Terraform and asks what to create first and in what order.
- A user asks why they cannot manage their state S3 bucket in the same Terraform config that uses it as a backend.
- A team asks whether Terragrunt is necessary or whether there is a native Terraform solution for DRY backend config.

## E — Execution

1. **Bootstrap step:** Create a separate Terraform configuration (or use the same one initially with local state) that provisions the S3 bucket (versioning on, SSE enabled, `prevent_destroy = true`) and the DynamoDB table (`hash_key = "LockID"`, `billing_mode = "PAY_PER_REQUEST"`). Apply it once with the default local backend.

2. **Migration step:** Add the `backend "s3"` block to the same configuration using hardcoded literal values for bucket, key, region, and dynamodb_table. Run `terraform init -migrate-state`. Confirm migration when prompted.

3. **For DRY config across environments:** Use partial backend configuration. Leave the backend block empty or minimal, and pass environment-specific values at init time:

   ```text
   terraform init \
     -backend-config="bucket=my-state-bucket" \
     -backend-config="key=prod/services/webserver/terraform.tfstate" \
     -backend-config="region=us-east-2" \
     -backend-config="dynamodb_table=terraform-locks"
   ```

   Store these as a `backend.hcl` file per environment directory and run `terraform init -backend-config=backend.hcl`.

4. **For fully automated DRY config:** Evaluate Terragrunt, which generates backend blocks from `terragrunt.hcl` inputs and eliminates the need to pass `-backend-config` manually.

## B — Boundary

- The variable restriction applies only to the `backend` block inside `terraform {}`. All other Terraform constructs — resources, data sources, locals, variables, modules — support full interpolation. The backend block is the single exception.
- This constraint is by design and is unlikely to be relaxed, because it would require Terraform to solve the bootstrapping problem at the language level. Terragrunt is the idiomatic solution for teams that need DRY backends at scale.
- The two-step bootstrap is only needed once per environment. After migration, subsequent applies use the remote backend normally.
- Terraform Cloud and HCP Terraform manage backend configuration through the platform UI, bypassing this limitation. This skill applies to self-managed backends (S3, GCS, Azure Blob, Consul).
- OpenTofu has the same backend variable restriction as of OpenTofu 1.x.

## Related Skills

- **[terraform-directory-layout-isolation](../terraform-directory-layout-isolation/SKILL.md)** — prerequisite for: file-layout isolation creates one backend block per environment; the DRY backend configuration strategies in this skill (partial config, Terragrunt) prevent copy-paste drift across those blocks.
- **[terraform-secrets-in-state](../terraform-secrets-in-state/SKILL.md)** — prerequisite for: the S3 bucket created during bootstrap is the same bucket that must be encrypted and access-controlled to protect plaintext secrets in state.
