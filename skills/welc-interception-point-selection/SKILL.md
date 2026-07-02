---
name: welc-interception-point-selection
description: |
  Invoke this skill when deciding WHERE to place tests to detect the effects of a set of planned changes in legacy code. Specific triggers: a developer has identified which methods need to change but doesn't know which methods to test; there are multiple related changes spread across several classes and the question is whether to write separate tests for each or find a shared test location; a test is passing but it's unclear whether it actually covers the change point; a single test suite is needed to cover several interrelated changes.

  Do NOT invoke when: the question is how to break dependencies to get code into a test harness (see welc-seam-model or welc-sensing-vs-separation); the question is what characterization tests to write once the test location is known (see welc-characterization-test); the question is which code to change, not where to test it (see welc-legacy-code-change-algorithm).
tags: [legacy-code, testing, effect-sketching, interception-points, pinch-points, characterization-tests]
---

# Interception Point and Pinch Point Selection

## R — Original Text (Reading)

> An interception point is simply a point in your program where you can detect the effects of a particular change. In some applications, finding them is tougher than it is in others. [...] The best way to start is to identify the places where you need to make changes and start tracing effects outward from those change points. Each place where you can detect effects is an interception point, but it might not be the best interception point. You have to make judgment calls throughout the process.
>
> In general, it is a good idea to pick interception points that are very close to your change points, for a couple of reasons. The first reason is safety. Every step between a change point and an interception point is like a step in a logical argument. Essentially, we are saying, "We can test here because this affects this and that affects this other thing, which affects this thing that we are testing." The more steps you have in the argument, the harder it is to know that you have it right.
>
> A pinch point is a narrowing in an effect sketch, a place where tests against a couple of methods can detect changes in many methods.
>
> What is a pinch point, really? A pinch point is a natural encapsulation boundary. When you find a pinch point, you've found a narrow funnel for all of the effects of a large piece of code.
>
> — Feathers, Chapters 11 and 12

______________________________________________________________________

## I — Methodological Framework (Interpretation)

When you have identified change points (the specific methods or lines that must be modified), the question becomes: where do you place tests so that any unintended effect of those changes will cause a test failure?

This is a two-level problem. First, you must find all candidate interception points by tracing effect propagation outward from each change point. Second, you must choose among those candidates using two criteria.

**Effect sketching** is the technique for finding candidates. Starting at each change point, trace forward through the call graph: which variables will have different values? Which method return values will differ? Which objects downstream consume those values? Each node in this graph is a candidate interception point. The diagram is informal — bubbles and arrows on paper — and the key rule is: draw a separate bubble for each variable and each method return value that can differ at runtime because of the change.

Two things to check while sketching: (1) superclasses and subclasses may have access to instance data via protected or package-scoped fields, making them invisible contributors to effects; (2) objects passed into the changed code and held by reference may carry effects out to clients who hold the same reference.

**Interception point evaluation** — two criteria for choosing among candidates:

- **Proximity**: Closer to the change point is better. Each step between change point and interception point is a logical inference in your test. The chain is: "This change affects A, which affects B, which affects C, which is where I test." If any link in that chain is wrong, the test gives a false sense of safety. Shorter chains are more reliable. The closest candidate is usually a public method on the class being changed.

- **Accessibility**: The interception point must be reachable from test code. A private variable that would be a perfect proximity-wise interception point fails this criterion.

**Pinch points** are the special case that makes this technique powerful for multi-change scenarios. A pinch point is a single interception point (or small set of points) through which the effects of multiple change points all flow. When making several related changes across a cluster of classes, a pinch point lets a single test suite cover all of them. You do not need to break dependencies on each individual class separately — you only need to reach the pinch point.

Pinch points have a secondary value: they are natural encapsulation boundaries. When you find one, you have located a place where the code has a meaningful internal/external divide. This can guide future structural improvements.

**Counter-example — distant interception points**: Testing at `BillingStatement.makeStatement` when the change point is a private calculation method inside `Invoice` covers everything, but any test failure requires reasoning back through multiple layers to understand what actually broke. The test may also pass for the wrong reason: the calculation changed in a way that happened to produce the same statement format. Distant interception points sacrifice diagnostic precision for coverage breadth. They are justified as a starting point when individual dependencies are too hard to break, but should eventually be supplemented by closer tests.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: InMemoryDirectory — Single Class, Two Change Points (Chapter 11)

- **Situation:** `InMemoryDirectory` needs changes to both `generateIndex` and `addElement`. No tests exist.
- **Effect sketch:** `generateIndex` → `elements` collection → `getElementCount`, `getElement`. `addElement` → `elements` collection → same downstream methods. Both change points converge on `elements`, which feeds into `getElementCount` and `getElement`.
- **Interception point selection:** `getElementCount` and `getElement` are the public methods where all effects surface. They are close to the change (one hop through `elements`) and accessible from tests. These are the correct interception points — not `elements` itself (private, inaccessible) and not some higher-level caller (would add unnecessary logical steps).
- **Result:** Tests on `getElementCount` and `getElement` cover both change points. The sketch reveals there is nothing else — subclass access is not a concern because `elements` is private.

