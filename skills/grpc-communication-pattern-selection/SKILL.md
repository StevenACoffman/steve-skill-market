---
id: grpc-communication-pattern-selection
title: gRPC Communication Pattern Selection
description: >
  Invoke when choosing between gRPC's four communication patterns (unary,
  server streaming, client streaming, bidirectional streaming) for a new
  service method. Trigger conditions: designing a new RPC that involves
  multiple results, batched writes, or real-time full-duplex flows.
source: "gRPC: Up and Running, Kasun Indrasiri and Danesh Kuruppu, 2020 (O'Reilly)"
tags: [grpc, streaming, pattern-selection, architecture, unary, bidi]
related_skills:
---

## gRPC Communication Pattern Selection

### R — Reading

> "There is no hard-and-fast rule when it comes to selecting a communication
> pattern, but it's always good to analyze the business use case and then select
> the most appropriate pattern. Simple RPC is the most basic one; it is pretty
> much a simple request–response style remote procedure invocation.
> Server-streaming RPC allows you to send multiple messages from the service
> to the consumer after the first invocation of the remote method, while client
> streaming allows you to send multiple messages from the client to the service.
> Bidirectional-streaming RPC allows both client and server to send streams of
> messages simultaneously and independently."

## Ch. 3 — gRPC Communication Patterns

### I — Interpretation

The four patterns are not style choices — they are structural matches to the
data-flow shape of the business operation. Choosing the wrong one means
simulating the correct pattern in application code, with weaker guarantees and
more complex logic than using the correct gRPC primitive directly.

**Unary** maps to any transactional lookup or command: one input, one output,
one round trip. The server has all the information it needs before the client
hangs up. Examples: `getOrder(id)`, `addProduct(product)`.

**Server streaming** is correct when a single query produces an unknown or
large number of results that should flow progressively — the server does not
buffer the entire result set before responding. The trigger condition is: "one
request, many responses." Examples: `searchOrders(query)` returning matching
orders as found, a log-tail subscription. The proto marker is `returns (stream T)`.

**Client streaming** is correct for batched writes or upload pipelines: the
client sends many items and the server summarizes or acknowledges after
processing all of them. The trigger condition is: "many inputs, one aggregate
response." The server calls `SendAndClose` after it drains the stream. Example:
`updateOrders(stream Order)` returning a summary string.

**Bidirectional streaming** is correct only when neither side waits for the
other to finish before sending. Both the client and the server send streams
independently and concurrently. This is a strong requirement — if the server
must process all client messages before it can respond, client streaming is
more appropriate. The trigger condition is: "full-duplex real-time exchange
where send and receive interleave." Examples: order processing with progressive
shipment acknowledgment (`processOrders`), a chat protocol.

The decision heuristic: start with unary. Upgrade to streaming only when there
is a specific, concrete reason — progressive delivery of many results, batched
writes, or genuine full-duplex interleaving. Streaming RPCs add complexity
(stream lifecycle management, error propagation mid-stream, flow control) that
unary avoids entirely.

### A1 — Past Application

The book's `OrderManagement` service demonstrates all four patterns on the same
domain object:

- **Unary**: `getOrder(StringValue) returns (Order)` — single order lookup by ID.
  One request, one response. No streaming justification.
- **Server streaming**: `searchOrders(StringValue) returns (stream Order)` —
  search result set of unknown size. Server iterates orders and calls
  `stream.Send()` per match; client loops `stream.Recv()` until `io.EOF`.
- **Client streaming**: `updateOrders(stream Order) returns (StringValue)` —
  bulk update. Client sends each order via `stream.Send()` then `CloseAndRecv()`;
  server loops until `io.EOF` then calls `SendAndClose(summary)`.
- **Bidirectional**: `processOrders(stream StringValue) returns (stream CombinedShipment)` —
  the server groups incoming order IDs by delivery location and flushes batches
  back to the client when a threshold is reached. The client uses a goroutine to
  receive shipments concurrently with sending more order IDs.

