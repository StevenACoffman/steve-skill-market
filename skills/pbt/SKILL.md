---
name: pbt
description: >
  Write property-based and metamorphic tests using rapid (pgregory.net/rapid) for Go. Triggers on: "property-based tests",
  "PBT", "rapid tests", "test with random inputs",
  "generative tests", "test properties", "randomized testing",
  "metamorphic testing", "metamorphic relations", and situations with no
  test oracle: expected outputs can't be written down, outputs legitimately
  vary between runs, or the code under test is concurrent/nondeterministic.
---

# Rapid: Property-Based Testing for Go

Rapid (`pgregory.net/rapid`) is a Go library for property-based testing. Tests
integrate with `go test` via `rapid.Check`. Rapid generates random inputs for
your code and automatically shrinks failing cases to minimal counterexamples.
It has zero external dependencies.

## Workflow

Follow these steps when writing property-based tests.

### 1. Load the Go Reference

Load `references/go.md` for full API details and idiomatic patterns.

### 2. Explore the Code Under Test

Before writing any test, understand what you're testing:

- **Read the source code** of the function/module under test
- **Read existing tests** to understand expected behavior and edge cases
- **Read godoc comments and type signatures** for documented contracts
- **Read usage sites** to see how callers use the code and what they expect

The goal is to find *evidence* for properties, not to invent them.

### 3. Identify Valuable Properties

Look for properties that are:

- **Grounded in evidence** from the code, docs, or usage patterns
- **Non-trivial** — they test real behavior, not tautologies, and do not duplicate the code being tested
- **Falsifiable** — a buggy implementation could actually violate them

Write one test per property. Don't cram multiple properties into one test.

If you cannot write down the expected output for a concrete input — or
outputs legitimately vary between runs (concurrency, arbitrary tie-breaking,
hidden seeds, floating point) — derive **metamorphic relations** instead of
forcing an oracle: see "Metamorphic Relations" below and load
`references/metamorphic.md`.

### 4. Check for Existing Tests to Evolve or Port

Before writing tests from scratch, **always** check existing tests:

- **Existing PBTs in another framework** (`testing/quick`, etc.) should be
  ported to rapid. Load `references/porting.md` for guidance.
  Don't carry over narrow generator bounds from the old framework — use broader
  generators unless bounds are justified by the function's contract.
- **Unit tests and example-based tests** can often be evolved into PBTs. Load
  `references/evolving-tests.md` for guidance. Tests with hardcoded values,
  table-driven tests, or multiple similar test cases are prime candidates.
- **Tests that use `math/rand` with fixed seeds** are especially good candidates —
  the randomness should come from rapid instead so failures produce shrinkable
  counterexamples.

When you evolve an existing test, **modify the existing test file** rather than
creating a new one. Add rapid tests alongside (or replacing) the existing tests
in the same file where the original tests live. Do not create a separate
`pbt_test.go` or similar — property-based tests are tests like any other and
belong with the code they're testing.

### 5. Write the Tests

For each property:

1. **Add tests to the appropriate existing test file.** If there's already a
   `foo_test.go` covering the module, add rapid tests there. Only create a new
   file if no relevant test file exists.
2. Choose the **simplest possible generators** — start with no bounds, unless
   bounds are logically necessary (e.g. if a number has to be non-zero it's
   fine to force it to be, but slices should not have `maxLen` set unless there
   is a compelling correctness reason to set them or poor performance has been
   observed when actually running the test)
3. Draw values using `generator.Draw(t, "label")`
4. Run the code under test
5. Assert the property using `t.Fatalf`, `t.Errorf`, or standard Go assertions

### 6. Run and Reflect

Run the tests. When a test fails, ask:

- **Is this a real bug?** If the code violates its own contract, flag the bug to the user and ask what to do, or fix the code if instructed to do so.
- **Is the property unsound?** If you asserted something the code never promised, fix the test.
- **Is the generator too broad?** Only if the failing input is genuinely outside the function's domain, add constraints. Investigate before constraining.

## Property Categories

Use this taxonomy to identify what to test. Not every category applies to every
function — pick the ones supported by evidence.

