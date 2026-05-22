---
name: supply-chain-binary-provenance
description: |
  Use this skill when designing deployment controls, evaluating build pipeline security, or
  responding to the question "how do we know the binary running in production corresponds to
  the code that was reviewed?" Canonical triggers: CI/CD pipeline design, artifact signing
  strategy, developer workstation compromise scenarios, insider-threat deployment controls,
  and any situation where code review is enforced socially but not machine-verifiably.

  The key shift: the question is not "did a human approve this?" but "can the deployment
  system cryptographically verify that this artifact was produced by the verified pipeline
  from reviewed source?" Binary provenance is the mechanism that closes the gap between
  human approval and machine verification.

  Do NOT apply to organizations where insider deployment risk is low and build
  infrastructure is simple — the operational complexity of full binary provenance with
  verifiable builds is substantial and appropriate for large or high-security organizations.

  Trigger phrases: "developer token compromise," "malicious branch deployment," "how do we
  verify the binary," "supply chain attack," "build pipeline integrity," "artifact signing."
source_book: "Building Secure and Reliable Systems" by Google
source_chapter: Chapter 14 — Deploying Code
tags: [supply-chain, binary-provenance, build-integrity, deployment-policy, verifiable-builds, code-signing, insider-risk]
related_skills: []
---

# Supply Chain Integrity via Binary Provenance and Provenance-Based Deployment Policies

## R — Original Text

> The threat model for code deployment includes the following: a malicious developer who
> compromises a build system; a compromised build artifact store; a deployment system that
> lacks verification of the artifact it is deploying. Binary provenance is a cryptographic
> record of exactly how a binary artifact was built. Provenance-based deployment policies
> allow you to enforce that only binaries built by your verified pipeline may be deployed —
> thereby verifying artifacts, not just people.
>
> Every build should produce binary provenance describing exactly how a given binary artifact
> was built: the inputs, the transformation, and the entity that performed the build.
>
> — Google BSRS, Chapter 14 — Deploying Code

______________________________________________________________________

## I — Framework (Own Words, 5-15 Lines)

Supply chain integrity means verifying not just the artifact (code signing) but the ENTIRE
build process: which source commits, which build tools, which build environment, which
dependencies. Binary provenance is the cryptographic record of this full transformation
chain — input source commit + build tool version + build environment hash + output artifact
hash — signed by the verified build infrastructure.

The key attack model: an attacker who compromises a developer workstation can exfiltrate
credentials and trigger builds from malicious branches. Code signing alone does not prevent
this if the developer's signing key is on the workstation. Binary provenance closes this gap:
the provenance records that the artifact was built from reviewed source in the verified
pipeline, not from an ad-hoc workstation build.

Provenance-based deployment policies enforce the claim as a machine-verifiable gate: the
deployment system checks provenance before running any artifact. An attacker must compromise
BOTH the developer account AND the build infrastructure signing key — two independent
systems — to deploy malicious code.

Hermetic builds (isolated from external dependencies at build time) and reproducible builds
(same inputs always produce the same output) strengthen provenance guarantees: they make it
impossible to silently inject dependencies not recorded in the provenance.

Code review, in this model, becomes the MPA layer for source: the provenance records that
the source was reviewed before building. The deployment policy enforces that provenance
before allowing execution. Social convention becomes machine-verifiable property.

______________________________________________________________________

## A1 — Past Application (From Cases.md)

**Google Binary Provenance Implementation (c08):** Google implemented binary provenance to
enforce deployment policies: each build produces a signed record of source commit, tools,
and pipeline. The initial implementation uploaded provenance asynchronously to a database,
which caused two severe problems: multiple provenance records for the same hash produced
useless error messages ("none of 497,129 records met policy"), and asynchronous upload
failures caused silent rejections. The system was redesigned to propagate provenance INLINE
with the artifact rather than through a database lookup, eliminating the ambiguity and
bringing latency within SLO. Key lesson: make provenance unambiguous and inline, not
database-queried.

**ClusterFuzz / OSS-Fuzz (c07):** Continuous fuzzing of open-source dependencies is a
supply chain security control at the dependency level — finding bugs in components before
they propagate downstream. Supply chain integrity is not limited to the build pipeline;
the quality of upstream dependencies is part of the supply chain trust model.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenarios:**

- A developer's GitHub token is stolen. The attacker triggers a CI build from a malicious
  branch and attempts to deploy the resulting artifact. With provenance-based deployment
  policy enforcing "artifact must be built from reviewed source in the main branch," the
  deployment is rejected without needing to detect the stolen token.
- A build worker in the CI pipeline is compromised. The attacker injects malicious code
  during compilation. The resulting binary's provenance does not match any reviewed source
  commit — the deployment policy catches the mismatch at deploy time.
- An artifact in the artifact store is tampered with after the fact. The tampered binary's
  hash does not match the hash signed by the build infrastructure — provenance mismatch
  detected at deploy time.

**Language Signals:**

- "how do we know the binary in production is what we reviewed," "developer account
  compromise," "build system trust," "artifact signing," "SLSA level," "supply chain
  attack," "can someone deploy from their laptop."

