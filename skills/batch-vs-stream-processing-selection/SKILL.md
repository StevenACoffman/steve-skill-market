---
name: batch-vs-stream-processing-selection
description: |
  Invoke this skill when an engineering team must choose between batch processing (periodic jobs over bounded, immutable input) and stream processing (continuous processing of unbounded, incrementally arriving input) for a data pipeline. Specific triggers: a data pipeline needs to produce derived outputs (search indexes, recommendations, ML features, analytics); a bug in a production pipeline corrupted derived data and you are evaluating whether you can recover; the team is debating "how often should we run this job?"; a pipeline produces stale results and the question is whether to move to real-time processing.

  Do NOT invoke when: the question is about online request-response latency (OLTP performance); the issue is with a single-node computation's correctness; you are deciding the primary storage architecture (see `system-of-record-vs-derived-data`).
tags: [batch-processing, stream-processing, immutable-inputs, derived-data, human-fault-tolerance, kafka]
allowed-tools: Bash, Read, Edit
---

# Batch Vs. Stream Processing Selection

## Current State

Pub/Sub topics and subscriptions (streaming entry points):
!`grep -rn 'pubsub\|PubSub\|topic\|subscription' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Batch/cron job patterns:
!`grep -rn 'cron\|batch\|job\|scheduler' --include='*.go' . 2>/dev/null | grep -iv 'rosterjob\|RosterJob' | grep -v '_test.go\|vendor' | head -5`

Event log / Kafka / stream processing references:
!`grep -rn 'kafka\|stream\|eventlog\|event_log' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

## R — Original Text (Reading)

> A batch processing job takes input data (which is read-only) and produces output data (which is generated from scratch every time the job runs). It typically does not mutate data in the way a read/write transaction would. The output is therefore derived from the input. If you don't like the output, you can delete it, adjust the job's logic, and run the job again.
>
> By treating inputs as immutable and avoiding side effects, batch jobs achieve good performance as well as other benefits: If you introduce a bug into the code and the output is wrong or corrupted, you can simply roll back to a previous version of the code and rerun the job, and the output will be correct again. The idea of being able to recover from buggy code has been called human fault tolerance.
>
> — Kleppmann & Riccomini, Chapter 11: Batch Processing

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Batch and stream processing are not categorically different systems — they are two points on a latency/complexity continuum for producing derived data from an event log. Choosing between them requires understanding the latency tolerance of the application *and* the recoverability requirements of the pipeline.

Batch processing operates on bounded, immutable input. The job runs to completion, produces derived output, then terminates. Because the input is never modified, if a bug produces incorrect output, you delete the output, fix the code, and rerun. This is human fault tolerance: the ability to recover from programmer error, not just hardware failure. Traditional online OLTP databases do not have this property — a bug that writes incorrect data to a mutable database must be corrected record-by-record.

Stream processing removes the "bounded input" constraint. Events arrive continuously; the processor handles them as they come. Latency can be reduced to seconds or milliseconds rather than hours or days. The same immutability principle applies: when the event log is the source of truth and derived outputs are produced by transforming it, a bug can be corrected by replaying the stream from a checkpoint. Stream processing achieves low-latency at the cost of additional complexity: windowing, out-of-order events (event time vs. processing time), state management, and exactly-once semantics.

The kappa architecture treats batch processing as a special case of stream processing — running the stream processor over a bounded historical log produces the same result as a batch job, unifying both under one system.

The primary selection criteria in order of priority:

1. **Recoverability requirement**: If the pipeline must be correctable after a bug (human fault tolerance), the input must be immutable and replayable. Both batch and log-based stream processing satisfy this; ad-hoc mutation of source data does not.
2. **Latency requirement**: How stale can the derived output be before it affects user outcomes? Hours/days → batch is simpler. Minutes/seconds → stream processing is required. Real-time is often speculative; measure whether users actually need it.
3. **Input boundedness**: Is the input naturally finite (a monthly report, a one-time migration) or unbounded (continuous user events, sensor readings)? Bounded input fits batch naturally. Unbounded input requires either artificial time-windowing in batch or continuous stream processing.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Apache Kafka — Log-Based Broker Enables Replayable Stream Processing

