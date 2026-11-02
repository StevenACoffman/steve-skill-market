---
name: gh-stack
description: |
  Use when the user wants to create, push, rebase, sync, navigate, or view stacks of dependent PRs. Covers the gh-stack GitHub CLI extension for managing stacked diffs, dependent pull requests, branch chains, and incremental code review workflows.
---

# `gh-stack`

`gh stack` is a [GitHub CLI](https://cli.github.com/) extension for managing **stacked branches and pull requests**. A stack is an ordered list of branches where each branch builds on the one below it, rooted on a trunk branch (typically the repo's default branch). Each branch maps to one PR whose base is the branch below it, so reviewers see only the diff for that layer.

```text
main (trunk)
 └── feat/auth-layer     → PR #1 (base: main)               - bottom (closest to trunk)
  └── feat/api-endpoints → PR #2 (base: feat/auth-layer)
   └── feat/frontend     → PR #3 (base: feat/api-endpoints) - top (furthest from trunk)
```

The **bottom** of the stack is the branch closest to the trunk, and the **top** is the branch furthest from the trunk. Each branch inherits from the one below it. Navigation commands (`up`, `down`, `top`, `bottom`) follow this model: `up` moves away from trunk, `down` moves toward it.

## When to Use This Skill

Use this skill when the user wants to:

- Break a large change into a chain of small, reviewable PRs
- Create, rebase, push, or sync a stack of dependent branches
- Navigate between layers of a branch stack
- View the status of stacked PRs
- Tear down and rebuild a stack to remove, reorder, or rename branches

## Prerequisites

The GitHub CLI (`gh`) v2.0+ must be installed and authenticated. Install the extension with:

```bash
gh extension install github/gh-stack
```

Before using `gh stack`, configure git to prevent interactive prompts:

```bash
git config rerere.enabled true       # remember conflict resolutions (skips prompt on init)
git config remote.pushDefault origin # if multiple remotes exist (skips remote picker)
```

## Agent Rules

**All `gh stack` commands must be run non-interactively.** Every command invocation must include the flags and positional arguments needed to avoid prompts, TUIs, and interactive menus. If a command would prompt for input, it will hang indefinitely.

01. **Always supply branch names as positional arguments** to `init`, `add`, and `checkout`. Running these commands without arguments triggers interactive prompts.
02. **When a prefix is set, pass only the suffix to `add`.** `gh stack add auth` with prefix `feat` → `feat/auth`. Passing `feat/auth` creates `feat/feat/auth`.
03. **Always use `--auto` with `gh stack submit`** to auto-generate PR titles. Without `--auto`, `submit` prompts for a title for each new PR.
04. **Always use `--json` with `gh stack view`.** Without `--json`, the command launches an interactive TUI that cannot be operated by agents. There is no other appropriate flag — always pass `--json`.
05. **Use `--remote <name>` when multiple remotes are configured**, or pre-configure `git config remote.pushDefault origin`. Without this, `push`, `submit`, `sync`, `link`, and `checkout` trigger an interactive remote picker.
06. **Avoid branches shared across multiple stacks.** If a branch belongs to multiple stacks, commands exit with code 6. Check out a non-shared branch first.
07. **Plan your stack layers by dependency order before writing code.** Foundational changes (models, APIs, shared utilities) go in lower branches; dependent changes (UI, consumers) go in higher branches. Think through the dependency chain before running `gh stack init`.
08. **Use standard `git add` and `git commit` for staging and committing.** This gives you full control over which changes go into each branch. The `-Am` shortcut is available but should not be the default approach—stacked PRs are most effective when each branch contains a deliberate, logical set of changes.
09. **Navigate down the stack when you need to change a lower layer.** If you're working on a frontend branch and realize you need API changes, don't hack around it at the current layer. Navigate to the appropriate branch (`gh stack down`, `gh stack checkout`, or `gh stack bottom`), make and commit the changes there, run `gh stack rebase --upstack`, then navigate back up to continue.
10. **Use `gh stack link` for external tool workflows.** When branches are managed by an external tool (jj, Sapling, etc.), use `gh stack link branch-a branch-b`. `link` does not rely on local tracking state and is intended for API-driven PR and stack management. Always provide at least 2 branch names or PR numbers.

**Never do any of the following — each triggers an interactive prompt or TUI that will hang:**

- ❌ `gh stack view` or `gh stack view --short` — always use `gh stack view --json`
- ❌ `gh stack submit` without `--auto` — always use `gh stack submit --auto`
- ❌ `gh stack init` without branch arguments — always provide branch names
- ❌ `gh stack add` without a branch name — always provide a branch name
- ❌ `gh stack checkout` without an argument — always provide a PR number or branch name
- ❌ `gh stack checkout <pr-number>` when a different local stack already exists on those branches — this triggers a conflict resolution prompt with no bypass flag; use `gh stack unstack` first to remove the local stack, then retry the checkout

## Thinking About Stack Structure

Each branch in a stack should represent a **discrete, logical unit of work** that can be reviewed independently. The changes within a branch should be cohesive—they belong together and make sense as a single PR.

### Dependency Chain

Stacked branches form a dependency chain: each branch builds on the one below it. This means **foundational changes must go in lower (earlier) branches**, and code that depends on them goes in higher (later) branches.

**Plan your layers before writing code.** For example, a full-stack feature might be structured like this (use branch names relevant to your actual task, not these generic ones):

```text
main (trunk)
 └── feat/data-models    ← shared types, database schema
  └── feat/api-endpoints ← API routes that use the models
   └── feat/frontend-ui  ← UI components that call the APIs
    └── feat/integration ← tests that exercise the full stack
```

This is illustrative — choose branch names and layer boundaries that reflect the specific work you're doing. The key principle is: if code in one layer depends on code in another, the dependency must be in the same branch or a lower one.

### Branch Naming

Prefer initializing stacks with a prefix (`-p`). Prefixes group branches under a namespace (e.g., `feat/auth`, `feat/api`) and keep branch names clean and consistent. When a prefix is set, pass only the suffix to subsequent `add` calls — the prefix is applied automatically. Without a prefix, you'll need to pass the full branch name each time.

### Staging Changes Deliberately

The main reason to use `git add` and `git commit` directly is to control **which changes go into which branch**. When you have multiple files in your working tree, you can stage a subset for the current branch, commit them, then create a new branch and stage the rest there:

```bash
# You're on feat/data-models with several new files in your working tree.
# Stage only the model files for this branch:
git add internal/models/user.go internal/models/session.go
git commit -m "Add user and session models"

git add db/migrations/001_create_users.sql
git commit -m "Add user table migration"

# Now create a new branch for the API layer and stage the API files there:
gh stack add api-routes # created & switched to feat/api-routes branch
git add internal/api/routes.go internal/api/handlers.go
git commit -m "Add user API routes"
```

This keeps each branch focused on one concern. Multiple commits per branch are fine — the key is that all commits in a branch relate to the same logical concern, and changes that belong to a different concern go in a different branch.

### When to Create a New Branch

Create a new branch (`gh stack add`) when you're starting a **different concern** that depends on what you've built so far. Signs it's time for a new branch:

- You're switching from backend to frontend work
- You're moving from core logic to tests or documentation
- The next set of changes has a different reviewer audience
- The current branch's PR is already large enough to review

### One Stack, One Story

Think of a stack from the reviewer's perspective: the stack of PRs should **tell a cohesive story** about a feature or project. A reviewer should be able to read the PRs in sequence and understand the progression of changes, with each PR being a small, logical piece of the whole.

**When to use a single stack:** All the branches are part of the same feature, project, or closely related effort. Even if the work spans multiple concerns (models, API, frontend), they're all building toward the same goal.

**When to create a separate stack:** The work is unrelated to your current stack — a different feature, a bug fix in an unrelated area, or an independent refactor. Don't mix unrelated work into a single stack just because you happen to be working on both. Start a new stack with `gh stack init` or switch to an existing stack with `gh stack checkout` for each distinct effort.

Small, incidental fixes (e.g., fixing a typo you noticed) can go in the current stack if they're trivial. But if a change grows into its own project, it deserves its own stack.

## Quick Reference

| Task                                              | Command                                   |
| ------------------------------------------------- | ----------------------------------------- |
| Create a stack (recommended)                      | `gh stack init -p feat auth`              |
| Create a stack without prefix                     | `gh stack init auth`                      |
| Adopt existing branches                           | `gh stack init --adopt branch-a branch-b` |
| Set custom trunk                                  | `gh stack init --base develop branch-a`   |
| Add a branch to stack (suffix only if prefix set) | `gh stack add api-routes`                 |
| Add branch + stage all + commit                   | `gh stack add -Am "message" api-routes`   |
| Push branches to remote                           | `gh stack push`                           |
| Push to specific remote                           | `gh stack push --remote origin`           |
| Push branches + create PRs                        | `gh stack submit --auto`                  |
| Create PRs as drafts                              | `gh stack submit --auto --draft`          |
| Sync (fetch, rebase, push)                        | `gh stack sync`                           |
| Sync with specific remote                         | `gh stack sync --remote origin`           |
| Rebase entire stack                               | `gh stack rebase`                         |
| Rebase upstack only                               | `gh stack rebase --upstack`               |
| Continue after conflict                           | `gh stack rebase --continue`              |
| Abort rebase                                      | `gh stack rebase --abort`                 |
| View stack details (JSON)                         | `gh stack view --json`                    |
| Switch branches up/down in stack                  | `gh stack up [n]` / `gh stack down [n]`   |
| Switch to top/bottom branch                       | `gh stack top` / `gh stack bottom`        |
| Check out by PR                                   | `gh stack checkout 42`                    |
| Check out by branch (local only)                  | `gh stack checkout feature-auth`          |
| Tear down a stack to restructure it               | `gh stack unstack`                        |

______________________________________________________________________

## Workflows

### End-to-End: Create a Stack from Scratch

```bash
# 1. Initialize a stack with the first branch
gh stack init -p feat auth
# → creates feat/auth and checks it out

# 2. Write code for the first layer (auth)
cat >auth.go <<'EOF'
package auth

func Middleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // verify token
        next.ServeHTTP(w, r)
    })
}
EOF

# 3. Stage and commit using standard git commands
git add auth.go
git commit -m "Add auth middleware"

# You can make multiple commits on the same branch
cat >auth_test.go <<'EOF'
package auth

func TestMiddleware(t *testing.T) {
    // test auth middleware
}
EOF
git add auth_test.go
git commit -m "Add auth middleware tests"

# 4. When you're ready for a new concern, add the next branch
gh stack add api-routes
# → creates feat/api-routes (prefix applied automatically — just pass the suffix)

# 5. Write code for the API layer
cat >api.go <<'EOF'
package api

func RegisterRoutes(mux *http.ServeMux) {
    mux.HandleFunc("/users", handleUsers)
}
EOF
git add api.go
git commit -m "Add API routes"

# 6. Add a third layer for frontend
gh stack add frontend
# → creates feat/frontend (just the suffix — prefix is automatic)

cat >frontend.go <<'EOF'
package frontend

func RenderDashboard(w http.ResponseWriter) {
    // calls the API endpoints from the layer below
}
EOF
git add frontend.go
git commit -m "Add frontend dashboard"

# ── Stack complete: feat/auth → feat/api-routes → feat/frontend ──

# 7. Push everything and create draft PRs
gh stack submit --auto --draft

# 8. Verify the stack
gh stack view --json
```

> **Shortcut:** If you prefer a faster flow, `gh stack add -Am "message" branch-name` combines staging, committing, and branch creation into one command. This is useful for single-commit layers but bypasses deliberate staging.

### Making Mid-Stack Changes

This is a critical workflow for agents. When you're working on a higher layer and realize you need to change something in a lower layer (e.g., you're building frontend components but need to add an API endpoint), **navigate down to the correct branch, make the change there, and rebase**.

