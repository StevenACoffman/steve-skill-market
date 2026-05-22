---
id: grpc-load-balancer-selection
title: gRPC Load Balancer Selection
description: >
  Invoke when choosing a load balancing strategy for gRPC services, or when
  diagnosing uneven traffic distribution across gRPC backends. Key trigger:
  "deploy gRPC behind a load balancer" or "one backend is getting all traffic."
  Core rule: generic L4 TCP load balancers do not distribute gRPC traffic —
  only L7 proxies with explicit gRPC support or client-side load balancing work.
source: "gRPC: Up and Running, Kasun Indrasiri and Danesh Kuruppu, 2020 (O'Reilly)"
tags: [grpc, load-balancing, kubernetes, envoy, l4, l7, http2, production]
related_skills:
---

## gRPC Load Balancer Selection

### R — Reading

> "Two main load-balancing mechanisms are commonly used in gRPC: a
> load-balancer (LB) proxy and client-side load balancing. In proxy load
> balancing, the client issues RPCs to the LB proxy. Then the LB proxy
> distributes the RPC call to one of the available backend gRPC servers. In
> theory, you can select any load balancer that supports HTTP/2 as the LB
> proxy for your gRPC applications. However, it must have full HTTP/2 support.
> Thus it's always a good idea to specifically choose load balancers that
> explicitly offer gRPC support."

## Ch. 5 — gRPC: Beyond the Basics

### I — Interpretation

The root cause of gRPC load balancing failures is a mismatch between how L4
load balancers work and how HTTP/2 multiplexing works. Understanding the
mechanism is required to choose the correct solution.

**Why L4 load balancers break gRPC:** A standard L4 TCP load balancer
distributes connections — each TCP connection it accepts is forwarded to one
backend for the lifetime of that connection. HTTP/1.1 made one TCP connection
per request, so connection-level load distribution approximated request-level
distribution. HTTP/2 multiplexes all RPCs from a client onto a single
long-lived TCP connection. The L4 LB sees one connection and forwards it to
one backend. All RPCs from that client go to that backend for as long as the
connection is alive — which for gRPC is minutes to hours. Other backends
receive zero traffic from that client. The failure mode in production: one
backend is hot (high CPU, high memory), others are idle, and the hot backend
becomes a bottleneck.

**What "full HTTP/2 support" means:** The load balancer must be able to
inspect HTTP/2 frames and balance at the stream level — one stream per RPC —
not at the connection level. This requires the LB to speak HTTP/2 on both the
client side and the backend side, acting as an HTTP/2 reverse proxy. This is
an L7 operation.

**The three correct alternatives:**

1. **L7 proxy with explicit gRPC support (Envoy, Nginx with `grpc_pass`).** The
   proxy terminates HTTP/2 from the client and opens separate HTTP/2 connections
   to backends. Each RPC stream is an independent unit the proxy can route to
   any backend. Envoy is the standard choice in service mesh deployments.

2. **Client-side load balancing.** The gRPC client maintains a connection to
   each backend and distributes RPCs itself using a load-balancing policy
   (`round_robin` or `pick_first`). Backends are discovered via a name resolver
   (DNS, xDS, custom). In Kubernetes, this requires a headless Service so DNS
   returns per-pod IP addresses rather than a single virtual IP. The client
   then connects to all pods directly.

3. **Service mesh (Istio, Linkerd).** The sidecar proxy (Envoy in Istio's
   case) handles per-RPC load balancing transparently. The application code
   connects to a local proxy address; the proxy handles backend discovery,
   per-RPC routing, and TLS. This is the preferred approach for Kubernetes
   workloads by 2021+ standards.

The choice between these three depends on operational constraints: service
mesh = lowest application-level burden, most operational complexity to set up;
client-side LB = simplest to understand, application-aware, requires name
resolver integration; L7 proxy = infrastructure-level, language-agnostic.

### A1 — Past Application

The book constructs the `ProductInfo` service (Ch. 5) and uses it to illustrate
the failure mode when deployed behind a naive load balancer. The scenario: two
backend instances of `ProductInfo`, one gRPC client, an L4 TCP LB in front.
The client opens one HTTP/2 connection to the LB. The LB picks backend A. All
subsequent RPCs — regardless of backend B's availability or load — go to A.
Backend B receives zero traffic.

The book then introduces the two solutions: the Envoy proxy with gRPC-aware
routing (Ch. 5 / Ch. 7) and client-side `round_robin` load balancing with a
name resolver that returns both backend addresses. The name resolver causes the
client to create two connections (one per backend) and distribute RPCs in a
round-robin fashion across both.

### A2 — Future Trigger ★

