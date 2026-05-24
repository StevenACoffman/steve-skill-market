---
allowed-tools: Bash, Read, Edit
name: testing-go-public-test-api
description: Invoke when multiple packages or external consumers need to test against a Go package's interface, or when consumers duplicate setup code because *_test.go files cannot be imported. Covers the testing.go pattern: factory functions (TestServer, TestConfig), compliance suite functions (TestMyInterface), and mock structs — all exported from a regular .go file importable by other packages.
  one call. The downside: the helpers compile into the production binary, adding
  binary size. For size-sensitive packages, guard with //go:build !production.
source_book: '"Advanced Testing with Go" by Mitchell Hashimoto'
source_chapter: Part 2 — Writing Testable Code / Testing as a Public API
tags: [go, testing, public-api, test-infrastructure, library-design]
related_skills:
  - test-helper-contract            # composes-with: every function exported in testing.go must follow this contract
  - custom-framework-within-go-test # composes-with: the custom harness is often published in testing.go
---

# Export Test Infrastructure in Testing.go as a Package's Public Test API

## Current State

testing.go files (public test API exported for other packages):
!`find . -name 'testing.go' -not -path '*/vendor/*' 2>/dev/null`

Test helpers defined only in \_test.go (not importable by other packages):
!`find . -name '*_test.go' -not -path '*/vendor/*' 2>/dev/null | xargs grep -l 'func Test\|func New.*testing\.T\|func Setup' 2>/dev/null | head -8`

Packages that import test helpers from sibling packages:
!`grep -rn '".*test\|testutil\|testhelper\|testing"' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Raw Source

> Newer HashiCorp projects have adopted the practice of creating `testing.go` or
> `testing_*.go` files. These export APIs for the sole purpose of providing mocks,
> test harnesses, and helpers. They allow other packages to test using our package
> without reinventing the components needed to meaningfully use our package in a
> test.
>
> **Example: config file parser**
>
> ```go
> TestConfig(t)        // Returns a valid, complete configuration for tests
> TestConfigInvalid(t) // Returns an invalid configuration
> ```
>
> **Example: API server**
>
> ```go
> TestServer(t)(net.Addr, io.Closer)
> // Returns a fully started in-memory server (address to connect to)
> // and a closer to shut it down.
> ```
>
> **Example: interface for downloading files**
>
> ```go
> TestDownloader(t, Downloader)
> // Tests all the properties a Downloader should have.
>
> type DownloaderMock struct{}
> // Implements Downloader as a mock, allowing recording and replaying of calls.
> ```

## — Mitchell Hashimoto, "Advanced Testing with Go" (GopherCon), Part 2: Testing as a Public API

Vault confirms the public-contract intent: "Vault actually exports a function for
you in Go to create a fully in-memory non-durable server that is Vault so you
could actually create a Vault client connect to it and test communicating with it
and it's a publicly supported exported API." (secondary transcript)

On the behavioral-contract motivation: "If we download without the destination
directory existing we expect you to create that directory — we can't represent
that in Go's type system so that's an implementation detail that's easy to miss
when you're implementing a Downloader." (secondary transcript)

______________________________________________________________________

## I — Interpretation

### The Core Problem

In Go, `*_test.go` files are invisible outside their own package. Any test helper
written in `server_test.go` cannot be called by an integration test in a sibling
package. Every team that depends on your package must recreate your test
infrastructure from scratch — they parse config structs they don't fully
understand, boot servers they don't know how to configure, and write mocks that
may silently diverge from the real behavior.

### The Mechanism

A regular `.go` file named `testing.go` (not `*_test.go`) compiles into the
package binary and is importable. Placing test infrastructure there makes it part
of the package's public contract. The naming convention `TestXxx` signals intent
to readers and `go test` will execute zero-argument `TestXxx(t *testing.T)`
functions as test cases — but functions with additional arguments (like
`TestDownloader(t, impl)`) are not run automatically, which is exactly what
compliance suites need.

### Three Patterns

**Pattern 1 — Factory function.** `TestConfig(t *testing.T) *Config` and
`TestServer(t *testing.T) (net.Addr, io.Closer)`. Accepts `*testing.T`, never
returns an error (calls `t.Fatalf` on failure), returns a ready-to-use value and
optionally a cleanup `io.Closer` or `func()`. Consumers call it in their own
`_test.go` files: `addr, closer := mypkg.TestServer(t); defer closer.Close()`.

**Pattern 2 — Compliance suite.** `TestDownloader(t *testing.T, impl Downloader)`.
Takes an implementation and runs every behavioral assertion that cannot be
expressed as a Go type: ordering, side-effect guarantees, error semantics. Any
team writing a `Downloader` calls this once and immediately verifies their
implementation against the full contract.

**Pattern 3 — Mock struct.** `type DownloaderMock struct { ... }` implementing the
interface, with fields that record calls and allow scripted return values. Teams
that need a test double without building the real thing import this instead of
writing their own.

### The \*\_Test.go Vs Testing.go Distinction

This is the non-obvious architectural decision. Almost all Go developers put
helpers in `*_test.go` because it feels right to keep test code isolated. But
`*_test.go` files cannot be imported — they are opaque to other packages. Only a
regular `.go` file in the package is importable. The cost: the helpers compile
into the production binary. Accept this cost explicitly for library and framework
packages; mitigate it with build tags for size-sensitive applications.

______________________________________________________________________

## A1 — Applied Cases

### Case 1: Vault TestServer(t) — in-Memory Server for External Packages

Vault's `testing.go` exports:

```go
func TestServer(t *testing.T) (net.Addr, io.Closer) {
	// starts a fully in-memory, non-durable Vault instance
	// calls t.Fatalf if setup fails
	// returns the listener address and a closer that shuts down the server
}
```

Any Go package that integrates with Vault (e.g., a secrets rotation service)
adds to its test file:

```go
import "github.com/hashicorp/vault/api"
import vaulttest "github.com/hashicorp/vault/helper/testhelpers/vault"

