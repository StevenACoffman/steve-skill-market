---
name: climax-cli-scaffold
allowed-tools: Bash, Read, Edit
description: |
  Invoke when initializing a new Go CLI application using the climax scaffold generator,
  when adding new subcommands to an existing climax app, or when a climax app has drifted
  from the canonical ff/v4 pattern and needs to be corrected.

  Specific triggers: "scaffold a new CLI", "add a subcommand to this CLI",
  "climax init", "climax add", "climax lint shows drift", "set up flags-first CLI",
  "structure this as an ff command tree", "add a version command", "add a man page",
  "install climax".

  Do NOT invoke for: CLIs built with cobra, kong, urfave/cli, or other frameworks;
  flag-only programs with no subcommand dispatch; non-Go CLIs.
source: climax (github.com/StevenACoffman/climax — ff/v4-based scaffold generator)
tags: [go, cli, scaffold, ff, flags-first]
related_skills: [go-constructor-option-pattern-selection, go-http-service-di-composition]
---

# Climax CLI Scaffold

## Current State

climax installed:
!`which climax 2>/dev/null || echo "not found — install: go install github.com/StevenACoffman/climax@latest"`

Is this a climax app (climax markers in cmd/cmd.go):
!`grep -l 'climax:name\|climax:root-pkg\|register new commands here' cmd/cmd.go 2>/dev/null && echo "yes" || echo "no (or cmd/cmd.go not present)"`

Commands registered:
!`grep 'New(' cmd/cmd.go 2>/dev/null | grep -v '//' | head -10`

go.mod module path:
!`grep '^module' go.mod 2>/dev/null || echo "no go.mod found"`

Lint status:
!`climax lint . 2>/dev/null || echo "(climax not installed or not a climax app)"`

## R — What Climax Does

