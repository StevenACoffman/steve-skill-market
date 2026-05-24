---
name: webapp-make
description: |
  Use when working in github.com/Khan/webapp and need to know which Make
  target to run. Covers service-level targets (check, lint, fix, serve,
  deploy, codegen), root-level targets (deps, tesc, linc, dev server,
  proto, graphql), linting infrastructure targets (go_lint_deps), and
  typical developer workflows. ONLY applies to github.com/Khan/webapp.

  Trigger signals:
  - "how do I run tests in webapp?"
  - "how do I start the dev server?"
  - "how do I rebuild the linter?"
  - "what make target do I use for X in webapp?"
  - "make check vs make tesc vs make lint"
  - Any question about running, building, or deploying a webapp service
allowed-tools: Bash, Read
---

# Webapp Make Targets

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. Do not
> apply these targets or Makefile conventions to any other repository.

The `webapp/` repo uses a two-level Makefile system. The root `Makefile`
covers global concerns (deps, dev server, proto, GraphQL pipeline, incremental
test/lint). Every service under `services/{name}/` has its own thin `Makefile`
that includes `services/Makefile.inc` and aliases the `default_*` rules defined
there.

All paths below are relative to the repo root at `/Users/steve/khan/webapp/`.

______________________________________________________________________

## Structure

```text
webapp/
  Makefile                  ← root targets: deps, tesc, linc, serve, proto, graphql
  services/
    Makefile.inc            ← shared default_* rules for all services
    {service-name}/
      Makefile              ← thin wrapper: sets ENTRYPOINT, includes Makefile.inc,
                              aliases default_* targets
```

A service `Makefile` looks like:

```makefile
ENTRYPOINT = cmd/serve/main.go
include ../Makefile.inc

check: default_check ;
lint: default_lint ;
serve: default_serve ;
# … etc
```

______________________________________________________________________

## Service-Level Targets

Run these from inside `services/{name}/`.

### Testing

| Target           | What it does                                                                                                                        |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `make check`     | Runs `lint` first (fails fast on lint errors), then `gotestsum ./... -- -race` for all Go tests with race detection                 |
| `make allcheck`  | Runs `check` for the service, then also runs `check` in the shared `pkg/` directory — use this for thorough pre-deploy verification |
| `make coverage`  | `go test -race -coverprofile=…` then opens the HTML coverage report in a browser                                                    |
| `make typecheck` | `pnpm typecheck` — TypeScript type check (only in services that have TypeScript)                                                    |

`make check` runs lint as a prerequisite (`default_check: lint`). If lint fails,
tests do not run.

### Linting

| Target      | What it does                                                                                                                                        |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `make lint` | Gets tracked non-symlink files via `git ls-files`, then pipes them to `tools/runlint.sh` — invokes golangci-lint (Go), flake8 (Python), eslint (TS) |
| `make fix`  | Same as lint but passes `--fix` — auto-corrects all fixable violations                                                                              |

Lint only operates on files tracked by git. Untracked new files are not linted
until they are staged or committed.

### Code Generation

Run these after changing a schema file or `analytics_events.yml`.

| Target                | What it does                                                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `make gqlgen`         | Runs `dev/cmd/gqlgen` to regenerate GraphQL server types (resolvers, models) from `*.graphqls` schema files, then triggers the root `make graphql` pipeline                          |
| `make gqlgen_only`    | Runs `dev/cmd/gqlgen` only — skips the root graphql pipeline rebuild; faster for iterating on generated types                                                                        |
| `make genqlient`      | Runs `dev/cmd/genqlient` to regenerate type-safe Go client code from `.graphql` operation files, then updates `graphql-operation-service-mappings`                                   |
| `make genqlient_only` | Runs `dev/cmd/genqlient` only — skips the operation-service-mappings update                                                                                                          |
| `make eventgen`       | Runs `dev/cmd/eventsync` first (syncs event schemas with the central schema registry), then runs `dev/cmd/eventgen` to regenerate event tracking Go code from `analytics_events.yml` |

### CI Verification (Check Generated Files Are Current)

These targets fail if codegen output is stale. CI runs them; you rarely run them
locally unless debugging a CI failure.

