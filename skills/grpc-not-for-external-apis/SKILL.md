---
name: grpc-not-for-external-apis
description: |
  Invoke when a team proposes exposing a gRPC service directly to external
  third-party consumers, public API users, or browser clients. Key trigger:
  "should we expose our gRPC service publicly?" or "can external clients use
  our gRPC API?" The answer is no for direct exposure; the correct pattern is
  gRPC internally + HTTP/JSON transcoding (gRPC gateway or Envoy) at the boundary.
tags: [grpc, external-api, grpc-gateway, rest, graphql, public-api, architecture]
---
# gRPC Is Not Suitable for External-Facing APIs

## gRPC Is Not Suitable for External-Facing APIs

### R — Reading

> "When you want to expose the application or services to an external client
> over the internet, gRPC may not be the most suitable protocol as most of the
> external consumers are quite new to gRPC and REST/HTTP. The contract-driven,
> strongly typed nature of gRPC services may hinder the flexibility of the
> services that you expose to the external parties, and consumers get far less
> control (unlike protocols such as GraphQL). The gRPC gateway is designed as
> a workaround to overcome this issue."

## Ch. 1 — Introduction to gRPC; Ch. 8 — the gRPC Ecosystem

### I — Interpretation

The case against gRPC as an external API is counterintuitive because gRPC is
technically superior to REST for service-to-service communication. The
limitations are not technical weaknesses in gRPC — they are environmental
constraints imposed by the external consumer's context.

**Constraint 1: No native browser support.** HTTP/2 binary framing cannot be
accessed from browser JavaScript via standard `fetch` or `XMLHttpRequest`. The
browser's HTTP/2 implementation is hidden behind an abstraction that does not
expose stream-level control. gRPC-Web (not covered in the book) requires an
Envoy proxy to translate between gRPC-Web framing and gRPC framing. Without
this proxy, a browser simply cannot call a gRPC service. REST/JSON over HTTPS
works natively in every browser.

**Constraint 2: Proto tooling dependency in consumer builds.** A third-party
developer integrating with a gRPC API must: install the `protoc` compiler and
language-specific plugins, add proto files to their build system, regenerate
stubs on every server-side schema change, and update their build pipeline to
compile the generated code. For internal teams this is a one-time setup. For
external consumers on diverse tech stacks (Python, Ruby, PHP, JavaScript, Go,
Java) it is an adoption barrier. REST/JSON clients need only an HTTP library
and JSON parser, which every language has in its standard library.

**Constraint 3: Inability to satisfy client-controlled field selection.** gRPC
service methods return a fixed message type. The server always returns the
entire message. An external consumer who wants only `{name, price}` from a
`Product` message still receives `{name, price, inventory_count, supplier_id, ...}` — the full message — and must discard the fields it does
not need. GraphQL was designed specifically to solve this: clients specify
exactly the fields they need and the server returns only those. gRPC cannot
be extended to provide this behavior without application-level field masking
that defeats the purpose of the proto contract.

**Constraint 4: Debugging difficulty.** REST APIs are debuggable with curl,
Postman, browser developer tools, and any HTTP proxy. gRPC's binary protobuf
payloads are not human-readable without proto definitions and a compatible
decoder. A third-party developer seeing unexpected behavior cannot inspect
the wire traffic without gRPC tooling (`grpcurl`, `grpc_cli`). REST errors
are plain JSON; gRPC errors are status codes plus metadata.

**The correct architecture** does not require rewriting the backend. The gRPC
gateway (an ecosystem plugin) generates a reverse proxy server from the proto
service definition. External HTTP/JSON clients hit the gateway; the gateway
translates requests to gRPC and forwards them to the backend. The gRPC backend
changes nothing. The same service serves internal gRPC callers directly and
external HTTP callers through the gateway.

### A1 — Past Application

Chapter 8 of the book introduces the gRPC gateway as a first-class ecosystem
component — not as an afterthought, but as the standard architectural pattern
for the external boundary. The gateway is generated from proto annotations:

```protobuf
import "google/api/annotations.proto";

service ProductInfo {
  rpc GetProduct(ProductID) returns (Product) {
    option (google.api.http) = {
      get: "/v1/products/{value}"
    };
  }
  rpc AddProduct(Product) returns (ProductID) {
    option (google.api.http) = {
      post: "/v1/products"
      body: "*"
    };
  }
}
```

