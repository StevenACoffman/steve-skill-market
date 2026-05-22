---
name: custom-framework-within-go-test
description: Invoke when building a pluggable system where multiple backends or plugins must satisfy the same multi-step acceptance scenario, or when considering a separate test binary or external test runner. Covers building a custom harness (TestCase struct + Test function) as a Go library so go test orchestrates all backends with full -run/-race/-cover support.
source_book: '"Advanced Testing with Go" by Mitchell Hashimoto'
source_chapter: Part 2 — Writing Testable Code / Custom Frameworks
tags: [go, testing, custom-framework, plugin-systems, acceptance-testing]
related_skills:
  - testing-go-public-test-api  # composes-with: the custom harness is published in testing.go to be importable
---

# R — Raw Source

From "Advanced Testing with Go" (Mitchell Hashimoto, GopherCon):

> `go test` is an incredible workflow tool. For complex, pluggable systems,
> write a custom framework *within* `go test` rather than building a separate
> test harness. Examples: Terraform providers, Vault backends, Nomad schedulers.

**Vault logicaltest.Test — the canonical example:**

```go
// Example from Vault
func TestBackend_basic(t *testing.T) {
	b, _ := Factory(logical.TestBackendConfig())
	logicaltest.Test(t, logicaltest.TestCase{
		PreCheck: func() { testAccPreCheck(t) },
		Backend:  b,
		Steps: []logicaltest.TestStep{
			testAccStepConfig(t, false),
			testAccStepRole(t),
			testAccStepReadCreds(t, b, "web"),
			testAccStepConfig(t, false),
			testAccStepRole(t),
			testAccStepReadCreds(t, b, "web"),
		},
	})
}
```

> `logicaltest.Test` is a custom harness that handles repeated setup/teardown,
> assertions, and so on. Terraform provider acceptance tests follow the same
> pattern. We can still use `go test` to run them all.

**Terraform provider acceptance tests (from the talk transcript):**

> Terraform has an acceptance test library… it takes real Terraform
> configurations and then from those configurations it creates real
> infrastructure and… we run these every night… we spin up thousands of
> resources on something like 50 different providers every night… and we use
> `go test` to trigger this even though they're not unit tests.

______________________________________________________________________

## I — Interpretation

**Why a library, not a binary?**

The instinct when facing a pluggable system with multi-step acceptance scenarios
is to build a dedicated test tool — a binary that knows how to configure, run,
and validate plugins. This instinct is wrong because `go test` is already a
powerful runtime. It handles process lifecycle, output formatting, `-run`
filtering, race detection, timeout enforcement, and coverage instrumentation.
A dedicated tool would have to reimplement all of this. A library that accepts
`*testing.T` gets all of it for free.

**The TestCase struct is the public API for plugin authors.**

When you write `logicaltest.Test(t, logicaltest.TestCase{Backend: b, Steps: [...]})`,
you are calling the harness as a library function from a standard `Test*` function.
The harness is invisible to `go test` — it is just Go code executing under a test
function. The result: plugin authors do not need to learn a new tool, a new CLI,
or a new configuration format. They write Go test code.

**Steps replace table cases for stateful scenarios.**

A table-driven test is the right pattern when cases are independent — each row
is a fresh input/output pair. Multi-step acceptance tests are different: each
step produces state that the next step consumes. A role created in step 3 is
read in step 5. A `Steps []TestStep` slice captures this sequential dependency
naturally. The harness executes steps in order, passes state forward, and fails
the test at the first step that fails.

**PreCheck gates expensive infrastructure.**

Acceptance tests that hit real cloud infrastructure must not run on every `go test ./...`. The PreCheck function is the correct gate: check for required
environment variables, call `t.Skip` if they are absent. Unit tests are
unaffected; acceptance tests run only in environments configured for them. This
is a better separation than a separate binary: you get both unit tests and
acceptance tests from a single `go test` invocation, distinguished only by
environment.

**The harness belongs in `testing.go`, not `_test.go`.**

If the harness (the `TestCase` struct and `Test` function) is meant to be
called by plugin authors in other packages, it must be in a non-`_test.go`
file so it is importable. Publishing it in `testing.go` (see the
`testing-go-public-test-api` skill) makes it part of the package's public test
API. Plugin authors import the package and call the harness — they do not copy
it.

______________________________________________________________________

## A1 — Worked Cases

### Case 1: Vault logicaltest.Test — Multi-Step Backend Acceptance Tests

Vault's secret backends (AWS, PKI, SSH, databases, and dozens more) each expose
a different credential issuance workflow, but all share the same abstract
contract: configure the backend, create a role, read credentials. The
`logicaltest` package defines the harness once; each backend's test file
assembles a `TestCase` with backend-specific steps.

