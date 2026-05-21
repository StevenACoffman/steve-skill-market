---
name: go-constructor-option-pattern-selection
allowed-tools: Bash, Read, Edit
id: go-constructor-option-pattern-selection
description: Invoke when designing a constructor for a type with optional configuration — specifically to decide between functional options (Rob Pike), dysfunctional options (method chaining), and an exposed config struct.
type: merged-skill
source_skills:
  - slug: effective-go-recipes/skills/go-functional-options-vs-config-struct
    book: Effective Go Recipes
    author: Miki Tebeka
  - slug: rednafi/option-configuration-patterns
    book: Go Advice
    author: Redowan Delowar (rednafi)
related_skills:
  - slug: effective-go-recipes/skills/go-functional-options-vs-config-struct
    relation: supersedes
    note: Merged into go-constructor-option-pattern-selection; source covers functional options implementation, per-option error validation advantage, and config struct as simpler alternative.
  - slug: rednafi/option-configuration-patterns
    relation: supersedes
    note: Merged into go-constructor-option-pattern-selection; source covers dysfunctional options pattern (method chaining), three-pattern decision tree, ~76x performance benchmark, and IDE discoverability argument.
tags: []
---

# Go Constructor Option Pattern Selection

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Functional option functions (With*):
!`grep -rn 'func With[A-Z]' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -10`

Config/Options structs:
!`grep -rn 'type.*Config struct\|type.*Options struct\|type.*Opts struct' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -10`

### R — Reading

> "By passing a variable number of arguments to NewServer, we allow the user to pass zero or more options. If the user doesn't pass any options, the server will be created with default values. Making the Server struct configuration-related fields unexported gives you the freedom to change the implementation of Server without users being aware."
>
> — Miki Tebeka, *Effective Go Recipes*
>
> "While the functional constructor pattern is the most intriguing one among the three, I almost never reach for it unless I need my users to be able to configure large option structs with many optional fields. It's rare and the extra indirection makes the code inscrutable. Also, it renders the IDE suggestions useless."
>
> "Apart from simplicity and the lack of magic, you can hover over the return type of the factory and immediately know about the supported modifier methods. I did a rudimentary benchmark of the two approaches and was surprised that the second one was roughly ~76x faster on Go 1.22!"
>
> — rednafi, *Go Advice*

**Convergence note:** Both sources agree that functional options are not the universal default and that the config struct is the right choice for internal or stable APIs with known options; Tebeka uniquely adds that per-option error validation (`func(*T) error` return type) is functional options' decisive advantage for APIs with complex option-specific validation requirements, while rednafi uniquely introduces the dysfunctional options pattern (method chaining on `*config`) as a superior alternative for most external API cases, supported by a ~76× performance benchmark and IDE discoverability argument.

---

### I — Unified Framework

Three Go option patterns, ranked by simplicity. The critical disagreement between sources — **resolved here as a decision conditional** — is which pattern to use for external APIs with optional fields: Tebeka says functional options; rednafi says dysfunctional options (method chaining). Both are correct in their respective cases; the decision depends on one specific caller behavior.

## R — Reading

> "By passing a variable number of arguments to NewServer, we allow the user to pass zero or more options. If the user doesn't pass any options, the server will be created with default values. Making the Server struct configuration-related fields unexported gives you the freedom to change the implementation of Server without users being aware."
>
> — Miki Tebeka, *Effective Go Recipes*
>
> "While the functional constructor pattern is the most intriguing one among the three, I almost never reach for it unless I need my users to be able to configure large option structs with many optional fields. It's rare and the extra indirection makes the code inscrutable. Also, it renders the IDE suggestions useless."
>
> "Apart from simplicity and the lack of magic, you can hover over the return type of the factory and immediately know about the supported modifier methods. I did a rudimentary benchmark of the two approaches and was surprised that the second one was roughly ~76x faster on Go 1.22!"
>
> — rednafi, *Go Advice*

