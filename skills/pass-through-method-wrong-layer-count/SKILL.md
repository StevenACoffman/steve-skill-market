# Pass-Through-Method-Wrong-Layer-Count

**Book**: A Philosophy of Software Design — John Ousterhout (2018)
**Chapters**: 7 ("Different Layer, Different Abstraction"), 9 ("Better Together or Better Apart?")
**Red Flag**: Pass-Through Method (named explicitly in the book's Summary of Red Flags)

______________________________________________________________________

## R — Reading (Original Source)

> "A pass-through method is one that does little except invoke another method, whose signature is similar or identical to that of the calling method. This typically indicates that there is not a clean division of responsibility between the classes... Pass-through methods make classes shallower: they increase the interface complexity of the class, which adds to complexity, but they don't increase the total functionality of the system. Pass-through methods also create dependencies between classes... The solution is to refactor the classes so that each class has a distinct and coherent set of responsibilities."
>
> "Each piece of design infrastructure added (classes, methods, variables) should pay for itself. A pass-through variable adds complexity to every method in a chain between the creator of the variable and the code that uses it. The solution is to introduce a context object."

— Chapters 7 and 9

______________________________________________________________________

## I — Interpretation

A pass-through method is a symptom, not the disease. The disease is two adjacent layers sharing the same abstraction — the upper layer is not adding value, so it degenerates into a forwarding relay.

The diagnostic is precise: if a method does nothing except call another method (possibly with trivial signature transformation such as renaming a parameter or reordering arguments), it is pass-through. The correct response is not to invent something for the pass-through to do. That produces artificial complexity. The correct response is to ask: **should this layer exist at all?** Each layer in a well-designed system provides an abstraction that differs from the layers above and below it. If the abstraction is identical, there is no reason for the intermediate layer. Merge the layers or expose the inner implementation directly.

Pass-through variables are the parameter-domain equivalent: a variable threaded through five method signatures to reach one leaf function. Every intermediate method must declare the variable in its signature even though it never uses it, creating coupling across the entire call chain. The fix is a context object — a single class that groups the application's global state, created at the entry point and passed as one argument. This is not a global variable; it travels through the normal parameter mechanism but eliminates the signature pollution.

Both forms share the same root cause: a layer or parameter that exists to satisfy an architectural convention rather than to add genuine abstraction.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**(1) TextDocument wrapping Text**
A `TextDocument` class exposed 15 methods. Thirteen were pure pass-throughs to an inner `Text` class — identical signatures, no transformation, no validation, no added state. The correct fix was not to add behavior to `TextDocument`. The correct fix was to eliminate `TextDocument` and let callers use `Text` directly. The intermediate layer provided no different abstraction.

**(2) NetworkErrorLogger wrapping a logger**
A `NetworkErrorLogger` class wrapped a general logger but only reformatted the error message string before forwarding it. The formatting logic belonged inline at the call site or in a small utility function — not in a dedicated class. Creating a class around a single string transformation creates the illusion of structure while adding interface surface area without adding depth.

**(3) Pass-through variable: config through 5 signatures**
A `config` object was required by one leaf function deep in a call chain. It was threaded through five intermediate method signatures — none of which used it — purely to deliver it to the leaf. The fix: create a context object at the entry point of the call chain that holds `config` alongside other application-wide state. Pass the context object as a single argument. The five intermediate signatures are cleaned up; future additions to application-wide state extend the context object rather than every intermediate signature.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you observe any of the following:

- A **service layer** delegates every call to a repository layer with no transformation, validation, or transaction wrapping.
- An **adapter class** that exists between two components but adds no type conversion, format change, or protocol translation.
- A **decorator** whose `Wrap()` or `Execute()` method calls the wrapped object with the same arguments and does nothing else — no logging, no retry, no access control.
- A **code review comment** "we need a class for X" where X is behavior already fully implemented by an existing class.
- Any method whose **first and only substantive action** is calling another method with the same parameters. Check: could a caller call the inner method directly without losing anything?
- A **variable appearing in N consecutive method signatures** that is not used by any of the intermediate methods — only by the final one.
- A **façade or wrapper introduced for future extensibility** that has been in place for years and the extension never arrived.

______________________________________________________________________

## E — Execution (Steps)

**(1) Identify the pass-through.**
Read the method body. Does it do anything except call another method? Minor transformations (renaming a parameter, default-filling one argument) count as pass-through. If the body is one line — or several lines that all feed into one call — it is pass-through.

**(2) Apply the different-abstraction test.**
Ask: does this layer provide a different abstraction from the layer it calls? Different means: different vocabulary, different level of detail, different unit of work, added invariants, added error handling. If the abstraction is the same, the layer adds no value.

**(3) If no different abstraction: merge the layers.**
Delete the intermediate class or method. Update callers to use the inner class or method directly. If the inner class is in a different package and visibility was previously hidden by the intermediate layer, adjust visibility accordingly. Run tests.

**(4) If the layers should remain separate: redesign so the upper layer adds something.**
The upper layer must contribute at least one of: input validation, error translation, unit-of-work / transaction boundary, caching, access control, format conversion, or a genuinely simpler interface. If none of these apply, the layer does not belong.

**(5) For pass-through variables: introduce a context object.**
Identify all variables that thread through three or more method signatures without being used by the intermediate methods. Create a context class at the entry point of the call chain. Move the pass-through variables into the context object. Pass the context object as a single parameter. Update every intermediate signature to accept the context object instead of the individual variables. Update the leaf function to read from the context object.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**(1) Dependency inversion for testing.**
A thin adapter layer that wraps a concrete dependency (database driver, HTTP client, file system) may appear to be a pass-through but is justified when it enables interface-based injection for unit testing. The adapter adds a seam even if it adds no runtime logic. Evaluate whether the testing benefit justifies the layer before eliminating it.

**(2) Public API stability during refactoring.**
A pass-through wrapper may be the correct transitional mechanism when the underlying implementation is being replaced and the old signature must remain stable for external consumers. Mark it explicitly as transitional, set a deadline for removal, and delete it when the migration is complete. Do not allow transitional wrappers to become permanent.

**(3) Cross-cutting concerns that cannot easily be inlined.**
Logging, distributed tracing, metrics emission, and retry logic sometimes appear as pass-through wrappers at the call site. These are genuine behaviors even if the core logic is one forwarding call. The test: does removing the wrapper change observable behavior in production? If yes, it is not a true pass-through.

**(4) Clean architecture and hexagonal architecture orthodoxy.**
These architectural styles mandate interface layers at domain boundaries — ports and adapters — that may produce thin pass-throughs at the adapter level. Developers working within these styles should evaluate each adapter consciously: does it translate between two genuine abstractions (external protocol ↔ domain model), or does it merely rename methods? The style does not override the principle; it requires more careful application of it.

______________________________________________________________________

## Related Skills

- **[Information Hiding & Temporal Decomposition](../information-hiding-temporal-decomposition/SKILL.md)** — *composes-with* → Two diagnostics for wrong module boundaries: pass-through = same abstraction at adjacent layers; leakage = design decision appearing in multiple interfaces. Apply both when evaluating a layered design.
- **[Somewhat General-Purpose Interface](../somewhat-general-purpose-interface/SKILL.md)** — *contrasts-with* → S04 addresses insufficient generality (interface mirrors use case — too specific); S05 addresses excessive layering (too many layers with identical abstractions). Both are interface design skills but address opposite failure directions.
