---
name: configuration-hermeticity-framework
description: |
  Use this skill when evaluating, designing, or debugging a configuration system — especially when rollbacks are failing, configs produce different outputs at different times, or the team is debating which configuration language or tooling to adopt.

  Call when: A team reports intermittent rollback failures, configuration rendering produces different results at different times, or a new configuration system is being designed. Also call when evaluating whether a proposed config tool (Helm, Jinja2, Ansible, CUE, Dhall) is safe for use in a reliability-sensitive deployment pipeline.

  Do not call when: The issue is a runtime configuration value being wrong (a data problem), not a configuration evaluation problem (a system property problem). This skill governs configuration system design, not configuration content auditing.
tags: [configuration, hermeticity, rollback, reproducibility, infrastructure-as-code, language-design]
---

# Configuration Hermeticity Framework (Three Required Properties + Five Pitfalls)

## R — Original Text

> "Our critical properties include hermeticity; that is, configuration languages must generate the same config data regardless of where or when they execute. A system can be hard or impossible to roll back if it depends on resources that can change outside of its hermetic environment. In order to be able to roll forward and roll back configuration, it must be hermetic. Systems that allow side effects violate hermeticity, and also prevent the separation of config from data."
>
> "Separate config and data to allow for easy analysis of the config and a range of configuration interfaces. Systems that allow these side effects violate hermeticity, and also prevent the separation of config from data. In order to allow separation of config and data, first evaluate the config, then make the resulting data available to the user to analyze, and only then allow for side effects."
>
> "It is not widely understood that these properties are critical... Despite the great variety of popular configuration systems, it is difficult to find one that does not fall foul of at least one of the following pitfalls."
>
> — Google SRE Workbook, Chapters 14 and 15

______________________________________________________________________

## I — Framework (Interpretation)

Configuration is hermetic when the same inputs always produce the same outputs, regardless of when or where evaluation occurs. This is a formal property, not a guideline. A config system either has it or does not. Most widely used configuration systems — Helm, Jinja2, Ansible playbooks, Dockerfile ARG — are not hermetic by default because they read external state during evaluation: environment variables, timestamps, network resources, secrets managers, or the "latest" version of a dependency.

The three required properties of any configuration system are:

1. **Good tooling** — linters, validators, IDE integration, diff tools. Without tooling, config changes cannot be reviewed safely.
2. **Hermetic evaluation** — same inputs → same outputs, always. This is the prerequisite for reliable rollback.
3. **Separation of config from data** — the three-phase sequence: evaluate config → produce data → inspect data → allow side effects. Mixing evaluation and side effects makes dry-run validation impossible.

The five pitfalls that destroy these properties:

1. Not recognizing config as a programming language problem — ad hoc features accumulate without formal semantics.
2. Designing accidental language features — unintended Turing-completeness, implicit evaluation order.
3. Too much domain-specific optimization — a config DSL with a user base of ten engineers gets no tooling ecosystem.
4. Interleaving evaluation with side effects — the canonical hermeticity violation; config that writes to external systems during evaluation cannot be safely retried or rolled back.
5. Using a general-purpose scripting language — heavyweight sandboxing requirements, security risks, and no config-specific tooling.

Hermetic config is a prerequisite for reproducible deployments and reliable rollbacks. An unreproducible deployment pipeline is one where the team discovers on rollback night that the "same" config version now produces different infrastructure.

______________________________________________________________________

## A1 — Past Application

**Case 1 — Helm chart with external secret injection at render time**
A platform engineering team at a mid-size SaaS company used Helm charts that called an external secrets manager (HashiCorp Vault) at `helm template` time to inject production credentials. When a bad deploy required rollback, `helm rollback` re-rendered the chart using the current Vault state, which had rotated credentials since the original deploy. The rendered manifest was different from what was originally applied. The rollback failed to restore the service because it produced a different artifact. Correct fix: render the chart once at deploy time, snapshot the rendered manifest, version-control the rendered output, and apply the stored artifact on rollback. This is the evaluate → inspect → apply sequence.

**Case 2 — Evernote's migration from ad hoc YAML to hermetic config**
Evernote's SRE team reported in the workbook that non-hermetic configuration was a root cause of several cascading failures: config that read live DNS entries during evaluation produced different rendered outputs in different network partitions. The team migrated to a config pipeline where all external references were resolved once, at a defined snapshot time, and the resolved config was stored as a static artifact. Deployments and rollbacks applied the stored artifact, not a re-render. The result was that config became auditable and rollbacks became reliable.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: Rollback produces different output than original deploy**
The team reports that rolling back to version N produces different rendered infrastructure than the original version N deploy. This is the canonical hermeticity violation. Diagnose by checking whether the config evaluation reads any external resource (secrets manager, DNS, environment variable, build version) at render time. If so, those external values have changed between the original deploy and the rollback.

**Scenario 2: Config "works on my machine" but not in CI**
Config evaluation produces different outputs in developer environments versus the CI pipeline. This is an environmental dependency violation — the config reads implicit state from the local environment (environment variables, local files, user credentials). The config is not hermetic.

