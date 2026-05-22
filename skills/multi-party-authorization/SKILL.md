---
name: multi-party-authorization
description: |
  Use this skill when designing or reviewing controls for operations that, if performed
  unilaterally by a single insider, could cause significant damage — whether through
  malice, compromise, or error. Canonical triggers: production access elevation, secret
  rotation, mass-delete or mass-send operations, emergency database maintenance, and
  deployment of code that bypasses the normal review pipeline. The non-obvious trigger:
  any code review gate that is enforced as a deployment precondition IS multi-party
  authorization — treat it explicitly as a security control, not just a quality practice.

  Do NOT apply as a universal overhead tax. Low-risk routine operations (reading logs,
  viewing dashboards, deploying to dev) should not require MPA — overuse produces
  rubber-stamp approvals that defeat the control. Apply proportionally to the risk tier
  established by least-privilege classification.

  Trigger phrases: "single admin account", "only one engineer approved", "no peer review
  required for this path", "shared service account", "insider risk", "who can approve
  this unilaterally", "emergency database access".
source_book: "Building Secure and Reliable Systems" by Google
source_chapter: Chapter 5 — Design for Least Privilege
tags: [MPA, multi-party-authorization, insider-risk, code-review, 3FA, audit, least-privilege]
related_skills: []
---

# Multi-Party Authorization for All Sensitive Operations

## R — Original Text

> Involving another person is one classic way to ensure a proper access decision, fostering
> a culture of security and reliability. MPA protects against unilateral insider risk as well
> as against compromise of an individual workstation (by requiring a second internal approval).
> MPA is often performed for a broad level of access — for example, by requiring approval to
> join a group that grants access to production resources. Requiring 3FA from the originator
> and simple web-based MPA from a second party can provide a very strong defense against the
> combination of most of these threats, with relatively little organizational overhead.
>
> — Google BSRS, Chapter 5 — Design for Least Privilege

______________________________________________________________________

## I — Framework (Own Words, 5-15 Lines)

Multi-party authorization (MPA) requires two independent actors to approve a sensitive
operation before it executes. The attack model is simple: a single compromised or coerced
actor cannot complete the operation alone. Two-actor requirement raises the cost of insider
attacks dramatically — the attacker must compromise two separate people or machines.

The non-obvious unification: code review enforced as a deployment gate IS MPA applied to
the software supply chain. The same security pattern simultaneously serves quality and
security without additional overhead.

3FA extends MPA to resist broad workstation compromise. Requiring the originator's approval
from a hardened mobile device (the third factor, outside the corporate workstation fleet)
closes the attack vector where an adversary has compromised all workstations on the same
network segment.

The approver must see sufficient context to make a real decision — showing only "approve /
deny" with no action detail produces a rubber stamp, not a security control. The approver
must understand precisely what they are authorizing, which is why MPA over small functional
APIs (narrow operations) provides stronger guarantees than broad group-membership approvals.

Ensure the technology and social dynamics allow the second party to say no. If organizational
culture means no one ever refuses, MPA provides audit trail but not security.

______________________________________________________________________

## A1 — Past Application (From Cases.md)

**Google Tool Proxy (c01):** Google's CLI tools could trigger production outages if given
incorrect scope selectors. The Tool Proxy intercepts all CLI invocations, checks a policy,
and requires MPA for sensitive commands before forwarding to Borg. When a sensitive command
is issued, MPA is triggered and the proxy waits for authorization from a person in
`group:admin-leads`. This eliminates the single-actor risk on dangerous operational commands
without removing engineers' ability to act. Direct connections outside breakglass are blocked
at the server level. Google estimates ~13% of evaluated outages could have been prevented
with controls of this kind.

**TrustedSqlString / code review as MPA (c03, p09):** Code review enforced as a deployment
precondition is MPA for production changes. No single engineer can ship to production; the
reviewer is the second party. Combined with configuration-as-code and deployment policies,
code review becomes the MPA layer for arbitrary production changes. The security and quality
functions are achieved by the same gate.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenarios:**

- A financial institution uses a shared DBA account for emergency database maintenance. One
  actor can perform any maintenance unilaterally. Regulators flag this as a control weakness.
- An engineering team has a deployment path that bypasses code review for "hotfixes." An
  insider could ship arbitrary production code without a second reviewer.
- A key rotation process requires only one admin to initiate. A single compromised account
  can rotate keys to attacker-controlled values, locking out legitimate access.

