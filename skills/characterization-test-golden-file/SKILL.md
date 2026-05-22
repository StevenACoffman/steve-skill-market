---
name: characterization-test-golden-file
allowed-tools: Bash, Read, Edit
id: characterization-test-golden-file
description: Use when you need to establish a behavioral safety net around code you do not fully understand before refactoring, rewriting, or replacing it — especially when the output is complex enough that inline expected values are unreadable or unmaintainable. Combines the fail-observe-pin posture for building comprehension (Feathers) with golden-file storage and the -update flag for assertion maintainability (Hashimoto).
type: merged-skill
source_skills:
  - slug: welc/welc-characterization-test
    book: Working Effectively with Legacy Code
    author: Michael C. Feathers
  - slug: hashimoto/golden-files-update-flag
    book: Advanced Testing with Go
    author: Mitchell Hashimoto
related_skills:
  - slug: welc/welc-characterization-test
    relation: supersedes
    note: Merged skill adds golden-file storage and -update flag; use this instead for any Go codebase
  - slug: hashimoto/golden-files-update-flag
    relation: supersedes
    note: Merged skill adds characterization posture and lifecycle guidance; use this for legacy/rewrite contexts
tags: []
---

# Characterization Test with Golden File Storage

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Existing golden files:
!`find . -name '*.golden' -not -path './.git/*' 2>/dev/null | head -10`

Test-fixtures dirs:
!`find . -type d -name 'test-fixtures' -not -path './.git/*' 2>/dev/null`

### R — Original Text (Reading)

**Feathers — the characterization test mechanism:**

> A characterization test is a test that characterizes the actual behavior of a piece of code. There's no "Well, it should do this" or "I think it does that." The tests document the actual current behavior of the system.
>
> **The Algorithm:** (1) Use a piece of code in a test harness. (2) Write an assertion that you know will fail. (3) Let the failure tell you what the behavior is. (4) Change the test so that it expects the behavior that the code produces. (5) Repeat.
>
> — Michael C. Feathers, *Working Effectively with Legacy Code*, Ch. 13
>
> When we write characterization tests, we aren't trying to find bugs. We are trying to understand the software well enough to be able to make changes safely.
>
> — Michael C. Feathers, *Working Effectively with Legacy Code*, Ch. 13
>
> Behavioral invariants ensure correctness across rewrites. As systems become more transient, rewrite services when you want to — behavioral invariants ensure correctness across rewrites.
>
> — Michael C. Feathers, *Testing Patience*

**Hashimoto — golden file storage and the -update flag:**

```go
var update = flag.Bool("update", false, "update golden files")

func TestAdd(t *testing.T) {
	// … table (probably!)
	for _, tc := range cases {
		actual := doSomething(tc)
		golden := filepath.Join("test-fixtures", tc.Name+".golden")
		if *update {
			ioutil.WriteFile(golden, actual, 0644)
		}
		expected, _ := ioutil.ReadFile(golden)
		if !bytes.Equal(actual, expected) {
			// FAIL
		}
	}
}
```

> Test complex output without manually hardcoding expected bytes. Human-eyeball the generated golden data; if it is correct, commit it. Very scalable way to test complex structures (write a `String()` method and use it as the golden output).
>
> — Mitchell Hashimoto, *Advanced Testing with Go*, Part 1 / Golden Files
>
> "The place in the standard lib where I first saw this… is to test gofmt. When they test gofmt they run gofmt and then they compare the resulting bytes to a golden file's contents and they put this flag which is really interesting… the flag update… updates all the golden files."
>
> — Mitchell Hashimoto, *Advanced Testing with Go*

**Convergence note:** Both authors independently discovered the same mechanism — let the code supply the expected value, inspect once at commit time, pin permanently — but from different starting problems. Feathers arrived at it from the change-safety problem in legacy OO code (2005); Hashimoto arrived at it from the assertion-maintainability problem in Go formatter testing (~2017). Feathers' manual fail-observe-pin builds comprehension of unknown behavior case-by-case; Hashimoto's `-update` flag automates expected-value capture and scales to hundreds of cases simultaneously.

______________________________________________________________________

### I — Methodological Framework (Interpretation)

The characterization test approach inverts the normal test-writing posture. Standard tests are forward-looking: you reason about what code should do and write assertions that verify conformance. Characterization tests are backward-looking: you ask the code what it already does, with no assumption that the answer is correct.

