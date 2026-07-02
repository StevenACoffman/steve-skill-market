---
name: test-helper-process-subprocess-mock
description: |
  When production code calls exec.Command to run an external binary, or when
  you need to simulate subprocess failure modes (non-zero exit, garbage stdout,
  crash) that a real binary cannot produce on demand. Make *exec.Cmd creation
  injectable via a commandFactory field; in tests supply helperProcess(), which
  re-executes the test binary itself with TestHelperProcess and
  GO_WANT_HELPER_PROCESS=1. Do not use for HTTP services (use httptest) or
  databases (use testcontainers).
tags: [go, testing, subprocess, exec, mocking, testable-code]
allowed-tools: Bash, Read, Edit
---

# Test Helper Process Subprocess Mock

## R — Rule

## Current State

exec.Command usage in production code (subprocess calls to mock):
!`grep -rn 'exec\.Command\|exec\.CommandContext' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Existing subprocess mock patterns:
!`grep -rn 'GO_WANT_HELPER_PROCESS\|TestHelperProcess\|helperProcess' --include='*.go' . 2>/dev/null | grep -v vendor | head -5`

os.Exec or os/exec imports:
!`grep -rln '"os/exec"' --include='*.go' . 2>/dev/null | grep -v vendor | head -5`

When code calls `exec.Command` to run an external binary, the subprocess is a
testability boundary. Two options exist.

**Option 1 — Execute the real binary.** Guard with `exec.LookPath` and skip if
the binary is absent:

```go
var testHasGit bool

func init() {
	if _, err := exec.LookPath("git"); err == nil {
		testHasGit = true
	}
}

func TestGitGetter(t *testing.T) {
	if !testHasGit {
		t.Log("git not found, skipping")
		t.Skip()
	}
	// …
}
```

**Option 2 — Mock the subprocess.** You still actually execute something—but
you are executing a mock. Make the `*exec.Cmd` configurable and pass in a
custom one. This technique comes from the Go standard library; it is how they
test `os/exec`. HashiCorp uses it for `go-plugin` and more.

**Get the `*exec.Cmd`:**

```go
func helperProcess(s ...string) *exec.Cmd {
	cs := []string{"-test.run=TestHelperProcess", "--"}
	cs = append(cs, s...)
	env := []string{
		"GO_WANT_HELPER_PROCESS=1",
	}
	cmd := exec.Command(os.Args[0], cs...)
	cmd.Env = append(env, os.Environ()...)
	return cmd
}
```

**What it executes (`TestHelperProcess`):**

```go
func TestHelperProcess(*testing.T) {
	if os.Getenv("GO_WANT_HELPER_PROCESS") != "1" {
		return
	}
	defer os.Exit(0)

	args := os.Args
	for len(args) > 0 {
		if args[0] == "--" {
			args = args[1:]
			break
		}
		args = args[1:]
	}

	cmd, args := args[0], args[1:]
	switch cmd {
	case "foo":
		// implement mock behavior for "foo"
	}
}
```

`TestHelperProcess` returns immediately when `GO_WANT_HELPER_PROCESS` is not
set, so normal `go test` runs are unaffected. When it is set, the function
implements mock subprocess behavior by switching on the command arguments.

______________________________________________________________________

## I — Insight

**The mechanism.** `os.Args[0]` inside a running test binary is the path to the
compiled test binary itself. `helperProcess` constructs a command that
re-invokes that same binary with `-test.run=TestHelperProcess`, causing `go test`'s runner to call only `TestHelperProcess`. The `GO_WANT_HELPER_PROCESS=1`
environment variable acts as a gate: without it, `TestHelperProcess` returns
immediately (zero cost during normal runs); with it, the function becomes the
mock process.

**Why this works structurally.** The real production code calls
`cmd.Run()` or `cmd.Output()` on a `*exec.Cmd` like any other subprocess. From
the OS's perspective, a subprocess was started; it ran and exited. From the
test's perspective, the subprocess's stdout, stderr, and exit code are fully
under the test's control via the switch statement in `TestHelperProcess`.

**The injection seam.** Production code must accept a command factory rather
than calling `exec.Command` directly:

```go
type Runner struct {
	// commandFactory defaults to exec.Command in production.
	// Tests inject helperProcess.
	commandFactory func(name string, arg ...string) *exec.Cmd
}

