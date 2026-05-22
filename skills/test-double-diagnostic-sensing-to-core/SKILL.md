---
name: test-double-diagnostic-sensing-to-core
allowed-tools: Bash, Read, Edit
id: test-double-diagnostic-sensing-to-core
description: Use when introducing test doubles to break dependencies in legacy code, or when an existing test suite has many mocks and you need to classify each one as a permanent architectural fixture or a refactoring prompt toward the functional core.
type: merged-skill
source_skills:
  - slug: welc/welc-sensing-vs-separation
    book: Working Effectively with Legacy Code
    author: Michael C. Feathers
  - slug: fcis/fcis-mocks-as-architecture-signal
    book: Functional Core, Imperative Shell
    author: Gary Bernhardt
related_skills:
  - slug: welc/welc-sensing-vs-separation
    relation: supersedes
    note: Merged into test-double-diagnostic-sensing-to-core; adds Bernhardt's purity test to determine whether each fix is permanent or a refactoring prompt
  - slug: fcis/fcis-mocks-as-architecture-signal
    relation: supersedes
    note: Merged into test-double-diagnostic-sensing-to-core; adds Feathers' sensing/separation diagnostic for understanding which axis is blocking the test
tags: []
---

# Test Double Diagnostic — Sensing to Core

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Mock / fake usage in tests:
!`grep -rln 'gomock\|testify/mock\|mock\.\|Fake[A-Z]\|fake[A-Z]' --include='*_test.go' . 2>/dev/null | head -10`

### R — Original Sources

**Feathers** (Working Effectively with Legacy Code, Ch. 3):

> "Generally, when we want to get tests in place, there are two reasons to break dependencies: sensing and separation.
>
> 1. Sensing — We break dependencies to sense when we can't access values our code computes.
>
> 2. Separation — We break dependencies to separate when we can't even get a piece of code into a test harness to run."

**Convergence note:** Both skills read test doubles as diagnostic signals about production code architecture, not just as testing tools. Feathers: the shape of the test double reveals which axis is blocked. Bernhardt: mock count is an architectural readout of how many collaborators the production code reaches out to. Neither author treats mock pain as a tooling problem.

**Bernhardt** (Functional Core, Imperative Shell, DAS-0072):

> "There's no need to track down other classes because it's all data in, data out, and there's no need to reason about mocking or stubbing because there just isn't any. Searching the entire source for the word 'mock' yields zero results. Searching for 'stub' yields exactly one... Replacing that stub with a real Tweet would leave the entire system tested in isolation without a single test double. The functional core makes test doubles structurally unnecessary: pure values replace collaborators."

______________________________________________________________________

### I — Unified Framework

A test double reflects an architectural boundary. Both frameworks start from this shared premise, but they operate at different moments in the testing workflow.

**Feathers' first pass: classify the blocker.** When a dependency is blocking a test, two distinct problems can be blocking it, and they have different solutions.

*Separation* is the obstacle of instantiation. The class cannot be constructed or executed in a test at all — its constructor opens a real database connection, talks to hardware, requires the entire application to be running. Every separation fix answers: "How do I build a version of this object that doesn't require live infrastructure?" The technique: parameterize the constructor, extract an interface, inject a null or minimal implementation.

*Sensing* is the obstacle of observation. The class instantiates fine, but its effects are invisible — it calls `logger.Info(...)`, writes to a file, sends a network packet, or mutates state on a collaborator the test can't inspect. Every sensing fix answers: "How do I make the effects of this code visible to my test assertions?" The dominant technique: introduce a recording fake that stores every call and argument it receives.

