---
id: letsgo-form-validator
title: Embedded Validator for Form Struct Validation
description: Invoke when implementing HTML form handling in Go — specifically when validation errors and original input values must travel together through a handler's re-render path.
source: Let's Go, Alex Edwards, 2023
---

## R — Reading

> "Because the `Validator` type is embedded in the `snippetCreateForm` struct, the promoted methods on the `Validator` type are available directly on `snippetCreateForm`. So for example, we can call `form.CheckField()` instead of `form.Validator.CheckField()`... The form struct, validation state, and original input all travel together as a single value, making handler logic and template rendering symmetrical."

## 07.03-Setting-up-the-Form, 07.05-Displaying-Validation-Errors

## I — Interpretation

HTML form validation in Go has a data-bundling problem: on validation failure, the handler must re-render the form with both the error messages and the original input values pre-populated. These are two distinct pieces of state. The naive approach stores errors in one variable and reads input from `r.PostForm` a second time — which diverges from what was validated, introduces duplication, and makes the template data model asymmetric.

Edwards' solution is structural. Define a `Validator` struct in `internal/validator/` with:

- `FieldErrors map[string]string` — one error message per named field
- `NonFieldErrors []string` — form-level errors (login failure, etc.)
- `CheckField(ok bool, key, message string)` — conditionally adds a field error
- `AddNonFieldError(message string)` — appends a form-level error
- `Valid() bool` — true iff both maps are empty

Then embed `validator.Validator` in each form struct:

```go
type snippetCreateForm struct {
	Title   string
	Content string
	Expires int
	validator.Validator
}
```

Embedding promotes `CheckField`, `AddNonFieldError`, and `Valid()` to methods on the form struct directly. The form struct, its validation state, and the original decoded values are a single value. The handler decodes into the struct, runs validation, and passes the struct to the template whether the form is valid or not. The template reads `{{.Form.Title}}` for the input value and `{{with .Form.FieldErrors.title}}...{{end}}` for the error.

This is not just convenient — it is structurally enforced. The form struct cannot reach the template data without carrying its validation state. There is no code path where errors are lost.

## A1 — Past Application

In Snippetbox, the `snippetCreatePost` handler:

```go
func (app *application) snippetCreatePost(w http.ResponseWriter, r *http.Request) {
	var form snippetCreateForm

	err := app.formDecoder.Decode(&form, r.PostForm)
	if err != nil {
		app.clientError(w, http.StatusBadRequest)
		return
	}

	form.CheckField(validator.NotBlank(form.Title), "title", "This field cannot be blank")
	form.CheckField(validator.MaxChars(form.Title, 100), "title", "This field cannot be more than 100 characters long")
	form.CheckField(validator.NotBlank(form.Content), "content", "This field cannot be blank")
	form.CheckField(validator.PermittedValue(form.Expires, 1, 7, 365), "expires", "This field must equal 1, 7 or 365")

	if !form.Valid() {
		data := app.newTemplateData(r)
		data.Form = form
		app.render(w, r, http.StatusUnprocessableEntity, "create.tmpl", data)
		return
	}

	// proceed to insert...
}
```

The same `Validator` type is embedded in `userSignupForm` and `userLoginForm` — the pattern requires no modification for reuse.

## A2 — Future Trigger ★

- Any Go handler that processes an HTML form submission and needs to re-render on validation failure
- A form with multiple fields where some errors are field-specific and some are form-level (login incorrect)
- Reviewing code that stores validation errors in a handler-local variable and re-reads values from `r.PostForm` for the template
- Adding a new form to an application that already uses the embedded Validator pattern (extend, don't reinvent)
- Deciding whether to use a struct-tag validation library vs. explicit `CheckField` calls

## E — Execution

1. Create `internal/validator/validator.go` with `Validator` struct, `FieldErrors`, `NonFieldErrors`, `CheckField`, `AddNonFieldError`, `Valid()`; add helper functions `NotBlank`, `MaxChars`, `MinChars`, `PermittedValue`, `Matches` as standalone functions in the same package
2. Define a form struct per form: fields matching the form inputs, plus `validator.Validator` embedded (not as a named field)
3. In the POST handler: call `r.ParseForm()` explicitly and check the error; decode with `app.formDecoder.Decode(&form, r.PostForm)`
4. Run `form.CheckField(...)` for each validation rule; run `form.AddNonFieldError(...)` for form-level rules (e.g., duplicate email from a model error)
5. Check `form.Valid()`; on false, set `data.Form = form` and render with `http.StatusUnprocessableEntity`
6. In templates: render field errors with `{{with .Form.FieldErrors.fieldname}}` and repopulate inputs with `value="{{.Form.FieldName}}"`

## B — Boundary

The `Validator` does not perform automatic struct-tag-based validation. Every rule is explicit — more verbose than `go-playground/validator`, but more readable and debuggable. This pattern does not validate file uploads, multipart forms with binary data, or JSON request bodies (those require different decoding). The `422 Unprocessable Entity` status is correct for client validation failures; do not use 400 (which signals a malformed request, not a semantically invalid one). The embedded pattern does not compose well if a form needs two distinct sets of validation rules applied conditionally — use separate form structs in that case.

## Related Skills

- **[letsgo-postform-not-postformvalue](../letsgo-postform-not-postformvalue/SKILL.md)** — depends on: explicit `r.ParseForm()` must be called and checked before `app.formDecoder.Decode(&form, r.PostForm)` can populate the form struct
- **[letsgo-template-safe-render](../letsgo-template-safe-render/SKILL.md)** — combines: on validation failure, the form struct (carrying errors and original values) is passed to `render()` as `data.Form`; the two patterns are always active together on the re-render path
- **[letsgo-db-sentinel-error-translation](../letsgo-db-sentinel-error-translation/SKILL.md)** — informs: model sentinels (e.g., `ErrInvalidCredentials`, `ErrDuplicateEmail`) are translated into `form.AddNonFieldError(...)` calls, bridging model errors into the form validation display
- **[go-http-service-di-composition](../go-http-service-di-composition/SKILL.md)** — depends on: `formDecoder` is a struct field on `application`; the embedded Validator pattern is made available to handlers through the `*application` receiver
- **go-http-service-test-strategy** — informs: end-to-end form tests must extract the CSRF token and re-submit it; the `Valid()`/`FieldErrors` contract is what test assertions verify in the response HTML