### Case 2: Billing System — Multiple Classes, Pinch Point (Chapter 12)

- **Situation:** Changes are needed in `Invoice` (constructor + `getValue`) and `Item` (new `shippingCarrier` field). Three classes — `Invoice`, `Item`, `BillingStatement` — are involved, none have tests.
- **Effect sketch:** `Invoice.constructor` → `shippingPricer` → `Invoice.getValue`. `Item.shippingCarrier` → `Invoice.getValue`. Both effect chains converge on `BillingStatement.makeStatement`.
- **Pinch point:** `BillingStatement.makeStatement` is reachable from all change points and is a single place to sense every effect. Writing characterization tests against `makeStatement` covers all three classes without breaking dependencies on each individually.
- **Limitation acknowledged:** When a separate change to `Item` also affects `InventoryControl.run`, the single pinch point breaks. The effect sketch now has two exit points — `makeStatement` and `run` — so the pinch point becomes the pair `{makeStatement, run}`. Two methods is still narrower than eight changed variables.
- **Result:** One test class against `BillingStatement` pins down the combined behavior of the entire cluster. Structural refactoring of `Invoice` and `Item` can proceed freely while these tests hold.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A developer needs to change the tax calculation logic in a `PricingEngine` class. The result feeds into `OrderSummary.getTotal()`, which is called by `CheckoutController.handleRequest()`. The developer asks: "Should I test through `getTotal` or through `handleRequest`?"
2. A team is modifying three related classes — `PaymentProcessor`, `FraudChecker`, and `TransactionLog` — for a new compliance requirement. Each class would take significant dependency-breaking effort to test individually. They ask: "Is there a way to write fewer tests and still be safe?"
3. A developer writes a test against a high-level endpoint after making a change to a private method deep inside a service. The test passes. They ask: "Can I trust that this test is actually covering my change?"
4. An effect sketch reveals that a change in `UserProfile.updatePreferences()` can affect `NotificationService.send()`, `AuditLog.record()`, and `RecommendationEngine.recompute()`. The developer asks: "Do I need tests at all three, or is there a single place I can test?"

### Language Signals

- "Which methods should I test given these changes?"
- "I changed the code and the test still passes — is my test actually checking anything?"
- "Do I have to write separate test suites for each of these classes?"
- "Where is the best place to put the test?"
- "Can I test this at a higher level and cover everything?"
- "The change is deep in a private method — what do I test?"
- "Is there a pinch point here?"

### Distinguishing from Adjacent Skills

- Difference from `welc-seam-model`: The seam model answers "where can I introduce a substitution point to break a dependency?" Interception point selection answers "given that I can write tests somewhere, where is the best place?" Seam work comes first (to make testing possible), interception point selection comes after (to decide where to test).
- Difference from `welc-characterization-test`: Characterization testing is the technique used to write tests once the interception point is chosen — deliberately writing failing assertions and accepting the current output as the expected baseline. Interception point selection is the prior step: deciding which method to call in those tests.
- Difference from `welc-sensing-vs-separation`: Sensing vs. separation diagnoses whether you cannot instantiate the class (separation problem) or cannot observe its effects (sensing problem). Interception point selection assumes you have solved the sensing/separation problem and now asks which observable point gives the best test coverage.

______________________________________________________________________

## E — Execution Steps

## Step 1: Sketch Effects from Each Change Point

Starting at each change point (method or line that will be modified), trace forward through the call graph. For each outbound call or data write, ask: "Could the return value or variable value differ after this change?" If yes, draw a bubble for it and draw an arrow from the change point to that bubble. Recurse: for each new bubble, repeat the question for its consumers. Continue until you reach a system boundary (I/O, public API surface, test-observable method).

Rules for the sketch:

- One bubble per variable or method return value that can change.
- Arrows go from cause to effect (change point → affected thing).
- Check superclasses and subclasses for access to non-private fields — they are invisible clients.
- Check objects passed by reference: if a caller holds a reference to an object you mutate, the mutation escapes through that reference.

Completion criteria: every change point has been traced, and every downstream node that could have a different value at runtime appears as a bubble.

## Step 2: Evaluate Candidate Interception Points

For each bubble in the sketch, evaluate it on two criteria:

- **Accessibility**: Can test code reach this bubble directly? Private fields and local variables are typically inaccessible. Public methods on public classes are accessible. Protected methods are accessible from subclasses (test subclass is a seam). Rule out inaccessible candidates.
- **Proximity**: Count the number of arrows between the change point and this bubble. Prefer fewer steps. The ideal is a public method on the class being changed (zero or one hop). For each additional hop, the logical inference chain lengthens, increasing the risk that the test passes for the wrong reason and increasing the difficulty of diagnosing failures.

