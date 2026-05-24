# Define-Errors-Out-of-Existence

**Source**: *A Philosophy of Software Design* by John Ousterhout (2018), Chapter 10\
**Skill ID**: define-errors-out-of-existence

______________________________________________________________________

## R — Reading (Original Source)

> "The best way to deal with special cases is to design them out of existence. Rather than defining exceptions for special cases and then requiring callers to handle the exceptions, define the operations in a way that makes the special cases go away. The Tcl `unset` command provides a good example. The original implementation of `unset` throws an error if the variable doesn't exist; this requires callers to check whether the variable exists before calling `unset`. In the new approach, `unset` doesn't throw an exception if the variable doesn't exist; instead, it simply does nothing. The new definition is: 'the `unset` command guarantees that the variable will not exist after the call.' With this definition, there is no exception if the variable doesn't already exist: the postcondition is already satisfied."

______________________________________________________________________

## I — Interpretation

The procedure is not about better exception handling — it is about contract redesign. Ousterhout argues that most error conditions are not inherent to the problem domain; they are artifacts of how an operation was specified. When you encounter an error case, the first question is not "how should I handle this?" but "does this error need to exist at all?"

The methodology works by reframing what a function *promises*. Instead of specifying what an operation does to a specific input, you specify what state the system guarantees after the call. This postcondition framing frequently eliminates the error entirely: if the caller's intent is "ensure X is gone," then "X was never there" is already a success, not an exception.

This changes how a developer approaches error design in two concrete ways. First, it shifts the unit of work from input-validation thinking ("what is the caller sending me?") to outcome thinking ("what does the caller actually need to be true afterward?"). Second, it redistributes complexity: instead of every caller defensively checking preconditions, the operation itself absorbs and resolves the ambiguous case. The result is fewer code paths at every call site, which compounds — every caller that no longer needs a guard clause is simpler, and simpler callers are easier to reason about and test.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

1. **Shell scripting / variable management** — Tcl `unset`: redesigned from "delete this variable (error if absent)" to "guarantee this variable does not exist after the call." Callers no longer need a prior `exists` check. Entire class of defensive preambles disappears.

2. **Operating system / file system** — Unix file deletion while a process holds an open file descriptor: instead of throwing an error or blocking, the OS removes the directory entry immediately and lets the process keep its fd until it closes the file. The caller (deleting process) never sees an error; the kernel masks the conflict by deferring the actual inode removal.

3. **Standard library / string processing** — Java `String.substring(startIndex, endIndex)` where `endIndex` exceeds string length: rather than throwing `OutOfBoundsException`, redefine the behavior as "return the substring up to the actual end of the string" (returning an empty string if `startIndex` is also out of range). The common caller intent — "give me up to N characters" — is satisfied without an exception branch.

4. **Distributed systems / network storage** — NFS server unreachability: rather than propagating a network error to the application, the NFS client masks it by retrying indefinitely until the server recovers. The file system layer absorbs the transient failure; applications calling `read()` or `write()` never see it. The error is masked rather than defined away, but the outcome for callers is the same: no exception to handle.

5. **Web application / request handling** — HTTP server exception aggregation: rather than every request handler declaring and propagating its own exception types, a single top-level dispatcher catches all unhandled exceptions and maps them to appropriate HTTP status codes. Individual handlers are written without exception declarations; the complexity is aggregated to one location rather than distributed across hundreds of call sites.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when:

- You are writing a function and find yourself adding a parameter-validation block that throws when the input is "already in the desired state" (e.g., deleting something that doesn't exist, setting something to its current value, inserting a duplicate into a set).
- You are reviewing a call site that begins with `if (exists) { delete }` or `if (!initialized) { initialize }` — defensive checks that exist only to avoid an exception the callee would throw.
- A code review surfaces that callers must call function A before function B or catch an exception — ordering requirements that could be absorbed into the function's own contract.
- You are designing a new API and instinctively adding "throws X if Y" clauses to the spec — pause before committing those to the interface.
- An exception is propagating across multiple layers and none of the intermediate layers can do anything useful with it — the error exists only because a lower layer defined it into existence.
- You encounter a boolean flag or nullable return specifically to signal "the thing you asked about didn't exist" — a signal that the caller is doing work that the callee could absorb.

Pain-point signals: widespread try/catch boilerplate, defensive precondition checks duplicated at every call site, callers who always catch and ignore a specific exception.

______________________________________________________________________

## E — Execution (Steps)

1. **State the caller's actual intent as a postcondition.** Ask: "What does the caller need to be true *after* this call completes?" Write that as a sentence. (Ousterhout's diagnostic question: "Does this error condition even need to exist, given what the caller is trying to accomplish?")