| Category | Description | Example |
|----------|-------------|---------|
| **Round-trip** | encode then decode recovers the original | `Unmarshal(Marshal(x)) == x` |
| **Idempotence** | applying twice equals applying once | `sort(sort(xs)) == sort(xs)` |
| **Commutativity** | order of operations doesn't matter | `a + b == b + a` |
| **Invariant preservation** | an operation maintains a structural property | `insert into BST preserves ordering` |
| **Oracle / reference impl** | compare against a known-correct implementation | `mySort(xs) == slices.Sort(xs)`, or comparing against an unoptimised implementation |
| **Monotonicity** | more input means more (or equal) output | `len(append(xs, ys...)) >= len(xs)` |
| **Bounds / contracts** | output stays within documented limits | `clamp(x, lo, hi)` is in `[lo, hi]` |
| **No-crash / robustness** | function handles all valid inputs without panicking | `parse(arbitraryString)` doesn't panic |
| **Equivalence** | two implementations produce the same result | `iterativeFib(n) == recursiveFib(n)` |
| **Model-based** | operations on real system match a simplified model | `custom map ops match built-in map` |
| **Consistency** | related APIs in the same library agree | `StringWidth(s) == sum of RuneWidth per rune` |
| **Precision preservation** | numeric values survive format conversions | `strconv.Atoi(strconv.Itoa(n)) == n` |
| **Metamorphic** | a relation between the outputs of two related runs replaces the missing oracle | `count(q∧p) + count(q∧¬p) == count(q)`; add one matching record → exactly one more result |

## High-Value Patterns (Field-Tested)

These patterns are ranked by how often they found real bugs when tested across
many popular Go libraries. See `references/field-tested-patterns.md`
for detailed examples.

### 1. Model Tests (Highest Value for Data Structures)

For any data structure, the highest-value first test is a **model test** — run
the same operations on the library under test and a known-good reference (usually
a standard library type), then assert they agree after every operation.

Choose the right oracle:
- `[]T` for sequential containers (fixed-capacity slices, ring buffers)
- `map[K]V` for hash maps (concurrent maps, ordered maps)
- `map[K]struct{}` or sorted slice for sets

### 2. Idempotence Tests (Highest Value for String/Text Processing)

Any normalization, case conversion, or formatting function should be idempotent:
`f(f(x)) == f(x)`. Use `rapid.String()` (not ASCII-only generators) because
Unicode edge cases like `ß` → `SS` and combining characters are where bugs hide.

### 3. Parse Robustness (Universal — Test Every Parser)

Every parsing function should be tested with `rapid.String()`. The property
is simple: it should never panic. Parsers that delegate to constructors which
panic on invalid values (instead of returning errors) are a common source of bugs.

### 4. Roundtrip Tests (High Value for Serialization)

`parse(format(x)) == x` for any serialize/deserialize pair. Test with the full
input domain — don't restrict to "reasonable" values. Bugs hide at boundaries
like zero (e.g. scientific notation missing the coefficient), large integers
(precision loss through float64 intermediaries for values > 2^53), and unusual
string content (double slashes in paths, control characters).

### 5. Boundary Value Tests (High Value for Numeric Code)

Integer operations should be tested with `math.MinInt`, `math.MaxInt`, `0`,
and unconstrained ranges. Negating `math.MinInt` overflows, and many libraries
forget to handle these. Don't add `rapid.IntRange(-100, 100)` — those bounds
hide real bugs.

## Metamorphic Relations (When There Is No Oracle)

Model and oracle tests assume you can predict the output. When you can't —
verifying one output is as hard as computing it, results legitimately vary
between runs (tie-breaking, floats, hidden seeds), or the code is concurrent
and a sequential model can't say which racing outcome is correct — run the
code twice, on an input and on a transformed version of it, and assert a
**relation between the two outputs** instead of predicting either.
Round-trip, idempotence, commutativity, and equivalence properties above are
already metamorphic relations; this generalizes them.

Choose in this order: (1) expected output computable → plain assertion;
(2) a short reference you trust → model test (Pattern 1); (3) an independent
implementation you don't trust → equivalence test; (4) none of these →
metamorphic relations, derived from two questions: **what must NOT change
the output** (shuffle order-free input, rename keys, add records that match
nothing, change a documented-invisible config knob) and **what changes it
predictably** (strengthen a filter → subset; partition → the parts recompose;
add one matching record → exactly one more result). Write 3–6 relations from
different families — a few diverse relations approximate a real oracle.

