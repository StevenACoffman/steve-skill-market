# Test Results — Grpc-Load-Balancer-Selection

## Verdict: PASS (9/9)

## Prompt Evaluations

### Tp01 — AWS NLB Proposal for gRPC

**Type:** should_invoke
**Result:** PASS

The A2 trigger matches: "You deploy a gRPC service behind an AWS Network Load Balancer (L4/TCP). One backend instance shows consistently high CPU while the other idles." The I section explains the L4 failure mechanism. The B section explicitly notes "AWS ALB and GCP managed load balancers have matured" as a post-book development. The skill produces the correct warning plus the specific alternatives (ALB, Envoy, client-side LB).

### Tp02 — Source Quote: LB Requirements

**Type:** should_invoke
**Result:** PASS

The R section contains the exact quote about "full HTTP/2 support" and explicitly offering gRPC support. The skill explains what "full HTTP/2 support" means operationally (stream-level routing vs. connection-level routing).

### Tp03 — Explain the L4 Failure Mechanism

**Type:** should_invoke
**Result:** PASS

The I section provides the complete causal chain: L4 distributes connections → HTTP/2 multiplexes all RPCs on one connection → all RPCs go to one backend for the connection lifetime. The contrast with HTTP/1.1 (one connection per request, so per-connection routing approximated per-request) is in the I section. The skill produces the mechanistic explanation, not just the symptom.

### Tp04 — Implementation: Client-Side Round-Robin on Kubernetes

**Type:** should_invoke
**Result:** PASS

The E section Option B shows both the headless Service YAML (`clusterIP: None`) and the Go client code with `dns:///` URI and `round_robin` service config. The skill explains why a standard ClusterIP Service won't work and why the headless Service is required for DNS to return per-pod A records.

### Tp05 — Client-Side LB Vs L7 Proxy Tradeoffs

**Type:** should_invoke
**Result:** PASS

The I section describes all three alternatives with their tradeoffs: "service mesh = lowest application-level burden, most operational complexity to set up; client-side LB = simplest to understand, application-aware, requires name resolver integration; L7 proxy = infrastructure-level, language-agnostic." The E section provides concrete implementation for each option. The skill produces differentiated guidance, not a single universal recommendation.

### Tp06 — Book Example: Failure Mode Scenario

**Type:** should_invoke
**Result:** PASS

The A1 section describes the Chapter 5 ProductInfo scenario with explicit detail: multiple instances behind TCP LB, all RPCs going to the first backend, fix via client-side `round_robin` with name resolver returning all backend addresses. The skill accurately represents both the failure and the fix from the book.

### Tp07 — Scaling That Doesn't Help

**Type:** should_invoke
**Result:** PASS

The A2 trigger matches: "A team increases the replica count of a gRPC service from 3 to 10 to handle load. CPU on the originally-targeted pods drops slightly but the new pods are idle." The skill correctly diagnoses this as L4 LB stickiness — new replicas receive no traffic because existing connections are already routed to the original backends. The fix options are all in the E section.

### Tp08 — Boundary: Service Mesh Replaces LB Concern

**Type:** blurred_boundary
**Result:** PASS

The B section notes that service mesh is "the preferred approach for Kubernetes workloads by 2021+ standards." The E section Option C describes Istio deployment with no application code changes. The skill correctly explains that mixing application-level `round_robin` with Istio creates two load-balancing layers — a nuanced point the generic documentation misses.

### Tp09 — Boundary: Post-Book AWS/GCP Managed LBs

**Type:** blurred_boundary
**Result:** PASS

The B section explicitly states: "AWS/GCP managed load balancers have matured. AWS ALB and GCP Cloud Load Balancing now support gRPC natively (HTTP/2 target groups). The book does not cover these." The skill correctly positions the book's Envoy recommendation as still valid but no longer the only option. For teams on managed cloud, checking cloud provider support first is the updated guidance.

## Notes

The selection framework's E section produces different execution paths based on the operational context (Envoy for language-agnostic, client-side for application-controlled, service mesh for infrastructure-managed). This context-sensitivity is the distinctive value over generic "gRPC needs L7 load balancing" advice.
