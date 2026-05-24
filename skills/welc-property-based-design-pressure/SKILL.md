---
name: welc-property-based-design-pressure
description: |
  Invoke this skill when a developer is struggling to write property-based tests, asking whether to use property-based testing, or trying to understand why their function is hard to test exhaustively. Specific triggers: a developer reports that their properties keep requiring exception clauses or special-case conditions; someone is choosing between example-based and property-based testing; a function's invariants are hard to state in universal terms; someone wants to know what makes property-based testing different from fuzz testing.

  Do NOT invoke when: the question is about which property-based testing library to install or how to use a specific framework's API; the function is simple CRUD with no non-trivial invariants; the question is purely about test coverage percentage or mutation score; the function's design is not in question and properties are already clean.

  Key signals: "I'm trying to write property-based tests but the properties keep having exceptions", "should I use property-based tests for this function?", "my function is hard to test with example inputs", "what invariants should hold for this function?", "my property tests need a lot of conditional logic", "I can write examples but I can't figure out what the general rule is."
source_book: Working Effectively with Legacy Code — Michael C. Feathers; also informed by Feathers' 'Testing Patience' talks (all three recorded versions) and p17 (Jessica Kerr, 'Writing property-based tests forces you to think way harder')
source_chapter: Testing Patience (conference talk, multiple versions); merged with f15 (Working Effectively with Legacy Code chapter on sensing and separation)
tags: [property-based-testing, design-pressure, invariants, TDD, test-difficulty, design-smell, legacy-code]
related_skills: [welc-characterization-test, welc-seam-model, welc-sensing-vs-separation, welc-tended-untended-systems]
---

# Property-Based Testing as Design Pressure

## R — Original Text (Reading)

> "Writing property-based tests forces you to think way harder."
>
> — Jessica Kerr (quoted by Michael Feathers in "Testing Patience")
>
> The key insight is: when you find yourself writing a property test with many exception clauses — "this property holds, except when X, except when Y, except when the input contains Z" — that is not a testing problem. It is a design problem. The function's contract is not clean enough to state universally.
>
> Consider a sort function in F#. One property: appending `minValue` to a list and then sorting it yields the same result as sorting the list and then prepending `minValue`. This property is universal — no exceptions, no special cases. If stating this property required exception clauses, that would be a signal that the sort function's contract was underspecified or that the function was doing too many things.
>
> — Feathers, "Testing Patience" (multiple recorded versions)
>
> Property-based testing shifts the question from "does this function produce the right output for these inputs?" to "what must be true of this function's output for all valid inputs?" That shift is mechanically harder, and the difficulty is diagnostic.
>
> — Feathers, "Testing Patience"

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Property-based testing requires stating mathematical invariants that hold universally across all valid inputs, rather than verifying specific input-output pairs. The framework has three distinct and separable uses:

**Use 1 — Quality tool (forcing deeper thinking):** Articulating properties demands that you understand the function's contract at a higher level of abstraction than examples require. You cannot write a clean universal property for a function you do not deeply understand. The effort of property articulation produces better understanding of what the function should do, which in turn produces better design of what the function does.

**Use 2 — Maintenance tool (invariant survival through rewrites):** Properties test WHAT a function does, not HOW it does it. Example-based tests often break when implementation details change because they are coupled to specific intermediate outputs or orderings. Property-based tests survive rewrites as long as the function's contract is preserved. This makes them unusually durable for legacy code that needs to change.

**Use 3 — Design diagnostic (property difficulty = design smell):** This is Feathers' distinctive contribution. When you struggle to articulate clean, exception-free properties for a function, that struggle is information about the function's design. A function that requires many conditional clauses in its property statement is a function whose contract is too complex to state cleanly — which means it is doing too many things, or its responsibilities are poorly bounded. The correct response is not to write a more complex property. It is to decompose the function until each piece has clean, universal properties.

### The Decomposition Heuristic

When a property keeps acquiring exception clauses, ask: what is the minimal decomposition that would make this property exception-free? The exception clause usually reveals a hidden sub-responsibility that should be extracted into its own function with its own clean properties.

**Clean property (no exceptions needed):** `sort(list + [minValue]) == [minValue] + sort(list)` — This holds for all valid lists. No exceptions.

**Property requiring exceptions (design smell):** `result contains all input elements, in order, except when input contains duplicates the behavior is X, except when input is null the behavior is Y, except when input exceeds capacity Z` — Each "except when" is a signal that the function has a hidden responsibility that should be separated.

### Distinguishing from Fuzz Testing

Property-based testing and fuzz testing both generate many inputs, but they are different activities. Fuzz testing searches for inputs that cause crashes, panics, or exceptions — it finds the boundary of "what the function tolerates." Property-based testing constrains the space of valid outputs — it verifies that for every generated input, the output satisfies a stated invariant. A property-based test requires a property; a fuzz test only requires a function to call.

### When Not to Use Property-Based Tests

