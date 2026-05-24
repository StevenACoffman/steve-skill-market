---
id: terraform-moved-block-refactoring
title: 'Terraform moved Block: Safe Rename and Module Extraction Without Destroy'
description: Invoke when a user wants to rename a Terraform resource, move a resource into a module, or restructure module layout without destroying and recreating live infrastructure.
source: "Terraform: Up and Running (3rd Edition), Yevgeniy Brikman, 2022 (O'Reilly)"
---

## R — Reading

> "If you want to rename a resource or move it into a module, you need to use a moved block to tell Terraform about the rename; otherwise, Terraform will delete the original and create a replacement. Without a moved block, Terraform interprets the rename as delete-old + create-new, destroying live infrastructure."

## Chapter 5 — Terraform Tips and Tricks: Loops, If-Statements, Deployment, and Gotchas

## I — Interpretation

Terraform's state model tracks every resource by its address — the path through modules and the resource type and name. When you rename `resource "aws_security_group" "instance"` to `resource "aws_security_group" "web_server"`, Terraform sees an unknown new resource (`web_server`) and a resource to delete (`instance`). It does not infer intent. The plan shows one destroy and one create, which for a stateful resource — an Elastic IP, an RDS instance, an S3 bucket, a KMS key — means data loss or service interruption.

The `moved` block, available since Terraform 1.1, tells Terraform explicitly that a resource at one address is the same real-world resource as a resource at another address. When Terraform plans, it reads the `moved` block and updates the state mapping before computing the diff. The plan output shows a note like `# aws_security_group.instance has moved to module.webserver_cluster.aws_security_group.instance` with no destroy or create — the real infrastructure is unchanged.

`moved` blocks are stackable. A multi-step refactor — rename a resource, move it into a module, then rename the module — can be expressed as three `moved` blocks applied in sequence within a single plan. This is far safer than running `terraform state mv` multiple times sequentially, which is imperative and not code-reviewable.

The lifecycle of a `moved` block is different from any other Terraform construct. It must persist in the codebase until every environment (staging, production, DR, etc.) has applied the plan that contains it. Once all environments have applied, the `moved` block can be removed in a follow-up commit. Removing it too early will cause Terraform to treat the old address as a new resource to create on the next plan for any environment that has not yet applied.

## A1 — Past Application

Brikman's example moves a root-level security group into a module during a refactor that extracts the web server cluster into `modules/services/webserver-cluster/`:

```hcl
# Before refactor: resource defined at root
# resource "aws_security_group" "instance" { ... }

# After refactor: resource is inside the module
# module "webserver_cluster" {
#   source = "../../modules/services/webserver-cluster"
# }

# Add this moved block to the root module:
moved {
  from = aws_security_group.instance
  to   = module.webserver_cluster.aws_security_group.instance
}
```

`terraform plan` output:

```text
# aws_security_group.instance has moved to
# module.webserver_cluster.aws_security_group.instance
```

No destroy. No create. The real security group is unchanged. On `terraform apply`, state is updated to reflect the new address.

A stacked example where a resource is both renamed and moved:

```hcl
moved {
  from = aws_security_group.instance
  to   = aws_security_group.web_server
}

moved {
  from = aws_security_group.web_server
  to   = module.webserver_cluster.aws_security_group.web_server
}
```

## A2 — Future Trigger ★

- A user wants to rename a Terraform resource (e.g., `aws_iam_user.admin` to `aws_iam_user.ops_admin`) without destroying and recreating it.
- A user is extracting resources from a root module into a reusable module and asks how to avoid downtime.
- A user is migrating from `count`-based resources to `for_each` and needs to map the old positional state keys to the new identity keys.
- A user asks whether `terraform state mv` is still the recommended approach for renaming resources.
- A team is doing a large infrastructure refactor and asks how to stage it safely across multiple environments.

## E — Execution

1. Make the code change first: rename the resource, move it into a module, or extract the module. Do not apply yet.
2. Add a `moved` block in the configuration that maps the old address to the new address. For a root-level resource being moved into a module: `moved { from = aws_resource_type.old_name; to = module.new_module.aws_resource_type.old_name }`.
3. Run `terraform plan`. Confirm that the output shows only `# <old_address> has moved to <new_address>` entries with no destroy/create operations for the moved resources. Any unexpected destroy operations indicate a missing or incorrect `moved` block.
4. Apply the plan. Terraform updates the state file to use the new addresses. The real infrastructure is untouched.
5. Leave the `moved` block in the codebase until all environments (staging, production, any additional environments) have applied the plan. Only then remove the `moved` block in a follow-up commit.
6. For a `count`-to-`for_each` migration, write one `moved` block per instance: `moved { from = aws_iam_user.example[0]; to = aws_iam_user.example["nelly"] }`, etc.

## B — Boundary

- `moved` blocks require Terraform 1.1 or later. For Terraform 0.x or early 1.0, use `terraform state mv` as the imperative equivalent. `terraform state mv` achieves the same state update but leaves no reviewable artifact in code.
- `moved` blocks handle only address changes within the same provider. Moving a resource from one provider to another (e.g., from `aws_s3_bucket` to a different AWS account's provider) requires a destroy/create or a manual import.
- The `moved` block does not work across state files. If you are splitting one module into two modules with separate state files, you need to use `terraform state mv` to move the resource to the new state file, not a `moved` block.
- For resources where the real infrastructure change is intentional (e.g., you want a new RDS instance with a new name), do not use a `moved` block — the destroy/create is correct.
- Removing a `moved` block prematurely (before all environments have applied) will cause Terraform to plan a new create for the resource at the old address on the next run in environments that haven't applied yet. Keep `moved` blocks until all environments are up to date.
- OpenTofu supports `moved` blocks with the same semantics as Terraform 1.1+.

## Related Skills

- **[terraform-for-each-over-count](../terraform-for-each-over-count/SKILL.md)** — prerequisite for: count-to-for_each migration requires one moved block per resource instance to map positional keys to identity keys without destroying live resources.
- **[terraform-module-size-smell](../terraform-module-size-smell/SKILL.md)** — prerequisite for: decomposing a large module into smaller modules changes resource addresses; moved blocks are the mechanism that makes this refactor safe.
- **[terraform-no-cluster-app-same-module](../terraform-no-cluster-app-same-module/SKILL.md)** — informs: separating a combined cluster+app module into two modules relocates resource addresses; moved blocks handle the state migration during that split.
