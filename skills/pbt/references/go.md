# Rapid Go SDK Reference

## Setup

Add to `go.mod`:

```go
require pgregory.net/rapid latest
```

No external dependencies. Run tests with `go test`. Rapid tests use
`rapid.Check(t, prop)` and integrate directly with the standard Go test runner.

## Test Structure

### `rapid.Check` (primary entry point)

```go
import (
    "testing"

    "pgregory.net/rapid"
)

func TestAdditionCommutes(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        a := rapid.Int64().Draw(t, "a")
        b := rapid.Int64().Draw(t, "b")
        if a+b != b+a {
            t.Fatalf("addition is not commutative: %d + %d", a, b)
        }
    })
}
```

The property is falsified by a call to `t.Fatal`, `t.Fatalf`, `t.Error`,
`t.Errorf`, `t.Fail`, `t.FailNow`, or by a panic.

### `rapid.MakeCheck` (for subtests)

```go
func TestFoo(t *testing.T) {
    t.Run("subtest name", rapid.MakeCheck(func(t *rapid.T) {
        // test code
    }))
}
```

### `rapid.MakeFuzz` (Go fuzz integration)

```go
func FuzzFoo(f *testing.F) {
    f.Fuzz(rapid.MakeFuzz(func(t *rapid.T) {
        // test code
    }))
}
```

### Configuration

Rapid is configured via command-line flags or environment variables:

| Flag | Env Var | Default | Purpose |
|------|---------|---------|---------|
| `-rapid.checks` | `RAPID_CHECKS` | 100 | Number of test iterations |
| `-rapid.steps` | `RAPID_STEPS` | 30 | Average state machine actions |
| `-rapid.seed` | `RAPID_SEED` | 0 (random) | PRNG seed for reproducibility |
| `-rapid.shrinktime` | `RAPID_SHRINKTIME` | 30s | Shrinking time budget |
| `-rapid.failfile` | `RAPID_FAILFILE` | | Persistence file path |
| `-rapid.nofailfile` | `RAPID_NOFAILFILE` | false | Disable fail file writing |
| `-rapid.v` | `RAPID_V` | false | Verbose output |
| `-rapid.debug` | `RAPID_DEBUG` | false | Debug output |
| `-rapid.log` | `RAPID_LOG` | false | Eager verbose output to stdout |

Example: `go test -rapid.checks=500 -rapid.seed=42`

## T Methods

`*rapid.T` embeds `testing.TB`. All standard testing methods are available.

| Method | Purpose |
|--------|---------|
| `t.Fatalf(...)` | Fail the test (primary way to falsify a property) |
| `t.Errorf(...)` | Record an error (test continues, but marked failed) |
| `t.Skip(...)` | Skip this test case (equivalent to `assume`/discard) |
| `t.Logf(...)` | Log debug info (shown on failure) |
| `t.Repeat(actions)` | Run a state machine test |
| `t.Cleanup(fn)` | Register cleanup function |
| `t.Context()` | Get a context.Context (Go 1.24+) |

### Skip as Assume

`t.Skip()` is rapid's equivalent of `assume()` in other PBT frameworks.
When a test case calls `t.Skip()`, rapid discards that test case and tries
another one. Use it for preconditions:

```go
rapid.Check(t, func(t *rapid.T) {
    b := rapid.Int().Draw(t, "b")
    if b == 0 {
        t.Skip("division by zero")
    }
    // ... use b as divisor
})
```

## Generator Reference

All generators are top-level functions in the `rapid` package. Values are
produced by calling `.Draw(t, "label")` on a generator.

### Integer Generators

**Unbounded:**

```go
rapid.Bool()      // *Generator[bool]
rapid.Byte()      // *Generator[byte]
rapid.Int()       // *Generator[int]
rapid.Int8()      // *Generator[int8]
rapid.Int16()     // *Generator[int16]
rapid.Int32()     // *Generator[int32]
rapid.Int64()     // *Generator[int64]
rapid.Uint()      // *Generator[uint]
rapid.Uint8()     // *Generator[uint8]
rapid.Uint16()    // *Generator[uint16]
rapid.Uint32()    // *Generator[uint32]
rapid.Uint64()    // *Generator[uint64]
rapid.Uintptr()   // *Generator[uintptr]
```

**With bounds:**