This inversion matters when you have no accessible specification — when intent has been lost, the original author is unavailable, and requirements documents don't match the code. Trying to write specification tests in this situation produces either wrong tests (that fail on correct behavior) or gaps (behavior that exists but wasn't anticipated by your reasoning). The characterization approach bypasses both problems by letting the code itself supply the expected values.

**The storage question.** Feathers' algorithm was designed for a world of simple string or numeric expected values. When the output is a rendered graph, a serialized AST, a formatted document, or any complex type, inline expected values become untenable: 200 lines of escaped string literal in a test assertion is not readable, and maintaining it when behavior changes intentionally is more painful than the change it was meant to guard. Golden files solve this storage problem: expected output lives in committed files under `test-fixtures/`, compared byte-for-byte at test time.

**Two distinct intents, one mechanism.** When your goal is comprehension of unknown behavior, use the manual fail-observe-pin posture (Feathers): write a failing assertion with a nonsense placeholder, observe what the code actually produces, copy that into the golden file. The act of running and reading the output builds your mental model of what the code does. When your goal is assertion maintainability on code whose behavior you already understand, use the `-update` flag (Hashimoto): run `go test -update`, generate all expected outputs at once, inspect via `git diff`, commit if correct. The `-update` flag bypasses the comprehension step — it is for when you have already decided the output is correct and need only to re-pin it after an intentional change.

**The rewrite enabler.** When characterization tests are written at the API boundary of a component — at `result = component.Process(input)` rather than at internal state or private methods — they survive a complete structural rewrite. The new implementation must produce the same bytes the old implementation produced. Golden files are the natural storage format for this: they live in the repository as committed artifacts, they are compared byte-for-byte in CI, and they produce readable diffs when the new implementation diverges. This is what allows the move from "carefully refactor method-by-method" to "rewrite and verify equivalence in CI."

**The moral authority constraint.** A passing characterization test does not mean the code is correct. It means the code has not changed from what it did when you pinned it. Known bugs remain bugs — they are now documented and tracked, but not fixed. This is the right guarantee for refactoring (structural changes must preserve behavior), not for bug-finding.

| Condition                                                               | Use manual fail-observe-pin (Feathers posture) | Use -update flag (Hashimoto posture)        |
| ----------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------- |
| Legacy code, unknown behavior, need comprehension                       | Yes — the manual step builds your mental model | No — the update flag bypasses comprehension |
| Known behavior, complex output, need to re-pin after intentional change | Not applicable                                 | Yes — -update flag scales to all cases      |
| Enabling a service rewrite                                              | Yes — write at API boundary, pin the contract  | Yes — golden files are the storage format   |
| Output is a string/bytes blob                                           | Either — golden file is the natural container  | Yes                                         |
| Output is a complex struct                                              | Either — add String() method first             | Yes                                         |

______________________________________________________________________

### A1 — Past Application

## R — Original Text (Reading)

**Feathers — the characterization test mechanism:**

> A characterization test is a test that characterizes the actual behavior of a piece of code. There's no "Well, it should do this" or "I think it does that." The tests document the actual current behavior of the system.
>
> **The Algorithm:** (1) Use a piece of code in a test harness. (2) Write an assertion that you know will fail. (3) Let the failure tell you what the behavior is. (4) Change the test so that it expects the behavior that the code produces. (5) Repeat.
>
> — Michael C. Feathers, *Working Effectively with Legacy Code*, Ch. 13
>
> When we write characterization tests, we aren't trying to find bugs. We are trying to understand the software well enough to be able to make changes safely.
>
> — Michael C. Feathers, *Working Effectively with Legacy Code*, Ch. 13
>
> Behavioral invariants ensure correctness across rewrites. As systems become more transient, rewrite services when you want to — behavioral invariants ensure correctness across rewrites.
>
> — Michael C. Feathers, *Testing Patience*

**Hashimoto — golden file storage and the -update flag:**

```go
var update = flag.Bool("update", false, "update golden files")

func TestAdd(t *testing.T) {
	// … table (probably!)
	for _, tc := range cases {
		actual := doSomething(tc)
		golden := filepath.Join("test-fixtures", tc.Name+".golden")
		if *update {
			ioutil.WriteFile(golden, actual, 0644)
		}
		expected, _ := ioutil.ReadFile(golden)
		if !bytes.Equal(actual, expected) {
			// FAIL
		}
	}
}
```

