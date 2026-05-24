---
name: welc-scratch-refactoring
description: |
  Use this skill when an engineer needs to understand a large or deeply tangled legacy code module well enough to change it safely, but reading the code has not produced a working mental model. The technique is: check out a branch (or scratch copy), refactor aggressively purely to understand — extract methods, rename variables, reorganize classes, expose dependencies — then delete the branch without checking it in. The understanding persists; the mess is discarded.

  Call this skill when an engineer expresses that they have been reading legacy code for a long time without gaining comprehension, cannot follow the control flow, does not know where to put a seam, or is about to make a change they do not yet fully understand. It is a pre-condition technique: it builds the mental model before safe change work begins.

  Do not call this skill when the code already has tests (use covered refactoring instead — structural changes under test coverage), when the engineer already understands the code well enough to identify seams and add characterization tests, or when the goal is to produce shippable improvement rather than understanding. The defining constraint is: the scratch refactoring must never be checked in.

  Key trigger signal: an engineer expressing incomprehension — "I don't understand this code," "I've been reading this for hours," "I can't even follow the control flow" — in the context of needing to make a safe change.
source_book: "Working Effectively with Legacy Code" by Michael C. Feathers (2005)
source_chapter: "Chapter 16: I Don't Understand the Code Well Enough to Change It; Chapter 17: My Application Has No Structure"
tags: [legacy-code, comprehension, refactoring, mental-model, exploration, characterization-tests, understanding]
related_skills: [welc-legacy-code-change-algorithm, welc-characterization-test, welc-interception-point-selection]
---

# Scratch Refactoring as Understanding Technique

## R — Original Text (Reading)

> One of the best techniques for learning about code is refactoring. Just get in there and start moving things around and making the code clearer. The only problem with this is that if you are refactoring without tests, you are taking a chance. You could introduce subtle bugs...
>
> The saving grace is that you don't have to keep the refactoring. Delete it when you're done. Just check in your changes to a new branch in your version control system. Do your scratch refactoring to understand the code, and then delete the branch. Don't check in.
>
> When I do scratch refactoring, I extract methods, move variables, and restructure code until I feel like I understand it. The code is a mess afterward; I've violated all of the rules. But that's okay because I'm going to delete it. In the meantime, I've started to understand the system.
> — Michael C. Feathers, Chapter 16: I Don't Understand the Code Well Enough to Change It
>
> When I can't understand a system well enough, I often do a scratch refactoring to understand the structure. Then I delete the scratch and go back to the original. But the mental model I built remains.
> — Michael C. Feathers, Chapter 17 (referenced in context of understanding large system structure before introducing tests)

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Scratch refactoring is an exploration technique, not a delivery technique. Its purpose is to build a mental model of code that is too large, tangled, or poorly named to comprehend by reading. It works because the act of refactoring — extracting a method, renaming a variable, following a dependency chain to pull out a class — forces active engagement with structure in a way that passive reading does not.

**The core license it grants:** Because you are planning to discard the result, you are freed from every quality constraint. You can give methods absurd temporary names if they help you see what a function does. You can break the Single Responsibility Principle deliberately to expose what a class really depends on. You can make private state public to trace data flow. You can extract a method purely because naming it forces you to say what this block of code actually does. None of these moves are safe to check in without tests — but none of them need to be, because you are not going to check them in.

**What you gain:** A mental model of the system's actual structure: where the responsibilities live, what the real dependencies are, what the control flow actually does, where natural seam points exist. This model persists after you delete the branch.

**The sequence:**

1. Check out the code into a version control branch or scratch directory.
2. Refactor aggressively without constraint — extract, rename, reorganize, expose — with the goal of comprehension, not quality.
3. Stop when you have a mental model sufficient to identify where a seam can be introduced or where a characterization test can be anchored.
4. Delete the branch. Do not check in.
5. Return to the original codebase and apply the mental model to do the actual safe change work — adding characterization tests, introducing seams, making covered modifications.

**Relationship to characterization tests:** Scratch refactoring and characterization tests are complementary, not competing. Scratch refactoring builds the mental model. Characterization tests then verify and lock it down. If you cannot figure out where to write a characterization test, scratch refactoring tells you where to look. Once you have characterization tests in place, scratch refactoring is no longer the right tool — use covered refactoring instead.

**Time-boxing is essential.** Scratch refactoring can become an open-ended exploration. Set a time limit — typically 30–60 minutes — before beginning. The question to ask at the end is not "is the code clean?" but "do I now understand it well enough to know where to place a seam?"

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Large Class with No Structure (Chapter 16 Context)