Each integer type has `Min`, `Max`, and `Range` variants:

```go
rapid.IntMin(10)        // int >= 10
rapid.IntMax(100)       // int <= 100
rapid.IntRange(1, 100)  // 1 <= int <= 100

rapid.Int32Range(-50, 50)
rapid.Uint64Min(1)
rapid.ByteRange(0x20, 0x7E)  // printable ASCII
```

### Float Generators

```go
rapid.Float32()                    // any float32 (no NaN)
rapid.Float32Min(0.0)              // float32 >= 0.0
rapid.Float32Max(1.0)              // float32 <= 1.0
rapid.Float32Range(0.0, 1.0)       // 0.0 <= float32 <= 1.0

rapid.Float64()                    // any float64 (no NaN)
rapid.Float64Min(0.0)              // float64 >= 0.0
rapid.Float64Max(1.0)              // float64 <= 1.0
rapid.Float64Range(-1.0, 1.0)      // -1.0 <= float64 <= 1.0
```

Min and max can be infinite (`math.Inf(1)`, `math.Inf(-1)`).

### String and Rune Generators

**`rapid.String()`** — Generate UTF-8 strings from a diverse set of runes
including Unicode edge cases.

```go
s := rapid.String().Draw(t, "s")
```

**`rapid.StringN(minRunes, maxRunes, maxLen)`** — Bounded strings:

```go
s := rapid.StringN(1, 100, -1).Draw(t, "s")  // 1-100 runes, no byte limit
```

Use -1 for any parameter to leave it unbounded.

**`rapid.StringOf(elem)`** — Strings from a custom rune generator:

```go
s := rapid.StringOf(rapid.RuneFrom(nil, unicode.ASCII_Hex_Digit)).Draw(t, "hex")
```

**`rapid.StringOfN(elem, minRunes, maxRunes, maxLen)`** — Bounded custom strings.

**`rapid.StringMatching(regexp)`** — Strings matching a Perl-syntax regular expression:

```go
code := rapid.StringMatching(`[A-Z]{3}-[0-9]{3}`).Draw(t, "code")
```

**`rapid.SliceOfBytesMatching(regexp)`** — Byte slices matching a regexp.

**`rapid.Rune()`** — Diverse Unicode runes (includes edge cases like BOM,
replacement char, RTL override, and runes that change byte length on case
conversion).

**`rapid.RuneFrom(runes, tables...)`** — Runes from specific characters or
Unicode range tables:

```go
digit := rapid.RuneFrom(nil, unicode.Digit).Draw(t, "digit")
vowel := rapid.RuneFrom([]rune{'a', 'e', 'i', 'o', 'u'}).Draw(t, "vowel")
```

### Collection Generators

**`rapid.SliceOf[E](elem)`** — Generate slices:

```go
xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
```

**`rapid.SliceOfN[E](elem, minLen, maxLen)`** — Bounded slices (use -1 for
unbounded):

```go
xs := rapid.SliceOfN(rapid.Int(), 1, 10).Draw(t, "xs")     // 1-10 elements
xs := rapid.SliceOfN(rapid.Int(), 5, -1).Draw(t, "xs")      // at least 5
```

**`rapid.SliceOfDistinct[E, K](elem, keyFn)`** — Slices of distinct elements:

```go
xs := rapid.SliceOfDistinct(rapid.Int(), rapid.ID[int]).Draw(t, "xs")
```

`rapid.ID[V]` is a helper identity function for use as `keyFn` with comparable
types.

**`rapid.SliceOfNDistinct[E, K](elem, minLen, maxLen, keyFn)`** — Bounded
distinct slices.

**`rapid.MapOf[K, V](key, val)`** — Generate maps:

```go
m := rapid.MapOf(rapid.String(), rapid.Int()).Draw(t, "m")
```

**`rapid.MapOfN[K, V](key, val, minLen, maxLen)`** — Bounded maps.

**`rapid.MapOfValues[K, V](val, keyFn)`** — Maps where keys are derived from values.

**`rapid.MapOfNValues[K, V](val, minLen, maxLen, keyFn)`** — Bounded derived-key maps.

**`rapid.Permutation[S](slice)`** — Random permutations of a slice:

```go
perm := rapid.Permutation([]int{1, 2, 3, 4, 5}).Draw(t, "perm")
```

