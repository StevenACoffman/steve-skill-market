---
id: grpc-l4-lb-failure-mode
title: L4 Load Balancer Failure Mode with gRPC
description: >
  Invoke when diagnosing uneven traffic distribution across gRPC backend pods,
  or when reviewing a gRPC deployment architecture that places services behind
  a TCP/L4 load balancer. Core issue: L4 LBs distribute connections, not RPCs;
  HTTP/2 multiplexing means all gRPC RPCs share one connection, so all go to
  one backend.
source: "gRPC: Up and Running, Kasun Indrasiri and Danesh Kuruppu, 2020 (O'Reilly)"
tags: [grpc, load-balancing, http2, l4, multiplexing, kubernetes, failure-mode, production]
related_skills:
---

## L4 Load Balancer Failure Mode with gRPC

### R — Reading

> "If you don't use a gRPC load balancer, then you can implement the
> load-balancing logic as part of the client applications you write. In theory,
> you can select any load balancer that supports HTTP/2 as the LB proxy for
> your gRPC applications. However, it must have full HTTP/2 support. Thus it's
> always a good idea to specifically choose load balancers that explicitly offer
> gRPC support. If you don't use a gRPC load balancer, then you can implement
> the load-balancing logic as part of the client applications you write."

## Ch. 5 — gRPC: Beyond the Basics

### I — Interpretation

This is a production gotcha that catches teams migrating from REST to gRPC
because the failure is invisible in development and only manifests at
production scale.

**How L4 load balancers work:** An L4 TCP load balancer intercepts TCP
connection establishment and routes each connection to a backend based on a
policy (round-robin, least-connections, etc.). From this point on, all traffic
on that TCP connection goes to that backend. The LB does not inspect the
payload — it does not know what application protocol is running over TCP.

**How HTTP/1.1 made L4 LBs work for REST:** HTTP/1.1 clients typically open a
new TCP connection per request (or use short-lived keep-alive with a small
connection limit). Each request — which maps to one connection opening — gets
load-balanced independently. Over many requests, traffic distributes roughly
evenly across backends. L4 LBs appeared to work for REST.

**Why HTTP/2 breaks this:** HTTP/2 is designed for connection reuse.
A gRPC client opens one TCP connection to the LB target and reuses it for the
lifetime of the channel — potentially hours. All RPCs from that client travel
as independent HTTP/2 streams over that one TCP connection. The L4 LB sees one
connection and routes it to backend A at connection time. Backend A receives
every subsequent RPC from that client. Backend B, C, D receive nothing from
that client. The result: one hot backend, the rest idle.

**The failure mode in production:**

- Backend A: high CPU, high memory, high latency, eventually OOM-killed or
  returning errors.
- Backends B, C, D: idle, low resource usage, healthy.
- Total capacity: a fraction of what was provisioned, because horizontal
  scaling is not working.
- Autoscaling: may spin up more backends, but they will all be idle because
  existing connections are sticky to backend A.

**Why it is invisible in development:** A single developer running one client
connecting to one backend does not exercise the load distribution at all. The
failure only appears when multiple clients connect, the LB makes different
routing decisions per-client, and the per-client stickiness becomes visible
as a skew.

**Why the fix requires L7 awareness:** An L7 proxy understands HTTP/2 framing.
It can terminate the client's HTTP/2 connection, inspect individual HTTP/2
streams (one per RPC), and route each stream to a different backend. From the
client's perspective it talks to one endpoint; from the backend's perspective
each RPC comes from the L7 proxy and can land on any backend.

### A1 — Past Application

The book's `ProductInfo` service deployment scenario (Ch. 5): three replicas
of the service behind a TCP load balancer. A continuous stream of `GetProduct`
RPCs from a single client. Expected behavior: roughly equal RPC distribution
across all three replicas. Actual behavior: all RPCs go to the replica that
received the initial TCP connection. The other two replicas serve zero RPCs.

The book then demonstrates the fix using client-side load balancing with a
round-robin service config and a name resolver that returns all three backend
addresses. The gRPC client creates three HTTP/2 connections (one per backend)
and sends RPCs to each in rotation. The L4 LB is removed from the picture
entirely — the client connects directly to the backends.

In the Kubernetes context (Ch. 7), the equivalent fix is a headless Service
(no ClusterIP), so DNS returns per-pod A records. The gRPC client's DNS
resolver discovers all pod IPs and connects to each.

### A2 — Future Trigger ★

- Prometheus metrics show `grpc_server_handled_total` orders of magnitude
  higher on one pod than the others despite an active load balancer in front.
  → L4 LB failure mode confirmed. Diagnose by checking if the LB is L4/TCP
  or L7/HTTP.