- **Problem:** An engineer inherits a several-hundred-line class. Reading it produces no clear mental picture of what it does or what depends on what. The class mixes concerns freely, private fields are accessed everywhere, and method names are opaque abbreviations.
- **Application:** The engineer creates a scratch branch, extracts methods from each logical block purely to name them, renames fields using their actual purpose, and pulls one responsibility into a separate class to see what breaks. No tests exist; the code may not even compile at the end.
- **Conclusion:** The extracting and naming forced the engineer to make explicit what was previously implicit. The "extracted" methods, though not checked in, revealed that the class had four distinct responsibilities and that one internal field was the only bridge between two of them — exactly where a seam could be introduced.
- **Result:** Branch deleted. Engineer returns to original with a clear seam location, writes characterization tests around that seam, then performs the actual covered refactoring.

### Case 2: Incomprehensible Control Flow in a Legacy Application (Chapter 17 Context)

- **Problem:** An engineer needs to add a feature to a legacy application with no structure documentation. The entry points are unclear, and responsibilities are spread across dozens of files with no apparent pattern.
- **Application:** Scratch refactoring applied at the application level — reorganize files and classes into notional packages, rename entry points to reflect what they actually do, trace the main data path by following method calls and extracting each segment.
- **Conclusion:** The reorganization, though not shippable, revealed that the application had one central "god class" receiving all requests and that all other classes were effectively utilities called from it. The control flow, once traced by extraction, was simpler than it appeared.
- **Result:** Branch deleted. With the mental model in place, the engineer could identify where to introduce the feature without disrupting the central dispatcher, and wrote characterization tests to verify the current behavior before touching the dispatcher.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1: Hours of reading, still no model**
An engineer has been trying to understand a payment processing module for three hours. They need to add retry logic but cannot determine where current retry decisions happen or what state is shared between the retry path and the happy path.
_Language signals:_ "I've been reading this for hours and still don't understand it" / "I can't figure out what this class is actually doing" / "Every method calls three other methods and I keep losing track"
_Apply scratch refactoring:_ Create a branch. Extract each logical block in the retry path into a named method. Rename variables to reflect what they actually hold. Follow the shared state to its source by making it a parameter and seeing who breaks. Stop when you can articulate in one sentence what the retry decision depends on. Delete the branch. Write characterization tests around that decision point.

**Scenario 2: Cannot locate the seam**
An engineer knows they need to introduce a seam to test a piece of behavior but cannot determine where dependencies are introduced — the class takes no constructor parameters and everything is instantiated inline.
_Language signals:_ "I don't know where to put a seam" / "I can't even follow the control flow" / "I don't understand this code well enough to change it safely"
_Apply scratch refactoring:_ Extract every inline instantiation into a separate method. This immediately reveals all hidden dependencies. The methods are temporary and bad practice, but they make every dependency visible. Stop when you can list all dependencies. Delete the branch. Return to the original and introduce seams where the scratch exposed them.

**Scenario 3: About to make a change without understanding**
An engineer is about to modify a legacy class to add a new behavior. They feel uncertain but are under time pressure and think they understand "enough." Their proposed change touches a method that is 150 lines long with no unit tests.
_Language signals:_ "I think I understand it well enough" (but expressed with uncertainty) / "I'll just try it and see" / "I don't fully get why this works but..."
_Apply scratch refactoring:_ Before touching the original, spend 30 minutes on a scratch branch extracting and naming parts of the 150-line method. The goal is to confirm whether the engineer's partial understanding is correct or whether the method contains hidden behavior. If scratch refactoring reveals the understanding was correct, proceed with confidence. If it reveals a surprise — a side effect, a hidden dependency — the scratch has prevented a production bug. Delete the branch regardless.

______________________________________________________________________

## E — Execution Steps

1. **Confirm the precondition:** The code has no tests, or the tests do not cover the section under investigation, and reading has not produced a sufficient mental model. If the code has tests, stop — use covered refactoring instead.

2. **Create the scratch space:** Check out a new branch named clearly as a scratch (e.g., `scratch/understand-payment-retry`), or copy the relevant files to a scratch directory. The name signals intent: this will be deleted.

3. **Set a time box:** Decide in advance how long you will spend — 30 or 60 minutes is typical. The exit condition is not "the code is clean" but "I understand it well enough to place a seam or write a characterization test."

