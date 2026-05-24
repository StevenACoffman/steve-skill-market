---
name: webapp-featureflags
description: |
  Use when writing Go code in github.com/Khan/webapp that evaluates or mocks
  a GrowthBook feature flag. Covers the KAContext interface, the Client API
  (IsOn/IsOff/GetFeatureValue), the Attributes struct, and how to mock flag
  values in tests. ONLY applies to github.com/Khan/webapp.

  Trigger signals:
  - "how do I check a feature flag in webapp?"
  - "how do I gate code behind a flag?"
  - "how do I mock a feature flag in a test?"
  - "what attributes can I pass to a feature flag?"
  - "featureflags.IsOn vs IsOff vs GetFeatureValue"
  - Any question about GrowthBook flags in webapp Go code
allowed-tools: Bash, Read, Edit, Write
---

# Feature Flags in Webapp

> **Scope:** This skill applies exclusively to `github.com/Khan/webapp`. The
> `featureflags` package wraps GrowthBook with a webapp-specific subset of its
> API. Do not apply these patterns to any other repository.

Package: `github.com/Khan/webapp/pkg/external/featureflags`

______________________________________________________________________

## KAContext Interface

Embed `featureflags.KAContext` in a function's context parameter to access the
client:

```go
import "github.com/Khan/webapp/pkg/external/featureflags"

func myFunc(ctx interface {
	featureflags.KAContext
	// ... other sub-interfaces
}) error {
	on, err := ctx.FeatureFlags().IsOn(ctx, "my-flag", featureflags.Attributes{
		Kaid: userKaid,
	})
	// ...
}
```

`ctx.FeatureFlags()` returns a `featureflags.Client`.

______________________________________________________________________

## Client Interface

```go
type Client interface {
	IsOn(ctx KAContext, flagname FeatureFlagName, attributes Attributes) (bool, error)
	IsOff(ctx KAContext, flagname FeatureFlagName, attributes Attributes) (bool, error)
	GetFeatureValue(ctx KAContext, flagname FeatureFlagName, attributes Attributes) (any, error)
	Close() error
}
```

| Method            | Returns `true` when…                                                     |
| ----------------- | ------------------------------------------------------------------------ |
| `IsOn`            | Flag value is truthy (JavaScript semantics: non-zero, non-empty, `true`) |
| `IsOff`           | Flag value is falsy                                                      |
| `GetFeatureValue` | Returns the raw value (`bool`, `string`, `int`, etc.)                    |

`FeatureFlagName` is a `string` type alias. Prefer defining named constants for
flag names in your service rather than using bare string literals.

______________________________________________________________________

## Attributes

```go
type Attributes struct {
	Kaid     string // User's KAID
	KALocale string // User's locale (e.g., "en")
}
```

Only these two attributes are supported. GrowthBook rules can target specific
kaids or locale values. Pass an empty `Attributes{}` for anonymous or system
contexts where a user is not available.

______________________________________________________________________

## Production Usage Pattern

```go
const flagStreamingTranslation featureflags.FeatureFlagName = "streaming-translation"

func handleRequest(ctx interface {
	featureflags.KAContext
	web.AuthedUserContext
}) error {
	kaid := ""
	if user, err := ctx.RequestUser(); err == nil && user != nil {
		kaid = user.Kaid
	}

	on, err := ctx.FeatureFlags().IsOn(ctx, flagStreamingTranslation, featureflags.Attributes{
		Kaid: kaid,
	})
	if err != nil {
		return err
	}
	if on {
		// new code path
	}
	// ...
}
```

______________________________________________________________________

## Testing — Mocking Flag Values

`servicetest.Suite.KAContext()` wires up a `featureflags.TestClient`
automatically. Evaluating an unmocked flag returns an error (`"You must set a mock value for this flagname"`), so every flag used by code under test must be
mocked.

### Global Mock (Same Value for All Attributes)

```go
func (s *mySuite) TestFeatureOn() {
	ctx := s.KAContext()
	ctx.FeatureFlags().(*featureflags.TestClient).MockFlagValue(
		"streaming-translation", true,
	)
	// code under test will see the flag as on
}
```

### Attribute-Specific Mock

```go
ctx.FeatureFlags().(*featureflags.TestClient).MockFlagValueForAttributes(
	"streaming-translation",
	featureflags.Attributes{Kaid: "kaid_teacher001"},
	true,
)
// Other kaids will fall through to the global mock (or error if none set)
```

### Truthy/Falsy Type Conversions in TestClient

`IsOn`/`IsOff` accept any value type for the mock:

| Value type           | Considered "on" if… |
| -------------------- | ------------------- |
| `bool`               | `true`              |
| `string`             | non-empty           |
| `int`, `uint`        | non-zero            |
| `float32`, `float64` | non-zero            |

______________________________________________________________________

## Flag Evaluation at the Boundary

Evaluate feature flags at the outermost layer — HTTP handler, task handler, or
cron function — and pass the resulting boolean (or variant value) inward as a
plain parameter. Do not call `ctx.FeatureFlags().IsOn` from deep inside a
service or model package.

```go
// Good — flag checked at handler boundary, plain bool passed inward
func handleRequest(ctx interface {
	featureflags.KAContext
	web.AuthedUserContext
}, r *http.Request) error {
	on, err := ctx.FeatureFlags().IsOn(ctx, flagStreamingTranslation, featureflags.Attributes{
		Kaid: currentKaid(ctx),
	})
	if err != nil {
		return err
	}
	return service.ProcessRequest(ctx, r, on)
}

// service.ProcessRequest accepts a plain bool — no feature-flag dependency
func ProcessRequest(ctx context.Context, r *http.Request, streamingEnabled bool) error {}
```

This keeps core logic free of flag-evaluation side effects and makes unit tests
straightforward: pass `true` or `false` directly without mocking the flag
client.

______________________________________________________________________

## Key Import Paths

| Symbol                         | Import                                             |
| ------------------------------ | -------------------------------------------------- |
| `featureflags.KAContext`       | `github.com/Khan/webapp/pkg/external/featureflags` |
| `featureflags.Client`          | `github.com/Khan/webapp/pkg/external/featureflags` |
| `featureflags.Attributes`      | `github.com/Khan/webapp/pkg/external/featureflags` |
| `featureflags.FeatureFlagName` | `github.com/Khan/webapp/pkg/external/featureflags` |
| `featureflags.TestClient`      | `github.com/Khan/webapp/pkg/external/featureflags` |