Select the accessible candidate(s) with the fewest hops as the primary interception point(s).

## Step 3: Identify Pinch Points for Multi-Change Coverage

When there are multiple change points, look for convergence in the effect sketch: a bubble that all (or most) change-point effect chains flow through. This is a pinch point.

Criteria for a valid pinch point:

- It is accessible from test code.
- Every change point has a path to it in the sketch.
- The number of methods needed to form the pinch point is small (ideally one; two or three is acceptable).

If a pinch point exists: write characterization tests at the pinch point. This single test suite covers all change points. You can then make changes across the cluster without breaking dependencies on each class individually.

If no pinch point exists: the changes are too broad or the design is too tangled. Either narrow the scope (test one or two change points at a time, as close as possible to each change) or accept multiple test locations and test each change point separately at its nearest accessible interception point.

Completion criteria: a specific method name (or small set of method names) has been chosen as the interception point. You can state the logical chain from each change point to the interception point and verify it is correct before writing tests.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is whether a dependency can be broken at all, not where to test. Use `welc-seam-model` first.
- The class cannot be instantiated in a test harness. That is a separation problem (`welc-sensing-vs-separation`) that must be resolved before interception point selection is meaningful.
- The codebase already has good unit tests at each change point. Interception point selection is a legacy-code technique for code with no existing tests. In well-tested code, you already know where to add tests: adjacent to the change.
- The change is isolated to a single method with a simple, accessible return value. The "right" interception point is obvious — the method itself — and no sketching is needed.

### Failure Patterns from the Book

- **fp-distance**: Testing only at the highest reachable point (e.g., an HTTP endpoint) when the change is inside a private calculation method. The test may pass for reasons unrelated to the change. Diagnosis when it fails requires mentally tracing through the entire call stack. If you are stuck with a distant interception point and are unsure whether your test is genuinely sensitive to the change, verify it: make a small deliberate break at the change point (e.g., return a wrong value or skip a step) and confirm the test fails. If the test still passes, your interception point is not connected to the change and you must find a closer one.
- **fp-inaccessible-private**: Identifying a private variable as the "best" interception point because it is closest, then having no way to read it from test code. Solution: look for the next accessible bubble up the effect chain.
- **fp-overreach**: Trying to find a single pinch point for too many changes at once. When the sketch becomes a tangled tree, the pinch point is illusory. Solution: scope down; find pinch points for subsets of two or three changes at a time.
- **fp-missed-client**: Failing to include a subclass or external holder of a passed-by-reference object in the effect sketch, leading to an interception point that misses one effect channel. Solution: always check superclasses, subclasses, and reference-sharing callers when building the sketch.

### Author's Limitations / Era Context

- The technique is described using Java class hierarchies. In languages with first-class functions, closures, or module-level state, the "bubble for each variable and method return value" model still applies, but the graph topology looks different. Effect chains can run through function variables, channel reads, or global state rather than object method calls.
- The sketch is described as a paper/pen diagram. For large systems, the graph becomes unmanageable manually. The technique's value is in the mental discipline it enforces, not in the physical diagram itself. Modern IDEs can partially automate call-graph tracing.
- Feathers notes (but does not fully resolve) the case where no pinch point is findable. The fallback — "test individual changes as close as you can" — is correct but can still require significant dependency-breaking work if the nearest accessible interception points have difficult dependencies.

### Easily Confused Adjacent Methodology

- **Code coverage tools** measure which lines are executed by a test, but do not tell you whether a test is logically connected to a change point. A test can achieve 100% coverage of a method without the interception point being genuinely sensitive to the specific change. Effect sketching is a manual reasoning process that coverage tools do not replace.
- **Integration tests** often test at high-level interception points (API responses, database state) by default. This is fine for regression but poor for change-point coverage: when an integration test fails, the failure is distant from the cause. Pinch points at the class collaboration level are preferable to full end-to-end tests when the goal is to cover a specific cluster of changes.

______________________________________________________________________

## Related Skills

- **welc-legacy-code-change-algorithm** — prerequisite-for: interception point selection is step 2 of the five-step algorithm ("find test points"); it must be executed before any changes are made.
- **welc-characterization-test** — prerequisite-for: the interception point must be chosen before characterization tests can be written; this skill selects the target, welc-characterization-test provides the writing technique.
- **welc-seam-model** — depends-on: seams are the candidate interception points; identifying available seams is the prerequisite for evaluating which point to select.
- **welc-sensing-vs-separation** — depends-on: the axis diagnosis (sensing vs. separation) determines which interception points are viable; if sensing is not yet resolved, no candidate point is observable.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Merged from**: f06 (Interception Point Selection) + f08 (Effect Sketching)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** Working Effectively with Legacy Code — Michael C. Feathers (2005) — Chapter 11: I Need to Make a Change. What Methods Should I Test? / Chapter 12: I Need to Make Many Changes in One Area
