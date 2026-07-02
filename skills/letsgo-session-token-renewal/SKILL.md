---
name: letsgo-session-token-renewal
description: Invoke when implementing login or logout handlers in a Go web app, or when auditing session management for session fixation vulnerabilities.
---
# Session Token Renewal on Every Authentication State Change

## R — Reading

> "It's good practice to generate a new session token before making any authorization or privilege level changes... But we should also generate a new session token when the user logs out — as well as when they log in. If we don't, an attacker could potentially fix a session ID after login, wait for the user to log out and log back in, and then use the same (fixed) session ID to access the newly-authenticated session."

## 10.04-User-Login, 10.05-User-Logout

## I — Interpretation

Session fixation is a two-window attack. Most developers know the first window: before login, an attacker plants a session ID in the victim's browser (via URL parameter, XSS, or network interception); the victim authenticates; the attacker uses the same session ID to access the authenticated session. Renewing the token on login closes this window.

The second window is less known. After login, the attacker observes or plants a post-login session ID. The user logs out. Without token renewal on logout, the session ID is reused for the next login. The attacker fixes the post-logout session, waits for the victim to re-authenticate, and inherits the new authenticated state. Renewing on logout closes this second window.

The rule is: every transition between authentication states issues a new session ID. Transitions are: unauthenticated → authenticated (login), authenticated → unauthenticated (logout). Both directions require `RenewToken()`.

The SCS library's `RenewToken(ctx)` generates a new session token value and migrates the existing session data to the new token in a single operation. It does not destroy the session data — flash messages, form data, and other session state survive the token renewal. Call `RenewToken` before setting or removing the `authenticatedUserID` session value.

Session middleware placement matters: `LoadAndSave` belongs on the `dynamic` chain (HTML routes), not the `standard` chain (which includes static files). Serving a CSS file should not create a session cookie.

## A1 — Past Application

In Snippetbox, the login handler:

```go
func (app *application) userLoginPost(w http.ResponseWriter, r *http.Request) {
	// ... decode and validate form ...

	id, err := app.users.Authenticate(form.Email, form.Password)
	if err != nil {
		if errors.Is(err, models.ErrInvalidCredentials) {
			form.AddNonFieldError("Email or password is incorrect")
			// re-render login form
			return
		}
		app.serverError(w, r, err)
		return
	}

	err = app.sessionManager.RenewToken(r.Context()) // renew BEFORE setting auth
	if err != nil {
		app.serverError(w, r, err)
		return
	}
	app.sessionManager.Put(r.Context(), "authenticatedUserID", id)
	http.Redirect(w, r, "/snippet/create", http.StatusSeeOther)
}
```

And the logout handler:

```go
func (app *application) userLogoutPost(w http.ResponseWriter, r *http.Request) {
	err := app.sessionManager.RenewToken(r.Context()) // renew BEFORE removing auth
	if err != nil {
		app.sessionError(w, r, err)
		return
	}
	app.sessionManager.Remove(r.Context(), "authenticatedUserID")
	app.sessionManager.Put(r.Context(), "flash", "You've been logged out successfully!")
	http.Redirect(w, r, "/", http.StatusSeeOther)
}
```

The logout renewal is the non-obvious half. Without it, the second fixation window is open.

## A2 — Future Trigger ★

- Implementing a login handler — the first RenewToken call is easy to forget
- Implementing a logout handler — the second RenewToken call is the one most implementations miss
- Reviewing authentication code for session fixation: look for `RenewToken` in both handlers
- Adding privilege escalation (e.g., sudo mode, re-authentication for sensitive operations) — these also require `RenewToken`
- Any code that calls `sessionManager.Put(ctx, "authenticatedUserID", ...)` without a preceding `RenewToken`

## E — Execution

1. Initialize SCS with a database store and secure cookie settings: `sessionManager.Cookie.Secure = true`, `sessionManager.Lifetime = 12*time.Hour`
2. Add `sessionManager.LoadAndSave` to the `dynamic` chain only — not to `standard` (static files must not trigger session creation)
3. In the login handler: call `RenewToken(r.Context())` first; check the error; then call `Put(ctx, "authenticatedUserID", id)`
4. In the logout handler: call `RenewToken(r.Context())` first; check the error; then call `Remove(ctx, "authenticatedUserID")`
5. For flash messages: use `Put(ctx, "flash", message)` in the redirect source and `PopString(ctx, "flash")` in `newTemplateData()` — `PopString` reads and deletes atomically
6. In `authenticate` middleware: read `authenticatedUserID` from session; verify the user still exists in DB via `users.Exists(id)`; set a typed context key (not a string key) to signal authenticated status downstream

## B — Boundary

This pattern covers session fixation prevention for standard login/logout flows. It does not cover token theft after authentication (that requires HTTPS, `Secure` and `HttpOnly` cookie flags, and short session lifetimes). SCS's MySQL store ties session persistence to the database; a Redis store is available for lower latency and automatic TTL expiry. Does not cover multi-session management (logging out all devices), concurrent login detection, or session binding to IP/User-Agent. Graceful session invalidation on password change is not covered in Let's Go (see Let's Go Further).

## Related Skills

- **go-http-middleware-construction-and-organization** — depends on: `sessionManager.LoadAndSave` must be placed on the `dynamic` chain in `routes()` for session state to be available to login and logout handlers at all
- **go-http-service-di-composition** — depends on: `sessionManager` is a struct field on `application`; login and logout handlers call it through the `*application` receiver
- **letsgo-form-validator** — informs: the login handler uses both patterns simultaneously — `form.AddNonFieldError(...)` on `ErrInvalidCredentials` and `RenewToken()` before setting `authenticatedUserID`; understanding both is required to implement login correctly
- **letsgo-db-sentinel-error-translation** — informs: `ErrInvalidCredentials` is what the login handler checks to decide whether to call `AddNonFieldError` or `RenewToken`; sentinel translation is upstream of token renewal
- **go-http-service-test-strategy** — informs: session state across redirects requires the test client's cookie jar; the login/logout token renewal flow is what makes end-to-end multi-request test sequences meaningful

______________________________________________________________________

## Provenance

- **Source:** Let's Go, Alex Edwards, 2023
