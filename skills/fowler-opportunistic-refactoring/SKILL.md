---
name: fowler-opportunistic-refactoring
description: |
  Use this skill when deciding *when* and *why* to refactor during normal development work.
  Fowler identifies four distinct modes: (1) Preparatory — refactor before adding a feature to
  make the addition easy; (2) Comprehension — refactor while reading unfamiliar code to move
  understanding from head into code; (3) Litter-pickup — fix small problems found in passing,
  note large ones for later; (4) Long-term — gradually migrate large structural problems over
  weeks using Branch By Abstraction, with every small step leaving the code working.

  Trigger signals: "I need to add X but the code isn't structured for it", "I'm reading this
  code and it's hard to follow", "I noticed a problem while working on something else",
  "we have a large architectural problem that needs months to fix."

  Do NOT invoke for: deciding which specific refactoring technique to apply (use the catalog);
  justifying refactoring to stakeholders (use fowler-design-stamina); separating feature work
  from structural changes (use fowler-two-hats); or diagnosing what is wrong with code
  (use fowler-code-smells). This skill answers "when should I refactor?" not "how?" or "why
  is this code bad?"

  Key constraint: planned refactoring sprints are a symptom of insufficient opportunistic
  refactoring — they are not the primary vehicle. Most refactoring should be unremarkable,
  woven into normal work.
source_book: 'Refactoring: Improving the Design of Existing Code — Martin Fowler (2018)'
source_chapter: Chapter 2
tags: [refactoring, workflow, preparatory, opportunistic]
related_skills:
  - slug: fowler-two-hats
    relation: composes-with
  - slug: fowler-code-smells
    relation: composes-with
  - slug: fowler-branch-by-abstraction
    relation: composes-with
---

# Four Modes of Opportunistic Refactoring — When and Why to Refactor

## R — Original Text (Reading)

> The best time to refactor is just before I need to add a new feature to the code base. As I
> do this, I look at the existing code and, often, see that if it were structured a little
> differently, my work would be much easier. [...] The examples above—preparatory,
> comprehension, litter-pickup refactoring—are all opportunistic. I don't set aside time at
> the beginning to spend on refactoring—instead, I do refactoring as part of adding a feature
> or fixing a bug. It's part of my natural flow of programming. [...] Most refactoring effort
> should be the unremarkable, opportunistic kind.
>
> "for each desired change, make the change easy (warning: this may be hard), then make the
> easy change" — Kent Beck
>
> — Martin Fowler, Chapter 2

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Opportunistic refactoring is not a phase or a block of time — it is a posture. You carry a
refactoring lens into every piece of programming work you do, and you switch into refactoring
mode when the signal for one of the four modes appears.

The four modes are triggered by four different kinds of encounters with code:

- **Preparatory**: You are about to make a change and the code's structure makes that change
  harder than it needs to be. The move is to reshape the code first, then make the change. The
  restructuring investment is repaid immediately — the feature or fix becomes simple.

- **Comprehension**: You are reading code to understand it, and understanding is arriving slowly.
  Rather than just taking mental notes, you externalize the understanding by renaming, extracting,
  and simplifying — the code itself becomes the record, not your head.

- **Litter-pickup**: You are doing something specific and notice a problem nearby. Triage by size:
  small problems get fixed immediately; large problems get noted and deferred. Neither ignoring
  nor derailing your current task.

- **Long-term**: A large structural problem can't be fixed in one session. The strategy is not a
  dedicated refactoring sprint but a directed accumulation: every time anyone passes through the
  affected code, they move it one step toward the target state. Branch By Abstraction is the
  enabling technique — introduce an abstraction layer that works with both old and new, then
  migrate callers incrementally.

The critical implication: if a team is scheduling regular refactoring sprints, they are treating
a symptom rather than adopting the posture. Planned episodes are sometimes necessary for
neglected codebases, but they should be rare, not routine.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Parameterize Function Before Adding a Feature Variant