- You deploy a gRPC service behind an AWS Network Load Balancer (L4/TCP). One
  backend instance shows consistently high CPU while the other idles. → L4 LB
  failure mode. Replace with an ALB with gRPC target type, or add Envoy, or
  use client-side load balancing.
- A Kubernetes `Service` of type `ClusterIP` is in front of a gRPC `Deployment`
  with 3 replicas. All traffic goes to one pod. → `kube-proxy` implements
  connection-level load balancing for TCP. Switch to headless Service +
  client-side `round_robin`, or use an ingress controller with gRPC support
  (Nginx, Traefik, GKE ingress).
- A team is choosing between Envoy sidecar and client-side load balancing for
  a gRPC fleet. The team does not want to modify application code. → Service
  mesh (Envoy sidecar via Istio/Linkerd); zero application changes required.
- A gRPC client uses `round_robin` but all backends still go to one pod because
  DNS returns a single ClusterIP. → Switch to headless Kubernetes Service
  (`clusterIP: None`) so DNS returns per-pod A records.

### E — Execution

## Option A: L7 Proxy (Envoy)

1. Configure Envoy with `lb_policy: ROUND_ROBIN` and `http2_protocol_options`
   on the cluster that points to gRPC backends. Envoy must use HTTP/2 on both
   the listener (client → Envoy) and the cluster (Envoy → backends).
2. Point clients at the Envoy address. No application code change required.

## Option B: Client-Side Load Balancing (Go)

1. In Kubernetes, create a headless Service for the gRPC backend:

   ```yaml
   spec:
     clusterIP: None
     selector:
       app: product-service
   ```

2. Configure the gRPC client with a `round_robin` service config:

   ```go
   conn, err := grpc.NewClient(
   	"dns:///product-service.default.svc.cluster.local:50051",
   	grpc.WithDefaultServiceConfig(`{"loadBalancingPolicy":"round_robin"}`),
   	grpc.WithTransportCredentials(creds),
   )
   ```

3. The DNS resolver returns one A record per pod. The client creates one
   connection per pod and distributes RPCs in round-robin order.

## Option C: Service Mesh (Istio)

1. Deploy Istio with sidecar injection enabled for the namespace.
2. No application code changes. The Envoy sidecar intercepts outbound gRPC
   traffic and applies the `DestinationRule` load balancing policy.
3. Configure the `DestinationRule` to use `ROUND_ROBIN` for the gRPC service.

**Verification:** Under all options, confirm that all backend pods show
roughly equal request rates via metrics (Prometheus `grpc_server_handled_total`
by pod).

### B — Boundary

**The book predates widespread service mesh adoption.** Ch. 5-6 was written
when service meshes were emerging but not yet default. The book presents
client-side LB as the main application-layer solution. In 2022+ Kubernetes
deployments, a service mesh (Istio or Linkerd) is more commonly the answer —
neither the client nor the server code needs LB awareness.

**AWS/GCP managed load balancers have matured.** AWS ALB and GCP Cloud Load
Balancing now support gRPC natively (HTTP/2 target groups). The book does not
cover these. For teams on managed cloud, check whether the cloud provider's
L7 load balancer supports gRPC before deploying Envoy.

**grpc.Dial is deprecated.** The book uses `grpc.Dial` for client connections.
Current gRPC-Go uses `grpc.NewClient`. The load balancing configuration via
`grpc.WithDefaultServiceConfig` works the same way.

### Audit Information

- Source extraction date: 2026-05-05
- Primary source: candidates/frameworks.md fw04; candidates/counter-examples.md ce05
- Verified entry: verified.md fw04, ce05
- Pipeline stage: Phase 2 (SKILL.md)
- Version: 0.1.0

### Related Skills

- **[grpc-l4-lb-failure-mode](../grpc-l4-lb-failure-mode/SKILL.md)** — compares: this skill is the prescriptive selection framework; grpc-l4-lb-failure-mode is the diagnostic companion for an existing production problem — use this skill for initial design, the other for incident diagnosis.
- **[grpc-observability-three-pillar](../grpc-observability-three-pillar-with-trace-log-bridge/SKILL.md)** — combines: per-pod Prometheus metrics (`grpc_server_handled_total` by pod) are the verification step after any load-balancing fix; run observability setup before or alongside LB changes.
- **[grpc-security-credential-composition](../grpc-security-credential-composition/SKILL.md)** — informs: service mesh deployments (the preferred LB option) absorb mTLS at the sidecar layer, removing the need to configure channel credentials in application code.
- **[grpc-vs-rest-vs-graphql](../grpc-vs-rest-vs-graphql/SKILL.md)** — informs: the internal-vs-external service topology established by the protocol selection skill determines what load-balancing infrastructure is appropriate.