func TestMyRotator(t *testing.T) {
	addr, closer := vaulttest.TestServer(t)
	defer closer.Close()

	client, _ := api.NewClient(&api.Config{Address: "http://" + addr.String()})
	// test against a real in-memory Vault with no separate process
}
```

The consumer writes zero Vault startup logic. When the Vault team changes
internal startup, they update `TestServer` — all consumers are fixed
automatically. This is a "publicly supported exported API," not a hidden
implementation detail.

______________________________________________________________________

### Case 2: TestConfig(t) / TestConfigInvalid(t) for Config Parsers

A config-parsing package exports:

```go
// testing.go

func TestConfig(t *testing.T) *Config {
	t.Helper()
	return &Config{
		ListenAddr: "127.0.0.1:0",
		DataDir:    t.TempDir(),
		LogLevel:   "warn",
		// ... all required fields set to valid test-appropriate values
	}
}

func TestConfigInvalid(t *testing.T) *Config {
	t.Helper()
	return &Config{
		// deliberately omits required fields to exercise error paths
	}
}
```

Downstream packages write:

```go
func TestServer_rejectsInvalidConfig(t *testing.T) {
	cfg := mypkg.TestConfigInvalid(t)
	_, err := mypkg.NewServer(cfg)
	if err == nil {
		t.Fatal("expected error for invalid config, got nil")
	}
}
```

When `Config` gains a new required field, only `TestConfig` needs updating. All
twenty packages that call it are fixed in one commit.

______________________________________________________________________

### Case 3: TestDownloader(t, Downloader) + DownloaderMock — Behavioral Compliance Suite

A download library exports three artifacts in `testing.go`:

```go
// testing.go

// TestDownloader runs the full compliance suite against any Downloader implementation.
// Call this from your package's _test.go file to verify your implementation.
func TestDownloader(t *testing.T, impl Downloader) {
	t.Helper()

	t.Run("creates destination directory if absent", func(t *testing.T) {
		dir := filepath.Join(t.TempDir(), "does-not-exist-yet")
		err := impl.Download("https://example.com/file.tar.gz", dir)
		if err != nil {
			t.Fatalf("Download returned error: %v", err)
		}
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			t.Fatal("expected destination directory to be created")
		}
	})

	t.Run("returns ErrNotFound for non-existent resource", func(t *testing.T) {
		err := impl.Download("https://example.com/nonexistent", t.TempDir())
		if !errors.Is(err, ErrNotFound) {
			t.Fatalf("expected ErrNotFound, got %v", err)
		}
	})

	// ... more behavioral assertions
}

