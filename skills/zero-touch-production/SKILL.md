---
name: zero-touch-production
description: |
  Use this skill when a user is designing or auditing production access controls,
  evaluating whether direct human access to production systems is acceptable, or
  planning the automation of operational tasks.

  Trigger signals:
  - "Engineers SSH into production servers to fix issues"
  - "We need direct database access for emergency ops"
  - "Our on-call team makes manual changes during incidents"
  - "We're designing an admin CLI for production systems"
  - "We want to reduce the risk of human error in production"
  - Any architecture discussion involving human access to live infrastructure

  Do NOT use this skill when:
  - The system is a development or staging environment (not production)
  - The question is specifically about code review or supply chain — use
    supply-chain-binary-provenance-deployment-policy
  - The question is about least privilege scoping without the human-access
    framing — use least-privilege-tooling-enforced-time-bounded
tags: [zero-touch-production, automation, safe-proxy, insider-risk, reliability, MPA, breakglass, audit]
---

# Zero Touch Production — All Production Changes via Automation or Audited Breakglass

## R — Original Text (≤150 Words)

> Zero Touch Prod is a project at Google that requires every change in production
> to be made by automation (instead of humans), prevalidated by software, or
> triggered through an audited breakglass mechanism. Safe proxies are among the
> set of tools we use to achieve these principles. We estimate that ~13% of all
> Google-evaluated outages could have been prevented or mitigated with Zero Touch Prod.
>
> Using the Tool Proxy achieves one of the main goals of Zero Touch Prod: making
> production safer by not allowing humans to directly access production. Engineers
> are not able to run arbitrary commands directly on servers; they need to contact
> the Tool Proxy instead. To ensure privileged users don't circumvent the proxy,
> we modified the server to allow only administrative actions to admin-proxy and
> to deny any direct connections outside of breakglass situations.
>
> — *Building Secure and Reliable Systems*, Google, Chapter 3

______________________________________________________________________

## I — Framework (Own Words, 5-15 Lines)

Zero Touch Production is a design principle with a single rule: no human directly
modifies production systems. Every production change flows through exactly one of
three sanctioned paths: (1) fully automated pipelines, (2) pre-validated software
with cryptographic provenance, or (3) a breakglass mechanism that is physically or
access-restricted, fully logged, rate-limited, and reviewed after the fact.

The key insight is that ZTP addresses two threats simultaneously with the same
mechanism. Human access to production is a security risk (insider attack, credential
compromise enabling unilateral change) and a reliability risk (human error under
stress). These are not competing concerns — eliminating direct human access improves
both. The ~13% figure grounds this in evidence: not a security statistic, but an
outage statistic.

The enforcement mechanism is the safe proxy — a mandatory intermediary for all
administrative operations. The proxy enforces policy (who can run what), requires
MPA for destructive operations, logs every action, and rate-limits blast radius.
Breakglass is the safety valve that makes strict controls politically deployable:
teams accept tight controls when they know an emergency override exists. Breakglass
frequency is a feedback signal — high use means automation coverage is insufficient
and the normal operational API is too narrow.

The transition path from ad-hoc SSH access: build runbooks as code triggered through
an audited API; route remaining operational tasks (log inspection, emergency reboots)
through a safe proxy with MPA; create a geographically or physically restricted
breakglass for true emergencies; measure breakglass use as the residual signal.

______________________________________________________________________

## A1 — Past Application (From Cases.md)

### Google Tool Proxy (C01)

Google engineers perform most administrative operations via CLI tools. Some are
dangerous — a misscoped command can stop multiple service frontends. Rather than
tracking every CLI tool individually, Google built the Tool Proxy: a binary that
intercepts all CLI invocations, checks a fine-grained policy, requires MPA for
sensitive commands, and logs every action. Engineers prepend `tool-proxy-cli` to
their commands; the proxy handles authorization before forwarding to Borg. Direct
server connections are blocked outside of breakglass situations at the server level.

**Outcome**: Production became auditable, rate-limited, and MPA-gated, without
eliminating engineers' operational capability. The proxy is transparent to workflow —
only a command prefix changes. Google estimates ~13% of evaluated outages would have
been prevented or mitigated by ZTP controls of this kind.

