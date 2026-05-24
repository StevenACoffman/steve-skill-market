---
name: matryer-decode-valid
description: |
  Eliminate repetitive decode-then-validate boilerplate in HTTP handlers by combining
  both operations into a single generic helper. Define a Validator interface with a
  Valid(ctx) method returning a problems map, then use decodeValid[T Validator] to
  decode JSON and validate in one call. The returned problems map is structured for
  direct use as an API error response, and the type constraint enforces validation
  at compile time.
source_book: "How I Write HTTP Services in Go After 13 Years" — Mat Ryer (2024)
source_chapter: Handle decoding/encoding in one place / Validating data
tags: [go, validation, generics, http-services, json, request-handling]
related_skills:
  - matryer-maker-func
---

# Decode + Validate in One Step with a Generic Helper

## R — Original Text (Reading)

From "Validating data" (Mat Ryer, 2024):

> I like a simple interface. Love them, actually. Single method interfaces are so easy to implement. So when it comes to validating objects, I like to do this:

```go
// Validator is an object that can be validated.
type Validator interface {
	// Valid checks the object and returns any
	// problems. If len(problems) == 0 then
	// the object is valid.
	Valid(ctx context.Context) (problems map[string]string)
}
```

> The `Valid` method takes a context (which is optional but has been useful for me in the past) and returns a map. If there is a problem with a field, its name is used as the key, and a human-readable explanation of the issue is set as the value.
>
> The method can do whatever it needs to validate the fields of the struct. For example, it can check to make sure:
>
> - Required fields are not empty
> - Strings with a specific format (like email) are correct
> - Numbers are within an acceptable range
>
> If you need to do anything more complicated, like check the field in a database, that should happen elsewhere; it's probably too important to be considered a quick validation check, and you wouldn't expect to find that kind of thing in a function like this, so it could easily end up being hidden away.
>
> I then use a type assertion to see if the object implements the interface. Or, in the generic world, I might choose to be more explicit about what's going on by changing the decode method to insist on that interface being implemented.

```go
func decodeValid[T Validator](r *http.Request) (T, map[string]string, error) {
	var v T
	if err := json.NewDecoder(r.Body).Decode(&v); err != nil {
		return v, nil, fmt.Errorf("decode json: %w", err)
	}
	if problems := v.Valid(r.Context()); len(problems) > 0 {
		return v, problems, fmt.Errorf("invalid %T: %d problems", v, len(problems))
	}
	return v, nil, nil
}
```

> In this code, `T` has to implement the `Validator` interface, and the `Valid` method must return zero problems in order for the object to be considered successfully decoded.
>
> It's safe to return `nil` for problems because we are going to check `len(problems)`, which will be `0` for a `nil` map, but which won't panic.

______________________________________________________________________

## I — Methodological Framework (Interpretation)

This pattern is built on three interlocking decisions:

## 1. Single-Method Validator Interface

The `Validator` interface has exactly one method: `Valid(ctx context.Context) (problems map[string]string)`. The signature is precise by design:

- `ctx` is included for future-proofing (e.g., deadline-aware checks), even if not always used.
- The return type is `map[string]string`, not `error` or `[]string`. Field name as key, human-readable description as value. This structure maps cleanly to JSON API error bodies.
- `len(problems) == 0` is the validity test — a nil map is safe and valid.

## 2. Scope Discipline: What Belongs in Valid()

`Valid()` is for structural field checks only:

- Empty required fields
- Format checks (email, UUID, date strings)
- Range or length constraints

It is not for I/O-dependent checks (database lookups, external API calls). Those belong in the handler or service layer. Keeping `Valid()` I/O-free means it is always fast, synchronous, and independently testable without infrastructure.

## 3. Generic Type Constraint Merges Two Operations

`decodeValid[T Validator]` uses a type constraint (not a runtime interface assertion) to require that the decoded type implements `Validator`. This collapses three separate call sites — decode, then assert interface, then validate — into one. The three-return signature `(T, map[string]string, error)` carries the full result without ambiguity:

- First value: the decoded struct (always returned, even on validation failure, for inspection)
- Second value: nil on success, populated map on validation failure
- Third value: nil on success, error on decode or validation failure

The caller decides how to present validation errors. Because the problems map is already field-name keyed, it can be JSON-marshalled directly into a 400 response body.

______________________________________________________________________

## A1 — Past Application (From the Book)

Ryer describes building this iteratively. The baseline `decode[T any]` helper wraps `json.NewDecoder(r.Body).Decode(&v)` and returns `(T, error)`. It consolidates JSON decoding in one place so that switching to XML (or any other format) later requires changes in only one function.

The next step is noticing that every handler that calls `decode` then manually calls validation logic or checks fields inline. Rather than add a second function to every handler, Ryer introduces the `Validator` interface so that request structs carry their own validation. The `decodeValid` generic function composes these two steps at the type level — the constraint `[T Validator]` means the compiler rejects any type that does not implement `Valid`.

The result is that a handler that previously read:

```go
req, err := decode[CreateUserRequest](r)
if err != nil {
	http.Error(w, err.Error(), http.StatusBadRequest)
	return
}
if req.Name == "" || !isValidEmail(req.Email) {
	http.Error(w, "invalid input", http.StatusBadRequest)
	return
}
```

becomes:

```go
req, problems, err := decodeValid[CreateUserRequest](r)
if err != nil {
	encode(w, r, http.StatusBadRequest, problems)
	return
}
```

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

