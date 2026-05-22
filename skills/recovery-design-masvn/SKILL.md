---
name: recovery-design-masvn
description: |
  Use this skill when designing update/rollback mechanisms for self-updating components,
  firmware, or any system where the ability to roll back conflicts with the need to
  permanently enforce a security patch. The canonical trigger: a reliability team wants
  to roll back to a previous version, but security has patched a vulnerability in the
  current version that must not be reintroduced.

  Apply when designing: firmware update pipelines, application binary self-update systems,
  OS kernel rollout mechanisms, or any component that maintains local version state and
  must resist attacker-forced rollback.

  Do NOT apply to stateless deployment systems where every deployment is a clean install
  with no local version state — MASVN assumes the component stores ComponentState locally
  and enforces it on initialization. Also do not apply when availability requirements make
  any form of rollback prevention unacceptable — the design tension is real and MASVN is
  a middle path, not a universal solution.

  Trigger phrases: "roll back to vulnerable version," "security patch has a bug," "attacker
  forcing rollback," "firmware downgrade attack," "can't roll back past the security fix,"
  "rollback vs. security tradeoff."
source_book: "Building Secure and Reliable Systems" by Google
source_chapter: Chapter 9 — Design for Recovery
tags: [recovery-design, MASVN, rollback, security-versioning, deny-lists, key-rotation, firmware]
related_skills: []
---

# Recovery Design with MASVN — Preventing Rollback Past Security Boundaries

## R — Original Text

> Rollbacks represent a tradeoff between security and reliability. When patching security
> vulnerabilities, you are often racing against attackers, trying to deploy a patch before
> an attacker exploits the vulnerability. Once the patch is successfully deployed and shown
> to be stable, you need to prevent attackers from applying a rollback that reintroduces the
> vulnerability. … The MASVN defines a low-water mark below which your systems should
> never operate.
>
> To mitigate a security vulnerability in release i–1, release i includes the security patch
> and an incremented Release[SVN]. Release[MASVN] doesn't change in release i, because even
> security patches can have bugs. Once release i is proven to be stable in production, the
> next release, i+1, increments the MASVN.
>
> — Google BSRS, Chapter 9 — Design for Recovery

______________________________________________________________________

## I — Framework (Own Words, 5-15 Lines)

MASVN (Minimum Acceptable Security Version Number) is a forward-only version floor: the
component stores ComponentState[MASVN] locally and refuses to initialize any version whose
Security Version Number (SVN) is below the floor. The floor ratchets forward — it can
only increase, never decrease — preventing rollback attacks.

The critical non-obvious design: the MASVN floor is NOT advanced at patch time. It is
advanced in the NEXT release (i+1) after the patched release (i) has been demonstrated
stable in production. This decouples "we patched it" from "we locked in the patch" — it
preserves the ability to roll back a buggy security patch without permanently blocking
recovery paths, while still eventually locking in the fix once proven.

Security recovery and availability recovery are in fundamental tension. Teams under crash-
recovery time pressure will reach for the rollback lever without thinking about whether the
version they are rolling back to has a known security vulnerability. MASVN is the mechanism
that makes security win during recovery without requiring operator memory — the component
itself refuses the insecure rollback.

Three complementary mechanisms address different time horizons:

1. **Deny lists** — rapid incident response (block specific known-bad versions immediately).
2. **MASVN** — permanent enforcement after the patch is proven stable (garbage-collect the
   deny list, permanently exclude vulnerable versions per component instance).
3. **Key rotation** — recovery from the most severe compromise (attacker controls release
   signing, sets MASVN to maximum to poison the ratchet).

The emergency push system should be the regular push system at maximum speed — not a
separate emergency pipeline. Separate emergency systems that are never exercised in normal
operations will fail when needed.

______________________________________________________________________

## A1 — Past Application (From Cases.md)

