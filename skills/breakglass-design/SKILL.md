---
name: breakglass-design
description: |
  Use this skill when designing a strict access control, implementing Zero Trust
  networking, enforcing MFA, or tightening any security control where the team or
  operations staff object "but what if we get locked out?" Breakglass is the design
  answer to that objection — and it must be designed, not improvised.

  WHEN TO CALL: A security control is being resisted because operators fear lockout during
  incidents. You are implementing ZTP, MFA enforcement, or fine-grained least privilege.
  You are reviewing an emergency access path that was built ad-hoc during an incident.
  Someone asks "what do we do if the auth system is down?" and the answer is "we'll figure
  it out" — that is not a breakglass design.

  WHEN NOT TO CALL: The control being implemented is so low-risk that lockout is not a
  meaningful concern. You are designing the normal access path (not the emergency bypass).
  Breakglass already exists and is properly designed — the question is about the normal
  access model.
tags: [breakglass, least-privilege, access-control, audit, emergency-access, zero-trust]
---

# Breakglass Must Exist for Every Strict Access Control

## R — Original Text

> Named after fire alarm pulls that instruct the user to "break glass in case of
> emergency," a breakglass mechanism provides access to your system in an emergency
> situation and bypasses your authorization system completely. The ability to use a
> breakglass mechanism should be highly restricted. All uses of a breakglass mechanism
> should be closely monitored. The breakglass mechanism should be tested regularly by the
> team(s) responsible for production services, to make sure it functions when you need it.
> The breakglass mechanism for zero trust networking should be available only from specific
> locations. These locations are your panic rooms, specific locations with additional
> physical access controls to offset the increased trust placed in their connectivity.
> (The careful reader will notice that the fallback mechanism for zero trust networking, a
> strategy of distrusting network location, is…trusting network location—but with
> additional physical access controls.)
>
> — Google, Building Secure and Reliable Systems, Chapter 5 — Design for Least Privilege

______________________________________________________________________

## I — Framework (Interpretation)

Breakglass is not a security hole — it is the mechanism that enables strict security
controls to exist at all. The causal chain is:

1. Without a known, audited emergency bypass, operators resist adopting strict controls
   because they fear being locked out during incidents.
2. That fear is legitimate — an untested emergency path is worse than no emergency path,
   because it will fail at the worst possible moment.
3. With a properly designed breakglass, the "but what if we get locked out?" objection
   is resolved, and strict normal controls become politically and operationally viable.

A properly designed breakglass has four mandatory properties:

- **Fully logged**: Every use of the breakglass produces an alert and an audit record.
  The alert must fire immediately; the record must be reviewed within 24–48 hours.
- **Rate-limited**: The breakglass cannot be invoked continuously without triggering
  escalation. High frequency use is a signal, not a norm.
- **Triggers review**: Every invocation is reviewed at the team level (routine security
  review) and at the central security team level (for patterns across teams).
- **Harder than the normal path**: Breakglass should feel exceptional. If breakglass is
  easier than the normal path, operators will use it routinely and the normal control
  becomes dead code.

For Zero Trust networking, breakglass is a physically hardened location (a "panic room")
that restores location-based trust as a last resort. This is an acknowledged tension: the
fallback for a system that explicitly distrusts network location is to trust a specific,
physically controlled location. The book accepts this tension explicitly — it is the
correct resolution.

Untested breakglass is worse than no breakglass: it creates a false sense of security
in the normal control, and then fails silently when actually needed.

______________________________________________________________________

## A1 — Past Application

**Case 1: DiRT exercise — testing breakglass credentials under simulated failure (c14)**
Google's annual Disaster Recovery Training (DiRT) exercises test whether breakglass
credentials can provide emergency access to corporate and production networks when
standard ACL services are unavailable. In one exercise, the security detection team was
deliberately included: when SREs invoked breakglass, the detection team verified that
the correct alert fired and that the access was confirmed as legitimate. This collapsed
two tests (reliability of the emergency path + security detection) into one exercise.
Outcome: confirmed that breakglass worked under simulated failure conditions and that the
security alerting pipeline fired correctly.

**Case 2: Zero Touch Production breakglass (c01, p03)**
ZTP requires every production change to flow through automation or audited breakglass.
For cases where automation coverage is insufficient (unforeseen emergency, novel failure
mode), breakglass is available to SREs only, is logged, rate-limited, and reviewed.
The existence of the breakglass is what makes ZTP politically viable: the objection
"what if something breaks that our automation can't handle?" is answered by the breakglass
design. High breakglass use is measured and drives automation investment — every breakglass
event is a signal that automation coverage has a gap.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — MFA enforcement rollout resistance**
A team proposes mandatory MFA for all admin access to a SaaS platform, including emergency
support scenarios. Security approves. Six months later, ops teams resist adoption because
they fear being locked out when MFA devices fail.

Apply breakglass design: design a secondary authentication path — a hardware key stored
in a physically secured location — that is accessible only when primary MFA fails. Use
requires: (1) physical access to the secured location, (2) a high-severity alert that
fires immediately on use, (3) review within 24 hours by the security team. Test the path
quarterly as a mandatory drill. Existence of this breakglass removes the "but what if"
objection, making mandatory MFA deployable. High breakglass use rate signals MFA device
reliability issues — investigate device failure rate, not the breakglass design.

