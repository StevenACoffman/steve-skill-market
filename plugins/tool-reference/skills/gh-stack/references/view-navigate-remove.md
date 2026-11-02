# Viewing, Navigating, and Removing Stacks

## View the Stack — `gh stack view`

Display the current stack's branches, PR status, and recent commits. **Always pass `--json`** — without it, this command launches an interactive TUI that agents cannot operate.

```bash
# Always use --json
gh stack view --json
```

| Flag     | Description                                                                |
| -------- | -------------------------------------------------------------------------- |
| `--json` | Output stack data as JSON to stdout (**required** for non-interactive use) |

**`--json` output format:**

```json
{
  "trunk": "main",
  "prefix": "feat",
  "currentBranch": "feat/api-routes",
  "branches": [
    {
      "name": "feat/auth",
      "head": "abc1234...",
      "base": "def5678...",
      "isCurrent": false,
      "isMerged": true,
      "needsRebase": false,
      "pr": {
        "number": 42,
        "url": "https://github.com/owner/repo/pull/42",
        "state": "MERGED"
      }
    },
    {
      "name": "feat/api-routes",
      "head": "789abcd...",
      "base": "abc1234...",
      "isCurrent": true,
      "isMerged": false,
      "needsRebase": false,
      "pr": {
        "number": 43,
        "url": "https://github.com/owner/repo/pull/43",
        "state": "OPEN"
      }
    }
  ]
}
```

Fields per branch:

- `name` — branch name
- `head` — current HEAD SHA
- `base` — parent branch's HEAD SHA at last sync
- `isCurrent` — whether this is the checked-out branch
- `isMerged` — whether the PR has been merged
- `needsRebase` — whether the base branch is not an ancestor (non-linear history)
- `pr` — PR metadata (omitted if no PR exists). `state` is `"OPEN"` or `"MERGED"`.

______________________________________________________________________

## Navigate the Stack

Move between branches without remembering branch names. These commands are fully non-interactive.

```bash
gh stack up     # Move up one branch (further from trunk)
gh stack up 3   # Move up three branches
gh stack down   # Move down one branch (closer to trunk)
gh stack down 2 # Move down two branches
gh stack top    # Jump to the top of the stack (furthest from trunk)
gh stack bottom # Jump to the bottom (first non-merged branch above trunk)
```

Navigation clamps to stack bounds. Merged branches are skipped when navigating from active branches.

______________________________________________________________________

## Check Out a Stack — `gh stack checkout`

Check out a stack from a pull request number or branch name. **Always provide an argument** — running `gh stack checkout` without arguments triggers an interactive selection menu.

```text
gh stack checkout <pr-number | branch>
```

```bash
# By PR number (pulls from GitHub)
gh stack checkout 42

# By branch name (local only)
gh stack checkout feature-auth
```

When a PR number is provided (e.g. `123`), the command fetches the stack on GitHub, pulls the branches, and sets up the stack locally. If the stack already exists locally and matches, it switches to the branch.

> **⚠️ Agent warning:** If the local and remote stacks have different branch compositions, this command triggers an interactive conflict-resolution prompt that cannot be bypassed with a flag. To avoid this: run `gh stack unstack` first to remove the conflicting local stack, then retry `gh stack checkout <pr-number>`.

When a branch name is provided, the command resolves it against locally tracked stacks only. This is always safe for non-interactive use.

______________________________________________________________________

## Remove a Stack — `gh stack unstack`

Tear down a stack so you can restructure it — remove a branch, reorder branches, rename branches, or make other large changes. After unstacking, use `gh stack init` to re-create the stack with the desired structure.

```text
gh stack unstack [flags] [branch]
```

```bash
# Tear down the stack (locally and on GitHub), then rebuild
gh stack unstack
gh stack init --base main --adopt branch-2 branch-1 branch-3 # reordered

# Only remove local tracking (keep the stack on GitHub)
gh stack unstack --local

# Specify a branch to identify which stack to tear down
gh stack unstack feature-auth
```

| Flag      | Description                                       |
| --------- | ------------------------------------------------- |
| `--local` | Only delete the stack locally (keep it on GitHub) |

| Argument   | Description                                            |
| ---------- | ------------------------------------------------------ |
| `[branch]` | A branch in the stack (defaults to the current branch) |

## Parsing `--json` Output

```bash
# Get stack state as JSON
output=$(gh stack view --json)

# Check if any branch needs a rebase, and rebase if so
needs_rebase=$(echo "$output" | jq '[.branches[] | select(.needsRebase == true)] | length')
if [ "$needs_rebase" -gt 0 ]; then
	echo "Branches need rebase, rebasing stack..."
	gh stack rebase
fi

# Get all open PR URLs
echo "$output" | jq -r '.branches[] | select(.pr.state == "OPEN") | .pr.url'

# Find merged branches
echo "$output" | jq -r '.branches[] | select(.isMerged == true) | .name'

# Get the current branch
echo "$output" | jq -r '.currentBranch'

# Check if the stack is fully merged (all branches merged)
echo "$output" | jq '[.branches[] | .isMerged] | all'
```
