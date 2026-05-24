# Test Results: Terraform-Moved-Block-Refactoring

## Verdict: PASS (10/10)

## Should_invoke

| ID       | Prompt (abbreviated)                                                                                  | Result | Notes                                                                                                                                                                                                                             |
| -------- | ----------------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| mb-si-01 | Rename resource from aws_security_group.instance to .web_server — will it destroy?                    | PASS   | A2 trigger exact match. I section explains the state address model. E steps give the moved block procedure.                                                                                                                       |
| mb-si-02 | Extract resources from root module into module called webserver_cluster without destroying production | PASS   | A2 trigger exact match. E steps 1-4 give the full extraction procedure with moved blocks. A1 shows the exact pattern.                                                                                                             |
| mb-si-03 | Difference between moved block and terraform state mv                                                 | PASS   | A2 trigger explicit ("asks whether terraform state mv is still recommended"). I section explains moved blocks are code-reviewable vs imperative; B section notes terraform state mv is still required for cross-state-file moves. |
| mb-si-04 | Count-to-for_each migration: map [0][1][2] keys to ["alice"]["bob"]["carol"] without destroying       | PASS   | A2 trigger exact match. E step 6 explicitly covers one moved block per instance with the positional-to-identity mapping syntax.                                                                                                   |

## Should_not_invoke

| ID        | Prompt (abbreviated)                                                          | Result | Notes                                                                                                                                                                   |
| --------- | ----------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| mb-sni-01 | Delete a resource from Terraform state without destroying real infrastructure | PASS   | No A2 trigger. terraform state rm is removing from state entirely, not renaming or moving. Skill correctly stays silent.                                                |
| mb-sni-02 | Import an existing AWS resource into Terraform state                          | PASS   | No A2 trigger. terraform import adds new resources to state; moved blocks handle address changes of existing state entries. Skill stays silent.                         |
| mb-sni-03 | Move state file from one S3 bucket to another                                 | PASS   | No A2 trigger. Backend migration (terraform init -migrate-state) is a different operation from resource address renaming. B section explicitly distinguishes this case. |

## Blurred_boundary

| ID       | Prompt (abbreviated)                                                                   | Result | Notes                                                                                                                                                                     |
| -------- | -------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| mb-bb-01 | Split one large module into two with separate state files — can moved block handle it? | PASS   | B section explicitly says "moved blocks do not work across state files; terraform state mv is required." Skill correctly resolves the ambiguity with a definitive answer. |
| mb-bb-02 | Applied moved block successfully — can I remove it now?                                | PASS   | B section and I section both explicitly warn: only remove moved blocks after all environments have applied. Skill gives specific lifecycle guidance.                      |
| mb-bb-03 | On Terraform 1.0, rename a resource without destroying — what are my options?          | PASS   | B section explicitly says "moved blocks require Terraform 1.1+. On 1.0, terraform state mv is the only option." Skill handles the version boundary cleanly.               |
