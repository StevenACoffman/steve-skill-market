---
name: option-configuration-patterns
description: |
  Trigger: user is designing configuration or options for a struct constructor and wondering which
  pattern to use — functional options (Rob Pike), exposed config struct, or some form of method
  chaining.

  This skill selects between three Go option patterns based on option count, API stability, and
  whether callers need to compose or store options programmatically. The key finding from
  rednafi: functional options (opts ...func(*Config)) are almost never the right choice. The
  standard library prefers simple constructors (bufio.NewReader). For external APIs with many
  optional fields, the "dysfunctional options" pattern — method chaining on a returned *Config —
  is ~76× faster than functional options, maintains IDE discoverability, and requires no
  closure allocation. Functional options are reserved for cases where callers must build,
  store, or conditionally apply option slices at runtime.

  The decision is driven by three questions: How many options? Are they stable? Does the caller
  need to compose them programmatically? If ≤3 stable options, pass them directly. If the API
  is internal, use an exposed Config struct. If the API is external with a stable option set,
  use dysfunctional options (method chaining). Only reach for functional options when callers
  need to collect []Option slices and apply them dynamically, or when third parties need to
  extend the option set.
source_book: "Go Advice" by Redowan Delowar (rednafi)
source_chapter: configure_options, dysfunctional_options_pattern
tags: [go, api-design, configuration, performance, patterns]
related_skills:
  - slug: manual-dependency-injection
    relation: composes-with
  - slug: merged/all-books-v1/go-constructor-option-pattern-selection
    relation: superseded-by
    note: Merged into go-constructor-option-pattern-selection; source covers dysfunctional options pattern (method chaining), three-pattern decision tree, ~76x performance benchmark, and IDE discoverability argument.
---

# Option Configuration Pattern Selection

## R — Original Text (Reading)

> Recently, I've spontaneously stumbled upon a fluent-style API to manage configurations that
> don't require so many layers of indirection and lets you expose optional configuration
> attributes. Let's call it **dysfunctional options pattern**.
>
> The idea is quite similar to how the API with functional options pattern is constructed. Instead
> of being higher order functions, the modifiers are methods on `config` and return a pointer to
> the struct. The `NewConfig` factory function instantiates the `config` struct with some default
> values and returns the struct pointer like the modifiers. This enables us to chain the `WithFizz`
> and `WithBazz` modifiers on the returned value of `NewConfig` and update the values of the
> optional configuration attributes.
>
> Apart from simplicity and the lack of magic, you can hover over the return type of the factory
> and immediately know about the supported modifier methods. I did a rudimentary benchmark of the
> two approaches and was surprised that the second one was roughly ~76x faster on Go 1.22!
>
> While the functional constructor pattern is the most intriguing one among the three, I almost
> never reach for it unless I need my users to be able to configure large option structs with many
> optional fields. It's rare and the extra indirection makes the code inscrutable. Also, it renders
> the IDE suggestions useless.
>
> In most cases, you can get away with exporting the option struct `Stuff` and a companion function
> `NewStuff` to instantiate it. For another canonical example, see `bufio.Read` and `bufio.NewReader`
> in the standard library.
> — rednafi, configure_options / dysfunctional_options_pattern

______________________________________________________________________

## I — Methodological Framework (Interpretation)

**Three patterns, ranked by simplicity:**

1. **Exposed config struct** (simplest): Export `Config` with public fields. Provide a `NewConfig(required fields) *Config` constructor that sets defaults. Callers set optional fields directly: `cfg := src.NewStyle(fg, bg); cfg.Und = true`. Go stdlib uses this (bufio.NewReader). Works for any API where callers are expected to use named fields and the struct is stable. Breaks if fields are added and callers use positional initialization — mitigated by named-field instantiation.

2. **Dysfunctional options** (method chaining): `NewConfig(required) *config` returns a `*config` with defaults. Each optional field gets a method `func (c *config) WithFizz(v int) *config { c.fizz = v; return c }`. Callers chain: `src.NewConfig("hello", "world").WithFizz(1).WithBazz(2)`. The config struct stays private; modifier methods appear as IDE completions on the return type. ~76× faster than functional options in benchmarks on Go 1.22 because no closures are allocated. The "dysfunctional" name signals it is Go's lightweight builder — no mandatory `.Build()` call.

3. **Functional options** (Rob Pike): `type option func(*config)`. Each optional field becomes `func WithFizz(v int) option { return func(c *config) { c.fizz = v } }`. Constructor accepts `opts ...option`. Every option allocates a closure on each call. IDE shows `func(*config)` for completions, not the available options. Callers can collect `[]option` slices and compose them at runtime — this is the one case where functional options win.

