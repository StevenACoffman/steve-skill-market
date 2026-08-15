---
name: webapp-review
description: |
  Use to review a github.com/Khan/webapp pull request end to end: scope the diff
  from the merge base with the deploy branch, judge it against the Go advice plus
  webapp's overriding rules, polish the write-up with `rumdl` and vale, and post the
  file-and-line findings as inline GitHub review comments.

  Trigger signals:
  - "review PR <n> in webapp"
  - "review the changes on <branch> from the merge base of <deploy branch>"
  - "post that review as comments on the PR"
  - Any webapp code review that should end up on GitHub rather than in chat
allowed-tools: Bash, Read, Edit, Write
---

# Webapp Pull Request Review

> **Scope:** `github.com/Khan/webapp` only. The rule sources, linters and deploy
> branch conventions referenced here are webapp-specific.

Four stages. Do not skip to posting: the wording rewrite in stage 2 is what makes
the comments useful to a reader who has never seen the rule documents.

## Placeholders

| Placeholder          | Meaning                                     | Example                                               |
| -------------------- | ------------------------------------------- | ----------------------------------------------------- |
| `$REPO`              | Local webapp checkout                       | `~/khan/webapp`                                       |
| `$PR_NUM`            | Pull request number                         | `41145`                                               |
| `$HEAD_BRANCH`       | Branch under review                         | `local-roster-db-script`                              |
| `$BASE_BRANCH`       | Deploy branch the PR targets                | `deploy/timmcca-be`                                   |
| `$GO_ADVICE`         | General Go advice document                  | `~/Documents/agent-orange/go-advice/summary_rules.md` |
| `$WEBAPP_EXCEPTIONS` | Rules that override the above               | `~/Documents/agent-orange/.../skills/webapp/RULES.md` |
| `$LINT_REPO`         | Repo whose `rumdl` and vale config to reuse | `~/Documents/git/canonizer`                           |
| `$SCRATCH`           | Temporary directory for the write-up        | session scratchpad                                    |

## Stage 1: Scope and Read the Diff

Prompt template:

> In `$REPO` I have run `gh pr checkout $PR_NUM` and I would like you to review
> the changes on the `$HEAD_BRANCH` branch from the merge base (and deploy
> branch) of `$BASE_BRANCH` using the advice in `$GO_ADVICE` with the exceptions
> for the webapp repository specified in `$WEBAPP_EXCEPTIONS`.

Verify the premise before trusting it. `gh pr checkout` can leave a different
branch checked out than the one named, and both branches must exist:

```bash
cd $REPO
git branch --show-current
git ls-remote --heads origin $HEAD_BRANCH $BASE_BRANCH
gh pr list --state all --head $HEAD_BRANCH --json number,state,baseRefName,url
```

Scope from the merge base, never from the base branch tip, or the diff will
include unrelated deploy commits:

```bash
MB=$(git merge-base origin/$BASE_BRANCH origin/$HEAD_BRANCH)
git log --oneline "$MB"..origin/$HEAD_BRANCH
git diff --stat "$MB"..origin/$HEAD_BRANCH
```

Separate hand-written files from generated ones, and use `--name-status -M` so
renames are visible:

```bash
git diff --name-status -M "$MB"..origin/$HEAD_BRANCH -- ':!*/generated/*'
```

Read whole files rather than diff hunks where a file is new: reviewing a hunk in
isolation hides ordering bugs. Read both rule documents in full before judging.

```bash
git show origin/$HEAD_BRANCH:path/to/file.go
```

**Pitfall:** `git show branch:path` fails if you use a path the change renamed. Get the current paths from `--name-status -M` first.

Read `$WEBAPP_EXCEPTIONS` carefully. It inverts several defaults, so a finding
based on general Go advice alone may be wrong here. Common inversions: testify
via `khantest.Suite` is required, `fmt.Errorf` and stdlib `errors` are banned,
`sync.WaitGroup` and `errgroup` are banned in favour of `tracegroup`, role-based
`models/` and `resolvers/` packages are enforced rather than discouraged,
resolvers must carry an explicit permission check, and time comes from
`ctx.Time()`. Also remember `fmt.Print*` is legitimate inside `cmd/` scripts.

Verify claims against the source before asserting them. If a finding depends on
whether a SQL query is scoped or idempotent, open the query.

## Stage 2: Rewrite for a Reader Who Has Not Read the Rules

Prompt template:

> The reader will not be familiar with my RULES.md or summary_rules.md documents
> or principles, so the review should be altered to have a terse justification
> instead of references.

Replace every citation with the reasoning it stands for.

| Instead of               | Write                                                                     |
| ------------------------ | ------------------------------------------------------------------------- |
| "violates §4 Repetition" | "this block is spelled out twice; naming it once removes the duplication" |
| "see RULES.md Rule 6"    | "a service importing another service fails `ka-import`"                   |
| "§15 be consistent"      | "the other three scripts do X; this one does Y"                           |

Keep linter names and real symbols. A reader can act on those. Drop document
names, section numbers and rule numbers.

Order findings by cost to the reader rather than by discovery order. Keep what is
worth fixing apart from what is minor. Mark any finding that rests on something
unverified, and set it aside for the confidence gate below rather than hedging it
into the review.

