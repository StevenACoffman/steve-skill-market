---
id: welc-sprout-wrap-decision
title: Sprout/Wrap Decision — Adding Behavior to Untestable Legacy Code
description: Trigger when a developer must add new behavior to existing code that cannot be immediately tested, and must choose among Sprout Method, Sprout Class, Wrap Method, or Wrap Class.
source: [Working Effectively with Legacy Code, Michael C. Feathers, Prentice Hall, 2005]
---

## R — Reading

> "When you use sprout method, you are clearly separating new code from old code. [...] When you use wrap method, you are making new behavior a peer of old behavior. [...] I use wrap method when the new behavior is as important as the old behavior. [...] Both of these techniques are useful when the existing code is difficult to get under test."
>
> "If the class is too difficult to instantiate, consider Sprout Class. Create a new class that holds the new feature, instantiate it in the original class, and delegate to it. You don't get the best design in the world this way, but you do get safe code that you can test."
>
> "The key question you have to ask yourself is: Am I adding this technique as a temporary measure, or am I intending to leave it in place? Both sprouts and wraps can be reasonable permanent design choices, but the danger is using them as a permanent workaround for code you were never willing to get under test."

## Chapter 6 (I Don't Have Much Time and I Have to Change It); Part II (Changing Software, Multiple Chapters)

## I — Interpretation

When you cannot get existing code under test before making a change — either because testing the method would require too much setup, or because the class itself cannot be instantiated in a harness — you still have four safe options. The choice is not arbitrary: each option matches a specific structural situation.

**Sprout Method** is appropriate when the new behavior is a subordinate, distinct piece of logic relative to the existing method. You extract the new behavior into a fresh, fully-tested method and add a single call to it from the legacy method. The legacy method's intent remains legible; the new method is independently verifiable. The existing method gains one line and nothing else.

**Sprout Class** is the escalation when you cannot even instantiate the existing class in a test harness. You write a new class containing the new behavior, construct it from within the legacy code, and delegate to it. The new class is small enough to test in isolation. This is the class-level equivalent of Sprout Method — same principle, elevated scope.

**Wrap Method** is appropriate when the new behavior is co-equal in importance to the existing behavior. You rename the existing method (e.g., `processPayment` becomes `processPayment_original`), then introduce a new method under the original name that calls both the renamed original and the new behavior. The outer method now documents the full algorithm at a high level. Callers are unaware of the change.

**Wrap Class (Decorator)** is the escalation when the new behavior applies to all callers and you want to keep new and old concerns entirely independent. You create a new class implementing the same interface, delegate to the original, and add the new behavior around the delegation. The original class is untouched. This is the class-level equivalent of Wrap Method.

The techniques are bridges, not destinations. The intent is always to eventually get the original code under test and refactor properly. Code that is only ever sprouted or wrapped — never cleaned up — accumulates as a separate stratum of logic that is hard to reason about in the aggregate.

## A1 — Past Application

**Sprout Method example**: A `TransactionManager.commit()` method has 200 lines of intertwined SQL and business logic and cannot be tested without a live database. The new requirement is to log each commit to an audit trail. Rather than splice logging into the untestable body, a developer writes `logCommit(Transaction t)` with full unit tests, then adds a single `logCommit(t)` call at the top of `commit()`. The legacy method is unchanged except for that one line.

**Wrap Method example**: A `ReportGenerator.generate()` method is similarly untestable. The new requirement is to notify a monitoring system after every report run — a requirement judged as co-equal to the generation itself. The developer renames `generate()` to `generate_original()`, writes a new `generate()` that calls `generate_original()` then `notifyMonitor()`, and tests `notifyMonitor()` in isolation. The public contract is unchanged.

**Sprout Class example**: An `OrderProcessor` class requires a database connection, an SMTP server, and a legacy COM object to construct. A new requirement needs to calculate a discount rule. The developer writes a `DiscountCalculator` class with the discount logic and tests it independently. `OrderProcessor` instantiates `DiscountCalculator` and delegates to it for that step.

**Wrap Class example**: A `PaymentGateway` class is a third-party type that cannot be subclassed and cannot be modified. All callers must now have their requests timed and logged. The developer writes a `TimedPaymentGateway` implementing the same interface, delegates all calls to the original `PaymentGateway`, and adds timing/logging around each delegated call. All callers are updated to accept the interface.

## A2 — Future Trigger ★

- You need to add behavior to a method but cannot write a test for the existing method body before making the change.
- The existing class requires a database, network, or heavyweight framework object to construct — making it untestable in isolation.
- You are asked to add a cross-cutting behavior (logging, metrics, auditing) that applies to all callers of an existing class.
- A code review comment says "this new feature doesn't belong in this method" but you cannot refactor the method safely right now.
- You are under time pressure and must make a safe, reviewable change to legacy code without destabilizing it.
- You have a new feature that is conceptually a peer of an existing feature rather than a subordinate detail.
- The class you need to modify is a third-party or generated type that cannot be changed directly.

