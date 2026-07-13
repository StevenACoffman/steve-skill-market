---
name: welc-tended-untended-systems
description: |
  Invoke this skill when someone is deciding how much testing to invest in
  a system, component, or piece of code — especially when they are asking
  whether their current test strategy is appropriate for their deployment
  model, or when they are comparing testing practices across different
  system types (firmware vs. web apps, embedded vs. cloud, regulated vs.
  rapid-release).

  Also invoke when someone is treating a tended system as if it were
  untended (e.g., demanding zero-defect pre-release verification for a
  cloud service that supports hotfixes), or treating an untended system as
  if it were tended (e.g., shipping firmware without formal verification
  because "we can always push an update").

  The skill introduces a two-axis classification: tended/untended
  (recoverability of post-deployment defects) and transient/long-lived
  (expected code lifetime). Test investment calibrates to both axes, not
  to a universal standard.
tags: [testing-strategy, risk-analysis, deployment-model, transience, firmware, cloud]
---

# Tended Vs. Untended Systems — Testing Strategy Calibration

## R — Original Text (Reading)

> **"The key qualifier is tended vs. untended systems. If someone can
> step in and fix problems, the tolerance for discovering issues in
> production is higher. If you're shipping firmware to a spacecraft
> near Pluto (where a firmware update takes hours at light speed), or
> code that controls an elevator, that calculus changes entirely.
> As systems become more tended, the case for treating production as a
> feedback mechanism — rather than a place tests protect you from —
> gets stronger."**

— Michael Feathers, *Testing Patience* (GeekFest / YOW! 2016)

> **"There's a deep assumption embedded in most testing practice: that
> the effort invested in writing tests will pay off over time because
> the code will live for a long time. This assumption isn't always
> true... if code is transient — if it's going to be thrown away in a
> month anyway — the calculus around how much testing investment it
> warrants changes. Fred George's arbitrage business operated on that
> logic. The code was genuinely meant to be temporary."**

— Michael Feathers, *Testing Patience* (YOW! 2016) — transience calibration

> **"The right testing approach is contextual. It depends on whether the
> system is tended or untended, how critical the code is, how transient
> the codebase is intended to be, and what feedback loops are
> available."**

— Michael Feathers, *Testing Patience* (GeekFest / YOW! 2016)

## I — Methodological Framework (Interpretation)

Most testing advice is delivered as a universal prescription: "have good
test coverage," "write tests first," "aim for 80% line coverage." This
prescription ignores a variable that determines whether heavy pre-release
testing is the right investment at all: the consequences of discovering a
defect in production.

Feathers' framework introduces a binary that precedes all other testing
decisions.

**Tended system**: A system where someone can intervene after deployment.
Problems discovered in production can be addressed quickly. Examples:
cloud services, web applications, mobile apps with forced update
mechanisms, microservices behind a gateway. In tended systems, production
is a feedback mechanism. Progressive rollouts, feature flags, and rapid
hotfixes are available levers. Heavy pre-release verification can be
premature — it may create slow, fragile pipelines that slow iteration
without meaningfully reducing defect risk.

**Untended system**: A system that cannot be patched or rolled back after
deployment. Problems discovered in production cannot be quickly fixed.
Examples: firmware shipped to vehicles, medical devices, spacecraft,
embedded systems, regulated software with multi-month certification
cycles. In untended systems, pre-deployment verification is the only
defect-detection mechanism. There is no "ship it and fix it." The
consequences of a post-deployment defect — unretrievable, legally
significant, or fatal — justify exhaustive pre-release investment.

The binary determines the answer to "how much testing is enough?" Before
that question is answerable, you must classify the system.

**The transience dimension** (absorbed from f16): The tended/untended
axis answers the recoverability question. A second axis answers the
longevity question: how long will this code exist?

Most testing investment assumes long-lived code. The ROI argument for
comprehensive tests depends on that code being maintained, extended, and
debugged over months or years. For short-lived code — a feature-flag
experiment that will be torn out in three months, a one-time data
migration script, a throwaway prototype — the same ROI argument fails.
The tests will be deleted with the code. The defects they might catch
will never manifest in production at scale.

