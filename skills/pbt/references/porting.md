# Porting from Other Property-Based Testing Libraries

When a project already has property-based tests in another framework, porting
to rapid is usually mechanical. The core concepts are the same — generate
random inputs, check a property, shrink failures — but the API surface differs.

## General Principles

### Rapid is imperative

Most PBT libraries use a declarative style: you describe what to generate in a
function signature or strategy combinator, and the framework calls your test
with the generated values. Rapid is imperative: your test function receives a
`*rapid.T` handle and calls `generator.Draw(t, "label")` whenever it needs
a value.

This means:
- There's no limit on how many values you generate per test
- You can generate values conditionally (e.g., inside an `if` or loop)
- Later draws can depend on earlier values without needing combinators

### Shrinking is automatic

Rapid's shrinking is built-in and automatic. You don't implement shrink
functions or define shrinking strategies. Every value drawn through `.Draw()`
is automatically shrinkable.

### Standard assertions

Rapid uses standard Go test assertions: `t.Fatal`, `t.Fatalf`, `t.Error`,
`t.Errorf`. No special assertion functions needed.

## What to Port and What to Rewrite

Not every existing PBT is worth porting line-for-line. Before mechanically
translating, consider:

- **Is the existing test over-constrained?** Many tests from other frameworks
  use narrow generators because shrinking was slow or unreliable. Rapid's
  shrinking is robust — try broader generators first.
- **Are the generators too complex?** If the existing test has elaborate
  strategy combinators just to produce valid inputs, rapid's imperative style
  might let you simplify significantly with sequential `.Draw()` calls.
- **Is the property still the right one?** Porting is a good time to reassess.
  The existing test might test something trivial or use the implementation as
  its own oracle.

## From testing/quick

`testing/quick` is Go's built-in property testing package, but it is limited:
no shrinking, basic generators only, and limited to functions that return bool.

### Test Structure

testing/quick:

```go
import "testing/quick"

func TestAdditionCommutes(t *testing.T) {
    f := func(a, b int) bool {
        return a+b == b+a
    }
    if err := quick.Check(f, nil); err != nil {
        t.Error(err)
    }
}
```

Rapid:

```go
import "pgregory.net/rapid"

func TestAdditionCommutes(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        a := rapid.Int().Draw(t, "a")
        b := rapid.Int().Draw(t, "b")
        if a+b != b+a {
            t.Fatalf("%d + %d != %d + %d", a, b, b, a)
        }
    })
}
```

Key differences:
- testing/quick infers generators from function parameter types via `Generate`;
  rapid uses explicit `.Draw()` calls.
- testing/quick tests return `bool`; rapid tests use `t.Fatal`/`t.Error`.
- testing/quick has no shrinking; rapid automatically shrinks to minimal
  counterexamples.
- testing/quick has no state machine support; rapid has `t.Repeat()`.

### Generator Mapping

| testing/quick | Rapid |
|--------------|-------|
| `func(a int) bool` (auto) | `rapid.Int().Draw(t, "a")` |
| `func(s string) bool` (auto) | `rapid.String().Draw(t, "s")` |
| `func(xs []int) bool` (auto) | `rapid.SliceOf(rapid.Int()).Draw(t, "xs")` |
| Custom `Generate` method | `rapid.Custom(func(t *rapid.T) T { ... })` |
| `quick.Config{MaxCount: 500}` | `-rapid.checks=500` flag or `RAPID_CHECKS=500` |

### Custom Generators

testing/quick:

```go
type Point struct{ X, Y float64 }

func (Point) Generate(rand *rand.Rand, size int) reflect.Value {
    return reflect.ValueOf(Point{
        X: rand.Float64()*200 - 100,
        Y: rand.Float64()*200 - 100,
    })
}
```

Rapid:

```go
pointGen := rapid.Custom(func(t *rapid.T) Point {
    return Point{
        X: rapid.Float64Range(-100, 100).Draw(t, "x"),
        Y: rapid.Float64Range(-100, 100).Draw(t, "y"),
    }
})
```

Or using reflection-based generation:

```go
pointGen := rapid.Make[Point]()
```

### Conditional Properties

testing/quick (no assume, must return true to skip):