## E — Execution

**Step 1 — Can you instantiate the class in a test harness?**

```text
Can you instantiate the class in a test harness
at a cost you will actually pay?
├── YES (instantiation is straightforward or modest) → go to Step 2
└── NO  → use a CLASS-LEVEL technique
   (Treat instantiation as "NO" if it requires five or more fakes,
    in-memory databases, or stubbed external services — setup so
    expensive you won't write the tests in practice.)
           ├── New behavior subordinate to existing? → SPROUT CLASS
           └── New behavior applies to all callers?  → WRAP CLASS
```

**Step 2 — Is the new behavior subordinate or co-equal, and who must receive it?**

```text
Is the new behavior a subordinate addition
(a detail within the existing algorithm)?
├── YES (subordinate)
│     └── Does it need to reach ALL callers via the interface?
│           ├── NO (only this method's callers, through one entry point)
│           │     → SPROUT METHOD
│           │       1. Write the new behavior as a separate method with a clear name.
│           │       2. Test that method in isolation until it passes.
│           │       3. Add a single call to it from the existing method.
│           │       4. Do not touch anything else in the existing method.
│           │
│           └── YES (every caller, regardless of which method they call)
│                 → WRAP CLASS (Decorator)
│                   Sprout Method would miss callers that do not go through
│                   the sprouted-into method. To guarantee universal coverage,
│                   wrap at the class boundary. (See Step 3.)
│
└── NO (co-equal, or: "this should be visible at the top level") → WRAP METHOD
      1. Rename the existing method (append _original or _impl).
      2. Create a new method under the original name.
      3. In the new method, call the renamed original and the new behavior.
      4. Test the new behavior in isolation.
      5. The outer method is now the high-level algorithm; leave it readable.
```

## Step 3 — Class-Level Escalation Detail

```text
SPROUT CLASS
  1. Write a new class containing only the new behavior.
  2. Give it a focused, descriptive name (not "Helper" or "Util").
  3. Test it completely in isolation.
  4. In the legacy class, construct it and delegate the new behavior to it.
  5. The new class is a seam — keep its interface narrow.

WRAP CLASS (Decorator)
  1. Extract or confirm the interface the original class implements.
  2. Write a new class implementing that same interface.
  3. Accept the original as a constructor parameter (composition, not inheritance).
  4. Delegate all interface methods to the original.
  5. Add the new behavior in the delegating methods (before, after, or around).
  6. Test the wrapper class with a fake/stub of the original.
  7. Update call sites to use the interface type — they need not know which implementation they hold.
```

## Step 4 — After the Change

- Mark the legacy method or class with a TODO comment: "covered by characterization test; refactor when under full test."
- Do not use the sprout/wrap as an excuse to permanently avoid cleaning up the original.
- At the next opportunity, apply the Legacy Code Change Algorithm to get the original code under test and consolidate the logic.

## B — Boundary

These techniques apply specifically when you cannot get the existing code under test before making the change. If you can get the existing code under test first — even partially, even with a characterization test — that is always preferable; you would then refactor or extend directly rather than sprouting or wrapping.

Sprout and Wrap are not the same as Extract Method or the Decorator pattern in greenfield code. In greenfield code, you extract a method because the decomposition is inherently right. Here, you are sprouting because a safety constraint (untestability) leaves you no better option at this moment.

Wrap Class is structurally a Decorator, but the motivation is different from the GoF Decorator pattern. The GoF pattern is a deliberate design choice for composable behavior. Wrap Class is a controlled intervention in code you cannot currently change safely. The two may look identical in the output but differ in intent and longevity.

The counter-example is cumulative avoidance: code where every new feature for five years was sprouted or wrapped, and the original method has never been touched. The result is a method that nominally "does X" but actually does a fraction of X — the rest is scattered across a dozen sprouted methods that developers must discover by searching for calls into the method. The original code becomes a lie. The sprout/wrap discipline requires a matching commitment to eventually clean up.

## Related Skills

- **welc-sensing-vs-separation** — contrasts-with: When fixing either the sensing or separation axis is too invasive for the current change episode, sprout/wrap provides a way to add new tested behavior without requiring those fixes; it is the escape hatch when the normal dependency-breaking path is blocked.
- **welc-legacy-code-change-algorithm** — composes-with: Sprout/wrap is the change strategy for Step 5 when Steps 3–4 are judged too risky or expensive; it is an acceleration for specific episodes, not a replacement for the full algorithm.
- **welc-seam-model** — pairs-with: When no usable seam exists in the existing code, wrapping the original class creates a new seam at the wrapper boundary; sprouting introduces a seam at the delegation call site.
- **welc-characterization-test** — contrasts-with: Characterization tests pin the existing code before modifying it; sprout/wrap deliberately avoids touching the existing code — the two techniques represent different safety strategies for the same constraint of untestable legacy code.
