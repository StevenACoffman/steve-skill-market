---
name: cli-secret-handling
description: |
  Use this skill when a CLI needs to accept a SECRET — a value that must not be visible to other
  processes or appear in logs. Secrets include passwords, API keys, tokens, and private credentials.

  WHEN TO CALL: (a) A developer is adding authentication to a CLI and asks how to accept a password,
  API key, or token; (b) a user asks whether an environment variable is a safe way to pass credentials
  to a CLI; (c) code review of a CLI shows a --password, --token, or --api-key flag; (d) a user is
  about to use shell substitution like --password $(cat file.txt) and wants to know if it is safe;
  (e) a user asks "how should my CLI accept credentials?"
tags: [cli, security, secrets, credentials, authentication]
---

# CLI Secret Handling

## R — Original Text (Reading)

> **Do not read secrets directly from flags.** When a command accepts a secret, e.g. via a
> `--password` flag, the flag value will leak the secret into `ps` output and potentially shell
> history. And, this sort of flag encourages the use of insecure environment variables for secrets.
>
> **Do not read secrets from environment variables.** Exported environment variables are sent to
> every process, and from there can easily leak into logs or be exfiltrated. Shell substitutions
> like `curl -H 'Authorization: Bearer $BEARER_TOKEN'` will leak into globally-readable process
> state. Docker container environment variables can be viewed by anyone with Docker daemon access
> via `docker inspect`. Environment variables in systemd units are globally readable via
> `systemctl show`.
>
> **Secrets should only be accepted via credential files, pipes, AF_UNIX sockets, secret management
> services, or another IPC mechanism.**
>
> — CLI Guidelines, cli-guidelines.github.io (2020)

______________________________________________________________________

## I — Methodological Framework (Interpretation)

CLI secrets have two distinct and independent threat surfaces. Understanding both is necessary
because each must be closed with a different defense.

### Threat 1: Flags Expose Secrets to Process Inspection

When a flag value like `--password s3cr3t` is passed on the command line, that value is part of
the process's argument list. Any process on the same system can read it via `ps aux` — no elevated
privilege required. The value also persists in the user's shell history file. Flags are inherently
a broadcast channel on multi-user or multi-process systems.

The Bash workaround `--password $(< password.txt)` does not fix this. The shell performs the
substitution before exec; the expanded plaintext value becomes the argument string and is therefore
still visible in `ps` output. This anti-pattern creates false confidence.

### Threat 2: Environment Variables Expose Secrets to Child Processes and Inspection Tools

Exported environment variables are inherited by every child process spawned. A subprocess that
logs its environment (common in debug modes), crashes with an env dump, or is controlled by an
attacker inherits all exported vars, including secrets. Additionally:

- Shell substitutions such as `curl -H "Authorization: Bearer $TOKEN"` expand the secret into
  the process argument list, reproducing Threat 1 with an additional attack surface.
- `docker inspect <container>` reveals all environment variables to anyone with Docker daemon
  access — a much larger group than those with shell access to the container.
- `systemctl show <unit>` exposes environment variables in systemd units to unprivileged users.

Environment variables are often presented as a safe alternative to flags because they are not
visible in `ps` output when set correctly (without shell substitution). This is incomplete: the
inheritance and inspection threats remain.

### Secure Alternatives

The following channels do not expose secrets to the threats above:

| Method                      | How to implement                                   | Notes                                                                      |
| --------------------------- | -------------------------------------------------- | -------------------------------------------------------------------------- |
| Credential file (path flag) | `--password-file /run/secrets/token`               | Read the file contents inside the process; path is in `ps`, not the secret |
| stdin pipe                  | `echo $TOKEN \| mycli --token-stdin` or convention | Only visible while the pipe is open; not in ps or history                  |
| AF_UNIX socket              | Connect to a local socket serving the secret       | No file-system residue; scoped to local user                               |
| Secret management service   | Vault, AWS Secrets Manager, GCP Secret Manager     | Secret never appears in process args or env                                |

The `--password-file` / `--token-file` pattern is the most widely deployable: it requires no
daemon, works everywhere, and keeps the secret value entirely within the process.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: the `--password-file` Pattern

- **Problem:** A CLI needs to authenticate with a remote service and the developer considers
  adding a `--password` flag for convenience.
- **Application:** Instead of accepting the secret value directly, the CLI accepts a path:
  `--password-file /run/secrets/db_password`. The process opens the file and reads the secret
  internally. The process argument visible in `ps` is the file path, not the secret.
- **Result:** Neither `ps` output nor shell history contains the credential. File permissions on
  the credential file control who can read it, which is the appropriate access-control mechanism.

### Case 2: the `$(< password.txt)` Bash Anti-Pattern

- **Problem:** A developer knows that plain `--password s3cr3t` leaks to `ps`, and uses the
  Bash substitution `--password $(< password.txt)` believing this reads from a file safely.
- **Application:** The substitution happens in the shell before the process is exec'd. By the
  time the CLI process starts, its argument list already contains the plaintext secret. The `ps`
  leak is identical to the naive case.
- **Result:** This pattern provides no security improvement over `--password s3cr3t` while
  creating a false impression of safety. The correct fix is `--password-file password.txt` so the
  path — not the value — is the argument.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A developer is building their first authenticated CLI and asks: "How should my CLI accept an
   API key or password?"
2. A developer is reviewing a PR and sees `--api-key` or `--token` flag definitions.
3. A user asks: "Is it safe to use `MYAPP_API_KEY` as an environment variable instead of a flag?"
   (The answer is: both are insecure for secrets in most contexts.)