| Target                     | What it does                                    |
| -------------------------- | ----------------------------------------------- |
| `make verify-gqlgen`       | Fails if `make gqlgen` would change any file    |
| `make verify-genqlient`    | Fails if `make genqlient` would change any file |
| `make verify-eventgen`     | Fails if `make eventgen` would change any file  |
| `make verify-capabilities` | Verifies `capabilities.go` is up to date        |

### Running and Deploying

| Target                    | What it does                                                                                                                                                                                                                |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `make serve`              | Builds the binary with debug flags (`-gcflags="all=-N -l"`, no optimisations) to `genfiles/go/bin/serve-{name}`, then runs it with `GOOGLE_CLOUD_PROJECT=khan-dev`, `KA_IS_DEV_SERVER=1`, `PORT` from `services/PORTS.toml` |
| `make deploy`             | Runs `verify_build` (checks Go ≥ 1.21, builds binary), runs `make check` (unless `ALREADY_RAN_TESTS=1`), installs deploy Python deps, then calls `deploy/deploy_service.py {service}.yaml`                                  |
| `make deploy-and-promote` | Runs `make check` AND `verify_build`, deploys with `--promote` flag (100% traffic immediately), then sends a Slack announcement to #whats-happening                                                                         |

**Deploy flags:**

```bash
make deploy ALREADY_RAN_TESTS=1      # skip running make check (CI uses this)
make deploy DEPLOY_VERSION=myversion # set an explicit Cloud Run revision name
make deploy-and-promote DEPLOY_VERSION=myversion
```

______________________________________________________________________

## Root-Level Targets

Run these from the repo root `webapp/`.

### Dependencies

| Target          | What it does                                                                                                     |
| --------------- | ---------------------------------------------------------------------------------------------------------------- |
| `make deps`     | Installs everything: `go mod download` + `gotestsum`, `pnpm install --frozen-lockfile` in all services, `flake8` |
| `make fix_deps` | Nuclear: wipes all checksum caches and forces a full reinstall of all deps                                       |
| `make go_deps`  | `go mod download` + builds `genfiles/go/bin/gotestsum`; cleans Go test cache if Go version changed               |

### Incremental Test and Lint (Daily Workflow)

These only operate on files changed relative to the upstream tracking branch
(`@{u}`). They are much faster than full `make check` / `make lint`.

| Target             | What it does                                                                                                                 |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| `make tesc`        | Incremental test + lint of changed files; calls `testing/quicktesc.sh` → `genfiles/go/bin/runtests`                          |
| `make quicktesc`   | Alias for `tesc`                                                                                                             |
| `make linc`        | Incremental lint only; calls `testing/quicklinc.sh` → `genfiles/go/bin/runlint`; also runs `tsc` and `mypy` where applicable |
| `make fixc`        | Incremental lint + auto-fix; same as `linc` but passes `--fix`                                                               |
| `make tesc JOBS=4` | Parallelise the incremental test runner across 4 workers                                                                     |

### GraphQL Pipeline

| Target                                           | What it does                                                                                                                                                        |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `make graphql`                                   | Full pipeline: runs `gengraphql` (TypeScript → unified schema files), then runs `genqlient` in all services                                                         |
| `make gengraphql`                                | Schema compilation only — runs `compile_graphql_schemas_wrapper.js` in `services/queryplanner/`; touches `genfiles/graphql_schema_was_updated` when it changes      |
| `make gqlgen`                                    | Runs gqlgen in every git-tracked service that has a `gqlgen.yml` (parallel, `-P4`), then runs `make graphql`                                                        |
| `make genqlient`                                 | Runs `gengraphql`, then runs genqlient in all services and `pkg/` (parallel, `-j2`), then updates `graphql-operation-service-mappings`                              |
| `make capabilities`                              | Regenerates `capabilities.go` in every service whose `Makefile` has a `capabilities:` target                                                                        |
| `make verify-gengraphql`                         | CI check: fails if schema files are stale                                                                                                                           |
| `make verify-graphql-operation-service-mappings` | CI check: fails if operation→service mapping files are stale                                                                                                        |
| `make gqlflow`                                   | **Stub only** — prints `"Please run 'pnpm gqlflow' from the ../frontend manually."` and exits; the actual TypeScript type generation must be run from `../frontend` |

### Protobuf

