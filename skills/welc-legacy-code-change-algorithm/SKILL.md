---
name: welc-legacy-code-change-algorithm
description: |
  Use this skill when a user needs to make ANY change to a codebase that has no tests
  — or insufficient tests — around the area to be changed.

  WHEN TO CALL: A user describes needing to (a) add a feature to a class or module
  with no tests; (b) fix a bug in code they are afraid to touch; (c) refactor legacy
  code safely; (d) get a class under test when it currently has none; (e) add tests
  retroactively to existing code before modifying it; (f) make changes to a class
  that has heavyweight constructor dependencies.

  WHEN NOT TO CALL: Do not call when the user is writing new code from scratch with
  no existing legacy to integrate with — that is greenfield TDD territory. Do not call
  when the question is specifically about HOW to break a particular dependency
  (use welc-seam-model or welc-sensing-vs-separation for that). Do not call when the
  user's code already has comprehensive tests around the change area and they just
  need to add behavior — that is standard TDD.
tags: [legacy-code, change-management, testing, dependency-breaking, characterization-tests, process]
---

# The Legacy Code Change Algorithm

## R — Original Text (Reading)

> **Legacy code** is simply code without tests.
>
> — Michael C. Feathers, *Working Effectively with Legacy Code*, Preface
>
> ______________________________________________________________________
>
> When you have to make a change in a legacy code base, here is an
> algorithm you can use:
>
> 1. Identify change points.
> 2. Find test points.
> 3. Break dependencies.
> 4. Write tests.
> 5. Make changes and refactor.
>
> The day-to-day goal in legacy code is to make changes, but not just
> any changes. We want to make functional changes that deliver value
> while bringing more of the system under test.
>
> — Michael C. Feathers, *Working Effectively with Legacy Code*, Chapter 2
>
> **The Legacy Code Dilemma**: When we change code, we should have tests
> in place. To put tests in place, we often have to change code.
>
> — Michael C. Feathers, *Working Effectively with Legacy Code*, Chapter 2

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The algorithm is a SEQUENCED INTERVENTION PROCEDURE — not a checklist. The specific
ordering of the five steps is the core insight: each step constrains and enables the
next. Most of the errors teams make when working with legacy code come from executing
a partial or reordered version of this sequence.

### The Foundational Redefinition

Feathers' operational definition of legacy code — code without tests — is the premise
on which the entire algorithm rests. It deliberately excludes quality judgments, age,
and authorship. Well-structured, readable, elegantly factored code without tests is
still legacy code in this framework, because the mechanism for knowing whether a change
preserved behavior is absent. The aerial gymnastics metaphor captures this: performing
without a net is dangerous regardless of the gymnast's skill level.

### The Legacy Code Dilemma and Why It Requires an Algorithm

The bootstrap paradox sits at the center of all legacy work: you should have tests
before changing code, but getting tests in place often requires changing code (to
break dependencies, to parameterize constructors, to extract interfaces). This mutual
dependency cannot be resolved by willpower or care — it requires a structured escape
sequence. Steps 1–2 define exactly what needs to change and where the test points
are. Step 3 performs only the mechanical dependency-breaking transformations that are
safe to do without tests. Step 4 gets tests in place before behavior is touched. Only
then does Step 5 make the actual change.

### Step-by-Step Analysis

**Step 1 — Identify change points**: Before writing a single test, determine EXACTLY
which methods, functions, or code locations must change to implement the desired
behavior. This is a scoping step, not a coding step. Its purpose is to prevent a
common failure mode: writing tests for the entire class when only one method needs
to change, wasting effort on characterizing behavior that is not at risk. Change points
are discovered by reading the code and asking: "If I implement the new behavior, what
will I actually have to edit?"

**Step 2 — Find test points**: Trace outward from each change point. A test point is
a location in the code where the effects of a change can be observed from a test.
This is typically a return value, a parameter to a collaborating object, a side effect
you can intercept, or a state query on the class itself. The test point is not
necessarily adjacent to the change point — it may be several levels up in the call
graph. (When multiple change points feed a single test point, that test point is a
"pinch point" — see `welc-interception-point-selection`.) The goal is to identify
the minimum set of locations where tests must be placed to detect regressions from
the changes in Step 1.