These two axes are independent. Fix separation first (you cannot sense effects from a class that won't construct). Then, and only then, address sensing.

**Bernhardt's second pass: determine whether the fix is the right final shape.** After the test double is in place and tests pass, apply the purity test to each mock or fake introduced:

*Is the mocked collaborator returning data?* Could the code under test receive this data as an argument instead of calling the collaborator directly? If yes: the collaborator can be inverted. Move the dependency to the caller. The caller passes the data in; the unit computes with the data and returns a result. The mock disappears — there is no longer anything to mock. This code belongs in the functional core.

*Is the mocked collaborator performing I/O or mutating external state?* Then this is genuine shell behavior. The mock is the correct permanent test tool. Or the code may legitimately belong untested in a thin shell with no branching logic.

**The combined decision path:**

```text
Test is blocked
  └─ Can you instantiate the class? No → Separation problem
                                   Yes ↓
     Can you assert on its effects? No → Sensing problem
                                    Yes ↓
     [Axis diagnosed. Introduce correct test double.]
       └─ For each test double introduced:
            └─ Does the collaborator return pure data? Yes → Invert to value argument. Mock disappears.
                                                      No  → Genuine I/O. Mock is permanent.
```

**The key reframe:** A recording fake introduced to solve a sensing problem is the clearest signal that the mocked collaborator *could* be a value argument instead of a collaborator. The fake is documenting the architectural boundary — it marks exactly where pure logic was tangled with impure infrastructure. That is the refactoring opportunity.

**Pure value objects are never mocked.** If the thing being mocked is a data structure with no external dependencies — a domain object, a configuration value, a pure data carrier — the mock is a self-created problem. Use the real object. Mocking a pure value object adds complexity without benefit and suppresses the architecture signal.

______________________________________________________________________

### A1 — Applications

## R — Original Sources

**Feathers** (Working Effectively with Legacy Code, Ch. 3):

> "Generally, when we want to get tests in place, there are two reasons to break dependencies: sensing and separation.
>
> 1. Sensing — We break dependencies to sense when we can't access values our code computes.
>
> 2. Separation — We break dependencies to separate when we can't even get a piece of code into a test harness to run."

**Convergence note:** Both skills read test doubles as diagnostic signals about production code architecture, not just as testing tools. Feathers: the shape of the test double reveals which axis is blocked. Bernhardt: mock count is an architectural readout of how many collaborators the production code reaches out to. Neither author treats mock pain as a tooling problem.

**Bernhardt** (Functional Core, Imperative Shell, DAS-0072):

> "There's no need to track down other classes because it's all data in, data out, and there's no need to reason about mocking or stubbing because there just isn't any. Searching the entire source for the word 'mock' yields zero results. Searching for 'stub' yields exactly one... Replacing that stub with a real Tweet would leave the entire system tested in isolation without a single test double. The functional core makes test doubles structurally unnecessary: pure values replace collaborators."

______________________________________________________________________

## I — Unified Framework

A test double reflects an architectural boundary. Both frameworks start from this shared premise, but they operate at different moments in the testing workflow.

**Feathers' first pass: classify the blocker.** When a dependency is blocking a test, two distinct problems can be blocking it, and they have different solutions.

*Separation* is the obstacle of instantiation. The class cannot be constructed or executed in a test at all — its constructor opens a real database connection, talks to hardware, requires the entire application to be running. Every separation fix answers: "How do I build a version of this object that doesn't require live infrastructure?" The technique: parameterize the constructor, extract an interface, inject a null or minimal implementation.

*Sensing* is the obstacle of observation. The class instantiates fine, but its effects are invisible — it calls `logger.Info(...)`, writes to a file, sends a network packet, or mutates state on a collaborator the test can't inspect. Every sensing fix answers: "How do I make the effects of this code visible to my test assertions?" The dominant technique: introduce a recording fake that stores every call and argument it receives.

These two axes are independent. Fix separation first (you cannot sense effects from a class that won't construct). Then, and only then, address sensing.

**Bernhardt's second pass: determine whether the fix is the right final shape.** After the test double is in place and tests pass, apply the purity test to each mock or fake introduced:

*Is the mocked collaborator returning data?* Could the code under test receive this data as an argument instead of calling the collaborator directly? If yes: the collaborator can be inverted. Move the dependency to the caller. The caller passes the data in; the unit computes with the data and returns a result. The mock disappears — there is no longer anything to mock. This code belongs in the functional core.

*Is the mocked collaborator performing I/O or mutating external state?* Then this is genuine shell behavior. The mock is the correct permanent test tool. Or the code may legitimately belong untested in a thin shell with no branching logic.

**The combined decision path:**

```text
Test is blocked
  └─ Can you instantiate the class? No → Separation problem
                                   Yes ↓
     Can you assert on its effects? No → Sensing problem
                                    Yes ↓
     [Axis diagnosed. Introduce correct test double.]
       └─ For each test double introduced:
            └─ Does the collaborator return pure data? Yes → Invert to value argument. Mock disappears.
                                                      No  → Genuine I/O. Mock is permanent.
```

**The key reframe:** A recording fake introduced to solve a sensing problem is the clearest signal that the mocked collaborator *could* be a value argument instead of a collaborator. The fake is documenting the architectural boundary — it marks exactly where pure logic was tangled with impure infrastructure. That is the refactoring opportunity.

**Pure value objects are never mocked.** If the thing being mocked is a data structure with no external dependencies — a domain object, a configuration value, a pure data carrier — the mock is a self-created problem. Use the real object. Mocking a pure value object adds complexity without benefit and suppresses the architecture signal.

______________________________________________________________________

## A1 — Applications

### Case 1: Feathers — NetworkBridge — Both Axes Simultaneously (Hardware Infrastructure Domain)

**Problem:** `NetworkBridge` accepts an array of `EndPoint` objects and manages their hardware configuration. Each `EndPoint` opens a socket and communicates with a physical device on construction. Getting `NetworkBridge` under test requires actual hardware (separation problem). Even with hardware, `formRouting()`'s effects on endpoint configuration go to the hardware, not back through a method return value (sensing problem).

**Methodology:** Diagnose both axes before choosing any technique. Separation: the constructor requires live EndPoint hardware. Sensing: the effects of routing calls are not visible to test code. Fix separation first: extract an interface from `EndPoint`, pass a fake array of implementations that don't open real sockets. Fix sensing second: the fake `EndPoint` implementations record every method call and argument so tests can query what the bridge told each endpoint.

Apply the purity test: do the `EndPoint` fakes return data or perform I/O? They perform I/O (hardware configuration). The fakes are permanent legitimate test tools. The sensing fix is the final shape — this is shell behavior.

**Conclusion:** Diagnosing both axes before starting prevents wasting effort on the wrong fix. The purity test confirms the fakes are permanent — this is not a refactoring prompt.

**Result:** Tests can verify routing behavior without hardware. The fakes are the correct long-term test infrastructure.

______________________________________________________________________

### Case 2: Bernhardt — the Lone Stub — a Self-Diagnosed Mistake (Pure Value Domain)

**Problem:** Bernhardt found one stub in the entire Twitter client codebase. A test for the `Cursor` class stubbed a `Tweet` object instead of using the real `Tweet` value object.

**Methodology:** Apply the purity test directly. Is `Tweet` a pure value object? Yes — it's a data carrier with no external dependencies. There is no reason it can't be used directly in tests. The stub exists because the test was written hastily, not because a stub was needed. Replace the stub with a real `Tweet` and the entire system has zero test doubles — even though almost all of it is tested in isolation.

The Feathers framing adds: what axis was this stub solving? Neither separation (Tweet constructs fine) nor sensing (Tweet is a value, its data is visible). The stub was solving neither problem — it was an unnecessary level of indirection introduced by habit.

**Conclusion:** If you're stubbing a pure value object, you're making work for yourself. Use the real thing. Mocking a pure value suppresses the architecture signal without solving an actual problem.

**Result:** Zero test doubles in the codebase. Every test is direct data-in/data-out with real objects.

______________________________________________________________________

## A2 — When to Use This Skill

Use this skill — not one of its source skills — when:

- You need to both choose the right test double technique (Feathers' diagnostic) AND decide whether the resulting double is a permanent fixture or a refactoring prompt (Bernhardt's purity test) — neither source provides both
- You have introduced a recording fake to solve a sensing problem and are wondering whether the fake should stay or whether it's pointing you toward a functional core extraction
- You have 30 mock setups in a test suite and need to classify each one systematically: separation-axis stub? sensing-axis recording fake? pure-value-that-should-be-a-value-argument? genuine-I/O-at-the-shell?
- You are deciding whether to improve your mocking infrastructure or refactor the production code — this skill redirects from "how do I mock better?" to "why does the code need a mock at all?"

**Instead of welc-sensing-vs-separation or fcis-mocks-as-architecture-signal, use this when:** the question spans both what kind of test double to introduce and whether the introduced double is the right long-term solution. Use `welc-sensing-vs-separation` alone when the only question is which axis is blocking you and which technique to apply. Use `fcis-mocks-as-architecture-signal` alone when tests already exist and you're asking whether the mock count signals an architectural problem.

**Language signals:**

- "I can run it but I don't know what it did" → sensing problem
- "The constructor requires a live database" → separation problem
- "I introduced a recording fake — is this the right final shape?"
- "My tests have 30 mock setups before the test logic begins"
- "My mocks keep breaking when I refactor"
- "Should I use a spy or a stub here?"
- "I stubbed this — do I need to?"

______________________________________________________________________

## E — Execution

**Step 1 — Diagnose the blocking axis (Feathers).**

Ask these two questions in order:

1. Can you write a test that constructs the class and calls the method without errors, even with wrong behavior? If no → separation problem exists.
2. If you call the method, can you write an assertion that would actually fail if the behavior were wrong? If no → sensing problem exists.

Write down which axis or axes are blocking. Do not start choosing a technique until both questions are answered. If both axes are blocked, fix separation first — you cannot sense effects from a class that won't construct.

**Step 2 — Apply the minimum fix for the blocking axis (Feathers).**

For **separation:**

- Preferred: parameterize the constructor — make the dependency an argument instead of a hard-coded internal creation.
- If hard to parameterize: extract an interface on the depended-on class and inject a null or minimal implementation.
- Check: can the test construct the object without errors?

For **sensing:**

- The dominant technique: introduce a recording fake. Write a test-only implementation that stores every call and argument in a list. Assert against that list.
- If no interface exists yet: locate the seam (see welc-seam-model) and introduce one.
- Check: can you write an assertion that would fail for wrong behavior?

**Step 3 — Write the simplest possible failing test.**

A test that can never fail is a sensing failure you haven't noticed yet. If the test passes trivially without a real assertion, the sensing problem is not solved.

**Step 4 — Apply the purity test to each test double introduced (Bernhardt).**

For each mock, stub, or fake you just created:

- **Is the mocked collaborator returning pure data** (data in, data out, no I/O, no external mutation)? If yes:

  - Could the code under test receive this data as a value argument instead of calling the collaborator?
  - If yes: invert the dependency. Refactor the unit to accept data as arguments. Extract the pure computation into a separate function or class. The mock disappears. This code moves toward the functional core.
  - The recording fake you introduced was a refactoring prompt, not a permanent solution.

- **Is the mocked collaborator performing I/O or mutating external state** (database, network, filesystem, shared mutable state)? If yes:

  - This is genuine shell behavior. The mock is the correct permanent test tool.
  - If the shell has no branching logic (just routes to core functions and assigns results), leaving it untested may be appropriate.

- **Is the thing being mocked a pure value object** (data carrier, domain object, no external dependencies)? If yes:

  - Use the real object. There is no reason to mock a pure value. Replace the mock with the real thing.

**Step 5 — Re-evaluate remaining mocks.**

After extraction: every remaining mock should be either (a) in a thin shell with few conditionals testing genuine I/O paths, or (b) in an integration test that tests the actual I/O path end to end. If mocks remain in code that has no genuine I/O, the purity test missed a collaborator that should be inverted to a value argument.

______________________________________________________________________

## B — Boundaries

**When this skill is inapplicable:**

- **Purely functional code:** Code with no side effects has no sensing problem (return values are the effects) and typically no separation problem. The sensing/separation framework is unnecessary.
- **Already injectable dependencies:** If the class already accepts its dependencies via constructor or method arguments, both axes may be solved. Don't apply the diagnostic to code that's already testable — just write the test.
- **Integration tests by design:** Some tests are supposed to run against real infrastructure. The sensing/separation diagnostic applies to unit and fast-feedback tests. Integration tests that intentionally test the I/O path should use mocks or fakes for external services appropriately — don't apply "eliminate the mock" here.
- **External services with non-deterministic behavior:** A controlled mock for a third-party API with rate limits or flaky responses is appropriate. The goal is not to eliminate all mocks everywhere — it is to eliminate mocks that exist because the production code has unnecessary collaborators.

**Source A failures (Feathers / sensing vs. separation):**

- Reaching for Extract Interface as the universal fix without diagnosing whether separation or sensing is the actual blocker — wasted effort, over-engineering
- Multiple simultaneous sensing problems: a class may have N independent sensing points (logger, event bus, cache); the framework correctly names the axis but doesn't address prioritization when multiple sensing points exist
- Over-application of sensing fakes: inserting recording fakes for every dependency creates tests tightly coupled to implementation detail — use sensing fakes to test behavioral outcomes, not internal call sequences
- Distributed/async sensing: effects that cross a network boundary or occur asynchronously require a different class of recording fakes; the sensing concept is correct but the implementation is more complex than the chapter suggests

**Source B failures (Bernhardt / mocks as architecture signal):**

- Using stubs instead of real value objects: if the thing being mocked is a pure value, use the real thing — mocking a pure value suppresses the architecture signal
- Mock proliferation suppressing the architecture signal: improving mock tooling without fixing the production code treats the symptom, not the cause
- Shell-level tests still need mocks: the "zero mocks" claim applies to the functional core; the shell, if tested, legitimately needs doubles for external resources
- Large systems with many domain collaborators: inverting to value arguments may produce functions with very large argument lists; the insight is directionally correct but may require additional patterns (domain events as pure values carrying relevant data)

**Synthesis-specific failure mode:** Using Feathers' framework to introduce a recording fake for a collaborator that returns pure data — and then stopping, treating the fake as the final state, without applying Bernhardt's purity test. The sensing problem is solved (tests pass), but the architectural problem is unchanged. The recording fake is documenting that a pure computation is entangled with a collaborator that could instead be a value argument. This is the most common combined failure: Feathers users stop at "tests pass"; Bernhardt's framework would prescribe eliminating the fake by architectural refactoring. The purity test in Step 4 is the bridge between the two stopping conditions.

**Genuine tension:** Feathers accepts mocks as permanent fixtures in well-tested legacy code. Bernhardt treats mocks as temporary symptoms to be resolved by architectural refactoring. These are not contradictory — they apply to different collaborator types. The conditional in Step 4 resolves the tension: pure-data collaborators follow Bernhardt's prescription (invert, eliminate); genuine-I/O collaborators follow Feathers' prescription (use the appropriate test double). The tension is real and the resolution requires asking the purity question for each collaborator — there is no universal answer.
