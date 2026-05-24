---
name: welc-three-goals-of-testing
description: |
  Use this skill when a user is confused about why their tests aren't working —
  why the test suite is slow and distrusted, why coverage is high but bugs still
  reach production, why TDD isn't preventing regressions, or which kind of test
  to write for a given situation.

  Trigger signals:
  - "Our tests don't seem to help" / "we write tests but still ship bugs"
  - "We have high test coverage but still ship bugs in production"
  - "Should we write unit tests or integration tests for this?"
  - "Our test suite is slow and nobody trusts it"
  - "TDD isn't catching the bugs we care about"
  - "We have a regression suite but refactoring always breaks everything"
  - "How do we know if users will actually accept this feature?"
  - Any question about the purpose, mix, or value of a test suite

  Do NOT use this skill when:
  - The question is specifically about how to write characterization tests for an
    existing legacy codebase (use welc-characterization-test instead)
  - The question is about how to apply TDD to force a specific design decision
    (use welc-property-based-design-pressure for the property/universal-quantification
    variant, or general TDD advice for the example-based variant)
  - The question is about how tended vs. untended system type changes testing
    investment decisions (use welc-tended-untended-systems instead)

  Based on: Michael Feathers, "Testing Patience" talks (GeekFest 2016, YOW! 2016,
  slide deck) combined with "Working Effectively with Legacy Code" (2005), Ch. 8–13.
source_book: "Working Effectively with Legacy Code" by Michael Feathers (2005) + "Testing Patience" talks (2016)
source_chapter: Testing Patience slide deck + GeekFest / YOW! 2016 talks; WELC Ch. 8–13
tags: [testing, tdd, characterization-tests, acceptance-tests, test-strategy, legacy-code]
related_skills: [welc-tended-untended-systems, welc-characterization-test, welc-legacy-code-change-algorithm, welc-property-based-design-pressure]
---

# The Three Goals of Testing

## R — Original Text (Reading)

> **The Three Goals of Testing**
>
> There are three distinct reasons to write tests. They are not the same reason,
> they do not share mechanisms, and conflating them produces suites that serve
> none of them well.
>
> | Goal            | What it actually does                                                                                                             | Canonical mechanisms                                           |
> | --------------- | --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
> | **Quality**     | Forces deliberate specification before or during coding. Value = the thinking the constraint demands, not the defects it catches. | TDD, property-based tests, design-by-contract, clean room      |
> | **Maintenance** | Freezes behavioral invariants so code can be safely changed or rewritten later.                                                   | Characterization tests, golden masters, regression suites      |
> | **Validation**  | Confirms that users find the system acceptable. Not verification against a spec — acceptability to people.                        | Acceptance tests, A/B tests, production rollout, user research |
>
> **The Flawed Theory**
> The common belief is: "more unit tests → fewer bugs in production." This is wrong.
> The value of a quality test (TDD, property-based) is in the deliberate thinking
> it requires, not in the bugs it catches. Quality comes from constraints that
> force thought. A developer who writes the test first and a developer who writes
> the same test afterward both produce a test that will pass. Only the first
> developer was forced to think.
>
> **Why the conflation fails**
> When teams write TDD-style unit tests as a regression safety net (quality
> mechanism for a maintenance goal), the tests are tightly coupled to
> implementation details. The test suite breaks during any refactor — exactly
> when the safety net is most needed. When teams use integration tests to force
> design thinking (maintenance mechanism for a quality goal), the tests are too
> slow and too coarse-grained to create useful design pressure. When teams use
> unit tests to validate user acceptability (testing mechanism for a validation
> goal), users don't care about unit test results.
>
> **Validation ≠ Verification**
> Verification checks whether the system meets its specification. Validation
> checks whether users accept the system. These are different questions, and unit
> tests answer neither one: they verify internal consistency at a granularity users
> never see.
>
> — Michael Feathers, "Testing Patience" (GeekFest, YOW! 2016)

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The three goals are non-overlapping. Each goal has a different mechanism, a different failure mode, and a different audience. Treating them as interchangeable is the root cause of test suites that are simultaneously large, slow, brittle, and unhelpful.

