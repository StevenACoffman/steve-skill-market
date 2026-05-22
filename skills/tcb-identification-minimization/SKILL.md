---
name: tcb-identification-minimization
description: |
  Use this skill when designing a system that must enforce a specific security policy and
  you need to identify which components must be correct for the policy to hold — and then
  shrink that set as small as possible.

  WHEN TO CALL: You are drawing a security boundary and asking "what do we need to
  audit?" You are decomposing a monolith and wondering which microservices need security
  review. You are choosing a language or runtime for a security-critical component. You
  are asked to estimate the audit scope for a security property.

  WHEN NOT TO CALL: The security policy is not yet defined — TCB identification requires
  a specific, stated policy to work from. You are doing a general attack-surface reduction
  (which is adjacent but broader). You are assessing a running system for known
  vulnerabilities (penetration testing is a different skill).

  KEY TRIGGER: "What needs to be correct for this security guarantee to hold?" or "Which
  components do we need to audit?" or "We're splitting this monolith — what changes in
  terms of security review scope?" This is the skill.
source_book: "Building Secure and Reliable Systems" by Heather Adkins, Betsy Beyer et al. (Google)
source_chapter: Chapter 6 — Design for Understandability
tags: [tcb, security-boundary, least-privilege, system-decomposition, understandability, audit]
related_skills: []
---

# TCB Identification and Minimization Methodology

## R — Original Text

> The trusted computing base (TCB) of a system is "the set of components whose correct
> functioning is sufficient to ensure that the security policy is enforced, or more
> vividly, whose failure could cause a breach of the security policy." Reasoning about a
> TCB becomes more difficult as the TCB broadens to include more code and complexity. For
> this reason, it's valuable to keep TCBs as small as possible, and to exclude any
> components that aren't actually involved in upholding the security policy. In addition
> to impairing understandability, including these unrelated components in the TCB adds
> risk: a bug or failure in any of these components could result in a security breach. To
> ensure that a system enforces a desired security policy, you have to understand and
> reason about the entire TCB relevant to that security policy.
>
> — Google, Building Secure and Reliable Systems, Chapter 6 — Design for Understandability

______________________________________________________________________

## I — Framework (Interpretation)

The TCB is not a global property of a system — it is per-security-policy. A component
may be in the TCB for confidentiality but not for integrity. This per-policy decomposition
is the non-obvious insight that distinguishes TCB reasoning from generic "minimize attack
surface" advice.

The methodology has four steps:

1. **State the security policy precisely**: "Only authenticated users can access their own
   shipping address data." The policy must be specific enough to test. A vague policy
   produces an unbounded TCB.

2. **Identify every component whose failure would violate the policy**: Draw the boundary
   around those components. Every component inside the boundary is in the TCB — including
   ones that feel unrelated (e.g., the web frontend that issues RPCs to a data store is in
   the TCB if the data store trusts those RPCs without re-verifying authorization).

3. **Evaluate necessity**: For each component, ask: if this component were perfectly
   correct, could the policy still be violated without compromising another TCB component?
   If yes, the component is not necessary — it does not belong in the TCB.

4. **Restructure to shrink**: Microservice decomposition, web origin isolation, and
   per-service databases are the primary tools. Moving authorization checks to a dedicated
   enforcer component allows the UI tier, analytics pipeline, and billing system to be
   excluded from the TCB for a given policy.

TCB size maps directly to audit burden: every line of code in the TCB requires security
review; every component outside the TCB does not. Minimization is therefore not a
one-time design exercise — it is ongoing engineering work, the same way technical debt
reduction is ongoing.

______________________________________________________________________

## A1 — Past Application

**Case 1: Google monolith to microservices (widget purchasing example, c02 context)**
In the book's worked example, a monolithic web application with a shared database places
the entire application codebase in the TCB for the security policy "only users can access
their own shipping addresses." A catalog search SQL injection vulnerability could expose
shipping addresses because the monolith's database grants read access to all modules.

After decomposition into microservices with separate databases, TCB_AddressData shrinks
to: the purchasing backend (owns the address data), the authentication service (resolves
user identity), and the RPC layer between them. The catalog search module — and any
vulnerability in it — is now outside the TCB for this policy.

**Case 2: Google App Engine multi-tenant sandbox (c02)**
The security policy is "tenant A's code cannot access tenant B's data or Google's
production infrastructure." The TCB for this policy includes: the NaCL compiler/runtime
that blocks memory corruption escapes, the ptrace layer that filters unexpected syscalls,
and the I/O API replacement layer that removes direct disk/network access. The tenant's
application code, the web request routing layer, and the billing system are all outside
the TCB. This allowed the App Engine team to concentrate security review on three
well-defined components, even while running arbitrary third-party code.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — Multi-tenant SaaS with a shared database**
A team is building a SaaS platform where all tenants share a PostgreSQL database with
row-level security. The security policy: "Tenant A cannot read Tenant B's data."

