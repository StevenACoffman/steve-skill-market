---
name: webapp-graphql
description: |
  Use when writing Go code in github.com/Khan/webapp that makes GraphQL
  requests, tests GraphQL resolvers, or needs to understand the webapp
  GraphQL client and testing layer. Covers gqlclient.Client/ClientAdapter,
  auth adapters (AsUser/AsServiceAdmin), BuildTestClientForSchema,
  gqltest.Query/Mutate/QueryType, js.Obj, and the query safelist. ONLY
  applies to github.com/Khan/webapp.

  Trigger signals:
  - "how do I call a GraphQL query from one service to another?"
  - "how do I test a GraphQL resolver in webapp?"
  - "what is gqlclient.Client vs ClientAdapter?"
  - "how do I use AsUser or AsServiceAdmin?"
  - "what is the GraphQL safelist?"
  - "how do I use gqltest.QueryType for a federated type?"
  - Any question about webapp's GraphQL client or resolver testing layer
allowed-tools: Bash, Read, Edit, Write
---

# Webapp GraphQL Client and Resolver Testing

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. The
> `gqlclient` package, auth adapters, and `gqltest` helpers are all
> webapp-specific. Do not apply these patterns to any other repository.

______________________________________________________________________

## `gqlclient.Client` Vs `gqlclient.ClientAdapter`

| Type                      | Import                                     | Purpose                                                                                 |
| ------------------------- | ------------------------------------------ | --------------------------------------------------------------------------------------- |
| `gqlclient.Client`        | `github.com/Khan/webapp/pkg/web/gqlclient` | Configuration surface: chain options, obtain auth adapters                              |
| `gqlclient.ClientAdapter` | `github.com/Khan/webapp/pkg/web/gqlclient` | Implements `graphql.Client` for genqlient; exposes `MakeRequest` and `HTTPPostForTests` |

`Client` is what you hold and configure. The three auth methods (`AsUser`,
`AsServiceAdmin`, `AsCronForTests`) each return a `ClientAdapter` that you pass
to genqlient-generated functions or to `gqltest.*`.

______________________________________________________________________

## Auth Adapters

```go
client := ctx.GraphQLClient() // gqlclient.Client from KAContext

// Authenticated user request (forwards user auth headers)
adapter := client.AsUser()

// Cross-service admin call (uses service admin secret, no user auth)
adapter := client.AsServiceAdmin()

// Cron / task-queue call (for tests and cron handlers)
adapter := client.AsCronForTests()
```

Pass the `ClientAdapter` to a genqlient-generated function:

```go
resp, err := generatedpkg.GetUser(ctx, client.AsServiceAdmin(), kaid)
```

______________________________________________________________________

## Client Configuration Options

Chain these on a `gqlclient.Client` before calling an auth adapter:

| Method                           | What It Does                                                    |
| -------------------------------- | --------------------------------------------------------------- |
| `WithService(name)`              | Routes the request to a specific service instead of the gateway |
| `WithKALocale(locale)`           | Adds locale header                                              |
| `WithVersion(version)`           | Pins a specific service version                                 |
| `WithAdditionalHeaders(headers)` | Adds arbitrary extra headers                                    |
| `WithQueryParams(params)`        | Adds query parameters to the request URL                        |

______________________________________________________________________

## Testing GraphQL Resolvers

### Import Path

```go
import (
	"github.com/Khan/webapp/dev/gqltest"
	"github.com/Khan/webapp/dev/servicetest"
	"github.com/Khan/webapp/pkg/web/gqlclient/js"
	generated "github.com/Khan/webapp/services/myservice/generated/graphql"
)
```

### Building a Test Client

`servicetest.Suite.BuildTestClientForSchema` starts an in-process HTTP server
hosting your schema and returns a configured `gqlclient.Client`:

```go
type mySuite struct{ servicetest.Suite }

func (s *mySuite) TestGetFoo() {
	ctx := s.KAContext()
	client := s.BuildTestClientForSchema(ctx, generated.NewExecutableSchema(
		generated.Config{Resolvers: &myResolver{ctx: ctx}},
	))

	result, err := gqltest.Query(ctx, client.AsUser(), `
        query GetFoo($id: String!) {
            foo(id: $id) { name }
        }
    `, js.Obj{"id": "abc"})
	s.Require().NoError(err)
	s.Require().Equal(js.Obj{"foo": js.Obj{"name": "expected"}}, result)
}
```

**Headers are captured at client creation time** from the KAContext state. To
test as a different user, clone the context before building the client.

### `BuildTestClientForSchema` Variants