### DiRT Exercise — Testing Breakglass Under Simulated Failure (C14)

During Google's annual Disaster Recovery Training exercise, SREs tested whether
breakglass credentials could provide emergency production access when standard ACL
services were down. The security detection team was looped in simultaneously to
verify that the correct alert fired when breakglass was invoked. Both the reliability
of the emergency path and the security detection layer were validated in one exercise.

**Outcome**: Confirmed breakglass worked under simulated failure conditions, and
alerting correctly fired and classified the access as legitimate. This illustrates
that untested breakglass procedures are unreliable — emergency paths must be part
of routine operational drills.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Scenario: Growing Startup, Lead Engineer Has SSH Access to All Production Servers

A 25-person startup's lead engineer has SSH access to all production servers "just
in case." The team is scaling and considering formalizing access controls, but is
worried about losing operational speed during incidents.

**ZTP prescription**:

1. Replace interactive SSH with runbooks-as-code triggerable through an audited API.
   Start with the highest-frequency tasks (service restarts, log drains, config updates).
2. Deploy a safe proxy for remaining operational tasks; route all remaining admin
   commands through it with per-command policy and MPA for destructive operations.
3. Create a breakglass path (geographically restricted token or physical device) with
   full audit trail and mandatory post-use review within 24 hours.
4. Measure: track breakglass frequency weekly. Each breakglass use points to a missing
   automation. The target metric is unautomated production changes trending to zero.

**What ZTP predicts**: The team will discover that ~80% of their "just in case" SSH
sessions correspond to a small set of repeated tasks that can be automated within
the first month. Breakglass use declines as automation coverage grows. The remaining
breakglass uses identify the long tail of edge cases that need tooling investment.

### Signals That Activate This Skill

- "We need to SSH in to fix this in production"
- "Our Terraform/Ansible applies directly to production by the on-call engineer"
- "We don't have time to build automation for this right now"
- "The engineer manually updated the config file during the incident"
- Any post-incident report where a human directly modified a production system

### Distinguishing from Adjacent Concerns

- Differs from **breakglass-for-every-strict-control**: That skill focuses on the
  breakglass mechanism design in isolation. ZTP is the overarching principle that
  creates the need for breakglass — it is the strict control that breakglass supplements.
- Differs from **supply-chain-binary-provenance-deployment-policy**: That skill
  addresses what gets deployed (artifact integrity). ZTP addresses who can make changes
  and through what mechanism once the artifact is in the deployment pipeline.
- Differs from **multi-party-authorization**: MPA is one enforcement technique within
  ZTP (required at the safe proxy for sensitive operations). ZTP is the broader
  architectural constraint.

______________________________________________________________________

## E — Execution Steps (With Completion Criteria)

1. **Inventory all direct human production access paths**

   - List every mechanism by which a human can modify production state: SSH, direct
     database clients, admin UIs with write access, manual Kubernetes exec, etc.
   - For each path: document the operations it enables, how frequently it is used,
     and whether any automation exists for those operations.
   - Completion criteria: Complete list of all direct access paths with usage data.

2. **Classify each access path against the ZTP triad**

   - For each path, determine which ZTP channel it belongs to or should be migrated to:
     (a) fully automated pipeline, (b) pre-validated software with provenance,
     or (c) audited breakglass.
   - Paths used routinely (more than once per month) must become (a) or (b).
     Paths used rarely or only in emergencies are candidates for (c).
   - Completion criteria: Every direct access path is assigned to a ZTP channel.

3. **Build or designate the safe proxy for remaining operational access**

   - Choose or build a safe proxy that: enforces per-operation policy, requires MPA
     for destructive operations, logs all requests with caller identity, and rate-limits
     high-blast-radius operations (e.g., rolling restarts).
   - Modify target systems to deny direct connections outside of breakglass (ACL at
     server level, not just at the proxy).
   - Completion criteria: All non-automated operations route through the proxy; direct
     connections are blocked at the target and verified.