| Target               | What it does                                                   |
| -------------------- | -------------------------------------------------------------- |
| `make proto`         | Compiles all `.proto` files → Go, BQ schemas, Java, JavaScript |
| `make proto_deps`    | Installs `protoc` (v22.5) and Go protoc plugins                |
| `make verify-protos` | CI check: fails if any generated proto file is out of date     |

### Dev Server (Docker-Based)

| Target                    | What it does                                                                                   |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| `make serve-fullstack`    | Starts frontend + backend containers (default; same as `make serve`); sets `MODE=fullstack`    |
| `make serve-frontend`     | Frontend container only, pointed at production backend; automatically sets `WORKING_ON=rspack` |
| `make serve-frontend-mfe` | Same as `serve-frontend` but with `MFE=true` for micro-frontend mode                           |
| `make serve-backend`      | Backend container only; sets `MODE=backend`                                                    |
| `make stop`               | Stops all dev server containers                                                                |
| `make logs-dev-server`    | Tails logs from Docker services (`FLAGS=` and `SERVICE_NAME=` accepted)                        |
| `make pubsub-emulator`    | Starts the GCP Pub/Sub emulator on `PORT` (default 8085)                                       |
| `make bigquery-emulator`  | Starts the BigQuery emulator                                                                   |
| `make datastore-emulator` | Starts the Cloud Datastore emulator on `PORT`                                                  |

Dev server targets delegate to `dev/server/`. The `start-dev-server-%` pattern
requires `WORKING_ON=service,service,...` (or `WORKING_ON=NONE`) and Docker to
be installed. The named `serve-*` targets set `WORKING_ON` automatically where
they can; `serve-fullstack` and `serve-backend` still require `WORKING_ON` to be
set by the caller or environment.

### Database Setup

| Target                | What it does                                                                           |
| --------------------- | -------------------------------------------------------------------------------------- |
| `make pg_create`      | Creates local PostgreSQL databases for services that need them                         |
| `make pg_migrate`     | Runs SQL migrations across all services                                                |
| `make sqlgen`         | Generates SQL code in services that use `sqlc`                                         |
| `make current.sqlite` | Downloads a prod Cloud Datastore snapshot for local development (requires gcloud auth) |

### Cleanup

| Target          | What it does                                                                                  |
| --------------- | --------------------------------------------------------------------------------------------- |
| `make clean`    | Removes `.pyc`/`.pyo` files and clears genfiles/genwebpack; safe, selective                   |
| `make allclean` | Nuclear: `git clean -xdff` + clears Go/Python caches, prunes pnpm, destroys Docker containers |

### Setup and Environment

| Target             | What it does                                                                        |
| ------------------ | ----------------------------------------------------------------------------------- |
| `make hooks`       | Installs git hooks (post-merge, post-checkout, post-rewrite) from `tools/githooks/` |
| `make tls-certs`   | Generates TLS certificates for local HTTPS                                          |
| `make check_setup` | Verifies pnpm and watchman are available in PATH                                    |

______________________________________________________________________

## Linting Infrastructure Targets

These targets build the linting tools themselves. Use them when `make lint`,
`make linc`, or `make check` fails with a plugin load error or binary-not-found
error.

| Target                                  | What it does                                                                                              |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `make -B go_lint_deps`                  | Rebuilds the `golangci-lint` binary **and** all 30 custom plugin `.so` files — the complete linting stack |
| `make -B genfiles/go/bin/golangci-lint` | Rebuilds only the golangci-lint binary (not the plugins)                                                  |

`-B` forces an unconditional rebuild. Without it Make skips the target if
existing outputs are newer than their declared inputs. Always use `-B` when
fixing a stale or corrupted toolchain.

webapp does **not** use an upstream golangci-lint release. The binary is built
from source using `go build` against the version pinned in `go.mod`, stamped
`main.version=khan-local`. It then loads the 30 custom `ka-*` linter plugins
(Go shared objects under `genfiles/go/plugins/linters/*.so`) at runtime.
`go_lint_deps` is the target that `dev/testing/cmd/runlint` calls before every
lint run.

______________________________________________________________________

## Key Design Details

**Checksum-based dep caching.** Dep targets (`go_deps`, `npm_deps`, etc.) hash
their input files and skip the install if nothing changed. This survives branch
switches correctly — unlike timestamp-based Make, switching branches and back
does not cause spurious reinstalls. `make fix_deps` wipes all checksums to force
a full reinstall.