Apply the methodology: TCB includes the RLS predicate enforcement in PostgreSQL, the
authentication service that resolves the tenant identity token, and the ORM layer that
constructs the WHERE clause carrying the tenant ID. Excluded from TCB: the UI rendering
layer, the analytics pipeline, the payment system, and the caching layer (assuming cache
keys are tenant-namespaced as an opaque component).

Audit scope: the RLS policy definition, the auth service token issuer, and the ORM tenant
scoping function — not the entire application. A SQL injection in the catalog search
module is now outside the TCB for the tenant isolation policy.

**Scenario 2 — Kubernetes cluster with shared control plane**
Policy: "Namespace A workloads cannot access Namespace B secrets." TCB includes: the
Kubernetes API server authorization layer (RBAC), the etcd storage layer, and the kubelet
credential injection mechanism. Excluded: the application containers themselves, the
ingress controller for HTTP traffic, the logging pipeline.

**Language signals that trigger this skill:**

- "What do we need to audit for this security requirement?"
- "We're splitting the monolith — does that change our security review scope?"
- "Which services are in scope for the PCI/HIPAA boundary?"

**Distinguishing from adjacent skills:**

- Attack surface reduction is about removing unnecessary exposure to attackers. TCB
  minimization is about identifying which components must be *correct* for a policy to
  hold — a logically different question.
- Threat modeling starts with attacker capabilities; TCB identification starts with the
  security property you want to enforce.

______________________________________________________________________

## E — Execution Steps

1. **Write the security policy as a testable invariant**: One sentence, specific, with
   subject and predicate. ("Only authenticated users can access their own order history.")

2. **List every component that touches the data or decision path**: Start from the data
   store and trace all paths to external callers. Include auth services, API gateways,
   ORMs, caches, and any service that makes authorization decisions.

3. **Apply the TCB test to each**: "If this component fails or is compromised, can the
   policy be violated?" Yes = in TCB. No = excluded.

4. **Draw the boundary**: Make it explicit in the architecture diagram. Label every
   component as "in TCB for [policy]" or "out of TCB for [policy]."

5. **Identify restructuring opportunities**: Can an authorization check be centralized
   in one enforcer component so that upstream components are excluded? Can a microservice
   split remove unrelated code from the TCB?

6. **Map audit burden to TCB**: The security review scope for this policy is the TCB.
   Everything outside the TCB can be reviewed for quality, not for this security property.

7. **Repeat per policy**: Run this exercise for each distinct security property.
   A component may be in different TCBs for different policies.

**Completion criteria**: A diagram or table explicitly lists, per security policy, which
components are in the TCB. Audit schedule covers TCB components at review frequency
proportional to their risk.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The security policy has not been stated — without a specific policy, the TCB is
  everything, which is useless.
- You are doing a full penetration test or vulnerability assessment — those are discovery
  exercises, not TCB exercises.

**Failure patterns:**

- Conflating TCB with "trusted code" or "code written by our team." The TCB is a formal
  property: components whose failure violates the policy. An open-source library your team
  did not write can be in the TCB; internal code your team wrote can be outside it.
- Creating a single global TCB for "security" rather than separate TCBs per policy.
  This inflates the audit scope to the entire codebase, defeating the purpose.
- Treating TCB minimization as a one-time design decision. Code changes continuously
  expand TCBs unless minimization is treated as ongoing engineering work.

**Author blind spots:**

- The methodology assumes clear service boundaries. In practice, shared libraries and
  in-process modules blur TCB edges — the book's microservices examples are idealized.
- Google-scale tooling (hermetic builds, per-service databases, verified RPC) makes TCB
  boundaries easier to enforce. Small teams may not have the infrastructure to maintain
  the separation the methodology requires.
- The book does not address TCB for ML model inference pipelines, where the training data
  and model weights are de facto TCB components with different auditability properties.

**Easily confused with:**

- Security perimeter: a perimeter is a network boundary; a TCB is a logical property of
  which components must be correct. A component inside the network perimeter may be
  outside the TCB for a given policy; a component outside the perimeter (a third-party
  auth provider) may be inside it.

______________________________________________________________________

## Related Skills

- **composes_with**: secure-by-construction-apis — secure-by-construction APIs shrink the TCB to a single constructor and its sanitizer, making the audit scope tractably small for injection-prevention policies
- **composes_with**: least-privilege-tooling-enforced — tooling-enforced narrow functional APIs limit the blast radius of any component, which directly reduces which components must be included in the TCB for a given policy

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Source IDs: f06, p02
- Distillation Time: 2026-05-04
