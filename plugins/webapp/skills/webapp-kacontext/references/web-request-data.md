# Web Request Data

`web.*Context` interfaces expose per-request data parsed from the incoming HTTP
request. These are available after `Upgrade()` in handlers and resolvers.

```go
// Current authenticated user
user, err := ctx.RequestUser()
if err != nil {
	// err is non-nil if there is no authenticated user
	return nil, errors.Wrap(err)
}
kaid := user.Kaid
isPhantom := user.IsPhantom

// Locale
locale := ctx.KALocale() // e.g., "en", "es"

// Request hostname
host := ctx.OriginalHost() // e.g., "www.khanacademy.org"

// Cookie read/write
cookieVal := ctx.Cookies().Get("my_cookie")
ctx.SetCookie(w, cookie)
```

## `SetActor` — Updating the Authenticated User After Login

Login mutations replace the request's authenticated user after verifying credentials:

```go
ctx.SetActor(
	web.UserIdentity{
		Kaid:              kaid,
		BingoID:           userData.GAEBingoIdentity,
		HasAnyPermissions: userData.HasAnyPermissions,
		IsPhantom:         userData.IsPhantom,
	},
	cookies.NewCookieCache(userData, userSettings, "").AsCombinedHeader(),
)
// After SetActor: ctx.RequestUser() returns the new identity,
// and cross-service GraphQL calls include updated auth headers.
```

`SetActor` is only available via `web.SetActorContext`. Include it in the context
interface only in login-related code.