**Adjacent skill distinctions:**

- **vs. multi-party-authorization:** MPA is the human-approval layer (code review requires
  a second human to approve). Binary provenance is the machine-verification layer (the
  deployment system verifies the artifact cryptographically). Both are required: MPA without
  provenance means the human approved code that may not correspond to the deployed artifact;
  provenance without MPA means the artifact is traceable but may have been built from
  unreviewed code.
- **vs. least-privilege-tooling-enforced:** Least privilege scopes what credentials can do;
  binary provenance controls what artifacts can be deployed. Both reduce the blast radius of
  a credential compromise.
- **vs. zero-touch-production:** ZTP requires all production changes to flow through
  automation; binary provenance is the cryptographic verification that the automation
  pipeline was the one that produced the deployed artifact.

______________________________________________________________________

## E — Execution Steps (With Completion Criteria)

1. **Map the supply chain.** Document every stage: source VCS → code review → CI build →
   artifact storage → deployment. Identify trust assumptions at each stage.

2. **Define the threat model for each stage.** For each stage, ask: what could an attacker
   accomplish if this stage were compromised, and does the next stage detect it?

3. **Implement binary provenance generation.** For every build, produce a signed provenance
   record containing: source repository URL and commit hash, list of reviewed commits, build
   tool versions, build environment identifier, output artifact hash, timestamp, and the
   identity of the pipeline that performed the build.

4. **Propagate provenance inline with the artifact.** Attach provenance to the artifact
   (not to a database keyed on the hash). This eliminates ambiguity when multiple builds
   produce the same hash and reduces latency and failure modes.

5. **Define deployment policies per environment.** For each deployment environment, specify
   what provenance properties are required: allowed source repositories, required review
   status, required build pipeline identity.

6. **Enforce provenance at deployment time.** The deployment system checks provenance against
   the environment's policy before executing any artifact. Deployment fails with a clear,
   actionable error message if provenance is missing or does not match policy.

7. **Strengthen with hermetic builds.** Ensure builds are isolated from external network
   dependencies at build time. External dependencies are pinned and pre-fetched. This ensures
   the provenance record captures all inputs.

**Completion criteria:** Any artifact that was not built by the verified pipeline from
reviewed source is rejected at deployment time, with a specific error identifying which
provenance property failed. A developer workstation compromise alone is insufficient to
deploy malicious code.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- Small organizations with low insider risk and simple build infrastructure. The operational
  complexity of full binary provenance (signing infrastructure, provenance storage, policy
  engine) is substantial. Simpler code-signing with mandatory code review may be sufficient.
- The deployment pipeline itself is not locked down — provenance from a build system that
  anyone can modify is not trustworthy. Hermetic, locked-down build infrastructure is a
  prerequisite.

**Failure patterns:**

- Provenance stored in a database keyed on artifact hash. Causes ambiguity with multiple
  builds of the same source, and introduces latency and failure modes (as Google discovered).
- Provenance checked only at initial deployment, not on every execution. An attacker who
  can swap the artifact after the initial check defeats the control.
- Build system signing key stored on the build worker alongside code. A compromised build
  worker can sign malicious artifacts. Signing keys must be in hardware security modules
  (HSMs) or equivalent.
- Code review enforcement that is advisory, not tooling-enforced. An advisory review that
  can be bypassed under deadline pressure means provenance may record "reviewed" falsely.

**Author blind spots / limitations:**

- The book's binary provenance model predates SLSA (Supply-chain Levels for Software
  Artifacts, 2021), which provides a more structured framework for the same concepts.
  Current implementations should map to SLSA levels.
- LLM-generated code introduces a new supply chain dimension not present in 2020: AI-
  generated code may pass review without reviewers fully understanding what it does. Binary
  provenance does not address this — it records that code was reviewed, not that the review
  was adequate.
- The Google-scale implementation assumes a centralized build infrastructure. Distributed
  development models (external contributors, open source forks) require different trust
  hierarchies.

**Easily confused with:**

- Code signing alone — code signing verifies artifact identity (who signed it) but not build
  provenance (what source produced it, via what pipeline). Provenance is strictly more
  information-rich.
- Artifact hashing / checksums — verifies integrity (artifact was not tampered with in
  transit) but not provenance (who built it from what source). Complementary, not equivalent.

______________________________________________________________________

## Related Skills

- **depends_on**: multi-party-authorization — code review is the MPA layer in the supply chain; binary provenance provides the machine-verifiable record that MPA was satisfied before the artifact was built
- **composes_with**: zero-touch-production — ZTP requires all production changes via automation; binary provenance is the cryptographic proof that the automation pipeline (not an ad-hoc workstation) produced the deployed artifact
- **composes_with**: recovery-design-masvn — binary provenance records which security patches were applied and via which pipeline; MASVN enforces the version floor that prevents rollback past those verified patches

______________________________________________________________________

## Audit Information

- V1 ✓ / V2 ✓ / V3 ✓ — 2026-05-04
