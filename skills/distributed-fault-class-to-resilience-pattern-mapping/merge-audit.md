# Merge Audit — Distributed-Fault-Class-to-Resilience-Pattern-Mapping

## Source Skills

- A: `grpc-microservices-in-go/grpc-resilience-pattern-layering` (Hüseyin Babal, 2023)
- B: `kleppmann/distributed-fault-taxonomy` (Kleppmann & Riccomini, 2nd ed.)

## Phase 1 Verdict

ADVANCE — all four gates passed.

## RIA++ Section Audit

### R

Both quotes are verbatim from verified source locations:

- Babal quote: verified at gRPC_Microservices_in_Go_book.md line 2845 (verbatim for first sentence; continuation accurately paraphrased from adjacent source text).
- Kleppmann quote: verified verbatim at DDIA 2nd ed. lines 15220–15224.
- Convergence note: one sentence. States shared principle (correct mitigation depends on failure class) and each source's unique contribution (Babal = mitigation stack for network-availability class; Kleppmann = broader taxonomy revealing categorically different mitigations for other classes). ✓

### I

Single unified framework structured as a two-axis taxonomy table plus four fault-class descriptions. No "Babal says / Kleppmann says" framing. Key synthesis stated explicitly: circuit breakers are orthogonal to process-pause faults and actively mask the failure (masking hazard paragraph). The table makes the fault-class → mitigation mapping readable without having read either book. ✓

### A1

- Case A (Order service, Babal): gRPC service chain, network availability fault. Shows retry + circuit breaker layering.
- Case B (HBase bug, Kleppmann): distributed lock, process-pause fault. Shows fencing tokens as correct mitigation; circuit breaker as irrelevant.
- Case C (Spanner TrueTime, Kleppmann): globally consistent transactions, clock-skew fault. Shows hardware-backed uncertainty acknowledgment.
- Cross-case meta-pattern explicit: same diagnostic (classify fault class first, then select mitigation) applied to three different domains producing three different mitigation stacks.
- A developer who knows only Case A and applies it to Case B has a latent correctness bug — explicitly stated. ✓

### A2

Sharper than union of source A2s. Six specific triggers, each starting with a language signal followed by the fault class classification and the correct response. The cross-layer trigger — "retry + circuit breaker isn't preventing duplicate job processing" — combines both source domains and is absent from both source A2s. The Redis SETNX / 20-second buffer counterexample is absent from both source A2s. ✓

### E

5-step sequence. Step 1 is the classification gate (new — neither source has this as an explicit step). Steps 2–4 are the per-fault-class mitigations (Babal for network, Kleppmann for process-pause and clock-skew). Step 5 is the synthesis verification (confirming fencing tokens are present regardless of circuit breaker state). Not longer than Babal's E (6 steps) or Kleppmann's E (5 steps). Conditionals within each step are fault-class-specific. ✓

### B

Three subsections:

1. Source A failures (Babal): 3 failure modes — retry storm, split circuit breaker counter, context not propagated.
2. Source B failures (Kleppmann): 3 failure modes — LWW/clock-skew (ce20), NTP false precision (ce21), split brain (ce10).
3. Synthesis-specific failure mode: circuit breakers protecting lock-using services are blind to process-pause; the exact sequence described (lock acquired → pause → second lock → resume → concurrent write) is absent from both source B sections. ✓
   The circuit breaker ≠ fencing token distinction surfaced explicitly. ✓

## Divergence Encoding

- Babal: prescriptive, network-availability class, gRPC implementation-level.
- Kleppmann: taxonomic, covers fault classes that require categorically different mitigations.
- Divergence encoded as scope: Babal is correct and sufficient within the network-availability fault class; Kleppmann shows the boundary of that class.
- No conflict — they address adjacent, non-overlapping fault classes. The skill presents them as complementary layers in a decision tree.

## Quote Accuracy

| Quote                         | Source                                     | Verified                                                 |
| ----------------------------- | ------------------------------------------ | -------------------------------------------------------- |
| Babal resilience quote        | gRPC_Microservices_in_Go_book.md line 2845 | ✓ verbatim (first sentence); paraphrase for continuation |
| Kleppmann process-pause quote | DDIA 2nd ed. lines 15220–15224             | ✓ verbatim                                               |

## Gate Summary

| Gate                         | Verdict                                                                                                                                                                                  |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1 — Independent convergence | PASS: Babal §6.1.2 (retry) + §6.1.3 (circuit breaker); Kleppmann Ch9 process-pause (HBase) + Ch9 clock-skew (Spanner) — 4 independent contexts                                           |
| V2 — Novel question          | PASS: "My gRPC circuit breakers are correctly configured and my Redis SETNX lock has correct TTL — is the system safe against duplicate job execution?" answered only by the merge       |
| V3 — Non-obvious synthesis   | PASS: The masking hazard — circuit breakers are orthogonal to the process-pause class — is not a standard mental model; practitioners reach for circuit breakers as catch-all resilience |
| V4 — Sharper A2              | PASS: Cross-layer trigger ("retry + circuit breaker isn't preventing duplicate job processing" → process-pause fault class → fencing tokens) is absent from both source A2s              |