func NewRunner() *Runner {
	return &Runner{commandFactory: exec.Command}
}
```

Without this seam, the subprocess cannot be redirected to the mock—this is the
standard "make exec.Cmd configurable" requirement that enables the whole pattern.

**Decision rule.** Prefer Option 1 (real binary) when:

- The binary is reliably present in CI (installable as a dependency).
- Running it produces no harmful side effects (git read operations, terraform
  validate, etc.).
- Test correctness matters more than isolation speed.

Use TestHelperProcess when:

- The binary may be absent on some machines (embedded CI, minimal containers).
- You need to simulate failure modes: non-zero exit, corrupted stdout, timeout.
- The binary has side effects that are unsafe or slow in tests (write to remote
  state, make network calls, modify filesystem).

______________________________________________________________________

## A1 — Anchoring Cases

**Case 1: Go stdlib os/exec test suite — the origin.** Hashimoto encountered
the pattern while reading the Go standard library's source for the `os/exec`
package. The stdlib itself uses `TestHelperProcess` to test its own subprocess
infrastructure—the test binary re-executes itself to simulate various child
process behaviors. This origin gives the pattern first-party legitimacy: any
team that reads Go stdlib tests has implicitly been exposed to it. It is not a
HashiCorp invention; it is a pattern endorsed by the Go core team.

> "I specifically remember I got from the Go standard library and thought was
> genius whoever did that in the Go standard library… it's actually how they
> test os/exec."

**Case 2: HashiCorp go-plugin.** `go-plugin` is HashiCorp's library for
building plugin systems over RPC—plugins run as child processes and communicate
over stdin/stdout or a network. The test suite uses `TestHelperProcess` to test
the full subprocess lifecycle: launch, RPC handshake, mid-flight crash
simulation, and clean shutdown. No real plugin binary needs to be compiled and
present in the test tree. The mock subprocess implements different behaviors
(clean exit, panic, protocol error) by switching on the arguments passed by
`helperProcess`. This is the most complete production use of the pattern in the
HashiCorp ecosystem.

> "You still actually execute something—but you are executing a mock. Make the
> \*exec.Cmd configurable and pass in a custom one. HashiCorp uses it for
> go-plugin and more."

**Case 3: TestGitGetter with Option 1 — the decision tree.** Terraform's `git`
getter (the code that fetches Terraform modules from git repos) uses Option 1:
it guards with `exec.LookPath("git")` in an `init()` function, sets a boolean,
and calls `t.Skip()` in any test function when git is absent. This is the right
choice for git because: the binary is available in Terraform's CI, git read
operations (clone, fetch) have no harmful side effects, and testing against the
real git exercises actual protocol behavior (SSH authentication, ref resolution,
sparse checkout) that would be cumbersome to simulate. TestGitGetter shows that
Option 2 is not always the answer—the decision is driven by binary availability
and side-effect risk, not a blanket preference.

______________________________________________________________________

## A2 — Application Triggers

Apply this skill when any of these situations arise:

- "My code calls `exec.Command` to run an external tool (git, terraform,
  kubectl, ffmpeg, openssl…). How do I test without the real binary?"
- "I want to simulate subprocess failure in tests: non-zero exit code, garbage
  stdout, early termination."
- "`exec.Command` is called in production code; I need to mock it without
  OS-level tricks or build tags."
- "How do I test code that wraps a CLI tool?"
- "I want to test multiple subprocess behaviors (success, failure, specific
  output) in different test cases."

Do NOT apply this skill for:

- HTTP services or REST APIs — use `net/http/httptest.NewServer()` instead.
- Database dependencies — use testcontainers, `sqlmock`, or an in-process test
  database instead.
- Cases where the real binary is available in CI and has no harmful side
  effects — use Option 1 with `exec.LookPath` and `t.Skip()`.

______________________________________________________________________

## E — Execution Steps

Follow these steps in order when adding the TestHelperProcess pattern to
existing code.

**Step 1 — Make exec.Command injectable.**

Add a `commandFactory` field to the struct that calls the subprocess. Default
it to `exec.Command` in the constructor so production behavior is unchanged:

```go
type Executor struct {
	commandFactory func(name string, arg ...string) *exec.Cmd
}

func NewExecutor() *Executor {
	return &Executor{commandFactory: exec.Command}
}

