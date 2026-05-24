---
name: go-test-tools
description: Use when the user asks to run tests, write tests, check coverage, debug test failures, or use gotestsum. Covers running and writing Go tests in this 19-module workspace.
allowed-tools: Bash, Read, Edit
---

# Go Test Tools

## Running Tests

This repo is a 19-module Go workspace (`go.work`). Tests run per module — not from the workspace root.

If gotestsum is available it provides colorized output and watch mode; the commands below show both forms. Install it with:

```bash
go install gotest.tools/gotestsum@latest
```

### One Module

```bash
# Plain go test (matches the pre-push hook)
cd MODULE && go test -count=1 -timeout 5m ./...

# With gotestsum (preferred when installed)
cd MODULE && gotestsum -- -count=1 -timeout 5m ./...
```

`-count=1` disables Go's test result cache so tests always run fresh.

### All Modules

```bash
for D in */; do
	[ -f "${D}go.mod" ] || continue
	echo "==> $D"
	(cd "$D" && go test -count=1 -timeout 5m ./...)
done
```

With gotestsum:

```bash
for D in */; do
	[ -f "${D}go.mod" ] || continue
	echo "==> $D"
	(cd "$D" && gotestsum -- -count=1 -timeout 5m ./...)
done
```

### Common Flags

With `go test`, add flags directly:

```bash
cd MODULE && go test -count=1 -timeout 5m -race ./...
cd MODULE && go test -count=1 -v -run TestMyFunction ./...
```

With gotestsum, pass `go test` flags after `--`:

```bash
cd MODULE && gotestsum -- -count=1 -timeout 5m -race ./...
cd MODULE && gotestsum -- -count=1 -v -run TestMyFunction ./...
```

| Flag            | Purpose                                   |
| --------------- | ----------------------------------------- |
| `-count=1`      | Disable result caching (always run fresh) |
| `-timeout 5m`   | Match the pre-push hook timeout           |
| `-race`         | Detect race conditions                    |
| `-run TestName` | Run a specific test or subtest            |
| `-v`            | Verbose: show `t.Log` output              |
| `-short`        | Skip long-running tests                   |
| `-cover`        | Report coverage percentage                |

### Running a Specific Test in a Suite

testify suites are registered as a single top-level `TestXxx` function. To target one test method inside the suite, use `/` to separate the suite function name from the method name:

```bash
# Run the whole suite
cd MODULE && go test -count=1 -run TestMyRepo ./...

# Run one method inside the suite
cd MODULE && go test -count=1 -run TestMyRepo/TestCreateSomething ./...
```

## Test Suite Pattern

Most tests in this repo extend one of two testify suite bases.

### Pure Logic (No External Services) — `khantest.Suite`

Use this when the code under test makes no datastore, pubsub, or network calls.

```go
import "github.com/Khan/districts-jobs/pkg/khantest"

type myThingSuite struct{ khantest.Suite }

func (suite *myThingSuite) TestDoesTheThing() {
	result := DoTheThing("input")
	suite.Require().Equal("expected", result)
}

func TestMyThing(t *testing.T) {
	khantest.Run(t, new(myThingSuite))
}
```

### With Datastore or Other Services — `servicetest.Suite`

Use this when the code under test reads or writes to the datastore emulator.

```go
import "github.com/Khan/districts-jobs/pkg/servicetest"

type myRepoSuite struct{ servicetest.BaseSuite }

func (suite *myRepoSuite) TestCreateSomething() {
	ctx := context.Background()
	dc := suite.Datastore() // acquires an emulator client, reset between tests

	err := repo.CreateSomething(ctx, dc, actorKaid, thing)
	suite.Require().NoError(err)
}

func TestMyRepo(t *testing.T) {
	servicetest.Run(t, new(myRepoSuite))
}
```

The datastore emulator is acquired once per suite and reset before each test in `SetupTest`. It is **not** reset between subtests (`suite.Run`/`t.Run`).

### Suite Lifecycle Order

1. `SetupSuite()`
2. `SetupTest()` — emulator reset happens here
3. `BeforeTest(suiteName, testName string)`
4. `TestYOURNAMEHERE()`
5. `AfterTest(suiteName, testName string)`
6. `TearDownTest()`
7. `TearDownSuite()`

### Table-Driven Tests Inside a Suite

```go
func (suite *myThingSuite) TestProcess() {
	tests := []struct {
		name    string
		input   string
		want    string
		wantErr bool
	}{
		{name: "valid", input: "hello", want: "HELLO"},
		{name: "empty", input: "", wantErr: true},
	}

	for _, tt := range tests {
		suite.Run(tt.name, func() {
			got, err := Process(tt.input)
			if tt.wantErr {
				suite.Require().Error(err)
				return
			}
			suite.Require().NoError(err)
			suite.Require().Equal(tt.want, got)
		})
	}
}
```

