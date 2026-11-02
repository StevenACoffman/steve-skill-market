# Source-Verification Header

Read before writing a `source-verification/<pair-id>-{r,a1}.md` file in Phase 1.5.

**Structured header.** Begin each `source-verification/<pair-id>-{r,a1}.md` with a
YAML frontmatter header recording the verdict per source, then the free-form
narrative. `exegesis merge-index` reads these headers to generate the INDEX
"Source Verification Summary" table (a V1–V4 column from the ledgers is not
generated yet), so you write each verdict once instead of hand-maintaining the table:

```yaml
---
pair: <pair-id>
check: r-quote-accuracy   # or a1-attribution
sources:
  - book: <slug-a>
    skill: <skill-a>
    status: accurate       # R: accurate|drifted-minor|drifted-major|not-found
    corrected: false       #    A1: verified|mismatch|not-found
  - book: <slug-b>
    skill: <skill-b>
    status: drifted-minor
    corrected: true
---
```

Use the **same `<pair-id>`** in these headers and in the `## Merge Status` ledger
so the summary's V1–V4 column joins correctly.