Climax is a scaffold generator for Go CLI applications built on [`peterbourgon/ff/v4`](https://github.com/peterbourgon/ff). It generates a one-package-per-command architecture with:

- **Flags-first configuration**: every configurable knob is an `ff.FlagSet` flag, visible via `-h`.
- **Shared I/O threading**: `stdin`/`stdout`/`stderr` are injected top-down through the whole command tree — no `os.Stdout` in command code.
- **Signal-safe shutdown**: `main()` uses `signal.NotifyContext` and a separate `run()` function.
- **AST-aware dispatcher**: `cmd/cmd.go` routes arguments to commands using AST analysis, so it works even after you've edited generated files.

### Commands

| Command                    | What it does                                            |
| -------------------------- | ------------------------------------------------------- |
| `climax init [path]`       | Create a new CLI app skeleton                           |
| `climax add <name> [path]` | Add a new subcommand package                            |
| `climax mango [path]`      | Add a `man` subcommand for roff man pages               |
| `climax lint [path]`       | Check app for structural drift from canonical templates |
| `climax version`           | Print climax's own build info                           |

### Generated Structure

```text
myapp/
  main.go               signal handling, run() delegation, os.Exit
  cmd/
    cmd.go              dispatcher — routes args to commands
    root/root.go        shared Config: Stdin/Stdout/Stderr, Flags, Command
    version/version.go  version command (unless --no-version)
    <name>/<name>.go    one package per subcommand
```

### Dispatcher Markers in `cmd/cmd.go`

Climax reads these comments when running `climax add` to locate insertion points:

```go
// climax:name myapp
// climax:root-pkg root
// climax:env-prefix MYAPP
// climax:imports          ← new import lines go here
// register new commands here   ← New() calls go here
```

---

## I — Interpretation

### The Three-Layer Structural Invariant

Every climax app has exactly three layers that must stay intact:

1. **`main.go`** — `signal.NotifyContext` + `run()` + `os.Exit`. The only place that calls `os.Exit`. No business logic.
2. **`cmd/cmd.go`** — `Run(ctx, args, stdin, stdout, stderr)`. Instantiates root, registers subcommands, parses flags, delegates to `Command.Run`. No flag definitions.
3. **`cmd/<name>/<name>.go`** — `Config` struct + `New(parent)` + private `exec()`. The only place flags are defined and business logic lives.

Drift in any layer is what `climax lint` detects. Common drift: direct `os.Stdout` use, `os.Exit` inside a command, flag binding in `exec()` instead of `New()`.

### Why Flags-First Matters

The invariant "every knob is a flag" means a developer can always run `myapp <command> -h` and see the complete configuration surface. Nothing is hidden in environment variables that aren't registered flags, in hard-coded defaults only visible in source, or in config file keys not reflected in flags. `ff` supports env vars and config files, but they are additive to flags — every option must still be a registered flag.

### Nested Commands Embed Parent Config

A child command does not take `*root.Config` directly — it takes `*parent.Config`, which already contains `*root.Config` transitively. This gives children access to the full I/O set and any parent-level flags without re-declaring them.

```go
// cmd/create/create.go — nested under "config"
type Config struct {
    *config.Config           // not *root.Config
    outputPath string
    Flags   *ff.FlagSet
    Command *ff.Command
}
```

### ExitError for Controlled Exit Codes

When a command needs to exit non-zero without printing an error message (e.g., a `check` command that exits 1 if something is missing), return `root.ExitError(N)`. `main()` intercepts this type and calls `os.Exit(N)` silently.

### Package-Level Mutable State Exceptions

The generated code avoids package-level mutable state. The five permitted exceptions are:

1. Sentinel errors: `var ErrFoo = errors.New("foo")`
2. Blank-identifier interface assertions: `var _ io.Reader = (*MyType)(nil)`
3. The version string: `var Version = "dev"` (overridden by ldflags or build info)
4. Pre-compiled regexps: `var reFoo = regexp.MustCompile(...)` (panic-safe since tested at startup)
5. Embedded files: `//go:embed` directives

No `init()` functions — registration and flag setup belong in `New()`.

---

## A1 — Past Application

### Case 1: Initializing a CLI from Scratch

- **Situation**: New Go module, need a flags-first CLI with version and two subcommands.
- **Steps used**:

  ```bash
  mkdir myapp && cd myapp
  go mod init github.com/org/myapp
  climax init --name "myapp" --short "manage org resources"
  climax add serve --short "start the HTTP server"
  climax add migrate --short "run database migrations"
  go run . --help      # verify dispatch works immediately
  climax lint          # confirm no drift
  ```

- **Result**: Runnable CLI with `myapp serve`, `myapp migrate`, `myapp version` all wired and flag-documented.

### Case 2: Adding a Nested Subcommand

- **Situation**: Existing climax app needs `myapp config set` nested under `myapp config`.
- **Steps used**:

  ```bash
  climax add config --short "manage configuration"
  climax add set --parent config --short "set a config value"
  ```

- **Key detail**: `cmd/set/set.go` embeds `*config.Config`, not `*root.Config`. The `set` command's `New()` receives a `*config.Config` argument, making config-level flags visible to `set`.
- **Result**: `myapp config set --key foo --value bar` works; `myapp config set -h` shows both config-level and set-level flags.

### Case 3: Correcting Structural Drift

- **Situation**: `climax lint` reports that `cmd/serve/serve.go` uses `os.Stdout` directly and binds a flag in `exec()`.
- **Fix**:
  1. Replace `os.Stdout` → `cfg.Stdout` (use the injected writer).
  2. Move flag binding from `exec()` into `New()`, before `cfg.Command` is created.
- **Result**: `climax lint` exits 0; the command is now testable by injecting a `bytes.Buffer` as stdout.

---

## A2 — Trigger Scenario ★

1. "I need to scaffold a new Go CLI" → `climax init`
2. "Add a `deploy` subcommand to this CLI" → `climax add deploy`
3. "Add a `deploy rollback` command nested under `deploy`" → `climax add rollback --parent deploy`
4. "This CLI has no `-h` output for some options" → flags are not registered; every option must be an `ff.FlagSet` flag in `New()`
5. "Tests can't capture this command's output" → command uses `os.Stdout` instead of `cfg.Stdout`
6. "climax lint is failing on CI" → run `climax lint`, read the diff, apply structural fixes
7. "Add a man page to this CLI" → `climax mango`, then `go get github.com/StevenACoffman/mango-ff github.com/muesli/roff`
8. "Embed a version string at build time" → use `-ldflags` or rely on `debug.ReadBuildInfo()` auto-detection

### Language Signals

- "scaffold", "boilerplate", "ff CLI", "flags-first", "peterbourgon/ff"
- "add a subcommand", "climax add", "climax init"
- "command not showing flags in -h"
- "os.Exit inside a command", "direct os.Stdout", "flag binding in exec"
- "climax lint drift"

---

## E — Execution Steps

### Installing Climax

```bash
# Option 1: go install (standard)
go install github.com/StevenACoffman/climax@latest

# Option 2: uv tool (if uv is available)
uv tool install climaxgo

# Verify
climax version
```

### Initializing a New CLI

1. Create the Go module if it doesn't exist: `go mod init <import-path>`
2. Run `climax init [--name <cli-name>] [--short "<description>"] [path]`
   - `--name` allows hyphens; defaults to the last segment of the import path
   - `--env-prefix` defaults to the name uppercased; use `--no-env-prefix` to disable
   - Add `--no-version` to skip the version command
3. Run `go run . --help` to confirm the dispatcher and root flags work
4. Run `climax lint` — should exit 0 on a freshly generated app

### Generated `main.go` Pattern

```go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()
    if err := run(ctx, os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
        var exitErr root.ExitError
        if errors.As(err, &exitErr) {
            os.Exit(int(exitErr))
        }
        fmt.Fprintln(os.Stderr, err)
        os.Exit(1)
    }
}

func run(ctx context.Context, args []string, stdin io.Reader, stdout, stderr io.Writer) error {
    return cmd.Run(ctx, args, stdin, stdout, stderr)
}
```

### Generated `cmd/cmd.go` Pattern

```go
func Run(ctx context.Context, args []string, stdin io.Reader, stdout, stderr io.Writer) error {
    rootCfg := root.New(stdin, stdout, stderr)

    // climax:imports
    versionCfg := version.New(rootCfg)
    // register new commands here

    _ = versionCfg

    if err := rootCfg.Command.ParseFlags(ctx, args, ff.WithEnvVarPrefix("MYAPP")); err != nil {
        fmt.Fprintln(stderr, rootCfg.Command.Help())  // parse error → full root help
        return err
    }

    // post-parse initialization goes here (e.g. set up logger from verbosity flag)

    if err := rootCfg.Command.Run(ctx, args); err != nil {
        if !errors.Is(err, ff.ErrNoExec) {
            fmt.Fprintln(stderr, rootCfg.Command.SelectedCommand().Help())  // run error → selected cmd help
        }
        return err
    }
    return nil
}
```

Key `cmd.go` rules:

- `ff.WithEnvVarPrefix("MYAPP")` is set here in the `ParseFlags` call, not per-command.
- Use `ff.WithEnvVars()` (no argument) instead when `--no-env-prefix` was passed to `climax init`.
- Post-parse initialization (logger setup, config file loading, etc.) happens between `ParseFlags` and `Run`.
- Parse error → print full root help. Run error (non-`ErrNoExec`, non-`ExitError`) → print selected command's help.

### Generated `cmd/<name>/<name>.go` Pattern

```go
type Config struct {
    *root.Config           // or *parent.Config for nested commands
    outputPath string
    Flags   *ff.FlagSet
    Command *ff.Command
}

func New(parent *root.Config) *Config {
    cfg := &Config{
        Config: parent,
    }

    cfg.Flags = ff.NewFlagSet("mycommand").SetParent(parent.Flags)  // chained at creation
    cfg.Flags.StringVar(&cfg.outputPath, 'o', "output", ".", "output directory")

    cfg.Command = &ff.Command{
        Name:      "mycommand",
        ShortHelp: "one-line description",
        Flags:     cfg.Flags,
        Exec:      cfg.exec,
    }

    parent.Command.Subcommands = append(parent.Command.Subcommands, cfg.Command)
    return cfg
}

func (cfg *Config) exec(ctx context.Context, args []string) error {
    // Use cfg.Stdout / cfg.Stderr — never os.Stdout
    // Return errors: fmt.Errorf("mycommand: %w", err) — lowercase, no period
    // Non-zero exit without message: return root.ExitError(1)
    // Graceful shutdown: check ctx.Done()
    return nil
}
```

Critical invariants in `New()`:

- `SetParent` is chained directly on `ff.NewFlagSet(...)` — do not call it separately.
- All `cfg.Flags.*Var(...)` bindings must come before `cfg.Command` is created.
- `parent.Command.Subcommands = append(...)` registers the command in `New()`, not in `exec()`.

### Adding a Shared Root Flag

Root `Config` starts with `cfg.Flags = nil`. To add a shared flag visible across all subcommands:

```go
// cmd/root/root.go — in New()
cfg.Flags = ff.NewFlagSet("myapp")
cfg.Flags.BoolVar(&cfg.Verbose, 'v', "verbose", false, "enable verbose logging")
cfg.Command = &ff.Command{
    Name:  "myapp",
    Flags: cfg.Flags,
}
```

### Adding a Subcommand (Full Workflow)

1. Run `climax add <name> [--short "<desc>"] [--parent <pkg>]`
   - `<name>` is the Go package name (lowercase); `--name` overrides the `ff.Command.Name` display string
   - `--parent <pkg>` is the Go package name of the parent (default: root package)
2. Open `cmd/<name>/<name>.go` — implement the `exec()` method
3. Confirm all flags are bound in `New()` before `cfg.Command` is created
4. Confirm `SetParent` is chained on `ff.NewFlagSet(...)` at creation
5. Run `go run . <name> --help` to confirm flags appear
6. Run `climax lint` to confirm no structural drift

### Testing a Command

```go
func TestMyCommand(t *testing.T) {
    var stdout, stderr bytes.Buffer
    rootCfg := root.New(strings.NewReader(""), &stdout, &stderr)
    _ = mycommand.New(rootCfg)

    err := cmd.Run(
        context.Background(),
        []string{"mycommand", "--output", "/tmp"},
        strings.NewReader(""),
        &stdout,
        &stderr,
    )
    require.NoError(t, err)
    assert.Contains(t, stdout.String(), "expected output")
}
```

No real `os.Stdout` is used — inject `bytes.Buffer` to capture and assert output.

### Version String

The generated `cmd/version/version.go` reads build info automatically via `debug.ReadBuildInfo()`. When installed with `go install github.com/org/myapp@v1.2.3`, the version is set automatically without ldflags.

To override (e.g., for release builds with a dirty tree or custom tag):

```bash
go build -ldflags "-X <module>/cmd/version.Version=$(git describe --tags --always)" -o myapp .
./myapp version
```

### Adding a Man Page

```bash
climax mango [--authors "Your Name"] [--copyright "2025"]
go get github.com/StevenACoffman/mango-ff github.com/muesli/roff
go run . man | man -l -   # preview
```

### Running Climax Lint in CI

```bash
climax lint .
# exits 0 = clean; exits 1 = structural drift detected, output is unified diff
```

---

## B — Boundary

### Do Not Use This Skill When

- The CLI uses cobra, kong, urfave/cli, or any non-ff framework.
- The program has no subcommands and is just a `flags.Parse()` wrapper.
- You are writing a library, not a CLI entrypoint.

### Failure Patterns

- **Binding flags in `exec()` instead of `New()`** — flags are already parsed when `exec` is called; the binding has no effect. Always bind in `New()`.
- **Calling `SetParent` separately instead of chaining** — the generated template chains it: `ff.NewFlagSet("cmd").SetParent(parent.Flags)`. Calling it after flag binding means parent flags may not propagate correctly.
- **Forgetting `parent.Command.Subcommands = append(...)`** — the command is registered in `New()`, not in `exec()`. Skip this and the subcommand never appears.
- **Writing to `os.Stdout` directly** — bypasses the injected writer; the command cannot be tested by capturing output. Always use `cfg.Stdout`.
- **Calling `os.Exit()` inside a command** — prevents deferred cleanup and makes the command untestable. Return `root.ExitError(N)` instead.
- **Using `init()` for setup** — climax constrains: no `init()` functions. Use `New()` for registration and `exec()` for runtime setup.
- **Removing dispatcher markers** — `// climax:imports` and `// register new commands here` allow `climax add` to locate insertion points. Removing them forces full AST analysis (slower, more fragile).
- **Treating `ff.ErrHelp` and `ff.ErrNoExec` as errors** — both must be handled as exit code 0 in `main()`.
- **Putting post-parse initialization in `New()`** — `New()` runs before parsing; flags are not yet resolved. Post-parse setup (logger, derived config) belongs in `cmd.go` between `ParseFlags` and `Run`.

### Related Skills

- **composes_with**: `go-constructor-option-pattern-selection` — the `New()` factory pattern climax generates is an instance of the constructor pattern; functional options can extend it for complex flag sets.
- **composes_with**: `go-http-service-di-composition` — a climax `serve` command's `exec()` is the natural place to wire up an HTTP server using the `run()`/application-struct DI pattern.
