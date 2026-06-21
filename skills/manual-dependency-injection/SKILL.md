---
name: manual-dependency-injection
description: |
  Activate when a developer asks whether to use a DI framework (dig, wire, FX) or how to
  structure dependency wiring in Go, or when they describe a complex dependency graph and
  wonder if they need a container.

  The skill covers two tightly connected ideas from rednafi's "Go Advice":
  1. DI is a "25-dollar term for a 5-cent concept" (James Shore): pass values into
     constructors instead of creating them inside. A manual main() that calls constructors
     in dependency order IS the DI container — and the Go compiler enforces it at build time,
     not at runtime.
  2. DI frameworks (dig, FX) and mocking libraries (mockery, gomock) are the same anti-pattern
     applied in different contexts: both hide the dependency graph behind reflection or
     codegen. With dig, commenting out a provider still compiles — the error is a 5-frame
     runtime stack trace. With mockery, generated mocks drift from interfaces and require
     migration workflows. Handwritten fakes passed directly to constructors replace both.

  Trigger phrases: "should I use wire/dig/FX", "how do I manage dependencies in Go",
  "my dependency graph is getting complex", "is there a DI container for Go", "should I
  use a mocking library", "why is my dig error so confusing".

  Do NOT activate for: questions about interface design or ISP (see
  consumer-side-interface-segregation), questions about which dependencies to inject vs.
  bake in (unrelated to the mechanism), or questions about service mesh / infra-level
  dependency resolution.
source_book: "Go Advice" by Redowan Delowar (rednafi)
source_chapter: di_frameworks_bleh, mocking_libraries_bleh
tags: [go, dependency-injection, architecture, testing]
related_skills:
  - slug: domain-driven-package-structure
    relation: depends-on
  - slug: consumer-side-interface-segregation
    relation: composes-with
  - slug: option-configuration-patterns
    relation: composes-with
---

# Manual Dependency Injection (No DI Frameworks)

## R — Original Text (Reading)

> Dependency Injection is a 25-dollar term for a 5-cent concept.
> — James Shore
>
> DI basically means *passing values into a constructor instead of creating them inside it*.
> That's really it. […] The call order is the dependency graph. Errors are handled right
> where they happen. If a constructor changes, the compiler points straight at every broken
> call. No reflection, no generated code, no global state. Go type-checks the dependency
> graph early and loudly, exactly how it should be.
>
> Now try commenting out `NewFlagClient`. The code still compiles. There's no error until
> runtime, when dig fails to construct `NewService` due to a missing dependency. And the
> error message you get? That's five stack frames deep, far from where the problem started.
> Now you're digging through dig's internals to reconstruct the graph in your head.
>
> — rednafi, di_frameworks_bleh

______________________________________________________________________

## I — Methodological Framework (Interpretation)

**DI is constructor parameter passing, nothing more.** `NewServer(db DB) *server` injects
the dependency. `NewServer() *server` that creates its own `DB` does not. The framework
vocabulary ("provider", "container", "invoke") is a marketing layer over this one-line concept.

**The Go compiler is the DI container — and stricter than any reflection tool.** A manual
`main()` that lists constructors in dependency order (`db := NewDB(cfg.DSN); repo := NewRepo(db); svc := NewService(repo, flags)`) gives the compiler complete visibility. Remove
a constructor call and the code does not build. The error message is one line: `not enough arguments in call to NewService`.

**DI frameworks add a second, weaker dependency graph at runtime.** With dig, every
`Provide()` call registers a node that is resolved by reflection when `Invoke()` runs.
Missing providers are invisible at compile time; they surface only when the process starts.
Wire shifts this to code generation, which is an improvement, but still requires running
`go generate` after every signature change and debugging generated glue code.

**Mocking libraries are the testing equivalent of DI frameworks.** mockery and gomock
generate code from interfaces at build time; gomock uses reflection at test time. Both hide
the fake behind indirection instead of a plain struct. Handwritten fakes passed directly to
the constructor under test — `svc := NewService(fakeDB, fakeCache)` — are the testing
equivalent of explicit wiring: visible, compiler-checked, no runtime surprises.

**Interfaces at injection boundaries enable both production and test substitution.** Services
accept `DB` (an interface), not `*sql.DB` (a concrete type). The production call passes a
`RealDB`; the test call passes a `FakeDB`. Both satisfy the interface; the compiler verifies
this. No mock generation step, no drift when the interface evolves.

**When `main()` grows large, split into regular Go functions, not into a framework.** A
`buildInfra(cfg)` helper that returns concrete infrastructure types is readable by anyone
without a framework manual. A 20-parameter builder function formatted with one parameter
per line (gofumpt) is still a plain function.

______________________________________________________________________

## A1 — Past Application

### Case 1: NewFlagClient Commented Out — Dig Compiles, Fails at Runtime (C06, Ce03, Ce12)

