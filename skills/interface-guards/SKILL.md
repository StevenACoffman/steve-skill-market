---
name: interface-guards
description: |
  Apply when a user defines exported types that must implement specific interfaces, or wants
  compile-time safety for interface conformance. The pattern is: var _ InterfaceName = (*ConcreteType)(nil).
  This is a zero-cost compile-time assertion — the compiler verifies the assignment is valid
  (i.e., the type satisfies the interface) but drops the unused variable; no runtime overhead,
  no allocation. If any required method is missing, has the wrong signature, or is removed, the
  build fails immediately at the guard line. The subtlety is when to add one: only for exported
  types with critical interface contracts where no other static conversion already exists in the
  code. If the type is already passed as the interface somewhere (e.g., a function parameter),
  the compiler already checks it — adding a guard is redundant. For unexported types used
  internally, interface conformance is usually obvious from usage.
tags: [go, interfaces, compile-time-safety, type-system]
---

# Interface Guards (Compile-Time Interface Conformity Checks)

## R — Original Text (Reading)

> Go's implicit interfaces can introduce subtle bugs unless you're careful. Types expected to
> conform to certain interfaces can fluidly add or remove methods. The compiler will only
> complain if an identifier anticipates an interface, but is passed a type that doesn't
> implement that interface. This can be problematic if you need to export types that are
> required to implement specific interfaces as part of their API contract.
>
> There's a way you can statically check interface conformity at compile time with zero runtime
> overhead. `var _ io.ReadWriter = (*T)(nil)` verifies that a nil pointer to a value of type T
> conforms to the io.ReadWriter interface. The code will fail to compile if the type ever stops
> matching the interface.
>
> Don't do this for every type that satisfies an interface, though. By convention, such
> declarations are only used when there are no static conversions already present in the code,
> which is a rare event. — Effective Go (quoted by rednafi)
> — rednafi, interface_guards

______________________________________________________________________

## I — Methodological Framework (Interpretation)

`var _ InterfaceName = (*ConcreteType)(nil)` works by assigning a nil pointer of the concrete
type to a blank identifier variable of the interface type. The compiler must verify the
assignment is valid — which means ConcreteType satisfies InterfaceName. If any method is
missing or has the wrong signature, the build fails at this line. The blank identifier `_`
ensures the nil pointer is never referenced in running code, preventing accidental nil dereference.

For value-receiver types: `var _ InterfaceName = ConcreteType{}`. Use pointer form `(*T)(nil)`
as the default; it handles pointer receivers and avoids needing to know the concrete zero value.

**Where to place it:** immediately after the type definition (before the methods), or at the
package level near where the type is declared. This makes the contract visible alongside the type.

**When to add it:**

- Exported types in library or plugin code where the interface contract is the API surface
- Types that implement framework interfaces (http.Handler, io.ReadWriter, io.ReadWriteCloser)
  without any direct static conversion elsewhere in the package
- Any type where a silent method removal or rename would not be caught until runtime

