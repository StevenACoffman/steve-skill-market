---
id: terraform-secrets-in-state
title: "Terraform Secrets Always Land in State: Why Injection Method Doesn't Matter"
description: Invoke when a user asks how to keep secrets out of Terraform state, whether sensitive=true protects secrets, or whether AWS Secrets Manager or environment variables solve the secrets problem in Terraform.
source: "Terraform: Up and Running (3rd Edition), Yevgeniy Brikman, 2022 (O'Reilly)"
---

## R — Reading

> "Any secret you pass into a Terraform resource will end up in the Terraform state file, in plain text. This is a known limitation of Terraform and there's no good workaround for it currently... The first step to securing secrets in Terraform is making sure you never store them in plain text, especially not in your version control system."

## Chapter 6 — Managing Secrets with Terraform

## I — Interpretation

There are three commonly used approaches to injecting secrets into Terraform: environment variables (`TF_VAR_db_password`), encrypted files decrypted at apply time, and centralized secret stores such as AWS Secrets Manager or HashiCorp Vault via a data source. Each of these improves on hardcoding secrets in version control, and each is worth using. But none of them solve the underlying problem: at apply time, Terraform reads the secret value and writes it verbatim into the state file.

When you use an AWS Secrets Manager data source, Terraform calls the Secrets Manager API, retrieves the plaintext value, passes it to `aws_db_instance.password`, and stores that attribute — including its value — in `terraform.tfstate`. The state file is a JSON document containing all resource attributes in plaintext. Anyone who can read the state file can read every secret it describes.

The `sensitive = true` flag, introduced in Terraform 0.14, is a display filter. It suppresses the value in `terraform plan` and `terraform apply` output. It does nothing to the state file. Many engineers encounter it and assume it is a security control; it is not.

The security model that actually works is backend-level: encrypt the state file at rest (S3 with SSE-KMS), restrict who can call `s3:GetObject` on the state bucket via IAM, enable S3 versioning so deleted state can be recovered, and log every access to the bucket via CloudTrail. The state bucket is a high-value target — it contains the configuration of every resource it describes, including every secret those resources use. Treat it with the same access controls as the production database it describes.

## A1 — Past Application

Brikman demonstrates the Secrets Manager pattern, which is the most secure injection approach available in Terraform:

```hcl
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "db-creds"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}

resource "aws_db_instance" "example" {
  username = local.db_creds.username
  password = local.db_creds.password
  # ...
}
```

This avoids secrets appearing in `.tfvars` files, CLI arguments, or environment variables. It still results in the `password` attribute being written to `terraform.tfstate` in plaintext. The state file for the RDS instance will contain `"password": "p@ssw0rd"`. The fix is not to change the injection method further — it is to ensure the S3 bucket storing the state has: `sse_algorithm = "aws:kms"`, a bucket policy denying access to all principals except the Terraform CI role and a named break-glass role, and CloudTrail data events enabled.

## A2 — Future Trigger ★

- A user asks whether marking a variable `sensitive = true` prevents it from appearing in the state file.
- A user has switched from environment variables to AWS Secrets Manager and asks if they are now protected from secrets exposure.
- A security team asks what the Terraform state file contains and whether it needs to be treated as sensitive.
- A user is setting up an S3 backend and asks whether they need encryption if they are already using Secrets Manager.
- A user reports that a secret is visible in their state file despite using `sensitive = true` and asks why.
- A compliance audit asks whether Terraform state files contain plaintext credentials.

## E — Execution

1. Accept that the state file will contain plaintext secrets for any resource that accepts a secret attribute — this is currently unavoidable in Terraform.
2. Use the best available injection method to keep secrets out of version control: prefer AWS Secrets Manager or HashiCorp Vault data sources over environment variables, and environment variables over `.tfvars` files with secret values.
3. Enable server-side encryption on the S3 state bucket using SSE-KMS (not just SSE-S3), so the bucket contents are encrypted at rest and key access is auditable.
4. Restrict `s3:GetObject` and `s3:PutObject` on the state bucket to the specific IAM roles used by CI — deny all other principals including account root where possible.
5. Enable S3 versioning on the state bucket to allow recovery from accidental overwrites or deletions.
6. Enable CloudTrail data events for the state bucket to log every GetObject call — this gives an audit trail for who accessed the state (and thus potentially the secrets) and when.
7. Do not mark `sensitive = true` as a substitute for any of the above; use it to reduce accidental log exposure, but understand it is a display filter only.

## B — Boundary

- This limitation is specific to Terraform's state model and has been an open issue since 2014. It affects all backends (S3, GCS, Azure Blob, Terraform Cloud). Terraform Cloud encrypts state at rest by default, but the state data itself is still stored and Terraform Cloud support staff policies govern access.
- HashiCorp Vault's Terraform provider has some support for dynamic secrets that are rotated after use, which limits the window of exposure in state — but the value is still written to state at the time of apply.
- Resources that do not expose secret values as attributes (e.g., a resource that only takes a secret ARN, not the secret value) do not have this problem. Review the provider schema to understand which attributes are stored.
- The `sensitive` output attribute hides values from `terraform output` display but does not prevent state file storage.
- This advice applies equally to OpenTofu.

## Related Skills

- **[terraform-backend-bootstrap-problem](../terraform-backend-bootstrap-problem/SKILL.md)** — depends on: the S3 backend that holds plaintext secrets must be set up before the secrets concern is addressable; the bootstrap skill covers SSE and versioning configuration of that bucket.
- **[terraform-directory-layout-isolation](../terraform-directory-layout-isolation/SKILL.md)** — combines: per-environment state buckets with separate IAM roles reduce the blast radius of a state file compromise; pair with state bucket encryption for full defense in depth.