4. **Refactor aggressively for comprehension:**

   - Extract methods from large blocks and give them names that describe what the block actually does, even if the names are ugly or temporary.
   - Rename variables and fields to reflect their actual purpose, not their original abbreviation.
   - Make private state temporarily public or accessible to trace data flow.
   - Extract classes or groupings to expose hidden dependency clusters.
   - Follow call chains by extracting each step, naming each extracted piece.
   - Break SRP deliberately if it reveals what a class really does.

5. **Capture the mental model:** Before deleting the branch, write down (in a comment, a note, or a design document) the key insights: where responsibilities actually live, what the real dependencies are, where natural seam points exist, what the control flow actually does. This documentation is what you keep.

6. **Delete the branch.** Do not check it in. Do not "just keep it for reference." If you are tempted to keep it, ask: would this code be safe to ship without tests? If no, it must be deleted.

7. **Apply the model to the original:** Return to the original codebase with the mental model and the written notes. Use characterization tests to verify the model, introduce seams at the locations the scratch revealed, then proceed with the actual change under test coverage.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The code already has meaningful test coverage for the section being changed. Use covered refactoring — structural changes under existing tests carry no scratch risk and produce a shippable result.
- You already understand the code well enough to identify seams and know what the characterization tests should assert. The cost of scratch refactoring is time; do not spend it on comprehension you already have.
- The goal is to produce shippable improvement rather than understanding. Scratch refactoring deliberately produces unshippable, untested code; if your goal is a releasable refactoring, use the characterization test workflow first.
- The module is simple enough that a characterization test would reveal its behavior faster than a scratch refactoring would. For short, single-purpose functions, characterization tests are cheaper.

**Do not check in the scratch refactoring.** This is the central risk. Engineers who scratch-refactor and then feel attached to the "improved" version may be tempted to merge it. This must not happen: the scratch changes were made without tests, may contain subtle behavioral changes introduced accidentally, and were never intended to be production code. Checking in the scratch is not a shortcut — it is a regression risk with no safety net.

**Do not use scratch refactoring as a substitute for tests.** The scratch produces a mental model; it does not produce verified behavior. A scratch refactoring that appears to "clean up" the code does not mean the code now works correctly. Only characterization tests verify current behavior.

**Failure patterns:**

- Merging the scratch branch because "the code looks better now." The code may also be broken — no tests exist to say otherwise.
- Spending half a day on scratch refactoring when 20 minutes of characterization testing would have built the same model faster. Scratch refactoring is best for code that is too tangled to even know where to put the first characterization test.
- Building a false mental model: aggressive refactoring can feel like understanding. If the scratch refactoring produces a model that seems too simple or too clean, treat it with suspicion — the original complexity existed for a reason.
- Using scratch refactoring as a permanent habit to avoid writing tests. It is a bootstrap technique for comprehension, not a substitute for test coverage.

**Author blind spots:**

- Feathers assumes version control is available and branching is cheap. In environments with expensive branching or no VCS, the scratch must be a literal copy of the files.
- The technique relies on the engineer being able to recognize when their mental model is sufficient. Engineers new to a codebase may not know what "sufficient understanding" looks like — they may need a pairing session or architecture review as a complement.
- Feathers does not address time-boxing explicitly. Without a time limit, scratch refactoring can expand into multi-day exploration. A time-box is a necessary discipline not made explicit in the original text.

**Easily confused with:**

- **Characterization testing (welc-characterization-test):** Characterization tests verify current behavior; scratch refactoring builds comprehension of structure. The normal sequence is: scratch refactoring first (when too tangled to know where to test), characterization tests second (to lock down the model before changing). If you can already write a characterization test, skip scratch refactoring.
- **Covered refactoring:** Refactoring under existing test coverage is safe and produces shippable output. Scratch refactoring is unsafe and produces nothing shippable. They are entirely different activities with different preconditions and outcomes.
- **Exploratory coding / spikes:** Spikes explore whether an approach is feasible; scratch refactoring explores what existing code actually does. Both are deleted, but for different purposes.

______________________________________________________________________

## Related Skills

- **welc-legacy-code-change-algorithm** — prerequisite-for: scratch refactoring builds the understanding needed for steps 1–2 of the algorithm (identify change points, find test points); it is the technique to use when the algorithm's assumptions about code comprehension do not yet hold.
- **welc-characterization-test** — contrasts-with: scratch refactoring is throwaway exploration that builds structural understanding; characterization tests are the permanent keeper that verifies and locks down the resulting mental model before actual changes begin.
- **welc-interception-point-selection** — combines-with: scratch refactoring reveals the structural layout needed to identify viable interception points; the two are sequenced — scratch first to see the structure, then interception point selection to decide where to test.

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-05