4. A developer writes a shell script that calls a CLI with `--password $(cat ~/.secrets/pw)` and
   asks if this is the right approach.
5. A developer is adding Docker or systemd deployment for a CLI-based service and asks how to
   pass credentials to the container or unit.

### Language Signals (Activate When These Appear)

- "How should my CLI accept a password / API key / token / secret?"
- "Is it safe to use an environment variable for credentials?"
- "My CLI needs to authenticate with an external service"
- "--password flag" or "--token flag" in code or conversation
- "I'm using `MYAPP_SECRET` as an env var, is that OK?"
- "Should I use `--password $(cat ...)`?"

### Distinguishing from Adjacent Concerns

- Difference from general CLI flag design: this skill applies only when the value is a secret.
  For non-secret configuration (URLs, regions, timeouts), flags and environment variables are
  both fine — do not apply this skill.
- Difference from secret manager integration guides: this skill covers the CLI interface contract
  (how the secret enters the process). It does not cover how to configure Vault, AWS Secrets
  Manager, or Kubernetes Secrets — consult those tools' documentation for provisioning.

______________________________________________________________________

## E — Execution Steps

1. **Classify the value: is it a secret?**

   - A value is a secret if its exposure to other processes, logs, or inspection tools would
     constitute a security breach (passwords, API keys, tokens, private keys).
   - Non-secrets (endpoints, regions, feature flags): environment variables and flags are fine.
     Stop here.
   - Completion criteria: explicit yes/no on whether the value is a secret.

2. **Remove any existing `--password`, `--token`, or `--api-key` direct-value flags**

   - Direct-value secret flags expose the secret to `ps` and shell history.
   - Completion criteria: no flag definition accepts a raw secret value.

3. **Remove or guard any environment variable secret reads**

   - If the CLI currently reads `os.Getenv("MYAPP_SECRET")` and uses it as a secret, audit
     every path where the secret could be logged, passed as a subprocess argument, or inherited.
   - Shell substitution patterns in documentation or examples (e.g. `--token $MY_TOKEN`) must
     be replaced with file-based alternatives.
   - Completion criteria: no raw secret value is constructed from an env var and passed as a
     subprocess argument or written to a log.

4. **Implement a `--password-file` / `--token-file` flag**

   - The flag accepts a filesystem path. The process opens the file and reads the secret value
     internally (trim whitespace). The path is what appears in `ps` — not the secret.
   - Completion criteria: a `--token-file PATH` (or equivalent) flag exists and is documented
     as the primary credential input method.

5. **Optionally implement stdin pipe support**

   - A `--token-stdin` flag, or detection that stdin is a pipe, allows `echo $TOKEN | mycli`.
   - Completion criteria (optional): stdin pipe works and is documented.

6. **Update documentation and examples**

   - Remove all examples using `--password $(...)` substitutions.
   - Show `--token-file /run/secrets/token` as the canonical example.
   - Completion criteria: no documentation example exposes a raw secret in a shell argument.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The value is not a secret: environment variables and flags are appropriate for API endpoint
  URLs, AWS regions, log levels, feature flags, timeouts, and other non-credential configuration.
- The environment variable is injected by a secrets manager (Vault Agent, AWS Secrets Manager
  sidecar, Kubernetes Secrets volume mount) and is never placed directly in shell substitutions
  or process argument lists. In managed injection contexts, the secrets manager is the security
  boundary; this skill's threat model does not apply to the injection mechanism itself.

### Counter-Examples (Common Misconceptions)

- **ce01 — "Env var is safer than a flag"**: A common belief is that `MYAPP_API_KEY=secret mycli`
  is a safe alternative to `mycli --api-key secret` because the secret does not appear in `ps`.
  This is partially true — the env var avoids the `ps` leak — but false overall: the env var is
  still inherited by all child processes, can be exfiltrated via subprocess logging, and is
  exposed by `docker inspect` and `systemctl show`. Both flags and env vars are insecure for
  secrets. Neither is the answer; credential files or pipes are.

- **ce02 — "$(< file) reads from a file, so it must be safe"**: The Bash substitution
  `--password $(< password.txt)` expands before exec. The resulting process argument is the
  plaintext secret. This is identical in behavior to `--password s3cr3t` from a `ps` perspective.
  The file read happens in the shell, not in the process; the security boundary is not preserved.

### Author's Notes / Limitations

- The guide acknowledges that stdin pipe (`mycli --token-stdin`) is secure but requires
  caller discipline: the pipe must be constructed so the secret is not in the shell's command
  history. `echo $TOKEN | mycli` still expands `$TOKEN` in the shell's argument list for `echo`,
  though it does not appear in the `mycli` process args. For highest assurance, use
  `mycli --token-file /run/secrets/token` rather than a pipe.
- AF_UNIX sockets and secret management service integrations are listed as secure options but
  require infrastructure setup beyond the CLI itself. For CLIs distributed to end users,
  `--password-file` is the most universally deployable secure option.
- The guide does not address TTY-based prompting (`getpass`/`stty -echo`). Interactive password
  prompts are also secure (the value is never in a process arg or env) but are not suitable for
  automation contexts.

______________________________________________________________________

## Related Skills

- **composes-with** `cli-configuration-hierarchy`:
  Secrets are a special category of configuration value. Use cli-configuration-hierarchy to
  determine placement in the precedence hierarchy, then apply this skill for the additional
  security constraints that apply when the value is a secret (file-based input, no flags or
  plain env vars).

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Command Line Interface Guidelines" by Aanand Prasad, Ben Firshman, Carl Tashian, Eva Parish (2020, cli-guidelines.github.io) — Configuration — Secrets
