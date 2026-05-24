# Skill: Write Comments First as a Design Tool

**Source**: *A Philosophy of Software Design* by John Ousterhout (2018), Chapter 15 — "Write the Comments First"
**Skill ID**: write-comments-first-as-design-tool

______________________________________________________________________

## R — Reading (Original Source)

> "I use a different approach to writing comments, which results in better comments and also helps improve the overall system design. I write the comments at the very beginning, as part of the design process."
>
> "If a method or variable requires a long comment, it is a red flag that suggests a design problem."
>
> "If the interface comment for a method is longer than the body of the method, the method is too shallow."
>
> "If you can't write a simple, clear comment describing what a method does, it's a red flag that the method doesn't have a clean design. When you find yourself in this situation, it's better to redesign the method than to write around a complex explanation."

— Chapter 15, *A Philosophy of Software Design*

______________________________________________________________________

## I — Interpretation

Writing interface comments before implementation code inverts the usual workflow — the comment becomes a falsification test for the design. If you cannot write a short, clear interface comment, the interface is wrong.

The comment-length signal works as a diagnostic tool:

- **Long interface comment = complex abstraction (bad)**: the caller must hold too much in their head.
- **Short interface comment + long implementation comment = good abstraction (good)**: the interface is clean; the complexity is hidden inside where it belongs.

This approach treats comments as design feedback, not documentation afterthought. Writing the comment first forces the designer to answer "what is this?" before they answer "how does this work?" — and that ordering disciplines the abstraction itself. A class that cannot be described in one clear sentence probably should not exist as designed. The comment-writing moment is the cheapest possible point to catch an abstraction that is unclear, overloaded, or leaking implementation details.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

1. **Comment-first workflow (Ch. 15)**: Ousterhout describes the sequence as: write the class-level interface comment → write each method's interface comment → write the implementation. The interface comment is written as a design specification, not retrospectively.

2. **Design signal in practice**: When a developer cannot write a concise interface comment, Ousterhout treats this as a trigger to redesign the class, not to write a longer comment. The inability to summarize is the diagnostic, not the symptom to document around.

3. **Comment length as a complexity proxy**: A method whose interface comment is longer than its body is "too shallow" — the overhead of understanding it exceeds the complexity it encapsulates. Conversely, a short interface comment on a long implementation signals that the abstraction is earning its keep.

4. **Commit-message failure mode**: Design decisions recorded only in git commit messages are invisible to future readers of the code. The rationale exists, but it is buried in version history rather than co-located with the abstraction it explains. Interface comments in the source are the durable, co-located record.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when:

- **Starting any new class or interface**: before writing the first line of implementation.
- **In code review**: when a reviewer cannot understand what a module does from reading it, the interface comment is missing or misleading — redesign, do not just annotate.
- **Onboarding a new developer**: if they cannot understand a module by reading its interface comments alone, the comments (and possibly the design) need work.
- **After a refactor changes interface semantics**: the interface comment is now wrong — update it first, then verify the implementation still matches.
- **As a pre-implementation checklist item**: on any pull request, before requesting review, confirm that each new class and each public method has a complete interface comment.
- **When you feel the urge to write a long inline comment inside a method signature**: that urge signals the interface may be too complex.

______________________________________________________________________

## E — Execution (Steps)

1. **Write the class-level interface comment first.** Before any implementation code: what abstraction does this class represent? What does it hide from callers? What invariants does it maintain? What does a caller need to know — and what should they never need to know?

2. **Write each method's interface comment.** For each public method: what does it do (not how)? What are the preconditions and postconditions? What are non-obvious behaviors or edge cases the caller must know about? What does it return on failure?

3. **Apply the length test.** If an interface comment requires more than 3–4 sentences, treat that as a design defect. Redesign the method or class until it can be described concisely. Do not write around a complex abstraction — simplify the abstraction.

4. **Write the implementation, with implementation comments.** Implementation comments explain *why*, not *what*. They capture rationale, constraints, algorithm choices, and non-obvious decisions. They must never leak into the interface comment: callers should be insulated from implementation details.

5. **Revisit interface comments after implementation is complete.** Does the comment still accurately describe the abstraction? Did the implementation reveal that the interface needs to change? If yes, update the interface comment (and possibly the interface) before merging.

______________________________________________________________________

## B — Boundary (When Not to Apply)

1. **Internal helpers with a single caller**: a private function used in exactly one place, in the same file, with an obvious name, may not need a formal interface comment. The cost exceeds the benefit when there is no interface boundary to protect.

2. **Expressive type signatures in statically typed languages**: when a function signature carries full information — parameter names, return type, and a well-named identifier — a short type signature may replace some of what a comment would say. Comments should add information not already present in the types, not restate them.

3. **Throwaway scripts and prototype code**: code with a known lifespan of hours or days does not justify the overhead. Apply the practice where the code will be read, maintained, or extended by others (including your future self).

4. **Purely mechanical getters/setters with no behavioral contract**: a getter that returns a stored field and has no side effects, preconditions, or surprising behavior may not need an interface comment beyond the field name. The practice targets abstraction boundaries, not boilerplate accessors.

______________________________________________________________________

## Related Skills

- **Strategic vs. Tactical Programming (`design-stamina-strategic-investment`)** — *enabled-by* → Comments-first produces no immediate feature output. It is a strategic investment in design clarity. Without the strategic mindset, this skill is abandoned as "documentation overhead."
- **[Design It Twice](../design-it-twice/SKILL.md)** — *preceded-by* → Design-it-twice selects the interface structure; comments-first verifies the chosen design can be described simply. Apply design-it-twice first to select between alternatives, then use comments-first on the winner.
- **Deep Module / Classitis Diagnosis (`structural-diagnosis-smells-depth`)** — *depends-on* → The comment-length signal ("long interface comment = bad abstraction, short interface + long implementation = good") requires understanding what module depth means. Deep module evaluation provides the vocabulary to read this signal correctly.