- **Question:** Fowler needs a function that does almost what he needs, but has hardcoded literal
  values that conflict with his new requirement. What should he do?
- **Use of Methodology:** Preparatory refactoring mode. With the refactoring hat on, he applies
  Parameterize Function to the existing function before writing any new code. Then, with the
  feature hat on, he calls the function with the parameters his new feature needs.
- **Conclusion:** The preparatory refactoring prevents duplicating the function (and the future
  maintenance cost of two similar functions). The feature itself becomes trivially simple.
- **Result:** Less code, no duplication, and the feature change took fewer lines than copy-paste
  would have — at the cost of an upfront structural step.

### Case 2: Comprehension Refactoring While Reading Unfamiliar Code

- **Question:** A developer is reading code written by someone else, working to understand the
  conditional logic and poorly named functions. What should they do with the understanding they
  gain?
- **Use of Methodology:** Comprehension refactoring mode. Rather than holding the understanding
  in their head, they rename variables and functions and break apart long functions as they come
  to understand each piece. They verify by running the tests.
- **Conclusion:** As Ward Cunningham puts it: "by refactoring I move the understanding from my
  head into the code itself." The code becomes its own documentation.
- **Result:** The developer finds additional design insights that would not have been visible
  without the restructuring. The comprehension refactoring opens up a second level of
  improvements.

### Case 3: Litter-Pickup Triage While Fixing a Bug

- **Question:** While tracking down a bug, Fowler notices that three bits of copied code are
  causing the error. He also spots a nearby function that's unnecessarily convoluted but not
  related to the bug.
- **Use of Methodology:** For the copied code directly causing the bug: fix immediately (unify
  the three copies). For the convoluted-but-unrelated function: make a note and defer. The
  decision rule is size and relevance to the current task.
- **Conclusion:** Fixing the copied code also increases the chance the bug stays fixed and
  reduces the chance of similar bugs in the same crevices.
- **Result:** Bug is fixed, the immediate smell that contributed is addressed, and the developer
  does not get derailed by a larger refactoring that would have blocked the fix.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

### Scenario 1: Adding a Feature Where the Code Isn't Structured for It

"I need to add X but the current code does A and B in the same function and I'd need to thread
X through all of it." → Preparatory refactoring: first separate A and B, then add X cleanly.

### Scenario 2: Reading Code That Is Hard to Understand

"I've spent 15 minutes reading this and I think I understand it now." → Comprehension
refactoring: don't stop there — rename, extract, simplify to lock that understanding into the
code before moving on.

### Scenario 3: Noticing a Problem While Doing Something Else

"This isn't what I'm here to fix, but I can see this code is badly structured." → Litter-pickup
triage: is it a 10-minute fix or a 3-hour effort? Fix it now or note it and move on.

### Scenario 4: a Large Structural Problem the Team Has Been Avoiding

"We all know this module's dependency graph is a mess, but nobody has time to fix it." →
Long-term refactoring: designate the zone, agree that anyone passing through moves it one step
toward the target. Use Branch By Abstraction to keep the code working at every step.

### Scenario 5: Team Schedules a "Refactoring Week"

"We haven't kept up with refactoring, so management approved a cleanup sprint." → This is
a valid but symptomatic response. Execute it, but also establish opportunistic habits so the
next cleanup sprint is never needed.

### Language Signals

- "I need to add [feature] but the code makes it hard"
- "I need to understand this code before I can change it"
- "I noticed this problem while working on something else"
- "We have a module that's been gradually getting worse for months"
- "We never have time to refactor, so we scheduled a refactoring sprint"

### Distinguishing from Adjacent Skills

- Difference from `fowler-two-hats`: Two Hats is about keeping feature work and refactoring
  mentally and operationally separate in any given moment. Opportunistic refactoring is about
  *when* to enter refactoring mode in the first place. Two Hats governs *how you work while
  refactoring*; opportunistic refactoring governs *when to start*.

