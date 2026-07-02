---
name: storage-engine-workload-selection
description: |
  Invoke this skill when selecting a storage engine or database for a new system, or when an existing storage engine is producing performance problems that are workload-driven (not query or schema problems). The key input is the ratio of writes to reads, whether access is by single key or by range/aggregate, and whether the workload is operational (low-latency per-row access) or analytical (bulk column scans).
tags: [storage-engine, lsm-tree, b-tree, columnar, write-amplification, compaction, oltp, olap, workload-classification]
allowed-tools: Bash, Read, Edit
---

# Storage Engine Workload Selection

## Current State

Storage backends in use:
!`grep -rln 'cloud\.google\.com/go/datastore\|github\.com/jackc/pgx\|go\.mongodb\.org\|redis' --include='*.go' . 2>/dev/null | head -10`

OLAP / analytics query patterns:
!`grep -rn 'GROUP BY\|SUM(\|COUNT(\|AVG(\|analytics\|report\|aggregate' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Write-heavy vs read-heavy indicators:
!`grep -rn '\.Put(\|\.Upsert(\|\.Insert(\|\.Update(' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | wc -l`

## R — Original Text (Reading)

> In particular, there is a big difference between storage engines that are optimized for transactional workloads (OLTP) and those that are optimized for analytics. This chapter starts by examining two families of storage engines for OLTP: log-structured storage engines that write out immutable data files, and storage engines such as B-trees that update data in place.
>
> The db_set function has pretty good performance for something that is so simple, because appending to a file is generally very efficient. Similarly to what db_set does, many databases internally use a log, which is an append-only data file.
>
> On the other hand, the db_get function has terrible performance if you have a large number of records in your database. Every time you want to look up a key, db_get has to scan the entire database file from beginning to end, looking for occurrences of the key.
>
> LSM-trees are typically faster for writes, whereas B-trees are thought to be faster for reads. Reads are slower on LSM-trees because they have to check several different data structures and SSTables at different stages of compaction.
>
> — Kleppmann & Riccomini, Chapter 4: Storage and Retrieval

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The framework selects a storage engine by classifying the workload along two axes: write/read ratio and access pattern (operational per-key vs. analytical bulk scan). Three engine archetypes cover the space:

**LSM-tree (Log-Structured Merge-tree)**: Writes are always sequential appends to an in-memory buffer (memtable), flushed to immutable sorted SSTables on disk. Compaction merges and garbage-collects SSTables in the background. Write performance is excellent because sequential I/O is always faster than random I/O. Read performance is worse than B-trees because reads must check multiple SSTables at different compaction levels (mitigated by Bloom filters). Compaction is an operational hazard: background I/O competes with foreground operations; under sustained high write throughput, compaction debt can accumulate and cause write stalls or latency spikes. Examples: RocksDB, LevelDB, Cassandra, ScyllaDB, HBase.

**B-tree**: Data is organized in fixed-size pages, updated in place. Random writes require seeking to the correct page and overwriting it — slower for high write throughput but providing more predictable read latency (a bounded number of page lookups). B-trees are the dominant structure for OLTP databases with mixed read/write workloads. Write amplification exists but is bounded and predictable. Examples: PostgreSQL, MySQL InnoDB, SQLite.

**Columnar (column-oriented)**: Data for the same column across all rows is stored contiguously, compressed together, and read together. Dramatically faster for analytical queries that scan a few columns across many rows (aggregations, GROUP BY, range scans). Write performance is poor for individual row inserts (the row must be decomposed across all column files). The correct choice for analytical workloads, not for operational per-row writes. Examples: Parquet, Iceberg, ClickHouse, Redshift, BigQuery, DuckDB.

The decision procedure:

1. Classify: is this workload operational (individual row reads/writes, user-facing latency) or analytical (bulk scans, aggregations, batch)? Columnar is for analytical; LSM and B-tree are for operational.
2. For operational: what is the write/read ratio? High write throughput → LSM. Mixed or read-heavy → B-tree.
3. For LSM: plan compaction explicitly. Compaction must be tuned; the defaults are often wrong for sustained high write loads. Monitor SSTable count, compaction queue depth, and write stall events as operational health metrics.
4. For mixed workloads (high-volume operational writes + analytical queries): use LSM for the hot write path and a separate batch export to columnar storage for analytical queries.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Bash Key-Value Store — Write Vs. Read Tension from First Principles

- **Question:** A two-function bash key-value store (append to file on write, scan file on read) demonstrates a fundamental storage trade-off. What does it teach about engine selection?
- **Use of Methodology:** The framework derives the write/read tension from first principles: appending to a file is O(1) and highly efficient (sequential I/O). Scanning the same file for a key is O(n) — unacceptable for large datasets. This is the foundational trade-off all storage engines resolve. An in-memory hash index turns reads to O(1) but requires all keys to fit in RAM. SSTables add sorted structure to make larger-than-RAM reads tractable. B-trees add in-place updates for bounded random read latency. Columnar adds per-column compression for analytical scan efficiency.
- **Conclusion:** Every storage engine is a specific resolution of the same write/read tension. Choosing an engine without understanding which resolution it applies means optimizing for the wrong side of the trade-off.
- **Result:** The bash store example makes the selection criteria concrete and derivable: identify which side of the trade-off (write or read performance) the workload values more, then select the engine that resolves the trade-off in that direction.

### Case 2: LSM Compaction Under IoT Write Load

- **Question:** An IoT platform ingesting 100,000 sensor readings per second considers RocksDB (LSM), PostgreSQL (B-tree), and Parquet+DuckDB (columnar). Which wins and what are the operational risks?
- **Use of Methodology:** The framework prescribes: classify workload (write-heavy, low read frequency, time-range queries for diagnostics). B-tree (PostgreSQL): random I/O write amplification will bottleneck at 100k/sec; read performance is good but unnecessary. LSM (RocksDB): sequential writes, write throughput suitable; compaction must be tuned or it will cause write stalls under sustained load. Columnar (Parquet+DuckDB): near-zero individual write capability; requires batch ingestion. Hybrid: LSM for hot write path, periodic batch export to columnar for analytical time-range queries.
- **Conclusion:** LSM wins for the write path; columnar wins for the analytical query path; the correct architecture is a hybrid that keeps these two workloads on their appropriate engine archetypes.
- **Result:** The framework prevents the common mistake of using a single general-purpose engine (PostgreSQL) for a workload that splits across both the write-optimization and analytical-optimization axes. Compaction interference is specifically called out as an operational risk that must be planned for, not discovered.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A logging pipeline writes 50,000 log events per second to a PostgreSQL table. Write latency begins to degrade and WAL I/O is saturating disk. The team is evaluating ClickHouse or Kafka+RocksDB.
2. An application using Cassandra (LSM) for a user profile store with mostly reads and rare writes is experiencing slow reads due to many SSTables requiring multi-file lookups. The team suspects "the wrong database."
3. A data warehouse team needs to run GROUP BY aggregations over 3 years of transaction history. PostgreSQL row-store query times are minutes; they are evaluating a columnar format.
4. An engineer proposes using RocksDB for a system where the access pattern is random-read-heavy (high read/write ratio). The write throughput is modest.
5. A team observes periodic write stalls in a RocksDB-backed system at regular intervals. Monitoring shows compaction I/O spikes correlating with the stalls.

### Language Signals

- "We're getting write stalls under load"
- "Reads are slow because of all the SSTables"
- "We need to query aggregates across years of data"
- "Should we use RocksDB or PostgreSQL for this?"
- "Compaction is killing our latency"

### Distinguishing from Adjacent Skills

- Difference from `replication-topology-selection`: storage engine selection is about the single-node data structure that stores and retrieves data; replication topology is about how copies of that data are distributed across nodes. These are orthogonal decisions.
- Difference from `schema-evolution-compatibility-planning`: schema evolution is about how data format changes are managed during rolling upgrades; storage engine selection is about which physical storage structure matches the workload's I/O characteristics.

______________________________________________________________________

## E — Execution Steps

1. **Classify the workload as operational or analytical**

   - Operational: individual row reads/writes, user-facing latency requirements, OLTP access pattern. Analytical: bulk column scans, aggregations, GROUP BY, low write frequency. Mixed: both operational writes and analytical queries on the same data.
   - Completion criteria: A written statement: "This workload is [operational / analytical / mixed] because [access pattern description]."
   - Stop condition: If analytical, go directly to columnar storage evaluation. Do not evaluate LSM or B-tree for analytical workloads.

2. **For operational workloads: quantify the write/read ratio**

   - Estimate writes per second vs. reads per second. Determine whether reads are point lookups (by key) or range scans. High write throughput (>10k/sec) with low read frequency → LSM. Mixed or read-heavy with random point lookups → B-tree.
   - Completion criteria: Write and read rates are measured or estimated with units (ops/sec). The dominant constraint (write throughput or read latency) is identified.

3. **For LSM selection: plan compaction explicitly**

   - Identify the compaction strategy for the chosen LSM engine (LevelDB, Tiered, FIFO). Estimate the write rate vs. compaction throughput. Set monitoring for SSTable count, compaction queue depth, and write stall events. Tune compaction thread count and I/O priority before production load.
   - Completion criteria: Compaction monitoring is in place; write stall thresholds are defined; compaction throughput has been load-tested at peak write rate.

4. **For mixed workloads: design a hybrid architecture**

   - Use LSM or B-tree for the hot operational write path. Use a separate batch export (CDC, scheduled export) to columnar storage for analytical queries. Define the staleness SLA for analytical queries (acceptable lag in the export pipeline).
   - Completion criteria: The two storage tiers have separate data paths, separate SLAs, and separate operational ownership. The analytical tier is explicitly derived data from the operational tier.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The performance problem is a missing index or a bad query plan — fix the index first before attributing the problem to the engine choice.
- The workload is small enough that a single-node B-tree database handles it with acceptable performance — premature engine optimization before the workload warrants it adds complexity without benefit.
- The selection is primarily driven by cloud vendor lock-in, team familiarity, or managed service constraints rather than workload characteristics — acknowledge those constraints explicitly but don't rationalize them as workload-driven decisions.

### Failure Patterns from the Book

- **ce06 — LSM Compaction Interference**: Under sustained high write throughput, compaction threads cannot keep pace. Unmerged segment count grows. Read latency increases. Eventually, write stalls occur as the engine throttles writes to allow compaction to catch up. This is not a configuration problem that disappears with tuning — it is an inherent characteristic of LSM under write pressure that must be sized for.
- **ce05 — ORM N+1 Query Problem**: While not a storage engine selection failure, the N+1 query pattern illustrates the same principle: the storage access pattern (N sequential round-trips instead of one join) overwhelms any storage engine, regardless of its write/read optimization. Engine selection is a necessary but not sufficient condition for performance.

### Author's Blind Spots / Era Limitations

- The book treats the operational/analytical split as relatively clean. In practice, modern streaming systems (Flink SQL, ksqlDB, materialized view engines) blur this boundary — data that arrives at streaming rates must also be queried analytically with low latency. The LSM/B-tree/columnar framework does not fully capture hybrid HTAP (Hybrid Transactional/Analytical Processing) workloads.
- The rapid adoption of object-storage-native engines (SlateDB, Delta Lake, Iceberg) post-dates the framework's primary examples. These systems decouple the storage medium (object store) from the engine archetype (LSM-on-S3), introducing latency and cost trade-offs the framework does not address.

### Easily Confused Adjacent Methodology

- **Write throughput vs. compaction throughput**: Engineers who choose LSM for write-heavy workloads sometimes assume write performance is "solved." It is solved at the moment of ingestion — but compaction is a delayed write amplification cost that becomes a throughput ceiling. The write performance of an LSM engine under sustained load is bounded by its compaction throughput, not its ingestion rate.

______________________________________________________________________

## Related Skills

- **composes_with**: sharding-strategy-selection — once the engine archetype is chosen (LSM for writes, columnar for analytics), the sharding strategy is applied on top to distribute that engine's data across nodes.
- **composes_with**: system-of-record-vs-derived-data — the storage engine decision often splits along the SoR/derived boundary: the operational write path (system of record) uses LSM or B-tree while derived analytical representations use columnar storage.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini — Chapter 4: Storage and Retrieval
