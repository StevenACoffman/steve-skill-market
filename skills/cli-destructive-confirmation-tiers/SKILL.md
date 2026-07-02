---
name: cli-destructive-confirmation-tiers
description: |
  Use this skill when designing or reviewing the confirmation UX for a CLI command that
  modifies or deletes data, state, or remote resources.

  WHEN TO CALL: A developer is (a) adding a delete, destroy, reset, or purge command to a CLI;
  (b) asking whether a given destructive operation needs a confirmation prompt; (c) designing
  a --force or --yes flag and wants to know whether that is sufficient; (d) asking how to
  prevent users from accidentally triggering an irreversible action while keeping the command
  scriptable; (e) reviewing a CLI command that implicitly destroys resources as a side effect
  of an innocuous-looking change.
tags: [cli, ux, confirmation, destructive-operations, safety]
---

# CLI Destructive Confirmation Tiers

## R — Original Text (Reading)

> "Dangerous" is a subjective term, and there are differing levels of danger: **Mild:** A small,
> local change such as deleting a file. You might want to prompt for confirmation, you might not.
> **Moderate:** A bigger local change like deleting a directory, a remote change like deleting a
> resource of some kind, or a complex bulk modification that can't be easily undone. You usually
> want to prompt for confirmation here. Consider giving the user a way to "dry run" the operation
> so they can see what'll happen before they commit to it. **Severe:** Deleting something complex,
> like an entire remote application or server. You don't just want to prompt for confirmation
> here—you want to make it hard to confirm by accident. Consider asking them to type something
> non-trivial such as the name of the thing they're deleting. Let them alternatively pass a flag
> such as `--confirm="name-of-thing"`, so it's still scriptable.
>
> Consider whether there are non-obvious ways to accidentally destroy things. For example, imagine
> a situation where changing a number in a configuration file from 10 to 1 means that 9 things
> will be implicitly deleted—this should be considered a severe risk, and should be difficult to
> do by accident.
>
> — CLI Guidelines, "Interactivity" chapter

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The tier model maps three levels of destructive severity to three distinct confirmation strategies.
The goal is to match the friction imposed on the user to the actual blast radius of the operation —
not to apply maximum friction everywhere, and not to leave severe operations protected only by a
single --force flag.

## Tier 1 — Mild

- Definition: Small, local, recoverable or easily re-done. Example: deleting a single local file.
- Confirmation strategy: Optional. A prompt is acceptable but not required. If you do prompt, a
  simple y/n is appropriate. Many mature CLIs omit the prompt entirely for mild operations because
  experienced users find it noise.
- Dry-run: Not necessary.

## Tier 2 — Moderate

- Definition: Larger local change (e.g., recursive directory removal), any remote state change
  (deleting a cloud resource, updating a database record), or any bulk non-undoable modification.
- Confirmation strategy: y/n prompt is the norm. The prompt should describe what will be affected.
- Dry-run: Offer a `--dry-run` flag that prints what would happen without executing. This lets
  users verify scope before committing.
- Scripting: Accept a `--yes` or `-y` flag to skip the prompt in non-interactive contexts.

## Tier 3 — Severe

- Definition: Operations with large blast radius and no recovery path — deleting an entire
  application, environment, account, or server; anything that aggregates many resources under one
  command.
- Confirmation strategy: Require the user to type a non-trivial value (typically the resource
  name) at an interactive prompt. This makes accidental confirmation physically difficult — you
  cannot confirm by pressing Enter on a default.
- Scripting: Also accept `--confirm="resource-name"` as a flag equivalent, so automation remains
  possible without interactive TTY.
- Dry-run: Strongly recommended alongside the confirmation gate.

**The implicit-destruction principle**
Severity classification must account for side effects, not just the literal syntax of the command.
A numeric decrement that implicitly removes N resources carries severe risk if N is large. The
tier assigned should reflect the worst-case outcome of the operation, regardless of whether the
destruction is explicit or implicit.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: the Three-Tier Enumeration

- **Problem:** CLI designers often treat all destructive operations identically — either all get
  a y/n prompt, or all require --force, regardless of whether the operation deletes one local
  file or tears down an entire production environment.
- **Application:** The authors establish three named tiers. A file delete is mild — prompt is
  optional. A directory delete or remote resource delete is moderate — y/n prompt plus dry-run
  offer. An entire remote application or server deletion is severe — require typing the resource
  name, and expose `--confirm="name"` for scriptability.
- **Conclusion:** Matching friction level to severity reduces both accidents (severe operations
  are hard to trigger by mistake) and frustration (mild operations are not gate-kept by
  unnecessary prompts).

### Case 2: Non-Obvious Implicit Destruction

- **Problem:** A configuration field accepts a count of running instances. Changing the count
  from 10 to 1 is syntactically a number edit, but semantically destroys 9 instances. A user
  editing a config file might not recognize this as a destructive action.
- **Application:** The authors classify this as severe, not mild or moderate, because the blast
  radius is large and the destruction is permanent. The innocuous appearance of the change (a
  number in a file) is precisely why it needs severe-tier protection — the surface looks safe
  but the consequence is not.
- **Conclusion:** Tier classification must be based on worst-case outcome, not on the syntactic
  form of the operation. Side-effect destruction that is not explicit in the command verb still
  needs to be graded and gated at the appropriate tier.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A developer is adding a `delete` or `destroy` subcommand to a CLI tool and is deciding whether
   to add a confirmation prompt, a --force flag, or some other gate.
2. A developer asks "should I require confirmation before deletion?" or "is `--force` enough for
   this command?"
3. A developer is designing a `deploy --reset`, `app destroy`, or `db wipe` command and wants to
   prevent users from running it accidentally in production.
4. A developer reports that users keep accidentally triggering a bulk-delete or teardown command
   and wants to know how to make it safer.