**Convergence note:** Both sources agree that functional options are not the universal default and that the config struct is the right choice for internal or stable APIs with known options; Tebeka uniquely adds that per-option error validation (`func(*T) error` return type) is functional options' decisive advantage for APIs with complex option-specific validation requirements, while rednafi uniquely introduces the dysfunctional options pattern (method chaining on `*config`) as a superior alternative for most external API cases, supported by a ~76× performance benchmark and IDE discoverability argument.

---

## I — Unified Framework

Three Go option patterns, ranked by simplicity. The critical disagreement between sources — **resolved here as a decision conditional** — is which pattern to use for external APIs with optional fields: Tebeka says functional options; rednafi says dysfunctional options (method chaining). Both are correct in their respective cases; the decision depends on one specific caller behavior.

### Pattern 1 — Exposed Config Struct (Simplest, Internal/stable APIs)

Export `Config` with public fields. Provide `NewConfig(required)` setting defaults. Callers set optional fields directly with named field syntax.

```go
type Style struct { Fg, Bg string; Und bool }
func NewStyle(fg, bg string) *Style { return &Style{Fg: fg, Bg: bg} }
// Caller: s := NewStyle("red", "blue"); s.Und = true
```

Standard library precedent: `bufio.NewReader`, `bufio.NewWriter`. Breaks only if callers use positional initialization without field names (mitigated by requiring named-field syntax in reviews).

**Use when:** internal or same-module API, stable options, ≤3 optional fields, or any case where the struct fields are safe to export.

### Pattern 2 — Dysfunctional Options / Method Chaining (External APIs, Most Cases)

`NewConfig(required)` returns a `*config` with defaults set. Each optional field gets a method returning `*config` for chaining.

```go
func NewConfig(foo, bar string) *config {
    return &config{foo: foo, bar: bar, fizz: 10, bazz: 100}
}
func (c *config) WithFizz(fizz int) *config { c.fizz = fizz; return c }
func (c *config) WithBazz(bazz int) *config { c.bazz = bazz; return c }

// Caller: src.NewConfig("hello", "world").WithFizz(1).WithBazz(2)
```

Advantages over functional options: ~76× faster (no closure allocation), IDE lists all `With*` methods immediately when the caller hovers over the factory return type, config struct stays private, modifier methods are discoverable without reading documentation.

The name "dysfunctional options" is rednafi's coinage — this is Go's idiomatic builder pattern without a mandatory `.Build()` call.

**Use when:** external or public API, many optional fields, callers do NOT need to collect or store options as a slice for later programmatic composition.

### Pattern 3 — Functional Options / Rob Pike Pattern (External APIs, Specific Case)

`type option func(*config)`. Each optional field becomes a `With*` function returning a closure.

```go
type Option func(*Server) error
func WithPort(p int) Option {
    return func(s *Server) error {
        if p < 1 || p > 65535 { return fmt.Errorf("invalid port %d", p) }
        s.port = p
        return nil
    }
}
func NewServer(opts ...Option) (*Server, error) {
    s := &Server{port: 8080, host: "localhost"}
    for _, opt := range opts {
        if err := opt(s); err != nil { return nil, err }
    }
    return s, nil
}
```

**The decisive advantage of functional options over dysfunctional options:** Each option can return a validation error with specific context (`"invalid port 8081000"`). Dysfunctional options mutate the struct directly — they cannot return an error without a separate `Validate()` step. If individual options have their own validation logic that must surface immediately, functional options are the right choice.

