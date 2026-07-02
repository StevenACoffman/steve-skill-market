---
name: fcis-shell-exploration-cadence
description: |
  Invoke this skill when a user is integrating a new library or technology they've
  never used before and asking whether to write tests first. Also invoke when a user
  asks how to do TDD when they don't know what the design should be yet, or when they're
  stuck writing tests for code whose interface hasn't stabilized. Also invoke when a
  user is building a new feature in an exploratory, iterative way and asking how to
  avoid accumulating untested code permanently.

  Trigger signals: "should I write tests when I'm still figuring out the design?",
  "I'm exploring a new API / library — how do I test while learning it?", "I keep
  rewriting my tests as the design changes", "my shell / entry point / main is growing
  and getting messy — when should I refactor?", "how do I do TDD when I don't know
  what I'm building yet?", "I have a lot of untested code in my main file — what do
  I do?".
tags: [tdd, exploration, refactor-cadence, shell, design-discovery]
---

# Shell-as-Exploration-Zone / TDD Extraction Cadence

## R — Original Text (Reading)

> "I tend to just cowboy code into here — either to explore a new library that I don't
> know, or to explore just how the application should work. I often don't know what I
> want, so I write some pretty nasty code in here, figure it out, and once I know what
> it's going to do (or I at least have a decent design), then I will move the source
> code into unit-tested files, often by doing TDD."
>
> "This is the cadence of the entire project so far. I tend to bloat up this outer file
> up to something like 250 lines in some cases, and then I extract behavior out, moving
> it into unit-tested classes, figuring out how to make it more functional. So this is
> not by any means a traditional TDD flow — although in most cases, when I pull those
> classes out, I do do TDD there."
>
> — Gary Bernhardt, *Functional Core, Imperative Shell* (DAS-0072)

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Standard TDD doctrine says: write the test first, then the code. This works well when you know what you're building. It breaks down when you don't.

Bernhardt's solution is to split the development lifecycle into two phases with different rules:

**Phase 1 — Exploration (in the shell).** Write rough, untested code directly in the imperative shell. No tests. Discover the library API, sketch out the design, figure out what the application actually needs. This is "cowboy code" — intentionally messy, fast to write, easy to delete. The shell is the designated zone for this work. It *expects* to become messy. Bloating to ~250 lines is normal.

**Phase 2 — Crystallization (TDD extraction).** Once a stable design emerges from exploration, extract it via TDD:

1. With the shell code as a reference, write a new spec/test file for the new functional class.
2. TDD the new class from scratch, letting the existing shell code inform the design without copy-pasting it.
3. Delete the old shell code and replace it with the new class.

The shell shrinks. The functional core grows. The new class arrives with full test coverage. The TDD process applies design pressure even on known behavior — the extracted class often ends up with a slightly better interface than the shell code it replaces.

**Why this works:** Committing to tests before the design is known is a form of waste — the tests will be rewritten as the design changes. The exploration phase defers that cost until the design has stabilized. Once stable, TDD applies design pressure at the right moment: when the design can actually improve from that pressure.

**The trigger for extraction:** Size and fear. The shell bloats; you notice complexity growing and feel uneasy about it; you recognize a stable design in the bloat. That's the extraction signal. Bernhardt's threshold is roughly 250 lines, but the real trigger is recognizing a coherent unit of behavior that can stand alone.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: TweetRenderer — TDD Extraction from Shell (Git History)

- **Question:** The Twitter client already had tweet-drawing behavior in the shell. Bernhardt wanted to improve it but the existing code was untested and entangled with the event loop.
- **Use of methodology:** Commit "add the TweetRenderer class" — creates a new spec file and a new production file, changes nothing else. The shell still uses the old code. He TDD'd the new class using the existing code as a reference. Then commit "replace untested TweetDrawing with TweetRenderer" — adds a small hook in the screen class, removes a large block from the shell.
- **Conclusion:** The extraction cost was self-contained. No existing code broke. The new class had slightly different interfaces than the old — TDD pressure improved the design. The deleted shell code was all red in the diff.
- **Result:** TweetRenderer ends up unit-tested, pure, and composable. The shell got shorter. The system's tested surface area grew with zero disruption to running behavior.

### Case 2: Discovering the Twitter API — Exploration Without Tests

- **Question:** Bernhardt didn't know the Twitter streaming API or the available Ruby libraries before writing the client.
- **Use of methodology:** Wrote the network/streaming integration directly in the shell without tests. Figured out how the library worked, what events it emitted, what data the application needed from it. The shell grew messy as the exploration proceeded.
- **Conclusion:** Once the shape of the data (what a Timeline looks like, what a Tweet contains) was clear from exploration, he could design functional core classes around known data structures rather than guessing. The extraction then followed naturally.
- **Result:** The `Timeline` and `Tweet` value objects were designed around data that the exploration had revealed. TDD-extracting them was straightforward because the design was already known.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A developer is integrating a new payment processor, message queue, or third-party API they've never used and asking if they should TDD from the start.
2. A developer has a large, untested `main.go`, `app.js`, or `application.rb` file and asks when and how to refactor it.
3. A developer is stuck in a TDD loop where tests keep changing as the interface evolves, and asks how to break the cycle.
4. A developer asks "I'm building something new and I don't know what the design should be — how do I handle tests?"
5. A developer has shell/entry-point code that has grown to hundreds of lines over months and feels the need to organize it.