**Quality** is about the discipline of specification. The test doesn't catch the bug; the act of writing the test catches the bug by forcing the developer to state — before or during coding — what the code should do. TDD exploits this: a developer who writes a test first is forced to specify the interface and the expected behavior before implementation. Property-based tests amplify it: to write a universal property (for all x, sort(x) has the same elements as x), you must think about the function invariantly, not by example. Design-by-contract and clean-room approaches enforce the same thing: the constraint generates the thought; the thought generates the quality. The consequence is that a quality test that was written after the code, by someone who already knew what the code did, provides little quality value — it will pass trivially. The mechanism only works when the constraint is applied before or during specification.

**Maintenance** is about behavioral invariance under structural change. The purpose of a characterization test, a golden master, or a regression suite is not to specify what the code should do — it is to record what the code does do, so that future changes can be verified to have preserved that behavior. This goal has a different enemy than quality: the enemy is refactoring without a safety net. Maintenance tests must be stable under implementation change (they test behavior, not internals) and they must be fast enough to run on every commit. A maintenance test that is tightly coupled to internal structure fails when the code is refactored — precisely backwards: it breaks most when it is most needed. The canonical maintenance tool for legacy code is the characterization test: write a failing assertion, run it, accept whatever the code actually produces as the expected value, and repeat across the behavior surface.

**Validation** is the question users answer. No test suite can answer it. Unit tests, integration tests, and end-to-end tests all verify internal consistency at a level of abstraction that users never interact with. A system can pass every test and still be rejected by users because the design is wrong, the UX is hostile, the feature doesn't match their mental model, or the performance is unacceptable in real conditions. Validation requires getting the system — or a representative part of it — in front of actual users and measuring their behavior or soliciting their judgment. Acceptance tests (user-story level, written in collaboration with stakeholders) are the closest approximation inside the development process; A/B tests and production rollouts are the strongest form. The failure mode of this goal is the team that ships to staging, runs the full integration suite, passes everything, and then discovers in production that users don't use the feature.

