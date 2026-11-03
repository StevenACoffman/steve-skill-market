# Test Results — Grpc-L4-Lb-Failure-Mode

## Verdict: PASS (9/9)

## Prompt Evaluations

### Tp01 — One Hot Backend Symptom

**Type:** should_invoke
**Result:** PASS

The A2 trigger matches: "Prometheus metrics show `grpc_server_handled_total` orders of magnitude higher on one pod than the others despite an active load balancer in front." The I section explains that kube-proxy implements ClusterIP at L4/TCP using iptables/IPVS. The E section provides the diagnosis path (check LB type, verify with PromQL) and fix options. The skill correctly rejects "add more replicas" as the fix.

### Tp02 — Source Quote: HTTP/2 LB Requirement

**Type:** should_invoke
**Result:** PASS

The R section contains the exact quote about "full HTTP/2 support." The skill explains what this means operationally: the LB must inspect HTTP/2 stream frames and route at the stream (per-RPC) level, not at the TCP connection level. This is the precise distinction the test requires.

### Tp03 — Why the Failure Is Invisible in Dev

**Type:** should_invoke
**Result:** PASS

The I section states: "The failure is invisible in development and only manifests at production scale." The skill explains why: a single developer's test with a few connections may not reveal the stickiness, and the skew only becomes visible when many clients connect simultaneously and each client's connection sticks to its assigned backend. The skill provides the specific causal explanation.

### Tp04 — Mechanism: HTTP/2 Multiplexing Root Cause

**Type:** should_invoke
**Result:** PASS

The I section provides the full causal chain in detail: L4 distributes connections → HTTP/2 multiplexes all RPCs on one connection → all RPCs follow the routing decision made at connection time. The HTTP/1.1 contrast (one connection per request, so per-connection routing approximated per-request distribution) is explicit. The skill explains the root mechanism, not just the symptom.

### Tp05 — Fix: Kubernetes Headless Service + Round_robin

**Type:** should_invoke
**Result:** PASS

The E section Fix option A shows both the headless Service YAML (`clusterIP: None`) and the Go client code with `dns:///service-name:port` URI and `round_robin` service config. The explanation of why ClusterIP won't work (returns one virtual IP, round_robin has nothing to balance over) is in the I section. The `dns:///` URI scheme prefix is shown.

### Tp06 — Autoscaling That Doesn't Help

**Type:** should_invoke
**Result:** PASS

The A2 trigger covers this: "A team increases the replica count of a gRPC service from 3 to 10. CPU on the originally-targeted pods drops slightly but the new pods are idle. → The scaling is not effective because connections are sticky." The skill explains that HPA triggers on the hot pods' CPU/memory, adds replicas, but the new replicas stay idle because existing connections are already routed to the original backends.

### Tp07 — Book's Demonstration Approach

**Type:** should_invoke
**Result:** PASS

The A1 section describes the Chapter 5 scenario: ProductInfo service replicas behind TCP LB, continuous RPCs all landing on one backend, client-side `round_robin` as the fix via a name resolver returning all backend addresses. The skill notes that the book covers both client-side LB and Envoy as solutions, and mentions Istio as the infrastructure-level alternative.

### Tp08 — Boundary: Service Mesh Absorbs LB Concern

**Type:** blurred_boundary
**Result:** PASS

The B section notes: "A service mesh (Istio, Linkerd) handles per-RPC load balancing transparently." The skill explains that having both application-level `round_robin` and Istio creates double load-balancing. The recommendation to remove `grpc.WithDefaultServiceConfig(round_robin)` when deploying with Istio is the correct nuanced guidance.

### Tp09 — Boundary: Post-Book AWS ALB gRPC Support

**Type:** blurred_boundary
**Result:** PASS

The B section states: "AWS ALB and GCP HTTPS Load Balancing now support gRPC natively. The book (2020) does not mention managed cloud load balancers with gRPC support." The skill positions this as a simpler alternative to standalone Envoy for AWS deployments. The book's Envoy recommendation remains valid; AWS ALB is an additional post-publication option.

## Notes

The relationship between this skill and `grpc-load-balancer-selection` is correctly scoped: this skill fires on an existing production problem (skewed traffic distribution already observed); the other fires on initial architecture decisions. The PromQL diagnosis query (`sum by (pod) (rate(grpc_server_handled_total[1m]))`) is a specific, actionable verification step that distinguishes this skill from generic load-balancing advice.
