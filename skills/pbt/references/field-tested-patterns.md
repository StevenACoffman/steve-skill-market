# Field-Tested Property Patterns

These patterns are drawn from extensive property-based testing of popular Go
libraries with rapid. They are ordered by effectiveness — patterns that
found more bugs are listed first.

## Pattern 1: Model Tests for Data Structures

Compare every operation on the data structure under test against a known-good
standard library reference. Assert agreement after **every** operation, not just
at the end.

```go
func TestMyMapModel(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        subject := NewMyMap[int, int]()
        model := make(map[int]int)

        t.Repeat(map[string]func(*rapid.T){
            "insert": func(t *rapid.T) {
                k := rapid.Int().Draw(t, "k")
                v := rapid.Int().Draw(t, "v")
                gotOld, gotOK := subject.Insert(k, v)
                wantOld, wantOK := model[k]
                model[k] = v
                if gotOK != wantOK || (gotOK && gotOld != wantOld) {
                    t.Fatalf("insert(%d, %d): got (%d, %v), want (%d, %v)",
                        k, v, gotOld, gotOK, wantOld, wantOK)
                }
            },
            "delete": func(t *rapid.T) {
                k := rapid.Int().Draw(t, "k")
                subject.Delete(k)
                delete(model, k)
            },
            "get": func(t *rapid.T) {
                k := rapid.Int().Draw(t, "k")
                got, ok1 := subject.Get(k)
                want, ok2 := model[k]
                if ok1 != ok2 || got != want {
                    t.Fatalf("get(%d): got (%d, %v), want (%d, %v)",
                        k, got, ok1, want, ok2)
                }
            },
            "": func(t *rapid.T) {
                if subject.Len() != len(model) {
                    t.Fatalf("len mismatch: %d vs %d", subject.Len(), len(model))
                }
            },
        })
    })
}
```

