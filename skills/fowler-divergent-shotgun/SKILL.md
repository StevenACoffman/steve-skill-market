---
name: fowler-divergent-shotgun
description: |
  Invoke this skill when a developer is trying to diagnose why a module is painful to change, or why a single logical change requires edits in many places. The skill applies whenever a code review or PR analysis reveals either: one class/module changes for multiple unrelated reasons (Divergent Change), or one conceptual change requires touching many different classes (Shotgun Surgery).

  Key trigger signal: "Every time I change X, I also have to change Y and Z in this same class." (Divergent Change) or "Every time I change X, I have to edit five different files." (Shotgun Surgery).

  Do NOT invoke this skill for general code smell detection across a whole codebase (use fowler-code-smells for the full smell vocabulary), or when the question is specifically about a function that is too long (Long Function smell), or when the question is about untangling feature from refactoring work (use fowler-two-hats for that).
tags: [code-smells, modularity, cohesion, refactoring]
---

# Divergent Change Vs. Shotgun Surgery — Two Inverse Modularity Failures

## R — Original Text (Reading)

> We structure our software to make change easier; after all, software is meant to be soft. When we make a change, we want to be able to jump to a single clear point in the system and make the change. When you can't do this, you are smelling one of two closely related pungencies.
>
> Divergent change occurs when one module is often changed in different ways for different reasons. If you look at a module and say, "Well, I will have to change these three functions every time I get a new database; I have to change these four functions every time there is a new financial instrument," this is an indication of divergent change. The database interaction and financial processing problems are separate contexts, and we can make our programming life better by moving such contexts into separate modules.
>
> Shotgun surgery is similar to divergent change but is the opposite. You whiff this when, every time you make a change, you have to make a lot of little edits to a lot of different classes. When the changes are all over the place, they are hard to find, and it's easy to miss an important change.
>
> A useful tactic for shotgun surgery is to use inlining refactorings, such as Inline Function or Inline Class, to pull together poorly separated logic. You'll end up with a Long Method or a Large Class, but can then use extractions to break it up into more sensible pieces. Even though we are inordinately fond of small functions and classes in our code, we aren't afraid of creating something large as an intermediate step to reorganization.
>
> — Martin Fowler, Chapter 3

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Divergent Change and Shotgun Surgery are two inverse failures of modularity. They share the same surface symptom — changes are painful — but they have opposite structures and opposite treatments.

**The "reasons to change" test** is the diagnostic tool. For every change event you can recall, ask two questions: How many modules did that change touch? How many different kinds of changes touch this one module? The answers place you on a 2×2 grid:

- One module, one reason: healthy.
- One module, multiple reasons: **Divergent Change** — the module is carrying unrelated concerns. The fix is to split it.
- One reason, multiple modules: **Shotgun Surgery** — a coherent concept is scattered across the codebase. The fix is to consolidate it.
- Multiple modules, multiple reasons: both smells are present simultaneously; start with whichever is more dominant.

**Divergent Change — the split direction.** A module that changes for two different reasons will force readers to understand both contexts even when only one context is relevant. The principle violated is that each module should have exactly one axis of change. The treatments are directional: Extract Class pulls a second concern into its own home; Split Phase separates a sequential pipeline with a clean data boundary between stages; Move Function relocates logic that clearly belongs to a different context.

**Shotgun Surgery — the consolidation direction.** Logic that is conceptually one thing but lives in many files will be missed during changes, will drift out of sync, and will make the codebase impossible to read because the "real" implementation of any concept is nowhere — it is distributed everywhere. The treatments are also directional: Move Function and Move Field pull scattered pieces together; Combine Functions into Class gathers related behaviors around shared data; Inline Function or Inline Class can be used as an intermediate consolidation step before re-extracting into a coherent structure.

