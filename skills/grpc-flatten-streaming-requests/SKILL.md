---
id: grpc-flatten-streaming-requests
title: Flatten Repeated Fields in Client-Streaming Requests — Eliminate Sub-Message Overhead
description: Trigger when designing or optimizing a client-streaming RPC request message that currently wraps a domain object in a nested sub-message.
source: [gRPC Go for Professionals, Clément Jean, Packt, 2023]
---

## R — Reading

> "We no longer need to incur overhead for the serialization of the user-defined type. On each request, we save 2 bytes (tag + type and length). We now have more control over the fields that a user might update. If we did not want the user to change due_date anymore, we would simply remove that from the UpdateTaskRequest message and reserve the tag 4."

## Ch6 (Designing Effective APIs)

## I — Interpretation

Every length-delimited sub-message in a Protobuf message incurs 2 bytes of fixed overhead per occurrence: 1 byte for the field tag (assuming tag ≤ 15) and 1 byte for the varint-encoded length of the nested message. For a client-streaming RPC, this overhead is paid on every message the client sends. At low volume the difference is negligible, but at millions of messages per day, 2 bytes per message accumulates into significant network cost.

Flattening means moving the fields of the sub-message directly into the parent request message, eliminating the wrapping struct entirely. In the book's example, `UpdateTasksRequest { Task task = 1; }` (nested: 56 bytes total) becomes `UpdateTasksRequest { uint64 id = 1; string description = 2; bool done = 3; google.protobuf.Timestamp due_date = 4; }` (flattened: 50 bytes total) — an 11% reduction per message.

Flattening also grants finer API control. The nested version implicitly exposes every field of the `Task` type as mutable through the update endpoint. The flattened version explicitly declares which fields are updatable; removing a field from the flattened request is a one-line proto change that does not affect the domain `Task` type. This is a useful separation when the domain type evolves but the API surface should remain stable.

The trade-off is field duplication: some fields appear in both the domain struct and the request message. This duplication is the price of the explicit API contract. It is acceptable when the performance benefit is measurable (high-volume streaming) or when explicit API surface control is the primary motivation.

## A1 — Past Application

The TODO service's `UpdateTasksRequest` evolution in Ch6 shows the before/after with measured byte counts. The v1 nested version (`Task task = 1`) produced 56 bytes per request measured with `proto.Marshal`. The v2 flattened version produced 50 bytes — saving 2 bytes from the sub-message wrapper and 4 bytes by removing the redundant `id` repetition in the nested case. The server's `Recv()` loop works identically in both versions; only the request message shape changed.

## A2 — Future Trigger ★

- You are designing a client-streaming RPC and the natural first draft wraps a domain type directly in the request message
- A high-volume streaming endpoint is consuming unexpected network bandwidth and you are profiling per-message sizes
- You need to restrict which fields of a domain object are exposed for mutation through a specific streaming endpoint
- A code review shows `UpdateXxxRequest { XxxType entity = 1; }` and the endpoint receives millions of messages per day

## E — Execution

1. Measure the current per-message size with `proto.Marshal` on a representative message and record the baseline
2. Identify which fields of the wrapped sub-message type need to be mutable through this endpoint (not necessarily all of them)
3. Replace `XxxType entity = 1` in the request message with individual field declarations for only the mutable fields, assigning tags 1–N
4. Add `reserved 1` (or the original tag range) if removing the sub-message field from an existing deployed schema
5. Update the server handler to read fields directly from the flattened request (`req.Id`, `req.Description`) instead of from the nested struct
6. Measure the new per-message size with `proto.Marshal` and confirm the expected reduction

## B — Boundary

Flattening is a binary-incompatible schema change if deployed clients are already using the nested version — treat it as a new API version or migrate clients simultaneously. The savings only justify the duplication for high-frequency streaming; for unary or low-volume endpoints, the overhead is negligible and the duplication cost (maintaining parallel field sets) is not worth it. Flattening makes the request message dependent on the domain fields at schema design time; if the domain type gains new fields that should be mutable, the request message must be updated separately. Never flatten in a way that removes a `reserved` tag without coordinating with existing clients.

## Related Skills

- **[grpc-payload-optimization](../grpc-payload-optimization/SKILL.md)** — prerequisite for: flattening is step 3 of the 5-step payload optimization sequence; payload-optimization frames when to apply flattening vs. field tag assignment vs. gzip.
- **[grpc-fieldmask-partial-updates](../grpc-fieldmask-partial-updates/SKILL.md)** — compares: both are streaming bandwidth reduction techniques — flattening reduces request overhead on client-streaming writes; FieldMask reduces response overhead on server-streaming reads; apply both for bidirectional streaming endpoints.