```go
// logicaltest/logical_testing.go (the harness — simplified)
package logicaltest

import "testing"

type TestCase struct {
	PreCheck func()
	Backend  logical.Backend
	Steps    []TestStep
	Cleanup  func()
}

type TestStep struct {
	Description string
	Operation   logical.Operation
	Path        string
	Data        map[string]interface{}
	Check       func(resp *logical.Response) error
	ErrorOk     bool
}

func Test(t *testing.T, c TestCase) {
	t.Helper()
	if c.PreCheck != nil {
		c.PreCheck()
	}
	if c.Cleanup != nil {
		defer c.Cleanup()
	}

	for i, step := range c.Steps {
		resp, err := c.Backend.HandleRequest(buildRequest(step))
		if err != nil && !step.ErrorOk {
			t.Fatalf("step %d (%s): request error: %s", i+1, step.Description, err)
		}
		if step.Check != nil {
			if err := step.Check(resp); err != nil {
				t.Fatalf("step %d (%s): check failed: %s", i+1, step.Description, err)
			}
		}
	}
}
```

A new backend author writes:

```go
// backend/aws/aws_test.go
func TestBackend_CredentialRead(t *testing.T) {
    b, err := Factory(logical.TestBackendConfig())
    if err != nil {
        t.Fatalf("factory: %s", err)
    }
    logicaltest.Test(t, logicaltest.TestCase{
        PreCheck: func() {
            if os.Getenv("AWS_ACCESS_KEY_ID") == "" {
                t.Skip("AWS credentials not configured")
            }
        },
        Backend: b,
        Steps: []logicaltest.TestStep{
            {
                Description: "configure AWS root credentials",
                Operation:   logical.UpdateOperation,
                Path:        "config/root",
                Data:        map[string]interface{}{"access_key": os.Getenv("AWS_ACCESS_KEY_ID"), ...},
            },
            {
                Description: "create role",
                Operation:   logical.UpdateOperation,
                Path:        "roles/deploy",
                Data:        map[string]interface{}{"arn": "arn:aws:iam::..."},
            },
            {
                Description: "read credentials",
                Operation:   logical.ReadOperation,
                Path:        "creds/deploy",
                Check: func(resp *logical.Response) error {
                    if resp.Data["access_key"] == "" {
                        return fmt.Errorf("empty access_key")
                    }
                    return nil
                },
            },
        },
    })
}
```

Running `go test ./backend/aws/` with AWS credentials set exercises the full
workflow. Without credentials, the PreCheck skips the test cleanly. The `-run TestBackend_CredentialRead` flag selects only this backend. `-race` detects
concurrent access in the backend's request handler. All go test flags work
because this is just a test function.

### Case 2: Terraform Provider Acceptance Tests — 50+ Providers, Nightly Runs

Terraform's provider acceptance framework applies real Terraform configurations
to real cloud infrastructure. Every provider author (AWS, GCP, Azure, Kubernetes,
Datadog, and 50+ more) uses the same harness to write their tests:

```go
// terraform-provider-aws/aws/resource_aws_s3_bucket_test.go
func TestAccAWSS3Bucket_basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSS3BucketDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSS3BucketConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					resource.TestCheckResourceAttr("aws_s3_bucket.bucket", "bucket", "my-tf-test-bucket"),
				),
			},
			{
				Config: testAccAWSS3BucketConfigWithVersioning,
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttr("aws_s3_bucket.bucket", "versioning.0.enabled", "true"),
				),
			},
		},
	})
}
```

`resource.Test` calls `terraform apply` with the given HCL config, runs the
Check functions against the resulting state, then calls `terraform destroy`
and verifies `CheckDestroy`. Steps build on each other: the S3 bucket created
in step 1 is upgraded in step 2 without recreating it from scratch.

HashiCorp runs these nightly across 50+ providers, spinning up thousands of
real cloud resources. The command is `go test -run TestAcc ./aws/ -v`. The
`-run TestAcc` convention gates acceptance tests by name prefix; the PreCheck
gates by environment. No separate runner. No separate binary. Just `go test`.

______________________________________________________________________

## A2 — Activation

This skill applies when:

- "I have a plugin interface. Every plugin needs to pass the same acceptance
  test suite. Should I write a separate test runner?"
- "We're building a driver/backend/provider abstraction. How do contributors
  test new implementations?"
- "Our acceptance tests are getting too complex for simple table tests but we
  don't want to leave `go test`."
- "We have multi-step tests where each step depends on state from the previous
  step — configure, then create, then read, then update."
- "We want to run the same test suite against every implementation of an
  interface (database drivers, storage backends, message queue clients)."
- "How does Terraform test 50+ cloud providers from the same codebase?"
- "Should I write a test harness or use a test framework library?"

______________________________________________________________________

## E — Execution Steps

1. **Define the `TestCase` struct** with the fields that vary across plugin
   implementations. Minimum fields:

   ```go
   type TestCase struct {
   	PreCheck func()              // gates the test; call t.Skip if env not configured
   	Backend  YourPluginInterface // the implementation under test
   	Steps    []TestStep          // ordered scenario steps
   	Cleanup  func()              // teardown after all steps (optional)
   }
   ```

2. **Define the `TestStep` struct** with per-step state. The Check function
   receives the response from the step and returns an error if the assertion
   fails:

   ```go
   type TestStep struct {
   	Description string
   	// fields for the operation the harness will execute
   	Check   func(response YourResponseType) error
   	ErrorOk bool // set true when the step expects an error
   }
   ```

