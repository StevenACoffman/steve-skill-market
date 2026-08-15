# Evolving Example-Based Tests into Property-Based Tests

Existing unit tests are often the best starting point for property-based tests.
They encode domain knowledge about what the code should do, and they frequently
contain implicit properties that can be generalized.

## Good Candidates for Evolution

Look for tests that:

- **Have multiple similar test cases (table-driven tests).** Three test cases for
  `parse("1")`, `parse("42")`, `parse("-7")` suggest a round-trip property:
  parse then format recovers the original.
- **Use simple input types.** Tests with integer, string, or collection inputs
  are easy to parameterize with generators.
- **Test round-trip behavior.** `assert(decode(encode(x)) == x)` is already
  a property — just replace `x` with a generator.
- **Contain existing randomness or hardcoded seeds.** Tests that create RNGs
  with fixed seeds (`rand.New(rand.NewSource(42))`) or use `math/rand` are
  excellent candidates. Replace the manual RNG with rapid generators so
  rapid controls the randomness and can shrink failures.
- **Test invariants across examples.** If every test case checks the same
  condition (e.g., output is sorted, length is preserved), that's a property.
- **Parameterized tests over hardcoded inputs.** Tests that loop over a list of
  specific sizes, distributions, or configurations should generate those
  parameters instead.

## Poor Candidates

- **Exact-output tests.** `assert(render(doc) == "<html>...")` depends on a
  specific output format that's hard to express as a property.
- **Complex setup with fixtures.** Tests that require database state, network
  mocks, or elaborate setup are harder to parameterize (though not impossible).
- **UI / snapshot tests.** Visual regression tests don't have obvious
  properties.
- **Tests of specific error messages.** Checking exact error strings is a
  unit test concern; PBTs work better for testing that errors are *raised*
  rather than what they *say*.

## The Evolution Process

### Step 1: Identify the Property

Read the existing tests and ask: **what is true across all these examples?**

```go
// Before: table-driven unit test
func TestAbs(t *testing.T) {
    tests := []struct{ in, want int }{
        {5, 5},
        {-3, 3},
        {0, 0},
    }
    for _, tt := range tests {
        if got := myAbs(tt.in); got != tt.want {
            t.Errorf("myAbs(%d) = %d, want %d", tt.in, got, tt.want)
        }
    }
}
```

The property: `myAbs(x) >= 0` for all `x`, and `myAbs(x) == myAbs(-x)`.

### Step 2: Parameterize

Replace concrete values with generated ones:

```go
func TestAbsNonNegative(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        x := rapid.Int64().Draw(t, "x")
        if myAbs(x) < 0 {
            t.Fatalf("myAbs(%d) is negative", x)
        }
    })
}

func TestAbsSymmetric(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        x := rapid.Int64().Draw(t, "x")
        if myAbs(x) != myAbs(-x) {
            t.Fatalf("myAbs(%d) != myAbs(%d)", x, -x)
        }
    })
}
```

### Step 3: Choose Generators

Start with the **broadest generator that matches the function's input type**.
Do not restrict the range to match the original test's examples. The whole
point is to explore inputs the original author didn't think of.

### Step 4: Adjust the Oracle

Unit tests often compare against a hardcoded expected value. PBTs need an
oracle that works for any input:

- **Use a reference implementation:** `slices.Equal(mySort(v), slices.Sorted(slices.Values(v)))`
- **Use a structural property:** `slices.IsSorted(mySort(v))`
- **Use a relationship:** `myAbs(x) == myAbs(-x)`

If you can't find a general oracle, the test may not be a good PBT candidate.

### Step 5: Handle Edge Cases

When the PBT finds failures on inputs the unit tests didn't cover, decide:

- **Is this a real bug?** Fix the code. This is PBT doing its job.
- **Is this outside the function's domain?** Add a constraint — but document
  why, and check whether the function's documentation should be updated.

## Example Transformations

### Parsing round-trip

Before:

```go
func TestParseInt(t *testing.T) {
    tests := []struct{ s string; want int }{
        {"123", 123},
        {"-1", -1},
        {"0", 0},
    }
    for _, tt := range tests {
        got, err := strconv.Atoi(tt.s)
        if err != nil || got != tt.want {
            t.Errorf("Atoi(%q) = %d, %v", tt.s, got, err)
        }
    }
}
```

After:

```go
func TestIntDisplayParseRoundTrip(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        n := rapid.Int().Draw(t, "n")
        s := strconv.Itoa(n)
        got, err := strconv.Atoi(s)
        if err != nil {
            t.Fatalf("Atoi(%q) error: %v", s, err)
        }
        if got != n {
            t.Fatalf("Atoi(Itoa(%d)) = %d", n, got)
        }
    })
}
```