The `processOrders` design is the critical one: the server does not wait for
the client to finish sending before it starts responding. That genuine
full-duplex requirement is what justifies bidirectional streaming over the
simpler server-streaming alternative.

### A2 — Future Trigger ★

- You are designing a `searchProducts(query)` endpoint that returns all
  matching products. The result set is potentially large and you want the
  client to display results as they arrive. → Server streaming.
- You are building a bulk-ingest endpoint where the client sends thousands of
  log entries and expects a single acknowledgment with a count. → Client
  streaming.
- A service needs to stream sensor readings to a server that responds with
  real-time alerts — both sides send concurrently without waiting. → Bidirectional
  streaming.
- A code review requests changing a unary `getReportLines()` to return a
  `repeated` field in one large response. The result set can be hundreds of
  megabytes. → Refactor to server streaming to avoid buffering.
- Someone proposes using bidirectional streaming for a use case where the
  server sends a response only after it has received all client messages. →
  Downgrade to client streaming; bidirectional is not needed.

### E — Execution

1. **Identify the data-flow shape.** Ask: how many messages does the client
   send? How many does the server send? Do they interleave? One-to-one =
   unary. One-to-many = server streaming. Many-to-one = client streaming.
   Many-to-many interleaved = bidirectional.

2. **Write the proto method signature.** Use `stream` prefix on input or
   output as dictated by the pattern:

   ```protobuf
   rpc GetOrder(StringValue) returns (Order);                            // unary
   rpc SearchOrders(StringValue) returns (stream Order);                // server stream
   rpc UpdateOrders(stream Order) returns (StringValue);                // client stream
   rpc ProcessOrders(stream StringValue) returns (stream CombinedShipment); // bidi
   ```

3. **Implement the server handler.** For server streaming: loop and call
   `stream.Send(msg)`, return `nil` to close. For client streaming: loop
   `stream.Recv()` until `io.EOF`, then `stream.SendAndClose(summary)`. For
   bidirectional: use a goroutine to receive concurrently with sending.

4. **Implement the client call.** For server streaming: loop `stream.Recv()`
   until `io.EOF`. For client streaming: call `stream.Send()` per item, then
   `stream.CloseAndRecv()`. For bidirectional: launch a goroutine for the
   receive loop before entering the send loop.

5. **Verify stream termination.** Every stream path must reach a terminal
   state. Server streaming: server returns `nil`. Client streaming: server
   calls `SendAndClose`. Bidirectional: both sides must close their send
   direction. A missing close leaks a goroutine.

### B — Boundary

**Bidirectional is often overused.** Developers default to bidi because it
feels most powerful. Before using it, verify that the server genuinely needs
to send before the client finishes — if not, client streaming (for client-heavy)
or server streaming (for server-heavy) is simpler and has less lifecycle
complexity.

**Java polyglot note.** The book gives Java implementations of all four patterns.
The gRPC semantics are identical; only the API surface differs (`StreamObserver`
vs. Go's `stream.Send`/`stream.Recv`). For Go-only teams, ignore the Java
examples but note the proto definitions are shared.

**Flow control and back-pressure** are not covered in the book. For high-volume
streaming, gRPC's HTTP/2 flow control window can stall a sender if the receiver
is slow. This is a production concern not addressed by pattern selection alone.

### Audit Information

- Source extraction date: 2026-05-05
- Primary source: candidates/frameworks.md fw01; candidates/cases.md ca01–ca04
- Verified entry: verified.md fw01
- Pipeline stage: Phase 2 (SKILL.md)
- Version: 0.1.0

### Related Skills

- **[grpc-vs-rest-vs-graphql](../grpc-vs-rest-vs-graphql/SKILL.md)** — informs: confirms gRPC is the right protocol before selecting which of its four patterns to use.
- **[grpc-observability-three-pillar](../grpc-observability-three-pillar-with-trace-log-bridge/SKILL.md)** — relates: streaming interceptors must be registered separately from unary interceptors; pattern selection determines which interceptor variants are needed.
