---
name: cli-configuration-hierarchy
description: |
  Use this skill when a user needs to decide where to put a CLI configuration
  value — whether that is a flag, an environment variable, a project-level config
  file, a user-level config file, or a system-wide config — or when designing the
  full configuration system for a new CLI tool.

  Trigger signals:
  - "Where should my CLI store the API endpoint / region / base URL?"
  - "Should I use a flag or an env var for this setting?"
  - "My users have to retype the same flags every time — is there a better way?"
  - "What's the right precedence order for flags vs env vars vs config files?"
  - "Should this go in a .env file or a real config file?"
  - Developer designing a CLI's configuration system for the first time
  - Any question of the form "how should my CLI accept <X>?"

  Do NOT use this skill when:
  - The question is specifically about secrets (tokens, passwords, private keys) —
    use cli-secret-handling instead, which covers the security considerations that
    this skill explicitly defers.
  - The question is about CLI output formatting or interface stability — see
    cli-interface-stability instead.
  - The configuration question is about a server or library, not a command-line tool.

  Based on: "Command Line Interface Guidelines" by Aanand Prasad, Ben Firshman,
  Carl Tashian, Eva Parish (2020, cli-guidelines.github.io).
source_book: "Command Line Interface Guidelines" by Aanand Prasad, Ben Firshman, Carl Tashian, Eva Parish
source_chapter: Configuration
tags: [cli, configuration, flags, env-vars, xdg, precedence, dotfiles]
related_skills:
  - slug: cli-secret-handling
    relation: composes-with
  - slug: cli-interface-stability
    relation: composes-with
---

# CLI Configuration Hierarchy

## R — Original Text (Reading)

> Command-line tools have lots of different types of configuration, and lots of
> different ways to supply it (flags, environment variables, project-level config
> files). The best way to supply each piece of configuration depends on a few
> factors, chief among them specificity, stability and complexity.
>
> Apply configuration parameters in order of precedence. Here is the precedence
> for config parameters, from highest to lowest: **Flags** / The running shell's
> **environment variables** / **Project-level configuration** (e.g. .env) /
> **User-level configuration** / **System wide configuration**
>
> Follow the XDG-spec. In 2010 the X Desktop Group, now freedesktop.org, attempted
> to solve the problem of configuration files. One goal was to limit the proliferation
> of dotfiles in a user's home directory by supporting a general-purpose
> `~/.config` folder.
>
> — *Command Line Interface Guidelines*, Aanand Prasad et al. (2020)

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Every configuration value has two defining properties: **how often it changes**
(per-invocation vs. session-stable vs. project-stable) and **who it varies for**
(this run, this user/machine, or the whole project team). Mapping those two axes
to the right mechanism eliminates the most common CLI configuration mistakes —
flags that repeat on every run, env vars used for team-wide settings, project
dotfiles that leak credentials into version control.

### The Two-Axis Decision

| Changes how often? | Varies for whom?         | Correct mechanism                                                   |
| ------------------ | ------------------------ | ------------------------------------------------------------------- |
| Every invocation   | Just this run            | Flag (required or optional)                                         |
| Session or machine | This user / this machine | Environment variable (optionally also a flag for override)          |
| Project lifetime   | All users on the project | Version-controlled config file (Makefile, docker-compose.yml, etc.) |

### The Precedence Hierarchy (Highest to Lowest)

```text
1. Flags               ← always win; per-invocation, explicit
2. Shell env vars      ← per-user/per-session override
3. Project-level .env  ← per-project defaults, NOT in source control
4. User-level config   ← per-user persistent settings (~/.config/myapp/)
5. System-wide config  ← /etc/myapp/ or OS-level defaults
```

Higher levels always shadow lower levels. A flag value always beats an env var
that beats a project .env entry that beats a user config file entry. Your code
must apply values in this order; never let a lower-precedence source silently
win over a higher-precedence one.

### XDG Base Directory Specification

User-level config belongs in `~/.config/<appname>/` (XDG_CONFIG_HOME), not in
a bespoke `~/.<appname>` dotfile. Using the XDG spec keeps the home directory
clean, gives users a predictable location to find and version their tool configs,
and avoids the dotfile proliferation that pre-XDG tools created.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Docker-Compose.yml as Project-Stable Configuration

- **Setting**: Which services to run, which ports to expose, which volumes to mount.
- **Properties**: Does not change run-to-run; identical for every developer on the
  project; must be reproducible on any machine that clones the repo.
- **Framework applied**: Axis 1 (how often?) → project lifetime. Axis 2 (who?) →
  all users on the project. Decision: version-controlled config file
  (`docker-compose.yml`), checked into source control, read at invocation time.
- **Why not flags**: Retyping `-p 5432:5432 -v ./data:/var/lib/postgres` on every
  `docker run` call is error-prone and non-reproducible across team members.
- **Why not env vars**: The settings are team-wide, not user-specific. An env var
  lives on one machine; a committed file lives in the repo.

### Case 2: HTTP Proxy Setting

