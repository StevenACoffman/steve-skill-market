# Datastore

## Model Struct Requirements (`ka-datastore-model`)

```go
type UserData struct {
	datastore.BaseModel           // required embed
	Name                string    `datastore:"name"`                 // all fields must be tagged
	CreatedAt           time.Time `datastore:"created_at,omitempty"` // time: omitempty
	Profile             Profile   `datastore:"profile,omitempty"`    // struct: omitempty
	Tags                []string  `datastore:"tags"`                 // slice: NO omitempty
}

// Required: key constructor in same file
func MakeUserDataKey(id string) *datastore.Key { return nil }

// Required: PreSave calls both super and safety check
func (m *UserData) PreSave(ctx context.Context) error {
	if err := m.BaseModel.PreSave(ctx); err != nil {
		return errors.Wrap(err)
	}
	return datastore.CheckTransactionSafetyForPut(ctx, m)
}
```

`omitempty` rules summary: **struct and `time.Time` fields** → add `omitempty`;
**slice fields** → never add `omitempty` (already omitted by datastore, adding
it breaks behavior).

## Key Construction (Service/non-Model Code)

```go
// Bad — raw key constructors banned in service code
key := datastore.NameKey("UserData", id, nil)
key := datastore.IDKey("UserData", numID, nil)

// Good — generated helpers
key := models.MakeUserDataKey(id)
```

## Transaction Closures (`ka-datastore-transaction`)

Outer variables declared with zero value and modified inside a transaction
closure **must be re-initialized at the very top** of the closure. Transactions
may retry up to three times, so the closure must be idempotent — it must
produce the same result whether it runs once or three times.

```go
var user models.UserData
err := ctx.Datastore().RunInTransaction(ctx, func(txn *datastore.Transaction) error {
	user = models.UserData{} // re-init first, before any other statement
	return getUserAndModify(ctx, txn, &user)
})
```

## Not-Found Handling (`ka-datastore-not-found`)

Functions that call `Get`/`GetMulti`/`GetAll`/`Iterator.Next` must never
return `(nil, nil)`.

```go
// Bad
if err := ctx.Datastore().Get(ctx, key, &u); err != nil {
	return nil, nil
}

// Good
if err := ctx.Datastore().Get(ctx, key, &u); err != nil {
	if datastore.IsNotFound(err) {
		return nil, errors.NotFound("user %s not found", id)
	}
	return nil, errors.Wrap(err)
}
return &u, nil
```

## Datastore Access Boundaries (ADR-312)

Code in `models/`, `pkg/services_shared/`, and `resolvers/` must **not** call
`ctx.Datastore()` or `datastore.Transaction`. Put datastore calls in a
dedicated service layer and call it from those packages. The one exception:
`resolvers/backfills.go` files may call `ctx.Datastore()` directly.
