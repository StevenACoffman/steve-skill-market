---
name: go-value-object-immutability
description: |
  Apply when implementing a DDD value object in Go — specifically when deciding on field visibility, constructor shape, method receiver types, and return semantics for any type classified as a value object (immutable, value-comparable, describes a domain concept).
---
# Go Value Object Immutability via Unexported Fields and Value-Type Structs

## R — Reading

> "Notice how, in the point class, x and y are lowercase? This is to stop them from being exported and mutated. It is recommended that value objects remain immutable to prevent any unexpected behavior... The point here is a description of our player's location. We can take advantage of the replaceability of the value object to update the point representing a player's position to be a completely new value every time we move. In this specific instance, you'll also notice that the move function is side effect free. This is something we should strive toward as part of immutability. By following the principles of immutability and side-effect-free functions, we have made our value objects easier to reason about and to write unit tests for."

## Chapter 3: Entities, Value Objects, and Aggregates

## I — Interpretation

Go's type system provides a concrete enforcement mechanism for value object immutability that DDD's original formulation (in Java and C++) lacks: unexported fields. When a struct's fields are unexported (lowercase), no code outside the defining package can read or write them directly. This converts immutability from a convention ("please don't mutate this") into a compile-time guarantee ("you cannot mutate this without going through the defined API").

The value-type versus pointer-type distinction carries a second implication: value equality. In Go, two values of the same struct type are equal via `==` if and only if all their fields are equal — but only when those values are not pointers. Two `*Point` values with identical coordinates are not equal because pointer equality checks memory address, not field content. By returning a value-type `Point` from the constructor (no `&`), the author encodes "equality means same attributes" directly into the type's semantics. Any consumer can compare two `Point` values with `==` and get the correct domain answer without needing a custom `Equal` method.

The replaceability pattern — returning a new instance from every method rather than mutating the receiver — is the Go-idiomatic expression of Evans's replaceability principle. A `move(currLocation Point, direction int) Point` function receives the current location by value, cannot modify it, and returns a new location. The caller reassigns: `currLocation = move(currLocation, directionNorth)`. This pattern makes it impossible to have a stale reference to a previous location, because the previous location value is never modified — a new value is substituted. The resulting code is trivially testable: any function that takes a value object as input and returns a new one has no observable side effects and requires no mocking.

Value receivers (not pointer receivers) on methods enforce the pattern at the language level. A method with signature `func (p Point) Translate(dx, dy int) Point` can only access the value it was given; it cannot modify `p` and have that modification observed by the caller. Using a pointer receiver on a value object method is a design smell — it signals that the method might mutate state, which contradicts the immutability contract.

## A1 — Past Application

In Chapter 5, Boyle implements the `Product` value object for CoffeeCo after the three-question framework confirms it is not an entity. The `Product` struct uses unexported fields for name, price, and size — none are accessible outside the `purchase` package except through the constructor and accessor methods. The `NewProduct` constructor takes all required fields, validates them, and returns a `Product` value (not a `*Product`). This means two `Product` values describing the same drink are equal under `==` without any custom comparison logic, and no consumer can accidentally set a product's price to zero by modifying an exported field. The `Product` type has no mutating methods; any operation that would "change" a product produces a new `Product` value instead. Boyle contrasts this with the `CoffeeLover` entity, which has exported fields (FirstName, LastName, EmailAddress) that may be updated through the entity's lifetime.

## A2 — Future Trigger ★

- A developer writes a `Money` struct with an exported `Amount float64` field and a pointer receiver on the `Add` method — this is the canonical anti-pattern: exported field defeats immutability enforcement, pointer receiver signals mutation intent; apply this skill to correct both.
- Code review shows `func (p *Point) Move(dx, dy int)` that modifies `p.x` and `p.y` in place — value object methods must be side-effect-free; correct to `func (p Point) Move(dx, dy int) Point` returning a new instance.
- A `Color` type (RGB value object) returns `*Color` from its constructor and two `Color` values with the same RGB fail equality checking — the fix is to return `Color` (not `*Color`) from `NewColor`; value-type semantics restore `==` equality.

## E — Execution

1. Declare all fields of the value object struct with lowercase names (unexported): `type Money struct { amount int; currency string }`.
2. Write a `New*` constructor function that takes all required fields, validates them, and returns the value type without `&`: `func NewMoney(amount int, currency string) (Money, error)`.
3. Write all methods with value receivers, not pointer receivers: `func (m Money) Add(other Money) Money`.
4. All methods that would "modify" the value object must return a new instance — never use `m.amount = newAmount` inside a method.
5. If equality via `==` is required in tests or application logic, verify that the struct contains only comparable field types (no slices, maps, or pointers as fields); if it does, the struct will support `==` automatically.
6. For JSON marshaling or ORM persistence, write a separate persistence model struct with exported fields and an `Unmarshal` / `toDomain` adapter — never export the value object's fields to satisfy infrastructure requirements.

## B — Boundary

Unexported fields prevent external mutation but do not prevent the package itself from mutating an instance. Within the defining package, a function could write to an unexported field. The enforcement mechanism protects against callers outside the package, not against careless code within it.

The value-type-only pattern has a performance implication for large value objects. A struct with many fields will be copied on every method call and every assignment. For very large value objects (many fields), this copy cost can be measurable. In practice, domain value objects are rarely large enough for this to matter, but for high-throughput hot paths it should be considered.

The `==` equality shortcut works only when all struct fields are comparable types. A value object that contains a slice field (e.g. `Tags []string`) is not directly comparable with `==` and requires a custom `Equal(other T) bool` method. Boyle's examples use only primitive field types; this limitation is not discussed.

Boyle's own `Point` constructor returns `*Point` initially (the failing version) before switching to `Point` (the correct version). The initial version is easy to write by habit and the mistake is invisible until a test fails. Teams should enforce the value-type return in code review or a linting rule rather than relying on developers to remember.

The immutability pattern complicates some standard Go idioms: JSON unmarshaling via `json.Unmarshal` writes to exported fields, and database scanning with `sqlx` also requires exported or settable fields. Adopting this pattern requires a deliberate infrastructure adapter layer — which the book acknowledges but does not demonstrate in detail.

## Related Skills

- **entity-vs-value-object-decision** — depends on: this skill implements what the decision framework classifies; always run entity-vs-value-object-decision first to confirm a type is a value object before applying these Go immutability mechanics.
- **domain-service-interface-composition** — informs: value objects are the primary domain types passed through domain service interfaces; the immutability and value-equality properties established here affect how interface method parameters and return types are designed.

______________________________________________________________________

## Provenance

- **Source:** Domain-Driven Design with Golang, Matthew Boyle, 2022