// DownloaderMock records calls and returns scripted responses.
type DownloaderMock struct {
	DownloadFn func(url, dest string) error
	Calls      []DownloadCall
}

type DownloadCall struct{ URL, Dest string }

func (m *DownloaderMock) Download(url, dest string) error {
	m.Calls = append(m.Calls, DownloadCall{URL: url, Dest: dest})
	if m.DownloadFn != nil {
		return m.DownloadFn(url, dest)
	}
	return nil
}
```

An implementing team writes:

```go
// mydownloader_test.go

func TestMyDownloader_compliance(t *testing.T) {
	dlpkg.TestDownloader(t, &MyDownloader{})
}
```

A consuming team that needs a test double without the real implementation:

```go
func TestProcessor(t *testing.T) {
	mock := &dlpkg.DownloaderMock{
		DownloadFn: func(url, dest string) error { return nil },
	}
	p := NewProcessor(mock)
	p.Run()
	if len(mock.Calls) != 1 {
		t.Fatalf("expected 1 download call, got %d", len(mock.Calls))
	}
}
```

The behavioral contract "create the destination directory if absent" cannot be
expressed in Go's type system. Without `TestDownloader`, every implementor misses
it. With it, every implementor catches it on first run.

______________________________________________________________________

## A2 — Triggers (When to Apply)

Apply this pattern when you encounter any of these:

- "Other packages in our repo need to test against our package. They're
  reimplementing test setup we already have." — Create `testing.go` with factory
  functions so consumers call `mypkg.TestServer(t)` instead of copy-pasting startup code.

- "I have an interface with behavioral contracts that the type system can't
  express. How do I make sure all implementations obey them?" — Export a
  `TestMyInterface(t, impl)` compliance suite in `testing.go` and require all
  implementors to call it.

- "I'm writing a library. How do I give consumers a way to test against it
  without starting a real service?" — Export an in-memory or lightweight server
  constructor in `testing.go` following the `TestServer(t) (net.Addr, io.Closer)`
  shape.

- "Multiple teams implement our storage interface. How do we ensure all
  implementations are correct?" — Export `TestStorage(t, impl)` in `testing.go`.
  Implementors run it; you maintain it once.

- "We keep finding the same bugs in third-party implementations of our interface."
  — The bugs are usually unwritten behavioral contracts. Codify them as assertions
  in a compliance suite and publish it.

______________________________________________________________________

## E — Execution Steps

1. **Identify what consumers need.** Audit which test setups are duplicated across
   packages. Look for: repeated struct initialization with the same field values,
   in-process server startup duplicated across test files, mock structs that
   reimplemented your interface with slightly different behavior.

2. **Create `testing.go` (not `testing_test.go`).** Place it in the package whose
   infrastructure you want to share. The filename `testing.go` is the HashiCorp
   convention; `testing_helpers.go` or `testing_mock.go` are acceptable variants.
   Do not use a `_test.go` suffix — that makes the file non-importable.

3. **Export factory functions following the test-helper contract.**

   ```go
   func TestXxx(t *testing.T) ReturnType {
   	t.Helper()
   	// set up the thing; call t.Fatalf on any error
   	// return the configured instance
   	// if cleanup is needed, register it: t.Cleanup(func() { ... })
   	// or return an io.Closer / func() as a second return value
   }
   ```

   Never return `error`. Never require callers to check for nil returns.

4. **Export compliance suites for interfaces.**

   ```go
   func TestMyInterface(t *testing.T, impl MyInterface) {
   	t.Helper()
   	t.Run("contract: X must do Y", func(t *testing.T) {
   		// assertion
   	})
   	t.Run("contract: Z must return ErrFoo when ...", func(t *testing.T) {
   		// assertion
   	})
   }
   ```

   Name each sub-test with the plain-English behavioral contract it verifies.

5. **Export mock structs for interfaces.**

   ```go
   type XxxMock struct {
   	XxxFn func(context.Context, string) (string, error)
   	Calls []XxxCall
   }

   // implement the interface methods on XxxMock
   ```

   Export the mock so consumers do not each write their own diverging version.

6. **Consumers import and call.**

   ```go
   // in another package's _test.go
   import "github.com/yourorg/yourpkg"

   func TestSomething(t *testing.T) {
   	cfg := yourpkg.TestConfig(t)
   	addr, closer := yourpkg.TestServer(t)
   	defer closer.Close()
   	// test against real infrastructure
   }

   func TestMyImpl_compliance(t *testing.T) {
   	yourpkg.TestMyInterface(t, &MyImpl{})
   }
   ```

7. **Optionally guard with a build tag for size-sensitive packages.**

   ```go
   //go:build !production

   package p
   ```

   Place this at the top of `testing.go` if binary size is a constraint.

______________________________________________________________________

## B — Boundaries and Confusions

### What Belongs in Testing.go

Keep `testing.go` to: factory functions, mock structs, compliance suites, and
simple in-memory server constructors. These are stable and directly serve
consumers.

### What Does NOT Belong in Testing.go

Do not put logic that is only meaningful during a test run but not as an
importable helper. If you write `func TestMyFeature(t *testing.T)` with no
additional arguments in `testing.go`, `go test` will execute it as a test case
in your own package every time someone runs `go test ./yourpkg/...`. This is
usually a mistake — it means you're running your own package's acceptance test
via another package's import. Standalone test functions (zero-argument `TestXxx`)
belong in `_test.go` files.

### Binary Size

`testing.go` compiles into the production binary. For most server applications
and libraries this is inconsequential. For CLIs, embedded binaries, or
size-audited packages, add `//go:build !production` (or equivalent) to exclude it
from release builds.