**When NOT to add it (Effective Go's warning):**

- The type is already passed as the interface to a function, stored in an interface variable,
  or returned as the interface somewhere — the compiler already enforces it there
- Unexported types used only internally where intent is obvious from usage
- Rapid prototyping where the interface contract is still evolving

The Go standard library uses this pattern itself: `bytes.Buffer` and `os.File` carry interface
guards for `io.ReadWriter` and `io.ReadWriteCloser` respectively.

______________________________________________________________________

## A1 — Past Application

### Case 1: Exported Type T Must Implement io.ReadWriter (From Source Chapter)

- **Problem:** Type T exported from a package is documented to implement io.ReadWriter. If a
  developer renames or removes Read or Write during refactoring, the compiler only catches it
  if T is actually used as io.ReadWriter somewhere in existing code — and that usage may be in
  a different package, in a test, or not yet written.
- **Method:** Add `var _ io.ReadWriter = (*T)(nil)` near the type definition. The blank
  identifier and nil pointer cost nothing at runtime; the compiler validates the assignment
  at build time.
- **Conclusion:** The guard makes the interface contract self-enforcing. Any future breakage
  fails the build immediately, before a caller in another package ever encounters the problem.
- **Result:** Both Read and Write must be present with the correct signatures for the package
  to compile. Removing either produces a clear error pointing to the guard line.

### Case 2: http.Handler Conformance for Exported Handler Struct (From Uber Style Guide, Cited by Rednafi)

- **Problem:** A Handler struct implements ServeHTTP but this is only verified when the type is
  registered with an HTTP mux. If ServeHTTP is accidentally dropped, tests that mock the handler
  may still pass, and the error surfaces only when registering the handler at startup.
- **Method:** `var _ http.Handler = (*Handler)(nil)` placed alongside the type definition.
- **Conclusion:** The guard catches the regression at compile time, regardless of test coverage
  or registration order.
- **Result:** Build fails immediately with a message identifying that \*Handler does not implement
  http.Handler (missing ServeHTTP method).

______________________________________________________________________

## A2 — Trigger Scenario ★

### Language Signals

- "how do I make sure my type implements an interface"
- "how can I get a compile error if I remove a method"
- "I renamed a method and didn't realize my type no longer satisfied the interface until production"
- "is there a way to enforce interface conformance at build time in Go"
- "we added a method to our interface and now things fail at runtime — how do we catch this earlier"
- "our plugin system has 20 types that must all implement Processor — how do we make sure they stay compliant"

### Distinguishing from Adjacent Skills

- **Difference from `consumer-side-interface-segregation`:** That skill is about where the
  interface is defined (at the consumer, not the producer) and keeping interfaces small. This
  skill is about verifying that a type satisfies an interface you already have — orthogonal
  concerns. You can use both: define a minimal consumer-side interface, then guard the
  implementation against it.
- **Difference from `manual-dependency-injection`:** Manual DI passes concrete types into
  constructors expecting interfaces, which gives the compiler implicit checking at the injection
  site. If the DI wiring already provides static conformance checking, an explicit guard is
  redundant (Effective Go's caveat applies). Use a guard when there is no such wiring site.

______________________________________________________________________

## E — Execution Steps

1. **Identify exported types with critical interface contracts**

   - Ask: does this type form part of a public API that promises interface conformance?
   - Ask: is there already a static conversion (function call, return statement, variable
     assignment) in the code that forces the compiler to verify conformance? If yes, skip
     the guard.
   - Completion criteria: Named the interface(s) the type must implement and confirmed no
     redundant static conversion exists.

2. **Choose the correct guard form**

   - Pointer receivers (most common): `var _ InterfaceName = (*ConcreteType)(nil)`
   - Value receivers only: `var _ InterfaceName = ConcreteType{}`
   - Place it near the type definition, before or after the struct declaration, at package level.
   - Completion criteria: Guard line is in the file; package compiles.

3. **Verify the guard catches regressions**

   - Temporarily remove or rename one required method.
   - Confirm the build fails with a message like: `cannot use (*ConcreteType)(nil) (type *ConcreteType) as type InterfaceName`
   - Restore the method.
   - Completion criteria: Build failure is unambiguous and points to the guard line, not to a
     distant usage site.

4. **For multiple implementing structs**

   - Add a guard for each struct separately — there is no sweep mechanism.
   - Convention: one guard per type, each near its own definition.
   - Completion criteria: Each struct has its own `var _ InterfaceName = (*StructN)(nil)` line.

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- The type is already statically assigned to the interface elsewhere in the package — redundant
  guard adds noise without benefit (Effective Go's explicit warning).
- Unexported types where interface conformance is obvious from the single usage site.
- During rapid prototyping where the interface definition is still changing — guards become
  friction before the contract is stable.
- The interface has only one method and the type is a function type satisfying it (the
  assignment pattern doesn't apply the same way).

### Failure Patterns

- **Relying on runtime panics** to discover interface mismatches — discovered in production,
  not at build time; the guard exists to eliminate this entirely.
- **Using type assertions at the usage site** (`t.(InterfaceName)`) as the only check — catches
  the mismatch where the type is used, not where it is defined; the error message is further
  from the cause, and usage sites may not be exercised in tests.
- **Adding guards to every type indiscriminately** — when conformance is already verified by
  static conversions, guards become dead weight and make code harder to read.
- **Forgetting to update guards after interface changes** — a guard added for the old interface
  definition must be reviewed when the interface gains or loses methods; however, this is still
  less work than tracking down all implementing types manually.

### Author's Blind Spots

- The guard only checks that the type satisfies the interface as defined today — it does not
  protect against future changes to the interface itself; that requires code review discipline
  or tooling (staticcheck, gopls).
- In codebases with many implementing structs, each one requires its own guard line; there is
  no macro or generative mechanism. This is manual but also explicit.
- The pattern relies on developers knowing it exists — the author notes it was "buried in
  Effective Go" and is not common knowledge among intermediate Go developers.

### Easily Confused With

- **`implements` keyword in TypeScript/Rust traits** — Go has no such keyword; the guard is a
  convention, not a language feature.
- **`go vet` / `staticcheck`** — these tools can also catch interface mismatches; they are
  complementary, not a replacement. Guards work without any toolchain setup and fail the build
  rather than producing a lint warning.
- **Type assertions `t.(InterfaceName)`** — these are runtime checks; guards are compile-time.

______________________________________________________________________

## Related Skills

- **composes-with** `consumer-side-interface-segregation`: After defining a narrow consumer-side interface in the business package and implementing it in a gateway package, an interface guard (`var _ paymentGateway = (*StripeGateway)(nil)`) placed in the gateway package verifies at compile time that the implementation still satisfies the interface. This is most valuable when the implementing type lives in a different package with no direct assignment in normal code paths — exactly the gateway pattern scenario.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Go Advice" by Redowan Delowar (rednafi) — interface_guards
