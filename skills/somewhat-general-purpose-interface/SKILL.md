---
name: somewhat-general-purpose-interface
description: |
  Invoke this skill during API design or review when any of the following signals appear: - A method's name includes a UI action or user operation: `backspace()`, `onClickSave()`, `handleDeleteKey()`, `submitForm()`. Names like these reveal that caller context has leaked into the module. The method is not describing what the module does — it is describing why a caller might call it. - The API is growing by accretion: each new product requirement adds a new method to the interface. The method count tracks the feature backlog rather than the underlying capability set. This is the clearest sign of special-purpose drift. - A method is called in exactly one place: if you grep the codebase and a method has a single caller, it probably encodes that caller's specific need. Ask whether the logic belongs in the caller or whether a more general form would serve both current and future callers.
---

# Skill: Somewhat-General-Purpose Interface

**Source**: *A Philosophy of Software Design* by John Ousterhout (2018), Chapter 6 — "General-Purpose Modules are Deeper"

______________________________________________________________________

## R — Reading (Original Source)

> "The sweet spot is to implement new modules in a somewhat general-purpose fashion. The phrase 'somewhat general-purpose' means that the module's functionality should reflect your current needs, but its interface should not. Instead, the interface should be general enough to support multiple uses. ... It turns out that the most important (and perhaps surprising) benefit of a general-purpose interface is that it tends to be simpler than a special-purpose interface. General-purpose interfaces also tend to provide better information hiding. ... The question to ask is: what is the simplest interface that will cover all my current needs? If you reduce the number of methods in an API without reducing its overall capabilities, then you are probably creating more general-purpose methods."

______________________________________________________________________

## I — Interpretation

The "somewhat general-purpose" principle identifies a sweet spot between two failure modes:

- **Too special-purpose (YAGNI taken too far)**: methods are named after specific use cases or UI actions (e.g., `backspace()`, `deleteWord()`). Each new requirement adds a new method. The interface grows fat, the implementation leaks caller context, and lower layers know too much about upper layers.
- **Too general-purpose (over-engineering)**: the interface becomes abstract to the point of being hard to use for any specific task, adding complexity without benefit.

The surprising insight Ousterhout offers: **a more general-purpose interface is often simpler, not more complex.** Fewer, more powerful methods replace a proliferation of narrow ones. Each method does more; callers compose less.

The three-question test is the concrete procedure:

1. **What is the simplest interface that will cover all my current needs?** — forces compression: can you reduce method count without losing capability?
2. **In how many situations will this method be used?** — a method used in only one place is a red flag that it is special-purpose and belongs in the caller, not the module.
3. **Is this interface easy to use for my current needs?** — guards against over-generalization; if the general design makes current callers awkward, it has gone too far.

These three questions work as a triangle: Q1 pushes toward generality, Q2 tests whether generality is real, Q3 catches generality that has become abstraction for its own sake.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

### Case 1: GUI Text Editor — Backspace Vs. Insert/Delete/ChangePosition

The original design mirrors keyboard shortcuts:

```text
backspace()       // delete char to left of cursor
delete()          // delete char to right of cursor
deleteWord()      // delete word to left of cursor
```

Three methods, each encoding a UI gesture. The text class knows about keyboard behavior. Every new shortcut (Ctrl+Backspace, Shift+Delete, etc.) requires a new method.

The general design:

```text
insert(position, text)
delete(start, end)
changePosition(cursor)
```

Three methods still — but now each is more powerful. `delete(start, end)` subsumes `backspace()`, `delete()`, `deleteWord()`, and any future deletion variant. The keyboard-shortcut logic moves to the UI layer, where it belongs. The text class knows nothing about how the editor is operated.

**Why it is simpler, not just more flexible**: the backspace design requires the text class to understand user intent. The general design does not. Fewer concepts live in the lower layer. The interface is narrower even though its power is greater.

### Case 2: Line-Oriented Vs. Character-Range Text Interface

A line-oriented interface exposes operations like `getLine(n)`, `insertLine(n, text)`, `deleteLine(n)`. This reflects how a human edits text in a terminal, but not what text fundamentally is.

A character-range interface exposes `insert(pos, text)` and `delete(start, end)` with positions as character offsets. Lines are just text with newlines; the interface has no concept of line boundaries.

**Why it is simpler**: the line-oriented interface forces the implementation to track line structure even when callers do not need it. The character-range interface has one model — positions in a sequence — and all operations derive from that. Callers who want line semantics compose them from the general primitives. The implementation does not carry the weight of a concept (lines) that belongs in the caller's domain.

In both cases the general design is simpler because **it pushes caller-specific concepts out of the module**. The module's job narrows to a clean, powerful primitive.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill during **API design or review** when any of the following signals appear:

- **A method's name includes a UI action or user operation**: `backspace()`, `onClickSave()`, `handleDeleteKey()`, `submitForm()`. Names like these reveal that caller context has leaked into the module. The method is not describing what the module does — it is describing why a caller might call it.

- **The API is growing by accretion**: each new product requirement adds a new method to the interface. The method count tracks the feature backlog rather than the underlying capability set. This is the clearest sign of special-purpose drift.

- **A method is called in exactly one place**: if you grep the codebase and a method has a single caller, it probably encodes that caller's specific need. Ask whether the logic belongs in the caller or whether a more general form would serve both current and future callers.

- **A reviewer invokes YAGNI to block generalization**: "we don't need that yet." This is the correct instinct for features, but not always for interfaces. When making an interface more general also makes it simpler (fewer methods, each more powerful), YAGNI is the wrong frame. The three-question test resolves the disagreement concretely.

- **The module is a lower-layer service** (storage, text manipulation, networking, data structures): lower layers should expose primitives, not policies. Policy names in lower-layer interfaces are always a trigger signal.

______________________________________________________________________

## E — Execution (Steps)

Apply when designing or reviewing a module's public interface:

**Step 1 — List current use cases.**
Write down every caller and every way it uses the interface today. Be concrete: "the editor calls `backspace()` when the user presses Backspace; it calls `deleteWord()` on Ctrl+Backspace."

**Step 2 — Ask: what is the simplest interface that covers ALL of them?**
Try to reduce the method count. Can two methods be merged into one more powerful method? Can a parameter replace a separate method? The target is the minimum set of operations that, composed by callers, can express every current use case without loss.

**Step 3 — Test: in how many situations will each method be called?**
For each method in your proposed interface, count distinct call sites and distinct calling contexts. A method used in only one place is a candidate for removal — push its logic to the caller or merge it into a more general method. A method used in five different contexts across three modules is pulling its weight.

**Step 4 — Ask: is there a design that is BOTH more general AND simpler?**
This is the key question. If you can reduce method count while maintaining or increasing capability, you have found a better level of generality. If making the interface more general requires adding complexity (more parameters, more edge cases, more documentation), stop — you have crossed into over-engineering.

**Step 5 — Reject any method whose name mirrors a user action or calling context.**
Rename or redesign. `backspace()` becomes `delete(start, end)`. `onUserSave()` becomes `persist(entity)`. `handleDeleteKeyPress()` belongs in the UI layer, not in the service. This rule is a fast filter: if naming the method requires you to reference *why* a caller calls it, the abstraction boundary is in the wrong place.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**1. When generality genuinely adds complexity (serialization formats, DSLs, protocols).**
A JSON serializer and a Protocol Buffers serializer share the abstract concept "serialize an object," but a general interface over both adds indirection, configuration, and edge cases that each specific interface avoids. Domain-specific languages have grammars that resist general-purpose abstraction. In these cases, the three-question test will correctly answer Q3 negatively: the general interface is *not* easy to use for current needs.

**2. When the module is an upper layer, not a lower layer.**
Ousterhout's advice targets lower-layer modules (data structures, text primitives, storage engines, networking). Upper layers — application logic, use-case handlers, UI controllers — are *supposed* to be special-purpose. A `CheckoutHandler` that encodes e-commerce checkout logic should not be generalized into a `TransactionHandler` just because both deal with money. The chapter's insight is about where primitives live, not about making all code generic.

**3. When the "current use cases" are highly varied and the callers are unknown (SDKs, public APIs, frameworks).**
The three-question test relies on Q1: "all my current needs." If the caller set is open — a public SDK, a plugin interface, a framework extension point — there are no "current needs" to anchor the test. Over-generalization is the actual risk here, and the test cannot protect against it because its first premise does not hold. In this context, design by explicit use cases (write three real callers first) rather than by generality.

**4. When the general interface obscures intent for the common case.**
If 95% of callers pass the same arguments and the general form forces them to spell out what the special form would have made implicit, the special form is preferable. The goal is *simplicity at the call site for the common case*, not generality as a terminal value. Ousterhout's warning — "somewhat" general-purpose — is explicit: stop when you have found the level of generality where the interface is simpler, not at maximum generality.

______________________________________________________________________

## Related Skills

- **Deep Module / Classitis Diagnosis (`structural-diagnosis-smells-depth`)** — *composes-with* → A somewhat-general-purpose interface is a technique for achieving depth. Use the depth ratio test (S02) to evaluate whether the generalized interface has achieved a better benefit-to-cost ratio.
- **Pass-Through Method / Wrong Layer Count** — *contrasts-with* → S04 addresses insufficient generality (interface mirrors use case); S05 addresses excessive layering (same abstraction at two levels). Both are about interface design but the failure directions are opposite.
