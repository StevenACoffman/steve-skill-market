# Creating and Submitting Stacks

## Initialize a Stack — `gh stack init`

Creates a new stack. **Always provide at least one branch name as a positional argument** — running without branch arguments triggers interactive prompts that agents cannot use.

```text
gh stack init [flags] <branches...>
```

```bash
# Set a branch prefix (recommended — subsequent `add` calls only need the suffix)
gh stack init -p feat auth
# → creates feat/auth

# Multi-part prefix (slashes are fine — suffix-only rule still applies)
gh stack init -p monalisa/billing auth
# → creates monalisa/billing/auth

# Create a stack with new branches (no prefix — use full branch names)
gh stack init branch-a branch-b branch-c

# Use a different trunk branch
gh stack init --base develop branch-a branch-b

# Adopt existing branches into a stack
gh stack init --adopt branch-a branch-b branch-c
```

| Flag                    | Description                                                                                                                     |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `-b, --base <branch>`   | Trunk branch (defaults to the repo's default branch)                                                                            |
| `-a, --adopt`           | Adopt existing branches instead of creating new ones                                                                            |
| `-p, --prefix <string>` | Branch name prefix. Subsequent `add` calls only need the suffix (e.g., with `-p feat`, `gh stack add auth` creates `feat/auth`) |

**Behavior:**

- Using `-p` is recommended — it simplifies branch naming for subsequent `add` calls
- Creates any branches that don't already exist (branching from the trunk branch)
- In `--adopt` mode: validates all branches exist, rejects if any is already in a stack or has an existing PR
- Checks out the last branch in the list
- Enables `git rerere` so conflict resolutions are remembered across rebases. On first run in a repo, this may trigger a confirmation prompt — pre-configure with `git config rerere.enabled true` to avoid it

______________________________________________________________________

## Add a Branch — `gh stack add`

Add a new branch on top of the current stack. Must be run while on the topmost branch (or the trunk if the stack has no branches yet). **Always provide a branch name** — running without one triggers an interactive prompt.

```text
gh stack add [flags] <branch>
```

**Recommended workflow — create the branch, then use standard git:**

```bash
# Create a new branch and switch to it (just the suffix — prefix is applied automatically)
gh stack add api-routes

# Write code, stage deliberately, and commit
git add internal/api/routes.go internal/api/handlers.go
git commit -m "Add user API routes"

# Make more commits on the same branch as needed
git add internal/api/middleware.go
git commit -m "Add rate limiting middleware"
```

**Shortcut — stage, commit, and branch in one command:**

```bash
# Create a new branch, stage all changes, and commit
gh stack add -Am "Add API routes" api-routes

# Create a new branch, stage tracked files only, and commit
gh stack add -um "Fix auth bug" auth-fix
```

| Flag                     | Description                                                 |
| ------------------------ | ----------------------------------------------------------- |
| `-m, --message <string>` | Create a commit with this message                           |
| `-A, --all`              | Stage all changes including untracked files (requires `-m`) |
| `-u, --update`           | Stage tracked files only (requires `-m`)                    |

**Behavior notes:**

- `-A` and `-u` are mutually exclusive.
- When the current branch has no commits (e.g., right after `init`), `add -Am` commits directly on the current branch instead of creating a new one.
- **Prefix handling:** Only pass the suffix when a prefix is set. `gh stack add api` with prefix `todo` → `todo/api`. Passing `todo/api` creates `todo/todo/api`. Without a prefix, pass the full branch name.
- If called from a branch that is not the topmost in the stack, exits with code 5: `"can only add branches on top of the stack"`. Use `gh stack top` to switch first.
- **Uncommitted changes:** When using `gh stack add branch-name` without `-Am`, any uncommitted changes (staged or unstaged) in your working tree carry over to the new branch. This is standard git behavior — the working tree is not touched. Commit or stash changes on the current branch before running `add` if you want a clean starting point on the new branch.

______________________________________________________________________

## Push Branches to Remote — `gh stack push`

Push all stack branches to the remote.

```text
gh stack push [flags]
```

```bash
# Push all branches
gh stack push

# Push to specific remote
gh stack push --remote upstream
```

| Flag              | Description                                       |
| ----------------- | ------------------------------------------------- |
| `--remote <name>` | Remote to push to (use if multiple remotes exist) |

**Behavior:**

- Pushes all active (non-merged) branches atomically (`--force-with-lease --atomic`)
- Does **not** create or update pull requests — use `gh stack submit` for that

**Output (stderr):**

- `Pushed N branches` summary

______________________________________________________________________

## Submit Branches and Create PRs — `gh stack submit`

Push all stack branches and create PRs on GitHub. **Always pass `--auto`** — without it, `submit` prompts for a PR title for each new branch.

```bash
# Submit and auto-title new PRs (required for non-interactive use)
gh stack submit --auto

# Submit and create PRs as drafts
gh stack submit --auto --draft
```

| Flag              | Description                                                                      |
| ----------------- | -------------------------------------------------------------------------------- |
| `--auto`          | Auto-generate PR titles without prompting (**required** for non-interactive use) |
| `--draft`         | Create new PRs as drafts                                                         |
| `--remote <name>` | Remote to push to (use if multiple remotes exist)                                |

**Behavior:**

- Pushes all active (non-merged) branches atomically (`--force-with-lease --atomic`)
- Creates a new PR for each branch that doesn't have one (base set to the first non-merged ancestor branch)
- After creating PRs, links them together as a **Stack** on GitHub (requires the repository to have stacks enabled)
- If stacks are not available (exit code 9), the repository does not have stacked PRs enabled. In interactive mode, `submit` offers to create regular (unstacked) PRs instead. In non-interactive mode, it exits with code 9.
- Syncs PR metadata for branches that already have PRs

**PR title auto-generation (`--auto`):**

- Single commit on branch → uses the commit subject as the PR title, commit body as PR body
- Multiple commits on branch → humanizes the branch name (hyphens/underscores → spaces) as the title

**Output (stderr):**

- `Created PR #N for <branch>` for each newly created PR
- `PR #N for <branch> is up to date` for existing PRs
- `Pushed and synced N branches` summary

______________________________________________________________________

## Link Branches as a Stack (No Local Tracking) — `gh stack link`

Link PRs into a stack on GitHub without creating any local tracking state. This is the recommended approach if you are managing stacked branches with other tools (jj, Sapling, git-town) and want to create GitHub Stacked PRs via an API.

```text
gh stack link [flags] <branch-or-pr> <branch-or-pr> [...]
```

```bash
# Link branches into a stack (pushes, creates PRs, creates stack)
gh stack link branch-a branch-b branch-c

# Use a different base branch and create PRs as drafts
gh stack link --base develop --draft branch-a branch-b branch-c

# Link existing PRs by number
gh stack link 10 20 30

# Add branches to an existing stack of PRs
gh stack link 42 43 feature-auth feature-ui
```

| Flag              | Description                                               |
| ----------------- | --------------------------------------------------------- |
| `--base <branch>` | Base branch for the bottom of the stack (default: `main`) |
| `--draft`         | Create new PRs as drafts                                  |
| `--remote <name>` | Remote to push to (use if multiple remotes exist)         |

**Behavior:**

- Arguments are provided in stack order (bottom to top)
- Each argument can be a branch name or a PR number. Numeric arguments are tried as PR numbers first; if no PR with that number exists, the argument is treated as a branch name
- Branch arguments are pushed to the remote automatically (non-force, atomic)
- For branches without open PRs, new PRs are created with auto-generated titles and the correct base branch chaining (first branch uses `--base`, subsequent branches use the previous branch)
- Existing PRs whose base branch doesn't match the expected chain are corrected automatically
- If the PRs are not yet in a stack, a new stack is created. If some PRs are already in a stack, the stack is updated (additive only — existing PRs are never removed)
- Does **not** create or modify any local state

**Output (stderr):**

- `Pushing N branches to <remote>...`
- `Found PR #N for branch <name>` for branches with existing PRs
- `Created PR #N for <branch> (base: <base>)` for newly created PRs
- `Updated base branch for PR #N to <base>` when base branches are corrected
- `Created stack with N PRs` or `Updated stack to N PRs`
