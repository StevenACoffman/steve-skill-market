---
name: grpc-vs-rest-vs-graphql
description: |
  Invoke when an architecture decision requires choosing between gRPC, REST/HTTP-JSON,
  or GraphQL for a service interface. Key trigger: "should we use gRPC for this API?"
  or "should we expose gRPC to external consumers?" The framework resolves internal
  vs. external, synchronous vs. event-driven, and field-selection requirements.
tags: [grpc, rest, graphql, api-design, external-vs-internal, architecture]
---
# gRPC vs. REST vs. GraphQL Selection Framework

## gRPC Vs. REST Vs. GraphQL Selection Framework

### R — Reading

> "GraphQL is more suitable for external-facing services or APIs that are exposed
> to consumers directly where the clients need more control over the data that
> they consume from the server. In most of the pragmatic use cases of GraphQL
> and gRPC, GraphQL is being used for external-facing services/APIs while
> internal services that are backing the APIs are implemented using gRPC. When
> you want to expose the application or services to an external client over the
> internet, gRPC may not be the most suitable protocol as most of the external
> consumers are quite new to gRPC and REST/HTTP."

## Ch. 1 — Introduction to gRPC; Ch. 3 Summary

### I — Interpretation

The three protocols are not interchangeable. Each is optimized for a specific
boundary and requirement set; using the wrong one at the wrong boundary
produces concrete problems.

**gRPC** is the correct choice for synchronous, internal service-to-service
communication where: (1) both sides are services you own and can regenerate
stubs; (2) strong typing and a versioned contract are required; (3) binary
efficiency matters (high-volume calls, bandwidth-sensitive); (4) streaming is
needed. The proto contract is the interface — not URLs, not JSON field names.
The gRPC client stub is generated from the same proto the server implements,
ensuring compile-time type safety across service boundaries.

**REST/HTTP-JSON** is correct at the external API boundary where consumers
include browsers, mobile clients, and third-party developers. These consumers
have HTTP tooling (curl, Postman, browser `fetch`), expect JSON, and do not
have proto compilers in their build systems. The correct architecture when the
backend is gRPC is not to rewrite it in REST — it is to put a translation layer
(gRPC gateway or Envoy HTTP/JSON transcoding) at the boundary so the backend
stays as gRPC and external clients see standard HTTP.

**GraphQL** is correct when external clients need fine-grained control over
which fields the server returns — clients specify their own query shape and
receive exactly those fields. gRPC's fixed method contracts cannot satisfy this:
the server always returns the full defined message type regardless of what the
client needs. GraphQL was designed precisely for this use case. The common
hybrid architecture is: gRPC between internal services, GraphQL for the
external API layer that aggregates and shapes data for frontends.

**Message brokers** (Kafka, NATS, RabbitMQ) are the correct choice for
asynchronous or event-driven inter-service flows — none of these three
synchronous protocols should be used for durable, async, or fan-out delivery.

The anti-pattern this framework prevents: exposing gRPC services directly to
external consumers because "gRPC is better." The technical superiority of gRPC
for internal communication does not transfer to external APIs where consumer
environment constraints dominate.

### A1 — Past Application

The book establishes the internal-gRPC / external-REST hybrid as the standard
production architecture:

The `ProductInfo` service (Ch. 1–2) is implemented as a gRPC service in Go
serving a Java client — both are internal services sharing the same proto
contract. This is the correct gRPC use case: two services you own, same build
system, proto compiler available on both sides.

Chapter 8 introduces the gRPC gateway pattern precisely because the book
acknowledges that gRPC cannot be the external boundary. The gRPC gateway
generates a reverse proxy that translates incoming REST/HTTP-JSON requests into
gRPC calls to the backend, enabling the same gRPC service to serve both
internal gRPC clients (directly) and external HTTP clients (via the gateway)
without any backend changes.

### A2 — Future Trigger ★