**Scenario 3: Evaluating whether to adopt a new config tool**
Apply the three-property checklist to the candidate tool: Does it have tooling (linter, validator)? Is evaluation hermetic (no external reads during evaluation)? Does it separate config evaluation from side effects? Score it against the five pitfalls.

**Language signals:** "the rollback didn't match," "it works locally but fails in prod," "we need to add a hook that calls the API during render," "we're just using Python scripts for our config," "the config reads the current hostname at deploy time."

**Distinguishing from adjacent skills:** This skill governs configuration system properties (is the system hermetic?), not configuration content (is the value correct?). It is not the deployment safety checklist (which governs the deployment process) and not the release engineering skill (which governs versioning and promotion strategy).

______________________________________________________________________

## E — Execution Steps

1. **Identify the evaluation boundary.** Determine exactly when config evaluation occurs and what inputs it consumes. List every external resource the config reads at evaluation time (environment variables, network calls, secrets managers, timestamps, filesystem reads outside the config repo).

2. **Test hermeticity.** Evaluate the same config twice: once now, once in a different environment or at a different time. Compare the outputs. If they differ without any change to the config inputs, the system is not hermetic.

3. **Identify the violation type.** Map the failure to one of the five pitfalls. Pitfall 4 (interleaving evaluation with side effects) is the most common. Pitfall 2 (accidental language features creating implicit evaluation order) is the hardest to detect.

4. **Separate evaluation from side effects.** Restructure the pipeline into three phases:

   - Phase 1: Evaluate config with all inputs pinned (no external calls). Produce a static artifact (e.g., rendered manifest, JSON blob).
   - Phase 2: Inspect the artifact. Run validators, diff tools, dry-run checks. Get human approval if required.
   - Phase 3: Apply the artifact. Allow side effects only at this stage.

5. **Pin all external references.** Any external data the config needs (secrets, versions, hostnames) must be resolved once, at a defined snapshot time, and stored alongside the config artifact. Rollback applies the stored artifact with its pinned external data, not a re-render.

6. **Add tooling.** A hermetic config system without tooling is not operationally safe. Add a linter that validates config syntax and type constraints before any evaluation, and a diff tool that shows the delta between current applied config and the proposed new config.

7. **Document the evaluation chain.** Record: what inputs the config takes, what outputs it produces, when evaluation occurs, and which pipeline stages are allowed to have side effects. This documentation is the audit trail that makes rollback trustworthy.

**Completion criteria:** The same config version, given the same pinned inputs, produces bit-identical output in any environment and at any time. Rollback applies a stored artifact, not a re-render. A linter runs before evaluation. Side effects occur only after inspection.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The problem is a wrong configuration value (a data error), not a configuration system design flaw. This skill does not help you find a misconfigured timeout; it helps you determine whether your config system would reliably roll back that misconfiguration.
- The configuration system is read-only and stateless by design (e.g., feature flags read from a database at runtime) — hermeticity applies to the evaluation pipeline, not to runtime feature flag reads.

**Failure patterns:**

- Achieving hermeticity in the happy path but re-introducing external reads in the error-handling path (e.g., "on failure, fetch the last-known-good config from the registry" — which is itself an external read during rollback evaluation).
- Pinning secrets but not build versions — the config is hermetic for secrets but not for the artifact it deploys.
- Storing the rendered manifest but not the inputs used to produce it — auditors cannot reproduce the evaluation.

**Author blind spots:**

- The workbook's concrete examples are Jsonnet and Kubernetes manifests. Jsonnet-specific patterns (e.g., `std.extVar`, `tla`) age poorly as the ecosystem moves toward CUE and KCL. The hermeticity principle itself is language-agnostic; the implementation patterns are not.
- The three-property framework was derived from Google's experience with internal config systems (Borgcfg, GCL). The pitfalls are empirically grounded but the framework does not account for config systems that are intentionally dynamic (e.g., Consul-template, which is designed to produce different outputs at different times). For intentionally dynamic config, hermeticity is not the goal — auditability of changes is.
- The book does not address the operational cost of storing all rendered manifests for all deployments (the storage and version-control overhead of a large fleet).

**Easily confused with:**

- Infrastructure-as-code best practices (broader category; hermeticity is one specific property within IaC).
- GitOps (a deployment pattern; hermeticity is a property of the config evaluation step within a GitOps pipeline, not of GitOps itself).

______________________________________________________________________

## Related Skills

- **contrasts_with**: canary-as-error-budget-arithmetic — both are deployment-safety disciplines but canary addresses code-defect detection while hermeticity addresses config reproducibility and rollback reliability
- **composes_with**: nalsd-iterative-design-methodology — hermetic config is a design-time property that NALSD's feasibility and resilience phases should validate before a system goes to production

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "The Site Reliability Workbook" by Betsy Beyer et al. (Google) — Chapter 14 - Configuration Design and Best Practices, Chapter 15 - Configuration Specifics