**Scenario 2 — BeyondCorp rollout and panic rooms (c13)**
Zero Trust networking removes network location as an authorization factor. But what if
the identity provider fails or all device certificates are revoked? The breakglass for
BeyondCorp is the panic room: a physically secured location where connecting to the
network grants a specific, limited emergency credential. The irony is explicit — ZTN's
fallback is location-based trust. This is the correct resolution, not a design flaw.

**Language signals that trigger this skill:**

- "What if we get locked out?"
- "Engineers are worried they won't be able to fix things during an incident."
- "We need to keep a backdoor in case the new auth system breaks."
- "The team is using breakglass all the time — should we widen the normal access?"

**The last signal is critical**: frequent breakglass use is a signal that the normal
access model is too restrictive — not that breakglass should be normalized. Investigate
and fix the gap in the normal API.

**Distinguishing from adjacent skills:**

- Fail-safe/fail-secure (fail-safe-vs-fail-secure) deals with what the system does when
  a dependency fails automatically. Breakglass deals with deliberate human override of a
  functioning control.
- Least-privilege tooling enforcement (least-privilege-tooling-enforced) designs the
  normal access model. Breakglass is the designed exception to that model.

______________________________________________________________________

## E — Execution Steps

1. **Identify the control and the lockout scenario**: For every strict control being
   implemented, explicitly state: what is the failure mode that would deny legitimate
   access? (e.g., MFA device unavailable, identity provider down, certificate revoked)

2. **Design the breakglass path**:

   - Who can invoke it? (SRE team only, or specific named individuals)
   - From where? (any location, or a physically hardened panic room)
   - What does it grant? (the minimum access needed to restore the system, not full admin)
   - How long does it last? (time-bounded, preferably < 1 hour)

3. **Design the monitoring**: Every breakglass invocation must produce:

   - An immediate high-severity alert to the security team
   - An audit record with: who, what, when, why, from where
   - A review assignment within 24 hours

4. **Make it harder than the normal path**: The breakglass should require at least one
   additional step compared to the normal path. If breakglass is easier, it will be used
   routinely.

5. **Rate-limit invocations**: Set a threshold (e.g., no more than 3 uses per 30 days
   for a given user without escalation review). High frequency triggers a design review
   of the normal access model, not a loosening of the breakglass.

6. **Test it as a drill**: Schedule a quarterly exercise where the team deliberately
   invokes the breakglass under controlled conditions. Verify: the path works, the alert
   fires, the review process runs. Untested breakglass is not a breakglass.

7. **Measure and act on breakglass frequency**: Build a dashboard. When breakglass use
   for a specific operation exceeds the threshold, investigate the normal access model for
   that operation and close the gap.

**Completion criteria**: Every strict control has a documented breakglass. The breakglass
is tested. The monitoring fires. The frequency is measured. The team's "lockout" objection
is answered by the design.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The control is not strict enough to create a meaningful lockout risk. Low-stakes access
  controls do not require breakglass — the overhead is disproportionate.
- You are using "we need a breakglass" as a justification to weaken a control rather than
  to create a proper emergency path. A breakglass that is easier than the normal path is
  not a breakglass — it is a backdoor.

**Failure patterns:**

- Untested breakglass: a breakglass that has never been tested in a drill will fail when
  needed, usually during the worst possible incident.
- Breakglass as routine: if engineers use breakglass daily, the normal access model has
  failed. The response is to fix the normal access model, not to accept breakglass use
  as normal.
- Unmonitored breakglass: a breakglass without alerting is indistinguishable from a
  hidden backdoor. Both allow bypass; only one produces an audit trail.
- Location-unrestricted breakglass for Zero Trust systems: if the ZTN breakglass can be
  invoked from anywhere on the internet, it defeats the purpose. Panic rooms exist
  precisely to add a physical constraint.

**Author blind spots:**

- The book does not address the organizational dynamics of breakglass review: who reviews
  it, how quickly, and what the escalation path is when reviewers disagree with the use.
  At Google scale, a centralized team can review; at smaller organizations, the reviewer
  may be the person who invoked the breakglass.
- The "test regularly" guidance is correct but understates the operational challenge:
  quarterly breakglass drills require buy-in from operations teams, coordination with
  security detection, and often conflict with production stability norms.
- LLM-era threat: automated agents with production access create new breakglass scenarios
  that the 2020 book does not address — what is the breakglass for an automated agent
  that has locked itself out through misconfiguration?

**Easily confused with:**

- Graceful degradation: a system that continues operating with reduced functionality
  when a dependency fails is not a breakglass. Graceful degradation is automatic;
  breakglass is a deliberate human action with a monitored audit trail.
- A backdoor: the difference is auditability and intent. A backdoor is hidden and
  unmonitored. A breakglass is documented, logged, alerted on, and reviewed. If
  your "breakglass" is not all four of those, it is a backdoor.

______________________________________________________________________

## Related Skills

- **depends_on**: least-privilege-tooling-enforced — breakglass exists because strict least-privilege creates the lockout risk that operators fear
- **contrasts_with**: fail-safe-vs-fail-secure — breakglass is deliberate human override of a functioning control; fail-safe/fail-secure is automatic system behavior when dependencies fail
- **composes_with**: zero-touch-production — ZTP requires breakglass as its mandatory safety valve; the breakglass design is what makes ZTP politically deployable

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Source IDs: p04
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Building Secure and Reliable Systems" by Heather Adkins, Betsy Beyer et al. (Google) — Chapter 5 — Design for Least Privilege
