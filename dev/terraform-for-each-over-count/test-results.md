# Test Results: Terraform-for-Each-Over-Count

## Verdict: PASS (10/10)

## Should_invoke

| ID       | Prompt (abbreviated)                                                | Result | Notes                                                                                          |
| -------- | ------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------- |
| fe-si-01 | Count-based IAM users, remove middle item — what happens?           | PASS   | A2 trigger exact match. E steps produce specific cascade-destroy explanation and for_each fix. |
| fe-si-02 | Removing one security group rule destroys two others unexpectedly   | PASS   | Describes the index-shift symptom precisely. A2 trigger fires. E steps diagnose and fix.       |
| fe-si-03 | Should I use for_each or count for S3 buckets with different names? | PASS   | A2 trigger ("named resources with distinct identities"). E steps give specific answer.         |
| fe-si-04 | Migrating IAM users from count to for_each without destroy          | PASS   | A2 trigger covers this explicitly. E step 3 addresses moved blocks for state key migration.    |

## Should_not_invoke

| ID        | Prompt (abbreviated)                                  | Result | Notes                                                                                                                       |
| --------- | ----------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------- |
| fe-sni-01 | 3 identical NAT gateways — count or for_each?         | PASS   | B section explicitly endorses count for identical interchangeable resources with fixed cardinality. Skill correctly defers. |
| fe-sni-02 | Referencing resource attributes from another module   | PASS   | No A2 trigger. Skill stays silent; cross-module references are a separate concern.                                          |
| fe-sni-03 | Difference between Terraform resource and data source | PASS   | No A2 trigger. Fundamental concept question unrelated to for_each/count.                                                    |

## Blurred_boundary

| ID       | Prompt (abbreviated)                                                   | Result | Notes                                                                                                                                                                  |
| -------- | ---------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| fe-bb-01 | for_each value not known until apply time                              | PASS   | B section explicitly addresses this limitation and notes count with known length or module restructuring as alternatives. Nuanced response.                            |
| fe-bb-02 | Using count for Route 53 records, never removed any — should I switch? | PASS   | A2 covers risk-model explanation even without current pain. I section explains the latent risk clearly.                                                                |
| fe-bb-03 | Loop over list of objects (name + CIDR) to create subnets              | PASS   | A2 partially triggers (named resources need for_each). E step 2 covers map-valued inputs with each.key/each.value. Skill correctly frames as for_each with map syntax. |