**The specific trigger for functional options (rednafi's narrowing):** Callers need to build `[]Option` slices programmatically — collect options conditionally, pass option sets across package boundaries, or let third-party callers define new options externally. Dysfunctional options cannot be stored as slices; they are method calls on a concrete type that third parties cannot extend.

**Use when:** callers need to collect/store/compose `[]Option` slices at runtime, OR individual options require their own error return with validation context.

### Decision Tree

```text
How many options? Are they stable?
├── ≤3 stable → pass directly or use small Config struct (Pattern 1)
└── More than 3 or growing →
    Is the API internal or same module?
    ├── Yes → exposed Config struct (Pattern 1)
    └── No (external/public) →
        Do callers need to build []Option slices programmatically,
        OR do individual options require per-option error validation?
        ├── Yes → functional options (Pattern 3) [Tebeka]
        └── No → dysfunctional options / method chaining (Pattern 2) [rednafi]
```

---

## A1 — Past Application

### Case 1: NewServer with per-Option Error Validation — Functional Options (Effective Go Recipes, Recipe 28)

Tebeka's `NewServer` constructor accepts `...func(*Server) error`. `WithPort` validates that the port is in range 1–65535 and captures the value in a closure. `WithHost` validates the host is non-empty. A caller writes `s, err := NewServer(WithPort(9999), WithHost("localhost"))`.

If `WithPort(-1)` is passed, `NewServer` returns an error attributed specifically to the port option — not a generic "invalid configuration" message. The validation runs at call-argument evaluation time (Go evaluates arguments before passing them), not inside `NewServer`'s loop, giving the clearest possible error attribution.

**Domain:** Library server constructor with complex validation. **What this demonstrates:** Per-option error validation is functional options' legitimate and specific advantage — it cannot be replicated with dysfunctional options without a separate explicit validation step.

### Case 2: Benchmark and IDE Failure — Dysfunctional Options Vs. Functional Options (Rednafi)

rednafi benchmarked the two approaches on Go 1.22. Each `With*` call in functional options allocates a closure on the heap. Dysfunctional options mutate the struct pointer directly with no allocation. Result: method chaining is approximately 76× faster in the benchmark.

In a second case (ce16), a library using `opts ...func(*Config)` gives users no IDE-visible hint of available options — hovering over the factory return type shows only `func(*Config)`, not the available `With*` functions. Switching to dysfunctional options (methods on `*config`) restores IDE completions immediately.

**Domain:** Library API design and IDE tooling. **What this demonstrates:** For the common case where callers do not need composable option slices and options do not require per-option error validation, dysfunctional options are faster, more discoverable, and require no closure allocation.

---

## A2 — Trigger ★

Instead of "functional options or config struct," use this skill when:

**Use this skill when:**

- You are designing a constructor for a type with optional configuration and need to choose between all three patterns with specific reasons — not just applying the Rob Pike pattern by default.
- You are writing an external (public) API and need to decide whether dysfunctional options (method chaining) or functional options is more appropriate for your callers.
- A teammate or generated code uses functional options for an external API; you need to evaluate whether dysfunctional options would be a better fit.
- Individual options need their own validation error return — this is the specific trigger for functional options over dysfunctional options.
- Callers need to collect option sets as `[]Option` slices for later application — this is the other specific trigger for functional options.
- Your IDE shows `func(*Config)` instead of the available configuration options — this is the dysfunctional options migration trigger.

**Not this skill when:** the question is about wiring services together (that is manual dependency injection); the question is about interface design (that is consumer-side interface placement); the API has no optional configuration.

---

## E — Execution

## Step 1 — Count Options and Assess Stability

If ≤3 options and they are stable: use an exposed config struct or pass required fields directly to the constructor. Done. Do not abstract further.

## Step 2 — Determine API Scope

If internal (same module or package): use an exposed Config struct. Callers use named fields. No closure, no method chain, no indirection.

## Step 3 — for External APIs, Apply the Decision Conditional

Does either of these conditions apply?

- Callers will build `[]Option` slices programmatically (conditional application, cross-package forwarding, third-party extension)
- Individual options need their own `error` return with specific validation context

If **yes**: use functional options (Pattern 3). Follow Tebeka's implementation: `type Option func(*T) error`, constructor applies each option in order and returns on first error, all configuration fields unexported.

If **no**: use dysfunctional options (Pattern 2). Follow rednafi's implementation: private `config` type, `NewConfig(required)` sets defaults and returns `*config`, each optional field is one method `func (c *config) WithX(v T) *config { c.x = v; return c }`.

## Step 4 — Implement the Chosen Pattern

**Dysfunctional options:**

```go
func NewConfig(foo, bar string) *config {
    return &config{foo: foo, bar: bar, fizz: 10, bazz: 100}
}
func (c *config) WithFizz(fizz int) *config { c.fizz = fizz; return c }
func (c *config) WithBazz(bazz int) *config { c.bazz = bazz; return c }
// Usage: src.NewConfig("hello", "world").WithFizz(1).WithBazz(2)
```

Completion: IDE shows `WithFizz`, `WithBazz` as method completions on the factory return type.

**Functional options:**

```go
type Option func(*T) error
func WithPort(p int) Option {
    return func(t *T) error {
        if p < 1 || p > 65535 { return fmt.Errorf("port out of range: %d", p) }
        t.port = p
        return nil
    }
}
func NewT(opts ...Option) (*T, error) {
    t := &T{port: 8080}  // defaults
    for _, opt := range opts {
        if err := opt(t); err != nil { return nil, err }
    }
    return t, nil
}
```

Completion: each option validates at call time; error attribution identifies the specific invalid option.

**Config struct:**

```go
func NewStyle(fg, bg string) *Style { return &Style{Fg: fg, Bg: bg} }
// Callers: s := NewStyle("red", "blue"); s.Und = true
```

Completion: named fields visible in IDE; zero closures, zero indirection.

---

## B — Boundary

### Source a Failures (Tebeka / Effective Go Recipes)

- Functional options add call-site verbosity: `NewServer(WithPort(8080), WithTimeout(30*time.Second))` is more verbose than `NewServer(Config{Port: 8080})`.
- Unexported fields make introspectability harder — if callers need to inspect the current configuration (health endpoints, debug logging), provide a `Config()` accessor or use an exported config struct.
- IDE discoverability is broken by design with functional options — Tebeka does not address this failure mode.

### Source B Failures (Rednafi)

- **Functional options IDE failure (ce16):** `opts ...func(*Config)` shows no method completions in IDE. Users cannot discover available options without reading documentation. Package-level `With*` functions scattered across files compound the problem.
- **Closure allocation overhead:** Each `With*` call in functional options allocates a closure. For startup-only configuration the 76× slowdown is irrelevant; for hot-path or frequently-constructed objects it matters.
- **Dysfunctional options and mutable shared `*config`:** Methods on `*config` mutate the pointed-to struct. Callers who store the `*config` and call `WithX()` after passing it to a consuming function will silently change live configuration. Functional options create a snapshot at construction time (the closure captures a value, not a pointer) — they are more immutable in practice.
- **Dysfunctional options are not extensible by third parties.** Methods on a private type cannot be added by external packages. If third-party callers need to define new configuration options for your library, functional options are required.
- Interface versioning when the minimal option set needs to grow is not addressed by either source.

### Synthesis-Specific Failure Mode

**Applying functional options as the default for external APIs because it is the "famous" Go pattern.** Both sources agree that functional options are not the universal default. rednafi's dysfunctional options (method chaining) are the correct default for most external APIs. Tebeka's functional options are the correct choice for two specific cases: per-option error validation and caller-composable option slices. A developer who defaults to functional options for an external API — because it is the Rob Pike pattern, because popular libraries use it, because LLMs generate it — is applying a pattern that is slower, less IDE-discoverable, and harder to navigate than dysfunctional options for the case where neither specific functional-options advantage applies.

> **Explicit source disagreement:** Tebeka recommends functional options for public APIs with growing option sets as the primary use case. rednafi recommends dysfunctional options for most external APIs and reserves functional options for the specific caller-composition case. The merged skill encodes this as a decision conditional (Step 3 in E and the decision tree in I) rather than declaring one source correct. Both recommendations are accurate for their respective trigger conditions; the merged skill makes those conditions explicit so the reader can self-select the right pattern.
