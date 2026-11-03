# Merge Status Ledger

Read before appending or reading a source skill's `## Merge Status` entry.

````markdown
## Merge status

```yaml
# one entry per merge run that evaluated this skill
- run: <merge-run-slug>          # which run (matches books/merged/<merge-run-slug>/)
  state: <state>                 # see vocabulary below
  pair: <pair-id>                # present for surface-resemblance, complementary, rejected
  into: <merged-skill-slug>      # present for merged and partial
  reason: <code>                 # present for rejected only
  excluded: <description>        # present for partial — what content was not included
```
````

**State vocabulary:**

| State                 | Written by         | Meaning                                                                          |
| --------------------- | ------------------ | -------------------------------------------------------------------------------- |
| `no-candidate`        | Phase 0            | No overlap candidate found for this skill in this run                            |
| `surface-resemblance` | Phase 0            | Pair evaluated; rejected as labels-only overlap                                  |
| `complementary`       | Phase 0            | Pair evaluated; different domains, Zettelkasten link added instead               |
| `rejected`            | Phase 1.5 or 1.5.5 | Pair passed Phase 0 but failed source verification or V1–V4                      |
| `partial`             | Phase 2            | Merged skill created; some content from this skill was excluded (see `excluded`) |
| `merged`              | Phase 2            | Merged skill created; all key content from this skill is represented             |

**Reason vocabulary** (used with `state: rejected` only):

| Reason code                    | Origin                                                      |
| ------------------------------ | ----------------------------------------------------------- |
| `source-text-unavailable`      | Phase 1.5: source EPUB/PDF not available                    |
| `source-verification-failed`   | Phase 1.5: quote not-found or material drift                |
| `v1-failed`                    | Phase 1.5.5: convergence not genuine                        |
| `v2-failed`                    | Phase 1.5.5: merged skill adds no predictive power          |
| `v3-failed`                    | Phase 1.5.5: synthesis is common wisdom                     |
| `v4-failed-merge-not-additive` | Phase 1.5.5: merge adds no capability over invoking sources |

**Relationship to `related_skills`:** `merge_status` is an audit trail — it records
why a fate was assigned and by which run. `related_skills` (written by Phase 3) is a
navigation pointer — it tells users where to find the merged skill. They coexist and
serve different purposes; `merge_status: merged` does not replace a
`related_skills: superseded-by` entry.