- **Setting**: Which proxy server requests should route through.
- **Properties**: Varies per user and per network/machine; does not change within a
  session; is not meaningful to commit to the project repo (different developers
  use different proxies, or none).
- **Framework applied**: Axis 1 → session-stable. Axis 2 → per-user/per-machine.
  Decision: environment variable (`HTTP_PROXY` / `HTTPS_PROXY`), not a `--proxy`
  flag.
- **Why not a flag**: The proxy never changes within a session; making the user pass
  `--proxy http://corp-proxy:8080` on every command is pure noise.
- **Why not project config**: The project team does not share a single proxy;
  committing it would break other users or leak internal network topology.

### Case 3: Debug Output Level

- **Setting**: Whether to emit verbose diagnostic output.
- **Properties**: Changes from run to run (the developer wants it during a specific
  debugging session, not always); not meaningful to persist.
- **Framework applied**: Axis 1 → per-invocation. Decision: flag (`-d` / `--debug`).
- **Why not env var**: Leaving `DEBUG=true` in the environment and forgetting it
  produces noisy output on all subsequent runs unintentionally.
- **Why not config file**: A committed `debug: true` would turn on debug output for
  all users on every run — the opposite of what is intended.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **First-time CLI configuration design**: A developer is building a new CLI and
   realizes they need to accept an API endpoint, a region, an output format, and a
   verbosity level — and has no framework for deciding which mechanism to use for each.
2. **"Retype the same flags every time" complaint**: A user or code reviewer notices
   that every invocation of the tool requires `--region us-east-1 --output json`.
   The question is whether to move these to an env var or a config file, and which.
3. **"Where does the API endpoint go?"**: A user is adding a configurable server URL
   to their CLI and asks whether it should be a flag, an env var like `MYAPP_URL`,
   or a field in a config file.
4. **Precedence bug**: A user reports that their environment variable is being ignored
   because a config file value is winning. The tool has the precedence order wrong.
5. **Team config vs. personal config conflict**: A developer wants to commit default
   settings to the repo so all team members get them without manual setup, but also
   wants each user to be able to override personally without editing the committed file.
6. **Dotfile proliferation**: A user complains that the tool created `~/.mytool` in
   their home directory and asks where it should go instead.

### Language Signals (Activate When These Appear)

- "Should this be a flag or an env var?"
- "Where should I store the config?"
- "Users keep having to pass the same flags every time"
- "How do I let users override the default without changing the project config?"
- "What's the right order of precedence?"
- "Should I read from `.env` or from a real config file?"
- "My tool created `~/.appname` — is that right?"
- "How do I follow XDG?"

### Distinguishing from Adjacent Skills

- Difference from `cli-secret-handling`: This skill covers configuration topology
  and precedence. Secrets (API keys, tokens, passwords) have additional security
  constraints (env var visibility, shell history, keychain integration) covered in
  cli-secret-handling. When the configuration value is a secret, apply
  cli-secret-handling after establishing the placement using this skill.
- Difference from `cli-interface-stability`: Interface stability covers how to
  version and change flags and output formats over time. This skill decides which
  mechanism to use initially.

______________________________________________________________________

## E — Execution Steps

When a user presents a configuration value to place, work through these steps in order.

1. **Identify the stability axis**

   - Ask: Does this value change run-to-run, or is it stable across a session?
   - If it changes run-to-run → it is a flag candidate. Go to step 4.
   - If it is session- or machine-stable → continue to step 2.

2. **Identify the scope axis**

   - Ask: Is this value the same for every developer on the project (all contributors
     share one value), or does it vary per-user or per-machine?
   - If it is project-wide and belongs in version control → it is a config-file
     candidate. Go to step 5.
   - If it varies per-user or per-machine → it is an env var candidate. Go to step 3.

3. **Place as environment variable**

   - Name it `APPNAME_SETTING` in SCREAMING_SNAKE_CASE with the tool name as prefix.
   - Also accept a flag override if users will occasionally need per-invocation
     control (flag wins over env var per the precedence hierarchy).
   - Document the env var name in `--help` output alongside the flag, if both exist.
   - For project-level defaults that vary per-project but not per-user (e.g.,
     a per-repo server URL), also accept `.env` file at project root — but do NOT
     commit secrets to `.env`.

4. **Place as flag**

   - Make it a named flag (`--debug`, `--dry-run`), not a positional argument, if
     the value is optional or boolean.
   - For required per-invocation values that the user will never want to persist,
     make the flag required and document it clearly.
   - Flags always win in the precedence hierarchy; no other mechanism can override them.

5. **Place as version-controlled config file**

   - Use the file format conventional for the ecosystem (YAML, TOML, JSON, Makefile).
   - Commit the file to source control so all team members get the same defaults.
   - Do NOT put secrets, personal paths, or machine-specific settings in this file.
   - For per-user overrides on top of the committed file, layer a user-level config
     at `~/.config/<appname>/config.{yaml,toml}` (XDG_CONFIG_HOME).