The non-obvious implication is that Shotgun Surgery is sometimes cured by a temporary increase in size. Inlining everything into one place first, even if the result is a Large Class or Long Method, gives you a complete picture of the concept before you re-partition it correctly. The intermediate ugliness is intentional and short-lived.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Divergent Change — Database and Financial Instrument Contexts in One Module

- **Question:** A module changes in two distinct directions: whenever the team switches to a new database, three functions change; whenever they add a new financial instrument, four different functions change. Both groups of changes are in the same module.
- **Use of Methodology:** Fowler identifies that "database interaction" and "financial processing" are separate contexts housed in the same module. Because the contexts change for unrelated reasons, they create Divergent Change. If the two aspects form a natural sequence — get data from the database, then apply financial processing — Split Phase separates them with a clean data structure at the boundary. If they are more interleaved, Move Function redistributes the processing. If functions mix both types of logic within themselves, Extract Function separates the mixed concerns before the move.
- **Conclusion:** The module is split into at least two modules, each with a single axis of change. A database change now touches only the database module; a new financial instrument now touches only the financial processing module.
- **Result:** The cognitive load per change drops because readers only need to understand one context. The change surface is bounded and predictable.

### Case 2: Shotgun Surgery — Payment Flow Logic Scattered Across Classes

- **Question:** Every time the team changes the payment processing flow — adding a new payment method, changing validation rules, adjusting the confirmation step — they must edit five or six different classes. Changes are hard to find, easy to miss, and frequently result in inconsistent state when a file is overlooked.
- **Use of Methodology:** Fowler prescribes Move Function and Move Field to draw the scattered logic toward a single module. If a cluster of functions all operate on similar payment data, Combine Functions into Class gathers them around that data. As an intermediate step, Inline Function or Inline Class can collapse the scattered pieces into one temporarily large structure, after which Extract Class re-partitions it correctly.
- **Conclusion:** The payment flow concept now lives in one module (or a small, explicit cluster). All changes to the payment flow touch that one place.
- **Result:** Changes become easier to find and impossible to forget. The codebase makes the concept's location legible.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

**Scenario 1 — Code review finds a module with multiple unrelated change reasons:** During a PR review, a reviewer notices that the `OrderService` class was modified both because the database schema changed and because a new product type was added. These are unrelated axes — schema changes are infrastructure, product type changes are domain logic. The class has Divergent Change.

**Scenario 2 — Noticing scattered changes in a PR diff:** A PR touches `PaymentProcessor`, `PaymentLogger`, `PaymentNotifier`, `PaymentAudit`, and `PaymentConfig` — all to implement one change: making payment retries configurable. No single file contains "the" retry logic. Shotgun Surgery: the retry concept is scattered.

**Scenario 3 — Microservice boundary decisions:** A team is deciding whether to split a service or merge two services. The "reasons to change" test applies at the service level. If the service changes for multiple unrelated reasons (Divergent Change at service granularity), it may need to be split. If two services always change together for the same reason (Shotgun Surgery at service granularity), they may be better combined.

**Scenario 4 — Onboarding confusion:** A new developer asks "where does the discount calculation actually live?" and the answer is "it's in four places" — that is Shotgun Surgery. A new developer asks "what does this class do?" and the honest answer is "it handles database connections, formats output, and calculates interest rates" — that is Divergent Change.

**Scenario 5 — Sprint retrospective pain point:** "Every sprint we make a small change and it takes three times as long as expected because we keep finding other files that need to update too." This is classic Shotgun Surgery — the estimate is always wrong because the change surface is invisible until you are already mid-change.

### Language Signals

- "Every time we change X, we also have to change Y and Z in the same class" → Divergent Change
- "Every time we make a change to [concept], we have to edit [many files]" → Shotgun Surgery
- "This class does too many things" → possible Divergent Change
- "I forgot to update the [file] again" → Shotgun Surgery (the scattered change was missed)
- "Are these the same problem or different problems?" when comparing two painful change types → this skill directly

### Distinguishing from Adjacent Skills