The two axes combine into a decision matrix:

|                | Tended                                                               | Untended                                                                         |
| -------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Long-lived** | Calibrate by component risk; iterate toward coverage                 | Rigorous pre-deployment verification; characterization + contract tests          |
| **Transient**  | Minimal testing; production feedback is fast and code is short-lived | Rare but possible (short-run regulated systems); verify the specific risk window |

Feathers' examples bracket the space:

- **NASA 40,000-line Fortran satellite** (untended + long-lived): Allan
  Stavely's clean room process achieved < 0.1 bugs/KLOC in three years of
  production. The satellite could not be patched at speed-of-light
  distance. Zero-defect process was not perfectionism — it was the only
  rational response to the deployment model.
- **Fred George's Programmer Anarchy** (tended + transient): Online
  arbitrage microservices built in any language, with no managers and
  minimal testing. Code lived for weeks before the business opportunity
  closed and the service was discarded. Comprehensive test coverage would
  have cost more than the service generated.
- **Web application** (tended + variable lifetime): Core billing logic is
  long-lived and warrants investment; a feature-flag experiment running for
  one sprint is transient and warrants less.

## A1 — Past Application (From the Talks)

### Case 1: NASA Satellite-Control System — Untended + Long-Lived → Clean Room (C13)

**Problem**: Allan Stavely's team was building 40,000 lines of Fortran for
a NASA satellite-control system. Once launched, the satellite could not
receive a patch at the latency of light-speed communication. Any
post-deployment defect was effectively permanent.

**Method**: Clean room process. Every piece of code was accompanied by a
formal "intended function" predicate (precondition/postcondition). Teams
held intensive review sessions using those predicates. No unit tests were
written in the modern sense — quality came from formal specification and
group verification of intent before code was ever executed.

**Conclusion**: The system produced 4.5 bugs/KLOC during development
testing (where they could be caught) and fewer than 0.1 bugs/KLOC in
three years of production use. This is an order-of-magnitude improvement
over standard practice.

**Result**: Feathers uses this case to demonstrate that pre-deployment
investment is not optional when the system is untended. The clean room
process was labor-intensive and not widely adopted — but the underlying
rationale (exhaustive verification before deployment) is non-negotiable
for untended systems.

______________________________________________________________________

### Case 2: Fred George's Programmer Anarchy — Tended + Transient → Minimal Testing (C16)

**Problem**: Fred George's team was building online arbitrage software.
The business model was transient by design: spot a supplier with surplus
inventory, build a microservice to test demand, resell the inventory, then
retire the service. Each service might be live for a month.

**Method**: No managers, any programming language, minimal testing,
no refactoring. The team called these microservices before the term had
wide currency. Every standard engineering practice was evaluated against
the question: "Will this service still exist long enough for this
investment to pay off?" Usually the answer was no.

**Conclusion**: The business was profitable. The experiment demonstrates
that testing constraints are not universal laws — they are responses to
specific assumptions about code lifetime and deployment recoverability.

**Result**: Feathers explicitly notes this approach does not generalize
to 90% of organizations. The enabling conditions — highly skilled team,
genuinely disposable domain, fast feedback from market reality — are rare.
But the logic is sound: when code is transient and the system is tended,
minimal testing is the correct calibration, not negligence.

______________________________________________________________________

### Case 3: Counter-Example — Treating a Tended System Like an Untended One

**Problem**: An engineering team building a cloud-hosted web application
demands zero-defect pre-release verification on every feature. All changes
require comprehensive integration test suites, manual QA sign-off, and
two-week testing cycles. The team has full rollback capability, feature
flags, and a progressive rollout infrastructure.

**Conclusion**: The team has classified a tended system as if it were
untended. The two-week test cycle slows iteration. The defects that reach
production are addressed via rollback within hours. The ROI of the
extensive pre-release investment is negative compared to the cost of the
delayed delivery.

