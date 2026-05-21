---
name: pgxpool
description: Create and configure PostgreSQL connection pools in this repo using pgxpool. Use when setting up database connections, tuning pool settings, or using the DBTX interface.
allowed-tools: Bash, Read, Edit
---

# Pgxpool in This Repo

This repo uses [pgxpool](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool) for PostgreSQL connection pooling. The canonical setup lives in `pkg/sqldb/helpers.go`. Use `ConfigureConnectionPool` as the entry point — do not construct pools directly.

## Entry Point

```go
import "github.com/Khan/districts-jobs/pkg/sqldb"

pool, cleanup, err := sqldb.ConfigureConnectionPool(
    ctx,
    logger,
    dbInfo,
    useProdDialer,      // true in production (AlloyDB), false for local/tests
    configCustomizer,   // func(*pgxpool.Config) or nil
)
if err != nil {
    return err
}
defer cleanup()
defer pool.Close()
```

`ConfigureConnectionPool` pings the database before returning, so a successful return guarantees the pool is ready.

## Default Settings

Applied by `commonConfigToPoolWithPing` (called internally):

| Setting             | Value                 | Why                                                               |
| ------------------- | --------------------- | ----------------------------------------------------------------- |
| `MaxConns`          | 25                    | Above 25 rarely improves throughput; prevents database exhaustion |
| `MaxConnLifetime`   | 30 minutes            | Below AlloyDB and App Engine limits (both 10–30 min)              |
| `ConnConfig.Tracer` | `otelpgx.NewTracer()` | Emits OpenTelemetry spans and metrics for every query             |

Override any of these via the `configCustomizer` parameter:

```go
pool, cleanup, err := sqldb.ConfigureConnectionPool(
    ctx, logger, dbInfo, false,
    func(cfg *pgxpool.Config) {
        cfg.MaxConns = 5   // reduced for test environment
    },
)
```

## Building DBInfo

`sqldb.MakeDBInfo` builds the connection parameters struct:

```go
dbInfo := sqldb.MakeDBInfo(
    "myuser",
    "mypassword",
    "mydbname",
    "myschema",
    readOnly, // true for read-only replica
)
```

For tests against a local PostgreSQL instance (not AlloyDB), set `DBHost` directly:

```go
dbInfo := &sqldb.DBInfo{
    DBUser:   "postgres",
    DBPass:   "",
    DBPort:   "5432",
    DBName:   "testdb",
    DBHost:   "localhost",
    DBSchema: []string{"testschema"},
}
```

## Production Vs. Local

`useProdDialer = true` routes through AlloyDB Language Connector (`alloydbconn`), which provides mutual TLS and IAM authorization. Use this in Kubernetes deployments.

`useProdDialer = false` uses a plain TCP connection via `pgxpool.ParseConfig`. Use this for local development and tests.

## The DBTX Interface

`pkg/sqldb/helpers.go` defines `DBTX`, which wraps the generated `districtsql.DBTX` and adds `Begin`:

```go
type DBTX interface {
    districtsql.DBTX                               // Exec, Query, QueryRow
    Begin(ctx context.Context) (pgx.Tx, error)
}
```

`*pgxpool.Pool` satisfies `DBTX` without any adapters. Services should accept `sqldb.DBTX` rather than `*pgxpool.Pool` to keep them testable with a transaction-backed double.

## Using the Pool with Sqlc

Pass the pool to any generated query package:

```go
import (
    "github.com/Khan/districts-jobs/pkg/generated/districtsql"
    "github.com/Khan/districts-jobs/pkg/sqldb"
)

q := districtsql.New(pool)
result, err := q.GetDistrict(ctx, sqldb.ToUUID(districtID))
```

## Transactions

`pool.Begin` returns a `pgx.Tx`, which satisfies `districtsql.DBTX` and preserves the OTel tracer chain. Always defer `Rollback` — it is a no-op after `Commit`:

```go
tx, err := pool.Begin(ctx)
if err != nil {
    return err
}
defer tx.Rollback(ctx)

q := districtsql.New(tx)
if err := q.ActivateClassroom(ctx, params); err != nil {
    return err
}
return tx.Commit(ctx)
```

Do not use `database/sql`-style transactions (`*sql.Tx`). `pgx.Tx` carries the tracer; `*sql.Tx` does not — query spans would be silently dropped inside a `*sql.Tx`-backed `Queries`.

