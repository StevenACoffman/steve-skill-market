# Pull Complexity Downward

**Source**: *A Philosophy of Software Design* by John Ousterhout (2018), Chapter 8\
**Skill ID**: pull-complexity-downward\
**Category**: Module Design / Interface Simplicity

______________________________________________________________________

## R — Reading (Original Source)

> "When developing a module, look for opportunities to take a little extra complexity on yourself in order to reduce the complexity of your users... As a module developer, you should strive to make life as easy as possible for the users of your module, even if that means extra work for you. Another way of expressing this idea: it is more important for a module to have a simple interface than a simple implementation.
>
> The most common form of pushing complexity upward is through configuration parameters... Each configuration parameter represents a failure to make a decision: rather than determine the right behavior internally, the module exports the decision to its callers. Is it better to suffer this complexity internally or to export it to callers? In most cases, complexity related to internal mechanisms should be handled internally."

______________________________________________________________________

## I — Interpretation

When complexity is unavoidable, it belongs in the implementation, not the interface.

The principle inverts a common instinct — "give callers control" — and replaces it with a sharper rule: give callers control only when they have information the module cannot access. The decisive question is: *Is it better to suffer the complexity internally or to export it?* The default answer is internally, unless there is a clear reason to export.

Configuration parameters are the canonical mechanism of pushing complexity upward. Every parameter is a decision the module is outsourcing to its callers. If the module already has the information needed to make that decision correctly — from its own state, from context it observes, from sensible defaults — then the parameter is not flexibility; it is complexity transfer.

The test is strict: if the module can derive the right value, it should. If no caller ever passes a value different from the default, the parameter should not exist. Absorbing decisions internally produces shallower interfaces, fewer call-site bugs, and callers who can use the module without understanding its internals.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**1. Network retry interval parameter**\
A network module exposed a retry-interval configuration parameter. The callers had no meaningful basis for setting it — they do not know round-trip time, current congestion, or backoff strategy. The module has all of that information. Exposing the parameter forces callers to guess at values the module could derive precisely, injecting complexity and the possibility of misconfiguration at every call site.

**2. Text class with line-oriented interface**\
A text-editor class that stored text as a collection of lines forced callers to split input on newline boundaries before passing it in. The callers' content is a stream of characters; newline boundaries are an internal artifact of the storage representation. By requiring callers to split on newlines, the module exported a storage detail they should not have known about. The fix: accept arbitrary character sequences and handle boundary detection internally.

**3. Java BufferedInputStream requiring explicit wrapping**\
Java's I/O library separates `InputStream` from `BufferedInputStream`, requiring callers to explicitly wrap any stream to get buffering. Buffering is almost always the right choice; the rare case where it is not is an edge case that does not justify the default complexity. The correct design would buffer automatically and expose an opt-out, not force every caller to opt in by remembering to add a wrapper class.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- A config object or options struct with many fields, especially where most callers leave most fields at their zero value
- A function or constructor parameter whose only purpose is "let the caller decide" and the module could derive the right value from its own state
- Code review comments of the form: "we should expose this so callers can control it" — this is the moment to ask whether callers actually have better information
- A parameter added to avoid a decision: timeouts, buffer sizes, batch sizes, retry counts set to arbitrary "safe" defaults by the caller
- Any time all callers pass the same value to a parameter — the parameter should be eliminated and the value made internal

______________________________________________________________________

## E — Execution (Steps)

1. **Identify the config parameter or caller-provided value.** Name the specific parameter under review. Write down its type, its current default (if any), and every call site that sets it to a non-default value.

2. **Ask: does any caller have information the module does NOT have?** Not "could a caller theoretically have an opinion" — rather, does the caller possess context (user intent, business rules, runtime environment) that is structurally unavailable to the module?

3. **If no: absorb the decision into the module.** Remove the parameter. Implement the decision internally using the module's own state, observed context, or a well-reasoned default. Update all call sites to remove the argument.

4. **If yes: expose the parameter, but only with a sensible default.** The default must be the right answer for the common case. The parameter exists only to accommodate callers with genuinely superior information, not to avoid making a decision.

5. **Test the result.** If all current callers use the same value — whether that is the default or a constant — the parameter should not exist. Eliminate it. A parameter that no caller differentiates is complexity that was never earned.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**Callers have genuine context the module cannot access.**\
User-facing timeout values depend on user expectations and product requirements. A database connection pool size depends on deployment topology. A retry count may encode a business rule about acceptable latency. These are not decisions the module can absorb, because the relevant information lives outside the module's scope and changes per deployment.

**Hiding defaults prevents testing.**\
If a module hard-codes a timer, a batch size, or a threshold, tests cannot exercise boundary conditions without restructuring the production code. In these cases, exposing the parameter with a default preserves testability. The goal is a sensible default that tests can override, not an un-overridable internal constant.

**Pulling down pushes complexity into a shared layer, creating a god module.**\
If "absorbing complexity internally" means a low-level utility must now import business logic, hold application state, or make cross-cutting decisions, the cure is worse than the disease. A shared module that accumulates everyone's absorbed complexity becomes a god object. The rule applies within a layer; it does not license downward coupling across architectural boundaries.

**The decision is legitimately variable by use case.**\
Serialization format, locale, currency precision, log verbosity — these vary in ways no single default can satisfy. Exposing them is not outsourcing a failure; it is providing a necessary extension point. The signal that you are in this case: callers set the parameter to genuinely different values for legitimate reasons, not because the module failed to reason about the right default.

______________________________________________________________________

## Related Skills

- **Deep Module / Classitis Diagnosis (`structural-diagnosis-smells-depth`)** — *composes-with* → Pulling complexity downward is the mechanism for creating depth: absorb complexity into implementation to keep the interface narrow (small top edge in the rectangle model).
- **[Define Errors Out of Existence](../define-errors-out-of-existence/SKILL.md)** — *composes-with* → Both principles relocate unavoidable complexity. Apply define-out-of-existence first (eliminate the error condition); apply pull-complexity-downward to whatever complexity cannot be eliminated (absorb it into the implementation).
