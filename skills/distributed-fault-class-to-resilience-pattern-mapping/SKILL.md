---
name: distributed-fault-class-to-resilience-pattern-mapping
allowed-tools: Bash, Read, Edit
id: distributed-fault-class-to-resilience-pattern-mapping
description: Apply before selecting any resilience pattern for inter-service calls or distributed lock implementations. Classify the fault class first — network availability, process pause, or clock skew — then select the correct mitigation. Circuit breakers are sufficient only for network-availability faults; they actively mask correctness failures in the process-pause and clock-skew classes.
type: merged-skill
source_skills:
  - slug: grpc-microservices-in-go/grpc-resilience-pattern-layering
    book: gRPC Microservices in Go
    author: Hüseyin Babal
  - slug: kleppmann/distributed-fault-taxonomy
    book: Designing Data-Intensive Applications, 2nd Edition
    author: Martin Kleppmann & Chris Riccomini
related_skills:
  - slug: grpc-microservices-in-go/grpc-resilience-pattern-layering
    relation: supersedes
    note: Merged into distributed-fault-class-to-resilience-pattern-mapping; circuit breaker scope bounded to network-availability fault class
  - slug: kleppmann/distributed-fault-taxonomy
    relation: supersedes
    note: Merged into distributed-fault-class-to-resilience-pattern-mapping; mitigation stack for network-availability class supplied by Babal
tags: []
---

# Distributed Fault Class to Resilience Pattern Mapping

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Resilience patterns in use:
!`grep -rn 'retry\|backoff\|CircuitBreaker\|RetryPolicy' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -10`

### R — Reading

> "Transient faults occur when a momentary loss of service functionality self-corrects. The retry pattern in gRPC enables us to retry a failed call automatically and thus is perfect for transient faults... if we don't know how long the problem will last, we may end up putting a high load on dependent services with infinite retries... To solve this problem, we use a circuit breaker to open a circuit once we reach the failure limit."
>
> "Transient faults occur when a momentary loss of service functionality self-corrects. The retry pattern in gRPC enables us to retry a failed call automatically and thus is perfect for transient faults... if we don't know how long the problem will last, we may end up putting a high load on dependent services with infinite retries... To solve this problem, we use a circuit breaker to open a circuit once we reach the failure limit."

## Hüseyin Babal, gRPC Microservices in Go, Chapter 6: Resilience Patterns

> "A node in a distributed system must assume that its execution can be paused for a significant length of time at any point, even in the middle of a function. During the pause, the rest of the world keeps moving and may even declare the paused node dead because it's not responding. Eventually, the paused node may continue running, without even noticing that it was asleep until it checks its clock sometime later."

## Martin Kleppmann & Chris Riccomini, Designing Data-Intensive Applications 2nd Ed., Chapter 9

**Convergence note:** Both sources independently establish that the correct mitigation depends on the failure class and its duration — Babal's contribution is the concrete mitigation stack for the network-availability class (timeout → retry → circuit breaker), and Kleppmann's contribution is the broader taxonomy showing that process-pause and clock-skew faults require categorically different mitigations (fencing tokens, logical clocks) that circuit breakers cannot provide.

## R — Reading

> "Transient faults occur when a momentary loss of service functionality self-corrects. The retry pattern in gRPC enables us to retry a failed call automatically and thus is perfect for transient faults... if we don't know how long the problem will last, we may end up putting a high load on dependent services with infinite retries... To solve this problem, we use a circuit breaker to open a circuit once we reach the failure limit."

## Hüseyin Babal, gRPC Microservices in Go, Chapter 6: Resilience Patterns

> "A node in a distributed system must assume that its execution can be paused for a significant length of time at any point, even in the middle of a function. During the pause, the rest of the world keeps moving and may even declare the paused node dead because it's not responding. Eventually, the paused node may continue running, without even noticing that it was asleep until it checks its clock sometime later."

## Martin Kleppmann & Chris Riccomini, Designing Data-Intensive Applications 2nd Ed., Chapter 9

**Convergence note:** Both sources independently establish that the correct mitigation depends on the failure class and its duration — Babal's contribution is the concrete mitigation stack for the network-availability class (timeout → retry → circuit breaker), and Kleppmann's contribution is the broader taxonomy showing that process-pause and clock-skew faults require categorically different mitigations (fencing tokens, logical clocks) that circuit breakers cannot provide.

## I — Interpretation

Distributed systems expose three distinct fault classes. Each requires a different mitigation. Applying the mitigation for one class to a different class either fails silently or, worse, masks the underlying failure while the system produces incorrect results.