3. **Write `func Test(t *testing.T, tc TestCase)`** as the harness entry point:

   - Call `t.Helper()` as the first line.
   - Call `tc.PreCheck()` if non-nil (this is where `t.Skip` lives).
   - `defer tc.Cleanup()` if non-nil.
   - Range over `tc.Steps`: execute each step, call `t.Fatalf` on unexpected
     errors, call `step.Check` and `t.Fatalf` if it returns an error.

4. **Export the harness in `testing.go`** (not `_test.go`) so plugin authors
   in other packages can import it. The `TestCase` and `TestStep` types and
   the `Test` function are the package's public test API.

5. **Gate acceptance runs in PreCheck:**

   ```go
   PreCheck: func() {
       if os.Getenv("MY_PLUGIN_TEST_TOKEN") == "" {
           t.Skip("MY_PLUGIN_TEST_TOKEN not set; skipping acceptance test")
       }
   },
   ```

   Alternatively, use a build tag (`//go:build acceptance`) on the test file.
   Both conventions are in use across HashiCorp projects.

6. **Plugin author writes a standard test function:**

   ```go
   func TestMyPlugin(t *testing.T) {
       mylib.Test(t, mylib.TestCase{
           Backend: NewMyPlugin(),
           Steps: []mylib.TestStep{
               {Description: "configure", ...},
               {Description: "create resource", ...},
               {Description: "read and verify", Check: func(resp Response) error { ... }},
           },
       })
   }
   ```

   This is a normal `go test` function. No new concepts for the plugin author.

7. **Verify that standard go test flags work unchanged:**

   - `-run TestMyPlugin` selects this specific backend.
   - `-v` prints each step's description as the test progresses.
   - `-race` detects concurrent access in the plugin implementation.
   - `-cover` measures coverage of the plugin code under the acceptance scenario.
   - `-timeout 10m` terminates hung infrastructure calls.

______________________________________________________________________

## B — Boundaries and Blind Spots

**Overkill for non-pluggable code.**
If you have one implementation of an interface and no plans to write more, a
table-driven test or a sequence of `t.Run` subtests is simpler. The custom
harness pattern pays for itself when there are multiple plugin implementations
(at least 3–5) that all must satisfy the same scenario. Below that threshold,
the abstraction cost exceeds the benefit.

**Do not reach for this before you have multiple consumers.**
Write the first backend test as an ordinary `Test*` function with inline steps.
Extract the harness only when you discover that the second backend test is
nearly identical structure. Premature harness extraction produces a complex
abstraction with a single consumer — the worst of both worlds.

**Author blind spot: `t.Run()` subtests (Go 1.7+).**
The talk predates `t.Run`. Modern Go allows step-by-step decomposition without
a custom harness:

```go
func TestMyBackend(t *testing.T) {
    b := setupBackend(t)
    t.Run("configure", func(t *testing.T) { ... })
    t.Run("create role", func(t *testing.T) { ... })
    t.Run("read credentials", func(t *testing.T) { ... })
}
```

`t.Run` subtests give you named steps, per-step failure isolation, and `-run`
filtering without a custom `TestCase` struct. For moderately complex scenarios
without shared plugin-interface structure, `t.Run` may be sufficient. The custom
harness becomes necessary when the structure (what fields a step carries, how the
harness orchestrates retries or cleanup between steps) must be shared across
many plugin packages.

**Author blind spot: `testing/synctest` (Go 1.24 experimental).**
For multi-step tests that involve goroutines and timing, `testing/synctest`
provides deterministic concurrency control that was not available when the talk
was given.

**Modern alternatives to a hand-rolled harness.**
The Go ecosystem now has specialized test harnesses that may be more appropriate
than a fully custom one:

- `testscript` (Roger Peppe / `golang.org/x/tools/txtar`): script-driven
  acceptance tests for CLI tools, used in the Go toolchain itself.
- `testcontainers-go`: Docker-based harness for tests that require real database
  or service infrastructure.
- `gotestfmt` + `gotestsum`: improved output formatting without a custom runner.
  Evaluate these before building a custom harness from scratch.

**Confusion with `testing-go-public-test-api`.**
That skill is about exporting helpers, mocks, and `TestConfig(t)` / `TestServer(t)`
functions for external consumers. This skill is about building a step-driven
orchestration harness for complex multi-step acceptance scenarios. The two
patterns compose naturally (the harness is typically exported via `testing.go`)
but address different problems: the public test API distributes test helpers
across packages; the custom framework orchestrates stateful scenarios within a
single pluggable system.

### Related Skills

- **testing-go-public-test-api** (composes-with): The custom harness (`TestCase` struct and `Test(t, tc)` function) needs to be importable by plugin authors in other packages. Publishing it in a `testing.go` file (not `_test.go`) provides that importability. The public test API skill provides the mechanism; this skill provides the structure. The two appear together in every production use of this pattern (e.g., Vault's `logicaltest`).