- **Problem:** A dig container registers six providers with `Provide(NewConfig)`, `Provide(NewDB)`,
  `Provide(NewFlagClient)`, etc. `NewFlagClient` is accidentally removed during a refactor.
  The build succeeds. The service starts and then panics at startup with a five-frame error:
  `dig invoke failed: could not build arguments for function main.main.func1 … missing type: *main.FlagClient`. A developer must read framework internals and mentally reconstruct the
  graph to find the source of the error.
- **Method:** Rewrite as manual `main()`: `cfg := NewConfig(); db := NewDB(cfg.DSN); repo := NewRepo(db); flags := NewFlagClient(cfg.FlagURL); svc := NewService(repo, flags, cfg.APIKey); NewServer(svc, cfg.ListenAddr).Run()`. Remove `flags := NewFlagClient(...)`.
- **Conclusion:** The compiler immediately reports `./main.go:33:39: not enough arguments in call to NewService — have (*Repo), want (*Repo, *FlagClient, string)`. The error points
  directly to the call site, not to framework internals.
- **Result:** Error surface moves from runtime startup (after deploy) to compile time (before
  build succeeds). Missing providers are structurally impossible to ship.

### Case 2: 8-Service Monorepo — Visible Wiring Vs. Hidden FX Graph (V2 Evidence)

- **Problem:** A monorepo with 8 services, each with 10–15 dependencies, uses FX for wiring.
  The FX container resolves the graph by reflection at startup. When the graph breaks, the
  error appears only when the binary is run. No single file shows the full dependency graph
  for any one service; the wiring is scattered across `fx.Provide` calls in multiple modules.
- **Method:** Each service gets its own short `main()` that wires all 10–15 dependencies
  explicitly. The wiring for a service fits in one function, readable top-to-bottom as a
  reading exercise.
- **Conclusion:** 8 short `main()` functions with full graph visible replace 8 hidden FX
  containers. A new team member can understand a service's entire dependency topology by
  reading one file.
- **Result:** Graph errors surface at compile time. LSP (gopls) can navigate from any
  constructor to its call site. The IDE remains useful; FX containers make LSP blind to
  the wiring.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Language Signals

- "should I use wire/dig/FX for dependency injection in Go"
- "how do I manage a complex dependency graph in Go"
- "my dependency graph is getting hard to track"
- "is there a DI container for Go like Spring"
- "how should I wire up my services in main"
- "should I use a mocking library like mockery or gomock"
- "why is my dig/FX error so hard to read"
- "LLMs keep generating tests that use gomock"

### Distinguishing from Adjacent Skills

- **Difference from `consumer-side-interface-segregation`:** Interface segregation decides
  what shape the injection boundary takes (which methods belong in an interface). This skill
  decides the mechanism for fulfilling that boundary (manual constructor call, not a
  framework). They compose: define a narrow consumer-side interface, then wire the concrete
  implementation manually in `main()`.
- **Difference from `test-state-not-interactions`:** That skill covers what you assert in
  tests (state, not call records) and how to write handwritten fakes that encode domain rules.
  This skill covers where fakes are passed in (directly to the constructor, not via a
  generated mock framework). They compose: write a handwritten fake, then inject it at
  the constructor.

______________________________________________________________________

## E — Execution Steps

1. **Wire all dependencies explicitly in main()**

   - List every concrete type in dependency order. Call each constructor once, assign to a
     named variable:

     ```go
     cfg := NewConfig()
     db := NewDB(cfg.DSN)
     repo := NewRepo(db)
     flags := NewFlagClient(cfg.FlagURL)
     svc := NewService(repo, flags, cfg.APIKey)
     srv := NewServer(svc, cfg.ListenAddr)
     srv.Run()
     ```

   - Completion criteria: every dependency appears once as a named variable; constructors are
     called in dependency order; the file reads top-to-bottom as the dependency graph.

2. **Use interfaces at injection boundaries**

   - Services accept interfaces (`OrderDB`, `Cache`, `FlagClient`), not concrete types
     (`*sql.DB`, `*redis.Client`, `*flags.Client`). Define interfaces in the consumer package,
     not the provider package.
   - Completion criteria: `go build` succeeds; swapping a concrete implementation requires
     only changing the `main()` call site, not the service or its tests.

3. **Let the compiler enforce the graph**

   - Do not run a separate graph-validation step. If a constructor is missing or its signature
     changes, the build fails immediately with a message that identifies the call site:

     ```text
     ./main.go:9:39: not enough arguments in call to NewService
         have (*Repo, *FlagClient)
         want (*Repo, *FlagClient, string)
     ```

   - Completion criteria: `go build` succeeds; every dependency is satisfied at compile time;
     no framework startup validation step is needed.