```go
func TestDivision(t *testing.T) {
    f := func(a, b int64) bool {
        if b == 0 {
            return true // skip — can't express preconditions
        }
        return a == (a/b)*b + (a%b)
    }
    quick.Check(f, nil)
}
```

Rapid:

```go
func TestDivision(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        a := rapid.Int64().Draw(t, "a")
        b := rapid.Int64().Draw(t, "b")
        if b == 0 {
            t.Skip("division by zero")
        }
        if a != (a/b)*b+(a%b) {
            t.Fatalf("division property violated for %d / %d", a, b)
        }
    })
}
```

## From gopter

Gopter is a Go port of ScalaCheck. The main differences:

- Gopter is declarative (properties + generators defined separately);
  rapid is imperative (`generator.Draw(t, "label")` calls).
- Gopter requires manual shrink definitions or uses built-in shrinkers;
  rapid handles shrinking automatically.
- Gopter has a complex API with `Gen`, `Prop`, `Properties`;
  rapid has only `Check` + generators.

### Test Structure

Gopter:

```go
func TestReverse(t *testing.T) {
    properties := gopter.NewProperties(nil)
    properties.Property("involution", prop.ForAll(
        func(xs []int) bool {
            return reflect.DeepEqual(reverse(reverse(xs)), xs)
        },
        gen.SliceOf(gen.Int()),
    ))
    properties.TestingRun(t)
}
```

Rapid:

```go
func TestReverseInvolution(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs")
        if !slices.Equal(reverse(reverse(xs)), xs) {
            t.Fatal("reverse is not an involution")
        }
    })
}
```

### Generator Mapping

| Gopter | Rapid |
|--------|-------|
| `gen.Int()` | `rapid.Int()` |
| `gen.IntRange(0, 100)` | `rapid.IntRange(0, 100)` |
| `gen.Float64()` | `rapid.Float64()` |
| `gen.AnyString()` | `rapid.String()` |
| `gen.SliceOf(g)` | `rapid.SliceOf(g)` |
| `gen.MapOf(k, v)` | `rapid.MapOf(k, v)` |
| `gen.OneConstOf(a, b, c)` | `rapid.SampledFrom([]T{a, b, c})` |
| `gen.OneGenOf(g1, g2)` | `rapid.OneOf(g1, g2)` |
| `g.Map(f)` | `rapid.Map(g, f)` |
| `g.SuchThat(f)` | `g.Filter(f)` |
| `g.FlatMap(f)` | Use sequential `.Draw()` calls |

### Dependent Generation

Gopter (requires FlatMap):

```go
gen.SliceOf(gen.Int()).FlatMap(func(v interface{}) gopter.Gen {
    xs := v.([]int)
    return gen.IntRange(0, len(xs)-1).Map(func(i int) interface{} {
        return [2]interface{}{xs, i}
    })
}, reflect.TypeOf([2]interface{}{}))
```

Rapid (just use sequential draws):

```go
rapid.Check(t, func(t *rapid.T) {
    xs := rapid.SliceOfN(rapid.Int(), 1, -1).Draw(t, "xs")
    i := rapid.IntRange(0, len(xs)-1).Draw(t, "i")
    // i is always a valid index into xs
})
```

This is one of rapid's main ergonomic advantages — dependent generation is just
sequential code, no combinator gymnastics needed.

## Porting Checklist

When porting tests from testing/quick or gopter:

1. **Remove the old dependency** (if no other tests use it) and add rapid.
2. **Replace the test structure** with `rapid.Check(t, func(t *rapid.T) { ... })`.
3. **Convert generators to `.Draw()` calls.** Start with the broadest generators
   — don't carry over narrow bounds from the old framework unless they're
   justified by the function's contract.
4. **Replace bool returns** with `t.Fatal`/`t.Fatalf` assertions.
5. **Replace `return true` skips** with `t.Skip()`.
6. **Simplify dependent generation.** If the old test used `FlatMap` chains
   just to make later values depend on earlier ones, rewrite as sequential
   `.Draw()` calls.
7. **Remove custom shrink implementations.** Rapid handles shrinking
   automatically.
8. **Run the tests.** If they fail on inputs the old framework didn't find,
   investigate — that's the point.