**Standard library signal:** `bufio.NewReader`, `bufio.NewWriter`, `bufio.NewScanner` all use simple constructors with an exposed type, not functional options. The stdlib rarely reaches for the pattern.

**The 76× finding:** Benchmark measured functional options vs. dysfunctional options on Go 1.22. Closure allocation is the cost — each `With*` call in functional options allocates a function object on the heap. For startup configuration the absolute difference is irrelevant, but for hot-path or frequently-constructed objects it matters. Dysfunctional options mutate a pointer directly with no allocation.

**IDE discoverability:** Functional options scatter `With*` functions at package level. Hovering over a factory return type that is `config` or `*config` shows nothing useful — you must read documentation or search the package. With dysfunctional options, `NewConfig(...)` returns `*config`, and the IDE immediately lists all `With*` methods.

______________________________________________________________________

## A1 — Past Application

### Case 1: Benchmark — Functional Options Vs. Method Chaining (C09)

- **Problem:** A library API needed to let users configure a struct with several optional fields. The natural impulse was functional options (Rob Pike pattern), which every popular Go library (Ngrok, Elasticsearch agent) uses.
- **Method:** rednafi benchmarked the functional options pattern against the dysfunctional options pattern (method chaining) on Go 1.22. Functional options require each `With*` call to allocate a closure; dysfunctional options mutate the struct pointer directly with no allocation.
- **Conclusion:** Dysfunctional options are approximately 76× faster. IDE completions work. The config struct can still be kept private. The pattern is Go's lightweight builder: `NewConfig(...).WithFizz(1).WithBazz(2)`.
- **Result:** Author adopted dysfunctional options as his preferred pattern for external APIs with optional fields. Functional options reserved for cases where callers need to build `[]option` slices dynamically.

### Case 2: Functional Options IDE Failure (Ce16)

- **Problem:** A library exposes functional options (`opts ...func(*Config)`). Users hover over the return type or factory signature in their IDE looking for what can be configured. The IDE shows `func(*Config)` — no method list, no hint of available options.
- **Method:** Because `With*` functions are package-level functions returning a closure type, they are invisible through the return type of the factory. Users must read source or documentation.
- **Conclusion:** IDE discoverability is broken by design with functional options. Package-level modifier explosion compounds the problem when multiple config structs use the pattern in the same package.
- **Result:** Switch to dysfunctional options (methods on `*config`) restores IDE completions. Users hover over the return type and see all `With*` methods immediately.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Language Signals

- "how should I design options for my struct"
- "should I use functional options"
- "my constructor has too many parameters"
- "how do I add optional configuration to a Go library"
- "Rob Pike options pattern — is that what I should use?"
- "I want to keep my config struct private but still let callers configure it"
- "my IDE doesn't show what options are available"
- "builder pattern in Go"
- "variadic options in Go"

### Distinguishing from Adjacent Skills

- Difference from `manual-dependency-injection`: Dependency injection is about wiring services together (which service gets which database, which logger). Option configuration is about how a single type exposes its construction-time knobs. DI operates at the composition root; option patterns operate at the type's constructor.
- Difference from `consumer-side-interface-segregation`: Interface segregation is about how callers define narrow interfaces over broad producers. Option patterns are about how producers expose construction-time configuration to callers. No interface is involved in the option patterns themselves.

______________________________________________________________________

## E — Execution Steps (Decision Framework)

1. **How many options? Are they stable?**

   - ≤3 stable options → pass directly to constructor as named parameters or use a small Config struct
   - Stop condition: if ≤3 stable options, done — don't abstract further

2. **Is the API internal or external?**

   - Internal (same module or package) → exposed Config struct with named fields: `NewFoo(cfg Config{})`. Simplest, zero allocation, full IDE visibility.
   - External (public library or cross-team API) → continue to step 3

3. **Do callers need to programmatically compose or store options?**

   - Yes (callers build `[]Option` slices, conditionally apply options, pass option sets across package boundaries) → functional options (`opts ...func(*Config)`)
   - No → dysfunctional options (method chaining on `*config`); almost always the right answer

