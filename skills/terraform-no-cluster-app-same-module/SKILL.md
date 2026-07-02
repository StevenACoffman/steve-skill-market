---
name: terraform-no-cluster-app-same-module
description: |
  Invoke when a user is deploying an EKS cluster and Kubernetes resources (Deployments, Services, etc.) in the same Terraform module, gets a provider configuration error referencing cluster outputs, or asks why depends_on doesn't fix the Kubernetes provider initialization failure.
---
# Terraform: Never Mix EKS Cluster Provisioning and Kubernetes App Deployment in One Module

## R — Reading

> "The problem is that Terraform processes providers and resources in two separate phases... you can't have providers configured dynamically from a dependency in the same module. The Kubernetes provider requires the EKS cluster endpoint to be known at plan time."

## Chapter 7 — Working with Multiple Providers

## I — Interpretation

Terraform's execution model has two distinct phases: provider configuration and resource planning/creation. Provider blocks are evaluated and providers are initialized during the first phase, before any resource is created, read, or destroyed. This means that any value referenced in a provider block must be known before the plan begins — it cannot come from a resource that Terraform will create later in the same apply.

The EKS + Kubernetes problem is a direct collision with this constraint. The `kubernetes` provider requires a `host` (the API server endpoint) and a `cluster_ca_certificate` to initialize. These values are outputs of `aws_eks_cluster`, which does not exist until Terraform creates it. Even if you add `depends_on = [aws_eks_cluster.example]` to every Kubernetes resource, the provider initialization still runs first. `depends_on` controls resource creation ordering; it has no effect on provider initialization ordering.

The result is a cryptic error at plan time, or a plan that succeeds but fails on apply because the provider cannot reach an endpoint that does not yet exist. Engineers commonly reach for `depends_on` when they first encounter this, which makes it worse — the error message does not change, and the root cause (provider config phase) is not obvious from the error text.

The correct solution is architectural separation: two modules, two separate `terraform apply` calls. The first module creates the EKS cluster and outputs its endpoint, certificate, and token data. The second module receives those outputs as input variables, configures the `kubernetes` provider from them, and deploys application resources. Since the second module only runs after the first has fully applied, the provider configuration values are fully resolved when the `kubernetes` provider initializes.

## A1 — Past Application

Brikman shows the antipattern directly — the code that produces the error:

```hcl
# antipattern: EKS cluster + Kubernetes app in same module
resource "aws_eks_cluster" "example" {
  name     = "my-cluster"
  role_arn = aws_iam_role.cluster.arn
  vpc_config { subnet_ids = var.subnet_ids }
}

provider "kubernetes" {
  # ERROR: aws_eks_cluster.example.endpoint is unknown at provider init time
  host = aws_eks_cluster.example.endpoint
  cluster_ca_certificate = base64decode(
    aws_eks_cluster.example.certificate_authority[0].data
  )
}

resource "kubernetes_deployment" "app" {
  metadata { name = "my-app" }
  spec { ... }
}
```

The correct structure splits this into two modules:

**Module 1: `modules/eks-cluster/`**

```hcl
resource "aws_eks_cluster" "example" { ... }

output "cluster_endpoint" {
  value = aws_eks_cluster.example.endpoint
}
output "cluster_ca_certificate" {
  value = aws_eks_cluster.example.certificate_authority[0].data
}
```

**Module 2: `modules/k8s-apps/`** — only applied after Module 1 is complete:

```hcl
variable "cluster_endpoint" {}
variable "cluster_ca_certificate" {}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  # token or exec auth from aws-iam-authenticator
}

resource "kubernetes_deployment" "app" { ... }
```

## A2 — Future Trigger ★

- A user gets an error that the Kubernetes provider cannot be configured because a cluster endpoint is unknown or null during plan.
- A user asks why `depends_on` does not fix the provider initialization error in a module that creates an EKS cluster and deploys apps.
- A user wants to deploy both the EKS cluster and their application in a single `terraform apply` and asks if it is possible.
- A user is designing the Terraform module layout for a Kubernetes-based application and asks how to structure cluster management vs. application deployment.
- The same pattern appears with GKE (Google Kubernetes Engine) and the `google` + `kubernetes` providers, or with AKS and the `azurerm` + `kubernetes` providers.

## E — Execution

1. Separate the Terraform code into two distinct modules (or root configurations): one for cluster infrastructure (`eks-cluster/`) and one for Kubernetes application resources (`k8s-apps/`).
2. In the cluster module, export the values the Kubernetes provider needs: `cluster_endpoint`, `cluster_ca_certificate`, and any token or exec configuration. Use module outputs or `terraform_remote_state`.
3. In the application module, declare those values as input variables and configure the `kubernetes` provider from them — all values will be fully resolved because the cluster module has already been applied.
4. Apply in order: `cd eks-cluster && terraform apply` first, then `cd k8s-apps && terraform apply`. Automate this ordering in CI using a pipeline with sequential steps and output passing.
5. If using Terragrunt, use `dependency` blocks to express the ordering and automatically pass outputs from the cluster module as inputs to the application module.

## B — Boundary

- This constraint applies to any provider whose configuration depends on a resource created in the same module: `kubernetes` after `aws_eks_cluster`, `helm` after EKS, `vault` after a Vault server provisioned in the same module. The pattern is general.
- If the cluster already exists (e.g., it was created by a separate team or in a prior apply), there is no issue — the `kubernetes` provider can be configured from a data source lookup of the existing cluster, since data sources are read at plan time and the cluster endpoint is already available.
- `depends_on` at the resource level does not solve provider initialization ordering. This is a deliberate Terraform design constraint and there is no workaround within a single module.
- Terraform 1.4+ introduced provider iteration capabilities that could theoretically address some multi-provider ordering scenarios, but the fundamental two-phase evaluation model still applies. For EKS + Kubernetes, two separate modules remains the recommended approach.
- This skill is AWS-centric (EKS) but the identical pattern applies to GKE (`google` + `kubernetes`), AKS (`azurerm` + `kubernetes`), and any other managed Kubernetes provider.

## Related Skills

- **terraform-module-size-smell** — compares: the provider-initialization constraint is a hard technical reason to split a module; the size-smell skill covers the organizational and operational reasons — together they give the full case for module separation.
- **terraform-directory-layout-isolation** — informs: the two-apply ordering required for EKS cluster then apps maps naturally onto two separate environment-aware directories in the file layout, each with its own backend and CI pipeline step.
- **terraform-moved-block-refactoring** — informs: if resources are being extracted from a mixed cluster+app module into separate modules, moved blocks prevent destroy/create during the split.

______________________________________________________________________

## Provenance

- **Source:** Terraform: Up and Running (3rd Edition), Yevgeniy Brikman, 2022 (O'Reilly)