**Result**: The correct calibration for a tended system is to invest
proportional to the lifetime and risk of each component, use progressive
rollout to catch defects in low-blast-radius stages, and reserve heavy
pre-release verification for components where production feedback is too
slow or costly (e.g., data corruption bugs, security vulnerabilities,
billing logic errors).

## A2 — Trigger Scenario (Future Trigger) ★

1. **"We need to decide how much testing to invest in before launch"**: The
   first question to ask is whether the system is tended or untended. If
   the team can push a hotfix within hours, the launch-testing calculus is
   different from firmware going to 10 million devices.

2. **"Our test suite is slow and we want to cut coverage"**: Before cutting,
   classify each test's target code on both axes. Transient code with
   tests can be cut. Long-lived untended code with sparse coverage is a
   risk. Tended code with redundant integration tests is a candidate for
   selective reduction.

3. **"Should we write tests for this migration script / experiment / spike?"**:
   Is the code transient? If the script runs once and is deleted, and the
   system is tended, minimal testing is the correct answer. Write tests
   only for the highest-risk operations (the parts that could corrupt data
   if wrong).

4. **"Our firmware team wants to adopt continuous delivery"**: Untended
   systems cannot borrow the tended-system playbook. Before adopting CD
   practices, identify which deliverables are truly untended (OTA-updateable
   firmware differs from chip-burned ROM). The untended components still
   require exhaustive pre-deployment verification regardless of pipeline
   automation.

5. **"Why do aerospace/medical teams have such different testing practices
   from web teams?"**: The deployment model difference explains the practice
   difference entirely. It is not conservatism or bureaucracy — it is the
   correct response to an untended system.

### Language Signals

- "How much testing do we need before we ship?"
- "Is our test coverage good enough?"
- "Should we write tests for this one-time script?"
- "Our release process is too slow — can we cut some testing?"
- "What's the right testing approach for embedded / firmware / medical?"
- "Our web team says we over-test — are they right?"
- "This feature might be retired in a month — should we still write full tests?"
- "We ship to devices that can't be updated in the field"

### Distinguishing from Adjacent Skills

- **welc-three-goals-of-testing**: That skill asks "which goal is this test
  serving?" (Quality / Maintenance / Validation). This skill asks the prior
  question: "how much total investment is warranted?" The two compose: after
  classifying the system as tended+long-lived, use the three-goals framework
  to allocate that investment across test types.

- **welc-characterization-test**: That skill provides the technique for
  building pre-deployment safety nets on legacy code. For untended systems,
  characterization tests are the primary pre-deployment verification
  mechanism. The tended/untended classification determines whether you need
  them urgently.

- **General coverage targets** (e.g., "aim for 80% line coverage"): Coverage
  targets are a proxy for quality, not a strategy. They do not condition on
  deployment model or code lifetime. A 20% covered tended microservice with
  progressive rollout may be safer than a 95% covered untended firmware with
  poor test quality.

## E — Execution Steps

## Step 1: Classify Tended or Untended

Ask: "If a defect reaches production, can we fix it quickly?"

- **Untended indicators**: shipped firmware, ROM-burned code, medical devices,
  spacecraft, long certification cycles (regulatory approval takes months),
  no OTA update capability, or update delivery is measured in days/weeks
  rather than minutes.
- **Tended indicators**: cloud-hosted service, web application, mobile app
  with forced-update support, microservice behind a load balancer with
  rollback, feature flag infrastructure, progressive rollout capability.

If untended: pre-deployment verification is your primary defect-detection
mechanism. Invest heavily. Skip or compress this investment only if you
can articulate the specific recovery path for every failure mode.

If tended: production is a feedback mechanism. Progressive rollout, feature
flags, and rapid hotfixes are available. Calibrate test investment by risk
per component, not as a flat rule across the codebase. Move to Step 2.

Completion criterion: you can state whether each major component being
changed is tended or untended, and you can describe the recovery path
(or lack of one) for a typical production defect.

## Step 2: Estimate Code Lifetime

Ask: "How long will this code exist in production?"

