---
name: ai-and-semistructured-data-guard
description: "Load for RAG/chatbot ingestion or retrieval code (top_k, vector filters, chunk metadata, file paths, modified_time), LLM/AI columns (ML.GENERATE_TEXT, sentiment or category per review/comment), matcher scores written into an _id column, JSON payload extraction (JSON arrow operators, :key, TRY_CAST), or partition expiration/deleting raw event tables after a rollup."
---
# AI and Semi-Structured Data Guard

Check each item against what the user pasted. If present, fix it in the deliverable itself (code, SQL, config) with one sentence of why; a warning beside unchanged code is not a fix, even when the user asked for their plan as written. If absent, skip silently.

## Crawl time used as validity
- **Spot:** newest version picked by modified_time, crawl or index time; pasted timestamps identical or clustered across old and new files.
- **Why it breaks:** a migration or re-crawl restamps old files, so superseded versions win or tie.
- **Do:** do not rank by that timestamp. Rank by effective date/version from metadata or content (else the version or year parsed from the name), exclude archive paths, close prior versions with valid_to. Ask for an effective-date field if none exists.

## Validity filtered after top-k
- **Spot:** search(top_k=N) then a filter on status or validity dates; or recency decay as validity.
- **Why it breaks:** near-identical superseded revisions fill top-k, leaving few or no current chunks.
- **Do:** put the filter in the vector query before ranking: `WHERE status='effective'` (or `valid_from <= :as_of AND (valid_to IS NULL OR :as_of < valid_to)`) with `ORDER BY embedding <=> :q LIMIT k`.

## Entity ID only in file name
- **Spot:** the ingest loop stores text/embedding but no entity column, while the owning ID appears only in the path or URI.
- **Why it breaks:** chunks cannot be filtered by entity, so search returns other entities' content.
- **Do:** state existing rows lack the ID; add entity_id to the ingest, backfill existing chunks from the path, pre-filter retrieval on it.

## Inferred links stored as facts
- **Spot:** a matcher/LLM top candidate written straight into an FK that payments or billing reads.
- **Why it breaks:** a wrong guess looks declared and pays or bills the wrong party, unauditable.
- **Do:** write candidates to a link table with method, score, model version, review_status; auto-accept only above a threshold calibrated on labeled data; queue the rest for review; set the FK only from accepted links.

## JSON drift yields silent NULLs
- **Spot:** pasted payloads show one measure under different keys, units or types across versions, and the existing expression reads only one.
- **Why it breaks:** the other shape extracts as NULL silently, dropping those rows from totals.
- **Do:** COALESCE every key with unit/type conversion; say the old expression undercounts; add a per-version null-rate check.

## Raw data discarded after summarizing
- **Spot:** expiration or delete on raw events because a rollup exists, especially one holding distinct counts, ratios or medians.
- **Why it breaks:** those cannot be re-aggregated or re-cut by new dimensions later.
- **Do:** archive raw to cold storage before expiring, or add components and sketches to the rollup first; name the future cuts the delete makes impossible.

## LLM attributes live or unversioned
- **Spot:** AI function in a full-refresh table or view; editable prompt or auto-upgraded model; no version columns.
- **Why it breaks:** re-inference and prompt/model changes rewrite history and create unexplained trend steps.
- **Do:** make it incremental (new/changed rows only) with model and prompt version columns; filter or backfill to one version.

## Single blended score for multi-aspect text
- **Spot:** one sentiment per comment/review while sample texts mix praise and complaints about different things.
- **Why it breaks:** opposing aspects average out, hiding complaints.
- **Do:** change the schema to (document_id, aspect, sentiment, span) and aggregate per aspect.

## Not applicable when
- Validity comes from maintained effective-date/status fields; the filter is inside the vector query; links pass human approval; the entity ID is in chunk metadata; values are typed columns; raw is kept or the summary stores components/sketches; scores are incremental and versioned; sentiment is already per aspect.
- Then just do the task: no guard sections, re-checks, or mention of this card.