**Step 3 — Break dependencies**: With change points and test points identified, the
scope of dependency-breaking is now precisely defined. You break only the dependencies
that prevent you from writing tests at the test points identified in Step 2. This is
the minimum-viable dependency-breaking principle: do not refactor the entire class;
do not generalize every dependency; do not introduce abstractions beyond what is needed
to get the specific test points under test. Techniques include Parameterize Constructor,
Extract Interface, Extract and Override Call, Subclass and Override Method, and ~20
other named techniques in Chapter 25. Crucially, these transformations are designed
to be applied mechanically, without prior tests, because they are structural changes
(not behavioral ones). If you are uncertain whether a transformation is safe to apply
without tests, it is not a dependency-breaking transformation — it is a refactoring
that requires Step 4 first.

**Step 4 — Write tests**: Now that the code is testable at the identified test points,
write characterization tests — tests that pin the EXISTING behavior of the code, not
the desired behavior. These tests use the actual output of the code as the expected
value. Their purpose is not to verify correctness; it is to detect any change in
behavior. The characterization test suite is the safety net. Once it exists, any
regression introduced by Step 5 is immediately visible. Write enough tests to cover
the behavior reachable from each test point that is at risk from the changes in Step 1.
Then, and only then, write the tests for the NEW behavior.

**Step 5 — Make changes and refactor**: With a safety net in place, implement the
required behavior. Because the change points were identified in Step 1, you know
exactly what to touch. Because characterization tests exist, any unintended behavioral
side effects are caught immediately. Refactoring is now safe: the test suite detects
any regression as soon as it is introduced.

### The Order Constraint

The sequence is a logical dependency chain:

- You cannot correctly scope Step 3 without Step 1 (you don't know what to make testable)
- You cannot correctly scope Step 3 without Step 2 (you don't know where to make it testable)
- You cannot safely execute Step 5 without Step 4 (no net = Edit and Pray)
- Step 3 cannot follow Step 4 — characterization tests break if the dependency-breaking
  transformation changes observable behavior, invalidating the net before it is fully set

### The Governing Principle: Leave More Tests Than You Found

Each application of the algorithm must leave more tests in place than existed before.
The change itself is not the only output; the accumulated test coverage is the compound
interest of legacy rehabilitation. Over time, "legacy code" in Feathers' definition
recedes as the codebase gains test coverage through successive applications of the
algorithm.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Financial Industry Team — Scenario Tests Too Coarse to Drive Change (Preface)

- **Context**: Feathers was consulting with a financial industry team that had recognized
  the value of unit testing and had written tests — but the tests were large scenario
  tests that made multiple database trips and exercised large chunks of code. The tests
  were so slow that the team rarely ran them.
- **The problem**: Without the algorithm's sequencing, the team had jumped to "write
  tests" without first identifying change points (Step 1) and finding the specific
  test points closest to the code to change (Step 2). The result was full-scenario
  integration tests rather than targeted unit tests. The tests existed but gave
  insufficient, slow feedback.
- **Application**: Feathers worked with the team to break dependencies and get smaller
  chunks of code under test — precisely Step 3 applied after Step 1 and Step 2 had
  identified where to focus.
- **Result**: Smaller, faster tests around the specific change points. The team could
  run tests continuously rather than occasionally. This consulting engagement, combined
  with the observation that the same pattern appeared on nearly every team Feathers
  worked with, motivated writing the book.

### Case 2: InvoiceUpdateResponder — the Legacy Code Dilemma Stated and Resolved (Chapter 2)

- **Context**: A billing system class, InvoiceUpdateResponder, required a live
  DBConnection and a fully instantiable InvoiceUpdateServlet to construct. Neither
  was available in a test harness.
- **Step 1 (Change points)**: The billing logic methods needing changes were identified.
- **Step 2 (Test points)**: The return values and side effects of those methods — but
  they were unreachable without instantiation.
- **The Dilemma**: To write tests (Step 4), the class had to be instantiable. To make
  it instantiable (Step 3), changes were required — but changes were supposed to
  follow tests.
- **Step 3 applied**: Two conservative, mechanical transformations: (a) Primitivize
  Parameter — pass invoice IDs instead of the full InvoiceUpdateServlet; (b) Extract
  Interface — create IDBConnection so a fake can be passed. Neither transformation
  changed the runtime behavior of the class.
- **Result**: InvoiceUpdateResponder could now be constructed in a test harness with
  a FakeConnection and a list of IDs. Step 4 (tests) became possible, unlocking Step 5.

### Case 3: Every FAQ Chapter in Part II — Algorithm Steps as Chapter Organization

- **Structure**: Part II of the book is organized as a series of FAQ chapters, each
  named as a question practitioners encounter: "I Can't Get This Class into a Test
  Harness" (Chapter 9), "I Need to Make a Change, What Methods Should I Test?" (Chapter 11),
  "I Need to Make a Change but I Don't Know What Tests to Write" (Chapter 13). Each
  chapter is a specialization of one or more algorithm steps: Chapter 9 addresses Step 3
  (break dependencies) when Step 2 reveals instantiation is blocked. Chapter 11
  addresses Step 2 (find test points) through effect sketching. Chapter 13 addresses
  Step 4 (write tests) via characterization testing. The algorithm is the organizing
  structure for the entire practical portion of the book.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Adding a feature to untested code**: A developer needs to add new behavior to a
   class, module, or function that has no test coverage. The risk of breaking existing
   behavior is real but unquantified.
2. **Bug fix in code without tests**: A bug is reported in a module that has no tests.
   The developer needs to fix it without accidentally breaking the other behavior the
   module produces.
3. **Pre-refactoring safety net**: A developer knows the code is poorly structured and
   wants to refactor it, but cannot do so safely without tests to detect regressions.
4. **Onboarding to an inherited codebase**: A developer or team has inherited a codebase
   with no tests and needs to understand the change protocol.
5. **Incremental test coverage recovery**: A team has committed to increasing test
   coverage and needs a systematic process for doing so change-by-change rather than
   as a separate test-writing project.

### Language Signals (Activate When These Appear)

- "I need to add X to legacy code"
- "This class has no tests" / "there are no tests for this"
- "I'm afraid to touch this code"
- "How do I safely modify untested code?"
- "I don't want to break anything"
- "We inherited this codebase and it has no test coverage"
- "Where do I even start with this mess?"
- "I need to change X but there's no safety net"
- "This code hasn't been touched in years and nobody knows how it works"
- "I need to refactor this but I can't add tests without changing it first"

### Distinguishing from Adjacent Skills

- Difference from `welc-seam-model`: The seam model answers HOW to break a specific
  dependency once Step 3 of the algorithm has identified that dependency-breaking is
  needed. The algorithm answers the SEQUENCE: when to break dependencies, what to
  break, and why. Use the algorithm first to determine scope; use the seam model
  when executing Step 3.
- Difference from `welc-sensing-vs-separation`: That skill is the diagnostic for
  WHICH TYPE of dependency-breaking to apply (can't observe vs. can't instantiate).
  It is a sub-tool for Step 3 execution. The algorithm determines WHEN Step 3 is
  needed and what its scope is.
- Difference from `welc-characterization-test`: Characterization testing is the
  specific technique used in Step 4. That skill provides the mechanics (write-fail-
  observe-pin). The algorithm determines WHEN characterization tests are needed and
  at which test points.
- Difference from `welc-sprout-wrap-decision`: Sprout and Wrap techniques apply when
  Step 3 reveals that the class cannot be made testable in time for the change, or
  when the risk of dependency-breaking exceeds the benefit. They are alternatives to
  the full algorithm for a single change episode — not replacements for it. See the
  B section for the permanent-sprout failure pattern.
- Difference from `welc-interception-point-selection`: That skill executes Step 2 in
  detail — given multiple change points, it identifies the best test points (especially
  pinch points). It is the deep application of Step 2, not a different procedure.

______________________________________________________________________

## E — Execution Steps

Once activated, work through all five steps in order. Do not begin a later step until
the current step's completion criteria are met.

1. **Step 1 — Identify change points**

   - Ask: "To implement the required change or fix, which specific methods, functions,
     or code locations will you actually edit?"
   - List them explicitly. Not the whole class — the specific lines or methods.
   - Completion criteria: A specific, bounded list of change points exists. If you
     cannot identify change points because the code is too unfamiliar, apply
     `welc-scratch-refactoring` first to build understanding, then return here.

2. **Step 2 — Find test points**

   - Ask: "For each change point, where can the effects of a change be observed from
     test code? What return values, collaborator interactions, or state queries are
     reachable from a test?"
   - Trace outward from each change point along the call graph. Identify all downstream
     variables, return values, and effects. (Use `welc-interception-point-selection` if
     multiple change points need to be covered efficiently.)
   - Completion criteria: A test point has been identified for each change point — a
     specific location where a test assertion can be written to detect a regression.

3. **Step 3 — Break dependencies**

   - Ask: "What dependencies currently prevent me from writing tests at those test points?"
   - For each blocking dependency, identify the seam type and applying a minimum-viable
     dependency-breaking technique. Prefer techniques that are mechanical, structural,
     and do not alter runtime behavior: Parameterize Constructor, Extract Interface,
     Extract and Override Call, Subclass and Override Method.
   - Apply ONLY the techniques needed to unblock the test points from Step 2. Stop
     when those test points are reachable.
   - Use `welc-sensing-vs-separation` to diagnose each dependency: is the problem
     that you cannot observe the effect (sensing), or that you cannot instantiate
     the class (separation)?
   - Completion criteria: The code can be instantiated in a test harness, and all
     test points from Step 2 are reachable from test code.

4. **Step 4 — Write tests**

   - Write characterization tests at each test point: tests that pin the CURRENT
     behavior of the code, not the desired behavior. Use the write-fail-observe-pin
     approach from `welc-characterization-test`.
   - Then write tests for the NEW behavior you intend to add in Step 5.
   - Completion criteria: (a) Characterization tests exist at all test points and
     pass. (b) At least one failing test exists for the new behavior to be introduced
     in Step 5.

5. **Step 5 — Make changes and refactor**

   - Implement the change. The failing test from Step 4 drives the implementation.
   - Run the characterization tests after every edit. Any failure is an immediate
     regression signal.
   - Refactor as needed: the characterization tests protect existing behavior while
     the new behavior tests verify the addition.
   - Completion criteria: All tests pass — both the characterization tests (existing
     behavior preserved) and the new behavior tests (change implemented correctly).
     The codebase has more tests than it did before you started.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is about NEW code being written from scratch without legacy context —
  use standard TDD practices rather than the change algorithm.
- The code already has comprehensive test coverage around the area being changed —
  the algorithm is unnecessary overhead; proceed directly with TDD for the new feature.
- The question is specifically about HOW to break a particular dependency (not whether
  to or in what order) — use `welc-seam-model` or `welc-sensing-vs-separation` directly.

### Failure Patterns Warned by the Author

**Skipping Steps 1–2 ("clean up first")**: The most common deviation is jumping to
dependency-breaking and test-writing without first identifying the specific change
points and test points. Teams end up writing tests for the entire class when only one
method needs to change, and breaking every dependency in the class rather than just
the ones blocking their specific test points. The algorithm becomes expensive and
teams abandon it — returning to Edit and Pray.

**Skipping Step 3 ("add tests to everything first")**: Some teams attempt to cover
entire classes with tests before any change is made, without first scoping the work
to the specific change points. This produces large characterization test suites that
pin accidental behavior across the entire class, making future refactoring harder
rather than easier, and making the investment prohibitive for small changes.

**Skipping Steps 3–4 ("I'll add tests later")**: The classic Edit and Pray mode —
making changes directly without a safety net. May feel faster for a single change;
compounds risk and debt across every subsequent change.

**Permanent Sprout / Wrap: the deferred completion anti-pattern**: Sprout and Wrap
techniques (adding new code in a side-car method or wrapper class) are legitimate
for Step 5 when the risk of a full dependency-breaking pass exceeds the benefit for
a single small change. The failure mode is using Sprout or Wrap PERMANENTLY as a
substitute for eventually getting the untested code under test. Over time, a codebase
accumulates sprouted methods and wrapped classes as isolated islands of testable code
surrounding an ever-growing core of untouched, untested legacy. The algorithm is the
intended path; Sprout and Wrap are accelerations for specific episodes, not permanent
architectural patterns. Every sprouted or wrapped addition should be accompanied by a
plan (even if deferred) for bringing the original code under test.

**Over-engineering Step 3**: Dependency-breaking is bounded by Step 2. If the change
point is a 10-line method and the test point is its return value, you do not need to
extract a full interface hierarchy — you may need only to parameterize the constructor
or extract and override a single call. Teams that over-break dependencies in Step 3
invest far more time than the change justifies, reinforcing the perception that
"doing it right" is too expensive for everyday changes.

### Author's Blind Spots / Limitations

- The algorithm assumes you can identify change points (Step 1) — which requires
  enough understanding of the code to trace the change. In the most tangled legacy
  systems, this understanding itself is the blocker. Feathers' answer is scratch
  refactoring (Chapter 16), but this is a prerequisite, not a step of the algorithm.
- The algorithm is scoped to single-process, object-oriented codebases. Distributed
  systems, service meshes, and event-driven architectures introduce boundaries that
  the algorithm does not directly address — service-level seams require different
  breaking techniques (consumer-driven contracts, API versioning, integration harnesses).
- The algorithm says "make changes and refactor" (Step 5) but does not address the
  organizational dynamics of obtaining time to apply Steps 1–4. In practice, the
  investment in dependency-breaking and characterization testing is often the primary
  obstacle — teams have permission to fix the bug but not permission to spend three
  days getting the class under test first.
- Characterization tests (Step 4) pin existing behavior, but existing behavior may
  include bugs. A characterization test that pins a buggy computation will mark the
  bug as "expected" — making the test suite a protection for incorrect behavior.
  Teams must decide consciously whether to pin or fix discovered bugs during Step 4.

### Easily Confused With

- **Standard TDD**: TDD starts from a clean slate. The Legacy Code Change Algorithm
  starts from untested code and has a dependency-breaking phase (Step 3) that TDD
  does not require. The characterization test approach (Step 4) also inverts normal
  TDD — the code tells the test what the expected value is, not the other way around.
- **Big Rewrite**: The algorithm is explicitly an alternative to rewriting. It is
  incremental and scoped to the specific change at hand. The principle "make changes
  and bring more of the system under test" accumulates coverage over many applications
  of the algorithm — it never requires a stop-the-world rewrite event.

______________________________________________________________________

## Related Skills

- **welc-seam-model** — composes-with: Step 3 (break dependencies) is executed by locating seams; the seam model is the conceptual tool that makes dependency-breaking tractable and bounded.
- **welc-sensing-vs-separation** — composes-with: Step 3 uses the sensing/separation two-axis diagnostic to select the correct dependency-breaking technique for each blocking dependency.
- **welc-characterization-test** — composes-with: Step 4 (write tests) is executed using the characterization test write-fail-observe-pin approach; that skill provides the detailed mechanics of Step 4.
- **welc-interception-point-selection** — composes-with: Step 2 (find test points) is deepened by interception point selection when multiple change points must be covered efficiently via pinch points.
- **welc-sprout-wrap-decision** — composes-with: When Steps 3–4 are too risky or expensive for a given episode, sprout/wrap provides a safe alternative for Step 5 that avoids touching untested existing code.
- **welc-scratch-refactoring** — precedes: When the codebase is too unfamiliar to identify change points (Step 1), scratch refactoring builds the mental model needed before the algorithm can be entered.
- **welc-tended-untended-systems** — calibrates: The tended/untended binary determines whether the full algorithm with comprehensive characterization is warranted, or whether a lighter-touch approach is acceptable for the given system.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f01 (framework extractor) merged with p06 (principle extractor), p01 (legacy code definition), p05 (legacy code dilemma) — merged at Phase 1.5
- **Distillation Date**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Working Effectively with Legacy Code" by Michael C. Feathers (2005) — Chapter 2 — Working with Feedback, Chapters 9–25 (all instantiate steps)