4. **Implement the chosen pattern**

   **Dysfunctional options:**

   ```go
   // config is private; only required args in constructor
   func NewConfig(foo, bar string) *config {
   	return &config{foo: foo, bar: bar, fizz: 10, bazz: 100} // defaults set here
   }

   // Each optional field gets one method; returns *config for chaining
   func (c *config) WithFizz(fizz int) *config { c.fizz = fizz; return c }
   func (c *config) WithBazz(bazz int) *config { c.bazz = bazz; return c }

   // Usage: src.NewConfig("hello", "world").WithFizz(1).WithBazz(2)
   ```

   - Completion criteria: IDE shows `WithFizz`, `WithBazz` as method completions on the factory return type

   **Functional options** (only when callers need composable/storable options):

   ```go
   type option func(*config)

   func WithFizz(fizz int) option { return func(c *config) { c.fizz = fizz } }
   func WithBazz(bazz int) option { return func(c *config) { c.bazz = bazz } }

   func NewConfig(foo, bar string, opts ...option) *config {
   	c := &config{foo: foo, bar: bar, fizz: 10, bazz: 100}
   	for _, opt := range opts {
   		opt(c)
   	}
   	return c
   }
   ```

   - Use only when callers collect and forward `[]option` slices, or third parties must extend the option set

   **Exposed struct + constructor** (internal/stable APIs):

   ```go
   // Export both struct and fields; constructor sets defaults
   func NewStyle(fg, bg string) *Style { return &Style{Fg: fg, Bg: bg} }

   // Callers set optional fields directly: s.Und = true
   // See bufio.NewReader in the standard library
   ```

______________________________________________________________________

## B — Boundary ★

### Do Not Use Dysfunctional Options When

- Callers need to collect, store, or conditionally apply options as `[]option` slices — closures in functional options enable this; dysfunctional options don't (you'd have to store a `*config` and chain later, which requires exporting it)
- Options must be applied in a specific order with meaningful side effects — functional options make order explicit through the call sequence; method chaining makes order implicit
- Third-party callers need to extend the option set without modifying the library — functional options allow external packages to define new `option` values; methods on a private type cannot be added externally

### Failure Patterns

- **Functional options IDE failure** (ce16): `opts ...func(*Config)` shows no method completions in IDE. Users can't discover available options. Package-level `With*` functions scattered across files compound the problem when multiple config types use the pattern in the same package.
- **Closure allocation overhead**: Functional options create a heap allocation per option on every constructor call. For startup-only configuration the 76× slowdown is irrelevant; for hot paths (objects constructed frequently per request) it matters.
- \**Dysfunctional options and shared *config**: Methods on `*config` mutate the pointed-to struct. If callers store the `*config` and chain `WithX()` later, they mutate the live config. Callers who store a `*config` and call `WithX()` after passing it to `Do()` will see unexpected behavior. Mitigate by documenting that `With*` methods must only be called during construction (before passing to any consuming function).

### Author's Blind Spots

- The 76× benchmark is a micro-benchmark measuring per-call closure allocation. For once-per-startup configuration (the common case for library config), the absolute time difference is nanoseconds and practically irrelevant. The IDE discoverability argument is stronger than the performance argument.
- Dysfunctional options allow mutation of the shared `*config` after construction. The caller receives a pointer; any code holding that pointer can call `WithX()` later and change the config silently. Functional options create a snapshot at construction time (the closure captures the value, not a pointer), so they are more immutable in practice.
- Method chaining is already well-established as the "builder pattern" in Go (e.g., `strings.Builder`, `http.Request` modifiers). Calling it "dysfunctional" is a tongue-in-cheek name for what is effectively Go's idiomatic builder.

### Easily Confused With

- **Builder pattern (GoF)**: Dysfunctional options *is* Go's builder pattern. The only difference from the classic builder is the absence of a mandatory `.Build()` call at the end of the chain — the chained pointer is directly usable.
- **Variadic options with a named type** (`func New(opts ...Option)` where `type Option func(*Config)`): This *is* the functional options pattern. The variadic parameter and the function type together are the functional options pattern, regardless of how the type is named.
- **Config struct as a parameter** (`func New(cfg Config)`): This is pattern 1 (exposed struct). It's the simplest pattern and used extensively in the standard library. Don't conflate it with the functional options pattern just because a struct is involved.

______________________________________________________________________

## Related Skills

- **composes-with** [`manual-dependency-injection`](../manual-dependency-injection/SKILL.md): Option patterns operate at the individual constructor level — they expose how a single type accepts its configuration knobs (timeouts, pool sizes, retry counts). Manual DI operates at the composition root level — it connects constructed types to each other in `cmd/main.go`. In practice: use dysfunctional options or functional options inside each `NewX(required).WithTimeout(5*time.Second)` call; use manual DI to pass the returned value into the next constructor.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05
