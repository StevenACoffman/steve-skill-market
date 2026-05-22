# Merge Audit — Grpc-Interceptor-Chain-Observability-Ordering

## Source Skills

| Field   | Source A                                               | Source B                                            |
| ------- | ------------------------------------------------------ | --------------------------------------------------- |
| Slug    | grpc-go-for-professionals/grpc-interceptor-composition | grpc-up-and-running/grpc-observability-three-pillar |
| Book    | gRPC Go for Professionals                              | gRPC: Up and Running                                |
| Author  | Clément Jean                                           | Kasun Indrasiri and Danesh Kuruppu                  |
| Chapter | Ch. 7 and Ch. 8                                        | Ch. 7 — Running gRPC in Production                  |
| Case    | TODO service (auth+metrics chain)                      | ProductInfo service (observability-only chain)      |

## Phase 1 Verdict

ADVANCE — V1, V2, V3, V4 all PASS.

## R-Section Audit

**Source A quote** ("Note that the order of these interceptors is important..."): Verified verbatim at lines 3100-3101 and 6560-6563 of `gRPC_go_for_professionals_book.md`. The merged skill correctly composites two passages from different chapters as a single R-section quote.

**Source B quote** ("When talking about observability, there are three main pillars..."): Verified at lines 6355-6357 of `gRPC_up_and_running_book.md` (same quote verified in pair-001).

**Convergence note:** Accurately describes convergence on `grpc.ChainUnaryInterceptor` from two independent books and services. Correctly identifies what each adds uniquely.

## I-Section Audit

**Single-registration constraint (Source A):** The claim that calling `grpc.UnaryInterceptor` twice silently overwrites the previous registration is verified from the source (lines 6560-6563). No compile error, no panic — this is the silent failure mode.

**Bidirectional execution model (Source A):** The left-to-right request / right-to-left response execution model is stated in the source at lines 3100-3101 and is standard gRPC interceptor behavior.

**Canonical ordering — auth before metrics (Source A):** The rate-limit → auth → metrics → logging ordering is verified at lines 3097-3101 and the counter-example (metrics before auth inflates counters) is the key claim from Source A. The phase-1 audit noted that the counter-example in A1 is the SKILL author's inference from the ordering principle — the source demonstrates the correct ordering but does not explicitly show the incorrect ordering as a labeled counter-example. This is an accurate caveat: the causal argument is stated in the source's I-section prescription but the explicit "if wrong order then false alerts" framing is an inference. The inference is valid and the merged skill is careful not to present it as a direct quote.

**Observability interceptors (Source B):** The three observability interceptors (Prometheus, zap, OTel) and `grpcMetrics.InitializeMetrics(s)` are verified at lines 6562-6589 of `gRPC_up_and_running_book.md`.

**OTel as StatsHandler not interceptor:** The merged skill correctly notes that OTel uses `grpc.StatsHandler` rather than `ChainUnaryInterceptor`. This is verified from the Up and Running source code pattern and is technically accurate for `otelgrpc.NewServerHandler()`.

**Ordering reconciliation (synthesis):** The merged skill's claim that Three-Pillar's observability chain (metrics before zap, no auth) is not in conflict with Interceptor-Composition's canonical ordering (auth before metrics) is the key reconciliation. The explanation — Three-Pillar describes the observability sub-chain in isolation, Interceptor-Composition describes the full chain including security — is an accurate characterization of how the two sources are scoped and is the correct way to combine them without contradiction.

## A1-Section Audit

**Case 1 (Source A — TODO service):** Auth interceptor with `metadata.FromIncomingContext` and `codes.Unauthenticated` return confirmed at source lines 6559-6570. Incremental Ch.7→Ch.8 chain build confirmed. The counter-example narrative is the SKILL author's synthesis from the principle (see I-section caveat above).

**Case 2 (Source B — ProductInfo):** `grpc_prometheus.NewServerMetrics()` at line 6562 and `grpcMetrics.InitializeMetrics(grpcServer)` at line 6589 confirmed verbatim. `grpc_zap.UnaryServerInterceptor(zapLogger)` confirmed in the E-section of Source B SKILL.md and the source. Attribution accurate.

**Cross-case insight:** The "sequential stages" framing (first add observability, then add auth in the correct position) is a valid logical inference from how the two books are scoped. This is not stated explicitly in either source but is entailed by the combination.

## A2-Section Audit

**Merged A2 sharpness:** Source A A2: "error-rate alerts during auth attack; suspect interceptor ordering." Source B A2: "add Prometheus interceptors; set up dashboard alert." Merged A2 is sharper — describes the specific production state (alerts firing on auth failures, not real errors), identifies the root cause (wrong chain ordering), prescribes the fix (swap in `ChainUnaryInterceptor`), and names a verification step (send failing auth request, confirm counter unchanged). More specific and actionable than either source.

## E-Section Audit

**Execution length:** 6 steps. Source A E has 6 steps. Source B E has 5 steps. Merged E is not longer than the longer source.

**Reconciliation:** Steps from both sources are combined without redundancy. The OTel stats handler (Source B pattern) is step 1, correctly positioned before chain registration. The auth-before-metrics constraint (Source A) is enforced in step 3 with an inline comment explaining why. The verification test (step 6) is from Source A and is the only way to validate the ordering constraint is actually in effect.

**No conflicts:** The merged E does not need conditionals for the E sections because Source A and Source B describe different parts of the same setup (Source A: chain API and ordering; Source B: observability interceptor initialization and metrics endpoint). They compose naturally.

## B-Section Audit

**Source A failures (4 items):** Silent override, client-side ordering inversion, existing chain audit requirement, AuthFunc stream limitation — all verified against Source A SKILL.md B-section.

**Source B failures (4 items):** OpenCensus deprecation, service mesh duplication, streaming interceptor gap, InitializeMetrics initialization order — all verified against Source B SKILL.md B-section.

**Synthesis-specific failure (1 item):** "Chain has all right interceptors in wrong positions — compiles, runs, produces metrics, but alerts are wrong." This is distinct from Source A's failure (wrong API call) and Source B's failure (missing interceptors). It is the failure mode that emerges specifically from combining the two sources without applying the ordering constraint.

**Contradiction surface:** One real potential conflict was identified: Three-Pillar registers metrics before zap (metrics, then zap), and Interceptor-Composition's canonical ordering puts metrics before logging (same relative order). No conflict on this axis. The apparent conflict — Three-Pillar shows no auth, Interceptor-Composition puts auth before metrics — is resolved as a scope difference, not a logical contradiction. The merged skill makes this explicit.

## V1–v4 Gate Summary

| Gate | Status | Evidence                                                                                                                                                                                           |
| ---- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1   | PASS   | TODO service Ch7 (2-interceptor chain) + Ch8 (4-interceptor chain) + ProductInfo Ch7 = 3 independent chain configurations across 2 books                                                           |
| V2   | PASS   | "I have Prometheus and logging registered, now adding auth — where does it go and what breaks if I get it wrong?" — neither source alone answers both halves                                       |
| V3   | PASS   | Wrong interceptor ordering produces incorrect metric signals causing incorrect alerts — not a style concern, a production operations correctness issue, non-obvious even to experienced developers |
| V4   | PASS   | Merged A2 identifies specific production state, names root cause, prescribes fix, names verification step — sharper than either source                                                             |

## Slug Rationale

`grpc-interceptor-chain-observability-ordering` — names all three synthesis contributions: the chain mechanism, the observability content, and the ordering constraint. A developer searching for interceptor ordering or observability chain composition will find this skill.