### Confusion: Testing.go Vs Test-Helper-Contract

The *test-helper-contract* skill governs the function signature of any test
helper: accept `*testing.T`, never return errors, return a cleanup `func()` or
register via `t.Cleanup`. That contract applies equally to helpers in `_test.go`
files and to factory functions in `testing.go`.

The `testing.go` pattern is about *location and importability* — where the helper
lives so other packages can reach it. The two skills are complementary: apply
test-helper-contract to every function you put in `testing.go`.

### Confusion: Testing.go Vs Custom-Framework-Within-Go-Test

The *custom-framework-within-go-test* skill is about writing a reusable test
harness (like `logicaltest.Test(t, TestCase{...})`) for pluggable systems where
many third-party implementations need multi-step acceptance tests. That harness
is itself often published in a `testing.go` file — but the *custom framework*
skill is about the structure of the harness (step-by-step execution, pre/post
hooks), while the `testing.go` skill is about the mechanism that makes it
importable. The two frequently appear together.

### Confusion: Testing.go Vs \_Test.go Package-Level Test Helpers

Some developers write helpers in `package foo_test` (external test package). This
is correct for tests within the same repository but still cannot be imported by a
third package. Only `package foo` (no `_test` suffix) in a non-`_test.go` file is
importable. If you need cross-package or third-party use, `testing.go` in the
main package is required.

## Related Skills

- **test-helper-contract** (composes-with): Every factory function and compliance suite exported in `testing.go` must follow the helper contract — accept `*testing.T`, never return errors, call `t.Fatalf` internally, register cleanup via `t.Cleanup` or a returned `func()`. The `testing.go` skill governs *where* helpers live (so they are importable); the helper contract skill governs *how* they are signed.
- **custom-framework-within-go-test** (composes-with): The custom test harness (e.g., `logicaltest.Test(t, TestCase{...})`) is typically published in a `testing.go` file so plugin authors in other packages can import and call it. The custom framework skill defines the *structure* of the harness (steps, PreCheck, cleanup); this skill provides the *mechanism* that makes it importable.