### Language Signals

- "Should I write tests while I'm still figuring out the design?"
- "I'm learning this library as I go — when should I add tests?"
- "My main file / entry point is getting huge"
- "I keep having to rewrite tests as the interface changes"
- "When should I refactor messy code out of the main layer?"
- "I have a prototype that worked — now how do I make it properly tested?"

### Distinguishing from Adjacent Skills

- Difference from `seam-to-zone-refactoring-trajectory`: Two-Zone Architecture is the structural end state (what the code looks like when done). Shell-Exploration-Cadence is the workflow for getting there (how you develop toward that state). Use the architecture skill for design questions; use this skill for workflow/process questions about when to write tests.
- Difference from `test-double-diagnostic-sensing-to-core`: Mocks-as-Architecture-Signal diagnoses existing code. Shell-Exploration-Cadence guides new development. Use the mocks skill when asking "what do these mocks tell me?" Use this skill when asking "how should I develop this new thing?"

______________________________________________________________________

## E — Execution Step

1. **Designate an exploration zone and write freely in it.**

   - Write the new feature/integration directly in the shell, main file, or outermost layer. No tests.
   - Goal: understand what the code needs to do, what data it works with, what the library API looks like. Speed and discovery are the priority.
   - Stopping condition: you can describe what the extracted functional class should do in one sentence, and you know what data it takes in and returns.

2. **Recognize the extraction signal.**

   - The shell has grown noticeably (rough threshold: 50–250 lines of new code for the feature). You feel mild unease about the complexity. You can identify a coherent unit of behavior in the bloat — a thing that computes something given some data.
   - If you can say "this part takes X and returns Y, with no I/O needed," that's the extraction target.
   - Do not extract prematurely: if you still don't understand the design, keep exploring.

3. **TDD-extract the functional class.**

   - Create a new file for the class. Write tests first, using the existing shell code as a reference for behavior.
   - Let TDD apply design pressure — don't just copy the shell code. The test-drive will often produce a cleaner interface.
   - Run the new class in parallel with the old shell code until the tests pass.

4. **Delete the old shell code.**

   - Replace the shell's old implementation with a call to the new functional class.
   - Delete the original code. All red in the diff is the goal.
   - Verify the system still works. The shell shrinks; the tested core grows.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Adding features to well-designed existing code:** If the design is already known and the codebase has established patterns, use standard TDD. The exploration phase is for genuine uncertainty, not as an excuse to skip tests.
- **Bug fixes in existing tested code:** Don't use the exploration phase as justification for adding untested code to a tested module. The shell exploration is for new, uncertain territory.
- **Long-lived exploration without extraction:** The shell is a *temporary* home. If exploratory code stays in the shell permanently, the architecture degrades. The cadence requires the extraction step. "I'm still exploring" cannot be an indefinite justification.

### Failure Patterns Warned About in the Book

- **Treating the shell as permanent code home (ce04):** Bernhardt explicitly warns: once the design crystallizes, the code must be extracted. Leaving it in the shell produces exactly the kind of untested, entangled codebase the architecture is designed to avoid.
- **Testing the shell's exploratory code with mocks (ce05):** Adding mocks to test exploratory shell code suppresses the pain signal that should trigger extraction. The tests become technical debt: they test the wrong thing (the messy intermediate design) and prevent the extraction by creating a false sense of coverage.
- **Premature test commitment:** Committing to tests before the design is known means tests will be rewritten as the design changes. The cost of exploration is paid twice — once in writing tests, once in rewriting them. Defer tests to when the design has stabilized.

### Author's Blind Spots / Limitations of the Era

- **Solo developer assumption:** The "cowboy code in the shell" stance works when one developer controls the shell. In a team, multiple developers adding untested shell code simultaneously creates a mess that may never get extracted. The cadence requires someone to own and execute the extraction cycle.
- **Extraction discipline required:** The pattern's correctness depends entirely on the developer actually performing the extraction. There is no structural enforcement. A developer who always explores and never extracts produces an ever-bloating shell. The discipline to extract is the assumption, not the product.
- **The "fear" threshold is subjective:** Bernhardt's "I would become afraid" signal for when to test is useful but non-transferable. Teams need a more explicit extraction trigger (line count, complexity metric, review checkpoints) to apply this at scale.

### Easily Confused Proximity Methodology

- **Spike-and-stabilize (XP):** Similar concept: write a spike (throwaway prototype) to learn, then TDD the real implementation. The difference: in FCIS, the spike code lives in the shell (a permanent architectural zone), not in a throwaway branch. Extraction is incremental, not a full rewrite.
- **Prototype-then-rewrite:** Common ad hoc practice: write a prototype, throw it away, rewrite properly. FCIS's cadence is more surgical: extract specific behaviors incrementally while the rest of the application keeps running. The prototype code is deleted piece by piece rather than all at once.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: seam-to-zone-refactoring-trajectory — the cadence is the workflow for building toward the two-zone structure
- composes-with: test-double-diagnostic-sensing-to-core — mock accumulation in the shell signals extraction is overdue

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: See test-prompts.json
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Functional Core, Imperative Shell" Gary Bernhardt — Testing the imperative shell / The Refactor Cadence