- A team proposes using gRPC for a public API that third-party developers will
  integrate. Many of those developers use Python, Ruby, or JavaScript without
  a proto build step. → Reject; use REST at the public boundary with gRPC
  internally; add a gRPC gateway.
- A mobile frontend needs to query a product catalog and wants to specify
  exactly which fields to fetch (name, price, thumbnail only — no inventory
  data). → GraphQL for the frontend API; gRPC for the internal catalog and
  inventory services.
- Internal microservices need to call each other in a service mesh with typed
  contracts, low latency, and streaming support. → gRPC.
- A browser-based dashboard needs to consume data from a gRPC backend service.
  → Add gRPC-Web proxy (not covered in book) or gRPC gateway; do not expose
  raw gRPC to the browser.
- An event-driven architecture needs to fan out an order-placed event to six
  downstream services. → Message broker; this is not a synchronous RPC use
  case for any of the three protocols.

### E — Execution

1. **Determine boundary type.** Internal service-to-service → gRPC first.
   External consumer-facing → REST or GraphQL.

2. **Check consumer environment.** Does the consumer have a proto compiler in
   their build system? Do you control their build? No → REST at the boundary.
   Yes → gRPC is viable.

3. **Check field-selection requirements.** Does the consumer need to specify
   exactly which fields to receive, with the server returning only those fields?
   Yes → GraphQL. No → REST or gRPC.

4. **Check async/event-driven requirements.** Is the integration asynchronous,
   durable, or fan-out? Yes → message broker. Do not use gRPC, REST, or GraphQL
   for durable async delivery.

5. **Apply the boundary pattern for hybrid architectures.** If the backend is
   gRPC (internal) but external consumers need REST: deploy gRPC gateway or
   Envoy transcoding at the API boundary. The gRPC annotation in the proto file
   specifies the HTTP mapping:

   ```protobuf
   rpc GetProduct(ProductID) returns (Product) {
     option (google.api.http) = {
       get: "/v1/products/{value}"
     };
   }
   ```

6. **Do not duplicate the backend.** The gateway translates; it does not
   replace the gRPC backend. Maintain one implementation, not one gRPC and one
   REST version of the same service.

### B — Boundary

**gRPC-Web for browsers** (not covered in the book): gRPC-Web is a browser
adaptation of gRPC that enables browser JavaScript to call gRPC services
through an Envoy proxy. It is the alternative to gRPC gateway for browser
consumers. It requires a proxy sidecar and does not support full bidirectional
streaming from the browser. For new browser integrations, evaluate gRPC-Web
vs. gRPC gateway based on the required streaming behavior.

**The book's position on GraphQL is limited.** The book treats GraphQL only as
"better for external clients who need field selection." In practice, GraphQL is
also used for API aggregation (BFF pattern) where a single GraphQL endpoint
federates many gRPC backends. This is a common architecture the book does not
address.

**OpenCensus is deprecated.** The observability examples in the book use
OpenCensus; the current standard is OpenTelemetry. This does not affect the
gRPC vs. REST vs. GraphQL decision logic itself.

### Audit Information

- Source extraction date: 2026-05-05
- Verified entry: verified.md fw02, ce04
- Pipeline stage: Phase 2 (SKILL.md)
- Version: 0.1.0

### Related Skills

- **grpc-not-for-external-apis** — prerequisite for: this skill establishes the framework; grpc-not-for-external-apis is the applied, actionable consequence focused on the external-boundary decision.
- **grpc-communication-pattern-selection** — prerequisite for: only relevant once gRPC has been confirmed as the correct choice for a given boundary.
- **grpc-load-balancer-selection** — informs: the internal-vs-external decision shapes the load-balancing topology (public L7 proxy vs. internal service mesh).

______________________________________________________________________

## Provenance

- **Source:** gRPC: Up and Running, Kasun Indrasiri and Danesh Kuruppu, 2020 (O'Reilly)