Non-negotiables: every relation carries a one-line `// spec:` comment
deriving it from the documented contract (docs and domain math, never the
implementation); canonicalize before comparing (sort unordered results, strip
undetermined fields); assert nothing the contract doesn't promise — result
order, bit-equal floats, mid-flight counts. For concurrent code, assert
exact relations only at quiescence.

Load `references/metamorphic.md` for the transformation catalog, float
tolerance rules, the concurrent playbook (determinate workloads, conserved
aggregates, invariance grids, unique-value tagging, checkpoint immutability),
failure triage, unsound-relation traps, and validating the suite with
mutants. Load `references/metamorphic-templates.md` for validated rapid
templates of each pattern, ready to adapt.

## Choosing Properties

Properties must be **evidence-based**. Find evidence in:

- **Names and Type signatures**: A function `func Merge(a, b []T) []T` implies the output length might equal the sum of input lengths.
- **Godoc comments**: "Returns a sorted slice" directly gives you an invariant.
- **Panics and assertions in the source**: These are properties the author already identified, and do not need to be duplicated in the tests, but may suggest other invariants.
- **Usage patterns**: If callers always assume a result is non-empty, assert that the result is always non-empty.
- **Existing tests**: Unit tests often encode specific instances of general properties.

Err on the side of creating more properties rather than fewer, and if they fail investigate whether the failure is legitimate behaviour or not.

**Beware of properties that seem universal but aren't.** Read the docs carefully
before asserting a property. Examples from real testing:
- Grapheme-based string reverse is NOT an involution (`reverse(reverse("\n\r"))
  ≠ "\n\r"` because `\r\n` is one grapheme cluster while `\n\r` is two).
- A method called `Difference` might mean symmetric difference (A △ B), not set
  difference (A \ B) — check the docs.
- A function documented as "returns the largest key ≤ k" means ≤, not <.

When a property fails, investigate whether it's a real bug or a genuine edge case
in the domain. A weaker property often still holds.

## Generator Discipline

A common mistake agents make when writing property-based tests is **over-constraining generators**.
This leads to tests that are weaker than they need to be.

### Start With No Bounds

If the function accepts any `int`, use:

```go
rapid.Int()  // no min, no max
```

Do NOT preemptively write:

```go
rapid.IntRange(0, 100)  // WRONG unless justified
```

### Edge Cases Are the Point

Don't narrow ranges to "avoid edge cases." Edge cases are exactly what PBT is for. If a function claims to work on all `int` values, test it on all `int` values — including `math.MinInt`, `math.MaxInt`, `0`, `-1`, and `1`.

### Don't Set `minLen` to 1 by Default

Unless the function's contract explicitly requires non-empty input, test with empty collections too. If a function panics on an empty slice, that might be a bug worth knowing about.

### When a Test Fails on Extreme Values

Your first reaction should be: **is this a real bug?**

You should assume that it is unless you have strong evidence that it is not. If in doubt, ask the user.

- If the function's documentation says it handles all integers but it overflows on `math.MaxInt`, that's a bug in the code, not in your test.
- Only add bounds after investigating and confirming the input is outside the function's documented domain.

### When to Add Constraints

Add generator bounds **only** when:

1. **The function's contract explicitly excludes some inputs.** For example, `func Sqrt(x float64)` documents that `x >= 0` is required.
2. **You need to avoid undefined behavior.** For example, division by zero.
3. **A test failure has been investigated** and confirmed to be outside the function's domain.
4. **You are concentrating the input space to force a structural interaction** — hot keys so concurrent operations actually contend, a narrow score range to force ties, a small key pool so deletes hit written keys. State the reason in a comment next to the bound; `references/metamorphic-templates.md` shows the pattern.

### Avoid Rejection Sampling Where Possible

When a constraint involves relationships between multiple generated values, you may use `t.Skip`:

```go
a := rapid.Int().Draw(t, "a")
b := rapid.Int().Draw(t, "b")
if a == b {
    t.Skip("need distinct values")
}
```

This example is perfectly fine, but it is better to avoid `Skip` altogether when you can:

e.g.

```go
a := rapid.Int().Draw(t, "a")
b := rapid.IntMin(a).Draw(t, "b")
```

is better than

```go
a := rapid.Int().Draw(t, "a")
b := rapid.Int().Draw(t, "b")
if a > b {
    t.Skip("need a <= b")
}
```