- **Transient indicators**: feature-flag experiment with a defined sunset
  date, one-time migration script, throwaway prototype, arbitrage-style
  microservice with a business lifetime measured in weeks.
- **Long-lived indicators**: core business logic, billing system, public
  API, authentication service, data model, anything that has been in the
  codebase for more than one product cycle.

If transient: test investment has a negative ROI beyond a baseline level.
Write tests only for operations where a defect in the short lifetime would
be catastrophic (e.g., a migration script that could corrupt data). Skip
comprehensive behavioral coverage.

If long-lived: standard test investment arguments apply. The ROI calculation
for a comprehensive test suite is positive because the tests will be read,
maintained, and relied upon over many change cycles.

Completion criterion: you can assign each code unit under review to one of
four quadrants: tended+transient, tended+long-lived, untended+transient,
untended+long-lived.

## Step 3: Calibrate Test Investment to the Quadrant

Apply the investment level appropriate to the quadrant:

- **Tended + transient**: Minimal. Test only catastrophic failure paths
  (data corruption, security, money). Skip behavioral coverage. Plan to
  delete the tests when the code is retired.

- **Tended + long-lived**: Standard or above. Invest in characterization
  tests for legacy code, unit tests for new logic, integration tests for
  high-risk interactions. Use progressive rollout to catch regressions
  that tests miss. Calibrate coverage to component risk, not uniformly.

- **Untended + long-lived**: Rigorous. Pre-deployment verification is the
  only defect-detection layer. Invest in formal or semi-formal
  specification, contract tests, characterization tests, and coverage
  sufficient to justify confidence. Treat every untested path as a known
  risk to be tracked, not ignored.

- **Untended + transient**: Rare. Example: a short-run regulated process
  with a fixed end date. Classify the specific risk window — what defects
  are possible and what are their consequences? Verify those paths
  explicitly, even if the code is short-lived. If the defect cost is high
  even for a brief lifetime, treat as untended+long-lived.

Completion criterion: for each component, you can state the investment
level (minimal / standard / rigorous), the rationale (quadrant + risk
profile), and the mechanisms chosen (which test types, at which layers).

## B — Boundary ★

## When NOT to Use

- **Pure mechanics questions**: "How do I write a table-driven test?" or
  "How do I mock this interface?" are technique questions, not strategy
  questions. Invoke this skill before choosing techniques, not during.

- **When the quadrant is already known and agreed**: If the team has already
  classified the system and established an investment level, don't
  re-litigate the classification on every feature. The skill is a
  decision-point tool, not a recurring checklist item for every code change.

- **Compliance-driven testing**: Some regulated industries mandate specific
  test artifacts (DO-178C for avionics, IEC 62304 for medical devices)
  regardless of Feathers' framework. In these contexts, the classification
  is predetermined by certification requirements. The skill can explain
  why those requirements exist, but it cannot override them.

## Failure Patterns

- **Defaulting to untended behavior for tended systems**: Teams shipping
  cloud software often apply aerospace-level verification because it "feels
  safer." The result is slow pipelines, brittle integration tests that
  break on unrelated changes, and delayed releases. The safety feeling is
  real; the safety gain is not proportional to the cost.

- **Assuming "tended" means "untested is fine"**: The tended classification
  does not eliminate the need for testing — it changes the optimal
  investment level and permits production to serve as a feedback mechanism.
  Shipping with zero tests to a tended system that lacks feature flags,
  rollback, or monitoring is not a tended deployment; it is an unmonitored
  one.

- **Treating transience as permanent**: Code intended to be transient
  frequently becomes permanent when the business opportunity persists
  longer than expected, or when the "temporary" solution is too entrenched
  to remove. Before assuming transience, identify who owns the retirement
  decision and whether a sunset date is enforced. If it is not enforced,
  treat the code as long-lived.