| Method                                                              | Use When                                                                   |
| ------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| `BuildTestClientForSchema(ctx, schema)`                             | Standard GraphQL resolver test                                             |
| `BuildTestClientForSchemaFastlyCacheable(ctx, schema)`              | Testing Fastly-cacheable response behaviour; sets Fastly headers, nil user |
| `BuildTestClientForSchemaWithResponseHeaders(ctx, schema, headers)` | Need to assert on response headers set by the resolver                     |

______________________________________________________________________

## `gqltest` Functions

All functions return `(js.Obj, error)`.

### `gqltest.Query`

```go
result, err := gqltest.Query(ctx, client.AsUser(), `
    query ListAssignments($classroomId: String!) {
        assignments(classroomId: $classroomId) { id dueDate }
    }
`, js.Obj{"classroomId": "class_001"})
```

### `gqltest.Mutate`

```go
result, err := gqltest.Mutate(ctx, client.AsServiceAdmin(), `
    mutation CreateAssignment($input: AssignmentInput!) {
        createAssignment(input: $input) { id }
    }
`, js.Obj{"input": js.Obj{"classroomId": "class_001", "contentId": "x:abc"}})
```

### `gqltest.QueryType` — Federation Entity Testing

Use `QueryType` to test a resolver on a type that is only reachable via Apollo
Federation `@key` (no top-level query field). It constructs an `_entities`
query internally.

```go
result, err := gqltest.QueryType(
	ctx,
	client.AsUser(),
	js.Obj{ // representation: __typename + all @key fields
		"__typename": "Assignment",
		"id":         "assign_001",
	},
	`{ dueDate title }`, // fields to fetch (pseudo-query string)
	nil,                 // extra vars inlined into the fields string
)
s.Require().NoError(err)
s.Require().Equal("2026-09-01", result["dueDate"])
```

Variables referenced in the `fields` string are inlined at the call site, not
forwarded as separate GraphQL variables. Use `gqltest.Enum("VALUE")` when a
variable value is a GraphQL enum (prevents quoting):

```go
gqltest.QueryType(ctx, client.AsUser(),
	js.Obj{"__typename": "User", "kaid": "kaid_001"},
	`{ role(context: $context) }`,
	js.Obj{"context": gqltest.Enum("STUDENT")},
)
```

______________________________________________________________________

## `js.Obj` And JSON Types

| Type                | Go backing type  | Notes                                     |
| ------------------- | ---------------- | ----------------------------------------- |
| `js.Obj`            | `map[string]any` | Represents a JSON object                  |
| `js.Array`          | `[]any`          | Represents a JSON array                   |
| `js.UnorderedArray` | custom matcher   | Equality check that ignores element order |

Use `js.Obj` for both query variables and result assertions:

```go
s.Require().Equal(js.Obj{
	"user": js.Obj{"email": "test@example.com"},
}, result)
```

______________________________________________________________________

## `# @genqlient` Directives — Authoring Cross-Service Operations

Cross-service operations live as raw GraphQL strings inside `cross_service/`
Go files, marked with a `# @genqlient` comment. The `genqlient` code generator
turns each one into a typed Go function plus an `*_Operation` symbol you can
hand to `tasks.GraphQLTask`.

The `ka-genqlient` linter enforces two related rules:

1. **Every `# @genqlient`-annotated operation must be referenced in the same
   `.go` file.** Either call the generated function, or — for cases where you
   only want the operation registered (e.g. it's executed via
   `tasks.GraphQLTask` rather than called directly) — add a `_ = …` reference
   to the corresponding symbol.
2. **Removing the last call site requires removing the directive.** Orphan
   directives left after a refactor will fail the linter on the next CI run.

```go
// Good — operation is invoked directly; no extra reference needed
func goodGetUser(ctx federationCtx, kaid string) (*User, error) {
	_ = `# @genqlient
		query Users_GetUser($kaid: String!) {
			user(kaid: $kaid) { id name }
		}
	`
	resp, err := client.UsersGetUser(ctx, kaid) // direct call site
	if err != nil {
		return nil, errors.Wrap(err)
	}
	return resp, nil
}

// Good — operation is fired only via tasks.GraphQLTask; add _ = … so the
//
//	linter sees the symbol is used. Place the reference next to the directive.
func goodTriggerEnrollment(ctx tasks.KAContext, kaid string) error {
	_ = `# @genqlient
		mutation Enrollments_Task_EnrollUser($kaid: String!) {
			enrollUserInClassroom(kaid: $kaid) { error { code } }
		}
	`
	_ = genqlient.Enrollments_Task_EnrollUser_Operation // satisfies ka-genqlient

	task, err := tasks.GraphQLTask(
		genqlient.Enrollments_Task_EnrollUser_Operation,
		map[string]any{"kaid": kaid},
	)
	if err != nil {
		return errors.Wrap(err)
	}
	return ctx.Tasks().CreateTask(ctx, "enrollments-deferred-queue", task)
}

// Bad — directive present, no call site or _ = reference in this file
func badOrphanDirective() {
	_ = `# @genqlient
		query Users_OrphanedQuery { user { id } }
	` // ka-genqlient fires: no caller and no _ = genqlient.Users_OrphanedQuery
}
```