## Stage 3: Format and Lint the Write-Up

Prompt template:

> Write that review to a temporary markdown file, run `rumdl fmt` on it with the
> same rules I use in `$LINT_REPO`, then vale with the same configuration, and
> make improvements.

```bash
rumdl fmt   --config $LINT_REPO/.rumdl.toml $SCRATCH/pr-$PR_NUM-review.md
rumdl check --config $LINT_REPO/.rumdl.toml $SCRATCH/pr-$PR_NUM-review.md

# vale resolves StylesPath relative to the config, so run from that repo
cd $LINT_REPO && vale --config $LINT_REPO/.vale.ini --minAlertLevel=error \
  $SCRATCH/pr-$PR_NUM-review.md
```

**Pitfall:** the `rumdl` `MD063` rule title-cases headings, which mangles proper nouns.
A branch name in an H1 becomes nonsense such as `Local-Roster-Db-Script`. Check
the H1 after formatting and move identifiers into code spans or body text.

Triage vale rather than obeying it:

- **Genuine smells, fix them.** Em-dashes, three-verb series, semicolon splices,
  hollow openers. Tightening these improves the review.
- **Real identifiers, wrap in code spans.** `kaid`, `worktree`, `snake_case`.
  Vale skips code spans, and they should be marked up as code anyway.
- **Do not add project terms to `$LINT_REPO`'s vocabulary** for a throwaway
  review file. That repo's vocab should not grow to accommodate this.
- **False positives worth rewording anyway.** `underscores` trips an overused
  vocabulary rule when it means the character; `snake_case` is clearer regardless.

Re-run both tools until clean.

## Confidence Gate: Ask Before Posting

Stop here and ask the operator about every low-confidence finding. A posted
comment carries the weight of a reviewed judgement, and a wrong one costs the
author real time chasing a defect that is not there. Guessing in public is worse
than asking in private.

Separate two kinds of uncertainty. They get different treatment.

**Uncertain whether the observation is true. Pause and ask.**

- The finding depends on a rule that may not apply, such as whether generated
  code counts as third-party for a wrapping rule.
- The finding depends on behaviour nobody checked, such as whether a linter or a
  test actually rejects the pattern.
- A verification step was skipped, so the claim is reasoned rather than
  confirmed.
- The finding contradicts an existing test, comment or commit message, which
  usually means the author knows something the reviewer does not.

**Uncertain only about intent, given a verified observation. Post it as a
question.** "This append runs before the `continue`, so the list includes
students the loop skips. Deliberate?" states a fact and asks about the reason.
That is useful to an author and cannot mislead.

Present the paused findings as a short list, each with what would settle it, and
wait for a decision:

```text
Two findings I can't confirm without your input:

1. Unwrapped genqlient error at populate-local-class-roster/main.go:91.
   Wrapping rules cover third-party errors; generated code may not count.
   Settles it: run the linter, or tell me the convention.

2. ...

Post, drop, or verify first?
```

Prefer verifying over asking where a command settles it. Running the linter, the
tests or the query is better than a question the operator has to answer. Ask only when
verification is impractical or the answer is a matter of convention.

Do not post a finding that stayed uncertain. Dropping it costs nothing. A
confident-sounding comment that turns out to be wrong costs the author's trust in
every other comment in the review.

## Stage 4: Post Inline Comments

Prompt template:

> Take the portions of the review that reference specific files and lines and
> make them specific review comments on those files and lines using the GitHub
> CLI.

Get line numbers from the head version of each file. They must fall inside the
diff, which for a new file means anywhere:

```bash
git show origin/$HEAD_BRANCH:path/to/file.go | grep -nE 'symbolOne|symbolTwo'
```

`gh pr review` cannot attach line comments. Build a review payload and post it
through the API in one call, so the comments arrive as a single review:

```bash
cat > /tmp/review_payload.json <<'JSON'
{
  "event": "COMMENT",
  "body": "Summary, plus any finding with no single line to anchor to.",
  "comments": [
    { "path": "services/foo/main.go", "line": 228, "body": "**Headline.**\n\nDetail." }
  ]
}
JSON

gh api repos/Khan/webapp/pulls/$PR_NUM/reviews -X POST \
  --input /tmp/review_payload.json -q '.html_url, .state'
```

Findings with no single line, such as inconsistent directory naming across a
change, belong in the review `body`. Do not anchor them to an arbitrary line.

Verify every comment anchored where intended, and expect pre-existing comments in
the count:

```bash
gh api repos/Khan/webapp/pulls/$PR_NUM/comments -q '.[] | "\(.path):\(.line)"'
```

## Conventions for the Comments Themselves

- Open with a bold one-line claim, then the reasoning. Reviewers skim.
- Say what to do about it. "Hoisting the call into the batch driver takes this
  from N table sweeps to one" is more useful than "this is inefficient".
- Post only findings that survived the confidence gate. Where intent is the only
  open question, ask it directly in the comment rather than hedging the claim.
- Say what is good, once, in the summary. It calibrates the rest.
- If the linter was not run, say so, so nobody reads the review as CI output.