> Test complex output without manually hardcoding expected bytes. Human-eyeball the generated golden data; if it is correct, commit it. Very scalable way to test complex structures (write a `String()` method and use it as the golden output).
>
> — Mitchell Hashimoto, *Advanced Testing with Go*, Part 1 / Golden Files
>
> "The place in the standard lib where I first saw this… is to test gofmt. When they test gofmt they run gofmt and then they compare the resulting bytes to a golden file's contents and they put this flag which is really interesting… the flag update… updates all the golden files."
>
> — Mitchell Hashimoto, *Advanced Testing with Go*

**Convergence note:** Both authors independently discovered the same mechanism — let the code supply the expected value, inspect once at commit time, pin permanently — but from different starting problems. Feathers arrived at it from the change-safety problem in legacy OO code (2005); Hashimoto arrived at it from the assertion-maintainability problem in Go formatter testing (~2017). Feathers' manual fail-observe-pin builds comprehension of unknown behavior case-by-case; Hashimoto's `-update` flag automates expected-value capture and scales to hundreds of cases simultaneously.

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The characterization test approach inverts the normal test-writing posture. Standard tests are forward-looking: you reason about what code should do and write assertions that verify conformance. Characterization tests are backward-looking: you ask the code what it already does, with no assumption that the answer is correct.

This inversion matters when you have no accessible specification — when intent has been lost, the original author is unavailable, and requirements documents don't match the code. Trying to write specification tests in this situation produces either wrong tests (that fail on correct behavior) or gaps (behavior that exists but wasn't anticipated by your reasoning). The characterization approach bypasses both problems by letting the code itself supply the expected values.

**The storage question.** Feathers' algorithm was designed for a world of simple string or numeric expected values. When the output is a rendered graph, a serialized AST, a formatted document, or any complex type, inline expected values become untenable: 200 lines of escaped string literal in a test assertion is not readable, and maintaining it when behavior changes intentionally is more painful than the change it was meant to guard. Golden files solve this storage problem: expected output lives in committed files under `test-fixtures/`, compared byte-for-byte at test time.

**Two distinct intents, one mechanism.** When your goal is comprehension of unknown behavior, use the manual fail-observe-pin posture (Feathers): write a failing assertion with a nonsense placeholder, observe what the code actually produces, copy that into the golden file. The act of running and reading the output builds your mental model of what the code does. When your goal is assertion maintainability on code whose behavior you already understand, use the `-update` flag (Hashimoto): run `go test -update`, generate all expected outputs at once, inspect via `git diff`, commit if correct. The `-update` flag bypasses the comprehension step — it is for when you have already decided the output is correct and need only to re-pin it after an intentional change.

**The rewrite enabler.** When characterization tests are written at the API boundary of a component — at `result = component.Process(input)` rather than at internal state or private methods — they survive a complete structural rewrite. The new implementation must produce the same bytes the old implementation produced. Golden files are the natural storage format for this: they live in the repository as committed artifacts, they are compared byte-for-byte in CI, and they produce readable diffs when the new implementation diverges. This is what allows the move from "carefully refactor method-by-method" to "rewrite and verify equivalence in CI."

**The moral authority constraint.** A passing characterization test does not mean the code is correct. It means the code has not changed from what it did when you pinned it. Known bugs remain bugs — they are now documented and tracked, but not fixed. This is the right guarantee for refactoring (structural changes must preserve behavior), not for bug-finding.

| Condition                                                               | Use manual fail-observe-pin (Feathers posture) | Use -update flag (Hashimoto posture)        |
| ----------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------- |
| Legacy code, unknown behavior, need comprehension                       | Yes — the manual step builds your mental model | No — the update flag bypasses comprehension |
| Known behavior, complex output, need to re-pin after intentional change | Not applicable                                 | Yes — -update flag scales to all cases      |
| Enabling a service rewrite                                              | Yes — write at API boundary, pin the contract  | Yes — golden files are the storage format   |
| Output is a string/bytes blob                                           | Either — golden file is the natural container  | Yes                                         |
| Output is a complex struct                                              | Either — add String() method first             | Yes                                         |

______________________________________________________________________

## A1 — Past Application

### Case 1: PageGenerator — Fail-Observe-Pin to Build Comprehension (Feathers, Ch. 13)