**The "Flawed Theory" implication**: Teams that believe "more unit tests → fewer bugs in production" systematically over-invest in quality-mechanism tests while under-investing in maintenance-mechanism tests (because regressions are boring) and validation (because it's harder to automate). The result is a large, fast-running suite that doesn't survive refactoring and doesn't predict whether users will accept the product.

______________________________________________________________________

## A1 — Past Application (From the Source)

### Case 1: Steve Freeman's Team — Quality Without Validation

- **Context**: A development team applied rigorous TDD discipline. Every feature was test-driven. The unit test suite was comprehensive.
- **Which goal was served**: Quality. The TDD practice forced specification thinking before every piece of code. Design quality was high.
- **Which goal was absent**: Validation. The team had no acceptance tests. Features were technically correct but user acceptability was not tested until delivery.
- **How the framework applies**: Both goals are legitimate; neither replaces the other. A high-quality, well-designed system can still fail validation. The presence of quality testing does not fill the validation slot.
- **Conclusion**: A strong quality practice does not substitute for validation. Teams doing exemplary TDD still need a validation mechanism — acceptance tests at minimum.

### Case 2: NASA Satellite System — Deliberate Thought via Intended Functions (0.1 bugs/KLOC)

- **Context**: A NASA satellite software development program achieved approximately 0.1 bugs per thousand lines of code in production — roughly 50x better than industry average.
- **Mechanism used**: Not TDD. The program used a formal technique of writing "intended functions" before code — a deliberate specification step that forced engineers to think rigorously about behavior before implementation.
- **How the framework applies**: The quality goal is served by any constraint that forces deliberate thought. TDD is one mechanism; formal intended functions is another. The value is in the constraint, not in the specific tool. The NASA result demonstrates that quality improvement comes from the specification discipline, not from test-driven tooling per se. The bugs were not caught by tests; they were eliminated by the thinking that writing intended functions required.
- **Conclusion**: Quality mechanisms are substitutable — what matters is that specification is forced before coding. TDD is the most accessible tool for this; formal methods are more powerful; any technique that requires deliberate pre-specification serves the quality goal.

### Case 3: F# Property-Based Test — Forces Universal Quantification

- **Context**: An F# developer writes a sort function and tests it with example-based tests: `sort([3,1,2]) == [1,2,3]`. The examples pass. The developer then attempts to write a property: for all lists `xs`, `sort(xs)` should... and struggles to state the invariant.
- **How the framework applies**: The struggle to state the property is the quality mechanism working. Example-based tests allow the developer to pick convenient inputs; property-based tests force universal quantification. The difficulty of writing `∀x. sort(x)` is diagnostic: if you cannot state the invariant without exception clauses, either the invariant doesn't exist (the function is inconsistent) or the function is doing too much (it needs decomposition). The quality value is produced by the attempt to state the property, not by the test passing.
- **Conclusion**: Property-based tests are a quality mechanism with stronger design pressure than example-based tests, because they force the developer to articulate a universal law rather than a sample outcome.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **"Our tests don't seem to help"**: The team has a test suite but it doesn't feel valuable — they write tests because they're supposed to, but bugs still reach production and nobody trusts the suite. This is the signature of goal confusion: quality-mechanism tests (often TDD unit tests) used as the only layer, with no maintenance-mechanism tests to survive refactoring and no validation to confirm user acceptability.

2. **"We have high test coverage but still ship bugs"**: Coverage measures execution, not goal coverage. A team can have 90% line coverage with every test serving the quality goal and have zero maintenance tests (characterization, regression) and zero validation tests. Bugs that appear in production after refactoring are maintenance-goal failures; bugs that appear because users don't accept the feature are validation-goal failures. High coverage of the wrong goal explains the phenomenon exactly.

3. **"Should we write unit tests or integration tests for this?"**: This question is unanswerable without knowing which goal is being served. Unit tests serve quality (fast feedback, design pressure) and can serve maintenance if written at the behavior boundary. Integration tests serve maintenance (behavior is tested end-to-end, stable under implementation change) but provide almost no quality value (too slow and coarse to create design pressure). Validation requires real users. The right answer depends entirely on which goal the team is trying to serve right now.

4. **"Our test suite is slow and nobody trusts it"**: Slowness and distrust are the compound failure mode of goal confusion. The suite is slow because maintenance tests (integration, end-to-end) were used to serve quality goals — they were written to TDD style over a large surface area, making them slow and implementation-coupled. Nobody trusts it because when the code is refactored, quality-mechanism tests break (they're coupled to implementation), making refactoring feel dangerous. The solution is to separate the goals: fast quality tests run on every save; stable maintenance tests run on every commit; validation runs at release gates.

### Language Signals (Activate When These Appear)

- "our tests don't seem to help"
- "we have high test coverage but still ship bugs"
- "should we write unit tests or integration tests for this?"
- "our test suite is slow and nobody trusts it"
- "TDD isn't preventing regressions"
- "refactoring always breaks our tests"
- "how do we know if users will accept this?"
- "what's the right amount of testing?"
- "our regression suite keeps breaking"
- "we're not sure what kind of tests to write"

### Distinguishing from Adjacent Skills

- Difference from `welc-characterization-test`: That skill is the step-by-step procedure for writing maintenance-goal tests against existing legacy code (how to write a characterization test). This skill diagnoses which goal the team should be serving and why. Use this skill first to establish which goal is needed; use welc-characterization-test when the answer is "maintenance goal against an existing untested codebase."
- Difference from `welc-property-based-design-pressure`: That skill is the step-by-step technique for using property-based tests as a quality-goal mechanism — how to write invariants and use failure to state them as a design signal. This skill establishes that property-based tests serve the quality goal. Use this skill for diagnosis; use welc-property-based-design-pressure for execution.
- Difference from `welc-tended-untended-systems`: That skill addresses how much testing investment is appropriate given system type (tended vs. untended) and code lifetime. This skill addresses which kind of testing to do and why each kind exists. Both can apply simultaneously: tended-untended calibrates the investment level; three-goals determines what to invest in.

______________________________________________________________________

## E — Execution Steps

When a user presents a testing confusion or strategy question, work through these steps:

1. **Identify the symptom class**

   - Symptom: "tests don't help / coverage is high but bugs reach production" → Goal confusion diagnosis. The team is likely over-indexing on one goal while neglecting the others.
   - Symptom: "refactoring breaks our tests" → Quality-mechanism tests are being used for the maintenance goal. The tests are coupled to implementation, not behavior.
   - Symptom: "users don't accept the feature even though all tests pass" → Validation goal is absent. Tests are answering a verification question, not a validation question.
   - Symptom: "should we write unit tests or integration tests?" → Goal is unknown. Clarify the goal first; the tool choice follows.
   - Symptom: "slow suite, nobody trusts it" → Likely maintenance-goal tests written with quality-mechanism coupling. Separate by goal.

2. **Name the three goals explicitly**

   - State the Quality goal: forcing deliberate thought before coding. Mechanism: TDD, property-based tests. Value: in the act of specification, not in the bug catch.
   - State the Maintenance goal: freezing behavioral invariants for safe change. Mechanism: characterization tests, golden masters, regression suites written against behavior. Value: surviving refactoring.
   - State the Validation goal: confirming user acceptability. Mechanism: acceptance tests, A/B tests, production rollout. Value: knowing whether users will use and accept the system.

3. **Map the user's current tests to goals**

   - Ask: which tests are forcing specification (quality)? Which tests are freezing behavior (maintenance)? Which tests are confirming user acceptability (validation)?
   - A team with only TDD unit tests has quality coverage and no maintenance or validation coverage.
   - A team with only integration tests has partial maintenance coverage and no quality pressure and no validation.
   - A test suite with all three goals covered can still be misconfigured (quality tests used as maintenance tests; see step 4).

4. **Diagnose the mechanism mismatch**

   - Quality-mechanism test used for maintenance goal: the test asserts internal structure (method calls, specific intermediate values, object state) instead of observable behavior. When the implementation changes, this test breaks — but the behavior hasn't changed. Fix: rewrite as behavior-level assertion; consider whether it belongs in the maintenance layer at all.
   - Maintenance-mechanism test used for quality goal: the integration/end-to-end test is slow. It runs after the code is already written. It provides no design pressure. Fix: this test is fine as maintenance coverage; add a TDD unit test layer upstream to generate quality pressure during new feature development.
   - No validation layer: the team ships to staging, runs all tests, passes, and declares done. Fix: add at least one validation gate — user story acceptance tests written with stakeholders, or a monitored production rollout.

5. **Prescribe by goal**

   - For quality: introduce TDD or property-based testing for new code. Write the test before writing the implementation. The constraint is the mechanism.
   - For maintenance: introduce characterization tests for existing code (see welc-characterization-test). For new code, write behavior-level regression tests at the public interface, not against internal structure.
   - For validation: establish an acceptance test layer (user-story-level tests written with stakeholders), or a production rollout mechanism (feature flags, A/B tests, monitored rollout). Do not treat test-suite passage as proof of user acceptability.

6. **Apply the "Flawed Theory" correction**

   - If the team believes more unit tests will reduce production bugs: correct the model. Quality tests reduce bugs that result from inadequate pre-specification. They do not reduce bugs that result from behavioral regression (maintenance gap) or user rejection (validation gap). Prescribe specifically for the gap that exists.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The user is asking how to write a specific characterization test against a specific class**: That is a welc-characterization-test execution question, not a goal-identification question. Apply this skill if the user doesn't know why they're writing characterization tests; apply welc-characterization-test if they know why and need the how.
- **The user is asking how to use property-based tests to pressure a specific design**: That is welc-property-based-design-pressure. This skill establishes that property-based tests serve the quality goal; the other skill executes on that insight.
- **The user is asking whether to invest heavily in testing at all (not which kind)**: That is a welc-tended-untended-systems question — the answer depends on whether the system is tended or untended and what the code lifetime is.
- **The question is purely about test tooling or framework selection** (e.g., "should I use Jest or Vitest?"): The three-goals framework is tool-agnostic. Tool selection is downstream of goal selection; answer the goal question first, but tooling specifics are outside this skill's scope.

### Failure Patterns Warned About by Feathers

- **TDD unit tests as a regression safety net**: The most common mismatch. Developers write TDD-style tests, but they test internal structure (how the code works) rather than behavior (what it does). During refactoring, the internal structure changes, the tests break, and the team concludes "our tests are brittle." The real problem is that quality-mechanism tests were being asked to serve the maintenance goal. Maintenance tests must be written at the behavior boundary.
- **"We have tests so we have quality"**: Having tests in the CI pipeline does not mean the quality goal is being served. If tests are written after the code, by the same developer who wrote the code, using examples they already know pass, they provide near-zero quality value. The constraint must precede or accompany the specification.
- **Counting coverage as a proxy for any goal**: Coverage measures which lines were executed. It says nothing about goal coverage. A codebase can have 100% line coverage with zero maintenance value (all tests are implementation-coupled), zero quality value (all tests were written after the code), and zero validation value (no acceptance or production tests).
- **Treating staging sign-off as validation**: Passing a staging suite is verification (the system matches the spec). It is not validation (users accept the system). The distinction matters most for new features, where the spec itself may be wrong.

### Author's Blind Spots / Limitations of the Era

- **Continuous delivery changes validation economics**: In 2016, production rollouts were batch events. The rise of feature flags, progressive rollouts, and production observability means that validation in production (via monitored rollout) is now a viable default, not an edge case. Feathers' formulation treats validation as external to the development process; modern CD pipelines bring it partially inside.
- **The quality goal assumes human specification**: The "deliberate thought" mechanism requires a human to write the constraint before coding. In AI-assisted development where tests can be generated automatically, the mechanism breaks: generated tests do not require the developer to think. The quality value of TDD in an AI-assisted workflow is a genuinely open question Feathers does not address.
- **Property-based tests bridge quality and maintenance**: Feathers places property-based tests squarely in the quality column, but a well-written universal invariant also serves as a strong maintenance test — it will catch behavioral regression under refactoring. The boundary between quality and maintenance is blurrier for properties than for example-based tests.

### Easily Confused Adjacent Concepts

- **Verification vs. validation**: Verification asks "did we build it right?" (does the system match the specification). Validation asks "did we build the right thing?" (do users accept the system). All automated test suites answer verification questions. Only user-facing mechanisms (acceptance tests with real stakeholder involvement, A/B tests, production rollouts) answer validation questions.
- **Test coverage vs. goal coverage**: Coverage tools measure which code was executed. Goal coverage is not measurable by a tool — it requires inspecting what each test is actually testing (behavior vs. structure, specification vs. regression vs. acceptability). High coverage scores are compatible with zero goal coverage for any of the three goals.
- **TDD as a quality tool vs. TDD as a regression tool**: Many developers write tests after coding, in TDD style, and call it TDD. Feathers' insight is that post-hoc tests written to known-passing code provide no quality value — the constraint was never applied. What is commonly practiced as "TDD" is often regression test writing with TDD syntax.

______________________________________________________________________

## Related Skills

- **welc-tended-untended-systems** — prerequisite-for: the three goals determine which kinds of tests to invest in; tended-untended-systems uses that framework to calibrate how much of each goal to fund given the deployment model and code lifetime.
- **welc-characterization-test** — combines-with: the maintenance goal (behavioral invariants for safe change) is exactly what characterization tests implement; this skill identifies the goal, welc-characterization-test provides the step-by-step procedure for achieving it on legacy code.
- **welc-legacy-code-change-algorithm** — combines-with: the three goals clarify why step 4 of the algorithm (writing characterization tests) exists — it serves the maintenance goal, not the quality goal.
- **welc-property-based-design-pressure** — combines-with: property-based tests serve the quality goal (forcing deliberate specification); welc-property-based-design-pressure elaborates the design-feedback dimension of that quality mechanism.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f11 (framework extractor) merged with p15, p16 (quality from deliberate thought, three goals principle)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-05
