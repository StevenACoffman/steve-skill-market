---
name: fowler-two-hats
description: |
  Invoke this skill when a developer is mixing refactoring work with feature or bug-fix work in the same session, or when they cannot tell whether a failing test is caused by a structural change or a new behavior change. The skill applies whenever forward progress is stalling because both goals are being pursued simultaneously without separation.

  Key trigger signal: "I've been refactoring and fixing at the same time and now I don't know what's broken." Or: spending more than a few minutes restructuring while trying to add or fix something.

  Do NOT invoke this skill to decide whether to refactor at all (use fowler-opportunistic-refactoring for that), or when the question is about organizing a long-term migration (use fowler-branch-by-abstraction for that). This skill is specifically about the moment-to-moment discipline of keeping the two modes separate.
source_book: 'Refactoring: Improving the Design of Existing Code — Martin Fowler (2018)'
source_chapter: Chapter 2
tags: [refactoring, workflow, discipline, tdd]
related_skills:
  - slug: fowler-opportunistic-refactoring
    relation: composes-with
  - slug: fowler-performance-sequencing
    relation: composes-with
---

# Two Hats Discipline — Separating Functionality from Refactoring

## R — Original Text (Reading)

> Kent Beck came up with a metaphor of the two hats. When I use refactoring to develop software, I divide my time between two distinct activities: adding functionality and refactoring. When I add functionality, I shouldn't be changing existing code; I'm just adding new capabilities. I measure my progress by adding tests and getting the tests to work. When I refactor, I make a point of not adding functionality; I only restructure the code. I don't add any tests (unless I find a case I missed earlier); I only change tests when I have to accommodate a change in an interface.
>
> As I develop software, I find myself swapping hats frequently. I start by trying to add a new capability, then I realize this would be much easier if the code were structured differently. So I swap hats and refactor for a while. Once the code is better structured, I swap hats back and add the new capability. Once I get the new capability working, I realize I coded it in a way that's awkward to understand, so I swap hats again and refactor. All this might take only ten minutes, but during this time I'm always aware of which hat I'm wearing and the subtle difference that makes to how I program.
>
> — Martin Fowler, Chapter 2

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The Two Hats discipline is the practice of keeping two programming activities — adding functionality and refactoring — strictly separated in time and mentally tracked at all moments.

Each hat has its own definition of success. With the functionality hat on, success means new tests are passing. Nothing about the structure should change. With the refactoring hat on, success means no new tests are needed — all existing tests still pass and the code does the same things. You are allowed to touch tests only when an interface change forces it.

The hats are swapped frequently — sometimes several times in ten minutes — but they are never worn simultaneously. The moment you notice the code would be easier to work in if it were structured differently, you stop adding functionality, switch hats deliberately, improve the structure, then switch back.

The non-obvious consequence of mixing both hats is that you lose the ability to locate errors. If you are both restructuring and adding behavior at the same time, a failing test could be caused by either action. You cannot bisect the problem. Progress on neither goal is measurable — you cannot say "the refactoring is done" or "the feature is done" independently.

Awareness is the operative word. The discipline is not about slowing down; Fowler performs these hat-swaps in minutes. It is about knowing at every moment which mode you are in, so that the success criterion is clear and errors are isolatable.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: the Chapter 1 Worked Example — Statement Printer Refactoring

- **Question:** Fowler needs to add two new features to a theater billing program: an HTML output format and support for new play types. The existing code is one large function with no separation of concerns.
- **Use of Methodology:** Before writing any new code, Fowler puts on the refactoring hat. He restructures the function into smaller pieces — decomposing the loop body, extracting the volume credits calculation, separating the amount calculation per play type — all while keeping the tests green at each step. Only after the structure supports the new features does he put on the functionality hat and implement the HTML formatter and the new play-type logic.
- **Conclusion:** The hat-swap discipline made the new-feature code trivial. The HTML formatter was essentially a copy of the existing text formatter with the logic already separated. The new play types slotted into an extracted `amountFor` function without touching unrelated code.
- **Result:** Every refactoring step was independently verifiable. No step introduced a behavioral change. The new functionality was added in clearly demarcated commits from the structural improvements.

### Case 2: Swapping Hats Mid-Feature When Structure Gets in the Way