6. **Verify the precedence hierarchy is correctly implemented**

   - Confirm the code applies values in this order: flag → shell env var →
     project `.env` → user config → system config.
   - Test: set a value in a lower-precedence source, then override it with a
     higher-precedence source. The higher-precedence value must win silently.
   - Document the precedence order in `--help` and in your tool's README.

7. **Apply XDG for user-level config**

   - Read `XDG_CONFIG_HOME` from the environment; default to `~/.config` if unset.
   - Write user config to `$XDG_CONFIG_HOME/<appname>/`.
   - Never create `~/.<appname>` as the primary config location.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Secrets (API keys, tokens, passwords)**: Env vars for secrets are visible in
  `ps`, shell history, and crash dumps. Use `cli-secret-handling` for the specific
  patterns that apply to sensitive values (keychain, secret files with tight
  permissions, prompting at runtime).
- **Server or library configuration**: The CLI Guidelines are written for interactive
  command-line tools. Configuration patterns for long-running daemons (systemd units,
  12-factor app env injection) or libraries follow different conventions; this
  framework does not apply directly.
- **Arguments vs. options confusion**: This skill addresses where to put a setting
  once you have decided it is configurable. If the question is whether a value should
  be a positional argument vs. a named option vs. a subcommand at all, that is an
  interface design question covered by the broader CLI Guidelines, not by this skill.

### Failure Patterns Warned About by the Guide

- **Using `.env` as a substitute for a real config file**: `.env` is intentionally
  not committed to source control. It has no type system (all values are strings),
  is poorly organized for complex settings, and has encoding edge cases. Using `.env`
  as the primary project configuration file (rather than as a per-project env var
  override layer) creates a configuration system that cannot be versioned or reviewed.
  Use a real config file (YAML/TOML/JSON) committed to the repo for project-stable
  settings, and reserve `.env` for its intended purpose: local env var overrides
  that individual developers do not want to commit.

- **Env vars for secrets (covered separately)**: Environment variables are visible
  to any process that can read `/proc/<pid>/environ` on Linux, appear in `ps auxe`
  output, and are inherited by all child processes. They should not be used as the
  sole mechanism for passing secrets. The cli-secret-handling skill covers the
  correct alternatives.

- **XDG violation — creating `~/.<appname>`**: Creating a bespoke dotfile directly
  in the user's home directory (e.g., `~/.myapp`, `~/.myapprc`) instead of following
  `~/.config/myapp/` clutters the home directory, makes it harder for users to find
  and back up their tool configs, and duplicates the dotfile proliferation problem
  that XDG was designed to solve. The only exception is tools that pre-date XDG
  and must preserve backward compatibility (e.g., `~/.gitconfig`); new tools have
  no excuse.

- **Reversed precedence order**: A flag the user passes on the command line must
  always beat a value in a config file. A config file the user edited must beat a
  system-wide default. Implementing precedence in the wrong order (e.g., reading
  the config file last and having it overwrite the flag) produces inexplicable
  behavior where users cannot override settings, and erodes trust in the tool.

### Author's Limitations / Scope Boundaries

- **Windows paths and registry**: The XDG spec is a Unix/Linux/macOS convention.
  Windows has its own config home (`%APPDATA%`, `%LOCALAPPDATA%`). The CLI Guidelines
  are primarily written from a Unix perspective; cross-platform tools need to handle
  the Windows equivalent separately.
- **Complex config schemas**: The guide describes where to put configuration, not
  how to structure complex nested schemas, validate types, or migrate config formats
  across tool versions. For tools with rich configuration objects, a dedicated config
  schema library (Viper, Cobra, Click) is required beyond what this skill covers.

### Easily Confused Adjacent Practices

- **12-factor app env injection**: 12-factor recommends storing all configuration
  in environment variables for server processes deployed to cloud platforms. This is
  correct for server processes but is not a blanket rule for CLI tools; CLI tools
  interact with users directly and benefit from flags (per-invocation) and user
  config files (persistent personal settings) that server processes do not need.
- **Putting everything in flags**: Some CLI authors default to flags for all
  configuration because it is explicit. This is correct for per-invocation values
  but creates poor UX for settings like `--output-format json` or `--region us-east-1`
  that the user sets once and never wants to retype. Persistent settings belong in
  env vars or user config; flags are for things that legitimately change run-to-run.

______________________________________________________________________

## Related Skills

- **composes-with** [`cli-secret-handling`](../cli-secret-handling/SKILL.md): After
  using this skill to determine that a configuration value should live in an env var
  or config file, apply cli-secret-handling if the value is a secret (token, password,
  key). The placement decision is made here; the security handling is made there.
- **composes-with** [`cli-interface-stability`](../cli-interface-stability/SKILL.md): Once
  flags, env var names, and config file keys are chosen using this skill, cli-interface-stability
  covers how to version them and communicate breaking changes to users over time. Config file
  keys are stable interfaces and are subject to the same deprecation discipline as flags.

______________________________________________________________________

## Audit Information

- **Verification Passed**: Phase 2
- **Source**: CLI Guidelines (cli-guidelines.github.io, 2020) — Configuration section
- **Distillation Date**: 2026-05-05
