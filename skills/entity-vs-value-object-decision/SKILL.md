---
id: entity-vs-value-object-decision
title: Entity vs Value Object Decision Framework
description: Apply when classifying a new domain type during modeling or code review — specifically when a developer is uncertain whether a struct should have an identity field (UUID), pointer semantics, and mutable state (entity) or value-type semantics, unexported fields, and immutability (value object).
source: Domain-Driven Design with Golang, Matthew Boyle, 2022
---

## R — Reading

> "If you care only about the values of an object, then it should preferably be a value object. Some other questions to ask yourself to ensure a value object is the right choice for you are: Is it possible for me to treat this object as immutable? Does it measure, quantify, or describe a domain concept? Can it be compared to other objects of the same type by its values? If the answers to all these questions are yes, a value object is probably right for your use case. Try and make everything a value object to start with until it does not fit your use case. At that point, it can be upgraded to an entity."

## Chapter 3: Entities, Value Objects, and Aggregates

## I — Interpretation

The three-question framework gives developers a concrete, repeatable decision procedure for the most common modeling ambiguity in DDD. The questions are ordered from most to least obvious: immutability (can we avoid tracking change?), description (does the type measure or describe something about the domain?), and value equality (does identity come from attributes rather than a system-assigned ID?). All three must be yes for a value object classification to hold.

The Go-specific consequence is what makes this framework non-trivial. Answering yes to all three questions does not just change the conceptual label — it changes the implementation axis entirely. A value object in Go is a value-type struct (not a pointer), with unexported fields to prevent external mutation, returned from constructors without `&`. An entity in Go is a pointer-receiver struct with a UUID identity field and exported or mutating methods. The implementation signals to callers whether identity or attributes define equality.

The "start as value object, upgrade to entity" heuristic is a pragmatic inversion of how most Go developers approach modeling. Most engineers default to pointer semantics and public fields, then find themselves unable to enforce immutability later. Boyle's direction — begin with the more restrictive construct and loosen only under domain pressure — avoids the cost of discovering that a mutable type was supposed to be immutable after it has been used throughout a codebase.

The upgrade path is also meaningful: a value object can always be promoted to an entity by adding a UUID field and switching to pointer receivers. The reverse — demoting an entity to a value object — requires finding and removing every site that depended on pointer identity. Starting as a value object therefore minimises future refactoring cost.

## A1 — Past Application

In the CoffeeCo monolith (Chapter 5), Boyle applies the three questions to the `Product` type. Coffee products have fixed names, prices, and sizes that do not change across transactions; a product is fully described by its attributes; two products with the same name and price are the same product in every domain conversation. All three questions pass: immutable? yes. Measures/describes a domain concept? yes (describes a drink on the menu). Value-comparable? yes. The conclusion is a value-type `Product` struct with unexported fields. Boyle explicitly states: "it is better to treat something as a value object and then upgrade it to an entity later, as it's a safer construct to deal with." The CoffeeLover type, by contrast, requires tracking across many purchases and loyalty point accumulations — the identity question fails immediately, so it becomes a pointer-identity entity with a `uuid.UUID` ID field.

## A2 — Future Trigger ★

- A developer proposes a `ShippingAddress` struct with a UUID field "in case we need to track addresses later" — apply the three questions: addresses are immutable per-order, describe a location, compare by value; UUID is premature and the correct type is a value object.
- During code review, a `Money` struct is defined with a pointer receiver on its `Add` method and an exported `Amount` field — this signals entity-like semantics for something that should be a value object; the framework identifies the mismatch and prescribes unexported fields and a value-returning `Add(other Money) Money`.
- A team is modeling an e-commerce `OrderLine` and debates whether two lines for the same SKU and quantity are "the same" — the value-equality question resolves whether `OrderLine` should be value-comparable (no UUID needed) or entity-tracked (UUID required for per-line refunds and cancellations).

## E — Execution

1. Ask question 1: Can this type be treated as immutable throughout its lifetime in the domain? If no, it is an entity.
2. Ask question 2: Does it measure, quantify, or describe a domain concept (rather than represent a tracked participant)? If no, it is an entity.
3. Ask question 3: Can two instances be considered equal if all their attribute values are equal? If no, it is an entity.
4. If all three answers are yes: implement as a value-type struct (no `&` in constructor), unexported fields, `New*` constructor with validation, value receivers only on methods, all methods return new instances rather than mutating state.
5. If any answer is no: implement as a pointer struct, add a `uuid.UUID` ID field, use pointer receivers for mutating methods, encapsulate all invariant-checking within those methods.
6. When uncertain, default to value object and document the promotion trigger (the domain condition that would require identity tracking).

## B — Boundary

Do not apply this framework to types that are clearly infrastructure concerns (database models, HTTP request structs, protobuf-generated types) — those are not domain types and the entity/value object taxonomy does not apply.

The framework assumes a single bounded context. The same concept may correctly be an entity in one context and a value object in another (e.g. `Address` is a value object in Orders but might be an entity in a CRM context that tracks address changes over time). The framework must be applied per-context, not globally.

The "start as value object" heuristic is sound for new code but costly to apply retroactively. If an existing codebase has a mutable type widely depended upon, the upgrade to value object requires coordinated refactoring; the framework does not provide a migration path for that scenario.

Boyle does not discuss the complication introduced when a value object must be persisted to a relational database: ORM libraries (GORM, sqlx) often require exported fields and pointer types for struct scanning. The unexported-field pattern produces an impedance mismatch with these libraries that requires a separate persistence model — a real engineering cost the framework omits.

## Related Skills

- **[ddd-fitness-scorecard](../ddd-fitness-scorecard/SKILL.md)** — prerequisite for: run the scorecard first to confirm DDD adoption is warranted before investing in tactical modeling decisions like entity vs value object.
- **[go-value-object-immutability](../go-value-object-immutability/SKILL.md)** — prerequisite for: once this framework classifies a type as a value object, go-value-object-immutability provides the Go-specific implementation mechanics (unexported fields, value receivers, replacement semantics).
- **[domain-service-interface-composition](../domain-service-interface-composition/SKILL.md)** — informs: the domain types produced by this classification (entity vs value object) become the method signatures in domain service interfaces.