### Collection operations

Before:

```go
func TestPushPop(t *testing.T) {
    s := NewStack()
    s.Push(1)
    s.Push(2)
    if got := s.Pop(); got != 2 {
        t.Errorf("Pop() = %d, want 2", got)
    }
    if got := s.Pop(); got != 1 {
        t.Errorf("Pop() = %d, want 1", got)
    }
    if got, ok := s.TryPop(); ok {
        t.Errorf("TryPop() = %d, want empty", got)
    }
}
```

After:

```go
func TestPushThenPopReturnsLast(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        items := rapid.SliceOf(rapid.Int()).Draw(t, "items")
        s := NewStack()
        for _, item := range items {
            s.Push(item)
        }
        // Property: popping returns items in reverse order
        for i := len(items) - 1; i >= 0; i-- {
            got := s.Pop()
            if got != items[i] {
                t.Fatalf("Pop() = %d, want %d", got, items[i])
            }
        }
    })
}
```

### Encoding/decoding

Before:

```go
func TestBase64Encode(t *testing.T) {
    tests := []struct{ in []byte; want string }{
        {[]byte("hello"), "aGVsbG8="},
        {[]byte(""), ""},
        {[]byte("a"), "YQ=="},
    }
    for _, tt := range tests {
        if got := base64Encode(tt.in); got != tt.want {
            t.Errorf("base64Encode(%q) = %q, want %q", tt.in, got, tt.want)
        }
    }
}
```

After:

```go
func TestBase64RoundTrip(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        data := rapid.SliceOf(rapid.Byte()).Draw(t, "data")
        encoded := base64Encode(data)
        decoded, err := base64Decode(encoded)
        if err != nil {
            t.Fatalf("decode error: %v", err)
        }
        if !bytes.Equal(decoded, data) {
            t.Fatal("round-trip failed")
        }
    })
}

func TestBase64OutputIsValid(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        data := rapid.SliceOf(rapid.Byte()).Draw(t, "data")
        encoded := base64Encode(data)
        for _, c := range encoded {
            valid := (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
                     (c >= '0' && c <= '9') || c == '+' || c == '/' || c == '='
            if !valid {
                t.Fatalf("invalid base64 character: %c", c)
            }
        }
    })
}
```

### Sorting

Before:

```go
func TestSort(t *testing.T) {
    tests := []struct{ in, want []int }{
        {[]int{3, 1, 2}, []int{1, 2, 3}},
        {[]int{1}, []int{1}},
        {nil, nil},
    }
    for _, tt := range tests {
        got := mySort(tt.in)
        if !slices.Equal(got, tt.want) {
            t.Errorf("mySort(%v) = %v, want %v", tt.in, got, tt.want)
        }
    }
}
```

After:

```go
func TestSortIsSorted(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
        sorted := mySort(xs)
        if !slices.IsSorted(sorted) {
            t.Fatalf("result is not sorted: %v", sorted)
        }
    })
}

func TestSortIsPermutation(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
        sorted := mySort(xs)
        expected := slices.Clone(xs)
        slices.Sort(expected)
        if !slices.Equal(sorted, expected) {
            t.Fatalf("got %v, want %v", sorted, expected)
        }
    })
}
```

## Where to Put Evolved Tests

**Modify the existing test file.** If the unit tests live in `foo_test.go`,
add or replace with rapid tests in `foo_test.go`. Do not create a separate
`pbt_test.go` — property-based tests are regular tests and belong with the
code they cover.

## Research Insights

Studies of evolving unit tests into property-based tests have found:

- **Most PBTs use simple generators.** Around 65% of property-based tests in
  practice use only basic generators (integers, strings, slices) without complex
  composition. Don't over-engineer generators.

- **PBTs find bugs that unit tests miss.** Even when unit tests pass, PBTs
  can discover failures — particularly around boundary conditions, empty inputs,
  and large values. In one study, PBTs found bugs in ~2% of cases where the
  corresponding unit tests all passed.

- **Table-driven tests are a stepping stone.** If you can't immediately see
  the right property, start by parameterizing the test (replacing concrete
  values with generated ones and keeping a simple oracle). You can refine the
  property later.

- **The biggest gain is coverage of edge cases.** PBTs typically add modest
  line coverage over unit tests, but their value is in exercising combinations
  and boundary conditions that humans don't think to write by hand.