Even better is:

```go
a := rapid.Int().Draw(t, "a")
b := rapid.Int().Draw(t, "b")
if a > b {
    a, b = b, a
}
```

It is particularly important to avoid rejection sampling in cases where the rejection rate is likely to be high.

For example `rapid.Map(rapid.Int(), func(n int) int { return n * 2 })` is much
better than `rapid.Int().Filter(func(n int) bool { return n%2 == 0 })`, as the
former constructs an even number directly, while the latter throws away around
50% of test cases.

### Getting Large Collections

Rapid's default collection size is small. If you need large collections (e.g.,
to exercise deep tree paths), draw the size separately and use `SliceOfN`:

```go
// GOOD — can generate large collections, shrinks well
n := rapid.IntRange(0, 300).Draw(t, "n")
keys := rapid.SliceOfN(rapid.Int(), n, -1).Draw(t, "keys")

// BAD — rapid's default size distribution rarely produces 100+ elements
keys := rapid.SliceOf(rapid.Int()).Draw(t, "keys")
```

Setting `minLen` but *not* `maxLen` (using -1) is a shrinking optimization:
rapid can shrink `n` to find the minimal collection size that triggers the bug,
while still being able to add extra elements if needed.

### Use `SliceOfDistinct` for Key Generation

When testing maps/sets that need unique keys:

```go
keys := rapid.SliceOfNDistinct(rapid.Int(), -1, 30, rapid.ID[int]).Draw(t, "keys")
```

This avoids confusion about which value wins for duplicate keys.

## Handling Randomness in Code Under Test

When the code under test requires an RNG (e.g., `func Sample(weights []float64, rng *rand.Rand)`),
**do not** create a seeded RNG like `rand.New(rand.NewSource(seed))` with a
rapid-generated seed. This defeats shrinking — rapid can only shrink the seed
integer, not the actual random decisions the RNG makes.

Instead, generate the random decisions you need directly through rapid generators.
For example, if the code needs a random index, draw it with `rapid.IntRange(0, n-1)`.

If the code's RNG is deeply embedded and cannot be easily replaced, generating
a seed is acceptable as a last resort, but understand that shrinking quality
will be reduced.

## Common Mistakes

1. **Over-constraining generators** — Adding bounds "just in case." This hides bugs and makes tests less valuable. See Generator Discipline above.
2. **Testing trivial properties** — `assert(x == x)` or `assert(len(s) >= 0)` test nothing. Every property should be falsifiable by a buggy implementation.
3. **Using the implementation as the oracle** — If your test calls the same function to compute the expected result, it can never fail. Use an independent reference implementation (do not just copy the code to write this!), a simpler algorithm, or a structural property.
4. **Generating too broadly then filtering almost everything** — If `.Filter()` or `t.Skip()` rejects most inputs, rapid will give up. Restructure your generators instead (e.g., use `rapid.Map` or dependent generation).
5. **Creating a separate test file for rapid tests** — Property-based tests belong alongside the existing tests for the same code. Don't put them in `pbt_test.go` or `properties_test.go` — add them to the existing test files.
6. **Using manually seeded RNGs** — Don't generate a seed with rapid then create `rand.New(rand.NewSource(seed))`. Generate the random decisions you need through rapid generators so rapid can shrink them. See "Handling Randomness" above.
7. **Overflowing in test code** — When computing values from generated data (e.g., `m[k] = k * 10`), your test code itself can overflow before the library has a chance to be buggy. Use smaller intermediate types (draw `int16`, cast to `int` for multiplication) to prevent this. Distinguish "this constraint protects the library's contract" (keep it) from "this constraint prevents my test from overflowing" (use a smaller type instead).
8. **Adding `maxLen` for performance** — If a test is slow with large collections, lower the check count with `-rapid.checks` rather than restricting the input space. A slow test that finds bugs beats a fast test that can't. Many tree/trie bugs only manifest at 50-200+ elements.
9. **Asserting more than the contract promises in cross-run relations** — result order where ordering is documented arbitrary, bit-equal floats across reordered arithmetic, exact sizes while writers are active. Canonicalize and compare only the promised projection. See `references/metamorphic.md`.

## Quick Setup

```go
// go.mod
require pgregory.net/rapid latest
```

Run with `go test`. Rapid integrates with `go test` via `rapid.Check(t, prop)`.