- **Question:** Traditional message queues (RabbitMQ-style) delete messages on acknowledgment. If a consumer has a bug, the messages it processed incorrectly are gone. How does Kafka solve this?
- **Use of Methodology:** Kafka treats the message log as primary storage (not a buffer to be cleared). Messages are retained on disk for a configurable retention period (the book mentions at least 22 hours). Each consumer tracks its own offset independently. This means: a consumer with a bug can reset its offset to a checkpoint, fix the code, and reprocess all messages from that point. The immutable-input principle from batch processing is applied to the streaming case.
- **Conclusion:** Log-based message brokers make stream processing recoverable by preserving the immutability of the input. The consumer's output (derived data) can be discarded and regenerated by replaying from the log. Slow consumers do not block fast producers.
- **Result:** Multiple independent consumer groups can read the same topic at different offsets, enabling retroactive processing and independent failure domains per consumer. This architectural property — that adding a new consumer can process the entire history — is not available in traditional message queues.

### Case 2: Recommendation Pipeline Bug — Human Fault Tolerance in Practice

- **Question:** A team discovers a bug in their recommendation model pipeline that has silently produced incorrect recommendations for 3 months. They need to regenerate all recommendations. Can they? What architecture determines whether this is possible or expensive?
- **Use of Methodology:** The framework asks: is the source event log immutable and retained? If yes (batch or log-based stream architecture): (1) the input log is unchanged; (2) the buggy derived output (recommendation scores) can be deleted; (3) fix the code, rerun the job against the unchanged input — all 3 months regenerated correctly. If no (pipeline mutated source data, or no replay capability): 3 months of input events may be gone; reconstruction requires manual forensics or accepting data loss.
- **Conclusion:** The ability to recover from the bug depends entirely on whether the architecture preserved immutable inputs. The choice of architecture at design time determines whether a production bug is "run the job again" or "3 months of manual data reconstruction."
- **Result:** Teams that adopt the immutable-input / derived-output pattern consistently cite this recovery scenario as its primary operational benefit. The extra storage cost of retaining the event log is the cost of human fault tolerance.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A recommendation system produces feature vectors nightly using a batch job. Product management is asking whether features can be fresher than 24 hours, and you must evaluate whether the benefit justifies migrating to stream processing.
2. A data pipeline has been writing incorrect analytics aggregates for 6 weeks due to a bug. The question is whether the correct aggregates can be regenerated from source data.
3. A stream processor is restarted after a code deployment. Its rate metrics immediately spike to 10x normal, triggering alerts. Engineers need to determine whether this is a real traffic problem or an artifact.
4. Two downstream systems read derived data from a pipeline — one requires near-real-time (fraud detection) and one is fine with daily (billing reports). The question is whether one pipeline can serve both.
5. A team is building a new event-driven system and must choose between writing events to a traditional message queue that deletes on acknowledgment vs. a log-based broker that retains them.

### Language Signals

- "Can we re-run the pipeline after fixing the bug?"
- "The recommendations are a day old — do users actually care?"
- "We need to process this in real time"
- "The batch job takes 6 hours and we need results sooner"
- "What happens if the consumer crashes mid-batch?"
- "We can't replay because we don't have the original events anymore"
- "Event time vs. processing time — our metrics are wrong after restarts"

### Distinguishing from Adjacent Skills

- Difference from `system-of-record-vs-derived-data`: The system-of-record skill determines which system is the authoritative source of truth and which are derived views. Batch vs. stream selection determines *how* those derived views are computed (periodically in bulk vs. continuously). The two skills compose: once you know what is derived, you use this skill to decide how to compute it.
- Difference from `storage-engine-workload-selection`: Storage engine selection is about the on-disk storage mechanism (LSM, B-tree, columnar). Batch vs. stream is about the computation and data-flow pattern. A batch job might use columnar storage; a stream processor might use an LSM-backed state store. They operate at different layers.

______________________________________________________________________

## E — Execution Steps

1. **Determine whether the input data is immutable and replayable**

   - Ask: is there an append-only log (Kafka, Kinesis, S3 event files, database CDC stream) that contains the complete history of input events? Can the pipeline be rerun against that log from a specific point in time?
   - Completion criteria: A definitive answer to "can we replay from 30 days ago?" If no, document the gap (missing inputs) as a human-fault-tolerance risk before proceeding.
   - Stop condition: If the input is not replayable and human fault tolerance is required, the architecture must first be fixed (add a log-based input layer) before choosing batch vs. stream.

2. **Quantify the latency requirement**

   - Determine the maximum acceptable age of derived output when a user interacts with it. Express in concrete terms: "fraud scores must be updated within 30 seconds of transaction," "product recommendations can be up to 24 hours stale," "billing aggregates need to be correct to the minute by end-of-month."
   - Completion criteria: Latency SLA is written down with user impact described. "Real-time" is rejected as a requirement unless accompanied by a specific maximum latency in seconds.

