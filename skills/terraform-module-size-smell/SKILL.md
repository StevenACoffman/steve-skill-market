---
id: terraform-module-size-smell
title: 'Terraform Module Size as Code Smell: Six Specific Harms of Large Modules'
description: Invoke when a user has a large Terraform module or monolithic configuration, asks when to split a module, or reports that plan/apply is slow, tests are impractical, or changes feel high-risk.
source: "Terraform: Up and Running (3rd Edition), Yevgeniy Brikman, 2022 (O'Reilly)"
---

## R — Reading

> "The larger the Terraform module, the more blast radius of any change... I've seen Terraform modules with hundreds of resources and thousands of lines of code, and they are an absolute nightmare to work with. Each module should be small and focused, doing one thing well, just as with functions in a programming language."

## Chapter 8 — Production-Grade Terraform Code

## I — Interpretation

Brikman identifies six concrete harms that emerge when a Terraform module grows too large, and they interact in a compounding way that is worth understanding as a system.

**Slow plan/apply** is the most visible harm. Terraform contacts the provider API for every resource in a module during plan. A 300-resource module requires 300 API calls minimum. Engineers who wait five minutes for a plan start finding reasons to skip it — or batch changes together to amortize the wait.

**Enormous blast radius** means that a bug in any part of the module can affect every resource in it. A misconfigured security group in a module that also manages RDS instances and S3 buckets puts all of them at risk from a single plan/apply.

**Complex dependency graphs** make the module hard to reason about. Terraform's graph engine handles this, but human reviewers cannot easily trace why a change to one resource is forcing recreation of another in a 300-resource graph.

**Difficult to test** is the harm that becomes acutely painful when teams try to write Terratest tests. Terratest deploys real infrastructure; a test against a 300-resource module can take 20 to 30 minutes and cost significant AWS spend per run. Tests become impractical and eventually stop being written.

**Difficult to review** compounds the slow-plan problem. If the plan output has 50 changes in it because multiple engineers' work was batched, reviewers cannot evaluate individual changes in isolation.

**Difficult to reuse partially** is the subtlest harm but often the biggest organizational one. If a module creates a VPC, three subnets, an ASG, an ALB, an RDS instance, and an S3 bucket, a team that only needs the networking components must either take everything or fork the module. Large modules become single-owner bottlenecks.

These harms interact: the blast radius risk creates risk aversion, which leads engineers to batch changes rather than apply frequently, which makes the module grow larger (because changes accumulate), which increases the blast radius further.

## A1 — Past Application

Brikman describes the canonical antipattern: a single `modules/everything/main.tf` that contains 200+ resources — VPC, subnets (public and private, count-based), EC2 instances, an RDS instance, an S3 bucket, a CloudFront distribution, and more. Every change to any service requires running plan against the entire stack. A bug in the CDN configuration can accidentally affect the database. No Terratest test is fast enough to be practical.

The correct decomposition for the same infrastructure:

```text
modules/
  networking/       # VPC, subnets, route tables, NAT gateways
  compute/          # ASG, launch configuration, ALB, security groups
  data-stores/      # RDS, parameter group, subnet group
  cdn/              # CloudFront distribution, ACM cert, Route 53 records
  iam/              # IAM roles, policies, instance profiles
```

Each module is applied independently. Cross-module dependencies flow through `terraform_remote_state` or module outputs. A bug in `cdn/` cannot destroy `data-stores/`. A Terratest test against `compute/` deploys only the ASG and ALB — typically under 5 minutes.

## A2 — Future Trigger ★

- A user reports that `terraform plan` takes more than two minutes and asks if there is a way to speed it up.
- A user is afraid to change a Terraform resource because the last time they applied, something unexpected was also modified.
- A team tries to write Terratest tests but finds them impractical because the module takes 25 minutes to deploy.
- A user asks when they should extract a resource group into its own module.
- An engineer is inheriting a Terraform codebase and finds a single `main.tf` with several hundred resources.
- A team wants to allow different engineers to own different parts of the infrastructure without stepping on each other.

## E — Execution

1. Identify the bounded responsibilities in the current module. Common natural seams: networking (VPC, subnets, routing), compute (instances, ASG, ALB), data stores (RDS, ElastiCache, S3), identity (IAM roles, policies), and edge/CDN layer. Each seam is a candidate module boundary.
2. Extract one module at a time starting with the lowest-dependency component (usually networking, which nothing else provides but many things consume). Move resources into the new module directory.
3. Use `moved` blocks (see `terraform-moved-block-refactoring`) to tell Terraform about each address change without destroying and recreating the real infrastructure.
4. Wire cross-module dependencies through module outputs and `terraform_remote_state` data sources — avoid passing large numbers of outputs up and back down; each module should expose only what consumers actually need.
5. Add an `examples/` subdirectory to each extracted module with a deployable example that serves as both documentation and Terratest fixture.
6. Set a size heuristic for ongoing use: if a module exceeds roughly 10–15 resources or combines concerns from two different layers of the architecture, treat it as a candidate for extraction.

## B — Boundary

- There is no hard line-count or resource-count threshold in Brikman's book. The heuristic is single responsibility: one module, one bounded concern. A networking module with 20 resources (VPC, 6 subnets, 3 route tables, 3 NAT gateways, 2 VPC endpoints, security group) is appropriate because all resources serve one concern. An 8-resource module that mixes compute and database is not.
- Module decomposition introduces coordination overhead: cross-module deployments must be applied in dependency order, and `terraform_remote_state` requires the providing module to have been applied first. Teams working on a single service who want to apply everything together may prefer a flat structure with Terragrunt `run-all`.
- This applies to modules of all kinds — root modules, child modules, and registry modules. The harms are the same regardless of whether the module is public or private.
- In small teams or early-stage projects, a single module managing an entire service may be acceptable temporarily. The cost of decomposition is paid back quickly once test times and blast radius become painful.

## Related Skills

- **[terraform-moved-block-refactoring](../terraform-moved-block-refactoring/SKILL.md)** — depends on: extracting resources from a large module into smaller modules changes resource addresses; moved blocks are required to prevent destroy/create on all extracted resources.
- **[terraform-no-cluster-app-same-module](../terraform-no-cluster-app-same-module/SKILL.md)** — compares: the EKS/Kubernetes skill is a concrete, provider-constraint-driven forcing function for the same module-boundary principle; use both to cover structural and behavioral reasons to split modules.
- **[terraform-directory-layout-isolation](../terraform-directory-layout-isolation/SKILL.md)** — combines: small focused modules (this skill) populate the `modules/` tree; environment directory layout (that skill) organizes how those modules are called per environment.
- **[terraform-for-each-over-count](../terraform-for-each-over-count/SKILL.md)** — informs: loop constructs inside large modules amplify blast radius; refactoring to for_each and splitting the module are often done together.