**Situation**: A developer has multiple HTTP handlers. Each one decodes a JSON body, then manually checks required fields (empty string, zero value, out-of-range number), then handles decode errors. The decode error and the validation error paths are both present in every handler, producing repeated branching. A code review comment says: "Every handler has the same 10 lines of decode-then-validate. Can we clean this up?"

**Why this skill is the answer**: The repetition exists because decode and validation are two separate responsibilities with no shared abstraction. This skill provides exactly that abstraction: a `Validator` interface that moves field-level rules onto the struct itself, and a `decodeValid` generic that executes both in sequence. The handler body shrinks to a single call site that handles both failure modes (malformed JSON vs. invalid fields) with one block.

**Trigger phrases**:

- "tired of writing decode, validate, check errors in every handler"
- "how do I validate request bodies in Go"
- "want to return field-level validation errors as JSON"
- "decoding and validation keep getting duplicated across handlers"
- "how to use generics for HTTP request validation"

______________________________________________________________________

## E — Execution Steps

**Step 1: Define the Validator interface** (once, in a shared file such as `helpers.go` or `validator.go`):

```go
// Validator is an object that can be validated.
type Validator interface {
	// Valid checks the object and returns any
	// problems. If len(problems) == 0 then
	// the object is valid.
	Valid(ctx context.Context) (problems map[string]string)
}
```

**Step 2: Implement Valid() on each request struct** — field checks only, no I/O:

```go
type CreateUserRequest struct {
	Name  string `json:"name"`
	Email string `json:"email"`
	Age   int    `json:"age"`
}

func (r CreateUserRequest) Valid(ctx context.Context) map[string]string {
	problems := make(map[string]string)
	if r.Name == "" {
		problems["name"] = "name is required"
	}
	if r.Email == "" {
		problems["email"] = "email is required"
	} else if !strings.Contains(r.Email, "@") {
		problems["email"] = "email must be a valid address"
	}
	if r.Age < 0 || r.Age > 150 {
		problems["age"] = "age must be between 0 and 150"
	}
	if len(problems) > 0 {
		return problems
	}
	return nil
}
```

**Step 3: Write the decodeValid generic function** (once, alongside the `decode` and `encode` helpers):

```go
func decodeValid[T Validator](r *http.Request) (T, map[string]string, error) {
	var v T
	if err := json.NewDecoder(r.Body).Decode(&v); err != nil {
		return v, nil, fmt.Errorf("decode json: %w", err)
	}
	if problems := v.Valid(r.Context()); len(problems) > 0 {
		return v, problems, fmt.Errorf("invalid %T: %d problems", v, len(problems))
	}
	return v, nil, nil
}
```

**Step 4: Use in handlers** — one call, two failure modes handled together:

```go
func handleCreateUser() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		req, problems, err := decodeValid[CreateUserRequest](r)
		if err != nil {
			// problems is nil for decode errors, populated for validation errors
			encode(w, r, http.StatusBadRequest, map[string]any{
				"error":    err.Error(),
				"problems": problems,
			})
			return
		}
		// req is valid; proceed with business logic
		_ = req
	}
}
```

**Step 5: For I/O-dependent checks** (uniqueness, existence), handle separately after `decodeValid` succeeds:

```go
req, problems, err := decodeValid[CreateUserRequest](r)
if err != nil {
	encode(w, r, http.StatusBadRequest, problems)
	return
}
// Field validation passed. Now check the database.
exists, err := s.db.UserExists(r.Context(), req.Email)
if err != nil {
	http.Error(w, "internal error", http.StatusInternalServerError)
	return
}
if exists {
	encode(w, r, http.StatusConflict, map[string]string{"email": "already in use"})
	return
}
```

______________________________________________________________________

## B — Boundaries and Blind Spots

**What this pattern handles well**:

- Synchronous, field-level structural validation (required, format, range)
- Any type that can be JSON-decoded (structs, not primitives)
- Go 1.18+ — requires generics
- Directly serializable validation errors for 400 responses

**What it does not handle**:

- I/O-dependent checks (database uniqueness, external service lookups) — these belong in the handler or service layer after `decodeValid` returns
- Cross-field validation involving I/O (e.g., "email must match the one registered for this user ID") — split into two phases: `decodeValid` for structural, then handler for relational
- Non-JSON request bodies — `decodeValid` as written calls `json.NewDecoder`; extend the decode step for multipart, form, or other encodings
- Streaming or partial validation — the entire body is decoded before `Valid()` is called
- Pointer receiver vs. value receiver on `Valid()`: if the struct has fields set via pointer receivers, ensure the type constraint is satisfied by the right receiver type

**Common mistakes**:

- Adding a database call inside `Valid()`: this hides a slow I/O call inside what looks like a fast validation step and couples the struct to infrastructure
- Returning a non-nil empty map from `Valid()` when there are no problems: `len(nil) == 0` is safe, but `len(map[string]string{}) == 0` is also fine — either works
- Forgetting to handle the case where `problems` is nil (decode error path) before marshalling it into a response — nil marshals as `null` in JSON, which may be undesirable; use `map[string]any{"problems": problems}` only when you've confirmed the distinction matters to the client

______________________________________________________________________

## Related Skills

- **matryer-maker-func** — pairs-with: `decodeValid` is called inside the closure returned by a maker function; the maker provides the handler skeleton, and `decodeValid` handles the request-body phase of every mutating endpoint.