3. **Select the processing model based on latency requirement**

   - If latency tolerance >= hours: batch processing (Spark, Flink batch mode, SQL warehouse). Simpler operationally, naturally handles bounded jobs.
   - If latency tolerance = minutes: micro-batch (Spark Streaming with short batch intervals, or Flink with checkpointing). Intermediate complexity.
   - If latency tolerance < 1 minute: continuous stream processing (Flink, Kafka Streams). Requires windowing, watermarks, exactly-once state management.
   - Completion criteria: A specific framework and latency configuration is chosen.

4. **Design for event time, not processing time**

   - If stream processing is chosen: ensure all metrics, windowing, and anomaly detection use the event timestamp embedded in the event, not the wall-clock time when the processor handles the event. Backlog replay will otherwise produce false spikes in processing-time metrics.
   - Completion criteria: No pipeline metric uses processing time as a proxy for event rate.

5. **Verify exactly-once or at-least-once semantics requirements**

   - Determine whether duplicated processing is acceptable. If the output operation is idempotent (e.g., overwriting a derived value), at-least-once with idempotent writes is sufficient and simpler. If it is not idempotent (e.g., incrementing a counter, charging a payment), exactly-once semantics must be implemented via transactional commits or idempotency keys.
   - Completion criteria: The output operation is classified as idempotent or non-idempotent. The processing semantic (at-least-once, exactly-once) is documented.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The question is about online request-response performance (reducing API latency, improving database query throughput). Batch and stream processing produce derived data offline; they do not directly reduce synchronous request latency.
- The derived data is produced by a single-node computation with no fan-out or distribution. The batch vs. stream selection is relevant for pipeline-scale data processing, not for simple server-side queries.
- The team has not yet established what the system of record is. Batch and stream processing operate on derived data; trying to select a computation model before designating the authoritative source of truth inverts the design.

### Failure Patterns from the Book

- **ce25 — Processing Time vs. Event Time Confusion**: A stream processor is restarted after an outage. On recovery, it processes a backlog of accumulated events from the past hour. Metrics based on processing time show a spike. Autoscaling triggers unnecessarily. Alerts fire. The actual event-time rate was steady throughout. Processing-time metrics are meaningless for backlog replay scenarios.
- **ce26 — Dual Writes Race Condition**: Application code writes to a primary database and a search index as two separate operations. Two concurrent updates to the same record arrive in different orders at each system. No error occurs. The systems permanently diverge. This failure is caused by the absence of a single source of truth + derived data pattern — both systems are treated as equal authorities rather than one being a derived view of the other.

### Author's Blind Spots / Era Limitations

- The book frames batch vs. stream as a latency trade-off. The operational cost dimension is underweighted: stream processing (stateful Flink jobs, exactly-once Kafka Streams) has dramatically higher operational complexity than batch jobs. Many teams underestimate this and migrate to stream processing for latency benefits they do not actually need.
- The kappa architecture (treating batch as a special case of streaming) is presented as the synthesis. The book underweights the schema evolution challenges in event stores over long time horizons — event schemas drift, old event formats must remain decodable for replay, and migration is much harder in an immutable event log than in a mutable database.
- MapReduce is discussed as the batch processing paradigm, but is acknowledged as largely obsolete. Modern alternatives (Spark, Flink, DuckDB, cloud warehouse query engines) have different trade-offs not deeply explored.

### Easily Confused Adjacent Methodology

- **Lambda architecture** (maintaining both a batch and a stream layer simultaneously) is an alternative to the kappa architecture. The book argues lambda architecture should be avoided because it doubles the code and operational surface area. Lambda is sometimes chosen when the team lacks confidence in stream processing's correctness, but it creates consistency problems between the two layers.
- **ETL pipelines** (Extract-Transform-Load into a data warehouse) are a specific instance of batch processing but are often treated as a distinct category. The immutable-input / derived-output principle applies equally to ETL. The failure pattern of ETL pipelines that mutate source data is the same as any other pipeline that loses the replay property.

______________________________________________________________________

## Related Skills

- **depends_on**: system-of-record-vs-derived-data — batch and stream processing produce derived data; which system is authoritative must be established before selecting how to compute derivations from it.
- **composes_with**: end-to-end-idempotence-request-ids — stream processing with at-least-once delivery requires idempotent consumers; the idempotency key mechanism is the standard implementation of that requirement.
- **composes_with**: schema-evolution-compatibility-planning — event log replay (the human-fault-tolerance recovery mechanism) requires that historical events remain decodable by current code; backward schema compatibility is a prerequisite for replay-based recovery.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini — Chapter 11: Batch Processing
