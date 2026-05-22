---
id: grpc-fieldmask-partial-updates
title: FieldMask for Partial Reads — Caller-Controlled Field Selection on Streaming Endpoints
description: Trigger when implementing caller-controlled partial field selection on a gRPC read or list endpoint, especially streaming, to prevent over-fetching.
source: [gRPC Go for Professionals, Clément Jean, Packt, 2023]
---

## R — Reading

> "FieldMasks is. It refers to objects containing a list of paths telling Protobuf which fields to include and telling it implicitly which should not be included... This is interesting when we are doing the equivalent of GET and we do not want to fetch too much unnecessary data (over-fetching). It is interesting to use masks because we can send it once and it will be applied to all the elements returned by the server."

## Ch6 (Designing Effective APIs)

## I — Interpretation

`google.protobuf.FieldMask` is a well-known Protobuf type carrying a list of dot-separated field path strings (e.g., `["id", "description"]`). Added to a list or get request message as `google.protobuf.FieldMask mask = 1`, it gives callers explicit control over which response fields are populated.

Server-side filtering is implemented using `ProtoReflect().Range()`, which iterates over all set fields in the message. For each field descriptor, check if its name is in the mask's path list; if not, call `proto.Reset` on that field to return it to its zero value. Zero-value fields are not serialized by Protobuf, so they cost zero bytes on the wire.

For server-streaming endpoints, the mask cost is paid exactly once per request (as part of the initial message) but the bandwidth savings compound across every streamed response. A mask that eliminates two fields from a response that streams 10,000 items eliminates the wire cost of those fields 10,000 times.

A subtle correctness requirement: apply the mask before computing any derived fields that depend on masked inputs. The book's TODO service computes `overdue = due_date != nil && !done && due_date.Before(now)`. If `due_date` is not in the caller's mask, the filter clears it to nil before the overdue calculation runs. Because the cleared field is now nil, `overdue` evaluates to false — and `false` (the default bool value) is not serialized either. Applying the mask after deriving `overdue` would incorrectly include the derived field even when its input was not requested.

## A1 — Past Application

The TODO service's `ListTasks` server-streaming endpoint was introduced without FieldMask in Ch5 (`ListTasksRequest` had no mask field). Ch6 adds `google.protobuf.FieldMask mask = 1` to `ListTasksRequest` and implements the `Filter(task, req.Mask)` helper. The handler calls `Filter` before the overdue calculation, then calls `stream.Send`. The server-streaming nature means the client pays for the mask field once and receives filtered responses for every task in the database, making the bandwidth saving proportional to result count.

## A2 — Future Trigger ★

- You are designing a list or get endpoint where different callers need different subsets of the response fields
- A mobile client is complaining about excessive bandwidth usage from a streaming endpoint that returns many fields they do not use
- You need to add field selection to an existing streaming endpoint and need to know the correct server-side implementation using ProtoReflect
- You have a response message with derived fields (computed properties) and need to ensure they are correctly omitted when their input fields are masked

## E — Execution

1. Add `import "google/protobuf/field_mask.proto"` to the proto file and add `google.protobuf.FieldMask mask = 1` to the request message for the read/list endpoint
2. In the server handler, extract `req.Mask`; if the mask is nil or empty, treat all fields as requested (skip filtering for full-response clients)
3. Implement a `Filter(msg proto.Message, mask *fieldmaskpb.FieldMask)` helper: iterate over the message's fields with `msg.ProtoReflect().Range(func(fd protoreflect.FieldDescriptor, v protoreflect.Value) bool {...})`; for each field whose name is not in `mask.Paths`, call `msg.ProtoReflect().Clear(fd)`
4. Call `Filter(response, req.Mask)` before any derived-field computation that depends on the potentially-masked inputs
5. Proceed with derived field computation; because cleared fields hold zero values, any computation on them naturally produces zero/false/nil — which Protobuf does not serialize
6. Call `stream.Send(response)` or return the filtered response from a unary handler

## B — Boundary

FieldMask path strings use the proto field name (snake_case), not the Go struct field name. The mask is advisory — the server must enforce it; a client cannot trust that the server will honor it without server-side implementation. FieldMask does not prevent the database query from fetching all columns; to avoid over-fetching at the database layer, the mask paths must be translated into a `SELECT` column list, which requires additional adapter logic. The `ProtoReflect().Range()` approach iterates only over fields that are currently set; fields already at zero value are not iterated but also not serialized, so they are naturally absent from the response. For nested messages, the mask path uses dots (e.g., `"metadata.created_at"`), which requires recursive filtering logic.

## Related Skills

- **[grpc-payload-optimization](../grpc-payload-optimization/SKILL.md)** — prerequisite for: FieldMask is step 4 in the payload optimization sequence; consult payload-optimization for the full 5-step ordering and the decision on when gzip complements or undercuts FieldMask savings.
- **[grpc-flatten-streaming-requests](../grpc-flatten-streaming-requests/SKILL.md)** — compares: both reduce per-message bandwidth on streaming endpoints by different means — FieldMask eliminates unwanted response fields at read time; flattening eliminates sub-message framing overhead at write time.