- **Treating an experiment as uniformly transient when it has a conditional long-lived path**: Some code starts as an experiment but carries a promotion path — "if validated, this becomes core infrastructure." In these cases, the correct calibration is not uniform transience or uniform long-lived treatment, but layer-specific treatment: the core logic that would survive promotion (algorithm, data model, API contract) should be treated as long-lived and tested accordingly; the scaffolding that would be removed on promotion or deletion (feature-flag wiring, experiment harness, A/B routing) is genuinely transient and warrants minimal testing. Ask: "If this experiment succeeds, which code survives?" Test that code as long-lived. Ask: "If this experiment is killed, which code is deleted?" Treat that code as transient.

- **Applying the quadrant to the system rather than the component**: A
  large system may contain both tended and untended components (e.g., a
  cloud service with an embedded edge agent that ships firmware to IoT
  devices). Classify at the component level, not the system level.

## Author Blind Spots

- **No explicit guidance on monitoring as a tended-system complement**:
  Feathers' framework treats production feedback as "someone can step in,"
  but modern tended systems also depend on observability infrastructure
  (structured logging, distributed tracing, error budget monitoring) to
  make production feedback actionable. The tended/untended binary is
  necessary but not sufficient — a tended system without monitoring
  degrades toward effectively untended in practice.

- **The transient/long-lived boundary is not quantified**: Feathers
  illustrates with clear extremes (one-month arbitrage vs. multi-year
  billing logic) but does not provide a threshold. In practice: code that
  is expected to survive more than two or three product cycles should be
  treated as long-lived. Code tied to a specific experiment or event with
  a confirmed retirement plan should be treated as transient.

- **Fred George's Programmer Anarchy does not generalize**: Feathers
  acknowledges this explicitly. The enabling conditions (elite team, purely
  disposable domain, rapid market feedback, no legacy burden) are rare.
  Most teams claiming "our code is transient" are using it as cover for
  under-investment, not as a genuine architectural stance.

## Easily Confused Methods

- **Risk-based testing**: A general practice of prioritizing test effort
  toward high-risk code paths. Related but distinct — risk-based testing
  asks "which parts of the code matter most?" The tended/untended axis asks
  the prior question: "how much total pre-release investment is appropriate?"

- **Shift-left testing**: Moving testing earlier in the development cycle.
  Compatible with this framework but orthogonal — shift-left applies equally
  to tended and untended systems; it says when to test, not how much.

## Related Skills

- **welc-three-goals-of-testing** — depends-on: the three goals (Quality / Maintenance / Validation) are the justification framework for why different investment levels are warranted; tended-untended-systems applies that framework to decide how much of each goal to fund.
- **welc-legacy-code-change-algorithm** — calibrates: the tended/untended classification determines whether to run the full five-step algorithm (tended systems may justify shortcuts) or to invest in the complete workflow before any change.
- **welc-characterization-test** — combines-with: tended systems justify full characterization investment as a maintenance mechanism; untended systems make characterization tests urgent and non-negotiable before any change; the classification drives the urgency level.
- **welc-sprout-wrap-decision** — combines-with: untended systems may only warrant sprout or wrap techniques rather than full test coverage for surrounding legacy code; the tended/untended axis calibrates how far to extend the test safety net.

## Audit Information

- Source extraction date: 2026-05-05
- Primary sources:
  - `/Users/steve/Documents/agent-orange/books/welc/candidates/frameworks.md`, id: f12 (Tended vs. Untended Systems) and f16 (Transience Calibration)
  - `/Users/steve/Documents/agent-orange/books/welc/candidates/principles.md`, id: p18 (Tended vs. Untended Systems Determine the Right Testing Strategy)
  - `/Users/steve/Documents/agent-orange/books/welc/candidates/cases.md`, id: c13 (NASA Fortran), c16 (Fred George Programmer Anarchy)
- Verified entry: `/Users/steve/Documents/agent-orange/books/welc/verified.md`, id: f12 (merged_from: [f12, p18, f16])
- Pipeline stage: Phase 2 (RIA++)
- Version: 0.1.0

______________________________________________________________________

## Provenance

- **Source:** "Working Effectively with Legacy Code" by Michael Feathers + "Testing Patience" talks (GeekFest, YOW! 2016) — Testing Patience talks — tended/untended binary (f12, p18) + transience calibration (f16)