- **Question:** During the Chapter 1 example, while adding the volume credits calculation, Fowler notices the code for it is tangled inside the main loop — the structure makes the new calculation harder than it should be.
- **Use of Methodology:** Rather than forcing the new calculation into the tangled structure (which would mix functionality and restructuring), Fowler switches to the refactoring hat, extracts the volume credits into its own function, verifies tests pass, then switches back to the functionality hat.
- **Conclusion:** Hat-swaps do not have to be planned in advance. The discipline is reactive: any time the structure is impeding the functionality work, swap hats before continuing.
- **Result:** The extraction was clean because no new behavior was in flight at the moment of the swap. Errors during the extraction could only be caused by the extraction itself.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

**Scenario 1 — Bug fix drifts into restructuring**: A developer starts fixing a null-pointer bug, then notices the method is long and confusing, then starts extracting helpers, then notices the extracted helper should live in a different class, then moves it — and 90 minutes later the original bug is not fixed and the tests are failing for unknown reasons.

**Scenario 2 — Feature work makes the code worse and the developer doesn't notice**: A developer adds a new payment method to a switch statement while also splitting the switch into a class hierarchy. Now it's unclear whether the tests are failing because of the new payment method or because of the class hierarchy change.

**Scenario 3 — Post-merge confusion**: After a refactoring, a developer notices a new requirement could be satisfied with one more change, adds it "while in the area," then cannot tell which part of the diff introduced the new behavior vs. the structural cleanup.

**Scenario 4 — Test failures of unknown origin**: A developer is running tests during combined restructuring + feature work. Tests fail. They cannot tell whether the failure is a refactoring regression or a missing behavior implementation.

**Scenario 5 — Code review produces mixed diffs**: A PR contains both structural changes and new features in the same commit. Reviewers cannot evaluate the correctness of either change independently.

### Language Signals

- "I've been refactoring but I also added X while I was in there"
- "The tests are failing and I'm not sure if it's from my refactoring or the new feature"
- "I started fixing the bug but the code was a mess so I started cleaning it up"
- "I can't tell if this is done — I've been changing so many things"
- "My PR has both structural cleanup and new functionality"

### Distinguishing from Adjacent Skills

- Difference from `fowler-opportunistic-refactoring`: Opportunistic refactoring is about *when* to decide to refactor (preparatory, comprehension, litter-pickup, long-term). Two Hats is about *how to execute* once you are in a refactoring session — specifically, the discipline of separation from functionality work. You can use the Two Hats discipline during any of the four opportunistic refactoring modes.
- Difference from `welc-legacy-code-change-algorithm`: The WELC algorithm addresses how to add a feature to legacy code without tests — it focuses on getting tests around code before changing it. Two Hats assumes a test suite already exists and addresses how to keep refactoring and feature work separate during normal development, not specifically in legacy contexts.

______________________________________________________________________

## E — Execution Step

1. **Name which hat you are currently wearing.**

   - Before writing a single line of code, state explicitly (in a comment, commit message, or to yourself): "I am in refactoring mode" or "I am in functionality mode."
   - Completion criteria: You can answer the question "if a test fails right now, what is the only possible cause?"

2. **Enforce the mode's allowed action set.**

   - Refactoring hat allowed: rename, extract, inline, move, reorganize structure. Prohibited: adding new behavior, adding new tests (except for a discovered untested case).
   - Functionality hat allowed: add new code, add new tests, make tests pass. Prohibited: restructuring existing code, changing variable names, moving methods.
   - Completion criteria: Any change you make can be categorized unambiguously as one or the other.
   - Stop condition: If you are about to make a change that violates the current mode (e.g., you notice while adding a feature that the code should be restructured), stop. Do not make the restructuring change. Either finish the functionality first and then switch, or abandon the half-written functionality, switch hats, refactor, then restart the functionality.

3. **Swap hats deliberately, not accidentally.**

   - When you notice the code structure is impeding your feature work: stop the feature work where it is (do not leave partial code), commit or stash the state, switch to refactoring mode, complete the restructuring, run all tests to confirm behavior is preserved, then resume the feature.
   - Completion criteria: Each hat-swap is a conscious decision, not a slide. The point of the swap is visible in the commit history or at least in your mental accounting.

