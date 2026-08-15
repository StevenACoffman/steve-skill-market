---
name: unconventional-commits
description: |
  Use when writing git commit messages, committing changes, or setting a project's commit convention — especially when the user wants scope-first (Linux/Git/Go/kernel-style) commits and explicitly wants to AVOID Conventional Commits (no `feat:`/`fix:`/`chore:` type prefixes). Triggers on "write a commit message", "commit this", "/commit", "what should the commit say", or any request to define commit guidelines where the user rejects the `type:` prefix style. Produces `scope: description` subject lines plus a body explaining what and why. Prefer this over the conventional `git-commit` skill whenever the user signals they dislike Conventional Commits, wants scoped commits, or points to a scope-prefixed project style.
allowed-tools: Bash
---

# Unconventional Commits

Write commit messages that put the **area of the codebase first** and explain the
**why** in prose — the style used by Linux, Git, Go, FreeBSD, and nixpkgs. This is a
deliberate rejection of Conventional Commits (`feat:`, `fix:`, `chore:` …). The
reasoning below matters as much as the format, because it tells you what to do when a
case is ambiguous.

## The core idea: scope over type

A commit's **scope** (what area changed) is the thing people actually search on.
Contributors scanning history, debuggers bisecting a regression, and incident
responders scanning commits around an outage all ask "what part of the system did
this touch?" — never "what *category* of change was this?". A change to the auth
subsystem is interesting during an auth outage whether it was labelled a feat, a fix,
or a refactor.

Conventional Commits inverts this: it makes the **type** mandatory and up front, and
the **scope** optional and second. That is backwards. So:

- **Lead with the scope**, and treat it as required, not optional.
- **Drop the type prefix entirely.** A well-written description already implies whether
  something was added, fixed, or refactored. The type label wastes scarce subject-line
  characters, and it forces a false choice on changes that are genuinely a fix *and* a
  refactor *and* a feature at once.

## Subject line format

```text
scope: imperative description of the change
```

- **scope** — the natural unit for *this* project. Pick whatever a maintainer would
  recognize: a subsystem (`sched:`), a package path (`net/http/cookiejar:`), a
  component (`auth:`), a service name, or a file/module. If a change is genuinely
  cross-cutting, pick the most affected area rather than inventing a vague catch-all;
  if it truly spans the whole tree, split the commit (see "Make commits atomic").
- **description** — the change itself, following these long-standing rules:
  - Use the **imperative mood** ("Add", "Fix", "Remove" — not "Added"/"Adds"). A commit
    describes what applying it *does* to the tree.
  - Keep the whole subject to roughly **50 characters**; hard-limit around 72.
  - No trailing period.
  - Capitalization of the description follows the project's existing history — match
    what's already there rather than imposing a rule.

## Body: explain what and why, not how

Separate the subject from the body with a **blank line**, and **wrap the body at ~72
characters**. The diff already shows *how* the code changed; the body exists so a future
developer understands *what* changed and *why* it needed to. Cover the motivation, the
problem being solved, and any consequences a reader should know — especially anything
that breaks or that other people need to react to. Short, obvious commits can skip the
body; anything non-trivial deserves one.

For a change that removes or breaks something, say plainly in the body what breaks, whom
it affects, and what they should do — this is far more useful than a machine-parseable
`BREAKING CHANGE:` token, and it's aimed at the humans who'll hit the breakage.

## Make commits atomic

Prefer several small, self-contained commits over one large blob. If a feature took
three logical steps, three commits — each one a coherent, reviewable change with its own
scope and reasoning — produce a history that is far easier to read, bisect, and revert
than a single mega-commit. This does more for discoverability than any prefix convention.

## What this style deliberately does NOT do

These follow from the same reasoning and are worth stating so you don't drift back into
Conventional-Commits habits:

- **Don't auto-generate changelogs from commits.** A changelog is *user*-facing and
  describes functional/business impact between releases; a commit log is *developer*-facing
  and tells the story of the code. They have different audiences and different grains.
  Keep release notes as a separate, curated artifact (from the PR/merge description),
  and don't contort commit messages to feed a changelog generator.
- **Don't drive CI/CD or version bumps off the commit *type*.** Trigger builds, tests,
  and publishes off the **diff** (which files/packages actually changed) — it's more
  reliable and can't be spoofed by a mislabeled `docs: fix typos` that actually touches
  auth. Type-based semver bumping also breaks on reverts and on breakage discovered after
  the fact.