The `protoc-gen-grpc-gateway` plugin reads these annotations and generates a
Go HTTP handler that translates `GET /v1/products/123` into a
`GetProduct(ProductID{Value: "123"})` gRPC call. The backend implementation is
unchanged. External clients interact with a standard REST API. Internal clients
call gRPC directly and bypass the gateway entirely.

### A2 — Future Trigger ★

- A product manager asks if the internal gRPC service catalog can be exposed
  as a public API for third-party integrators. → No direct exposure; add a
  gRPC gateway layer at the public boundary.
- A mobile team reports that they cannot call a gRPC endpoint from their React
  Native app without a complex setup. → This is the expected result: no native
  gRPC support in React Native without a proxy. Provide a REST or gRPC-Web
  gateway.
- A customer integration team says they cannot consume a gRPC API because their
  platform (Salesforce, SAP) has no proto tooling. → This is the external
  consumer tooling constraint. Expose REST via gateway; gRPC stays internal.
- A team is building a developer API portal (public docs, API keys, SDKs).
  The backend is gRPC. → Generate OpenAPI documentation from the gRPC gateway
  handlers; publish REST endpoints. External developers never see the gRPC
  layer.
- An existing public REST API is being redesigned. The team wants to migrate
  to gRPC for performance. → Migrate the backend to gRPC internally; keep
  REST at the public boundary via gateway. Do not force existing integrators
  to migrate to gRPC.

### E — Execution

1. **Identify the boundary.** Services calling each other within your
   infrastructure → gRPC. Services called by external consumers (browsers,
   third-party developers, mobile clients, partner systems) → REST/JSON at
   the boundary.

2. **Add HTTP annotations to the proto file.**

   ```protobuf
   import "google/api/annotations.proto";

   service OrderManagement {
     rpc GetOrder(StringValue) returns (Order) {
       option (google.api.http) = {
         get: "/v1/orders/{value}"
       };
     }
   }
   ```

3. **Generate the gateway.**

   ```sh
   protoc -I . \
   	--go_out=. --go-grpc_out=. \
   	--grpc-gateway_out=. \
   	order_management.proto
   ```

   This produces `order_management.pb.gw.go` containing the HTTP handler.

4. **Register the gateway handler alongside the gRPC server.**

   ```go
   mux := runtime.NewServeMux()
   err := pb.RegisterOrderManagementHandlerFromEndpoint(ctx, mux, grpcAddr, opts)
   httpServer := &http.Server{Handler: mux, Addr: ":8080"}
   go httpServer.ListenAndServe()
   // gRPC server still runs on :50051
   ```

5. **Keep the gRPC service unchanged.** Internal gRPC callers connect to the
   gRPC port. External HTTP callers connect to the gateway port. The backend
   service handles both without modification.

### B — Boundary

**When gRPC is appropriate for "external" use.** If all consumers are services
controlled by your organization — even across team boundaries — and they have
the ability to run the proto compiler and integrate the generated client stubs,
gRPC is appropriate. "External" in this context means third-party developers
and consumers with no build system access. Inter-company B2B APIs where both
parties agree on the proto toolchain are a gray area.

**gRPC-Web (not in the book).** gRPC-Web is a protocol variant that allows
browsers to call gRPC services through an Envoy proxy that translates between
gRPC-Web framing and standard gRPC framing. It is the alternative to the gRPC
gateway for browser-to-service communication. gRPC-Web does not support
full bidirectional streaming from the browser (only server streaming is
supported). For new browser integrations, evaluate gRPC-Web vs. gRPC gateway
based on streaming requirements and operational preferences.

**The book does not cover gRPC-Web.** It notes that "browser support is
primitive" but does not present gRPC-Web as a solution. This is an era
limitation — gRPC-Web was maturing at the time of publication.

### Audit Information

- Source extraction date: 2026-05-05
- Verified entries: verified.md ce04, fw02
- Pipeline stage: Phase 2 (SKILL.md)
- Version: 0.1.0

### Related Skills

- **grpc-vs-rest-vs-graphql** — depends on: this skill is the actionable consequence of the broader protocol-selection framework; run grpc-vs-rest-vs-graphql first for the full decision logic.
- **grpc-security-credential-composition** — informs: introducing a gRPC gateway changes the TLS topology — the gateway terminates TLS from external clients while the backend may use mTLS internally.
- **grpc-load-balancer-selection** — relates: the gRPC gateway is itself an L7 proxy that sits at the external boundary; its placement interacts with the internal load-balancing topology.

______________________________________________________________________

## Provenance

- **Source:** gRPC: Up and Running, Kasun Indrasiri and Danesh Kuruppu, 2020 (O'Reilly)
