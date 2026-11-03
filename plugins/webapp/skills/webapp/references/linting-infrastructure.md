# Webapp Linting Infrastructure

## Linting Infrastructure

### How the Custom Binary Is Built

webapp does **not** use an upstream golangci-lint release. It builds the binary
from source at `genfiles/go/bin/golangci-lint` using `go build` against the
version pinned in `go.mod`, stamped with `main.version=khan-local`. This means
the exact binary version is tied to the repo's Go module graph.

In addition to the upstream binary, webapp compiles 30 custom linter plugins as
Go shared objects (`-buildmode=plugin`) under `genfiles/go/plugins/linters/*.so`.
Every rule prefixed `ka-` in SKILL.md's Quick-Reference Cheat Sheet comes from one of these plugins.

### Rebuilding the Linting Tools

Two Make targets handle this (both live in the root `webapp/` Makefile):

```bash
# Rebuild only the golangci-lint binary
# Deps: go.mod, current Go version
make -B genfiles/go/bin/golangci-lint

# Rebuild the binary AND all 30 custom plugin .so files
# This is what runlint/quicklinc actually need
make -B go_lint_deps
```

`-B` forces an unconditional rebuild regardless of timestamps — use it when the
binary or a plugin is stale or missing. Without `-B` Make skips the target if
the output file already exists and its declared inputs haven't changed.

`go_lint_deps` is the target called by `dev/testing/cmd/runlint` before linting.
Running it manually is the right fix when `make lint` or `make linc` fails with
a plugin load error or a binary-not-found error.

### Custom Plugin List

Each plugin source lives at `dev/linters/plugins/<name>/main.go` and compiles
to `genfiles/go/plugins/linters/<name>.so`:

| Plugin                   | Rule enforced (see SKILL.md's rule sections)     |
| ------------------------ | ------------------------------------------------ |
| `always-close`           | `ka-always-close` — defer Close on io.Closer     |
| `backfill-cedar`         | enforces backfill patterns                       |
| `banned-symbol`          | `ka-banned-symbol` — forbidden APIs              |
| `cache`                  | `ka-cache` — cache ordering rules                |
| `compare`                | `ka-compare` — use `.Equal`/`.Before`/`.After`   |
| `context`                | `ka-context` — ctx first param, no Background    |
| `context-interface`      | `ka-context-interface` — embed only what you use |
| `cross-service`          | `ka-cross-service` — genqlient call boundaries   |
| `datastore-model`        | `ka-datastore-model` — model struct rules        |
| `datastore-not-found`    | `ka-datastore-not-found` — no (nil, nil) return  |
| `datastore-transaction`  | `ka-datastore-transaction` — re-init in closure  |
| `deprecated-terminology` | `ka-deprecated-terminology` — banned word list   |
| `documentation`          | `ka-documentation` — exported fn doc comments    |
| `errors-arguments`       | `ka-errors-arguments` — Is/As arg order          |
| `errors-stacktrace`      | `ka-errors-stacktrace` — wrap third-party errors |
| `errors-wrap`            | `ka-errors-wrap` — odd arg count, string keys    |
| `eval-component`         | `ka-eval-component`                              |
| `genqlient`              | `ka-genqlient` — genqlient usage rules           |
| `graphql-task`           | `ka-graphql-task`                                |
| `http-return`            | `ka-http-return` — return after http.Error       |
| `import`                 | `ka-import` — service/pkg boundary enforcement   |
| `json-tag`               | `ka-json-tag` — explicit json struct tags        |
| `linewrap`               | `ka-linewrap` — 80/100 char line limits          |
| `log`                    | `ka-log` — no fmt.Sprintf in log messages        |
| `log-or-return-error`    | `ka-log-or-return-error` — log OR return         |
| `no-screaming-snake`     | `ka-no-screaming-snake` — no SCREAMING_SNAKE     |
| `permissions`            | `ka-permissions` — resolver permission checks    |
| `resolver-error`         | `ka-resolver-error` — error in response struct   |
| `suite`                  | `ka-suite` — khantest.Suite assertions           |
| `visiblity`              | `ka-visibility` — `_`-prefixed file-private      |
