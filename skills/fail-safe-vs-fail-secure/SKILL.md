---
name: fail-safe-vs-fail-secure
description: |
  Use this skill when designing any component whose authorization, access-control, or
  configuration system can fail — and you need to decide what the component does when it
  cannot verify its own state.

  WHEN TO CALL: A component loads ACLs, certificates, or policies from an external source
  at runtime. You are asked "what should the system do if that load fails?" You are
  designing a door lock, a payment gate, a network appliance, or any system where failure
  has both availability and confidentiality consequences. The decision surfaces in design
  docs, architecture reviews, or incident post-mortems where failure mode was not
  pre-decided.

  WHEN NOT TO CALL: The component has no authorization layer (it serves only public data).
  The failure mode has already been decided and encoded in the system. You are debugging
  an existing failure rather than designing future behavior.
tags: [fail-safe, fail-secure, failure-mode-design, security-reliability-tradeoff, resilience]
---

# Fail-Safe Vs. Fail-Secure Must Be Decided at Design Time

## R — Original Text

> When designing a system to handle failure, you must balance between optimizing for
> reliability by failing open (safe) and optimizing for security by failing closed
> (secure): To maximize reliability, a system should resist failures and serve as much as
> possible in the face of uncertainty. Even if the system's integrity is not intact, as
> long as its configuration is viable, a system optimized for availability will serve what
> it can. If ACLs failed to load, the assumed default ACL is "allow all." To maximize
> security, a system should lock down fully in the face of uncertainty. If the system
> cannot verify its integrity — regardless of whether a failed disk took away a part of its
> configs or an attacker changed the configs for an exploit — it can't be trusted to
> operate and should protect itself as much as possible. If ACLs failed to load, the
> assumed default ACL is "deny all." Security-critical operations should not fail open.
>
> — Google, Building Secure and Reliable Systems, Chapter 8 — Design for Resilience

______________________________________________________________________

## I — Framework (Interpretation)

Fail-safe and fail-secure are not implementation choices — they are threat model choices.
The framework has three mandatory steps:

1. **Identify the primary threat**: Is the greater harm an availability failure (a locked-out
   operator, a patient who cannot get medication, a fire door that traps occupants) or a
   confidentiality/integrity breach (unauthorized access, data exfiltration, fraud)?

2. **Encode the decision**: The chosen failure mode must be explicit in the system design
   document and implemented as the default behavior under uncertainty — not left to runtime
   operator judgment.

3. **Resolve the tension structurally**: Failing secure does not mean failing dark. A
   lower-cost fallback component with stronger security controls can replace the failing
   primary component. This makes failing secure survivable: the system degrades to a
   safer, simpler mode rather than going offline entirely.

The decision is irreconcilable — a single component cannot simultaneously maximize
availability and security under the same failure condition. Choosing both is choosing
neither. The correct posture is to pick the primary failure threat, make the choice
explicit, test it in drills, and design the breakglass override of the chosen mode for
the cases where an operator must override.

______________________________________________________________________

## A1 — Past Application

**Case 1: Electronic door lock (physical security)**
An electronic lock failing during a power outage must choose: fail-safe (remain open, for
safe egress) or fail-secure (remain locked, to prevent unauthorized entry). Life-safety
codes in most jurisdictions mandate fail-safe for fire egress doors — the threat model is
"trapped occupant" not "unauthorized intruder during power failure." The decision is made
at installation time, not by the guard on duty during the outage.

**Case 2: Google App Engine sandbox (c02)**
App Engine runs untrusted third-party code inside Google's network. When a sandbox layer
(NaCL or ptrace) encounters an unexpected syscall, it fails secure — it blocks and alerts
rather than allowing the operation. The threat model is confidentiality/integrity breach
from tenant code escaping to Google infrastructure. Availability of the tenant's code is
secondary. This was a design-time decision validated over five years of confirmed
exploitation attempts, all contained within design parameters.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — Hospital medication dispensing system**
An LDAP server authorizes pharmacist access to a medication dispenser. During a network
partition, LDAP becomes unreachable. The question: fail open (pharmacist can dispense
without authorization) or fail secure (dispenser locks until LDAP recovers)?

Apply the framework: the primary threat is not "unauthorized dispensing" — it is "locked
pharmacist unable to dispense medication causing patient harm." This is a life-safety
system. Decision: fail-safe (fail open). The breakglass path must be designed to prevent
abuse of the open state: a paper log, a supervisor co-sign, and a time limit.