When you delete the last caller of a generated function, search for and remove
its `# @genqlient` block too. The directive is not load-bearing on its own —
genqlient only emits the typed function when something in the same file uses it.

______________________________________________________________________

## GraphQL Safelist

Webapp maintains a static allowlist of every GraphQL query sent by Go services.
At deploy time the deploy tooling gathers all queries and uploads them. The
server rejects any query not in the list.

**As a developer you do not need to manage the safelist manually during
development.** However you should know:

- Every genqlient-generated `.graphql` operation file is automatically included.
- Hand-written queries sent via `gqltest` in tests are not included in the
  production safelist (tests bypass the safelist check).
- If a query is rejected in a deployed environment, check whether the deploy
  pipeline ran `upload_graphql_safelist.py` successfully.

______________________________________________________________________

## Authorization

Every non-trivial resolver must check permissions before accessing data or
performing mutations. The `ka-permissions` linter requires a
`//ka:permission-check` annotation on resolvers; omitting it causes a CI
failure.

```go
func (r *Resolver) MyData(ctx context.Context, args MyArgs) (*MyDataResult, error) {
	//ka:permission-check
	if err := permissions.Require(ctx, permissions.ViewMyData); err != nil {
		return nil, err
	}
	return r.service.GetMyData(ctx, args.ID)
}
```

Mutation resolvers must return authorization failures inside the response struct
rather than as top-level GraphQL errors:

```go
type EnrollResult struct {
	Error *EnrollError `json:"error"`
}

func (r *Resolver) EnrollUser(ctx context.Context, args EnrollArgs) (*EnrollResult, error) {
	//ka:permission-check
	if err := permissions.Require(ctx, permissions.EnrollUsers); err != nil {
		return &EnrollResult{Error: &EnrollError{Code: "UNAUTHORIZED"}}, nil
	}
	return r.service.EnrollUser(ctx, args.Kaid, args.ClassroomID)
}
```

______________________________________________________________________

## Resolver Design

Keep resolver functions thin: check permissions, delegate to a service
function, and return the result. Business logic, datastore calls, and
conditional branching belong in a service package (e.g., `services/myservice/`),
not in resolver bodies. This keeps resolvers independently testable without a
GraphQL layer.

```go
// Thin resolver — good
func (r *Resolver) Assignment(ctx context.Context, args AssignmentArgs) (*AssignmentResult, error) {
	//ka:permission-check
	if err := permissions.Require(ctx, permissions.ViewAssignment); err != nil {
		return nil, err
	}
	return r.assignmentService.GetAssignment(ctx, args.ID)
}

// Fat resolver — bad: business logic embedded in resolver
func (r *Resolver) Assignment(ctx context.Context, args AssignmentArgs) (*AssignmentResult, error) {
	//ka:permission-check
	if err := permissions.Require(ctx, permissions.ViewAssignment); err != nil {
		return nil, err
	}
	row, err := r.db.QueryRow(ctx, "SELECT ...") // datastore access here
	if err != nil {
		// ...
	}
	if row.DueDate.Before(time.Now()) { // business logic here
		// ...
	}
	return &AssignmentResult{}, nil
}
```

______________________________________________________________________

## Key Import Paths

| Symbol                         | Import                                        |
| ------------------------------ | --------------------------------------------- |
| `gqlclient.Client`             | `github.com/Khan/webapp/pkg/web/gqlclient`    |
| `gqlclient.ClientAdapter`      | `github.com/Khan/webapp/pkg/web/gqlclient`    |
| `js.Obj`                       | `github.com/Khan/webapp/pkg/web/gqlclient/js` |
| `gqltest.Query`                | `github.com/Khan/webapp/dev/gqltest`          |
| `gqltest.Mutate`               | `github.com/Khan/webapp/dev/gqltest`          |
| `gqltest.QueryType`            | `github.com/Khan/webapp/dev/gqltest`          |
| `gqltest.Enum`                 | `github.com/Khan/webapp/dev/gqltest`          |
| `servicetest.ExecutableSchema` | `github.com/Khan/webapp/dev/servicetest`      |