### Suite Helper Methods

| Method                                                  | Purpose                                    |
| ------------------------------------------------------- | ------------------------------------------ |
| `suite.Require().NoError(err)`                          | Assert no error; stop the test on failure  |
| `suite.Require().Equal(a, b)`                           | Assert equality; stop the test on failure  |
| `suite.All(suite.Assert().Equal(a,b), suite.Assert()…)` | Run several assertions; stop if any fail   |
| `suite.AddCleanup(fn)`                                  | Run `fn` after the test (LIFO order)       |
| `suite.Setenv(key, val)`                                | Set env var; auto-restore after test       |
| `suite.Unsetenv(key)`                                   | Unset env var; restore original after test |

Use `suite.Require()` (stops the test immediately on failure) by default. Use `suite.Assert()` only inside `suite.All()` — `Assert()` records failures without stopping, so `All()` can collect all failures before halting.

## Linter-Enforced Test Patterns

The `.golangci.yml` enables several test-focused linters. Violations block CI.

### `thelper` — `t.Helper()` in Test Helper Functions

```go
// ✅ correct — failure lines point to the caller, not inside assertThing
func assertThing(t *testing.T, got string) {
	t.Helper()
	if got != "expected" {
		t.Errorf("got %q, want %q", got, "expected")
	}
}
```

### `testifylint` — Use the Right Testify Assertion

| Instead of                         | Use                            | Why                   |
| ---------------------------------- | ------------------------------ | --------------------- |
| `suite.Require().Nil(err)`         | `suite.Require().NoError(err)` | Clearer error message |
| `suite.Require().Equal(true, x)`   | `suite.Require().True(x)`      | More readable         |
| `suite.Require().Equal(0, len(s))` | `suite.Require().Empty(s)`     | Semantic assertion    |
| `suite.Require().Equal(false, x)`  | `suite.Require().False(x)`     | More readable         |
| `assert.Nil(t, err)`               | `assert.NoError(t, err)`       | Clearer error message |

### `usetesting` — Prefer `testing.T` Helpers Over `os` Package

```go
// ❌ flagged by usetesting
os.Setenv("KEY", "val")
dir, _ := os.MkdirTemp("", "test")

// ✅ correct — auto-restored after test
t.Setenv("KEY", "val")
dir := t.TempDir()
```

In suite tests, `suite.Setenv()` also satisfies this linter and uses the suite's cleanup mechanism.

### `tparallel` — `t.Parallel()` Must Be Consistent

If a test calls `t.Parallel()`, all its subtests must also call `t.Parallel()`:

```go
func TestFoo(t *testing.T) {
	t.Parallel()

	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			// ...
		})
	}
}
```

Note: testify suite tests do **not** use `t.Parallel()` — the suite runner manages concurrency.

## Coverage

```bash
cd MODULE && go test -count=1 -coverprofile=coverage.out ./...
go tool cover -func=coverage.out # coverage per function
go tool cover -html=coverage.out # open in browser
go tool cover -func=coverage.out | grep total
```

## Benchmarks

```bash
cd MODULE && go test -bench=. -benchmem ./...
cd MODULE && go test -bench=BenchmarkMyFunc -benchmem ./...
```

## Watch Mode (TDD)

Requires gotestsum:

```bash
cd MODULE && gotestsum --watch -- ./...
cd MODULE && gotestsum --watch --format testdox -- ./...
```

## Output Formats

```bash
cd MODULE && gotestsum --format testname -- ./... # test names only
cd MODULE && gotestsum --format dots -- ./...     # . = pass, F = fail
cd MODULE && gotestsum --format pkgname -- ./...  # group by package
cd MODULE && gotestsum --format testdox -- ./...  # BDD-style output
```

## Rerun Failed Tests

```bash
cd MODULE && gotestsum --rerun-fails -- -count=1 ./...
```

## JUnit XML Output (CI)

```bash
cd MODULE && gotestsum --junitfile junit.xml -- -count=1 ./...
```

## Debugging a Failing Test

```bash
# Verbose output to see t.Log lines
cd MODULE && go test -v -count=1 -run TestSpecificFunction ./...

# Stop after first failure
cd MODULE && go test -count=1 -failfast ./...

# Delve debugger
dlv test ./pkg/mypkg -- -test.run TestSpecificFunction
```