**Fault class 1 — Network availability (transient and persistent):** A remote service is unreachable or slow. The failure is at the call layer: the request does not complete successfully within a time budget. Two sub-cases:

- *Transient*: The service is restarting, momentarily throttled, or experiencing a brief network hiccup. It will recover in seconds. Mitigation: retry with exponential backoff. Retry is counterproductive against persistent failure — it adds load to an already-degraded system.
- *Persistent*: The service is down for minutes. Retrying a persistent failure amplifies the problem. Mitigation: circuit breaker. When the failure rate exceeds a threshold, the circuit opens; subsequent calls fail immediately without reaching the downstream service. After a probe interval, the circuit moves to half-open and allows a small number of test calls through.

The correct layering is: timeout enforced by context → retry with backoff (transient sub-case) → circuit breaker wrapping the retry (persistent sub-case). The circuit breaker must be outermost: an open circuit suppresses the retry loop entirely. The circuit breaker must be a single shared instance per downstream connection — per-call instances split the failure counter across independent states, and the circuit never opens even when 80% of calls are failing.

**Fault class 2 — Process pause:** A running process is preempted — GC stop-the-world, VM live migration, OS context switch, container scheduler suspension — and resumes seconds or minutes later. From the process's perspective, no time passed. From the world's perspective, the lease the process held has expired, another node has taken over, and the resumed process is a zombie acting on stale authority. The critical property: the process does not know it was paused. A `time.Since(leaseAcquiredAt) < leaseTTL` check that passed before the pause will still pass after the pause, but its result is now wrong.

Mitigation: fencing tokens at the resource layer. The lock service issues a monotonically increasing integer token with each lock grant. The protected resource (storage, database, job queue) accepts the fencing token with each write and rejects any write whose token is older than the most recently seen token. A zombie process holding a stale token is rejected at the resource layer; no application-level awareness of the pause is required.

Circuit breakers are orthogonal to this failure class. A circuit breaker on the gRPC call to a lock-using service prevents retrying a call when the service is unavailable — but once a lock is acquired, the circuit breaker plays no role. The zombie process already holds the lock; the circuit breaker has no mechanism to invalidate a held lock when the lock-holder's process pauses.

**Fault class 3 — Clock skew:** Each machine has its own clock. NTP accuracy is tens of milliseconds over the internet. A "later" timestamp on one machine may correspond to an earlier real event on a machine with a faster clock. Using wall-clock time for distributed ordering or lock-validity checks introduces silent correctness failures:

- Last-write-wins conflict resolution with wall-clock timestamps silently discards causally later writes when the writing machine has a slow clock.
- A process that checks `leaseExpiresAt.After(time.Now())` before a write may be wrong by tens of milliseconds — enough for the lease to have expired on the lock service while the local clock disagrees.

Mitigation: replace wall-clock ordering with logical ordering. Options: Lamport timestamps or vector clocks for causal ordering only; hybrid logical clocks when physical time correlation is also needed; fencing tokens for lease/lock validity (which avoid the clock comparison entirely by using monotonically increasing counters instead of timestamps).

**Two-axis decision procedure — classify first, mitigate second:**

| Fault class                       | Symptom                                   | Wrong mitigation                            | Correct mitigation               |
| --------------------------------- | ----------------------------------------- | ------------------------------------------- | -------------------------------- |
| Network availability — transient  | Request fails, recovers quickly           | No retry                                    | Retry with backoff               |
| Network availability — persistent | Request fails continuously                | Retry without circuit breaker (retry storm) | Circuit breaker wrapping retry   |
| Process pause                     | Zombie holds stale lock; duplicate write  | Circuit breaker at call layer               | Fencing tokens at resource layer |
| Clock skew                        | Causally later write discarded; LWW wrong | Longer NTP sync interval                    | Logical clocks; fencing tokens   |

**The masking hazard:** A system with gRPC circuit breakers protecting a service that uses Redis SETNX distributed locks has a latent correctness bug that the circuit breaker actively masks. Open circuit = calls to the lock service stop. But if the lock-holder's JVM pauses for longer than the lock TTL before the circuit opens, the zombie holds a stale lock during the window when the circuit is still closed. The circuit breaker sees no failure signal from the zombie's continued operation — the zombie is not making new calls, it is acting on a lock it already holds. The circuit breaker is blind to this failure class.

## A1 — Past Application

**Order service (Babal, Ch. 6):** A gRPC microservice chain (Order → Payment → Shipping) experiences a Shipping service outage. The retry layer handles a brief 500ms restart. When Shipping fails continuously, the circuit breaker opens after the failure rate threshold is crossed, preventing the retry loop from flooding the recovering Shipping service. The Order service fails fast with an open-circuit error rather than accumulating goroutines on timeout-waiting calls.