- Difference from `fowler-design-stamina`: Design Stamina is the economic argument for *why*
  refactoring is worth doing at all — the cumulative speed argument for stakeholders and for
  self-justification. Opportunistic refactoring is the *workflow taxonomy* — the four modes
  tell you specifically when to act. Design Stamina answers "why refactor?"; opportunistic
  refactoring answers "when exactly should I refactor right now?"

______________________________________________________________________

## E — Execution Step

1. **Identify which of the four modes applies**

   Before any refactoring, name the mode:

   - Am I about to add a feature or fix a bug and the code structure is making it harder?
     → Preparatory
   - Am I reading code to understand it and the understanding is coming slowly?
     → Comprehension
   - Am I working on something and noticed a nearby problem I wasn't here to fix?
     → Litter-pickup
   - Is there a large structural problem the team has been avoiding that requires weeks?
     → Long-term

   If none of these apply, do not refactor now.

2. **Apply the mode-specific approach**

   **Preparatory**: Put on the refactoring hat. Make the structural change that will make the
   feature easy — reshape the code so the upcoming change is trivial. Commit the refactoring
   separately if possible. Then switch to the feature hat and make the change. Do not mix the
   two in a single commit or mental state.

   **Comprehension**: As you read and gain understanding, act on it immediately. Rename the
   variable whose name you just decoded. Extract the block whose purpose you just figured out.
   Run the tests after each change. Do not defer the renaming to "later."

   **Litter-pickup**: Apply the size triage. If the fix is small (minutes), do it now. If it is
   large (hours or more), make a note — a comment, a ticket, a TODO — and return to your current
   task. Do not abandon your current task to pursue a large cleanup.

   **Long-term**: Agree with the team on the target state. Use Branch By Abstraction: introduce
   an abstraction that can work with both old and new implementation, then migrate callers
   incrementally. Every merge leaves the system in a working state. There is no feature freeze
   or cleanup sprint — the migration happens alongside normal work.

3. **Validate**

   After any preparatory refactoring: verify the tests still pass before switching to the feature
   hat. This confirms that the restructuring preserved observable behavior.

   After comprehension refactoring: run the tests to verify your understanding was correct (if the
   tests pass, your restructuring was behavior-preserving).

   After litter-pickup: run the tests, then return immediately to the task you were doing.

   For long-term: at each step, run CI. The invariant is that the main branch is never broken.

4. **Calibrate planned refactoring**

   If your team is scheduling refactoring sprints regularly: treat it as a signal that opportunistic
   refactoring is not happening enough. Use the planned episode to establish the posture, then
   prevent the next one by building the four modes into daily workflow.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **You don't have tests and can't run them quickly.** Opportunistic refactoring depends on fast
  feedback from a test suite. Without it, every small step is unverifiable. Get self-testing code
  in place first (or use WELC techniques to add coverage); do not attempt opportunistic
  refactoring blind.

- **You are in the middle of a feature and the code you want to refactor is not directly in your
  path.** Litter-pickup applies to things you encounter, not things you go searching for. Do not
  let refactoring become a displacement activity that prevents shipping.

- **The refactoring will take hours and you have a deadline today.** Note it. Do not start a
  large refactoring you cannot finish — a half-refactored codebase is worse than an unrefactored
  one. Use long-term mode with small steps instead.

- **You are refactoring shared interfaces consumed by other teams.** The book's techniques
  (retain old signature as pass-through, gradual migration) apply within a single codebase. Cross-
  team API contracts require a published interface versioning strategy that goes beyond what
  this skill covers.

- **You have been asked specifically to deliver a feature, not to prepare the codebase.** In
  extreme schedule pressure, Fowler acknowledges refactoring may need to wait — but notes this
  is a short-term tradeoff with long-term cost. If the team is always in this state, it is a
  Design Stamina problem, not a scheduling problem.

