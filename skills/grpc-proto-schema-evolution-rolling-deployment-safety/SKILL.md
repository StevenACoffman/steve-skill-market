---
name: grpc-proto-schema-evolution-rolling-deployment-safety
allowed-tools: Bash, Read, Edit
id: grpc-proto-schema-evolution-rolling-deployment-safety
description: >
  Invoke when planning a Protobuf schema change that will be deployed to a gRPC
  system where old and new service versions run simultaneously during the rollout.
  Key trigger: "we're adding a field to a proto and old nodes are still running"
  or "we can't figure out where our new field data went." The non-obvious failure:
  during rolling deployments, old-version nodes that read new-format records and
  reconstruct objects via ORM/DTO silently strip unknown fields before writing back —
  no error is raised, the data is permanently lost. The test that catches this is
  explicitly exercising old-code deserialization of new-format records followed by
  write-back verification.
type: merged-skill
source_skills:
  - slug: kleppmann/schema-evolution-compatibility-planning
    book: "Designing Data-Intensive Applications, 2nd Edition"
    author: Martin Kleppmann and Chris Riccomini
  - slug: grpc-up-and-running/grpc-proto-contract-design
    book: "gRPC: Up and Running"
    author: Kasun Indrasiri and Danesh Kuruppu
related_skills:
  - slug: kleppmann/schema-evolution-compatibility-planning
    relation: supersedes
    note: Covers bidirectionality framework and rolling-deployment failure modes without proto-specific tooling (buf, reserved syntax, package versioning).
  - slug: grpc-up-and-running/grpc-proto-contract-design
    relation: supersedes
    note: Covers proto contract rules and buf tooling without the rolling-deployment forward-compatibility failure analysis.
tags: []
---

# gRPC Proto Schema Evolution — Rolling Deployment Safety and the Read-Modify-Write Failure

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Proto files:
!`find . -name '*.proto' -not -path './.git/*' 2>/dev/null | head -10`

Reserved field declarations:
!`grep -rn '^  reserved' . --include='*.proto' 2>/dev/null | head -10`

buf.yaml (schema linting):
!`find . -name 'buf.yaml' -o -name 'buf.gen.yaml' -not -path './.git/*' 2>/dev/null | head -5`

### R — Reading