**Problem:** A `PageGenerator` class needs to be changed. There are no tests and no specification. The developer doesn't know what the `generate()` method produces for any given input.

**Methodology:** Write a test that asserts `result == "fred"` — a value you know is wrong. Run the test. The failure message reads: `expected "fred" but got ""`. Now you know: the PageGenerator produces an empty string on fresh creation. Update the assertion to `result == ""`. The test passes. Repeat with different inputs; capture the actual output each time.

**Conclusion:** Within a handful of iterations, you have a test suite documenting what the PageGenerator does in several concrete cases — without reading the implementation. The manual fail-observe-pin cycle built your mental model of the class as a side effect.

**Result:** Tests document that PageGenerator produces `""` on fresh creation and a specific XML string with a given row mapping. No bugs are intentionally fixed; the tests are a future regression detector and change-confidence mechanism.

______________________________________________________________________

### Case 2: Terraform Graph — Golden Files for 2,000-Node DAG Output (Hashimoto)

**Problem:** Terraform graph nodes need testing, but a graph can have 2,000 or more nodes. `reflect.DeepEqual` failure on such a structure is a nightmare — the failure message contains thousands of fields with no indication of which one changed.

**Methodology:** Graph nodes implement `testString()` (unexported, producing a human-readable indented representation of the graph). Tests call `testString()` on the result and compare against a golden file. When graph rendering logic changes intentionally, `go test -update` regenerates all golden files in one command; `git diff test-fixtures/` shows exactly what changed.

**Conclusion:** The golden file produces a compact, readable diff. A developer can look at the changed `.golden` file in a PR and understand immediately whether the change in graph representation is correct or a regression.

**Result:** HashiCorp adopted this as standard across Terraform, Consul, Vault, and Nomad. The pattern is now directly traceable to the Go standard library's `gofmt` test suite, where it originated.

______________________________________________________________________

## A2 — Trigger Scenario ★

Instead of asking "how do I write tests for code I don't understand?" (Feathers alone) or "how do I test complex output without hardcoding expected bytes?" (Hashimoto alone), use this merged skill when:

**Trigger 1 — Characterizing legacy code with complex output before a rewrite:** You are about to replace a service or module. The service has no tests. Its output is complex — a rendered document, a serialized graph, a formatted report — and you cannot write inline expected values for it. You need both comprehension (what does it produce?) and maintainability (how do I keep these tests from becoming unmaintainable as the project evolves?).

**Trigger 2 — Before refactoring when inline assertions are infeasible:** You need a characterization safety net, but the output is too large or complex for inline `== "..."` assertions. Golden files are the solution to the storage problem; the characterization posture is the solution to the comprehension problem.

**Trigger 3 — Behavioral invariant contract for a rewrite:** You want to verify that a new implementation produces byte-for-byte the same outputs as the old one at the API boundary. Golden files committed to the repository are the machine-checkable contract.

**Trigger 4 — Adding characterization coverage to code you are about to touch:** You need coverage of the change boundary and adjacent behaviors. Some of those behaviors produce complex output. Use the characterization posture to discover what the outputs are; use golden files to store them.

**Do NOT use when:**

- Writing tests for new code you are about to write (use TDD instead).
- You already have a specification and want to verify conformance (those are specification tests).
- The output is non-deterministic (timestamps, UUIDs, random values) — normalize or strip those before comparison, or choose a different assertion strategy.
- The code has never been run in production and has no established behavior to characterize.
- The expected output is small and stable enough to inline (a single string, a number, two lines of text).

______________________________________________________________________

## E — Execution Steps

Work through these steps in order. Do not evaluate correctness during steps 1–4 — the goal is empirical documentation, not verification.

## Step 1: Get the Code into a Test Harness

Verify that you can call the code from a test and compile. If the code cannot be instantiated or called due to dependencies, break those dependencies first (Extract Interface, Parameterize Constructor). Do not proceed until the code is callable from a test.

## Step 2: Add the Package-Level Update Flag (Once per Package)

```go
var update = flag.Bool("update", false, "update golden files")
```

Place this at the top of a `_test.go` file, outside any function. Create `test-fixtures/` if it does not exist.

## Step 3: Add a String() Method to the Type Under Test (If Output Is Complex)

```go
func (g *Graph) String() string {
	// canonical, deterministic human-readable representation
	// sort any maps before iteration — output must be deterministic
}
```

