---
name: go-test-auto
description: |
  Use when the user asks about change-aware testing, affected tests, or wants to avoid running the full test suite. Covers gta (Go Test Affected) to find and run only the packages affected by current changes.
allowed-tools: Bash, Read, Edit
---

# Go Test Affected (`gta`)

[gta](https://github.com/digitalocean/gta) (Go Test Affected, by DigitalOcean) finds the transitive closure of packages whose tests need re-running after a set of file changes. It loads the full package dependency graph from the workspace root, builds a reverse dependency map, then traverses outward from each changed package to find everything that imports it — directly or transitively.

Run from the `districts-ff/` workspace root. The output is Go import paths, space-separated when piped, ready to feed directly to `go test`.

## Installation

```bash
go install github.com/digitalocean/gta@latest
```

## Running from the Workspace Root

```bash
gta -base origin/main -include github.com/Khan/districts-jobs/
```

Sample output (one import path per line in a terminal, space-separated when piped):

```text
github.com/Khan/districts-jobs/pkg/encryption
github.com/Khan/districts-jobs/pkg/models
github.com/Khan/districts-jobs/roster/pkg/rostering/audit
```

`-include` is required — without it, stdlib and every loaded third-party package appears in the output alongside your repo's packages.

`-base origin/main` is required because the gta default is `origin/master`, which does not exist in this repo.

**Startup time:** gta calls `packages.Load` from the workspace root, loading all 25,699 packages across the 19 modules. A cold build cache takes 30–90 seconds; warm-cache runs are much faster.

## Key Flags

| Flag                    | Default         | Purpose                                                                       |
| ----------------------- | --------------- | ----------------------------------------------------------------------------- |
| `-base <branch>`        | `origin/master` | Branch to diff against; use `origin/main` for this repo                       |
| `-include <prefixes>`   | *(none)*        | Comma-separated import-path prefixes; filter output to matching packages      |
| `-changed-files <path>` | *(none)*        | Read changed-file absolute paths from a newline-separated file instead of git |
| `-test-transitive`      | `true`          | Whether test-only imports propagate the reverse traversal                     |
| `-json`                 | `false`         | Emit structured JSON (`changes`, `dependencies`, `all_changes`)               |

## Running Affected Tests

```bash
# go test
go test -count=1 -timeout 5m $(gta -base origin/main -include github.com/Khan/districts-jobs/)

# gotestsum (go test flags go after --)
gotestsum -- -count=1 -timeout 5m $(gta -base origin/main -include github.com/Khan/districts-jobs/)
```

When no packages are affected (for example, a docs-only change), gta outputs nothing and `go test` receives no arguments — which prints usage and exits non-zero. Guard against this:

```bash
AFFECTED=$(gta -base origin/main -include github.com/Khan/districts-jobs/)
if [ -n "$AFFECTED" ]; then
	# $AFFECTED is intentionally unquoted — word-splits into separate package arguments
	gotestsum -- -count=1 -timeout 5m $AFFECTED
else
	echo "No affected packages — skipping tests"
fi
```

## JSON Output

```bash
gta -base origin/main -include github.com/Khan/districts-jobs/ -json
```

Example output:

```json
{
  "changes": [
    "github.com/Khan/districts-jobs/pkg/encryption"
  ],
  "dependencies": [
    "github.com/Khan/districts-jobs/roster/pkg/rostering/audit"
  ],
  "all_changes": [
    "github.com/Khan/districts-jobs/pkg/encryption",
    "github.com/Khan/districts-jobs/roster/pkg/rostering/audit"
  ]
}
```

`changes` = directly modified packages; `dependencies` = packages that import a changed package transitively; `all_changes` = union of both.

Use `-json` in CI to log what gta detected, to write the affected list to a file, or to feed it to other tooling. For running tests, the plain output piped via `$()` is easier.

## Uncommitted Changes

By default gta diffs against a branch (`-base`). To test changes not yet committed, generate the file list from git and pass it via `-changed-files`:

```bash
# Staged and unstaged changes
git diff HEAD --name-only |
	sed "s|^|$(git rev-parse --show-toplevel)/|" >/tmp/changed.txt
gta -changed-files /tmp/changed.txt -include github.com/Khan/districts-jobs/

# Staged changes only
git diff --staged --name-only |
	sed "s|^|$(git rev-parse --show-toplevel)/|" >/tmp/changed.txt
gta -changed-files /tmp/changed.txt -include github.com/Khan/districts-jobs/
```

`-changed-files` expects a newline-separated list of absolute file paths.

## CI Integration

The current `.github/workflows/test.yml` runs 8 hardcoded modules unconditionally via a matrix. A gta-based alternative detects affected packages first and skips the run entirely for unaffected changes:

```yaml
  - name: Install gta
    run: go install github.com/digitalocean/gta@latest

  - name: Find affected packages
    id: affected
    run: |
      AFFECTED=$(gta -base origin/main -include github.com/Khan/districts-jobs/)
      echo "pkgs=$AFFECTED" >> $GITHUB_OUTPUT

  - name: Run affected tests
    if: steps.affected.outputs.pkgs != ''
    run: |
      gotestsum \
        --jsonfile /tmp/go_test.json \
        --junitfile /tmp/report.xml \
        --format-icons=hivis \
        --format=pkgname-and-test-fails \
        -- -count=1 -timeout 10m ${{ steps.affected.outputs.pkgs }}
```

## Workspace Behavior

gta works correctly from `districts-ff/` because `packages.Load("...")` is workspace-aware. When invoked from the workspace root it loads all 25,699 packages across all 19 modules and builds a complete cross-module dependency graph. Verified:

- `roster/pkg/rostering/audit` imports `pkg/encryption`, `pkg/models`, and other `pkg` sub-packages.
- A change to any of those `pkg` packages causes gta to surface the `roster` packages that import them.
- The `-include github.com/Khan/districts-jobs/` filter excludes `lockwatch` and `teller` (which have non-standard module paths), but both have zero tests so nothing is missed.

## Known Limitation — `moduleroot()` in Workspace Mode

gta detects the module root by running `go list -m -f '{{.Dir}}'`. In workspace mode this outputs one directory per module (19 lines here) rather than one. The multi-line result is stored as-is and is not a valid filesystem path.

**This does not affect output.** The invalid root is used only for a single early-exit optimization in path filtering; since it never matches any real path, that check is skipped and the remaining filtering logic runs correctly. `gta.New()` succeeds and all affected packages are reported accurately.

The fix: detect workspace mode via `go env GOWORK` and derive the root from the `go.work` file path instead. No patch is needed to use gta today.
