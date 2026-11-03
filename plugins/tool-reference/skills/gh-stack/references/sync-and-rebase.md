# Syncing and Rebasing Stacks

## Sync the Stack — `gh stack sync`

Fetch, rebase, push, and sync PR state in a single command. This is the recommended command for routine synchronization.

```text
gh stack sync [flags]
```

| Flag              | Description                                                      |
| ----------------- | ---------------------------------------------------------------- |
| `--remote <name>` | Remote to fetch from and push to (use if multiple remotes exist) |

**What it does (in order):**

1. **Fetch** latest changes from the remote
2. **Fast-forward trunk** to match remote (skips if already up to date, warns if diverged)
3. **Cascade rebase** all stack branches onto their updated parents (only if trunk moved). Handles merged PRs automatically. If a conflict is detected, **all branches are restored** to their pre-rebase state and the command exits with code 3 — see [Handle rebase conflicts](../SKILL.md#handle-rebase-conflicts-agent-workflow) for the resolution workflow
4. **Push** all active branches atomically
5. **Sync PR state** from GitHub and report the status of each PR

**Output (stderr):**

- `✓ Fetched latest changes from origin`
- `✓ Trunk main fast-forwarded to <sha>` or `✓ Trunk main is already up to date`
- `✓ Rebased <branch> onto <base>` per branch (if base moved)
- `✓ Pushed N branches`
- `✓ PR #N (<branch>) — Open` per branch
- `Merged: #N, #M` for merged branches
- `✓ Stack synced`

______________________________________________________________________

## Rebase the Stack — `gh stack rebase`

Pull from remote and cascade-rebase stack branches. Use this when `sync` reports a conflict or when you need finer control (e.g., rebase only part of the stack).

```text
gh stack rebase [flags] [branch]
```

```bash
# Rebase the entire stack
gh stack rebase

# Rebase only branches from trunk to current branch
gh stack rebase --downstack

# Rebase only branches from current branch to top
gh stack rebase --upstack

# After resolving a conflict: stage files with `git add`, then:
gh stack rebase --continue

# Abort and restore all branches to pre-rebase state
gh stack rebase --abort
```

| Flag              | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `--downstack`     | Only rebase branches from trunk to the current branch   |
| `--upstack`       | Only rebase branches from the current branch to the top |
| `--continue`      | Continue after resolving conflicts                      |
| `--abort`         | Abort and restore all branches                          |
| `--remote <name>` | Remote to fetch from (use if multiple remotes exist)    |

| Argument   | Description                                    |
| ---------- | ---------------------------------------------- |
| `[branch]` | Target branch (defaults to the current branch) |

**Conflict handling:** See [Handle rebase conflicts](../SKILL.md#handle-rebase-conflicts-agent-workflow) in the Workflows section for the full resolution workflow.

**Merged PR detection:** If a branch's PR was merged on GitHub, the rebase automatically handles this using `--onto` mode and correctly replays commits on top of the merge target.

**Rerere (conflict memory):** `git rerere` is enabled by `init` so previously resolved conflicts are auto-resolved in future rebases.
