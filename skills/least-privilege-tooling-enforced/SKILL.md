---
name: least-privilege-tooling-enforced
description: |
  Use this skill when designing or auditing an access control system where the question
  is not just "who should have access?" but "how do we prevent excess access from being
  used, even under pressure?" The skill applies when access is granted permanently or
  broadly and the enforcement mechanism is policy documents, training, or human honor
  rather than tooling.

  WHEN TO CALL: You are designing access control for a production system, a data pipeline,
  a shared service account, or an administrative API. You are reviewing an existing system
  where engineers have broad access "just in case." You observe frequent breakglass use
  for routine operations. You are choosing between policy-based and tooling-enforced
  access models.

  WHEN NOT TO CALL: The access model is already time-bounded and tooling-enforced and
  the question is about a specific access decision. You are designing authentication (who
  can prove identity) rather than authorization (what an authenticated identity can do).
tags: [least-privilege, access-control, breakglass, time-bounded, tooling-enforced, insider-risk]
---

# Least Privilege Enforced by Tooling, Time-Bounded, and Context-Aware

## R — Original Text

> Not all data or actions are created equal, and the makeup of your access may differ
> dramatically depending on the nature of your system. Therefore, you shouldn't protect
> all access to the same degree. In order to apply the most appropriate controls and avoid
> an all-or-nothing mentality, you need to classify access based on impact, security risk,
> and/or criticality. … Your goal should be to construct an access framework from which
> you can apply appropriate controls with the right balance of productivity, security, and
> reliability. The principle of least privilege says that users should have the minimum
> amount of access needed to accomplish a task, regardless of whether the access is from
> humans or systems. Because we can't rely on human perfection, we must assume that any
> possible bad action or outcome can happen. Therefore, we recommend designing the system
> to minimize or eliminate the impact of these bad actions.
>
> — Google, Building Secure and Reliable Systems, Chapter 5 — Design for Least Privilege

______________________________________________________________________

## I — Framework (Interpretation)

Least privilege implemented via policy documents fails — humans will exceed it under
pressure, accident, or compromise. The correct enforcement mechanism is tooling: access
requests are time-bounded, context-specific, and require re-approval.

The framework proceeds in four phases:

1. **Classify access by risk tier**: Not all access is equal. Separate public access,
   sensitive access, and highly sensitive access into distinct categories with distinct
   controls. Administrative APIs that can delete data are not in the same tier as
   read-only APIs.

2. **Design narrow functional APIs**: Each API endpoint does one thing. Instead of
   exposing a full POSIX shell (which allows deletion, modification, reading, and
   networking simultaneously), expose one endpoint per administrative operation. The API
   surface determines the maximum blast radius of any single credential compromise.

3. **Grant time-bounded, context-linked access**: Access grants expire. On-call engineers
   receive elevated production access only during on-call windows. Temporary access
   requests must be linked to structured justifications (ticket IDs, incident numbers)
   that are machine-verifiable. Permanent ambient authority is the failure mode.

4. **Treat breakglass frequency as a design signal**: If engineers frequently invoke
   breakglass for a particular operation, the normal access model is too restrictive for
   that operation's actual requirements. Breakglass frequency data should drive API surface
   improvements — not be treated as an acceptable baseline.

The non-obvious insight: high breakglass frequency is not a sign that security controls
are working; it is a sign that the normal access model is mis-specified. Breakglass data
is design feedback.

______________________________________________________________________

## A1 — Past Application

**Case 1: Google Tool Proxy — safe proxy enforcing ZTP (c01)**
Google engineers had broad CLI tool access to production systems. The Tool Proxy
intercepts all CLI invocations, checks a fine-grained policy, requires MPA for sensitive
commands, and logs every action. Engineers prepend `tool-proxy-cli` to their commands.
Direct connections outside breakglass situations are blocked at the server level. This
is tooling-enforced least privilege: the policy is not in a document that engineers could
ignore under pressure — it is enforced by the proxy infrastructure. Breakglass use at
the team level triggers peer review, creating a feedback loop that drives API surface
improvement over time.

**Case 2: On-call rotation access scoping**
Human engineers receive elevated production access only during their on-call rotation
window. Access automatically expires at rotation end. When an engineer goes off-call, they
return to baseline access — they do not retain elevated permissions. Structured business
justifications (incident numbers) are machine-verifiable. This reduces ambient authority:
the blast radius of any compromised on-call account is bounded to the duration of the
on-call window, not the engineer's tenure at the company.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — Data engineering team with shared service account**
A startup's data engineering team uses a shared service account with read/write access to
all production data buckets for data pipeline work. A junior engineer joins.

Apply the framework:

- Classify: raw production data is highly sensitive.
- Narrow API: replace the shared account with per-pipeline service accounts scoped to
  only their source and destination buckets.
- Time-bound: pipeline jobs request short-lived credentials for their run, auto-expiring
  after job completion.
- Human access: require structured justification tied to a task ticket; grant access for
  the task duration only.

Measure: the blast radius of any single credential compromise goes from "all data" to
"one pipeline's data for one run window."

