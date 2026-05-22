---
name: security-as-emergent-property
description: |
  Use this skill when a user is evaluating whether security (or reliability) can be
  added to an existing system, estimating the cost of retrofitting a security control,
  or deciding where in the development lifecycle security reviews should occur.

  Trigger signals:
  - "Can we add authentication/authorization/encryption after the fact?"
  - "We'll do security review before launch"
  - "We didn't have time to design security in — we'll harden it post-MVP"
  - "We need to add TLS/mTLS to our existing internal service mesh"
  - Any estimate for "adding security" to a system that is already partially built
  - Security review requested at the pre-launch gate rather than at design time
  - "Why is retrofitting authentication taking 3× longer than estimated?"

  Do NOT use this skill when:
  - The user is designing a new system from scratch and asking what to design in —
    this skill is the diagnostic for why retrofit fails, not the design recipe;
    use the appropriate design-time skills (tcb-identification-minimization,
    least-privilege-tooling-enforced-time-bounded, etc.) for the positive prescriptions
  - The question is about a specific tactical security control (e.g., "how do I add
    rate limiting") — use the relevant specific skill
  - The question is about reliability only, with no security component

  The mechanism explained here is "emergent property": security is not a feature that
  can be localized to a module and bolted on — it arises from the interaction of all
  design decisions simultaneously. This explains structurally (not just anecdotally)
  why bolt-on security fails and why retrofit cost is proportional to integration
  points, not to the complexity of the security mechanism itself.
source_book: "Building Secure and Reliable Systems" by Google
source_chapter: "Chapter 4 — Design Tradeoffs; Chapter 1 — The Intersection of Security and Reliability"
tags: [emergent-properties, design-tradeoffs, security-by-design, architecture, technical-debt, reliability, lifecycle]
related_skills: []
---

# Security and Reliability Are Emergent Properties — Must Be Designed In, Never Bolted On

## R — Original Text (≤150 Words)

> It's usually difficult to "bolt on" security and reliability to an existing system
> that wasn't designed from the outset with these concerns in mind. If a system lacks
> well-defined and understandable interfaces between components and contains a tangled
> set of dependencies, it likely will have lower availability and be prone to bugs with
> security consequences. No amount of testing and tactical bug-fixing will change that.
> Accommodating security and reliability requirements in an existing system often
> requires significant design changes, major refactorings, or even partial rewrites,
> and can become very expensive and time-consuming.
>
> Feature requirements usually exhibit a fairly straightforward connection between the
> requirements, the code that satisfies those requirements, and tests that validate the
> implementation. In contrast, nonfunctional requirements — like reliability and
> security requirements — are often much more difficult to pin down. Reliability is
> primarily an emergent property of the design of your system.
>
> — *Building Secure and Reliable Systems*, Google, Chapters 1 & 4

______________________________________________________________________

## I — Framework (Own Words, 5-15 Lines)

Security (and reliability) is an emergent property: it arises from the interaction of
all design decisions in a system simultaneously, not from any individual component.
This is the precise mechanism that explains why bolt-on security fails structurally —
not just in practice, but in principle.

A feature can be localized: adding a billing screen requires changing the billing
module, the UI, and the API. The scope is tractable. Security cannot be localized the
same way: adding authentication to a system that was built without it requires changing
every component that calls the unauthenticated API to carry credentials, every
component that receives those calls to validate them, every integration point to handle
credential expiry, every deployment pipeline to provision credentials, and every test
to model authenticated interactions. The cost is proportional to the number of
integration points — not to the complexity of the authentication mechanism itself.

This is the key prediction: when a team estimates "6 weeks to add auth," the estimate
typically accounts for the auth middleware but not for the integration surface. The
actual cost grows with system complexity in a way that feature debt does not.

The same mechanism applies to reliability: a system designed without replication,
circuit breakers, and load-shedding requires rebuilding its dependency graph to add
them — not adding a resilience module.

The practical implication is that security reviews must happen at design time, before
the integration surface is established, because the intervention cost is lowest then.
The design document with mandatory security and reliability sections is the
operationalization: forcing engineers to articulate invariants before implementation
begins is when the emergent-property regression is cheapest to prevent.

A system can have no individual component vulnerabilities and still be insecure at the
system level — because the emergent property of security is a global property that
exists or does not exist at the architectural level.

______________________________________________________________________

## A1 — Past Application (From Cases.md)

### Payment Processing System Design — Security and Reliability Tradeoffs Cascade (C15)

A worked example from the book demonstrates emergent-property coupling directly.
Building a payment processing service:

- Using a third-party payment provider removes security risk (no card data stored) but
  introduces reliability risk (dependency on provider SLA).
- Adding a message queue to buffer transactions during provider outages reintroduces
  security risk (payment data at rest, even temporarily).
- Adding a second provider for redundancy introduces additional API complexity and new
  security exposure surface.

Each mitigation creates a new tradeoff only visible when security and reliability are
analyzed as an integrated system. No individual decision is wrong in isolation — the
risk cascade is an emergent property of the design as a whole.

**Outcome**: The correct resolution requires explicitly choosing which failure mode is
acceptable for the specific threat model at design time, not during an incident. The
case is used throughout the book as a touchstone: the decision must be made before the
integration points are established, or it becomes a retrofit problem.

### Chrome — Security Designed in Vs. Bolted on (C10, C11)

Chrome's security team was established in 2008, one year after launch — but "late"
in this context was still early enough to influence architecture. Site Isolation
(process isolation per site) was identified as a necessary security property in 2012.
The project took six years rather than the estimated one — because changing a browser's
renderer process model after the initial architecture is established requires rebuilding
a substantial portion of the integration surface. The security property was sound; the
retrofit cost was six years of engineering.

**Outcome**: Site Isolation shipped in 2018 and provided the coincidental benefit of
partially mitigating Spectre. The case demonstrates both the value of designing security
in early (Chrome's 2008 multiprocess architecture was designed in) and the cost of
retrofitting a security property that was identified after the architecture was locked.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Scenario: Startup Adding Authentication to an Internal Admin API 18 Months Post-Launch

A startup's MVP was built with no authentication on the internal admin API ("it's
internal, only our team uses it"). After Series A funding, a security review identifies
this as a critical gap. Engineering estimates 6 weeks. The team asks why the security
team is pushing back on the estimate.

**Framework prediction**: The 6-week estimate likely accounts for the authentication
middleware but not for the integration surface. The actual cost includes:

1. **Discovering all call sites**: Every microservice or tool that calls the admin API
   must be updated to carry credentials. If internal services evolved organically for
   18 months, call sites may not be fully inventoried.
2. **Credential provisioning at deployment time**: Every service that calls the API
   needs credentials at deploy time. The deployment pipeline must provision these,
   which may require changes to the secrets management system and every deployment
   manifest.
3. **Handling credential expiry and rotation**: All callers must handle 401s and
   re-authenticate, which requires error-handling changes across all call sites.
4. **Updating integration tests**: Every integration test that calls the admin API now
   needs authenticated credentials, which may require test infrastructure changes.
5. **Handling failure modes**: What happens when the auth service is unavailable?
   This is a new failure mode that must be designed and tested.

The 6-week estimate is for the auth middleware. The actual cost is the integration
surface multiplied by the complexity of each call site's error handling, deployment
model, and test setup.

**Emergent-property prediction**: The true cost of retrofitting authentication is
proportional to the number of integration points established in 18 months of
development — not to the complexity of the JWT library.

### Signals That Activate This Skill

- A security or reliability feature is being scoped "to add later"
- An engineering estimate for a security retrofit is lower than expected by the
  security team
- "We'll do a security audit before we launch"
- "The system is already built; now how do we secure it?"
- A post-incident finding is "we need to add X security control" to an existing system
- Any situation where security review is framed as a final gate rather than a
  design-phase activity

### Distinguishing from Adjacent Concerns

- Differs from **technical debt**: Feature debt can often be paid down module by module
  without touching other parts of the system. Emergent-property debt (security,
  reliability) cannot be paid down locally — it requires architectural-level changes
  because the property is global.
- Differs from **"bolt-on security is just hard"**: The book provides a precise
  mechanism — emergent vs. feature property — not just a difficulty observation. This
  distinction matters because it explains when retrofit is feasible (when the
  integration surface is small) vs. when it requires a partial rewrite.
- Differs from **fail-safe-vs-fail-secure-design-time-decision**: That skill is about
  a specific design-time choice within a resilient system. This skill is about the
  upstream question: why that choice must be made at design time at all.

______________________________________________________________________

## E — Execution Steps (With Completion Criteria)

1. **Diagnose whether the property in question is a feature or an emergent property**

   - Ask: Can this property be satisfied by changing one component without changing
     its callers, its dependencies, or the deployment pipeline?
   - If yes: it is a feature (localized). Standard retrofit estimation applies.
   - If no: it is an emergent property (global). Proceed to Step 2.
   - Completion criteria: Property type is explicitly classified; team agrees on
     the classification before estimation begins.

2. **Map the integration surface for the retrofit**

   - If retrofitting: identify every integration point affected by adding this property.
     For authentication: every caller, every callee, every deployment manifest, every
     test, every monitoring system that checks for auth failures.
   - Document the count of integration points. This number (not the complexity of the
     security mechanism) drives the estimate.
   - Completion criteria: Integration surface is documented; estimate is revised to
     include each integration point's modification cost.

3. **Identify the minimum intervention point (design review)**

   - If still at design phase: mandate security and reliability sections in the design
     document before implementation begins. These sections articulate: (a) the security
     invariants the system must maintain, (b) the failure modes under adversarial
     conditions, (c) the trust boundaries between components.
   - If post-design: use the integration surface map from Step 2 to sequence the
     retrofit from the highest-trust boundary inward (add authentication at the
     perimeter first; propagate credential-carrying inward from there).
   - Completion criteria: Security invariants are written down and agreed before
     implementation proceeds.

4. **Evaluate partial vs. full retrofit feasibility**

   - Not all retrofits require a full rewrite. Evaluate: can an enforcing proxy be
     placed at the integration point to intercept and authenticate calls without
     modifying internal services? (ZTP safe proxy model applied as a retrofit mechanism.)
   - If yes: the proxy buys time while internal services are migrated. Document the
     proxy as a temporary control with a migration plan, not a permanent solution.
   - Completion criteria: Retrofit scope is defined as either proxy-first (feasible)
     or architectural change required (estimate accordingly).

5. **Design the security review cadence for future work**

   - Establish design review as the mandatory security review point, not pre-launch.
     Security review at pre-launch finds architectural problems too late to fix without
     slipping the launch.
   - Implement mandatory security and reliability sections in all design documents.
     If a design document is approved without these sections, security review is not
     complete regardless of other approvals.
   - Completion criteria: Design document template includes security and reliability
     sections; security review sign-off is a prerequisite for implementation approval,
     not launch approval.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- **The system has clean, narrow interfaces**: If the system was designed with explicit
  interface contracts and low coupling, adding a security control may be tractable even
  post-design. The emergent-property problem is worst in systems with tangled
  dependencies. Evaluate the integration surface before assuming the worst case.
- **The security property is truly isolated**: Some security additions are localized —
  adding rate limiting at the edge (where all traffic passes through a single point)
  may not require changes to internal services. Not all security controls are emergent
  in all systems.
- **The question is only about reliability**: While reliability is also an emergent
  property by the same mechanism, the specific advice and skill set for reliability
  retrofitting (circuit breakers, replication, load shedding) differs from security
  retrofitting. Use reliability-specific skills for reliability-only questions.

### Failure Modes Warned About in the Book

- **"We'll harden it at launch"**: The book explicitly identifies this as the canonical
  deferred-emergent-property failure. Launch gates find the architectural property
  missing but the integration surface fully established, producing either a slip (retrofit
  under time pressure) or a launch with the property absent.
- **Underestimating retrofit cost by ignoring integration surface**: The book's
  prediction: "accommodating security and reliability requirements in an existing system
  often requires significant design changes, major refactorings, or even partial
  rewrites." This is not pessimism — it is the mechanism in action.
- **Tactical bug-fixing as a substitute for architectural repair**: If the system's
  dependency structure makes certain invariants unenforceable, bug-fixing individual
  vulnerabilities does not change the structural property. New vulnerabilities will
  appear in the same class until the architecture is changed.

### What This Is Easily Confused With

- **Technical debt (general)**: Not all technical debt is emergent. Feature debt is
  local and can often be paid module by module. Emergent-property debt requires the
  architectural refactoring that general technical debt management does not prescribe.
  The distinction matters for estimation and prioritization.
- **"Security takes time"**: The book's claim is more specific than difficulty: emergent
  properties have a structural explanation for why they cannot be added after the fact.
  This explanation produces testable predictions (retrofit cost is proportional to
  integration surface) that "security is hard" does not.

______________________________________________________________________

## Related Skills

- **composes_with**: tcb-identification-minimization — TCB identification is the positive design-time prescription for bounding security scope; this skill explains why that work must happen at design time and cannot be deferred
- **contrasts_with**: fail-safe-vs-fail-secure — fail-safe/fail-secure is a specific design-time choice within a properly designed system; security-as-emergent-property explains structurally why that choice (and all security choices) cannot be made after the integration surface is established

______________________________________________________________________

## Audit Information: V1✓/v2✓/v3✓ — 2026-05-04

- **Source IDs**: f18, p01
- **Verification**: All three validation tests passed (cross-domain, predictive power,
  exclusivity) — see verified.md entry for f18+p01
