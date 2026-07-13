---
name: grpc-payload-optimization
description: Trigger when optimizing Protobuf message sizes or deciding whether to enable gzip compression on a gRPC service.
---
# Payload Optimization — Varint Field Ordering, gzip Threshold, and FieldMask Sequencing

## R — Reading

> "We need to keep the smaller field tags available for the fields that are the most populated or required... before diving into how to use the gzip Compressor, it is important to understand that lossless compression might result in a bigger payload size. If your payload does not contain repetitive data, which is what gzip detects and compresses, you will send more bytes than needed... The compressed payload is five times bigger than the original one."

## Ch2 (Protobuf Fundamentals), Ch6 (Designing Effective APIs), Ch7 (Out-of-the-Box Features)

## I — Interpretation

Protobuf field tags are encoded as varints alongside the wire type. Tags 1–15 fit in a single byte (5 bits for the tag value, 3 bits for the wire type). Tags 16–2047 require two bytes. This means a field set on every message costs 1 extra byte per occurrence when assigned tag 16 instead of tag 15. In a client-streaming RPC handling millions of messages, even this 1-byte difference compounds into meaningful network and serialization cost. The actionable rule: assign tags 1–15 to the most frequently populated fields; reserve higher tags for optional fields that are rarely set.

gzip compression has a fixed overhead of approximately 18 bytes regardless of input size. A minimal Protobuf message (such as a single `Int32Value` serializing to 2 bytes) expands to roughly 20 bytes under gzip — a 10x increase. Protobuf binary already eliminates field names and uses compact varint encoding, leaving little repetition for gzip to exploit. gzip only benefits messages with long strings, large repeated fields with similar values, or other repetitive byte sequences. Always measure with `proto.Marshal` before and after enabling compression; never enable it globally without benchmarking typical message samples.

The five-step payload optimization sequence — integer type selection → field tag assignment → message flattening → FieldMask for reads → gzip benchmarking — progresses from cheapest to apply (type and tag choices at schema design time) to most impactful conditionally (gzip, which can harm rather than help). Structural changes made at design time cost nothing at runtime; compression imposes CPU overhead on every call whether or not it helps.

For negative integers, `sint32`/`sint64` with ZigZag encoding is far more efficient than `int32`/`int64`: a negative `int32` always costs 10 bytes (Protobuf encodes it as a 64-bit two's complement), while `sint32` encodes small negative values in 1–2 bytes.

## A1 — Past Application

The book's TODO service evolution in Ch6 demonstrates measured field tag optimization: moving high-frequency fields (`id`, `description`, `done`) to tags 1–4, then flattening the nested `Task` sub-message in `UpdateTasksRequest` (v1: 56 bytes per request; v2: 50 bytes per request — 11% reduction per message). For `ListTasksRequest`, adding `FieldMask mask = 1` lets callers request only the fields they need, paid once per request but reducing bandwidth across all N streamed responses. Ch7's gzip example shows `Int32Value` expanding from 2 bytes to ~20 bytes under gzip compression.

## A2 — Future Trigger ★

- You are designing a proto schema for a high-volume client-streaming endpoint and need to assign field numbers
- You are evaluating whether to enable `grpc.UseCompressor(gzip.Name)` globally on a service
- A code review shows a proto message with frequently-used fields assigned tags 20+ while optional fields occupy tags 1–5
- You want to reduce bandwidth on a server-streaming endpoint that sends the same large message repeatedly to different callers

## E — Execution

1. Choose integer types: `uint32`/`uint64` for non-negative IDs, `sint32`/`sint64` for fields that frequently hold negative values, `fixed32`/`fixed64` only when values cluster near maximum range
2. Assign field tags: identify the fields set on every message; give them tags 1–15; group optional/rarely-set fields at tags 16+
3. Flatten nested messages in high-volume streaming requests: if a message wraps a sub-message type, move the editable fields directly into the request to eliminate the 2-byte length-delimited overhead per occurrence
4. Add `google.protobuf.FieldMask mask = 1` to list/get request messages; implement server-side filtering with `ProtoReflect().Range()` to clear non-requested fields before `stream.Send()`
5. Benchmark gzip: measure `proto.Marshal` output size before compression; write the same bytes to a gzip writer and measure the compressed size; enable gzip only if compressed size is reliably smaller for typical payloads

## B — Boundary

Field tag assignment is a schema design decision that is binary-incompatible once clients exist — existing serialized bytes carry the original tag numbers. Never reassign tags to different fields after deployment; add `reserved` statements for removed fields. The flattening optimization increases the number of fields in the request message, creating a maintenance burden if the domain type changes; weigh this against measured performance gain. FieldMask filtering using `ProtoReflect().Range()` clears fields from the in-memory message before serialization — ensure derived fields (e.g., an `overdue` flag computed from `due_date`) are computed after the mask is applied, not before.

## Related Skills

- **grpc-fieldmask-partial-updates** — combines: FieldMask is step 4 of the 5-step optimization sequence described here; apply fieldmask-partial-updates for the detailed server-side implementation.
- **grpc-flatten-streaming-requests** — combines: message flattening is step 3 of the same sequence; apply flatten-streaming-requests for the detailed before/after byte count analysis and migration guidance.

______________________________________________________________________

## Provenance

- **Source:** [gRPC Go for Professionals, Clément Jean, Packt, 2023]