**MASVN Scheme Design (c09):** Google needed to solve the fundamental tension in self-
updating components: allowing rollback for reliability while preventing rollback for security.
The MASVN scheme uses a forward-only integer stored in ComponentState that ratchets up as
security fixes are proven stable. The component refuses to load any version with a lower SVN
than the stored MASVN. Crucially, MASVN is only incremented AFTER a patch is proven stable
(in the following release i+1), preserving the ability to roll back a buggy security patch
without permanently blocking recovery paths.

For hardware devices with OTP fuses (one-time-programmable), the MASVN approach uses the
OTP-backed ComponentState to cover a small, single-purpose bootloader that then exposes more
robust MASVN semantics to the higher-level software stack.

**Heartbleed Response (c06):** When Heartbleed was discovered, Google patched key external
systems under embargo before public disclosure. The accelerated timeline imposed by unexpected
early public disclosure illustrated the value of having rapid key rotation already designed
in — key rotation was necessary because private keys may have been exposed through memory
disclosure. Design for rapid key rotation is a prerequisite for surviving this class of
incident.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenarios:**

- A team patches a critical authentication bypass vulnerability in API gateway v2.3.1.
  Version 2.3.0 had the bug. A new bug in 2.3.1 causes crashes and operations wants to roll
  back. With MASVN advanced to 2.3.1 (after proving stability), the rollback to 2.3.0 is
  rejected by the component itself — not by a policy document or an operator's memory.
- An attacker gains temporary control of the release signing key and sets Release[MASVN] to
  the maximum value, poisoning the MASVN ratchet. The recovery mechanism: key rotation —
  revoke the compromised public key in new releases signed by a new key, and add dedicated
  logic to recognize the unusually high ComponentState[MASVN] and reset it.
- A firmware update is deployed to fix a critical vulnerability. Operations wants to roll
  back because the firmware has a compatibility issue. MASVN allows rollback to the patched
  version (i) because the MASVN has not yet been advanced to i+1 — but prevents rollback to
  the vulnerable version (i-1).

**Language Signals:**

- "can we roll back to the previous version," "the security patch broke something," "we need
  to revert," "firmware downgrade," "what happens if we roll back past the security fix,"
  "attacker is forcing a recovery to an old version."

**Adjacent skill distinctions:**

- **vs. fail-safe-vs-fail-secure:** Fail-safe/fail-secure is about the system's behavior
  during uncertainty (fail open vs. fail closed). MASVN is about recovery from a known
  bad state — it governs which versions the system will accept, not how the system behaves
  during partial failure.
- **vs. supply-chain-binary-provenance:** Binary provenance verifies that the artifact was
  built from reviewed source via the verified pipeline. MASVN verifies that the artifact
  meets the minimum security version floor. Provenance is about BUILD integrity; MASVN is
  about ROLLBACK prevention. Both are needed for complete supply chain security.
- **vs. breakglass-for-every-strict-control:** Breakglass provides an emergency bypass for
  strict access controls. A MASVN enforcement that prevents rollback may itself need an
  emergency override procedure for catastrophic bugs in the patch itself — this is the
  breakglass that allows MASVN to be strict in normal operations.

______________________________________________________________________

## E — Execution Steps (With Completion Criteria)

1. **Add Security Version Number (SVN) to releases.** Separate from the release version
   number. SVN is an integer that increments only when a security fix is included.

2. **Store ComponentState[MASVN] locally in the component.** This is the forward-only floor.
   It is not part of the deployment system — it lives in the component's local state.

3. **Enforce MASVN on every initialization.** Before loading any update, verify:
   `Release[SVN] >= ComponentState[MASVN]`. If not, reject the update.

4. **Update ComponentState[MASVN] conservatively.** When a new release initializes for the
   first time, run: `ComponentState[MASVN] = max(self[MASVN], ComponentState[MASVN])`.
   Only advance MASVN in release i+1, after release i (the patched release) is proven stable.

5. **Use deny lists for rapid incident response.** Hardcode deny lists in the component to
   block specific known-bad versions immediately during an incident. Deny lists are the fast
   path; MASVN provides the permanent enforcement once the incident is resolved.