**Key points:**
- Assert **return values** of mutating operations (insert, delete), not just
  final state. A common bug pattern is `Insert` returning the wrong boolean
  (e.g. claiming a value was already present when it wasn't).
- Include `Len()` checks after every operation to catch subtle state corruption
  like stale index entries that aren't cleaned up on update.
- Use unconstrained key generators — some bugs only manifest with many unique
  keys (e.g. 50-200+) because they require deep tree structures with multiple
  node levels.

**Oracle selection:**

| Data structure type | Oracle |
|---|---|
| Sequential containers (fixed-capacity slices, ring buffers) | `[]T` |
| Deque-like containers (ring buffers, persistent vectors) | `[]T` with index math |
| Hash maps (alternative hash maps, concurrent maps) | `map[K]V` |
| Ordered maps (tree maps, skip lists) | `map[K]V` + sorted keys |
| Sets / bitmaps (compressed bitmaps, tree sets) | `map[K]struct{}` |

## Pattern 2: Idempotence Tests for String Processing

Any normalization, case conversion, or formatting function should be idempotent.
The critical ingredient is `rapid.String()` — ASCII-only inputs miss the bugs.

```go
func TestNormalizeIdempotent(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        s := rapid.String().Draw(t, "s")
        once := normalize(s)
        twice := normalize(once)
        if once != twice {
            t.Fatalf("not idempotent for %q: %q -> %q", s, once, twice)
        }
    })
}
```

**Why Unicode matters:** Some Unicode characters change length when case-mapped.
For example, the German sharp-s (`ß`) uppercases to `SS` (two characters). A
case conversion function that splits words on case transitions will see different
word boundaries on the first and second pass, breaking idempotence. This is
completely invisible with ASCII-only generators.

**Apply to:** case conversion (`strings.ToUpper`/`strings.ToLower` wrappers),
URL normalization, path canonicalization, HTML escaping, string slugification,
Unicode normalization, any function that transforms text into a "canonical" form.

## Pattern 3: Parse Robustness

Every parsing function should handle all input without panicking — even invalid
input. The property is simple:

```go
func TestParseRobustness(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        s := rapid.String().Draw(t, "s")
        _ = MyParse(s) // Should never panic
    })
}
```

**Why this finds bugs:** Parsers often delegate to internal constructors that
panic on invalid values. For example, a fraction parser might successfully parse
a numerator and denominator from the string, then call `NewRatio(0, 0)` which
panics with "denominator == 0" instead of returning an error. The parser
validated the syntax but not the semantics.

**Apply to:** any `encoding.TextUnmarshaler`, any custom `Parse` function,
XML/JSON/YAML/TOML parsers, URL parsers, date/time parsers.

## Pattern 4: Roundtrip Tests

Test `parse(format(x)) == x` for any serialize/deserialize pair.

```go
func TestDisplayParseRoundtrip(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        v := rapid.Int64().Draw(t, "v")
        s := strconv.FormatInt(v, 10)
        got, err := strconv.ParseInt(s, 10, 64)
        if err != nil {
            t.Fatalf("ParseInt(%q): %v", s, err)
        }
        if got != v {
            t.Fatalf("round-trip failed: %d -> %q -> %d", v, s, got)
        }
    })
}
```

**Where roundtrips break:**
- **Zero as a special case:** Formatters that produce scientific notation may
  emit `"e0"` instead of `"0e0"` for zero — missing the coefficient entirely.
  The parser then rightfully rejects the output.
- **Large integers through float64:** Some parsers route all numeric types
  through float64 internally, silently losing precision for integers > 2^53.
  The value `9007199254740993` gets roundtripped as `9007199254740992`.
- **Unusual path components:** URL and path operations may break roundtrips on
  edge cases like double slashes, empty segments, or relative path resolution.

## Pattern 5: Boundary Value Tests for Numeric Code

Integer boundary values (`math.MinInt`, `math.MaxInt`, `0`) are where overflow
bugs hide. Don't add bounds to avoid them — they ARE the test.

```go
func TestNumericOperation(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        a := rapid.Int64().Draw(t, "a")
        b := rapid.Int64().Draw(t, "b")
        if b == 0 {
            t.Skip("division by zero")
        }
        // Operations that internally negate, multiply, or compute GCD/LCM
        // often overflow on boundary values
        _ = myNumericOp(a, b)
    })
}
```

**Common overflow patterns:**
- **Negating `MinInt`:** `-math.MinInt64` overflows because `|math.MinInt64| > math.MaxInt64`.
  Any code path that negates an integer (conjugate, absolute value, GCD) is
  vulnerable.
- **Intermediate products:** Computing `a * b + c` where the multiplication
  overflows even though the final result would fit.
- **GCD/LCM computations:** These often internally negate values or multiply
  denominators, triggering overflow on boundary inputs.
- **Display/formatting:** Implementations that check `if value < 0` then negate
  to format the absolute value will panic on `MinInt`.

## Pattern 6: API Consistency Tests

When a library provides multiple ways to compute the same thing, they should
agree:

```go
func TestBatchVsIndividual(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        s := rapid.String().Draw(t, "s")
        batchResult := computeForString(s)
        var individualSum int
        for _, r := range s {
            individualSum += computeForRune(r)
        }
        if batchResult != individualSum {
            t.Fatalf("batch(%q) = %d, sum of individual = %d",
                s, batchResult, individualSum)
        }
    })
}
```

**Apply to:** any library where a "batch" API and "single-item" API should agree
(e.g. string width vs sum of rune widths), parallel vs sequential
implementations, different algorithm modes (e.g. NFA vs DFA in a regex engine),
or different encoding paths that should produce identical output.

## Pattern 7: Large Input Sizes

Small inputs (< 20 elements) often fit in a single tree/trie node. Traversal
bugs between nodes are never exercised. Draw the size separately to force large
inputs:

```go
func TestWithLargeInput(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        n := rapid.IntRange(0, 300).Draw(t, "n")
        keys := rapid.SliceOfN(rapid.Int(), n, n).Draw(t, "keys")
        // ... test with large data structure
    })
}
```

Tree/trie data structures are especially vulnerable — bugs in B-tree node
splitting, rebalancing, or cross-node traversal only manifest when the tree
has enough keys to require multiple levels of internal nodes.

## Pattern 8: Build Tag / Configuration Testing

Non-default build configurations are often less tested. Check for build tags
and test with different configurations:

```bash
go test -tags=custom_allocator
go test -race  # always run with race detector
```

Experimental or opt-in features are prime targets. Sometimes the README or
documentation will even say "this feature has not been tested" — take that as
a direct invitation.

## Bug Patterns by Category

| Category | What to look for |
|---|---|
| **Integer overflow** | Boundary values (MinInt, MaxInt, 0) in arithmetic, GCD, negation, display |
| **Idempotence failure** | Case conversion / normalization with Unicode (ß → SS), word splitting on case transitions |
| **Precision loss** | Numbers routed through float64 lose precision for integers > 2^53 |
| **Roundtrip failure** | Format/parse on edge cases: zero, empty strings, unusual path components |
| **Parse panic** | Parser delegates to a constructor that panics instead of returning error |
| **Stale state** | Update operations that modify one index but don't clean up the old entry in another |
| **Unicode line breaks** | `\u0085` (NEL), `\u2028` (LS), `\u2029` (PS) treated inconsistently as line breaks |
| **Race conditions** | Concurrent access bugs (always use `-race` flag with rapid tests) |
| **Deep structure bugs** | Traversal that only fails when data structure has multiple internal levels (50-200+ elements) |
