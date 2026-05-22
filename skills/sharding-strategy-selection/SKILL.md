---
allowed-tools: Bash, Read, Edit
name: sharding-strategy-selection
description: |
  Invoke this skill when a system's data volume or write throughput has grown beyond what a single node can handle and you must decide how to distribute data across multiple machines. Specific triggers: the team is choosing between key-range and hash-based sharding; a single shard is overloaded while others are idle (hot spot); a new compound key design is being evaluated; a time-series or sequential-ID partitioning scheme is under consideration.

  Do NOT invoke when: the problem is read throughput only (use read replicas instead of sharding); the data fits comfortably on one node with replication (single-node first); you are choosing a replication topology (see `replication-topology-selection`); the question is about within-machine PostgreSQL table partitioning rather than cross-machine distribution.

  Key signals: "all writes are going to one node," "we're hitting write throughput limits," "do we use the timestamp or the user ID as the partition key," "consistent hashing vs. range sharding," "celebrity/hot key problem," "we need range queries but also even write distribution."
source_book: Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini
source_chapter: 'Chapter 7: Sharding'
tags: [sharding, partitioning, hot-spot, distributed-systems, scalability, partition-key]
related_skills: [storage-engine-workload-selection, replication-topology-selection, consistency-model-selection]
---

# Sharding Strategy Selection

## Current State