6. **Design key rotation for compromised signing key recovery.** Maintain the ability to
   revoke the current signing key and rotate to a new one. New releases signed with the new
   key include logic to handle the poisoned MASVN edge case.

7. **Make the emergency push system the regular push system at maximum speed.** Do not
   maintain a separate emergency pipeline. This ensures the emergency path is continuously
   exercised and will work when needed.

**Completion criteria:** No component can be downgraded past a proven-stable security
boundary without the component itself rejecting the operation. Deny lists handle the fast
incident response window. MASVN handles the permanent enforcement. Key rotation handles
signing key compromise.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- Stateless deployment systems where every deployment is a clean install with no local
  component state. MASVN requires the component to store and enforce ComponentState locally.
- Systems where any form of rollback prevention is unacceptable due to availability
  requirements. The design tension between security and availability is real — for some
  systems (life-safety equipment), availability must win over rollback prevention.
- Simple web applications without self-updating components. MASVN is designed for
  firmware, OS kernels, and self-updating binaries that maintain local state across
  deployments. Standard deployment pipelines use other mechanisms.

**Failure patterns:**

- Advancing MASVN at patch time (in release i) rather than after proving stability (in
  release i+1). This prevents rollback of a buggy security patch, turning a reliability
  problem (crash) into a permanent availability problem (no rollback possible).
- Using MASVN without deny lists. Deny lists handle the incident response window (hours);
  MASVN handles the long-term enforcement (weeks). Using only MASVN leaves the incident
  window unprotected.
- Separate emergency push pipeline that is not exercised during normal operations. Untested
  emergency systems fail when needed.
- Wall-clock time dependencies in recovery (e.g., "certificates expire after X days").
  Prefer epoch/version advancement — time dependencies create coordination problems and can
  be manipulated by attackers who control the system clock.

**Author blind spots / limitations (Blind spots section):**

- Google-scale: MASVN is designed for large component fleets where version state can be
  tracked per component instance. Smaller deployments may find the complexity unnecessary
  relative to simpler deployment policies.
- ZTP/MPA require scale: the emergency API for advancing ComponentState[MASVN] requires
  a deployment management system capable of sending per-component commands at scale.
- Hardware constraints: OTP (one-time-programmable) fuses implementing MASVN on hardware
  devices have significant reliability risks — rollback is infeasible. The book acknowledges
  this requires additional software bootloader layering, but implementation is complex.
- Fail-safe/fail-secure is an unresolved tension: if the MASVN logic itself has a bug and
  rejects a valid update, the system is stuck. The breakglass override for this scenario is
  not fully resolved in the book's treatment.
- LLM threats absent 2020: AI-generated code that passes review but contains subtle security
  flaws may advance SVN without actually being secure. MASVN tracks version numbers, not
  semantic security properties.

**Easily confused with:**

- Semantic versioning (SemVer) — SemVer is a public API compatibility signal. SVN/MASVN is
  a security floor signal. They can coexist: a release can have SemVer 2.3.1 and SVN 7.
- Feature flags / rollback prevention policies — policy documents that say "do not roll back
  past version X" are not MASVN. MASVN is enforced by the component itself, not by operator
  memory or policy.

______________________________________________________________________

## Related Skills

- **depends_on**: supply-chain-binary-provenance — binary provenance records which security patches were applied and via which verified pipeline; MASVN enforces the version floor that prevents rolling back past those proven-safe patches
- **composes_with**: breakglass-design — MASVN enforcement needs a breakglass override for catastrophic bugs in a security patch; breakglass is what allows MASVN to remain strict under normal conditions
- **composes_with**: unified-incident-management-imag — IMAG orchestrates the human recovery decisions (when to advance MASVN, when to invoke deny lists) that MASVN enforces mechanically

______________________________________________________________________

## Audit Information

- V1 ✓ / V2 ✓ / V3 ✓ — 2026-05-04