```bash
# You're on feat/frontend but need to add an API endpoint

# 1. Navigate to the API branch
gh stack down
# or: gh stack checkout feat/api-routes

# 2. Make the change where it belongs
cat >users_api.go <<'EOF'
package api

func handleGetUser(w http.ResponseWriter, r *http.Request) {
    // new endpoint the frontend needs
}
EOF
git add users_api.go
git commit -m "Add get-user endpoint"

# 3. Rebase everything above to pick up the change
gh stack rebase --upstack

# 4. Navigate back to where you were working
gh stack top
# or: gh stack checkout feat/frontend

# 5. Continue working — the API changes are now available
```

**Why this matters:** If you make API changes on the frontend branch, those changes will end up in the wrong PR. The API PR won't include them, and the frontend PR will have unrelated API diffs mixed in. Always put changes in the branch where they logically belong.

### Modify a Mid-Stack Branch and Sync

When you need to revisit a branch after the initial creation (e.g., responding to review feedback):

```bash
# 1. Navigate to the branch that needs changes
gh stack bottom
# or: gh stack checkout feat/auth
# or: gh stack checkout 42  (by PR number)

# 2. Make changes and commit
cat >auth.go <<'EOF'
package auth
// updated implementation
EOF
git add auth.go
git commit -m "Fix auth token validation"

# 3. Rebase everything above this branch
gh stack rebase --upstack

# 4. Push the updated stack
gh stack push
```