Partition key or shard key patterns:
!`grep -rn 'shard\|Shard\|partition\|Partition\|bucket\|Bucket' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

District/school ID used as routing key:
!`grep -rn 'DistrictID\|districtID\|district_id\|SchoolID\|schoolID' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Hot-key or load distribution concerns:
!`grep -rn 'hotkey\|hot_key\|loadbalance\|hash.*key\|consistent.*hash' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Original Text (Reading)

> A downside of key-range sharding is that you can easily get a hot shard if there are a lot of writes to nearby keys. For example, if the key is a timestamp, then the shards correspond to ranges of time—for example, one shard per month. If you write data from the sensors to the database as the measurements happen, all the writes will end up going to the same shard (the one for this month), so that shard will be overloaded with writes while others sit idle.
>
> To avoid this problem in the sensor database, you need to use something other than the timestamp as the first element of the key. For example, you could prefix each timestamp with the sensor ID so that the key ordering is first by sensor ID and then by timestamp. Assuming you have many sensors active at the same time, the write load will end up more evenly spread across the shards. The downside is that when you want to fetch the values of multiple sensors within a time range, you now need to perform a separate range query for each sensor.
>
> — Kleppmann & Riccomini, Chapter 7: Sharding

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The core problem sharding solves is distributing data and write load across machines so no single node is a bottleneck. But the method of distribution determines which queries are fast and which are scatter-gather — you cannot optimize for everything simultaneously.

Key-range sharding assigns contiguous key ranges to shards, enabling efficient range queries (all records for sensor X between time T1 and T2 live in one or a few shards). The critical failure mode is monotonically increasing keys (timestamps, sequential IDs): all current writes concentrate on the single "latest" shard, leaving all others idle. This is a hot spot.

Hash-based sharding applies a hash function to the partition key and distributes records by hash value. This distributes writes evenly across all shards. The cost: all range queries become scatter-gather (you must query every shard and merge results), because records with adjacent keys land on different shards.

Compound keys offer a middle path: use one dimension (e.g., entity ID) as the hash prefix to distribute writes across shards, and a second dimension (e.g., timestamp) as the sort key within each shard. This enables per-entity range queries but makes cross-entity time-range queries scatter-gather. There is no free lunch: the choice encodes which query pattern is primary.

Additional risks: automatic shard splitting under high load triggers an expensive rewrite operation at precisely the moment when load is highest, potentially worsening the hot-shard problem transiently. Modulo-N hashing requires rehashing nearly all keys when a node is added; fixed numbers of shards or consistent hashing are the correct alternatives.

The guiding principle: identify the dominant query pattern first, then choose the partition key that makes that pattern cheap — explicitly accepting the cost to secondary patterns.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Sensor Timestamp Key — Range Sharding Hot-Spot Anti-Pattern

- **Question:** An IoT application stores sensor measurements with the timestamp as the partition key. All writes concentrate on the current-month shard. Why, and how is it fixed?
- **Use of Methodology:** The framework identifies this as a monotonically increasing key problem. Timestamp range sharding ensures all current writes go to the one shard covering "now." The fix requires prefixing the key with sensor ID so the key ordering is `(sensor_id, timestamp)`, distributing writes by device.
- **Conclusion:** Range queries per sensor remain efficient. Cross-sensor time-window queries now require a separate range scan per sensor (scatter-gather).
- **Result:** Write load distributes evenly across shards proportional to the number of active sensors. The access-pattern trade-off is explicit: single-sensor history is fast; all-sensor windows require fan-out.

### Case 2: Celebrity Hot Key — Special-Case Handling for Outlier Keys

- **Question:** A social network's write-time timeline materialization overwhelms the shard containing a celebrity account with millions of followers. Twitter reportedly dedicated 3% of servers to Justin Bieber's fan-out. How is this handled?
- **Use of Methodology:** The framework identifies this as a hot-key problem (not a hot-shard problem from key range). A single partition key has disproportionately high load. Uniform sharding strategies cannot solve per-key load concentration; per-key routing policy is required.
- **Conclusion:** Celebrity posts are handled separately: excluded from write-time materialization and merged at read time from a separate store, while non-celebrity posts use write-time fan-out.
- **Result:** Write load distributes normally for non-celebrity users. Celebrity read-time merge adds latency to reads but eliminates the write-time hot key. The monitoring signal that triggers special-case handling is observing which keys have load an order of magnitude above average.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A time-series database (IoT, metrics, financial ticks) is being designed and the team proposes using the event timestamp as the partition key because it makes time-range queries obvious.
2. A sharded database cluster shows one shard at 90% CPU while all others are at 5–10%, and the partition key is either a timestamp, an auto-increment ID, or a sequential counter.
3. The team must support two query patterns — (a) all events for user X in a date range, and (b) all events across all users in a 5-minute window — and must choose a partition key that serves both.
4. A cluster is being resized (nodes added or removed) and the existing sharding scheme uses `hash(key) % N`, causing a full data migration.
5. A social network or marketplace has a small set of "power users" or viral items that create per-key write throughput far above average.

### Language Signals

- "All writes are hitting one shard"
- "Our partition key is the created_at timestamp"
- "We need range scans but also want even distribution"
- "One node is hot while others are idle"
- "Do we use consistent hashing or range partitions?"
- "The rebalancing is taking forever and breaking things"
- "We have a celebrity problem"

### Distinguishing from Adjacent Skills

- Difference from `replication-topology-selection`: Sharding splits *different* data across nodes (solves write throughput and data volume); replication copies the *same* data to multiple nodes (solves read throughput and fault tolerance). Both are often used together but address orthogonal problems.
- Difference from `storage-engine-workload-selection`: Storage engine selection is about the on-disk data structure within a single shard (LSM vs B-tree vs columnar); sharding is about which machine holds which shard.
- Difference from `consistency-model-selection`: Consistency is about what reads return relative to recent writes; sharding is about data placement. A sharded system still needs a consistency strategy, but the two decisions are separable.

______________________________________________________________________

## E — Execution Steps

1. **Confirm that sharding is the right solution**

   - Completion criteria: Write throughput or data volume is confirmed to exceed single-node capacity after ruling out vertical scaling and read-replica scaling. If reads are the bottleneck, stop — use read replicas.
   - Stop condition: If a single node can handle the load with headroom, sharding adds complexity without benefit.

2. **Enumerate the dominant query patterns**

   - List all access patterns the application requires. For each, note: does it require range queries on the candidate key? Point lookups only? Cross-entity aggregations?
   - Completion criteria: At least 2–3 query patterns are listed with relative frequency estimates. The dominant pattern (highest frequency or most latency-sensitive) is identified.

3. **Evaluate key-range sharding against those query patterns**

   - Ask: Is the candidate partition key monotonically increasing (timestamp, auto-increment)? If yes, key-range sharding will create a hot spot on current data. Is range-scan capability on the key required? If yes, key-range preserves it.
   - Completion criteria: Hot-spot risk is assessed. If the key is monotonically increasing, key-range sharding is eliminated or a compound key prefix is designed.

4. **Evaluate hash sharding and compound keys**

   - Hash the entity dimension (user ID, sensor ID, account ID) to distribute writes evenly. If range queries on a secondary dimension (time, sequence) are required within an entity, design a compound key: `(hash(entity_id), secondary_sort_key)`.
   - Completion criteria: The compound key design is written out. The queries that become scatter-gather under this scheme are identified explicitly.

5. **Identify and handle hot keys separately**

   - Check whether any individual key (user, item, event) will have load orders of magnitude above average. If yes, design a per-key routing exception (separate store, read-time merge, key splitting with random suffix).
   - Completion criteria: The system has a monitoring hook to detect hot keys at runtime and a documented response (per-key routing, traffic shaping, or offline processing).

6. **Choose a rebalancing strategy**

   - Do not use `hash(key) % N`. Use fixed number of shards (many more shards than nodes) with shard-to-node mapping, or consistent hashing. Pre-split shards at setup if key distribution is predictable.
   - Completion criteria: The rebalancing algorithm is named and the expected data movement on node add/remove is quantified (should be O(K/N), not O(K)).

7. **Document the accepted trade-offs**

   - Write down which query patterns are efficient under the chosen scheme and which are scatter-gather. This is a design constraint, not a bug.
   - Completion criteria: The trade-off statement is reviewed by the team and included in the architecture decision record.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- Read throughput is the bottleneck, not write throughput or data volume. Read scaling via read replicas is sufficient and avoids sharding complexity.
- The dataset fits on a single machine. A single-shard database is dramatically simpler; sharding adds distributed transaction complexity and routing overhead.
- The system has cross-shard join requirements that would dominate query patterns — sharding with heavy cross-shard joins may be worse than a well-indexed single-node database.

### Failure Patterns from the Book

- **ce13 — Timestamp Key-Range Partition Hot Spot**: Using event timestamp as partition key routes all current writes to one shard (one shard per month / day). The other shards receive zero writes. Write throughput does not scale with cluster size.
- **ce14 — Hash-Modulo-N Rebalancing**: Using `hash(key) % N` means adding or removing one node causes nearly all keys to be reassigned. Cluster resizes become full data migrations.
- **ce15 — Automatic Rebalancing Cascades**: A node that is temporarily slow triggers automatic rebalancing, which adds I/O load to the already-struggling node. The node worsens, the cascade continues. Automatic rebalancing with short timeouts in an already-loaded cluster can cause cascading failure.

### Author's Blind Spots / Era Limitations

- The book focuses on data volume and write throughput as sharding triggers. Emerging serverless and multi-tenant SaaS architectures (cell-based, per-tenant sharding) create sharding needs driven by isolation rather than capacity, which the framework addresses only partially.
- The treatment of cross-shard transactions is brief — the book acknowledges they exist but defers to Ch. 8 without integrating the distributed transaction cost into the sharding decision procedure.
- The book was written before widespread use of object storage as primary storage (Iceberg, Delta Lake), where sharding semantics differ from traditional databases.

### Easily Confused Adjacent Methodology

- **Consistent hashing** is a rebalancing algorithm (minimizes data movement on topology change), not a sharding strategy. It answers "how do I assign keys to shards when the cluster changes size?" not "should I use range or hash sharding?"
- **Database table partitioning** (PostgreSQL PARTITION BY) is within-machine data management for query pruning and storage efficiency. It does not distribute data across machines. Engineers sometimes assume PostgreSQL partitioning solves their distributed scaling problem — it does not.

______________________________________________________________________

## Related Skills

- **depends_on**: storage-engine-workload-selection — the on-disk engine archetype (LSM, B-tree, columnar) must be chosen before designing the sharding strategy, since the engine's write/read characteristics determine which partition key properties (range vs. hash) produce acceptable performance per shard.
- **contrasts_with**: replication-topology-selection — sharding splits different data across nodes to scale write throughput and volume; replication copies the same data to multiple nodes for fault tolerance and read scaling; they are orthogonal decisions often applied together.
- **composes_with**: consistency-model-selection — a sharded system distributes the consistency problem across shards; which operations require cross-shard linearizability (uniqueness checks, global quotas) must be determined using the consistency model selection framework.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04