### Combinators

**`rapid.Custom[V](fn func(*T) V)`** — Primary way to create user-defined
generators. Build composite values by drawing from other generators:

```go
pointGen := rapid.Custom(func(t *rapid.T) Point {
    return Point{
        X: rapid.Float64Range(-100, 100).Draw(t, "x"),
        Y: rapid.Float64Range(-100, 100).Draw(t, "y"),
    }
})
p := pointGen.Draw(t, "point")
```

**`rapid.Map[U, V](g, fn)`** — Transform generator output:

```go
evenGen := rapid.Map(rapid.Int(), func(n int) int { return n * 2 })
```

**`rapid.Just[V](val)`** — Always returns the same value:

```go
g := rapid.Just(42)
```

**`rapid.SampledFrom[S](slice)`** — Sample from a fixed set:

```go
suit := rapid.SampledFrom([]string{"hearts", "diamonds", "clubs", "spades"}).Draw(t, "suit")
```

**`rapid.OneOf[V](gens...)`** — Choose from multiple generators:

```go
n := rapid.OneOf(
    rapid.Just(0),
    rapid.IntRange(1, 100),
    rapid.IntRange(-100, -1),
).Draw(t, "n")
```

All generators passed to `OneOf` must produce the same type.

**`rapid.Ptr[E](elem, allowNil)`** — Pointer generator:

```go
p := rapid.Ptr(rapid.Int(), true).Draw(t, "p")   // *int, may be nil
p := rapid.Ptr(rapid.Int(), false).Draw(t, "p")  // *int, never nil
```

**`rapid.Deferred[V](fn)`** — Lazy evaluation for recursive generators:

```go
type Tree struct {
    Value    int
    Children []*Tree
}

var treeGen *rapid.Generator[*Tree]
treeGen = rapid.Custom(func(t *rapid.T) *Tree {
    return &Tree{
        Value:    rapid.Int().Draw(t, "val"),
        Children: rapid.SliceOfN(rapid.Deferred(func() *rapid.Generator[*Tree] {
            return treeGen
        }), 0, 3).Draw(t, "children"),
    }
})
```

### Generator Methods

**`.Draw(t *T, label string) V`** — Produce a value. The label appears in
counterexample output.

**`.Filter(fn func(V) bool) *Generator[V]`** — Keep only values matching a
predicate:

```go
odd := rapid.Int().Filter(func(n int) bool { return n%2 != 0 })
```

Filter retries a limited number of times. Prefer constructing valid values
directly over filtering when possible.

**`.Example(seed ...int) V`** — Produce an example value outside of tests (for
documentation, debugging). Do not use in property-based tests — use `.Draw()`
instead.

**`.AsAny() *Generator[any]`** — Convert to `*Generator[any]` (useful with
`MakeCustom`).

### Reflection-Based Generation

**`rapid.Make[V]()`** — Generate values of any type using reflection:

```go
type User struct {
    Name   string
    Age    int
    Active bool
}

user := rapid.Make[User]().Draw(t, "user")
```

Supports: bool, all integer types, float32, float64, string, arrays, slices,
maps, pointers, and structs (exported fields only).

**`rapid.MakeCustom[V](cfg MakeConfig)`** — With overrides:

```go
user := rapid.MakeCustom[User](rapid.MakeConfig{
    Types: map[reflect.Type]*rapid.Generator[any]{
        reflect.TypeOf(""): rapid.StringN(1, 50, -1).AsAny(),
    },
    Fields: map[reflect.Type]map[string]*rapid.Generator[any]{
        reflect.TypeOf(User{}): {
            "Age": rapid.IntRange(0, 150).AsAny(),
        },
    },
}).Draw(t, "user")
```

`MakeConfig` fields:
- `Types` — Override generators for specific `reflect.Type`s
- `Kinds` — Override generators for specific `reflect.Kind`s
- `Fields` — Override generators for specific struct fields (by type and field name)

## State Machine Testing

Rapid supports stateful (model-based) testing via `t.Repeat()`.

### Using `t.Repeat` directly

