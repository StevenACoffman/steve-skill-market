---
name: lintme
description: Run Go linters on this repository and fix errors. Use when the user asks to run lint, fix lint errors, or mentions "/lintme".
allowed-tools: Bash, Read, Edit
---

# `lintme`

`lintme` (<https://github.com/StevenACoffman/lintme>) is a wrapper around `golangci-lint` that auto-discovers all Go modules in a workspace and runs `golangci-lint` on each one with a single command.

## Current State

Tool availability:
!`export PATH="$HOME/go/bin:$PATH"; for t in lintme golangci-lint; do builtin type -P "$t" &>/dev/null && echo "$t ✓" || echo "$t MISSING"; done`

Current branch:
!`git branch --show-current 2>/dev/null`

---

## Step 0 — Ensure Tools Are Installed

### `lintme`

Install via Go:

```bash
go install github.com/StevenACoffman/lintme@latest
```

Or via uv from PyPI (lintme is a Go binary that is also published to PyPI, so `uv tool install` works without a Go toolchain):

```bash
uv tool install lintme
```

Ensure `$GOPATH/bin` (or `$GOBIN`) is on your `PATH` after a Go install, or that `uv tool` binaries are on your `PATH`.

### `golangci-lint`

```bash
export GOBIN_STD="$HOME/go/bin"
export PATH="$GOBIN_STD:$PATH"
mkdir -p "$GOBIN_STD"

builtin type -P golangci-lint &>/dev/null || \
  curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$GOBIN_STD" latest
```

## Step 1 — Run Formatters

Apply formatting fixes across all modules with:

```bash
export PATH="$HOME/go/bin:$PATH"
lintme run --fmt-only
```

This runs `golangci-lint fmt` in every module, which invokes `gofumpt` and `gci` as configured in each module's `.golangci.yml`.

## Step 2 — Run `lintme`

`lintme` discovers all modules from `go.work` and runs `golangci-lint` on each. Pick the right mode:

| Mode               | When to use                                             | Command         |
| ------------------ | ------------------------------------------------------- | --------------- |
| `branch` (default) | Normal dev — lint only issues introduced on this branch | `lintme branch` |
| `run`              | Full sweep — lint all issues in all modules             | `lintme run`    |
| `pr <number>`      | Lint only changes in a specific GitHub PR               | `lintme pr 123` |

```bash
# Default: lint branch-introduced issues, auto-fix
lintme branch

# Full sweep, no auto-fix (just report)
lintme run --no-fix

# Pass extra flags through to `golangci-lint`
lintme branch -- --timeout=5m

# Lint a specific PR
lintme pr 456 --token="$GITHUB_TOKEN"
```

Output format per module:

```text
==> ./lms-connect (github.com/Khan/districts-jobs/lms-connect)  config: .golangci.yml
lms-connect/foo.go:42:9: some issue (lintername)

1/12 modules passed
```

Exit 0 = all modules passed. Exit 1 = one or more failed.

## Step 3 — Run the Repowrite Analyzer

`lintme` does not run the custom `repowrite` analyzer. Run it separately across all modules:

```bash
for D in */; do
  [ -f "${D}go.mod" ] || continue
  echo "==> $D"
  (cd "$D" && go run ../pkg/analyzers/repowrite/cmd/repowrite ./...)
done
```

### What Repowrite Enforces

Direct datastore writes to four protected models must go through `pkg/repo/` functions:

```go
// ❌ violations — direct Put/Delete or generic crud on protected types
dc.Put(ctx, udi.Key, udi)
crud.Update[models.UserDistrictInfo](ctx, dc, key, updater)

// ✅ correct — use repo functions
repo.UpdateUDI(ctx, dc, key, actorKaid, updater)
repo.CreateCDIs(ctx, dc, actorKaid, cdis...)
```

| Model                   | Repo functions                                                                                                          |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `UserDistrictInfo`      | `repo.CreateUDIs`, `repo.UpdateUDI`, `repo.UpdateUDIs`, `repo.HardDeleteUDIs`; `InTxn` variants for inside transactions |
| `ClassroomDistrictInfo` | `repo.CreateCDIs`, `repo.UpdateCDI`, `repo.HardDeleteCDIs`; `InTxn` variants                                            |
| `District`              | `repo.CreateDistricts`, `repo.UpdateDistrict`, `repo.HardDeleteDistricts`; `InTxn` variants                             |
| `School`                | `repo.CreateSchools`, `repo.UpdateSchool`, `repo.HardDeleteSchools`                                                     |

All repo functions take `actorKaid string` as a required argument. Find the right actor ID from the call site context.

## Step 4 — Fix Remaining Issues

After `--fix`, any remaining diagnostics require code changes. Common patterns from the enabled linters in `.golangci.yml`:

| Linter                       | Typical message                                          | Fix                                                         |
| ---------------------------- | -------------------------------------------------------- | ----------------------------------------------------------- |
| `revive/context-as-argument` | `context.Context should be the first parameter`          | Move `ctx` to first argument position                       |
| `revive/error-return`        | `error return value should be the last`                  | Reorder return values                                       |
| `revive/superfluous-else`    | `if block ends with a return/break; else is superfluous` | Remove the `else`, dedent the block                         |
| `perfsprint`                 | `fmt.Errorf can be replaced with errors.New`             | Replace `fmt.Errorf("msg")` → `errors.New("msg")`           |
| `bodyclose`                  | `response body must be closed`                           | Add `defer resp.Body.Close()` after the error check         |
| `staticcheck/SA1006`         | `Printf with dynamic first argument`                     | Use a format string literal                                 |
| `testifylint`                | `use assert.NoError instead of assert.Nil for errors`    | Swap the assertion                                          |
| `durationcheck`              | `multiplying durations`                                  | Use `5 * time.Second`, not `time.Duration(5) * time.Second` |

## Step 5 — Verify Clean

```bash
lintme run --no-fix && \
for D in */; do
  [ -f "${D}go.mod" ] || continue
  (cd "$D" && go run ../pkg/analyzers/repowrite/cmd/repowrite ./...)
done
```

Both must exit 0.

## Rules

- **Never add `//nolint`** to silence a linter. Fix the underlying issue. For genuine false positives on generated files, add an exclusion path to `.golangci.yml` instead.
- **Generated files** (`generated/` directories) are already excluded by `.golangci.yml`.
- **Test files** (`*_test.go`) are exempt from `repowrite` but still linted by golangci-lint.