func (e *Executor) Run(name string, args ...string) ([]byte, error) {
	cmd := e.commandFactory(name, args...)
	return cmd.Output()
}
```

**Step 2 — Write `helperProcess`.**

This lives in a `_test.go` file in the same package. It returns a `*exec.Cmd`
that re-executes the test binary with `-test.run=TestHelperProcess` and the
`GO_WANT_HELPER_PROCESS=1` env var:

```go
func helperProcess(s ...string) *exec.Cmd {
	cs := []string{"-test.run=TestHelperProcess", "--"}
	cs = append(cs, s...)
	env := []string{"GO_WANT_HELPER_PROCESS=1"}
	cmd := exec.Command(os.Args[0], cs...)
	cmd.Env = append(env, os.Environ()...)
	return cmd
}
```

**Step 3 — Write `TestHelperProcess`.**

Also in a `_test.go` file. The guard at the top is mandatory—without it, this
function would run during every normal `go test` invocation:

```go
func TestHelperProcess(t *testing.T) {
	if os.Getenv("GO_WANT_HELPER_PROCESS") != "1" {
		return
	}
	defer os.Exit(0)

	// Strip args before "--"
	args := os.Args
	for len(args) > 0 {
		if args[0] == "--" {
			args = args[1:]
			break
		}
		args = args[1:]
	}

	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "no command")
		os.Exit(2)
	}

	cmd, args := args[0], args[1:]
	switch cmd {
	case "terraform":
		switch {
		case len(args) > 0 && args[0] == "init":
			fmt.Println("Terraform has been successfully initialized!")
			// os.Exit(0) is handled by defer above
		case len(args) > 0 && args[0] == "apply":
			fmt.Fprintln(os.Stderr, "Error: No configuration files found")
			os.Exit(1)
		default:
			fmt.Fprintf(os.Stderr, "unknown subcommand: %s\n", args)
			os.Exit(2)
		}
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", cmd)
		os.Exit(2)
	}
}
```

**Step 4 — Inject `helperProcess` in tests.**

In each test that exercises the subprocess path, set `commandFactory` to
`helperProcess`:

```go
func TestExecutor_TerraformInit_Success(t *testing.T) {
	e := NewExecutor()
	e.commandFactory = helperProcess

	out, err := e.Run("terraform", "init")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !bytes.Contains(out, []byte("successfully initialized")) {
		t.Errorf("expected init success message, got: %s", out)
	}
}

func TestExecutor_TerraformApply_Failure(t *testing.T) {
	e := NewExecutor()
	e.commandFactory = helperProcess

	_, err := e.Run("terraform", "apply")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
```

**Step 5 — Add one case per mock behavior.**

Each distinct subprocess behavior (different command, different exit code,
different stdout) maps to one `case` in the switch in `TestHelperProcess`.
Keep behaviors minimal and deterministic: no sleeps, no randomness, no external
calls inside `TestHelperProcess`.

______________________________________________________________________

## B — Boundaries and Blind Spots

**When to use Option 1 instead.** If the real binary is available in CI,
installable as a test dependency, and running it has no harmful side effects
(e.g., `git status`, `terraform validate`, `kubectl version --client`), use
Option 1 with `exec.LookPath` and `t.Skip()`. Tests against the real binary
exercise actual behavior, including flag parsing, output formatting, and exit
code semantics that the mock may not replicate faithfully.

**Do not use for HTTP services.** If the external dependency is an HTTP API,
use `net/http/httptest.NewServer()` to create a real in-process HTTP server.
It is simpler, better supported, and exercises actual HTTP transport semantics.
TestHelperProcess adds no value here.

**Do not use for database dependencies.** Use `testcontainers-go`, `pgmock`,
`sqlmock`, or an in-process SQLite database. These provide richer query
inspection than subprocess stdout parsing.

**Author blind spot — coverage and debugger confusion.** `TestHelperProcess`
is a real `Test*` function that runs in two modes. Coverage tools count it as
a test but measure coverage only during the "guard returns immediately" path
in normal runs. The mock-behavior branch is exercised only during subprocess
re-execution, which is not attributed to coverage by default. Debuggers and
editors that auto-run test functions may be confused by functions that
conditionally call `os.Exit`. This is a real operational cost the author does
not acknowledge.

**Author blind spot — modern alternatives (era).** This talk predates
`github.com/google/go-cmdtest`, exec-wrapping libraries such as
`github.com/nicholasgasior/gsfmt/execwrap`, and testscript-based integration
test runners. For complex multi-command CLI workflows, `testscript` (from the
`golang.org/x/tools` family) may provide better isolation and reproducibility
than the TestHelperProcess approach. Evaluate modern tooling before committing
to this pattern for new projects.

**The hidden test problem.** `TestHelperProcess` must not be split across test
files carelessly. It is shared state: all subprocess mocks for a package live
in one switch statement. For packages with many different subprocess commands,
the switch can become a maintenance burden. Structure mock behaviors clearly
with comments identifying which test case each case serves.

## Related Skills

- **never-mock-net-conn-use-loopback** (contrasts-with): Both patterns reject shallow, inadequate mocks in favor of real implementations. `TestHelperProcess` rejects OS-level subprocess mocking by re-executing the real test binary. `testConn` rejects `bytes.Buffer` mocks of `net.Conn` by providing a real loopback TCP pair. Same underlying philosophy — "use a real instance of the thing" — applied to different problem domains (subprocesses vs. networking).

______________________________________________________________________

## Provenance

- **Source:** "Advanced Testing with Go" by Mitchell Hashimoto — Part 2 — Writing Testable Code / Subprocessing