```go
func TestQueue(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        n := rapid.IntRange(1, 1000).Draw(t, "n")
        q := NewQueue(n)
        var model []int

        t.Repeat(map[string]func(*rapid.T){
            "get": func(t *rapid.T) {
                if q.Size() == 0 {
                    t.Skip("queue empty")
                }
                got := q.Get()
                if got != model[0] {
                    t.Fatalf("got %v, expected %v", got, model[0])
                }
                model = model[1:]
            },
            "put": func(t *rapid.T) {
                if q.Size() == n {
                    t.Skip("queue full")
                }
                i := rapid.Int().Draw(t, "i")
                q.Put(i)
                model = append(model, i)
            },
            "": func(t *rapid.T) {
                // Invariant check — runs after every action
                if q.Size() != len(model) {
                    t.Fatalf("size mismatch: %v vs %v", q.Size(), len(model))
                }
            },
        })
    })
}
```

The `""` key is special — it designates an invariant check that runs after
every other action. Use `t.Skip()` within actions to skip inapplicable actions
(e.g., can't dequeue from empty queue).

### Using `StateMachine` interface

For complex state machines, define a type implementing `rapid.StateMachine`:

```go
type queueMachine struct {
    q     *Queue
    n     int
    model []int
}

func (m *queueMachine) Check(t *rapid.T) {
    // Invariant — called after every action
    if m.q.Size() != len(m.model) {
        t.Fatalf("size mismatch")
    }
}

// Actions are methods named anything except "Check",
// with signature func(*rapid.T) or func(rapid.TB)
func (m *queueMachine) Get(t *rapid.T) {
    if m.q.Size() == 0 {
        t.Skip("empty")
    }
    got := m.q.Get()
    if got != m.model[0] {
        t.Fatalf("got %v, want %v", got, m.model[0])
    }
    m.model = m.model[1:]
}

func (m *queueMachine) Put(t *rapid.T) {
    if m.q.Size() == m.n {
        t.Skip("full")
    }
    i := rapid.Int().Draw(t, "i")
    m.q.Put(i)
    m.model = append(m.model, i)
}

func TestQueueStateMachine(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        n := rapid.IntRange(1, 1000).Draw(t, "n")
        m := &queueMachine{q: NewQueue(n), n: n}
        t.Repeat(rapid.StateMachineActions(m))
    })
}
```

`rapid.StateMachineActions(sm)` uses reflection to discover action methods.
Any public method (other than `Check`) with signature `func(*rapid.T)` or
`func(rapid.TB)` is treated as an action.

## Failure Persistence

When a test fails, rapid automatically saves the minimal failing test case to
`testdata/rapid/TestName/*.fail`. On subsequent runs, rapid replays these
saved failures before generating new test cases, ensuring regressions stay
caught. Commit these files to version control.

Disable with `-rapid.nofailfile` or `RAPID_NOFAILFILE=true`.

## Idiomatic Patterns

### Round-trip (serialize/deserialize)

```go
func TestJSONRoundTrip(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        user := rapid.Make[User]().Draw(t, "user")
        data, err := json.Marshal(user)
        if err != nil {
            t.Fatalf("marshal: %v", err)
        }
        var got User
        if err := json.Unmarshal(data, &got); err != nil {
            t.Fatalf("unmarshal: %v", err)
        }
        if !reflect.DeepEqual(user, got) {
            t.Fatalf("round-trip failed: %v != %v", user, got)
        }
    })
}
```

### Invariant preservation

```go
func TestSortPreservesLength(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
        original := len(xs)
        slices.Sort(xs)
        if len(xs) != original {
            t.Fatalf("length changed: %d -> %d", original, len(xs))
        }
    })
}
```

### Oracle / reference implementation

```go
func TestMySortMatchesStd(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
        expected := slices.Clone(xs)
        slices.Sort(expected)
        actual := mySort(xs)
        if !slices.Equal(actual, expected) {
            t.Fatalf("mismatch: got %v, want %v", actual, expected)
        }
    })
}
```

### No-crash / robustness

```go
func TestParseDoesntPanic(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        input := rapid.String().Draw(t, "input")
        _ = MyParser(input) // should never panic
    })
}
```

### Dependent generation

```go
func TestValidIndex(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOfN(rapid.Int(), 1, -1).Draw(t, "xs")
        idx := rapid.IntRange(0, len(xs)-1).Draw(t, "idx")
        _ = xs[idx] // always valid
    })
}
```

### Evolving a unit test into a PBT

Before (unit test):

```go
func TestReverse(t *testing.T) {
    tests := []struct{ in, want []int }{
        {[]int{1, 2, 3}, []int{3, 2, 1}},
        {nil, nil},
        {[]int{42}, []int{42}},
    }
    for _, tt := range tests {
        got := reverse(tt.in)
        if !slices.Equal(got, tt.want) {
            t.Errorf("reverse(%v) = %v, want %v", tt.in, got, tt.want)
        }
    }
}
```

After (property-based test):

```go
func TestReverseInvolution(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
        if !slices.Equal(reverse(reverse(xs)), xs) {
            t.Fatal("reverse is not an involution")
        }
    })
}

func TestReversePreservesElements(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
        got := reverse(xs)
        slices.Sort(xs)
        slices.Sort(got)
        if !slices.Equal(xs, got) {
            t.Fatal("reverse changed elements")
        }
    })
}
```

### Model-based testing (data structures)

```go
func TestMyMapModel(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        subject := NewMyMap()
        model := make(map[int]int)

        t.Repeat(map[string]func(*rapid.T){
            "insert": func(t *rapid.T) {
                k := rapid.Int().Draw(t, "k")
                v := rapid.Int().Draw(t, "v")
                subject.Insert(k, v)
                model[k] = v
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
                    t.Fatalf("get(%d): got (%d, %v), want (%d, %v)", k, got, ok1, want, ok2)
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

### Commutativity

```go
func TestSetUnionCommutes(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        a := rapid.SliceOfDistinct(rapid.Int(), rapid.ID[int]).Draw(t, "a")
        b := rapid.SliceOfDistinct(rapid.Int(), rapid.ID[int]).Draw(t, "b")
        ab := union(a, b)
        ba := union(b, a)
        slices.Sort(ab)
        slices.Sort(ba)
        if !slices.Equal(ab, ba) {
            t.Fatalf("union is not commutative")
        }
    })
}
```

### Idempotence (normalization / case conversion)

```go
func TestNormalizeIdempotent(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        s := rapid.String().Draw(t, "s")  // full Unicode, not ASCII
        once := normalize(s)
        twice := normalize(once)
        if once != twice {
            t.Fatalf("not idempotent for %q: %q -> %q", s, once, twice)
        }
    })
}
```

### Parse robustness

```go
func TestParseNoPanic(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        s := rapid.String().Draw(t, "s")
        _ = MyType(s) // should never panic, just return error
    })
}
```

## Gotchas

1. **Labels are required for `Draw`.** Always pass a descriptive label:
   `rapid.Int().Draw(t, "count")`. The label appears in counterexample output,
   making failures easier to understand.

2. **`rapid.Check` wraps `*testing.T`, not replaces it.** Your test function
   signature is `func TestFoo(t *testing.T)`, and you call
   `rapid.Check(t, func(t *rapid.T) { ... })` inside it.

3. **`t.Skip()` discards test cases.** It's the equivalent of `assume` in
   other frameworks. If too many cases are skipped, rapid will report an error
   about not generating enough valid tests.

4. **Float generators exclude NaN.** `rapid.Float64()` generates values in
   [-MaxFloat64, MaxFloat64] by default, which excludes NaN. If your code
   should handle NaN, test for it separately.

5. **Default collection sizes are small.** `rapid.SliceOf(gen)` with no bounds
   rarely produces 100+ elements. If you need large collections, draw the size
   separately:
   ```go
   n := rapid.IntRange(0, 300).Draw(t, "n")
   xs := rapid.SliceOfN(rapid.Int(), n, -1).Draw(t, "xs")
   ```

6. **Use `rapid.ID[T]` with `SliceOfDistinct`.** When testing maps/sets that
   need unique keys of a comparable type:
   ```go
   keys := rapid.SliceOfDistinct(rapid.Int(), rapid.ID[int]).Draw(t, "keys")
   ```

7. **Failure files go in `testdata/rapid/`.** Rapid persists minimal failing
   test cases here. Commit them to version control so regressions stay caught.

8. **`-1` means unbounded.** For collection generators, pass `-1` for `minLen`
   or `maxLen` to leave that bound unset:
   ```go
   rapid.SliceOfN(rapid.Int(), 5, -1)  // at least 5 elements, no upper bound
   ```