- **Don't enforce a commit linter that rejects *contributions*.** Guide with examples, not
  gates. Rigid linters value style over content and turn away people who care about the
  code. If you need uniformity in the mainline, squash a PR into the house style yourself
  rather than demanding contributors learn a non-portable convention. This is about not
  gatekeeping *other people's* commits — it says nothing against an author running a linter
  over their *own* message as a private self-review before committing (see below).

## Polish the message with Vale + vale-ai-tells

A scope-first subject and a why-focused body get the *structure* right. The remaining
failure mode — especially for AI-assisted commits — is the *prose*: hollow filler
("This commit refactors…"), throat-clearing, hedging, and the tell-tale phrasings that
mark machine-written text. The [`vale-ai-tells`](https://github.com/StevenACoffman/vale-ai-tells)
package ships a dedicated `ai-tells-commits` style: 13 rules purpose-built for commit
messages, kept separate from the prose rules so you can lint messages without dragging
those checks into your docs.

Treat this as the author's own **self-review**, not a gate on anyone else — that is fully
consistent with the "don't gatekeep contributions" point above. The loop is: write the
message to a scratch file, lint it, fix what's real, then commit from that file.

```bash
# Draft the message in a scratch dir that has a .vale.ini using ai-tells-commits
# (see the vale-cli skill for how to build that config and install the package).
$EDITOR "$SCRATCH/COMMIT_EDITMSG.md"
# --no-global is essential: without it Vale merges your global config and its
# styles (Readability, spelling, etc.) leak in and bury the commit-specific alerts.
vale --config="$SCRATCH/.vale.ini" --no-global "$SCRATCH/COMMIT_EDITMSG.md"
# ...address genuine alerts, re-run until clean...
git commit -F "$SCRATCH/COMMIT_EDITMSG.md"
```

For the exact install and config steps — installing Vale itself, discovering the latest
`vale-ai-tells` release, and the `Packages =` / `BasedOnStyles = ai-tells-commits`
settings — follow the **`vale-cli`** skill (reference/setup) and the **`vale`** skill
(the lint-and-fix workflow, including its commit-message section). Apply the same triage
judgement Vale always needs: fix the real smells, and suppress or ignore false positives
rather than mangling an accurate message to satisfy a rule.

## Optional: sign-off

If the project uses the Developer Certificate of Origin, commit with `git commit --signoff`
to append a `Signed-off-by:` trailer.

## Workflow

When asked to write a commit:

1. **Look at the actual change** to determine scope and write an honest description:
   ```bash
   git diff --staged   # or the working-tree diff if nothing is staged
   git status
   ```
2. **Check the project's existing convention** so your scope vocabulary and capitalization
   match what's already there — the right scope is almost always self-evident from history:
   ```bash
   git log --oneline -20
   ```
3. **Choose the scope** from that project's natural unit (subsystem / package / component).
4. **Write the subject** as `scope: imperative description`, ≤50 chars, no type prefix.
5. **Add a body** (blank line first, wrapped ~72) explaining what and why, when the change
   is non-trivial or has consequences.
6. If the work is really several logical changes, **propose splitting it** into atomic
   commits rather than composing one prefix-tagged blob.
7. **Optionally lint the drafted message** with Vale's `ai-tells-commits` style to catch
   AI-tell phrasing and prose filler before committing (see "Polish the message with Vale
   + vale-ai-tells" above). This is especially worthwhile for AI-generated messages.

## Examples

**Example 1 — simple, scope is a package path**
Change: added godoc links to the cookiejar package
```text
net/http/cookiejar: add godoc links
```

**Example 2 — bugfix, no type label needed (the description says it's a fix)**
Change: SVG `<style>` elements in namespaces were being stripped by the compiler
```text
compiler: prevent namespaced SVG <style> elements from being stripped
```

**Example 3 — a change that's a fix + refactor + feature at once**
Conventional Commits would force you to pick one type; here you just name the area.
```text
core/webmcp: support both document.modelContext and navigator.modelContext

The previous code only read navigator.modelContext, so pages that set the
context on the document silently got no model. Read both, preferring the
document form when present.

This changes the resolution order for callers that set both; see the
migration note in docs/webmcp.md for how to keep the old behaviour.
```

**Example 4 — subsystem scope, imperative subject**
```text
i2c: virtio: mark device ready before registering the adapter
```

## Why this exists (for when you have to justify it)

Conventional Commits promises semantic, machine-readable history but in practice
prioritizes the least useful field (type), makes the most useful field (scope) optional,
tends to *shorten* messages because the format feels like it already conveyed meaning,
and adds contributor friction for benefits (changelog generation, semver, CI triggers)
that are better served other ways. Scope-first commits — proven at scale by Linux, Git,
Go, FreeBSD, and nixpkgs — keep the history readable by the humans who actually dig
through it.