For test-only serialization, use an unexported `testString()` method in the same package.

## Step 4: Write a Failing Assertion Using a Nonsense Placeholder

For each behavior to characterize, write an assertion you know will fail. Use `"PLACEHOLDER"`, `"fred"`, `-999`:

```go
actual := []byte(codeUnderTest.String())
golden := filepath.Join("test-fixtures", t.Name()+".golden")
// First run: the golden file doesn't exist — this will fail.
// That is the point.
expected, err := os.ReadFile(golden)
if err != nil {
	t.Fatalf("missing golden file %s — run go test -update to create", golden)
}
if !bytes.Equal(actual, expected) {
	t.Errorf("output mismatch:\ngot:\n%s\nwant:\n%s", actual, expected)
}
```

Run the test. It fails because the golden file does not exist. Read the failure message. This is the first observation.

## Step 5: Capture Output as the Golden File

```bash
go test -update ./path/to/package/...
```

This runs the code, captures its actual output, and writes it to `test-fixtures/<case-name>.golden`. The `-update` flag is Hashimoto's mechanism for Feathers' "accept the actual output as the expected value" step — automated for all cases at once.

## Step 6: Inspect the Golden File Before Committing

```bash
git diff test-fixtures/
```

Read the golden file. Ask: does this output make sense given what you now know about the code? If the output looks wrong (e.g., an empty document where you expected content), this is your opportunity to discover that the code is not doing what you thought. Do not commit until you have inspected and understood what was produced.

This step is the moral authority check: pinning does not mean correct. Human inspection at commit time is the only correctness gate.

## Step 7: Commit the Golden Files

```bash
git add test-fixtures/ && git commit -m "characterize <component> behavior before rewrite"
```

Golden files are version-controlled test data. They belong in the same commit as the test code that generates them.

## Step 8: Repeat for Additional Behaviors (Use t.Run for Table-Driven Coverage)

For multiple inputs or code paths, organize cases as a `map[string]struct{}` table. Each map key becomes a distinct golden file path (`filepath.Join("test-fixtures", name+".golden")`):

```go
func TestPageGenerator_Characterize(t *testing.T) {
	cases := map[string]struct {
		setup func(*PageGenerator)
	}{
		"fresh creation produces empty": {setup: func(g *PageGenerator) {}},
		"with row mapping produces xml": {setup: func(g *PageGenerator) { g.AddRow("1.1", "vectrai") }},
	}

	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			g := NewPageGenerator()
			tc.setup(g)
			actual := []byte(g.Generate())

			golden := filepath.Join("test-fixtures", name+".golden")
			if *update {
				if err := os.WriteFile(golden, actual, 0o644); err != nil {
					t.Fatalf("writing golden file: %s", err)
				}
			}
			expected, err := os.ReadFile(golden)
			if err != nil {
				t.Fatalf("missing golden file %s — run go test -update to create", golden)
			}
			if !bytes.Equal(actual, expected) {
				t.Errorf("%s: output mismatch\ngot:\n%s\nwant:\n%s", name, actual, expected)
			}
		})
	}
}
```

## Step 9: Use the Tests as the Safety Net for the Change or Rewrite

Run `go test ./...` (without `-update`) continuously during the refactor or rewrite. Any behavioral change at the API boundary appears as a byte-comparison failure naming the specific golden file that changed. Decide whether the failure reveals an accidental breakage (fix it) or an intentional change (run `go test -update`, inspect the new diff, commit with an explanation).

**Key guardrail at step 6:** If the golden file content looks like a bug — the code returns an empty document where content was expected — do not delete the golden file to make the test pass. Accept the empty document. Your job right now is to document reality. The decision of whether to fix the bug belongs to a later, explicit step.

**Rewrite variant:** When using this technique to enable a full rewrite rather than an in-place refactor, ensure all tests exercise inputs and assert outputs at the public API boundary. Tests at internal state or private methods will not survive the rewrite. Tests at `result = component.Process(input)` boundaries will.

______________________________________________________________________

## B — Boundaries and Failure Modes

### Source a Failures (Feathers — Characterization Test)

