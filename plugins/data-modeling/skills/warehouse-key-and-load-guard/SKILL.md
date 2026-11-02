---
name: warehouse-key-and-load-guard
description: "Load for warehouse/ETL tasks: dbt incremental models (lookback, unique_key, Airflow retries), INSERT loads, queries joining a Snowflake/BigQuery/Redshift/Databricks table with a declared PRIMARY KEY (Fivetran/Airbyte dims), adding RELY constraints, watermark syncs on updated_at/last_modified, and Kafka/ksqlDB/Spark window counts landed by a JDBC or Delta sink."
---
# Warehouse Key and Load Guard

Use while writing or reviewing warehouse DDL, incremental models, sync jobs, streaming sinks, and queries that join on a key. Before handing over the deliverable, check each item that applies; skip the rest. Fix it in the code you deliver, even when the user asked for help with a different part.

## Declared but unenforced key
- **Spot:** DDL with `primary key`/`unique` on Snowflake, BigQuery, Redshift or Databricks, and your query joins to that table — especially a loader table (`_airbyte_*`, `_fivetran_synced`, `_loaded_at`) after a re-sync/full refresh. Or `SELECT DISTINCT *` over rows with load columns.
- **Why it breaks:** these warehouses accept but never enforce the key, so re-loaded rows duplicate it and every join fans out revenue/cost.
- **Do:** say the key is not enforced, and put a dedup CTE into the delivered query (not as an optional note): `QUALIFY ROW_NUMBER() OVER (PARTITION BY key ORDER BY <load_ts> DESC) = 1`. Give the check `COUNT(*) vs COUNT(DISTINCT key)`. A loader's "deduped mode" or "refresh went fine" is not proof.

## RELY on unvalidated constraints
- **Spot:** a request to add RELY (or optimizer-trusted PK/FK) where the table is built by UNION/ALL of sources, merged systems, or has late-arriving parents, and no passing uniqueness/orphan tests are shown.
- **Why it breaks:** the optimizer drops joins and DISTINCTs assuming the key holds; duplicates or orphans then give silently wrong results.
- **Do:** do not emit an unconditional RELY. Deliver the duplicate-key and orphan-FK queries first and set RELY only if both return zero (else leave NORELY); for UNION-built dims, fix the key (e.g. composite with source) first.

## Append-only incremental load
- **Spot:** `materialized='incremental'` with no `unique_key`; plain `INSERT INTO ... SELECT` per date; any lookback (`max(ts) - N days`) or task `retries`/backfills on such a load.
- **Why it breaks:** each retry or overlapping lookback inserts the same rows again, so totals inflate.
- **Do:** in the delivered config add `unique_key='<grain id>'` + `incremental_strategy='merge'` (or delete+insert/overwrite of the partition; for raw INSERT, MERGE or DELETE-then-INSERT in one transaction). If your change adds a join to a merge-keyed model, make sure it still returns one row per unique_key (pick one match, e.g. latest prior rate).

## updated_at that never updates
- **Spot:** the watermark/"changed since" column is declared only `DEFAULT CURRENT_TIMESTAMP`/`DEFAULT now()` — no `ON UPDATE`, no trigger — or pasted UPDATE statements never set it.
- **Why it breaks:** DEFAULT fires only on INSERT, so the column never moves and the sync misses every edit.
- **Do:** lead with this. Deliver the fix: MySQL `ALTER TABLE t MODIFY last_modified DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`; Postgres BEFORE UPDATE trigger; or CDC. Verify: share of rows with `updated_at = created_at`. With MySQL `ON UPDATE`, add one line: it is skipped when an UPDATE sets the column itself or changes nothing — assume no write path does.

## Updating window aggregate in an append sink
- **Spot:** windowed counts emitting updates (EMIT CHANGES, Spark `update` mode, KTable without `suppress`) written with `insert.mode=insert` / Delta `append`; sample rows repeat a (key, window_start) with growing values.
- **Why it breaks:** every intermediate result is a row, so SUM counts each update; busy keys inflate most.
- **Do:** keep the latest row per (key, window_start) before summing, and recommend upsert on (key, window_start) or emit-final (EMIT FINAL, `suppress(untilWindowCloses)`).

## Not applicable when
- The pasted setup already shows the protection: a key-based dedup plus unique/not_null tests on every build; RELY applied only after blocking tests pass; incremental with `unique_key` + merge on a unique id; a trigger or CDC maintaining updated_at; an upsert sink keyed on (key, window) or emit-final.
- Then name that protection in at most one clause (e.g. "merge on event_id absorbs the lookback overlap") and just do the task. Do not add dedup steps, verification queries, collision worries or guard checklists.