- A Kubernetes deployment has multiple gRPC replicas behind a `ClusterIP`
  Service. Traffic is uneven. → `kube-proxy` routes at the connection level.
  Fix: headless Service + client-side `round_robin`, or an L7 ingress with
  gRPC support.
- A team increases the replica count of a gRPC service from 3 to 10 to handle
  load. CPU on the originally-targeted pods drops slightly but the new pods
  stay idle. → The scaling is not effective because connections are sticky.
  The root cause is L4 LB, not insufficient replicas.
- A gRPC service is deployed behind an AWS Network Load Balancer. → NLB is L4.
  Switch to ALB (which supports gRPC as an HTTP/2 target type) or add Envoy.

### E — Execution

**Diagnosis:**

1. Check the load balancer type. L4 (TCP, NLB, `iptables` kube-proxy,
   `ClusterIP` Service) → potential gRPC skew. L7 with explicit gRPC support
   (ALB with gRPC target, Envoy, Nginx grpc_pass) → not the issue.

2. Verify with per-pod metrics. In Prometheus:

   ```promql
   sum by (pod) (rate(grpc_server_handled_total[1m]))
   ```

   Highly uneven distribution across pods = L4 LB failure mode.

**Fix option A: Headless Kubernetes Service + client-side round_robin:**

```yaml
# Service
spec:
  clusterIP: None          # headless — DNS returns per-pod A records
  selector:
    app: product-service
```

```go
// Client
conn, err := grpc.NewClient(
	"dns:///product-service.default.svc.cluster.local:50051",
	grpc.WithDefaultServiceConfig(`{"loadBalancingPolicy":"round_robin"}`),
	grpc.WithTransportCredentials(creds),
)
```

**Fix option B: Envoy proxy with gRPC support:**

Configure Envoy with `http2_protocol_options` on both listener and cluster,
and `lb_policy: ROUND_ROBIN` on the cluster. Point clients at the Envoy
endpoint. No client code changes needed.

**Fix option C: Service mesh (Istio / Linkerd):**

Enable sidecar injection for the namespace. No application code changes.
The Envoy sidecar intercepts all outbound gRPC traffic and performs per-RPC
load balancing via the xDS `DestinationRule`.

**Verification:** After applying the fix, confirm even distribution with the
same PromQL query. All pods should show approximately equal RPC rates within
expected variance.

### B — Boundary

**This failure mode applies only to long-lived connections.** If the gRPC
client is configured to close and re-establish the channel frequently (e.g.,
a serverless function that creates a new connection per invocation), L4 LBs
will distribute connections across backends more evenly. This is a workaround
with significant latency cost (connection establishment per invocation) and
is not a recommended pattern.

**AWS ALB and GCP HTTPS Load Balancing now support gRPC natively.** The book
(2020) does not mention managed cloud load balancers with gRPC support, which
have since become available. AWS ALB can be configured with gRPC as the target
group protocol; it operates at L7 and balances per-RPC. This is simpler to
operate than Envoy for AWS-hosted workloads.

**The book predates Kubernetes Gateway API.** The Kubernetes Gateway API (GA
2023\) provides a standardized way to configure L7 ingress including gRPC
routing. The book uses Nginx and Envoy directly, which remains correct but is
now one of several options.

**This skill overlaps with grpc-load-balancer-selection.** That skill covers
the full decision framework (which LB strategy to choose and why). This skill
covers the specific failure mode and diagnosis pattern for L4 LBs. Use this
skill when diagnosing an existing problem; use grpc-load-balancer-selection
when making an initial architecture decision.

### Audit Information

- Source extraction date: 2026-05-05
- Primary source: candidates/counter-examples.md ce05; candidates/frameworks.md fw04
- Verified entries: verified.md ce05, fw04
- Pipeline stage: Phase 2 (SKILL.md)
- Version: 0.1.0

### Related Skills

- **[grpc-load-balancer-selection](../grpc-load-balancer-selection/SKILL.md)** — compares: grpc-load-balancer-selection is the prescriptive framework for initial architecture decisions; this skill is the diagnostic companion for an existing production problem — use this skill when traffic skew is already observed.
- **[grpc-observability-three-pillar](../grpc-observability-three-pillar-with-trace-log-bridge/SKILL.md)** — depends on: per-pod Prometheus metrics are required to confirm and measure the L4 LB failure mode; observability must be installed before this diagnostic skill can be applied.
- **[grpc-security-credential-composition](../grpc-security-credential-composition/SKILL.md)** — informs: moving to a service mesh to fix L4 LB also changes how mTLS is handled — the mesh sidecar absorbs channel credentials, so application-level TLS config must be re-evaluated.
