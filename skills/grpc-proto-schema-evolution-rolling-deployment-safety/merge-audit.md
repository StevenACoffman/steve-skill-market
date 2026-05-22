# Merge Audit — Grpc-Proto-Schema-Evolution-Rolling-Deployment-Safety

## Source Skills

| Field              | Source A                                           | Source B                                       |
| ------------------ | -------------------------------------------------- | ---------------------------------------------- |
| Slug               | kleppmann/schema-evolution-compatibility-planning  | grpc-up-and-running/grpc-proto-contract-design |
| Book               | Designing Data-Intensive Applications, 2nd Edition | gRPC: Up and Running                           |
| Author             | Martin Kleppmann and Chris Riccomini               | Kasun Indrasiri and Danesh Kuruppu             |
| Chapter            | Ch. 5 — Encoding and Evolution                     | Ch. 2 and Ch. 4                                |
| Disciplinary frame | Distributed systems theory                         | gRPC practitioner guide                        |

## Phase 1 Verdict

ADVANCE — V1, V2, V3, V4 all PASS. Strongest pair in the batch.

## R-Section Audit

**Source A quote** ("This means that old and new versions of the code... may potentially coexist..."): Verified verbatim at lines 6804-6830 of DDIA 2nd ed. "Backward compatibility" and "Forward compatibility" definitions confirmed at lines 6808-6814. The field-loss passage ("if the record is decoded into a model object that does not explicitly preserve unknown fields, data can be lost") confirmed at lines 6823-6830. Rating: Accurate — verbatim match for all key claims.

**Source B quote** ("Here the number assigned to each message field is used to uniquely identify the field..."): Verified at lines 945-947 of `gRPC_up_and_running_book.md`. Package versioning sentence confirmed at lines 1034-1035. Rating: Accurate — verbatim match.

**Convergence note:** Accurately describes genuine convergence from two completely different disciplinary framings (distributed systems theory vs. gRPC practitioner guide) on the same underlying binary encoding constraint. Both arrive at "never reuse field/tag numbers" and "add new fields with new numbers" from independent derivations.

## I-Section Audit

**Field-number contract (both sources):** Both claims about field-name vs. field-number wire encoding are verified verbatim from both sources. The wire type mismatch producing silent corruption is from Source B at lines 942-947.

**Bidirectionality framework (Source A):** The backward/forward compatibility framing is verified verbatim at lines 6808-6822. The key non-obvious point — "Forward compatibility is what breaks rolling deployments" — is a direct derivation from the source that correctly characterizes the asymmetry.

**Read-modify-write failure (synthesis-specific):** The claim that the failure occurs when an ORM reconstructs a struct from parsed fields rather than serializing from the original wire bytes is the key synthesis insight. This is derived from Kleppmann's field-loss passage (lines 6823-6830) combined with the gRPC/ORM context from Source B. Kleppmann describes the general failure mode; the merged skill contextualizes it to Go ORM patterns (GORM, custom DTOs) specific to gRPC microservices. This is an accurate and important synthesis that neither source alone makes.

**Safe evolution rules table:** All rules in the table are verified from one or both sources. The "Add required field → STOP" row is from Kleppmann at lines 7174-7178. The "Change field type on same number → STOP" row is from Up and Running at lines 942-947. The `reserved` syntax is from Up and Running (verified at E-section). The "reuse removed field number → never permitted" row is from both sources (Kleppmann line 7179 + Up and Running line 945).

## A1-Section Audit

**Case 1 (Required field addition — Source A):** The rolling deployment crash from required field addition is stated in Kleppmann at lines 7174-7178. The four-step fix sequence (add as optional → deploy → verify interop → retire old code) is synthesized from the Kleppmann prescription and is correctly attributed. The case narrative is the SKILL author's construction from the general prescription — consistent with source material.

**Case 2 (Silent field loss — Source A):** The forward compatibility field loss scenario is directly stated in Kleppmann at lines 6823-6830 (Figure 5-1 reference). This is a named, illustrated case in the source. The ORM-specific framing (Go struct reconstruction) is the SKILL author's contextualization of the general principle to gRPC microservices context — accurate inference, not a verbatim claim.

**Case 3 (ProductInfo safe field addition — Source B):** `ProductInfo` service field numbering (Ch. 2) confirmed at lines 942-947. The `supplier_id = 5` evolution example is consistent with the source's "add with new number" prescription. Attribution accurate.

## A2-Section Audit