Domain: gRPC inter-service availability fault. Fault class: network availability. What it shows: retry for transient, circuit breaker for persistent, interceptor ordering critical (circuit breaker outermost).

**HBase process-pause bug (Kleppmann, Ch. 9):** A distributed system uses a lease-based lock to ensure only one process writes to a file at a time. Post-mortem reveals concurrent writes corrupting the file despite correct TTL values. Diagnosis: the lock-holding JVM process checked `lease.isValid()`, then paused for longer than the lease TTL due to garbage collection. The lock expired; a second process acquired the lock and began writing. The first process resumed, still believed the lease valid (the check happened before the pause), and wrote concurrently. The correct fix: fencing tokens at the storage layer — monotonically increasing token issued at lock grant time; storage rejects writes with tokens older than the most recently seen. TTL-based validity checks cannot protect against this failure class.

Domain: distributed lock correctness. Fault class: process pause. What it shows: circuit breakers at the call layer are irrelevant to this failure mode; correctness enforcement must be at the resource layer.

**Google Spanner TrueTime (Kleppmann, Ch. 9):** Distributed transactions across datacenters require globally consistent ordering. Wall-clock timestamps are insufficient because NTP accuracy across datacenters is tens of milliseconds. Spanner exposes clock uncertainty as a confidence interval `[earliest, latest]` via the TrueTime API (backed by GPS receivers and atomic clocks). Transactions commit only after waiting out the uncertainty window, guaranteeing that any transaction assigned timestamp T is later than any transaction with timestamp T' < T_earliest. The circuit breaker pattern is not part of this solution — it is a different fault class.

Domain: globally consistent distributed transactions. Fault class: clock skew. What it shows: wall-clock ordering is insufficient; hardware-backed uncertainty acknowledgment is the correct design.

All three cases share the meta-pattern: the fault class determines the correct mitigation. Applying Babal's layering to the HBase scenario produces a system with retry and circuit breakers on the lock acquisition call — but the process-pause failure occurs after lock acquisition, at which point the circuit breaker plays no role.

## A2 — Future Trigger

Instead of reaching for retry and circuit breakers as the default resilience pattern (which is correct only for the network-availability fault class), apply this skill to classify the fault first:

- **"Our retry + circuit breaker setup isn't preventing duplicate job processing."** Classify: duplicate job processing despite correct retry/circuit breaker configuration is the process-pause signature — a zombie worker holding a stale lock. Circuit breakers cannot fix this. Apply fencing tokens at the job queue or storage layer.
- **"The timeout was set correctly but the node thought it was still the leader."** Classify: process-pause fault class. The node resumed after a pause; its local lease check passed but the lease had expired in wall-clock time. Circuit breakers at the call layer are irrelevant. Fencing tokens required.
- **"LWW should work because our clocks are synced with NTP."** Classify: clock-skew fault class. NTP accuracy is tens of milliseconds; LWW with wall-clock timestamps silently discards causally later writes from machines with slow clocks. Replace wall-clock ordering with logical clocks or fencing tokens.
- **"A downstream service went down for 10 minutes and clients flooded it when it recovered."** Classify: network-availability, persistent fault. Apply circuit breaker wrapping retry; the circuit breaker prevents the retry loop from flooding the recovering service.
- **"We applied circuit breaker logic at each gRPC call site and the circuit never opens even though 80% of calls are failing."** Per-call circuit breaker instances: failure counter is split across independent instances; circuit never opens. Fix: one shared circuit breaker instance per downstream connection.
- **"We use Redis SETNX with a 30-second TTL. A worker checks the TTL every 10 seconds so we have 20 seconds of buffer."** The buffer argument is invalid: a process-pause of longer than the buffer duration can occur at any point, including between the TTL check and the protected operation. Fencing tokens are required regardless of buffer size.

## E — Execution

**Step 1: Classify the fault class from the observed or anticipated failure.**

Ask: what is the failure mechanism?

- A remote service is unavailable or slow → network availability fault class → go to Step 2.
- A process resumed after a pause (GC, VM migration, OS preemption) and acted on state it believed was current → process-pause fault class → go to Step 3.
- A time-based ordering decision was wrong, or LWW discarded a causally later write → clock-skew fault class → go to Step 4.
- A node sent incorrect or malicious data → Byzantine fault class → assess whether the threat model requires Byzantine fault tolerance; for typical datacenters, it does not.

**Step 2: Network availability fault — apply the three-layer stack.**