- Difference from `fowler-code-smells`: `fowler-code-smells` covers the full vocabulary of 22+ code smells as a reference catalog. This skill is a deep-dive into one specific inverse pair — Divergent Change and Shotgun Surgery — including the diagnostic logic for telling them apart and concrete treatment sequences. Use `fowler-code-smells` for a broad smell survey; use this skill when you have already identified that a change-pain problem exists and need to classify and treat it.
- Difference from `fowler-two-hats`: Two Hats is about keeping refactoring and feature work separate in time during a single session. This skill is about diagnosing the structural problem that makes change painful in the first place — it addresses the question before you start the refactoring session.
- Difference from `fowler-opportunistic-refactoring`: Opportunistic refactoring is about deciding *when* to refactor (preparatory, comprehension, litter-pickup). This skill is about diagnosing *what structural problem* you are treating.

______________________________________________________________________

## E — Execution Step

1. **Gather the change history for the module under examination.**

   - List the last 5–10 changes to the module (from git log, PR history, or team memory). For each change, write one sentence: "This change was made because [reason]."
   - Completion criteria: You have a list of change events with stated reasons. Do not proceed until the reasons are explicit — vague entries like "bug fix" must be resolved to "bug fix in the database connection logic" or "bug fix in the discount calculation."

2. **Apply the Divergent Change test: count distinct reasons per module.**

   - Group the change events by reason. If a single module has changes in two or more distinct reason groups, it has Divergent Change. "Distinct" means the reasons are in different problem domains — not just different features in the same domain.
   - Completion criteria: You can answer "this module changes for [N] distinct reasons" with the reasons named explicitly.
   - Decision: If N > 1, you have Divergent Change → go to step 4a. If N = 1, proceed to step 3.

3. **Apply the Shotgun Surgery test: count modules touched per logical change.**

   - For the most recent 3–5 changes to the concept under examination, count how many distinct files/classes were touched per change. If most changes touch 3+ modules, you have Shotgun Surgery.
   - Completion criteria: You can answer "a typical change to [concept] touches [N] modules" with those modules named.
   - Decision: If N > 2–3 and they share a coherent concept, you have Shotgun Surgery → go to step 4b.

4a. **Treat Divergent Change: split the module.**

- Identify the two (or more) axes of change. Give each axis a name.
- Determine the relationship between the axes: if they form a sequential pipeline (data in → processing → output), use Split Phase to create a clean data structure at the boundary. If they are more interleaved but separable at the function level, use Move Function to redistribute. If individual functions mix both concerns, use Extract Function first, then Move Function. If the module is a class, use Extract Class to formalize the split.
- Completion criteria: Each resulting module has exactly one axis of change, and you can state it in one sentence.

4b. **Treat Shotgun Surgery: consolidate the concept.**

- Identify the single concept that is scattered. Give it a name.
- Use Move Function and Move Field to pull scattered pieces toward a single module. If a group of functions all operate on similar data, apply Combine Functions into Class. If the functions are transforming a data structure, apply Combine Functions into Transform.
- If the scattered logic is too interleaved to move incrementally, apply Inline Function or Inline Class to pull everything into one temporarily large module, then re-extract into a coherent structure using Extract Class or Extract Function.
- Completion criteria: A developer can answer "where does [concept] live?" with a single module name.

5. **Verify the treatment.**