**`make check` runs lint first.** `default_check: lint` means lint is a
prerequisite. Lint failures abort the run before any Go test is compiled.

**`make check` auto-bootstraps Go tools.** It explicitly calls
`$(MAKE) -C $(KA_ROOT) go_deps` to ensure `gotestsum` is built. It does **not**
auto-install npm or Python deps; run `make deps` from the root if those are missing.

**`make lint` only sees git-tracked files.** Both `default_lint` and `default_fix`
use `git ls-files -s | grep ^10` to enumerate tracked non-symlink files, then
pipe them to `runlint.sh`. New files must be `git add`-ed before lint sees them.

**`make serve` uses debug build flags.** The binary is built with
`-gcflags="all=-N -l"` (disables inlining and optimisations) so debuggers can
attach cleanly. The binary lands at `genfiles/go/bin/serve-{service-name}`.

**No env setup needed for `make serve`.** It sets all required env vars: `KA_IS_DEV_SERVER=1`, `GOOGLE_CLOUD_PROJECT=khan-dev`, `KA_SERVICE_NAME`, `KA_SERVICE_VERSION` (current timestamp), `NODE_ENV=development`, and `PORT` from `services/PORTS.toml`.

**`make tesc`/`linc`/`fixc` work from service directories.** `Makefile.inc`
defines these targets and they simply delegate to the root Makefile:
`make -C "$(KA_ROOT)" tesc`. You do not need to `cd` to the repo root first.

**`JOBS` flag.** `make tesc JOBS=4` parallelises the incremental test runner.

**`make tesc` vs `make check`.** `tesc` only tests and lints files changed
relative to the upstream tracking branch (`@{u}`) and runs in seconds. `make check`
runs the full suite for the entire service; CI runs it. Use `tesc` during
development, `check` before deploying.

**`make help`.** The root Makefile has a `help` target that prints a concise
summary of the most commonly used targets.

______________________________________________________________________

## Typical Workflows

### First-Time Setup

```bash
cd /Users/steve/khan/webapp
make deps      # install Go, npm, Python dependencies
make hooks     # install git hooks
make pg_create # create local databases (if working on a SQL service)
```

### Daily Development in a Service

```bash
cd services/my-service
make lint     # lint only (make check runs lint too, but this is faster to iterate)
make fix      # auto-fix lint violations
make check    # full suite: lint first, then go tests with -race
make allcheck # check + shared pkg/ tests (more thorough, use before deploying)
```

### After Changing a GraphQL Schema File

```bash
cd services/my-service
make gqlgen # regenerate server types AND triggers root `make graphql`
#   (which runs gengraphql + genqlient across all services)
make check # verify tests still pass
```

`make gqlgen` at the service level chains to the root `make graphql` pipeline,
which runs `gengraphql` (updates `gengraphql/composed_schema.graphql`) and
regenerates genqlient client code in all services.

**Always commit `gengraphql/composed_schema.graphql`** after schema changes —
CI runs `make verify-gengraphql` and fails if this file is stale. If you see
that failure, run from the repo root:

```bash
make -C . gengraphql # regenerate composed_schema.graphql
git add gengraphql/composed_schema.graphql
```

### Before Committing (From Repo Root)

```bash
make tesc # test + lint only what changed since upstream
# or
make linc # lint only, faster
```

### Run a Service Locally

```bash
cd services/my-service
make serve
```

### Deploy

```bash
cd services/my-service
make allcheck           # thorough pre-deploy check (service + pkg/)
make deploy             # verify build + run tests + push to Cloud Run
make deploy-and-promote # verify build + run tests + push + send Slack announcement

# Skip re-running tests (e.g. CI already ran them):
make deploy ALREADY_RAN_TESTS=1

# Set an explicit revision name:
make deploy DEPLOY_VERSION=2026-05-23-my-fix
```

### Fix a Broken Linter

```bash
cd /Users/steve/khan/webapp
make -B go_lint_deps # rebuild golangci-lint binary + all 30 plugins
```

### After a Go Version Upgrade or `make allclean`

```bash
make deps            # rebuilds gotestsum, downloads modules
make -B go_lint_deps # rebuilds golangci-lint + plugins against new Go version
```