5. A developer is building a CLI that reconciles declared state to actual state (e.g., a
   Terraform-style tool) and a reduce-count operation implicitly removes resources.

### Language Signals (Activate When These Appear)

- "Should I add a confirmation prompt before this command?"
- "How do I prevent users from accidentally deleting / destroying / wiping?"
- "Is --force the right flag here or do I need something stronger?"
- "Users keep running this command by mistake"
- "How do I make this hard to run accidentally but still scriptable?"
- "Do I need y/n or should I ask them to type the name?"
- "This command deletes everything — how should I protect it?"

### Distinguishing from Adjacent Skills

- Difference from general confirmation UX advice: this skill is specifically about *destructive*
  operations graded by severity. General prompting advice (e.g., asking for input before any
  action) does not include the tier model or the resource-name confirmation mechanism.
- Difference from `cli-secret-handling`: secret handling governs how credentials are passed and
  stored. Confirmation tiers govern how irreversible mutations are gated.

______________________________________________________________________

## E — Execution Steps

1. **Name the operation and its worst-case outcome**

   - List every resource, file, or state change that can result from running the command,
     including implicit side effects (e.g., reconciliation deletions, cascading deletes).
   - Completion criteria: A concrete statement of the form "In the worst case, this command
     permanently deletes/modifies [N resources / the entire X]."

2. **Assign the tier**

   - Mild: single local resource, easily re-created, no remote state.
   - Moderate: multiple local resources, any remote resource, any bulk non-undoable change.
   - Severe: entire application, environment, or account; large-N implicit deletion; no recovery
     path.
   - Completion criteria: One of {Mild, Moderate, Severe} assigned with justification.

3. **Apply the confirmation strategy for the assigned tier**

   - Mild: decide whether a prompt adds value; if yes, use a simple y/n default-no prompt.
   - Moderate: add a y/n default-no prompt describing what will be affected; add `--dry-run`
     support; accept `--yes` / `-y` to allow non-interactive use.
   - Severe: prompt requires the user to type the resource name (not just press Enter or y);
     add `--confirm="resource-name"` flag for scriptability; add `--dry-run` support.
   - Completion criteria: Implementation matches the tier's required pattern.

4. **Check for implicit-destruction risk**

   - Ask: can a change to a numeric or boolean field cause resources to be silently removed?
     If yes, re-evaluate the tier as if the deletion were explicit.
   - Completion criteria: No silent large-N side-effect destruction is classified below Severe.

5. **Verify scriptability**

   - For Moderate: `--yes` or `-y` must bypass the prompt cleanly in CI/automation contexts.
   - For Severe: `--confirm="name"` must bypass the interactive type-to-confirm step.
   - Completion criteria: Automated use cases can invoke the command without a TTY.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The operation is read-only — no data or state is modified. Confirmation UX is irrelevant for
  non-destructive commands.
- The question is about how to word the prompt message or format the output — that is a
  presentation/copy concern, not a tier-design concern.
- The question is about rate-limiting or access control to prevent unauthorized use — those
  are security concerns, not confirmation UX.

### Failure Patterns Warned by the Authors

- **ce01 (Auto-correction without confirmation)**: If you silently run what you think the user
  meant rather than what they typed, you may execute a destructive action they did not intend.
  Invalid input should be rejected with a clear error, not silently corrected into a mutation.
- **ce02 (Over-confirmation / treating everything as Severe)**: Applying maximum friction to all
  destructive operations — including mild ones — degrades the experience of experienced users
  and conditions them to dismiss confirmations as noise. Reserve the hard-to-confirm pattern
  for genuinely severe blast radius.
- **ce03 (--force as the only confirmation mechanism)**: `--force` is a single binary gate with
  no gradation. It provides no dry-run path, no resource-name verification, and no signal to
  the user about severity. Using `--force` alone for severe operations leaves a trivially easy
  path to irreversible destruction.
- **ce04 (Implicit destruction misclassified as mild)**: Classifying a command as mild because
  its syntax looks innocuous (a numeric decrement, a flag toggle) when its semantic outcome is
  large-N resource deletion. Tier assignment must be driven by worst-case outcome, not by
  syntactic appearance.

### Author's Blind Spots / Limitations

- The tier model defines three tiers but provides limited guidance for operations that sit on
  the boundary between Moderate and Severe (e.g., deleting 50 remote resources vs. an entire
  environment). Teams will need to calibrate the boundary based on their specific domain.
- The `--confirm="resource-name"` pattern works well for named resources but has no canonical
  answer for unnamed or dynamically-generated resources. Teams must design a stable identifier
  or summary string for the user to type.
- The framework assumes a human is present for interactive use cases. For fully automated
  pipelines where no human reviews the confirmation, the tier model cannot substitute for
  access-control or policy-based guardrails at the infrastructure layer.

### Easily Confused With

- **--force flag**: --force is a single binary confirmation gate. It is a reasonable shortcut
  for Moderate operations in non-interactive scripts, but it is not a Severe-tier confirmation
  mechanism — it requires no resource-specific knowledge from the user and is trivially
  included in a one-liner.
- **"Are you sure? [y/N]" on all commands**: Uniform y/n prompts regardless of tier fail both
  directions: they add friction to mild operations that don't need it, and they provide
  insufficient protection for severe operations where pressing "y" is still nearly effortless.

______________________________________________________________________

## Related Skills

- **composes-with** `cli-interface-stability`: Confirmation
  tier flags (`--force`, `--yes`, `--confirm`) are stable CLI surfaces; renaming or removing them
  requires the same deprecation discipline as any other stable flag.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Command Line Interface Guidelines" by Aanand Prasad, Ben Firshman, Carl Tashian, Eva Parish — Interactivity — Prompts / Dangerous Actions
