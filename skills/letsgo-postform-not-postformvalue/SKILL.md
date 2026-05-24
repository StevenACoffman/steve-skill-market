---
id: letsgo-postform-not-postformvalue
title: r.PostForm.Get Over r.PostFormValue; internal/ for Package Encapsulation
description: Invoke when reading form data from an HTTP request in Go, or when deciding which packages belong under internal/ vs at the module root.
source: Let's Go, Alex Edwards, 2023
---

## R — Reading

> "`r.PostFormValue()` calls `ParseForm()` for us automatically, discarding any errors that it returns. Using `r.ParseForm()` instead means we get an explicit error that we can handle... If a client sends a `GET` request with some URL query string parameters and we use `r.FormValue()` to read them, we would also accidentally read them if we later receive a `POST` request with the same parameter name in the request body. That's a subtle source of bugs."

## 07.02-Parsing-Form-Data

> "The `internal` directory name is special in Go: any packages which live under this directory can only be imported by code inside the parent of the `internal` directory. In our case, this means that any packages under `internal/` can only be imported by code inside our `snippetbox` module... It's not just a naming convention — it's enforced by the Go compiler."

## 02.07-Project-Structure

## I — Interpretation

`r.PostFormValue()` is a convenience function that calls `r.ParseForm()` internally and then returns `r.PostForm.Get(key)`. The problem is in what it discards: if `r.ParseForm()` returns an error (malformed body, wrong Content-Type, network error reading the body), `r.PostFormValue()` returns an empty string with no indication that anything failed. The handler proceeds with empty data and likely produces confusing behavior — validation passes on empty strings if `NotBlank` is not set, or validation fails with a misleading error message. The correct path is to call `r.ParseForm()` explicitly, check the error, and return 400 if parsing fails. Then read values through `r.PostForm.Get(key)`.

The second footgun is `r.FormValue()`. It reads from both `r.PostForm` (body) and `r.Form` (URL query string). A handler that uses `r.FormValue("title")` will silently read a `title` query parameter from a GET request, even on a POST handler. This mixes input sources in a way that is invisible at the call site.

The `internal/` directory rule is simpler but equally non-obvious to developers coming from other languages. In Go, `internal/` is not a naming convention — the compiler enforces it. Code outside the parent module cannot import packages under `internal/`. This means `internal/models`, `internal/validator`, and `internal/assert` cannot be accidentally imported by external code if the module is ever published. It also signals to teammates that these packages are implementation details. The distinction matters: `internal/validator` is the embedded form validation helper; if it lived at `validator/`, another module could import and depend on it, creating an unintended public API.

## A1 — Past Application

In Snippetbox, the `snippetCreatePost` handler uses explicit parsing:

```go
func (app *application) snippetCreatePost(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	if err != nil {
		app.clientError(w, http.StatusBadRequest)
		return
	}

	// read via r.PostForm, not r.PostFormValue
	title := r.PostForm.Get("title")
	content := r.PostForm.Get("content")
	// ...
}
```

The project structure enforces encapsulation:

```text
snippetbox/
  cmd/
    web/
      main.go         -- can import internal/models, internal/validator
  internal/
    models/           -- compiler-enforced: only importable within snippetbox
      snippets.go
      users.go
      errors.go
      mocks/
    validator/        -- only importable within snippetbox
      validator.go
    assert/           -- only importable within snippetbox
      assert.go
```

In the book's final form, the `gorilla/schema` form decoder (`app.formDecoder.Decode(&form, r.PostForm)`) reads from `r.PostForm` — which is populated only after explicit `r.ParseForm()`. The decoder does not call `ParseForm()` automatically.

## A2 — Future Trigger ★

- Writing any handler that reads from an HTML form POST body
- Reviewing code that uses `r.PostFormValue()` or `r.FormValue()` anywhere in handler code
- Deciding which new packages to put under `internal/` vs at the module root
- Considering publishing a Go module — the `internal/` packages are already protected
- Debugging a handler that proceeds with empty form data after a malformed POST request
- A POST handler where the same field name exists in both the URL query string and the request body

## E — Execution

1. In every POST handler: call `r.ParseForm()` first; on error, return `app.clientError(w, http.StatusBadRequest)` and return
2. Read form values via `r.PostForm.Get("key")` — this reads only from the POST body, not from URL query parameters
3. Never use `r.PostFormValue()` (silently discards parse errors) or `r.FormValue()` (mixes body and query string)
4. If using a form decoder library (`gorilla/schema`, `go-playground/form`): pass `r.PostForm` (not `r`) to `decoder.Decode(&form, r.PostForm)` — this ensures the decoder reads from the already-parsed body
5. Place every package that is not a public API under `internal/`: models, validator, assert, mocks, and any other application-specific helpers
6. Never put packages under `internal/` that need to be tested from outside the module — but `_test.go` files inside the same module can always import `internal/` packages

## B — Boundary

The explicit `r.ParseForm()` requirement applies to `application/x-www-form-urlencoded` bodies. For `multipart/form-data` (file uploads), call `r.ParseMultipartForm(maxMemory)` instead. JSON request bodies use `json.NewDecoder(r.Body).Decode(&v)` — `ParseForm` is irrelevant there. The `internal/` restriction applies to the Go module boundary; within a monorepo where multiple modules share code, `internal/` may prevent sharing between modules, requiring a separate shared module or moving the package up.

## Related Skills

- **[letsgo-form-validator](../letsgo-form-validator/SKILL.md)** — prerequisite for: explicit `r.ParseForm()` must be called before `app.formDecoder.Decode(&form, r.PostForm)` populates the form struct that the embedded Validator operates on
- **[go-http-service-di-composition](../go-http-service-di-composition/SKILL.md)** — informs: the `internal/` directory structure (models, validator, assert, mocks) that compiler-enforces encapsulation is established at the same time as the application struct; knowing `internal/` is required to lay out the project correctly
- **[letsgo-db-sentinel-error-translation](../letsgo-db-sentinel-error-translation/SKILL.md)** — relates: both skills address correct error handling at a layer boundary — this skill at the HTTP input boundary (`ParseForm` errors), that skill at the persistence boundary (driver error translation)
- **go-http-service-test-strategy** — informs: `internal/assert` and `internal/models/mocks` are compiler-enforced private packages; understanding the `internal/` rule is needed when setting up the test helper layout