- **Characterization tests as permanent specification substitutes:** Teams treat the characterization test suite as proof of correctness rather than a behavioral snapshot. Known bugs become codified. Passing tests are confused with correct code — the two statements are logically independent when using characterization tests. Mitigation: after completing the refactoring the tests enabled, upgrade key tests from characterization tests to specification tests once you understand what correct behavior should be.
- **Tests written at the wrong level:** Characterization tests that assert on internal state, private variables, or intermediate results break when you refactor — exactly when you need them. Always write at a public interface boundary.
- **Characterization tests for code you are not about to touch:** Feathers is explicit that these tests should target the area you plan to change. Writing them for code with no imminent changes is wasted effort that accumulates a test suite pinning bugs indefinitely without the corresponding benefit of safe refactoring.

### Source B Failures (Hashimoto — Golden Files)

- **Non-deterministic output:** Timestamps, UUIDs, random values, or memory addresses cause spurious byte-comparison failures on every run. Normalize or strip these values before writing to the golden file, or choose a different assertion strategy.
- **Small, stable output:** If the expected output is a single string or number that will never change, inline the expected value. Golden files add file-system overhead and a commit step that is not justified for trivial assertions.
- **Unreadable binary output:** The "eyeball the golden file" step provides no verification value if the output is opaque binary with no human-readable representation. Add a `String()` method first.
- **Failure message quality:** Raw `bytes.Equal` on large files produces an unreadable failure message. Pair with `github.com/google/go-cmp/cmp.Diff` or `github.com/stretchr/testify/assert.Equal` (which produces a unified diff on string comparison).
- **Golden file changed in PR but not reviewed:** A changed `.golden` file is a meaningful output change requiring the same review attention as a changed function. Reviewers who approve golden file diffs without reading them undermine the inspection gate.

### Synthesis-Specific Failure Mode

- **Using -update flag as the comprehension substitute:** The `-update` flag is designed for cases where you already understand the output and are re-pinning after an intentional change. If you run `go test -update` on code you have never read, then commit the golden files without inspecting them, you have pinned the code's output without any comprehension step. You get the mechanical benefits of golden files (byte comparison, readable diffs) but none of the comprehension benefits of characterization tests (understanding what the code actually does). The merged skill requires inspection at step 6 even when the update flag automates generation — the flag does not replace the human review.

### Contradiction to Surface Explicitly

Feathers says characterization tests are scaffolding for code you are about to change and warns against using them for code you are not about to touch. Hashimoto's golden-file pattern has no such constraint — it applies to any complex-output function, including stable production code, as a permanent fixture. These are not reconcilable by synthesis: they represent different views of when pinning is appropriate. Resolution via conditional: if the goal is change safety on unknown code (Feathers context), target the tests at the change boundary and plan to promote or delete them after the change. If the goal is assertion maintainability on stable complex output (Hashimoto context), the tests are permanent fixtures with no lifecycle constraint.

______________________________________________________________________

## Related Skills

- **welc/welc-characterization-test** — superseded-by: this merged skill; the source skill remains useful for non-Go contexts or when golden file storage is not applicable
- **hashimoto/golden-files-update-flag** — superseded-by: this merged skill in characterization/rewrite contexts; the source skill remains useful for stable complex-output testing with no legacy/unknown-behavior concern
- **welc/welc-sensing-vs-separation** — depends-on: the code must be callable from a test before any characterization test can be written; sensing/separation is the prerequisite diagnostic
- **hashimoto/table-driven-named-cases** — composes-with: each map key in a table-driven characterization test maps to a distinct `.golden` filename; naming is what makes failing golden file comparisons immediately identifiable
- **welc/welc-legacy-code-change-algorithm** — composes-with: characterization tests with golden files are the execution of Step 4 of the change algorithm

______________________________________________________________________

## Audit Information

- **Phase 1 verdict:** ADVANCE (all four gates passed)
- **V1 (genuine convergence):** PASS — two independent authors (Feathers 2005, Hashimoto ~2017) from different domains independently discovered the let-code-supply-expected-value mechanism
- **V2 (novel questions answered):** PASS — merged skill handles "characterize legacy service API before rewrite AND keep tests maintainable" which neither source addresses alone
- **V3 (non-obvious synthesis):** PASS — golden files as the optimal storage format for characterization test expected values, and the comprehension vs. maintainability conditional, are not documented in Go circles
- **V4 (sharper A2):** PASS — merged A2 adds the rewrite-with-golden-file-contract scenario that neither source alone handles
- **Merge date:** 2026-05-05