**Merged A2 sharpness:** Source A A2: "old services start failing after deploy" (required field) + "rolling deployment schema safety." Source B A2: "change int32 to int64 on same field number" (wire type change). Merged A2 is operationally sharper — asks four specific questions about a concrete deployment scenario (three services, independent schedules, one service with read-modify-write), names specific implementation checks (ORM write-back, `buf breaking`), and specifies deployment ordering as a concern. More specific and actionable than either source.

**"Instead of" framing:** Clearly distinguishes when to use this merged skill vs. either source skill alone: when the deployment window creates old+new coexistence AND there is a read-modify-write service in the dependency graph.

## E-Section Audit

**Execution length:** 8 steps. Source A E has 4 steps. Source B E has 5 steps. The merged E is longer than both sources, but justifiably so: steps 1 (deployment matrix, from A), 4 (ORM write-back test, synthesis-specific), and 8 (schema registry, from A) are each distinct prescriptions not present in the other source. The merged E does not repeat or pad; each step is non-redundant.

**Step 4 (the write-back test):** This is the key synthesis contribution in the E section — a concrete Go test that catches the read-modify-write forward compatibility failure. The test structure (write with new proto → decode with old proto → update and write back → decode with new proto → assert unknown field preserved) is correctly derived from Kleppmann's field-loss scenario and the Protobuf `proto.Marshal`/`proto.Unmarshal` API. Neither source prescribes this specific test; it is the synthesis-specific prescription that fills the gap both sources leave.

**Reconciliation:** Steps from both sources are integrated without duplication. Steps 3 and 5 (proto syntax, reserved) come from Source B. Steps 1, 2, and 8 (deployment matrix, classification, schema registry) come from Source A. Step 4 is synthesis-specific. Step 6 (`buf` CI detection) and step 7 (package versioning) come from Source B.

## B-Section Audit

**Source A failures (6 items):** Silent field loss (ce08), required field crash, serialization security (ce07), schema-on-read deferral, atomic deployment scope condition, long-lived data backward compatibility — all verified against Source A SKILL.md B-section.

**Source B failures (4 items):** Wire type change corruption, `protoc` no breaking-change detection, `StringValue` deprecation, no compile-time reuse detection — all verified against Source B SKILL.md B-section.

**Synthesis-specific failure (1 item):** The read-modify-write forward compatibility failure is explicitly named as the synthesis contribution — the failure mode that requires combining both sources to understand, and for which neither source prescribes a test. This is accurately characterized.

**Contradiction surface:** The apparent scope tension between sources is surfaced explicitly: Kleppmann scopes forward-compatibility requirements to rolling deployments; Up and Running presents proto rules as always-applicable design rules. The merged skill resolves this by making the scope condition explicit (the failure requires old+new coexistence) rather than ignoring it. There are no logical contradictions between the two sources; they address different aspects of the same underlying constraint from different disciplinary frames.

## V1–v4 Gate Summary

| Gate | Status | Evidence                                                                                                                                                                                                                                                                                              |
| ---- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1   | PASS   | Kleppmann: Protobuf field tag evolution + rolling deployment context + database write-back scenario (Ch. 5). Up and Running: field numbering (Ch. 2) + wire encoding mechanics (Ch. 4) + package versioning (Ch. 2). Five independent contexts across two books with different disciplinary framings. |
| V2   | PASS   | "We're doing a rolling deployment, adding a field to a proto, and one service reads and writes back records — what can go wrong?" Neither source alone answers the full question.                                                                                                                     |
| V3   | PASS   | The read-modify-write forward compatibility failure is invisible to developers who know proto field numbering rules but do not know about ORM write-back behavior and unknown field preservation. This is genuinely non-obvious even to experienced gRPC engineers.                                   |
| V4   | PASS   | Merged A2 is operationally specific: four concrete questions for a real deployment scenario, naming specific implementation checks and deployment ordering concerns — sharper than either source.                                                                                                     |

## Slug Rationale

`grpc-proto-schema-evolution-rolling-deployment-safety` — names all three synthesis components: the gRPC/proto context, the schema evolution topic, and the rolling-deployment safety framing. A developer searching for proto evolution, rolling deployment safety, or forward compatibility in gRPC will find this skill.

## Note on Synthesis Quality

This is the strongest pair in the batch. The convergence is from two completely different disciplinary framings (distributed systems theory + gRPC practitioner guide) on the same underlying encoding constraint. The synthesis contribution — the read-modify-write forward compatibility failure and the test that catches it — is a concrete, prescriptive addition that neither source provides and that directly addresses a real production failure class. The test in step 4 is the most actionable single addition in this merge batch.
