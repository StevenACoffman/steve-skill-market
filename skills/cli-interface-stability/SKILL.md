---
name: cli-interface-stability
description: |
  Use this skill when designing, evolving, or reviewing a CLI tool's public surfaces — flags,
  subcommands, environment variables, config file keys, and exit codes — where backward
  compatibility matters.

  WHEN TO CALL: A user asks (a) whether it is safe to rename, remove, or change the behavior of
  a flag or subcommand; (b) how to deprecate a CLI feature without breaking existing scripts;
  (c) how to design a subcommand namespace that won't box them in later; (d) whether they can
  freely change their program's output format; (e) how to structure machine-readable output for
  script consumers.

  WHEN NOT TO CALL: Do not call when the question is about internal API design (library
  functions, RPCs, HTTP endpoints) — those have their own versioning disciplines. Do not call
  when the user is asking purely about UX aesthetics of a CLI (colors, column widths, help text
  wording) with no concern for scripting consumers.
tags: [cli, api-stability, backward-compatibility, deprecation, versioning]
---

# CLI Interface Stability (CLI Surfaces as Versioned Public APIs)

## R — Original Text (Reading)

> "In software of any kind, it's crucial that interfaces don't change without a lengthy and
> well-documented deprecation process. Subcommands, arguments, flags, configuration files,
> environment variables: these are all interfaces, and you're committing to keeping them working."
>
> "Keep changes additive where you can. Rather than modify the behavior of a flag in a
> backwards-incompatible way, maybe you can add a new flag — as long as it doesn't bloat the
> interface too much."
>
> "Warn before you make a non-additive change. Eventually, you'll find that you can't avoid
> breaking an interface. Before you do, forewarn your users in the program itself: when they
> pass the flag you're looking to deprecate, tell them it's going to change soon. If possible,
> you should detect when they've changed their usage and not show the warning any more."
>
> "Changing output for humans is usually OK. The only way to make an interface easy to use is
> to iterate on it... Encourage your users to use --plain or --json in scripts to keep output
> stable."
>
> — CLI Guidelines, Aanand Prasad et al. (2020)

______________________________________________________________________

## I — Methodological Framework (Interpretation)

A CLI tool's stable interface contract covers exactly these surfaces: **flags** (short and long
forms), **subcommands** (names and their argument signatures), **environment variables**,
**config file keys**, and **exit codes**. Each of these is a public API commitment the moment
a user or script depends on it. The contract does not cover human-formatted output by default.

**The asymmetry of output stability.** Human-formatted output (tables, progress bars, colored
text, summary lines) is safe to change because it is consumed by eyes, not by code. Machine-
readable output — anything produced under `--json`, `--plain`, `--csv`, or similar flags —
becomes a stable contract the moment scripts depend on it, and must be treated with the same
discipline as the flag interface itself. The practical recommendation: encourage all script
authors to use `--json`/`--plain` so that human output remains freely iterable.

**Additive-only as the default change strategy.** When existing behavior must change, prefer
adding a new flag over modifying an existing one. A new flag can coexist with the old one;
the old one continues to work until a deprecation cycle completes. This is only viable if the
total interface size remains manageable — additive changes that meaningfully bloat the surface
should be reconsidered.

**The in-program deprecation cycle.** When a breaking change cannot be avoided, the correct
sequence is: (1) emit a deprecation warning every time the old interface is used, naming what
will change and when; (2) detect when the user has migrated to the new interface and suppress
the warning automatically; (3) remove the old interface only after the warning has been live
for a documented period.

**Namespace preservation.** Two subcommand namespace traps permanently reduce future design
space: (a) making a subcommand implicit (catch-all) means any common program name can never be
added as a subcommand; (b) allowing arbitrary prefix abbreviations means you can never add a
subcommand whose name shares the abbreviated prefix.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: the Catch-All Subcommand Trap (The `echo` Problem)

- **Problem:** A CLI tool makes its most common subcommand implicit — e.g., `mycmd <text>`
  runs `mycmd echo <text>` without requiring the subcommand name. This appears to improve
  usability.
- **Application of the framework:** The implicit form consumes the tool's entire unprefixed
  argument namespace. Any word a user might type as a bare argument is now an ambiguous
  invocation. If the tool later needs a subcommand named `install`, `run`, `help`, or any other
  common word, it collides with existing behavior. The namespace is permanently locked.
