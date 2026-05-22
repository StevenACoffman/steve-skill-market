# Merge Audit — Grpc-Observability-Three-Pillar-with-Trace-Log-Bridge

## Source Skills

| Field   | Source A                                            | Source B                                              |
| ------- | --------------------------------------------------- | ----------------------------------------------------- |
| Slug    | grpc-up-and-running/grpc-observability-three-pillar | grpc-microservices-in-go/grpc-traceid-log-correlation |
| Book    | gRPC: Up and Running                                | gRPC Microservices in Go                              |
| Author  | Kasun Indrasiri and Danesh Kuruppu                  | Hüseyin Babal                                         |
| Chapter | Ch. 7 — Running gRPC in Production                  | Ch. 9 — Observability                                 |
| Case    | ProductInfo service (single service)                | Order/Payment service pair (multi-service)            |

## Phase 1 Verdict

ADVANCE — V1, V2, V3, V4 all PASS.

## R-Section Audit

**Source A quote** ("When talking about observability, there are three main pillars..."): Verified verbatim at lines 6355-6357 of `gRPC_up_and_running_book.md`. The merged skill uses a condensed version that preserves the meaning without adding claims not in the source.

**Source B quote** ("To inject trace and span IDs into every log we printed using the logrus library..."): Verified at lines 5820-5838 and 5871 of `gRPC_Microservices_in_Go_book.md`. The quote composites three sentences from adjacent paragraphs; all claims are verbatim.

**Convergence note:** Documents genuine convergence — OTel interceptor injection from two independent codebases. Correctly identifies what each adds uniquely without overstating the overlap.

## I-Section Audit

**Three-pillar framing (Source A):** The cost/volume model (metrics = always-on, logs = medium, traces = sampled) is accurately derived from the source's treatment of the three signals.

**Integration gap (synthesis-specific):** The claim that registering OTel interceptors does not automatically inject trace_id into log lines is the key non-obvious synthesis insight. This is correct and verified: `otelgrpc.NewServerHandler()` creates spans but does not inject fields into logrus entries. The formatter is required as an additional step. Neither source alone states this plainly; the merged skill makes it explicit.

**Formatter implementation:** The `Format(entry *logrus.Entry)` pattern with `trace.SpanFromContext(entry.Context)` is verified at lines 5838-5858 of `gRPC_Microservices_in_Go_book.md`.

## A1-Section Audit

**Case 1 (Source A — ProductInfo):** Code snippets for `grpc_prometheus.NewServerMetrics()` verified at lines 6562-6589 of `gRPC_up_and_running_book.md`. Attribution accurate.

**Case 2 (Source B — Order/Payment):** The `logrusFormatter` type and `logrus.SetFormatter` in `init()` verified at lines 5838-5858 of `gRPC_Microservices_in_Go_book.md`. `log.WithContext(ctx).Info(...)` confirmed at line 5861. Kibana trace_id filter confirmed at lines 6055-6059.

**Cross-case claim:** The claim that a single-service case cannot exhibit the integration gap (because there is only one log stream) is a valid logical inference from the source material. It is not a direct quote but is entailed by the setup.

## A2-Section Audit

The merged A2 is sharper than either source:

- Source A A2: "logs show the error but not which downstream call caused it" — suggests traces
- Source B A2: "cannot correlate log lines to a specific user request" — suggests trace_id in logs
- Merged A2: "all three pillars are live, filtering by trace_id returns no results — bridge missing" — more specific, identifies the exact production failure state

The "Instead of" framing is satisfied: instead of applying the three-pillar pattern or the bridge pattern independently, use this merged skill when both are needed together.

## E-Section Audit

**Execution length:** The merged E has 9 steps. Source A E has 5 steps. Source B E has 6 steps. The merged E is not longer than the longer source E in terms of implementation depth — the additional steps (formatter registration, context audit, backend configuration) are each short and non-redundant.

**Reconciliation:** Steps from both sources are combined without duplication. The merged sequence correctly positions the formatter installation (step 2) before server start and before any log calls — an ordering constraint derived from Source B that is not present in Source A.

**Conditionals:** The note distinguishing `grpc.StatsHandler(otelgrpc.NewServerHandler())` from chain interceptors is accurate — OTel uses the stats handler API, not the interceptor API, for the trace injection.

## B-Section Audit

**Source A failures (3 items):** OpenCensus deprecation, service mesh duplication, streaming interceptor gap — all verified against Source A SKILL.md B-section.

**Source B failures (4 items):** Missing WithContext, backend dependency, logrus-specific extension point, Jaeger deprecation — all verified against Source B SKILL.md B-section.

**Synthesis-specific failure (1 item):** "All three pillars correct, zero log-trace correlation" — this is the combination failure mode that neither source's B-section alone describes. It is the key synthesis insight reformulated as a failure mode.

**Contradiction surface:** No direct contradictions between source B-sections. Source A treats the three signals as co-equal strategic pillars; Source B implicitly prioritizes the trace-log bridge as the most actionable production step. These are complementary framings, not contradictions. The merged skill presents both framings without forcing a false conflict.

## V1–v4 Gate Summary

| Gate | Status | Evidence                                                                                                                                                                  |
| ---- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1   | PASS   | ProductInfo (A, Ch7) + Order service (B, Ch9) + Payment service (B, Ch9) = 3 independent contexts across 2 books                                                          |
| V2   | PASS   | "Three pillars running, cannot filter logs by trace_id" — neither source alone answers this                                                                               |
| V3   | PASS   | Registering OTel interceptors does NOT automatically inject trace_id into logrus entries — non-obvious to experienced gRPC developers                                     |
| V4   | PASS   | Merged A2 is more specific than either source: identifies the exact production failure state (all pillars live, correlation absent) rather than individual pillar absence |

## Slug Rationale

`grpc-observability-three-pillar-with-trace-log-bridge` — encodes both the strategic frame (three-pillar) and the specific synthesis contribution (trace-log bridge). A developer searching for either term will find this skill.
