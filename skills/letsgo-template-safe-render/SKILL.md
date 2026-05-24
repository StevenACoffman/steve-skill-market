---
id: letsgo-template-safe-render
title: Template Cache with Two-Stage Safe Render
description: Invoke when writing the render helper for a Go HTML template service — specifically to prevent the partial-200 failure mode where a template error produces corrupted HTML with an incorrect 200 status.
source: Let's Go, Alex Edwards, 2023
---

## R — Reading

> "There's an important detail here: we're first writing our template to a `bytes.Buffer`... If there's an error executing the template, we call our `serverError()` helper method and return. Because we haven't written anything to `http.ResponseWriter` yet, the user will still receive a proper error response... But if the template is executed successfully, we then write the buffer contents to our `http.ResponseWriter`."

## 05.04-Catching-Runtime-Errors

## I — Interpretation

The failure mode this pattern prevents is subtle. `http.ResponseWriter` is a streaming writer. The first call to `Write()` or `WriteHeader()` sends HTTP headers — including the status code — to the TCP connection. Once headers are sent, they cannot be changed. Template execution is incremental: the engine writes bytes to the writer as it processes each node. If the template encounters an error halfway through (missing data field, wrong type), bytes and a 200 status have already been sent. There is no mechanism to recall them and substitute a 500 error response. The client receives corrupted HTML with a 200 OK status.

The fix is a two-stage render. A `bytes.Buffer` is an in-memory writer; writes to it cost nothing on the network. Execute the template into the buffer. If execution fails, the buffer is discarded and `serverError(w, r, err)` writes a proper 500 to the still-clean `http.ResponseWriter`. If execution succeeds, `w.WriteHeader(status)` and `buf.WriteTo(w)` flush the complete, verified response in one shot.

The template cache is the other half of this skill. Parsing templates on every request is slow and surfaces parse errors at runtime on the first affected request. Building a `map[string]*template.Template` at startup in `newTemplateCache()` achieves two things: templates are pre-validated (a malformed template is a startup failure, not a user-visible runtime error), and the cache is warm from the first request.

Both techniques together — startup cache building plus two-stage render — form a complete safe rendering strategy.

## A1 — Past Application

In Snippetbox, the `render()` helper is:

```go
func (app *application) render(w http.ResponseWriter, r *http.Request,
	status int, page string, data templateData) {
	ts, ok := app.templateCache[page]
	if !ok {
		err := fmt.Errorf("the template %s does not exist", page)
		app.serverError(w, r, err)
		return
	}

	buf := new(bytes.Buffer)

	err := ts.ExecuteTemplate(buf, "base", data)
	if err != nil {
		app.serverError(w, r, err)
		return
	}

	w.WriteHeader(status)
	buf.WriteTo(w)
}
```

And `newTemplateCache()` in `main()`:

```go
templateCache, err := newTemplateCache()
if err != nil {
	logger.Error(err.Error())
	os.Exit(1)
}
```

The startup failure is intentional — a malformed template is a deployment error, not something to surface to users.

## A2 — Future Trigger ★

- Writing a `render()` helper for any Go application serving HTML templates
- Debugging a bug where the response body is truncated HTML but the status code is 200
- Adding a new template data field and getting a template execution error in production
- Reviewing a PR where `ts.Execute(w, data)` is called directly without buffering
- Any situation where `w.WriteHeader()` and `t.Execute()` appear close together and the ordering seems uncertain

## E — Execution

1. Build template cache at startup: walk `ui/html/pages/*.tmpl`, parse each page with the base layout and all component partials, store in `map[string]*template.Template`; fail fast if any parse fails
2. Store the cache in `app.templateCache` (an `application` struct field)
3. In the `render()` helper: look up the template by page name; if not found, call `serverError` and return
4. Allocate `buf := new(bytes.Buffer)` and call `ts.ExecuteTemplate(buf, "base", data)` — the writer is the buffer, not `w`
5. Check the error from `ExecuteTemplate`; on error call `serverError(w, r, err)` and return — `w` is still clean
6. On success: call `w.WriteHeader(status)` then `buf.WriteTo(w)` — headers and body go out together after verification

## B — Boundary

Templates are loaded once at startup and not reloaded on change — a server restart is required after template edits. For development, an environment flag can skip the cache and call `newTemplateCache()` on each request. This pattern applies only to server-rendered HTML; JSON APIs that call `json.NewEncoder(w).Encode(data)` have the same partial-write problem for large payloads, but the solution there is different (encode to buffer, then copy). Does not cover template inheritance strategies, content negotiation, or streaming responses where the two-stage approach is intentionally bypassed.

## Related Skills

- **[go-http-service-di-composition](../go-http-service-di-composition/SKILL.md)** — depends on: `templateCache` is a field on `application`; `render()` is a method on `*application` that reads from it
- **[letsgo-form-validator](../letsgo-form-validator/SKILL.md)** — combines: `render()` is the function called on validation failure; the form struct carrying its validation state is the `data.Form` value passed to `render()` — these two patterns are always used together on the re-render path
- **go-http-service-test-strategy** — informs: `newTestApplication(t)` must supply a test template cache so end-to-end tests can exercise the two-stage render path without a filesystem
- **go-http-middleware-construction-and-organization** — informs: the `dynamic` chain's session and CSRF middleware run before handlers that call `render()`; CSRF token injection into template data is part of the render data pipeline