## Params Helpers

`pkg/sqldb/params.go` converts Go values to the PostgreSQL types that generated queries expect. Use these instead of constructing `pgtype.*` values directly:

```go
import "github.com/Khan/districts-jobs/pkg/sqldb"

// String → uuid.NullUUID
id := sqldb.ToUUID(req.DistrictID)

// String → pgtype.Text (always valid)
name := sqldb.ToText(req.Name)

// String → pgtype.Text (empty string becomes NULL)
desc := sqldb.ToNullableText(req.Description)

// bool → pgtype.Bool
active := sqldb.ToBool(req.Active)

// []string → []uuid.NullUUID
ids := sqldb.ToUUIDs(req.DistrictIDs)
```

## Observability

### What `otelpgx` Instruments

`otelpgx.NewTracer()` returns a single tracer object that implements six of pgx's seven tracer interfaces:

| Interface               | What it traces                                             |
| ----------------------- | ---------------------------------------------------------- |
| `pgx.QueryTracer`       | Every `Exec`, `Query`, `QueryRow` call                     |
| `pgx.PrepareTracer`     | Prepared statement cache misses (first use per connection) |
| `pgx.BatchTracer`       | `SendBatch` calls and each query within a batch            |
| `pgx.CopyFromTracer`    | `CopyFrom` bulk insert operations                          |
| `pgx.ConnectTracer`     | New database connections being established                 |
| `pgxpool.AcquireTracer` | Connection acquisitions from the pool                      |

Each query call through the pool produces this sequence of spans:

```text
pgxpool.acquire             ← connection borrowed
postgresql.prepare_statement ← first execution of this SQL on this connection only
query <SQL or name>         ← the actual round-trip to Postgres
```

The prepare span fires at most once per query per connection in the pool (pgx caches 512 prepared statements per connection via LRU). On all subsequent calls through the same connection it is skipped.

### Span Naming (Current Default)

With the current `otelpgx.NewTracer()` call (no options), span names are the **full SQL string** prefixed with `"query "`. For a sqlc query like:

```sql
-- name: GetDistrict :one
SELECT id, name FROM district WHERE id = $1
```

The span name becomes `"query -- name: GetDistrict :one\nSELECT id, name FROM district WHERE id = $1"`. This is verbose and noisy in traces.

### Improving Span Names for Sqlc Queries

To use the sqlc query name (`GetDistrict`) as the span name, override the tracer in `configCustomizer`:

```go
import (
    "regexp"
    "strings"
    "github.com/exaring/otelpgx"
)

var sqlcNameRe = regexp.MustCompile(`^(?:--|/\*)\s*name:\s*(\w+)`)

pool, cleanup, err := sqldb.ConfigureConnectionPool(
    ctx, logger, dbInfo, useProdDialer,
    func(cfg *pgxpool.Config) {
        cfg.ConnConfig.Tracer = otelpgx.NewTracer(
            otelpgx.WithSpanNameCtxFunc(func(_ context.Context, stmt string) string {
                if m := sqlcNameRe.FindStringSubmatch(stmt); len(m) > 1 {
                    return m[1]
                }
                if fields := strings.Fields(stmt); len(fields) > 0 {
                    return fields[0]
                }
                return "query"
            }),
            otelpgx.WithDisableSQLStatementInAttributes(), // omit raw SQL from span attributes in prod
        )
    },
)
```

This produces span names like `GetDistrict`, `ListTeachers`, `UpsertCurrentYear`.

### Other Useful Options

```go
// Include connection host/port in span attributes (on by default, disable to reduce cardinality)
otelpgx.WithDisableConnectionDetailsInAttributes()

// Include the SQL statement text as a span attribute (on by default)
otelpgx.WithDisableSQLStatementInAttributes()

// Include bound parameter values (off by default — avoid in prod: exposes PII)
otelpgx.WithIncludeQueryParameters()

// Use only the first SQL keyword as span name (SELECT, INSERT, etc.)
otelpgx.WithTrimSQLInSpanName()
```

### Pool-Level Metrics

To get connection pool stats (useful in health checks or dashboards):

```go
stats := pool.Stat()
// stats.TotalConns(), stats.IdleConns(), stats.AcquiredConns()
```