4. **Use test results as mode verifiers.**

   - After any refactoring step: all pre-existing tests pass, no new tests added. If tests fail, the refactoring introduced a behavioral change — revert to last green state and retry the refactoring in a smaller step.
   - After any functionality step: new tests pass; pre-existing tests still pass. If pre-existing tests fail, the functionality change broke existing behavior unintentionally.
   - Completion criteria: At any point in the session, you can state which hat caused any given test state.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **When you are doing exploratory/discovery work without a test suite**: The Two Hats discipline relies on running tests after each step to verify behavior preservation. Without a reliable test suite, the verification signal is absent. In this case, use Feathers' WELC characterization testing approach to establish tests first.
- **When the "refactoring" required is actually a large architectural change spanning multiple systems**: Renaming a field across 50 microservices, migrating a database schema, or splitting a service are not single-session hat-swaps — they are week-scale Branch By Abstraction (fowler-branch-by-abstraction) or Database Parallel Change (fowler-database-parallel-change) projects. The Two Hats discipline applies within a single session or a day's work, not across release cycles.
- **When the entire purpose of the current task is exploratory spiking**: If you are writing throwaway code to learn whether an approach works, the discipline of hat-separation is wasteful overhead. Spikes are discarded; the discipline applies to code you intend to keep.
- **When the test suite is too slow to run after each step**: The discipline requires running tests frequently (after each refactoring step). If tests take 20 minutes, the cadence is broken. Fix the test performance first; the discipline cannot be applied at the required granularity otherwise.

### Failure Patterns Warning by the Author in the Book

Fowler does not give an extended failure case for Two Hats specifically, but the implicit failure pattern throughout Chapter 1 is visible: the starting state of the theater billing code is exactly what happens when developers have been mixing functionality additions with ad-hoc structural changes without separation. The result is a `statement()` function that is hard to modify, has tangled concerns, and cannot be safely changed without understanding the whole.

The Chapter 2 Two Hats section implicitly warns: if you are not aware of which hat you are wearing, you cannot measure progress per hat, and you cannot isolate errors. The entire value of the discipline is in the awareness and separation — not in the refactoring or functionality steps themselves.

### Author's Blind Spots / Limitations of the Era

- **No guidance for pair programming or mob programming contexts**: The Two Hats metaphor is described from a single developer's perspective. When two or three developers are working on the same code simultaneously, the "hat" must be shared and communicated — but Fowler does not address how to manage the discipline in collaborative coding contexts.
- **"Don't tell your manager" is a social band-aid**: Fowler's advice for handling organizational resistance to refactoring is to not mention it. This avoids the genuine organizational problem — that refactoring time requires explicit allocation in many team structures, and covert refactoring creates trust issues when discovered. The economic argument (fowler-design-stamina) is a better long-term response.
- **IDE automation changes the hat-swap cadence**: By 2018 (and more so by 2026), many catalog refactorings (Extract Method, Rename, Move) are single IDE keystrokes in statically-typed languages. The discipline of hat-separation still applies, but the granularity of the steps is finer than the book describes — a single IDE-automated rename takes seconds, not the careful manual steps the book describes. The underlying discipline remains valid; the execution mechanics are faster.

### Easily Confused Proximity Methodology

- **Preparatory Refactoring** (fowler-opportunistic-refactoring): Preparatory refactoring IS an application of the Two Hats discipline — you switch to the refactoring hat *before* starting feature work, improve the structure, then switch to the functionality hat. The Two Hats discipline is the general principle; preparatory refactoring is one specific instance of it. They are not in conflict, but Two Hats is the broader rule.
- **Test-Driven Development (TDD) red-green-refactor cycle**: TDD's refactor phase is the refactoring hat; the red-green phase is the functionality hat. The Two Hats discipline is compatible with TDD and can be understood as the rule that makes the "refactor" phase of TDD safe — you must not add functionality during the refactor step.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- **composes-with** `fowler-opportunistic-refactoring`: Opportunistic refactoring answers *when* to enter refactoring mode (preparatory, comprehension, litter-pickup, long-term). Two Hats answers *how* to execute once you are in that mode — keep the structural work strictly separated from feature work. You apply both simultaneously: opportunistic refactoring triggers the switch; Two Hats governs the session.

- **composes-with** `fowler-performance-sequencing`: Performance sequencing establishes a macro-level order: write well-factored code first (Two Hats discipline), then add features, then profile, then tune. Two Hats operates at the micro level within each of those phases. The performance sequencing skill explicitly names Two Hats as part of its recommended sequence: "refactor first (Two Hats discipline), then feature, then profile, then tune."

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Time**: 2026-05-05