- After splitting (4a): Introduce a change to one axis and confirm it touches only one module.
- After consolidating (4b): Introduce a change to the concept and confirm it touches only one module.
- Completion criteria: The change surface matches the conceptual boundary.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **When a class is intentionally an orchestrator or facade:** Some classes are designed to coordinate multiple concerns — an HTTP handler that validates input, calls a service, and formats a response is not Divergent Change, it is orchestration. The test is whether the concerns are *independently changing* for unrelated reasons. If they always change together (the validation and the service call change together when the API changes), they are not Divergent Change.
- **When scattered changes are in a stable, infrequently-changed area:** Shotgun Surgery is painful because changes are missed. If an area is stable and changes are rare and thoroughly tested, the scattered layout may not warrant the cost of consolidation. Apply the smell treatment when the pain is real and recurring, not preemptively in areas that never change.
- **When the module was intentionally designed using a Strategy, Visitor, or Self-Delegation pattern:** These patterns deliberately separate small pieces of varying behavior from the stable algorithm structure. They look like Shotgun Surgery — a behavior change touches the concrete strategy class plus the context class — but they are intentional. The smell applies when scattering is accidental, not when it is the intended design.

### Failure Patterns

- **Splitting too eagerly creates too many tiny classes:** Treating every function that changes for two reasons as a Divergent Change produces a proliferation of single-function classes with no conceptual weight. The split should be driven by genuine domain separation, not by change frequency alone. If the two "axes" are really just two features in the same domain, they belong together.
- **Consolidating too eagerly creates God Objects:** Shotgun Surgery treatment (Move Function/Move Field to a single module) can overshoot. If every payment-related function in the codebase is moved to `PaymentService`, the result is a God Object with thousands of lines. Consolidate to a coherent concept, not to a grab-bag of anything with the same noun in its name.
- **Using Inline Class as a treatment without re-extracting:** The tactic of inlining everything into a large intermediate structure is only useful if the re-extraction into a better structure follows. Stopping at the large intermediate is not a treatment — it is trading one smell (Shotgun Surgery) for two others (Large Class, Long Method).

### Author's Blind Spots / Limitations of the Era

- **The analysis is within a single codebase:** Fowler's treatment of both smells assumes you can move functions and classes freely within the codebase. At microservice or distributed system boundaries, consolidation requires merging services and Divergent Change splitting may require service decomposition — both of which are organizational and operational decisions, not just refactoring decisions. The "reasons to change" test is still valid at service granularity, but the treatments are more expensive.
- **The "single reason to change" ideal is an approximation:** No real module has exactly one reason to change in practice. Fowler's framing is a simplifying heuristic, not a formal specification. The practical test is whether the change reasons are *sufficiently unrelated* that mixing them creates genuine cognitive overhead — not whether they are mathematically distinct.
- **No guidance on legacy code without tests:** Both treatments (moving functions, splitting classes, inlining) are safe only when a reliable test suite catches behavioral regressions. Fowler assumes a green test suite throughout. In legacy code without tests, both smells are harder to treat because the refactoring steps cannot be safely verified. Feathers' WELC characterization testing approach should precede the structural changes in that context.

### Easily Confused Proximity Methodology

- **Large Class** smell: A class that is too large may have Divergent Change as its root cause, but Large Class is the symptom (size), not the diagnosis (multiple change axes). Diagnosing Divergent Change requires the change-history analysis; diagnosing Large Class only requires counting lines. Use this skill when you know *why* the class is large, not just that it is.
- **Feature Envy** smell: A function that uses more data from another module than its own is Feature Envy — it should move to where its data is. This can look like Shotgun Surgery but is not: Shotgun Surgery is about a concept scattered across many modules; Feature Envy is about a single function in the wrong home. Both are treated with Move Function, but the diagnosis is different.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- **depends-on** `fowler-code-smells`: Divergent Change and Shotgun Surgery are two specific named smells from the code-smells vocabulary. Understanding this skill requires the broader framework: that named smells map structural friction to specific treatments via a sense→name→map→act workflow. The divergent-shotgun skill is a deep-dive into one specific inverse pair within that vocabulary — the "reasons to change" test, the 2×2 diagnostic grid, and the split vs. consolidate treatment sequences. The broader smell vocabulary is the prerequisite context for understanding why these two smells are paired as inverses and how their treatments relate to the full catalog.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** Refactoring: Improving the Design of Existing Code — Martin Fowler (2018) — Chapter 3