Not every function has non-trivial properties worth testing with a property-based framework. Simple CRUD functions (persist this record, retrieve that record) have trivially verifiable example-based tests. Forcing property-based tests onto simple functions adds overhead without adding signal. The question to ask is: "Is there a universal invariant here that example-based tests cannot adequately cover?" If the answer is no, use examples.

______________________________________________________________________

## A1 — Past Application (From the Talks)

### Case 1: Sort Function in F# (Testing Patience)

- **Question:** How do you write a property-based test for a sort function? What invariant holds universally?
- **Use of Methodology:** Feathers uses this as the canonical example. The property `sort(list + [minValue]) == [minValue] + sort(list)` is clean and exception-free. It expresses a real mathematical invariant about the sort function's behavior with respect to minimum elements. The property could not acquire exception clauses without revealing a problem in the sort function's design.
- **Conclusion:** A clean, exception-free property demonstrates that the function has a clear, bounded contract. The property becomes a specification: any implementation satisfying this property (and similar properties for other invariants) is a correct sort function.
- **Result:** The test survives complete rewrites of the sort implementation. Switching from quicksort to mergesort to timsort leaves the property true. This is the maintenance-tool use in action.

### Case 2: Property Articulation Difficulty as a Diagnostic

- **Question:** A developer is trying to write a property-based test for a function that validates, transforms, and routes a business event in a single operation. The property keeps needing exception clauses: "the output should contain only valid events, except when the input has missing fields, except when the routing table is empty, except when the event type is deprecated..."
- **Use of Methodology:** Each "except when" is a hidden sub-responsibility. Validation logic should be separated from transformation logic, which should be separated from routing logic. Each separated piece has a clean property. The validation function has the property: "the output is a subset of the input, containing only elements for which the validation predicate holds." The routing function has the property: "every output element's destination key appears in the routing table." Neither property requires exception clauses.
- **Conclusion:** The property articulation difficulty was a design signal. The function was doing three things. Decomposing it into three functions with three clean properties produces both a better design and a more maintainable test suite.
- **Result:** After decomposition, each function's properties are testable with standard property-based frameworks without conditional logic in the property statement itself.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A developer is trying to write QuickCheck or Hypothesis tests for a parsing function. After two days, the properties still have four `if` branches and two "except when the input is malformed" clauses. They ask: "Is my property-based test framework not powerful enough?"
2. A team is debating whether to use property-based testing for a REST API's CRUD endpoints. They ask: "Should we use property-based tests here?"
3. A developer says: "I can always come up with good example inputs for this function, but I can't figure out what the general rule is that the function should follow. I know the examples are right but I can't state a property."
4. A team is refactoring legacy code and wants tests that will survive the rewrite without being recoupled to implementation details. They ask: "What kind of tests should we write before starting this refactor?"

### Language Signals

- "I'm trying to write property-based tests but the properties keep having exceptions"
- "should I use property-based tests for this function?"
- "my function is hard to test with example inputs"
- "I know the examples pass but I can't state a general invariant"
- "my property tests need a lot of conditional logic inside them"
- "the property I wrote isn't really universal — it only works for simple inputs"
- "I can't figure out what should always be true for all inputs"

### Distinguishing from Adjacent Skills

- Difference from `welc-three-goals-of-testing`: Three goals (documentation, defect detection, design feedback) is a framework for choosing what kind of tests to write for a given purpose. Property-based design pressure is a specific diagnostic tool within the design-feedback category — it explains why property articulation difficulty is itself informative about design quality.
- Difference from `welc-characterization-test`: Characterization tests capture what a function currently does (for legacy code). Property-based tests specify what a function must always do. Characterization tests are about preserving behavior during refactoring; property-based tests are about specifying and validating contracts. They can be used together: characterize first to establish a safety net, then decompose using property-based design pressure, then replace characterization tests with property-based tests on the cleaner pieces.

______________________________________________________________________

## E — Execution Steps

1. **Attempt to state the function's properties in universal terms**

   - Without looking at the implementation, write down: "For all valid inputs X, f(X) satisfies \_\_\_." Try to complete this without any "except when" clauses.
   - Completion criteria: Either a clean, exception-free property statement exists, or you have a list of exception clauses that constitute the diagnostic.
   - Stop condition: If a clean universal property emerges without effort, the function has good design — proceed to implement the property-based test directly.

2. **Treat each "except when" clause as a design signal**

   - For each exception clause in your property statement, ask: "What responsibility does this exception reveal?" Name it explicitly. Write it down as a candidate function.
   - Completion criteria: Each exception clause has been assigned to a named candidate sub-responsibility.

3. **Decompose the function along the discovered sub-responsibility boundaries**

   - Extract each sub-responsibility into its own function. Each extracted function should have a clean universal property with no exception clauses.
   - Completion criteria: Each extracted function has a property that can be stated in one sentence with no conditionals.
   - Stop condition: If decomposition produces a function whose property still requires exception clauses, the decomposition is not yet complete — recurse on that function.

