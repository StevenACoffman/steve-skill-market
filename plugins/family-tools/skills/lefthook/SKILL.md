---
name: lefthook
description: Use when configuring or debugging Git hooks in this project. Covers lefthook.yaml structure, pre-commit commands, stage_fixed, and running hooks manually.
---

# Lefthook — Git Hooks Manager

Lefthook is a fast, dependency-free Git hooks manager written in Go. It
replaces hand-rolled shell scripts in `.git/hooks/` with a single
`lefthook.yaml` committed to the repository and shared across the team.
Hooks run in parallel by default, support staged-file filtering, and can
auto-stage files they modify.

## When to Use This Skill

- Installing or activating Lefthook in a project
- Adding or modifying hook jobs in `lefthook.yaml`
- Diagnosing a hook that is not firing or failing unexpectedly
- Running hooks manually without committing or pushing
- Skipping hooks for a single operation
- Adding a new module to an existing multi-module hook configuration

______________________________________________________________________

## Installation

```bash
# macOS / Linux — recommended
brew install lefthook

# Go toolchain
go install github.com/evilmartians/lefthook@latest

# Node.js
npm install --save-dev lefthook

# Ruby
gem install lefthook
```

Verify (this project requires ≥ 2.0.0):

```bash
lefthook --version
```

### Activating Hooks

After cloning, install the Git hook shims once per clone:

```bash
lefthook install
```

This writes thin shim scripts into `.git/hooks/` that delegate to lefthook.
It only needs to be run once. Changes to `lefthook.yaml` are picked up
automatically after `git pull` — no reinstall required.

To remove the shims:

```bash
lefthook uninstall
```

______________________________________________________________________

## `lefthook.yaml` Structure

```yaml
min_version: 2.0.0      # fail fast if lefthook is too old

<hook-name>:            # e.g. pre-commit, pre-push, commit-msg
  parallel: true        # run all top-level jobs concurrently (default: false)
  jobs:
    - name: my-job
      root: subdir/     # working directory for this job (relative to repo root)
      glob: '*.go'      # only run if staged/pushed files match this pattern
      run: some-command
      stage_fixed: true # re-stage files modified by this job
```

### Key Job Fields

| Field               | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `name`              | Job identifier; used with `--jobs` flag and in output        |
| `root`              | Working directory for the job (relative to repo root)        |
| `glob`              | File pattern; job is skipped if no staged/pushed files match |
| `run`               | Shell command to execute                                     |
| `stage_fixed: true` | Re-stage files the command modifies in place                 |
| `interactive: true` | Allow the job to read from stdin (e.g. prompts)              |
| `fail_text`         | Custom message shown on failure                              |
| `env`               | Environment variables for this job (`KEY: value`)            |
| `tags`              | Labels for filtering with `--tags`                           |

### Job Groups (Sequential Within Parallel)

Use `group` with `piped: true` to run a set of steps sequentially, aborting at
the first failure, while the outer hook still runs multiple groups in parallel:

```yaml
pre-push:
  parallel: true
  jobs:
    - name: my-module
      root: my-module/
      glob: '*.go'
      group:
        piped: true
        jobs:
          - run: go mod tidy -diff
          - run: go vet ./...
          - run: go test ./...
          - run: golangci-lint run ./...
```

### Template Variables

Lefthook substitutes these in `run` values:

| Variable         | Expands to                                                  |
| ---------------- | ----------------------------------------------------------- |
| `{staged_files}` | Space-separated list of staged files matching `glob`        |
| `{push_files}`   | Space-separated list of files changed in the pushed commits |
| `{all_files}`    | All tracked files matching `glob` (regardless of staging)   |
| `{cmd}`          | The `run` value itself (useful in scripts)                  |

```yaml
pre-commit:
  jobs:
    - name: lint-changed
      glob: '*.md'
      run: rumdl check --fix {staged_files}
      stage_fixed: true
```

### `min_version`

Set at the top of `lefthook.yaml` to fail fast if a developer has an older
lefthook installed:

```yaml
min_version: 2.0.0
```

______________________________________________________________________

## Running Hooks Manually

```bash
# Run all jobs in a hook
lefthook run pre-commit

# Run a single named job
lefthook run pre-commit --jobs fmt-roster

# Run against all matching files (not just staged/pushed)
lefthook run pre-commit --all-files

# Dry run — show what would execute without running it
lefthook run pre-commit --dry-run

# Run only jobs with a specific tag
lefthook run pre-commit --tags lint
```

______________________________________________________________________

## Skipping Hooks

```bash
# Skip all hooks for one operation
LEFTHOOK=0 git commit -m "wip"
LEFTHOOK=0 git push

# Skip specific jobs by name
LEFTHOOK_EXCLUDE=fmt-roster,fmt-teller git commit -m "wip"
```

______________________________________________________________________

## Troubleshooting

**Hook didn't fire on commit or push**
The shim scripts in `.git/hooks/` may be missing or stale. Run:

```bash
lefthook install
```

**Job not running even though files changed**
Check that the staged (pre-commit) or pushed (pre-push) files match the `glob`
pattern and are inside the `root` directory. The glob is scoped to `root`.

**`golangci-lint run --fix` modifies files but the push is still rejected**
The fixed files were not part of the pushed commits. Stage and amend:

```bash
git add -p
git commit --amend --no-edit
git push
```

**`go mod tidy -diff` fails with "flag provided but not defined"**
`-diff` requires Go 1.23 or later. Check with `go version` and update if needed.

## Want to Run Pre-Push Jobs Locally Without Actually Pushing

```bash
lefthook run pre-push --all-files
```

______________________________________________________________________

## Districts-Ff Reference Configuration

The districts-ff project is a Go workspace with 19 independent modules sharing
a single `lefthook.yaml` at the repo root. The pattern below is the established
convention for this project.

### Pre-Commit: Parallel Formatting per Module

Every module gets a `fmt-<name>` job that runs `golangci-lint fmt` against
staged `.go` files and re-stages the result:

```yaml
min_version: 2.0.0

pre-commit:
  parallel: true
  jobs:
    - name: fmt-<module>
      root: <module>/
      glob: '*.go'
      run: golangci-lint fmt --config=../.golangci.yml
      stage_fixed: true
```

`golangci-lint fmt` applies three formatters in one pass — `gofumpt`,
`gci` (import ordering), and `golines` (line wrapping) — matching exactly what
`golangci-lint run` will enforce at push time.

`stage_fixed: true` automatically re-stages formatted files so the commit
contains the formatted versions, not the originals.

### Pre-Push: Piped Quality Gate per Module

Every module gets a `<name>` job running four steps sequentially, aborting at
the first failure:

```yaml
pre-push:
  parallel: true
  jobs:
    - name: <module>
      root: <module>/
      glob: '*.go'
      group:
        piped: true
        jobs:
          - run: go mod tidy -diff
          - run: go vet ./...
          - run: go test -count=1 -timeout 5m ./...
          - run: golangci-lint run --fix --config=../.golangci.yml ./...
```

**Why this order:**

| Step                                 | Purpose                                    | Why here                                                      |
| ------------------------------------ | ------------------------------------------ | ------------------------------------------------------------- |
| `go mod tidy -diff`                  | Fail if `go.mod`/`go.sum` are inconsistent | First — broken dependencies break everything downstream       |
| `go vet ./...`                       | Built-in static analysis                   | Fast; no point running slow tests on unvetted code            |
| `go test -count=1 -timeout 5m ./...` | Full test suite, cache bypassed            | Before linting — linter findings on broken code are noise     |
| `golangci-lint run --fix`            | Full linter suite (26 linters) + auto-fix  | Last — only meaningful on code that compiles and passes tests |

All 19 modules run in parallel; wall-clock time is bounded by the slowest
module.

### Adding a New Module

1. Create the module and add it to the workspace:

   ```bash
   mkdir newmodule && cd newmodule
   go mod init github.com/Khan/districts-ff/newmodule
   cd .. && go work use ./newmodule
   ```

2. Add to `pre-commit → jobs` in `lefthook.yaml`:

   ```yaml
     - name: fmt-newmodule
       root: newmodule/
       glob: '*.go'
       run: golangci-lint fmt --config=../.golangci.yml
       stage_fixed: true
   ```

3. Add to `pre-push → jobs` in `lefthook.yaml`:

   ```yaml
     - name: newmodule
       root: newmodule/
       glob: '*.go'
       group:
         piped: true
         jobs:
           - run: go mod tidy -diff
           - run: go vet ./...
           - run: go test -count=1 -timeout 5m ./...
           - run: golangci-lint run --fix --config=../.golangci.yml ./...
   ```

4. Commit `lefthook.yaml` and `go.work` together.

### Current Modules

19 modules covered by both hooks:

`admin-reports`, `alerter`, `distutil`, `instructional-area-gen`, `isyncso`,
`khanx`, `khanxadmin`, `listdistricts`, `lms-connect`, `lockwatch`, `pkg`,
`pull-demographics`, `pull-test-results`, `repoman`, `roster`,
`rosterjob-updates`, `signer`, `teller`, `yearend`

The shared linter config lives at `.golangci.yml` in the repo root and is
referenced from each module job via `--config=../.golangci.yml`.

### Adding a Markdown Lint Job

To add rumdl as a pre-commit job alongside the Go formatters:

```yaml
pre-commit:
  parallel: true
  jobs:
    - name: rumdl
      glob: '*.md'
      run: rumdl check --fix --config .vale/.vale.ini {staged_files}
      stage_fixed: true
    # ... existing fmt-<module> jobs
```

Note: no `root` is set so the job runs from the repo root and `{staged_files}`
expands to the full relative paths of all staged `.md` files.