- **Conclusion:** Never make a subcommand implicit unless you are certain the tool will never
  need additional subcommands. The usability gain is not worth the permanent loss of namespace
  flexibility.

### Case 2: the Arbitrary Abbreviation Trap

- **Problem:** A CLI tool allows users to abbreviate any subcommand to any unique prefix —
  `mycmd i` runs `mycmd install`, `mycmd ins` also works, and so on.
- **Application of the framework:** Each abbreviation in active use becomes a de-facto stable
  interface. Once scripts rely on `mycmd i` for `install`, the tool can never introduce a
  second subcommand starting with `i` (e.g., `mycmd init`) without breaking those scripts.
  The tool's future subcommand alphabet is permanently constrained by which abbreviations users
  have adopted.
- **Conclusion:** Do not support arbitrary prefix abbreviations for subcommands. If shortcuts
  are desired, define them explicitly as documented aliases with stable names — then they are
  intentional API commitments rather than accidental ones.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A developer has a CLI tool with a `--verbose` flag they want to rename to `--log-level` and
   wonders whether they can simply swap the flag name in the next release.
2. A platform team publishes a CLI for internal use that has grown organically; they want to
   tidy up output formatting for a quarterly release without realizing that downstream scripts
   parse the current format.
3. A developer is designing a new CLI tool and is deciding whether to support `git`-style prefix
   abbreviations for subcommands to improve interactive usability.
4. A developer wants to remove a `--legacy-mode` flag that was a mistake and needs a safe
   removal process that does not silently break existing automation.
5. A developer asks whether it is safe to change the color scheme and column layout of their
   CLI's table output since it "is just cosmetic."

### Language Signals (Activate When These Appear)

- "I want to rename this flag / change this subcommand"
- "Can I change how my CLI formats its output?"
- "How do I deprecate a feature in my CLI?"
- "Will this break existing scripts / automation?"
- "I want to support short-form aliases for subcommands"
- "Can I make the default subcommand implicit?"
- "Designing a long-lived CLI tool" / "public CLI API"
- "We want to clean up our CLI interface"

### Distinguishing from Adjacent Skills

- Difference from `cli-configuration-hierarchy`: cli-configuration-hierarchy covers the
  precedence order (env var overrides config file overrides default). cli-interface-stability
  covers whether you can change the names or semantics of those env vars and config keys at
  all. Both apply simultaneously when evolving a configured CLI.
- Difference from general API versioning: CLI interface stability is more conservative than
  library API versioning because CLIs are often invoked from shell scripts that have no
  equivalent of a lock file or import statement — there is no mechanism for a script to pin to
  a CLI version, so breakage is invisible until it fires in production.

______________________________________________________________________

## E — Execution Steps

1. **Enumerate all stable surfaces of the CLI**

   - List: all flag names (short and long), all subcommand names and their argument signatures,
     all recognized environment variables, all config file keys, all documented exit codes.
   - Completion criteria: a complete inventory exists. If unknown, treat any in-use surface as
     stable until proven otherwise.

2. **Classify the proposed change**

   - Additive (new flag, new subcommand, new config key, new env var): proceed to step 3.
   - Behavioral change to an existing stable surface: proceed to step 4.
   - Removal of an existing stable surface: proceed to step 5.

3. **For additive changes: check namespace safety**

   - Does the new subcommand name conflict with any existing prefix abbreviation that users
     depend on? If yes, reconsider the name or remove the abbreviation support first.
   - Does the new flag name shadow or confusingly overlap an existing flag? If yes, revise.
   - Completion criteria: no namespace conflict. The addition is safe to ship.

4. **For behavioral changes: apply additive-first strategy**

   - Can the new behavior be introduced via a new flag while the old flag retains its original
     behavior? If yes, add the new flag and leave the old one in place.
   - If not, treat it as a removal (step 5) of the old behavior plus an addition of new.
   - Completion criteria: old behavior still works; new flag exists for new behavior.

5. **For removals: execute the in-program deprecation cycle**

   - Step 5a: Emit a deprecation warning in stderr whenever the to-be-removed surface is used.
     The warning must name what is changing, what to use instead, and a timeline.
   - Step 5b: Implement migration detection — if the user also passes the replacement flag/uses
     the new surface in the same invocation, suppress the warning automatically.
   - Step 5c: Document the deprecation in release notes and changelog.
   - Step 5d: After the documented deprecation period, remove the surface.
   - Completion criteria: the warning fires reliably; the warning suppresses when migration is
     detected; the removal is not shipped until the deprecation period has elapsed.