4. **For tests, pass fakes directly to constructors**

   - Do not use mockery or gomock. Write a small struct with in-memory state and pass it:

     ```go
     type FakeDB struct{ data map[string]string }

     func NewFakeDB() *FakeDB                        { return &FakeDB{data: map[string]string{}} }
     func (f *FakeDB) Get(id string) (string, error) { return f.data[id], nil }
     func (f *FakeDB) Save(id, value string) error   { f.data[id] = value; return nil }

     func TestExample(t *testing.T) {
     	svc := NewService(NewFakeDB(), NewFakeCache())
     	_ = svc
     }
     ```

   - Completion criteria: no import of `mockery`, `gomock`, or any mock-generation library;
     the fake satisfies the interface; the compiler verifies this without a generation step.

5. **If main() grows unwieldy, extract regular Go helper functions**

   - Split by infrastructure concern, not by framework concept:

     ```go
     func buildInfra(cfg *Config) (*DB, *FlagClient, error) { return nil, nil, nil }
     func buildService(cfg *Config) (*Service, error)       { return nil, nil }
     ```

   - Completion criteria: each helper is a plain function that any Go developer can read
     without a framework manual; no `Provide`, `Invoke`, or `wire.Build` calls.

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- **Monorepo with hundreds of services and a platform team enforcing architectural constraints
  via FX** — at that scale, framework-enforced consistency across all teams may outweigh the
  local readability benefit. Uber's use of FX (discussed in the chapter) is the canonical
  example of a context where the tradeoff is real.
- **Plugin systems where providers are registered dynamically at runtime** — when the set of
  available implementations is not known at compile time, a reflection-based registry may be
  genuinely necessary.
- **Codebase already using a framework with working tests and no active pain** — refactoring
  to manual wiring without a specific problem to solve is churn, not improvement.

### Failure Patterns

- **ce03 — DI framework hides missing dependency until runtime:** Commenting out a `Provide`
  call still compiles; `Invoke()` fails at startup with a multi-frame error referencing
  container internals. Manual wiring fails at the exact call site during `go build`.
- **ce12 — Framework errors buried in runtime stack traces:** A missing `*FlagClient`
  provider produces `dig invoke failed: could not build arguments for function main.main.func1 … failed to build *main.Server … missing type: *main.FlagClient` — five
  frames deep, pointing at framework internals rather than the missing call.
- **ce11 — AI-generated test bloat:** LLMs default to mockery and gomock because they are
  overrepresented in training data. Generated mocks verify interaction (which method was
  called) rather than state (what changed). They break on harmless refactors and pass
  through swallowed errors. Handwritten fakes injected at the constructor avoid both failure
  modes.

### Author's Blind Spots

- **"Explicit wiring doesn't scale" is partly true.** The author argues a 20-dependency
  `main()` is fine; in a monorepo with 100+ services and frequent dependency changes, uniform
  framework enforcement may prevent graph errors that code review misses. The author
  acknowledges the Uber case without retracting the general advice.
- **The author conflates "I don't need this" with "nobody needs this."** The chapter is
  written from the perspective of industrial Go shops with 5–20 services. The conclusion that
  frameworks add more confusion than value is calibrated to that scale, not to the enterprise
  Java-shop-adopting-Go scenario.

### Easily Confused With

- **Service locator pattern (anti-pattern):** A global registry that provides dependencies on
  demand (`container.Get("db")`). This is the opposite of injection — dependencies are pulled,
  not passed. Injection is always preferable.
- **Constructor injection (this IS constructor injection, done manually):** Manual wiring does
  not abandon the DI principle; it implements it directly without a framework intermediary.
- **Functional options for configuration:** Functional options control how a single type is
  configured (timeouts, buffer sizes). Manual DI wiring connects separate types to each other.
  They are orthogonal.

______________________________________________________________________

## Related Skills

- **depends-on** [`domain-driven-package-structure`](../domain-driven-package-structure/SKILL.md): Manual DI in `cmd/main.go` works elegantly because domain packages are already decoupled — technology packages import domain packages, never the reverse. Without this structural discipline, `main()` would need to resolve circular dependencies or import technology packages from domain packages, defeating the purpose of explicit wiring.
- **composes-with** [`consumer-side-interface-segregation`](../consumer-side-interface-segregation/SKILL.md): CSI defines the interface shape at the injection boundary (narrow, consumer-owned, in the business package). Manual DI fulfills that boundary by wiring the concrete gateway at `cmd/main.go`. Together: define a `paymentGateway` interface in `order/`, implement it in `external/stripe/`, pass it via `order.NewService(stripeGW)` in `main.go`.
- **composes-with** [`option-configuration-patterns`](../option-configuration-patterns/SKILL.md): Option patterns control how individual constructors expose their configuration knobs (timeouts, buffer sizes, retry counts). Manual DI connects those constructors to each other in dependency order. Options configure a single type at construction time; DI composes multiple configured types into a working service.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05