2a. Set `context.WithTimeout` at the service entry point for every operation that calls downstream; pass this context through all downstream calls. Do not re-declare per-hop timeouts — propagate the remaining budget.

2b. Configure retry for transient status codes only (`UNAVAILABLE`, `RESOURCE_EXHAUSTED`). Use `BackoffExponential` with a maximum attempt count (e.g., 3). Do not retry on persistent errors.

2c. Implement the circuit breaker as a single `grpc.UnaryClientInterceptor` per downstream connection. Register with `grpc.WithUnaryInterceptor` — not per-call. Configure `ReadyToTrip` at a failure-rate threshold (e.g., 60%). Register `OnStateChange` for operational visibility. If the circuit is open, the retry loop does not execute.

2d. Order in the call stack: circuit breaker wraps retry wraps the call. The circuit breaker is outermost.

**Step 3: Process-pause fault — apply fencing tokens at the resource layer.**

3a. The lock service must issue a monotonically increasing integer fencing token with each lock grant.

3b. The lock-holding process must include its fencing token in every protected operation.

3c. The protected resource (storage, API endpoint, job queue) must accept the token with each operation and reject any operation whose token is older than the most recently seen token.

3d. Verify: there is no code path where a process writes to the protected resource without presenting its fencing token. Check the TTL-based validity check — if any code path does `if lease.isValid() { write() }` without a fencing token, it is vulnerable to process-pause corruption regardless of the TTL value.

**Step 4: Clock-skew fault — replace wall-clock ordering with logical ordering.**

4a. Identify every distributed ordering decision that uses wall-clock time: LWW conflict resolution, lease validity checks across machines, transaction ordering.

4b. For causal ordering: replace wall-clock timestamps with Lamport timestamps or vector clocks. For lease validity: replace timestamp comparison with fencing tokens (Step 3c). For globally consistent transactions requiring physical time: evaluate TrueTime-style bounded-uncertainty approaches (GPS-backed hardware + commit-wait).

4c. Verify: no distributed ordering decision relies on `time.Now()` or equivalent as a causal ordering signal across different machines.

**Step 5: Verify fault class boundaries are correctly applied.**

For systems that use both call-layer resilience (network availability) and distributed locks (process-pause risk): confirm that the fencing token validation is present at the resource layer regardless of the circuit breaker configuration. An open circuit at the call layer does not invalidate a lock already held by a process that subsequently pauses.

## B — Boundary

**Failure modes from Babal (network-availability patterns):**

- Retry against persistent failure → retry storm floods recovering service. Fix: circuit breaker as persistent-failure mitigation.
- Per-call circuit breaker instances → failure counter split across instances; circuit never opens. Fix: one shared instance per downstream connection.
- Timeout context not propagated → goroutine accumulation, connection pool exhaustion. Fix: pass the incoming context, never create a fresh root context inside a handler.

**Failure modes from Kleppmann (process-pause and clock-skew):**

- LWW conflict resolution with wall-clock timestamps (ce20) → causally later writes silently discarded when a writing machine has a slow clock. NTP does not fix this.
- NTP false precision (ce21) → `gettimeofday()` returns microsecond-resolution timestamps accurate only to tens of milliseconds; decisions with false confidence.
- Split brain from timeout-based leader detection (ce10) → network partition is indistinguishable from node crash under timeout-based detection; two leaders accept divergent writes. Longer timeouts do not fix split brain; fencing tokens at the resource layer do.

**Synthesis-specific failure mode:** A system with correct gRPC circuit breakers protecting a service that uses distributed locks has a latent correctness gap: the circuit breaker is blind to the process-pause fault class. The sequence is: lock acquired → process pauses beyond TTL → lock expires → second process acquires lock → first process resumes, believes lock valid, writes concurrently. The circuit breaker saw no failure signal from this sequence — no new call was made during the pause, the circuit did not open, and no retry storm occurred. The circuit breaker provides correct network-availability mitigation and zero process-pause mitigation. Both mitigations are required in any system that combines gRPC inter-service calls with distributed lock-using operations.

**Scope of circuit breakers:** Circuit breakers are not a substitute for fencing tokens. They do not provide fencing semantics. They do not address the clock-skew fault class. They address the network-availability fault class. Apply them there and only there; for the other fault classes, apply the correct mitigation independently.

**Byzantine faults:** The taxonomy includes Byzantine faults (nodes that send incorrect data), but Byzantine fault tolerance (BFT consensus, cryptographic message signing) is warranted only when the threat model includes adversarial or untrustworthy nodes. For typical internal datacenter deployments, crash-stop and crash-recovery fault models are sufficient. Do not incur BFT overhead for fault classes that do not occur in the threat model.