### Failure Patterns Warning by the Author in the Book

- **Treating opportunistic refactoring as time theft.** Fowler warns that refactoring is not
  separate from programming — "any more than you set aside time to write if statements." The
  failure mode is treating it as an extra activity that must be budgeted separately, which leads
  to it being cut first under pressure.

- **Conflating excellent code with no need to refactor.** Fowler explicitly warns: "you have to
  refactor when you run into ugly code, but excellent code needs plenty of refactoring too."
  Tradeoffs that were correct for yesterday's feature set may not be right for today's. Clean
  code is not static code.

- **Separating refactoring commits from feature commits as a rigid rule.** Fowler is skeptical
  of this advice: "too often, the refactorings are closely interwoven with adding new features,
  and it's not worth the time to separate them out. This can also remove the context for the
  refactoring, making the refactoring commits hard to justify."

### Author's Blind Spots / Limitations of the Era

- **The "opportunistic refactoring is sufficient" hypothesis is unproven for large neglected
  codebases.** Fowler argues against planned refactoring sprints in favor of opportunistic
  refactoring. But many teams working in large, poorly-maintained codebases find that
  opportunistic refactoring doesn't accumulate fast enough to reverse decay — planned investment
  is sometimes necessary. Fowler acknowledges this but characterizes it as rare; in practice it
  may be more common. (BOOK_OVERVIEW.md §3, Unproven Hypotheses)

- **Social and organizational resistance is barely addressed.** The four modes assume you have
  permission and space to refactor as part of normal work. Fowler's "Don't tell your manager"
  aside is a tell — the organizational problem is real but not seriously engaged. In environments
  where refactoring is actively discouraged or must be justified in tickets, the opportunistic
  posture requires organizational work that the book does not address. (BOOK_OVERVIEW.md §3,
  Author's Blind Spots)

- **Partial test coverage is not addressed.** The modes assume you have a test suite fast enough
  to run after each change. The common case — partial, low-quality tests that pass but don't
  catch regressions — is not addressed. Comprehension refactoring without reliable tests is
  higher-risk than Fowler implies.

### Easily Confused Proximity Methodology

- **Two Hats** (fowler-two-hats): Governs how to work *during* refactoring — don't add features
  while restructuring, don't restructure while adding. Opportunistic refactoring governs *when*
  to enter refactoring mode. Both apply simultaneously: you use the four modes to decide when
  to refactor, and Two Hats to govern how you do it.

- **Code Smells** (fowler-code-smells): Smells are the diagnostic vocabulary for *what* is wrong
  with code. Opportunistic refactoring is the *when* framework. Litter-pickup mode is often
  triggered by a smell, but the smell identification and the decision to act are separate.

- **Design Stamina Hypothesis** (fowler-design-stamina): The economic argument for *why* to
  refactor at all. Opportunistic refactoring is the operational answer to *when* to refactor.
  Design Stamina is the justification; opportunistic refactoring is the workflow.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- **composes-with** `fowler-two-hats`: Opportunistic refactoring governs *when* to enter refactoring mode; Two Hats governs *how* to work while in that mode. Both apply simultaneously in any refactoring session — opportunistic refactoring decides the trigger, Two Hats enforces the separation from feature work during execution.

- **composes-with** `fowler-code-smells`: The code-smells vocabulary provides the diagnostic language for what triggers litter-pickup and comprehension refactoring. When you sense that code is wrong during comprehension or litter-pickup mode, the smells catalog lets you name it precisely — turning vague friction into an actionable diagnosis before you begin the refactoring.

- **composes-with** `fowler-branch-by-abstraction`: The long-term mode of opportunistic refactoring explicitly names Branch By Abstraction as its enabling technique. Large structural problems that cannot be addressed in one session are migrated incrementally by directing everyone passing through the zone to take one small step toward the target — Branch By Abstraction provides the seam that makes that incremental migration possible without breaking the system.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Time**: 2026-05-05