4. **Write the property-based tests for the decomposed functions**

   - Use a property-based testing framework (QuickCheck, Hypothesis, fast-check, gopter, etc.) to generate inputs and assert the invariants. The test body should not contain `if` branches over the input — if it does, the property is not yet universal.
   - Completion criteria: Each property-based test's assertion is a single, unconditional predicate over the generated input and output.

5. **Decide whether property-based tests are warranted at all**

   - If the function is simple CRUD with no non-trivial invariants, example-based tests are sufficient. Apply the test: "Is there a universal invariant here that examples cannot adequately cover?" If no, use examples.
   - Completion criteria: The choice between example-based and property-based testing is explicit and justified, not defaulted.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is about which property-based testing framework to install or how to configure it. This skill is about the design insight, not framework mechanics.
- The function is simple CRUD with no meaningful invariants beyond "the record stored is the record retrieved." Property-based testing does not add signal for purely stateful persistence operations.
- The team's only goal is raising coverage percentage. Property-based tests provide design feedback and invariant verification; they are the wrong tool for mechanical coverage improvement.
- The code cannot be tested at all yet due to tight coupling, external dependencies with no interfaces, or no seams. Address testability first (see `welc-seam-model`, `welc-sensing-vs-separation`), then apply property-based design pressure.

### Counter-Examples (Failure Patterns)

- **ce-complexity-in-property**: Writing increasingly complex property statements (with nested conditionals, input filters, and exception branches) instead of treating the complexity as a design signal. The correct response to a property that requires conditionals is to decompose the function, not to make the property smarter.
- **ce-fuzz-confusion**: Treating property-based testing as equivalent to fuzz testing. Fuzz testing finds inputs that crash the function. Property-based testing verifies that outputs satisfy invariants. Combining them is valid (generate surprising inputs AND assert invariants), but they are different concerns.
- **ce-universal-hammer**: Applying property-based testing to every function regardless of whether non-trivial invariants exist. A CRUD function that stores and retrieves a record has the trivial invariant "what you store is what you retrieve" — this is correctly covered by a single example-based test. Generating thousands of random records to test this adds noise without signal.
- **ce-testing-problem-framing**: Responding to property articulation difficulty by blaming the testing framework, the input generator, or the property syntax. The difficulty is about the function's design, not the test infrastructure.

### Author's Blind Spots / Era Limitations

- The "Testing Patience" talks predate the widespread adoption of property-based testing in mainstream languages. Hypothesis (Python), fast-check (TypeScript), and gopter (Go) have substantially improved the ergonomics since Feathers' examples. The design-pressure insight remains valid regardless of framework ergonomics.
- The talks focus on pure functions with mathematical invariants (sort, arithmetic, data structures). Applying property-based design pressure to effectful functions (those with I/O, external state, or time dependencies) requires additional patterns (effect isolation, test doubles for non-determinism) that Feathers does not address in this context.
- Feathers does not address the cost of property-based tests in CI pipelines — they can run slowly when generating thousands of inputs. Teams must balance the design and maintenance benefits against runtime cost. Shrinking (automatic minimal failing-case reduction, a feature of mature frameworks) mitigates but does not eliminate this.

### Easily Confused Adjacent Methodology

- **Characterization tests** (from Working Effectively with Legacy Code) capture what code currently does, enabling safe refactoring. They answer "what does this function do?" not "what must always be true?" They are about preserving observed behavior, not specifying required invariants. Use characterization tests first on untested legacy code; use property-based design pressure to guide decomposition into cleaner units.
- **TDD with example-based tests** drives design through specific cases. Property-based design pressure is complementary: examples specify desired behaviors, properties specify invariants. Neither replaces the other. The design-pressure value of properties is specifically in the difficulty of stating them universally — that difficulty does not arise in example-based TDD.

______________________________________________________________________

## Related Skills

- **welc-characterization-test** — depends-on: hard-to-write characterization tests on existing legacy code are a downstream signal of design problems; property-based design pressure is the analytical framework for diagnosing and correcting those problems through decomposition.
- **welc-seam-model** — combines-with: hard-to-find seams and hard-to-state properties are correlated signals of tight coupling; both point to the same structural problems; seam analysis exposes the coupling, property difficulty quantifies the contract complexity.
- **welc-sensing-vs-separation** — combines-with: persistent sensing problems (effects that cannot be cleanly observed) signal hidden effects in design; property-based design pressure converts that signal into a decomposition directive — extract until each piece has observable, universal invariants.
- **welc-tended-untended-systems** — combines-with: design pressure applies most forcefully when the system is tended and long-lived; for untended systems, property-based tests also serve as durable pre-deployment specifications that survive implementation rewrites.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ (all three talk versions) / V2 ✓ / V3 ✓
- **Source merge**: f15 + p17
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-05
