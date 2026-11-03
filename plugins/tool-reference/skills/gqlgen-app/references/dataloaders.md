# Dataloaders (N+1 Prevention)

## Dataloaders (N+1 Prevention)

Use a dataloader to batch many individual loads into one DB query. Two library
options:

| Library                            | Approach        | Notes                                   |
| ---------------------------------- | --------------- | --------------------------------------- |
| `github.com/vektah/dataloaden`     | Code-generated  | Used in gqlgen's own examples           |
| `github.com/vikstrous/dataloadgen` | Generic library | Modern alternative; no codegen required |

The examples below use `dataloadgen`.

### Setup

```bash
go get github.com/vikstrous/dataloadgen
```

Define loader types and attach them to the request context via HTTP middleware.
Loaders must be created **per request** — they batch within one operation only.

```go
type Loaders struct {
	UserByID *dataloadgen.Loader[string, *model.User]
}

func NewLoaders(db *sql.DB) *Loaders {
	return &Loaders{
		UserByID: dataloadgen.NewLoader(
			func(ctx context.Context, ids []string) ([]*model.User, []error) {
				// one DB query for all ids collected in this tick
				rows := db.QueryUsersByIDs(ctx, ids)
				byID := make(map[string]*model.User, len(rows))
				for _, u := range rows {
					byID[u.ID] = u
				}
				// results must be in the same order as ids
				result := make([]*model.User, len(ids))
				errs := make([]error, len(ids))
				for i, id := range ids {
					result[i] = byID[id]
					if result[i] == nil {
						errs[i] = fmt.Errorf("user %s not found", id)
					}
				}
				return result, errs
			},
			dataloadgen.WithWait(500*time.Microsecond),
		),
	}
}

type loadersKey struct{}

func LoadersMiddleware(db *sql.DB, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := context.WithValue(r.Context(), loadersKey{}, NewLoaders(db))
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func GetLoaders(ctx context.Context) *Loaders {
	return ctx.Value(loadersKey{}).(*Loaders)
}
```

### Usage in Resolver

```go
func (r *todoResolver) User(ctx context.Context, obj *model.Todo) (*model.User, error) {
	return GetLoaders(ctx).UserByID.Load(ctx, obj.UserID)
}
```

Multiple resolver calls for `User` within one GraphQL operation are automatically
batched into a single `QueryUsersByIDs` call.

### One-to-Many Loaders

When each key maps to a slice of results, use `[]*T` as the value type:

```go
PostsByAuthorID * dataloadgen.Loader[string, []*model.Post]

// fetch returns [][]*model.Post, one slice per author id
func(ctx context.Context, authorIDs []string) ([][]*model.Post, []error) {
	rows := db.QueryPostsByAuthorIDs(ctx, authorIDs)
	byAuthor := make(map[string][]*model.Post)
	for _, p := range rows {
		byAuthor[p.AuthorID] = append(byAuthor[p.AuthorID], p)
	}
	result := make([][]*model.Post, len(authorIDs))
	for i, id := range authorIDs {
		result[i] = byAuthor[id] // empty slice if no posts
	}
	return result, make([]error, len(authorIDs))
}
```