2. **Check whether the error is already a no-op.** If the postcondition is already satisfied before the operation runs (e.g., the variable is already absent, the item is already removed), the operation can return success silently. If yes: rewrite the contract to state the postcondition rather than the input precondition, and remove the exception.

3. **Check whether the error can be masked internally.** If the error is transient or resolvable within the module (e.g., retry logic, lazy initialization, default fallback), handle it inside the function rather than surfacing it. Only surface errors the *caller can actually act on*.

4. **Check whether multiple similar exceptions can be aggregated.** If several related operations throw distinct exceptions that all mean "something went wrong in this subsystem," replace them with one exception type at a higher abstraction layer. Callers bind to the aggregate, not the internals.

5. **Rewrite the function's documented contract** to reflect the new postcondition. The signature may not change, but the spec must explicitly state the new behavior for the formerly-exceptional input.

6. **Delete the call-site guard clauses** that existed only to avoid the now-eliminated exception. Verify that callers are simpler. If a caller still needs conditional logic after the redesign, that is a signal the error was not fully eliminated — return to step 1.

______________________________________________________________________

## B — Boundary (When Not to Apply)

1. **You do not own the contract.** If the function is part of an external API, a published interface, an industry standard (HTTP, SQL, POSIX), or a library you cannot modify, you cannot redefine its postconditions. You can wrap it and mask errors in your own layer, but the principle's primary technique — changing the spec — is unavailable. Ousterhout does not address this case; he writes as if the designer always controls the interface.

2. **The error signals a condition the caller must distinguish.** If different callers need to take materially different actions based on what went wrong — not just "something failed" but "it failed *in this specific way* that requires a specific recovery path" — collapsing the error out of existence loses information the caller legitimately needs. Aggregation and masking are wrong here; an explicit, well-typed exception is the right tool.

3. **"Crash" is underspecified and dangerous to apply broadly.** Ousterhout lists crashing as a valid response for "truly unrecoverable" errors but provides no rigorous definition of that threshold. In practice, what is unrecoverable depends heavily on context: a corrupted config file is unrecoverable in a CLI tool but recoverable (reload from backup) in a server. Applying "just crash" without this analysis risks turning recoverable errors into outages. The technique requires domain-specific judgment that the book does not supply.

4. **Masking can hide bugs.** Indefinite retry (the NFS example) is appropriate only when the underlying failure mode is genuinely transient and the system has a path to recovery. Applied to a logic error or a permanently broken dependency, masking produces a system that hangs silently rather than failing visibly. The principle assumes you can distinguish "temporary external condition" from "programming error" — that distinction requires telemetry and careful design that the chapter does not discuss.

5. **Postcondition redesign can weaken safety invariants.** Returning an empty string for an out-of-bounds substring is convenient, but it can also silently swallow bugs where the caller computed the wrong index. In high-stakes domains (financial calculations, security checks, data integrity pipelines), the original exception may be the correct behavior because silent wrong results are worse than a loud failure. Define-out-of-existence trades explicitness for convenience; that trade-off is not always correct.

______________________________________________________________________

## Related Skills

- **[Pull Complexity Downward](../pull-complexity-downward/SKILL.md)** — *composes-with* → Both relocate unavoidable complexity. Apply this skill first: can the error condition be eliminated entirely? If yes, no caller-side handling is needed. If no, apply pull-complexity-downward: absorb the error handling into the module's implementation rather than exposing it to callers.