> "This means that old and new versions of the code, and old and new data formats, may
> potentially coexist in the system at the same time. For the system to continue running
> smoothly, you need to maintain compatibility in both directions:
>
> Backward compatibility: Ensures that newer code can read data written by older code.
>
> Forward compatibility: Ensures that older code can read data written by newer code.
>
> Forward compatibility can be trickier, because it requires older code to ignore
> additions made by a newer version of the code.
>
> Say you add a field to a record schema, and the newer code creates a record containing
> that new field and stores it in a database. Subsequently, an older version of the code
> (which doesn't yet know about the new field) reads the record, updates it, and writes
> it back. In this situation, the desirable behavior is usually for the old code to keep
> the new field intact, even though it wasn't able to interpret it. But if the record is
> decoded into a model object that does not explicitly preserve unknown fields, data can
> be lost."

*Designing Data-Intensive Applications, 2nd Ed., Ch. 5 — Encoding and Evolution* (Kleppmann & Riccomini)

> "Here the number assigned to each message field is used to uniquely identify the field
> in the message. So, we can't use the same number in two different fields in the same
> message definition... We can also define package names with version numbers like
> ecommerce.v1 and ecommerce.v2. So future major changes to the API can coexist in the
> same codebase."

*gRPC: Up and Running, Ch. 2 and Ch. 4* (Indrasiri & Kuruppu)

**Convergence note:** Both sources ground their core rules in the same binary encoding fact — Protobuf fields are identified by tag/field numbers, not names — arriving independently because the rules derive from the Protobuf wire encoding specification, not from opinion. What each adds uniquely: Kleppmann contributes the bidirectionality framework (backward and forward compatibility as simultaneous requirements during rolling deployments) and the silent-field-loss failure mode that occurs at the application layer above the proto layer; Up and Running contributes the proto-specific syntax (`reserved`, `optional`), package versioning for breaking changes, and the `buf` CLI for automated breaking-change detection.

### I — Interpretation

**The field-number contract.** Protobuf encoding writes each field as a `(field_number, wire_type, value)` tuple. Field names are not transmitted on the wire. The decoder on the receiving end looks up the field number to determine which field of its local message struct to populate. This has two major implications:

- Field name changes are safe — renaming `string product_id = 1` to `string item_id = 1` changes generated code but not the wire format. No deployed client or server requires simultaneous update.
- Field number changes are contract breaks — changing `string name = 2` to `int32 quantity = 2` causes any client compiled against the old proto to misinterpret the bytes. The decoder does not report an error; it produces garbage values or wrong field population.

**The bidirectionality requirement.** During a rolling deployment, old-version and new-version nodes run simultaneously. Both compatibility directions must hold at the same time:

- *Backward compatibility* (new code reads old data): relatively easy. New code knows what old-format data looks like and can provide defaults for fields old data does not include.
- *Forward compatibility* (old code reads new data): harder, and the one that breaks rolling deployments. Old-version nodes encounter records written by new-version nodes that contain fields the old code has never seen. If the old code cannot safely ignore those fields — and if it writes the record back — those new fields are permanently lost with no error.

**The read-modify-write forward compatibility failure.** This is the non-obvious production failure that neither source prescribes a test to catch:

1. New-version nodes are deployed alongside old-version nodes (rolling deployment).
2. New-version nodes write records with a new optional field (say, `priority_tier = 6`).
3. Old-version nodes read those records. Protobuf's generated code handles unknown fields by default when the field is optional — the field is preserved in the binary representation.
4. *But*: if the old-version node's ORM layer reconstructs a Go struct from parsed proto fields, updates one attribute, and then serializes *from the struct* (not from the original wire bytes), the new field is absent from the struct and is silently dropped on write-back.
5. No error is raised. The record now has `priority_tier` absent. New-version nodes that read the record back see a zero-value for the field.
6. Discovery happens only after the deployment completes — when engineers notice new field values absent from records that were modified by old nodes during the window.

The failure is caused by the application layer, not the proto layer. The proto field addition was correct (new number, optional, with default). The ORM or DTO reconstruction is the component that drops the field. Protobuf's generated code preserves unknown fields in `XXX_unrecognized` (proto2) or the unknown fields mechanism (proto3) — but only if the serialization path writes from the original parsed message, not from a reconstructed struct.

**Safe evolution rules (both sources, reconciled):**

| Change                           | Safety                 | Action                                                      |
| -------------------------------- | ---------------------- | ----------------------------------------------------------- |
| Add optional field, new number   | Safe both directions   | Use new field number; verify ORM preserves on write-back    |
| Add required field               | Backward violation     | Stop — add as optional, enforce at application layer        |
| Rename field                     | Safe in Protobuf       | Change freely; number is the contract                       |
| Remove field                     | Forward violation risk | Reserve the number; `reserved 3; reserved "old_name";`      |
| Change field type on same number | Both violations        | Stop — add new field with new number; deprecate old         |
| Reuse removed field number       | Both violations        | Never — corrupts data with no error signal                  |
| Breaking API redesign            | Both violations        | Create `package ecommerce.v2`; run v1 and v2 simultaneously |

### A1 — Past Application

## R — Reading

> "This means that old and new versions of the code, and old and new data formats, may
> potentially coexist in the system at the same time. For the system to continue running
> smoothly, you need to maintain compatibility in both directions:
>
> Backward compatibility: Ensures that newer code can read data written by older code.
>
> Forward compatibility: Ensures that older code can read data written by newer code.
>
> Forward compatibility can be trickier, because it requires older code to ignore
> additions made by a newer version of the code.
>
> Say you add a field to a record schema, and the newer code creates a record containing
> that new field and stores it in a database. Subsequently, an older version of the code
> (which doesn't yet know about the new field) reads the record, updates it, and writes
> it back. In this situation, the desirable behavior is usually for the old code to keep
> the new field intact, even though it wasn't able to interpret it. But if the record is
> decoded into a model object that does not explicitly preserve unknown fields, data can
> be lost."

*Designing Data-Intensive Applications, 2nd Ed., Ch. 5 — Encoding and Evolution* (Kleppmann & Riccomini)

> "Here the number assigned to each message field is used to uniquely identify the field
> in the message. So, we can't use the same number in two different fields in the same
> message definition... We can also define package names with version numbers like
> ecommerce.v1 and ecommerce.v2. So future major changes to the API can coexist in the
> same codebase."

*gRPC: Up and Running, Ch. 2 and Ch. 4* (Indrasiri & Kuruppu)

**Convergence note:** Both sources ground their core rules in the same binary encoding fact — Protobuf fields are identified by tag/field numbers, not names — arriving independently because the rules derive from the Protobuf wire encoding specification, not from opinion. What each adds uniquely: Kleppmann contributes the bidirectionality framework (backward and forward compatibility as simultaneous requirements during rolling deployments) and the silent-field-loss failure mode that occurs at the application layer above the proto layer; Up and Running contributes the proto-specific syntax (`reserved`, `optional`), package versioning for breaking changes, and the `buf` CLI for automated breaking-change detection.

## I — Interpretation

**The field-number contract.** Protobuf encoding writes each field as a `(field_number, wire_type, value)` tuple. Field names are not transmitted on the wire. The decoder on the receiving end looks up the field number to determine which field of its local message struct to populate. This has two major implications:

- Field name changes are safe — renaming `string product_id = 1` to `string item_id = 1` changes generated code but not the wire format. No deployed client or server requires simultaneous update.
- Field number changes are contract breaks — changing `string name = 2` to `int32 quantity = 2` causes any client compiled against the old proto to misinterpret the bytes. The decoder does not report an error; it produces garbage values or wrong field population.

**The bidirectionality requirement.** During a rolling deployment, old-version and new-version nodes run simultaneously. Both compatibility directions must hold at the same time:

- *Backward compatibility* (new code reads old data): relatively easy. New code knows what old-format data looks like and can provide defaults for fields old data does not include.
- *Forward compatibility* (old code reads new data): harder, and the one that breaks rolling deployments. Old-version nodes encounter records written by new-version nodes that contain fields the old code has never seen. If the old code cannot safely ignore those fields — and if it writes the record back — those new fields are permanently lost with no error.

**The read-modify-write forward compatibility failure.** This is the non-obvious production failure that neither source prescribes a test to catch:

1. New-version nodes are deployed alongside old-version nodes (rolling deployment).
2. New-version nodes write records with a new optional field (say, `priority_tier = 6`).
3. Old-version nodes read those records. Protobuf's generated code handles unknown fields by default when the field is optional — the field is preserved in the binary representation.
4. *But*: if the old-version node's ORM layer reconstructs a Go struct from parsed proto fields, updates one attribute, and then serializes *from the struct* (not from the original wire bytes), the new field is absent from the struct and is silently dropped on write-back.
5. No error is raised. The record now has `priority_tier` absent. New-version nodes that read the record back see a zero-value for the field.
6. Discovery happens only after the deployment completes — when engineers notice new field values absent from records that were modified by old nodes during the window.

The failure is caused by the application layer, not the proto layer. The proto field addition was correct (new number, optional, with default). The ORM or DTO reconstruction is the component that drops the field. Protobuf's generated code preserves unknown fields in `XXX_unrecognized` (proto2) or the unknown fields mechanism (proto3) — but only if the serialization path writes from the original parsed message, not from a reconstructed struct.

**Safe evolution rules (both sources, reconciled):**

| Change                           | Safety                 | Action                                                      |
| -------------------------------- | ---------------------- | ----------------------------------------------------------- |
| Add optional field, new number   | Safe both directions   | Use new field number; verify ORM preserves on write-back    |
| Add required field               | Backward violation     | Stop — add as optional, enforce at application layer        |
| Rename field                     | Safe in Protobuf       | Change freely; number is the contract                       |
| Remove field                     | Forward violation risk | Reserve the number; `reserved 3; reserved "old_name";`      |
| Change field type on same number | Both violations        | Stop — add new field with new number; deprecate old         |
| Reuse removed field number       | Both violations        | Never — corrupts data with no error signal                  |
| Breaking API redesign            | Both violations        | Create `package ecommerce.v2`; run v1 and v2 simultaneously |

## A1 — Past Application

### Case 1: Rolling Deployment Crash — Required Field Addition

A distributed system team adds a new `required` field to a Protobuf message and initiates a rolling deployment. Old nodes in the cluster — running the version compiled against the old proto — begin crashing when they receive messages written by new nodes. The new field is absent from those messages (old nodes that wrote them did not know about it), and the new code requiring the field fails or crashes on deserialization.

**Methodology applied (Kleppmann):** Adding a required field violates backward compatibility. The fix is to add the field as `optional` with a sensible default. Old code receiving a message without the field uses the default rather than crashing. New code receiving a message without the field (written by old code) also uses the default. After all old code is retired, the field's required semantics can be enforced at the application layer.

**Conclusion:** The crash is a direct, deterministic consequence of violating "never add required fields." The fix is not to slow the rollout — it is to change the schema rule.

**Result:** Old nodes crash during the deployment window. Rolling back requires coordination because new-format data already written to the database or message queue persists.

### Case 2: Silent Field Loss — ORM Write-Back Strips Unknown Fields

During a rolling deployment, new-version nodes write order records with a new `fulfillment_priority = 6` field. Old-version nodes read those records via their ORM layer, update the `status` field, and write the records back. The `fulfillment_priority` field disappears from all records that pass through old nodes. No error is raised — not in application logs, not in Protobuf deserialization, not in the database.

**Methodology applied (Kleppmann):** This is a forward compatibility violation at the application layer. Protobuf's generated code preserves unknown fields in the binary representation when parsing. But the ORM reconstructs a Go struct from parsed fields, updates `Status`, and serializes from the struct — which does not model `fulfillment_priority`. The new field is absent from the struct and is silently dropped on write-back.

**Conclusion:** The fix requires that the serialization path on write-back uses the original parsed message (with unknown fields preserved), not a reconstructed struct. If the ORM cannot be configured this way, the deployment order must ensure old nodes do not write back records written by new nodes until old nodes are fully retired.

**Result:** Permanent, silent data loss for records modified by old nodes during the deployment window. Discovery is post-deployment, when field values are missing from recently-written records.

### Case 3: ProductInfo Service — Safe Field Addition

The book *gRPC: Up and Running* demonstrates safe evolution of the `ProductInfo` proto (Ch. 2, Ch. 4):

```protobuf
// Original
message Product {
  string id = 1;
  string name = 2;
  string description = 3;
  float price = 4;
}

// Safe evolution — new field, new number
message Product {
  string id = 1;
  string name = 2;
  string description = 3;
  float price = 4;
  string supplier_id = 5;  // old clients receive this as zero value ("")
}
```

An old client that does not know about field 5 ignores it gracefully. A new client connecting to an old server receives `supplier_id` as the zero value — also handled gracefully because proto3 zero values are defaults. This is the happy path that works correctly when (a) the field is optional, (b) there is no read-modify-write path through old code, and (c) the ORM preserves unknown fields.

## A2 — Future Trigger ★

Instead of applying the compatibility planning framework (Kleppmann) or the proto contract rules (Up and Running) independently, use this merged skill when:

- You are adding a new optional string field to a Protobuf message used by three services deployed on independent schedules. Before deploying, answer: (a) Is the field optional with a default? (b) Does any service read records and write them back — and if so, does its ORM preserve unknown fields in the write-back path? (c) Does CI have `buf breaking` detection to catch future field number reuse? (d) What is the deployment order — does the writing service or reading service deploy first?
- A developer proposes reusing field number 5 for a new `routing_key` field because the old `metadata` field using number 5 was removed last quarter. Stop: reusing number 5 corrupts any persisted records that have the old `metadata` bytes, with no error signal.
- After a rolling deployment, engineers discover that a new field's values are absent from records modified during the deployment window. This is the read-modify-write forward compatibility failure — audit the old code's ORM write-back path for unknown field preservation.
- A team is choosing between JSON and Protobuf for an inter-service event schema that will be consumed by services deployed on different schedules over multiple years. Protobuf and Avro enforce compatibility rules structurally; JSON relies on developer discipline and code review (fragile at scale).

## E — Execution

1. **Build the deployment matrix.**
   List every service or node that reads or writes the data being schema-changed. Determine which versions will coexist during the deployment window and for how long. If any old+new coexistence window exists, both backward and forward compatibility must hold.

2. **Classify each proposed schema change.**
   For every change in the diff:
   - Add optional field, new number → compatible; proceed
   - Add required field → STOP; change to optional with default
   - Remove field → STOP; add `reserved <number>; reserved "<name>";` first
   - Rename field → safe in Protobuf; proceed
   - Change field type on same number → STOP; add new field with new number, deprecate old
   - Reuse removed field number → STOP; never permitted

3. **Write the proto contract-first.**

   ```protobuf
   syntax = "proto3";
   package ecommerce.v1;
   option go_package = "github.com/example/ecommerce/v1;ecommerce";

   message Product {
     reserved 5, 6;
     reserved "legacy_sku", "internal_code";
     string id = 1;
     string name = 2;
     string description = 3;
     float price = 4;
     string supplier_id = 7;  // new field, new number
   }
   ```

   Generate code for all services from the same proto: `protoc --go_out=. --go-grpc_out=.`

4. **Test unknown-field preservation across old and new code versions.**
   This is the test that neither source prescribes explicitly but that catches the read-modify-write failure:

   ```go
   func TestOldCodePreservesUnknownFieldsOnWriteBack(t *testing.T) {
       // 1. Write a record using the NEW proto (with supplier_id = 7)
       newMsg := &newpb.Product{Id: "p1", SupplierId: "s42"}
       encoded, _ := proto.Marshal(newMsg)

       // 2. Decode using the OLD proto (no supplier_id field)
       oldMsg := &oldpb.Product{}
       proto.Unmarshal(encoded, oldMsg)

       // 3. Modify a known field and write back via old code's ORM path
       oldMsg.Name = "Updated Name"
       reencoded, _ := proto.Marshal(oldMsg)

       // 4. Decode the written-back record using NEW proto
       roundTripped := &newpb.Product{}
       proto.Unmarshal(reencoded, roundTripped)

       // 5. Assert unknown field was preserved
       assert.Equal(t, "s42", roundTripped.SupplierId,
           "old code write-back must preserve unknown fields")
   }
   ```

   If this test fails, either the ORM is reconstructing from a struct (fix the ORM path) or change the deployment order so old nodes do not write back new-format records.

5. **Reserve removed field numbers and names.**

   ```protobuf
   message Product {
     reserved 3, 7;
     reserved "old_field_name", "deprecated_sku";
     // ... remaining fields
   }
   ```

6. **Add `buf` breaking-change detection to CI.**

   ```sh
   buf breaking --against '.git#branch=main'
   ```

   This catches field number reuse, type changes, and field removal before they reach a deployed service.

7. **Create a new package version for breaking changes.**
   When field-number-preserving evolution is not possible:

   ```protobuf
   syntax = "proto3";
   package ecommerce.v2;
   option go_package = "github.com/example/ecommerce/v2;ecommerce";
   ```

   Run `v1` and `v2` simultaneously until all clients have migrated. Maintain `v1` until the last client is retired.

8. **For long-lived event schemas, add a schema registry in FULL compatibility mode.**
   Configure BACKWARD + FORWARD enforcement before any producer deployment. The registry blocks schema changes that fail compatibility checks before they reach a consumer. For short-lived RPC schemas with controlled deployment windows, CI `buf` detection (step 6) is sufficient.

## B — Boundary

**Source A (Kleppmann) failure modes:**

- Silent field loss (ce08): Old code reads new-format record, drops unknown fields on write-back — permanent data loss, no error signal. The defining synthesis failure mode.
- Required field addition crashes old nodes during rolling deployment — direct, deterministic, caught by load testing in staging if staging simulates rolling deployment.
- Language-specific serialization security (ce07): Java `Serializable`, Python `pickle` allow arbitrary code execution if an attacker controls deserialized data. Proto and Avro are not subject to this; relevant when evaluating format selection.
- Schema-on-read defers rather than eliminates the schema problem: document stores ("schemaless") shift schema enforcement to read time, multiplying version-detection conditionals across all readers.
- Atomic deployment (all nodes upgraded simultaneously) eliminates forward compatibility requirements — but is only feasible for monolithic single-version deployments.
- Long-lived data at rest (years in a database or event log) requires backward compatibility indefinitely — new code written in 2028 must read records written in 2024.

**Source B (Up and Running) failure modes:**

- Wire type change on same field number produces silent data corruption — the decoder does not report an error; it decodes bytes according to its local (wrong) expectation.
- `protoc` has no breaking-change detection. `buf` is required for automated enforcement; manual review is fragile at scale.
- `google.protobuf.StringValue` wrapper type pattern is deprecated. Use `proto3 optional` for fields where zero and absent have different semantics.
- No breaking-change detection in `protoc` directly — field number reuse is a compile-time success that becomes a runtime corruption.

**Synthesis-specific failure mode:**
The read-modify-write forward compatibility failure is the primary synthesis contribution. A developer adds an optional field (correct technique, passes Source B's contract rules), deploys new code while old nodes are still running (covered by Source A's framework), but does not test whether old code's ORM preserves unknown fields on write-back (neither source prescribes this test). The field addition is correct at the proto layer. The data loss occurs at the application layer above the proto layer. The test in execution step 4 is the specific prescription that neither source provides and that catches this failure in staging before it reaches production.

**Contradiction surface:** Kleppmann focuses on the deployment-window coexistence problem and the general principle of serialization format selection. Up and Running focuses on per-change proto syntax rules. These are orthogonal framings of the same underlying constraint (field-number identity) — they do not conflict. The only apparent tension is scope: Up and Running's rules are presented as always-applicable proto design rules; Kleppmann's rules are explicitly scoped to systems with rolling deployments or independent service deployments. The merged skill makes the Kleppmann scope condition explicit: the forward-compatibility failure mode requires old+new code coexistence — atomic deployments of a single-version monolith do not exhibit it.