**Scenario 2 — SaaS platform where support agents have broad read access**
Customer support representatives have read access to all customer records for efficiency.

Apply the framework:

- Block access by default.
- Grant access to specific customer records only when the representative has an open
  ticket for that customer.
- Time-bound: access expires when the ticket closes.
- Machine-verify: the justification (ticket ID) is checked programmatically against the
  open ticket system, not accepted as free text.

Signal: if representatives frequently invoke breakglass or escalate to override this
access control, that is a signal that the ticket-based workflow has a gap — investigate
what the gap is and close it with a proper API.

**Language signals that trigger this skill:**

- "We trust our engineers to use their access responsibly."
- "We gave everyone broad access so they can deal with incidents."
- "Engineers will just use breakglass if we restrict access too much."

**Distinguishing from adjacent skills:**

- Breakglass design (breakglass-design) is about the emergency bypass. This skill is about
  the normal access model that makes breakglass rare.
- Multi-party authorization (p06) is an advanced control layered on top of this skill;
  it requires that sensitive operations have a second approver, which this skill's
  narrow-API design makes practical.

______________________________________________________________________

## E — Execution Steps

1. **Classify all access in scope**: Assign each API, data store, and administrative
   function to a risk tier. Document the classification. Use it to calibrate control
   intensity.

2. **Decompose large APIs**: For each administrative API, list the distinct operations it
   exposes. Create one endpoint per operation. Remove or restrict the general-purpose
   interface (interactive SSH, full POSIX API) where possible.

3. **Replace permanent access grants with time-bounded access**:

   - Service accounts: rotate credentials on schedule; pipeline jobs use short-lived tokens.
   - Human access: tie elevated access to on-call rotation windows or explicit task tickets.
   - Default expiry: all elevated access expires; re-approval is required for continuation.

4. **Require structured justifications**: Access requests for sensitive operations must
   include machine-verifiable context: incident number, ticket ID, customer case ID.
   Free-text justifications are not auditable.

5. **Implement tooling enforcement**: The policy is not in a document. It is enforced by
   the infrastructure: the proxy checks policy, the credential issuer checks justification,
   the token expires automatically. Policy documents describe intent; tooling enforces it.

6. **Instrument breakglass frequency per operation**: Build a dashboard that shows
   breakglass invocations by operation type. Set a threshold (e.g., >5 breakglass uses
   per month for a specific operation) that triggers a design review of the normal API.

7. **Test least privilege**: Write automated tests that verify each role profile has
   exactly the access it needs — no more. These tests run in CI and fail if a role gains
   unexpected permissions.

**Completion criteria**: Every elevated access grant has an expiry. Every sensitive
operation has a structured justification requirement. Breakglass frequency is measured.
Least privilege is tested in CI.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The access model is already time-bounded and tooling-enforced and the question is
  about a specific access decision rather than the access design.
- You are working in an early-stage system where the operational cost of fine-grained
  access would impede getting to first production — but document the debt explicitly and
  set a timeline for resolution.

**Failure patterns:**

- "We'll trust engineers not to abuse broad access" — this is honor-enforced least
  privilege, which fails under stress, compromise, and accidental typos. Trust is not
  an enforcement mechanism.
- Treating breakglass frequency as acceptable rather than as a signal. If breakglass
  is used daily for routine operations, the normal access model has failed.
- Confusing authentication strength (2FA, security keys) with authorization narrowness.
  Strong authentication with broad authorization still creates a large blast radius.
- Granting time-bounded access via a calendar reminder rather than tooling — the expiry
  will not be enforced.

**Author blind spots:**

- The book describes a mature tooling ecosystem (credential issuers, time-bounded token
  systems, structured justification frameworks) that takes significant engineering
  investment to build. Small teams may find the operational overhead of fine-grained
  time-bounded access higher than the book implies.
- The breakglass-as-feedback-signal insight is valuable but requires instrumentation
  investment to operationalize. Teams that do not measure breakglass frequency cannot
  use it as a design signal.
- The book does not address the case where the access model is correct but the tooling
  for making access requests is so painful that engineers create workarounds — usability
  of the access request path is a prerequisite for compliance.

**Easily confused with:**

- Zero trust networking: ZTN removes network location as an authorization factor.
  Least-privilege tooling enforcement narrows what any authenticated identity can do.
  They are complementary: ZTN addresses who is trusted; least privilege addresses what
  they are allowed to do.

______________________________________________________________________

## Related Skills

- **depends_on**: tcb-identification-minimization — decomposing access into narrow functional APIs requires first identifying which components are in the TCB; small APIs reduce TCB scope
- **composes_with**: breakglass-design — breakglass removes the lockout objection that blocks strict least-privilege controls from being deployed; both are required for politically viable strict access
- **composes_with**: multi-party-authorization — MPA is the advanced control layered on top of least-privilege classification for the highest-sensitivity tier; least privilege narrows scope, MPA requires two actors for what remains sensitive

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Source IDs: f08, p05, p07
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Building Secure and Reliable Systems" by Heather Adkins, Betsy Beyer et al. (Google) — Chapter 5 — Design for Least Privilege
