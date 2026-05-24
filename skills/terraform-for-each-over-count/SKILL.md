---
id: terraform-for-each-over-count
title: 'Terraform for_each vs count: The Index-Shift Cascade Destroy Bug'
description: Invoke when a user is creating multiple resources with count and any resource has a distinct name, ID, or configuration — or when they ask why removing one item destroys seemingly unrelated resources.
source: "Terraform: Up and Running (3rd Edition), Yevgeniy Brikman, 2022 (O'Reilly)"
---

## R — Reading

> "Imagine that somewhere in the middle of those three IAM users, you need to remove one... Terraform deletes [user at index 1] and replaces [user at index 2]... For any resource that has an identity — a name, an ID, any property that makes it distinct — use for_each rather than count."

## Chapter 5 — Terraform Tips and Tricks: Loops, If-Statements, Deployment, and Gotchas

## I — Interpretation

When you write `count = length(var.user_names)`, Terraform tracks each resource by its positional index in the list: `aws_iam_user.example[0]`, `aws_iam_user.example[1]`, `aws_iam_user.example[2]`. That index is the resource's identity in state. The moment you remove an element that is not last — say, removing "neo" at index 1 from a list of three — every item after it shifts down by one. Terraform now sees that `aws_iam_user.example[1]` (which was "neo") should be destroyed and that `aws_iam_user.example[2]` (which was "morpheus") no longer exists. It therefore destroys "morpheus" and recreates it at the new index. In the plan output this looks like two routine replacement operations, making it easy to miss during code review.

The `for_each` mechanism keys resources by a map or set value — typically the resource's actual name. `aws_iam_user.example["neo"]` and `aws_iam_user.example["morpheus"]` are independent entries in state. Removing "neo" from the set produces exactly one destroy operation targeting `aws_iam_user.example["neo"]`. The "morpheus" entry is untouched.

The deeper principle is that Terraform's state model requires a stable, unique key per resource instance. `count` delegates that key to list position, which is fragile. `for_each` delegates it to a value you control, which is stable. This is the identity vs. position distinction.

Reserve `count` for the narrow case where you need N truly identical, interchangeable copies whose set will never shrink — for example, `count = 3` for three identically-configured availability zone subnets with no names that matter. For everything else — and especially for resources with names, ARNs, or distinct configuration — use `for_each`.

## A1 — Past Application

In Brikman's running example, IAM users are created with `count = length(var.user_names)` and the list `["nelly", "neo", "morpheus"]`. Removing "neo" from index 1 triggers the cascade: Terraform destroys the resource at index 1 ("neo") and also destroys and recreates the resource at index 2 ("morpheus" — because its index shifted from 2 to 1). In the plan output both show as normal destroy/create operations. The fix is switching to:

```hcl
variable "user_names" {
  type    = set(string)
  default = ["nelly", "neo", "morpheus"]
}

resource "aws_iam_user" "example" {
  for_each = var.user_names
  name     = each.value
}
```

After the switch, removing "neo" produces a single `destroy` on `aws_iam_user.example["neo"]`. `aws_iam_user.example["nelly"]` and `aws_iam_user.example["morpheus"]` show no changes.

## A2 — Future Trigger ★

- A user has `count`-based security group rules and reports that changing one rule destroys others that appear unrelated.
- A user asks whether `count` or `for_each` is safer for managing a list of S3 buckets, IAM roles, or Route 53 records.
- A user sees an unexpected `destroy` + `create` pair in a plan after removing one item from a variable list and cannot explain why both are appearing.
- A user is migrating from `count` to `for_each` and needs to understand the state key change and whether `moved` blocks are required.
- A team is reviewing a plan in CI and wants to know how to spot a cascade destroy before applying.

## E — Execution

1. Change the variable type from `list(string)` to `set(string)` (or `map(any)` if each resource needs distinct attributes beyond its name).
2. Replace `count = length(var.user_names)` with `for_each = var.user_names` and update any `var.user_names[count.index]` references to `each.value` (or `each.key` / `each.value` for map-valued inputs).
3. If the resource already exists in state under `count` keys (e.g., `aws_iam_user.example[0]`), add `moved` blocks to migrate each instance to its new `for_each` key (e.g., `aws_iam_user.example["nelly"]`) before applying, to avoid destroy/create on all existing instances.
4. Run `terraform plan` and verify that the output shows only the expected changes and no spurious destroy/create pairs on unchanged resources.

## B — Boundary

- `count` remains appropriate for truly stateless, identical resources with a fixed cardinality that will never shrink — e.g., `count = 3` for three identical NAT gateways in fixed AZs where no element has a name you care about.
- `for_each` requires that keys be known at plan time. If the set depends on a resource attribute that is not known until apply (e.g., the ID of a resource being created in the same plan), Terraform will error with "The 'for_each' value depends on resource attributes that cannot be determined until apply." In that case `count` with a known length, or restructuring into separate modules applied in sequence, may be required.
- This skill applies to Terraform 0.12.6+ (`for_each` on resources) and Terraform 0.13+ (`for_each` on modules). OpenTofu has the same behavior.
- The state key migration problem when switching from `count` to `for_each` is addressed by the `terraform-moved-block-refactoring` skill.

## Related Skills

- **[terraform-moved-block-refactoring](../terraform-moved-block-refactoring/SKILL.md)** — prerequisite for: migrating an existing count-based resource to for_each requires moved blocks per instance to avoid destroy/create on all existing infrastructure.
- **[terraform-module-size-smell](../terraform-module-size-smell/SKILL.md)** — informs: count-based loops in large modules compound blast radius; switching to for_each is often part of the same refactor that splits a module.
- **[terraform-directory-layout-isolation](../terraform-directory-layout-isolation/SKILL.md)** — informs: stable for_each keys become especially important when the same module is reused across multiple environment directories.