4. **Design and document breakglass**

   - Create a restricted breakglass mechanism: require physical restriction, geographic
     restriction, or hardware token to invoke; generate an alert on use; mandate review
     within 24 hours; test quarterly in DiRT or equivalent exercise.
   - Document the breakglass procedure so any on-call engineer can find and use it
     under stress without assistance.
   - Completion criteria: Breakglass is documented, accessible, tested, and monitored.

5. **Instrument and act on breakglass frequency**

   - Track breakglass invocations per week. Any spike signals either an incomplete
     automation coverage gap or a sufficiently narrow operational API.
   - For each breakglass use, create an automation backlog item.
   - Completion criteria: Breakglass frequency is visible on the on-call dashboard and
     has a defined threshold that triggers automation investment.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- **Development and staging environments**: ZTP applies to production. Applying it
  to dev environments adds friction without meaningful security benefit — developers
  need direct access to debug locally.
- **Emergency response where automation itself has failed**: If the automation
  infrastructure (proxy, CI/CD, orchestrator) is itself the cause of the incident,
  breakglass exists precisely for this case. ZTP does not prohibit emergency access;
  it requires that emergency access is audited, not that it is unavailable.
- **Small teams at very early stage (\<5 engineers)**: The overhead of a safe proxy
  before the team has stable operational patterns tends to produce a poorly-designed
  proxy. At very early stage, focus on logging all production changes manually
  (documented runbook + PR for each change) before investing in proxy infrastructure.

### Failure Modes Warned About in the Book

- **Breakglass used as the normal path**: If breakglass frequency is high, the team
  has not built enough automation. The safe proxy must cover the common cases; breakglass
  that becomes routine is no longer an auditable escape valve — it is the de facto
  access model, defeating the purpose of ZTP.
- **Proxy without server-side enforcement**: A proxy that can be bypassed by connecting
  directly to the target system provides only the illusion of ZTP. The target system must
  deny direct connections at the network or application layer; the proxy is not a
  voluntary layer.
- **Untested breakglass**: A breakglass mechanism that has never been invoked in a drill
  will fail during an actual emergency — credentials expired, procedure undocumented,
  alert not firing. The DiRT case demonstrates this must be tested before it is needed.

### What ZTP Is Easily Confused With

- **"We have Terraform so we have ZTP"**: Infrastructure-as-code is a precondition for
  ZTP but not sufficient. ZTP requires that the Terraform apply itself cannot be run by
  a human ad-hoc — it must flow through an audited CI pipeline. A developer who can run
  `terraform apply` from their laptop is not ZTP-compliant.
- **"We have an audit log so we have ZTP"**: Logging direct SSH access is not ZTP.
  Logging records what happened; ZTP prevents the dangerous thing from happening in the
  first place (with audited breakglass for exceptions). Audit without prevention addresses
  forensics, not risk reduction.

______________________________________________________________________

## Related Skills

- **depends_on**: breakglass-design — ZTP requires a properly designed breakglass as its safety valve; without it the strict no-direct-access control cannot be deployed due to operator lockout fear
- **composes_with**: least-privilege-tooling-enforced — the safe proxy implements tooling-enforced least privilege for operational access; both skills apply simultaneously at the enforcement layer
- **composes_with**: multi-party-authorization — MPA is the human-approval enforcement mechanism at the safe proxy for sensitive commands; ZTP provides the architectural constraint, MPA provides the dual-approval gate within it
- **composes_with**: supply-chain-binary-provenance — ZTP requires all production changes via automation; binary provenance is the cryptographic proof that the ZTP pipeline (not an ad-hoc path) produced and deployed the artifact

______________________________________________________________________

## Audit Information: V1✓/v2✓/v3✓ — 2026-05-04

- **Source IDs**: p03
- **Verification**: All three validation tests passed (cross-domain, predictive power,
  exclusivity) — see verified.md entry for p03

______________________________________________________________________

## Provenance

- **Source:** "Building Secure and Reliable Systems" by Google — Chapter 3 — Case Study: Safe Proxies, Chapter 5 — Design for Least Privilege