### Routine Sync After Merges

```bash
# Single command: fetch, rebase, push, sync PR state
gh stack sync
```

### Squash-Merge Recovery

When a PR is squash-merged on GitHub, the original branch's commits no longer exist in the trunk history. `gh stack` detects this automatically and uses `git rebase --onto` to correctly replay remaining commits.

```bash
# After PR #1 (feat/auth) is squash-merged on GitHub:
gh stack sync
# → fetches latest, detects the merge, fast-forwards trunk
# → rebases feat/api-routes onto updated trunk (skips merged branch)
# → rebases feat/frontend onto feat/api-routes
# → pushes updated branches
# → reports: "Merged: #1"

# Verify the result
gh stack view --json
# → feat/auth shows "isMerged": true, "state": "MERGED"
# → feat/api-routes and feat/frontend show updated heads
```

If `sync` hits a conflict during this process, it restores all branches to their pre-rebase state and exits with code 3. See [Handle rebase conflicts](#handle-rebase-conflicts-agent-workflow) for the resolution workflow.

### Handle Rebase Conflicts (Agent Workflow)

```bash
# 1. Start the rebase
gh stack rebase

# 2. If exit code 3 (conflict):
#    - Parse stderr for conflicted file paths
#    - Read those files to find <<<<<<< / ======= / >>>>>>> markers
#    - Edit files to resolve conflicts
#    - Stage resolved files:
git add path/to/resolved-file.go

# 3. Continue the rebase
gh stack rebase --continue

# 4. If another conflict occurs, repeat steps 2-3

# 5. If unable to resolve, abort to restore everything
gh stack rebase --abort
```

For scripting against `gh stack view --json`, see [`references/view-navigate-remove.md`](references/view-navigate-remove.md).

### Restructure a Stack (Remove a Branch, Reorder, or Rename)

Use `unstack` to tear down the stack, make structural changes, then re-init:

```bash
# 1. Remove the stack (locally and on GitHub)
gh stack unstack

# 2. Make structural changes — e.g. delete a branch, reorder, rename
git branch -m old-branch-1 new-branch-1

# 3. Re-create the stack with the new structure
gh stack init --base main --adopt new-branch-1 new-branch-2 new-branch-3
```

______________________________________________________________________

## Commands

Full flag tables and examples for every command live in `references/`:

- [`references/create-and-submit.md`](references/create-and-submit.md) — read before running `init`, `add`, `push`, `submit`, or `link` with flags beyond the Quick Reference.
- [`references/sync-and-rebase.md`](references/sync-and-rebase.md) — read before running `sync` or `rebase` (including `--upstack`, `--continue`, `--abort`).
- [`references/view-navigate-remove.md`](references/view-navigate-remove.md) — read before running `view`, `up`/`down`/`top`/`bottom`, `checkout`, or `unstack`, and when parsing `view --json` output.

______________________________________________________________________

## Output Conventions

- **Status messages** go to **stderr** with emoji prefixes: `✓` (success), `✗` (error), `⚠` (warning), `ℹ` (info).
- **Data output** (e.g., `view --json`) goes to **stdout**.
- When piping output, use `2>/dev/null` to suppress status messages if only data output is needed.

## Exit Codes and Error Recovery

| Code | Meaning                    | Agent action                                                                                                                |
| ---- | -------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 0    | Success                    | Proceed normally                                                                                                            |
| 1    | Generic error              | Read stderr for details; may indicate commit/push failure                                                                   |
| 2    | Not in a stack             | Run `gh stack init` to create a stack first                                                                                 |
| 3    | Rebase conflict            | Parse stderr for conflicted file paths, resolve conflicts, run `gh stack rebase --continue`                                 |
| 4    | GitHub API failure         | Check `gh auth status`, retry the command                                                                                   |
| 5    | Invalid arguments          | Fix the command invocation (check flags and arguments)                                                                      |
| 6    | Disambiguation required    | A branch belongs to multiple stacks. Run `gh stack checkout <specific-branch>` to switch to a non-shared branch first       |
| 7    | Rebase already in progress | Run `gh stack rebase --continue` (after resolving conflicts) or `gh stack rebase --abort` to start over                     |
| 8    | Stack is locked            | Another `gh stack` process is writing the stack file. Wait and retry — the lock times out after 5 seconds                   |
| 9    | Stacked PRs unavailable    | The repository does not have stacked PRs enabled. `submit` will offer to create regular (unstacked) PRs in interactive mode |

## Known Limitations

1. **Stacks are strictly linear.** Branching stacks (multiple children on a single parent) are not supported. Each branch has exactly one parent and at most one child. If you need parallel workstreams, use separate stacks.
2. **Stack disambiguation cannot be bypassed.** If the current branch is the trunk of multiple stacks, commands error with code 6. Check out a non-shared branch first.
3. **Multiple remotes require `--remote` or config.** If more than one remote is configured, pass `--remote <name>` or set `remote.pushDefault` in git config before running `push`, `sync`, or `rebase`.
4. **Merging PRs:** Merging Stacked PRs from the CLI is not supported yet. Direct users to open the PR URL in a browser to merge PRs.
5. **Remote stack checkout requires a PR number.** `checkout` with a branch name only works with locally tracked stacks. Use a PR number (e.g. `gh stack checkout 123`) to pull stacks from GitHub.
6. **PR title and body are auto-generated.** There is no flag to set a custom PR title or body during `submit`. The title and body are generated from commit messages plus a footer. Use `gh pr edit` to modify PR title and body after creation.