**Scenario 2 — Payment processing gateway**
A payment gateway cannot reach its fraud-scoring service. Fail open means processing all
payments without fraud scoring; fail secure means rejecting all payments until the scoring
service recovers.

Apply the framework: the primary threat for a payment system is financial fraud and
chargebacks (confidentiality/integrity), not revenue loss from temporary unavailability.
Decision: fail-secure (fail closed). The lower-cost fallback is a simpler rule-based
fraud filter (not the ML model) that accepts low-value transactions only.

**Language signals that trigger this skill:**

- "What happens if the auth service goes down?"
- "Should we default to allow or deny?"
- "We should fail open so we don't take down the product."
- "We should fail closed to be safe."

**Distinguishing from adjacent skills:**

- Breakglass design (breakglass-design) deals with *intentional* bypass of controls;
  fail-safe/fail-secure deals with *unintentional* system failure.
- Defense in depth deals with multiple layers assuming earlier layers failed; this skill
  deals with what a single component does when its own dependencies fail.

______________________________________________________________________

## E — Execution Steps

1. **Articulate the failure scenario**: What external dependency can fail, and what does
   the component do when that dependency is unavailable?

2. **Identify the primary threat**: State explicitly: is the greater harm an availability
   failure or a confidentiality/integrity breach? Write this in one sentence.

3. **Choose the failure mode**: Fail-safe (fail open) if availability harm dominates;
   fail-secure (fail closed) if confidentiality/integrity harm dominates.

4. **Design the fallback component**: If failing secure, identify the lower-cost,
   higher-security alternative that replaces the failing primary component (e.g., a
   simpler rule-based system in place of an ML fraud scorer).

5. **Encode the decision**: Implement the chosen failure mode as the default behavior.
   Make it visible in code (not buried in configuration) and state it in the design doc.

6. **Design the human override**: What is the breakglass that allows an authorized
   operator to override the chosen failure mode? This override must be logged and
   rate-limited.

7. **Test the failure mode in a drill**: Deliberately induce the dependency failure in a
   staging environment. Verify the system behaves as designed. Untested failure modes are
   unreliable failure modes.

**Completion criteria**: The design document states the chosen failure mode and its
rationale. The failure mode is implemented as the system default. The drill has been run
and recorded.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The system serves only publicly available data with no access control — failure mode is
  irrelevant because there is no authorization state to lose.
- The failure mode has already been decided and implemented — this skill is for design,
  not for re-litigating settled decisions without new threat model information.

**Failure patterns:**

- Choosing both ("we'll try to fail open for low-risk requests and fail closed for
  high-risk ones") — this is not a failure mode choice, it is a runtime judgment that
  will be made inconsistently under stress.
- Treating fail-secure as automatically safer — for life-safety systems, fail-secure
  (fail closed) can be the more dangerous choice.
- Making the decision during an incident — by definition, the worst time to choose a
  failure mode is while the failure is occurring.

**Author blind spots:**

- The book assumes failure modes are clean and detectable. In practice, partial failures
  (timeouts, flapping, partial ACL loads) create intermediate states that don't map
  cleanly to fail-open or fail-closed.
- The "lower-cost fallback component" resolution is theoretically elegant but requires
  pre-building and maintaining that fallback — operational cost the book understates.
- LLM-era threats (model inference endpoints, prompt injection) create new failure mode
  dimensions the 2020 book does not address.

**Easily confused with:**

- Graceful degradation: a system that continues operating with reduced functionality is
  not the same as a system that has made an explicit fail-safe/fail-secure choice. Graceful
  degradation is an availability pattern; fail-safe/fail-secure is a security policy
  decision under uncertainty.

______________________________________________________________________

## Related Skills

- **depends_on**: tcb-identification-minimization — TCB components are typically those whose failure triggers the fail-safe/fail-secure decision; identifying the TCB is prerequisite to deciding the failure mode
- **contrasts_with**: breakglass-design — fail-safe/fail-secure handles unintentional system failure automatically; breakglass handles deliberate human override of a functioning control
- **composes_with**: security-as-emergent-property — the failure mode choice is a canonical example of a design-time decision that cannot be deferred without embedding an uncontrolled default

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Source IDs: f03, p20
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Building Secure and Reliable Systems" by Heather Adkins, Betsy Beyer et al. (Google) — Chapter 8 — Design for Resilience, Chapter 4 — Design Tradeoffs