6. **For output format changes: classify the consumer**

   - Is the output consumed by human eyes only? Change is safe.
   - Is the output consumed by scripts (even unofficially)? Treat it as a stable machine
     interface and apply the same deprecation cycle as step 5.
   - Does the tool have a `--json` or `--plain` mode? Encourage script consumers to migrate
     to that mode; the human output format can then change freely.
   - Completion criteria: machine-readable output is not changed without a deprecation cycle;
     human output can be iterated freely.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question concerns internal library function signatures, HTTP API endpoints, or RPC
  schemas — those have their own versioning disciplines and are not CLI surfaces.
- The CLI is purely an internal developer tool with a single team of known users who can
  coordinate a migration synchronously — the formal deprecation cycle overhead may exceed its
  value.
- The CLI is in a pre-1.0 / experimental state where no stability commitment has been made —
  though even then, the namespace traps (catch-all subcommands, prefix abbreviations) should
  be avoided because they are architectural, not just stability, problems.

### Failure Patterns Warned by the Book

- **ce01 (Silent breaking change)**: Renaming or removing a flag, subcommand, or config key
  without a deprecation warning. Scripts that rely on the old interface fail silently or with
  confusing errors. The user has no in-program signal that a migration is needed.
- **ce02 (Catch-all subcommand lock-in)**: Making a common subcommand implicit permanently
  consumes the tool's unprefixed argument namespace. Future subcommand additions whose names
  collide with common program names or user arguments become impossible.
- **ce03 (Prefix abbreviation lock-in)**: Supporting arbitrary prefix abbreviations creates
  invisible stable interfaces for every abbreviation in active use. Adding any subcommand that
  shares a prefix with a popular abbreviation silently breaks existing users.
- **ce04 (Over-stabilizing human output)**: Treating formatted table output, progress bars, or
  summary text as a stable contract prevents any iteration on the human UX. The correct fix is
  to add `--json`/`--plain` and direct script authors there, freeing the human output for
  iteration.
- **ce05 (Time-bomb external dependencies)**: Embedding external URLs or service calls in a CLI
  without acknowledging that the external resource may not exist in 20 years. Unlike a flag or
  subcommand, an external service dependency is not under the tool's control and can break the
  stable interface contract from the outside.

### Author's Blind Spots / Limitations

- The guidelines do not address semver conventions for CLIs — they recommend stable interfaces
  but do not prescribe a versioning scheme that signals to users when a breaking change has
  shipped (e.g., a major version bump). In practice, a CLI without a semver major-version
  signal leaves users with no programmatic way to detect that their scripts need updating.
- The in-program deprecation warning guidance assumes interactive or logged execution. In fully
  automated pipeline environments (CI, cron jobs, orchestration systems), stderr warnings may
  be silently discarded. High-stakes automation environments may need an additional out-of-band
  deprecation notice mechanism (email, changelog feed, etc.).
- The framework treats all five surfaces (flags, subcommands, env vars, config keys, exit
  codes) as equally subject to the same stability contract, but in practice exit codes are the
  most commonly broken surface because they are the least visible during development. The
  guidelines do not provide specific guidance on exit code versioning.

### Easily Confused With

- **Semantic Versioning (semver)**: Semver is a signaling convention for library consumers that
  use package managers with lock files. CLI users typically cannot pin to a semver range —
  the installed binary is whatever version is in their PATH. CLI interface stability requires
  more conservative change management than semver's "breaking changes are OK in major versions"
  rule implies.

______________________________________________________________________

## Related Skills

- **composes-with** → `cli-configuration-hierarchy`: Configuration hierarchy governs how config keys, env vars, and flags interact at runtime; interface stability governs whether their names and semantics may change across versions.
- **composes-with** → `cli-destructive-confirmation-tiers`: Confirmation tier design depends on stable flag names (e.g., `--force`, `--yes`) — changing those flags is itself a stability problem governed by this skill.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Command Line Interface Guidelines" by Aanand Prasad, Ben Firshman, Carl Tashian, Eva Parish (2020, cli-guidelines.github.io) — Future-proofing