**Language Signals:**

- "shared account," "single admin," "I can approve my own deployment," "emergency path
  doesn't require review," "one person initiates the rotation," "no peer approval needed."

**Adjacent skill distinctions:**

- **vs. least-privilege-tooling-enforced:** Least privilege reduces WHAT one actor can do;
  MPA requires that DOING it needs two actors. Both apply together: least privilege shrinks
  scope, MPA adds the two-actor requirement for what remains sensitive.
- **vs. breakglass-for-every-strict-control:** Breakglass is a bypass of strict controls for
  emergencies; MPA is the normal-path control. Breakglass paths themselves may require MPA
  (location-restricted panic rooms with full audit).
- **vs. zero-touch-production:** ZTP routes all changes through automation or audited
  breakglass; MPA is the human-approval layer within those routes for sensitive operations.

______________________________________________________________________

## E — Execution Steps (With Completion Criteria)

1. **Identify sensitive operations.** Enumerate operations that, if performed unilaterally,
   could cause significant damage: mass data deletion, secret rotation, production
   deployment, privilege elevation, emergency database access.

2. **Apply risk-tier classification.** Use the least-privilege access classification to
   determine which operations require MPA vs. simpler controls.

3. **Design the MPA gate.** For each sensitive operation:

   - Choose the approval granularity: broad (group membership) for unusual one-off actions;
     narrow (specific small API) for routine sensitive operations.
   - Ensure the approver sees the full context of the request, not a one-click approval.
   - For highest-sensitivity operations, add 3FA: require originator approval from a
     hardened mobile device, not just the corporate workstation.

4. **Enforce in tooling, not policy.** The operation must be structurally impossible without
   the second approval. A policy document that can be bypassed under deadline pressure is
   not MPA.

5. **Apply to code review as MPA.** Confirm that the deployment pipeline enforces code
   review as a precondition — no deployment path accepts unreviewed code.

6. **Log and alert every MPA action.** Each approval produces a durable audit record
   attributing the action to both parties. High MPA-bypass frequency signals a design
   failure in normal operations.

**Completion criteria:** No sensitive operation can be completed by a single actor without
tool-enforced approval from a second, independently authenticated party. Approvers see
sufficient context to make a genuine decision. Audit trail attributes actions to both parties.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- Routine, low-risk operations (log viewing, dashboard reads, dev deployments). MPA overhead
  on routine tasks produces approval fatigue and rubber stamps.
- The organization lacks the social dynamics for approvers to say no — audit trail without
  real veto power is theater, not security.

**Failure patterns:**

- One-click approval UI with no context shown to the approver. Produces rubber stamps.
- Shared accounts used as the "second party." Not independent actors.
- MPA implemented as a policy document rather than a tooling gate. Bypassed under pressure.
- All approvers on the same workstation fleet. A broad workstation compromise defeats MPA
  without 3FA.

**Author blind spots / limitations:**

- MPA is modeled on internal corporate approval workflows. External attackers who compromise
  the identity provider or SSO system may be able to generate approvals without real second-party
  involvement — MPA assumes the authentication system is trustworthy.
- The book does not address AI-assisted approval spoofing (social engineering of the second
  party via AI-generated fake context), an emerging 2024+ threat vector not present in 2020.
- Google-scale: MPA with 3FA assumes a hardened mobile device program exists. Smaller
  organizations may lack the MDM infrastructure to implement 3FA as described.

**Easily confused with:**

- Two-person integrity (TPI) in nuclear/financial contexts — MPA is the software equivalent,
  but implementation differs significantly from physical two-key systems.
- Multi-factor authentication (MFA) — MFA is a single-actor control (multiple factors from
  one person); MPA is a two-actor control.

______________________________________________________________________

## Related Skills

- **depends_on**: least-privilege-tooling-enforced — least-privilege classification identifies which operations are sensitive enough to require MPA; MPA is the advanced control for the highest-sensitivity tier
- **composes_with**: supply-chain-binary-provenance — code review is the MPA layer in the supply chain; binary provenance provides the machine-verifiable record that MPA was satisfied
- **composes_with**: zero-touch-production — MPA is the human-approval enforcement mechanism at the safe proxy for sensitive commands; the two skills compose in the safe proxy design

______________________________________________________________________

## Audit Information

- V1 ✓ / V2 ✓ / V3 ✓ — 2026-05-04
