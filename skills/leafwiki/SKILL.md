---
name: leafwiki
description: |
  Use when building or maintaining a personal/team knowledge base with LeafWiki
  (the self-hosted Go wiki at github.com/perber/leafwiki, local copy in
  ~/Documents/git/leafwiki) — running the server, editing its markdown-on-disk
  content under data/root/, triggering resync after external edits, and writing
  pages so they are also valid Open Knowledge Format (OKF v0.2) concepts. Triggers
  on "leafwiki", "self-hosted wiki", "LLM wiki", "ingest this source into the
  wiki", "update the wiki", "wiki lint pass", or any request to accumulate/curate
  knowledge as interlinked markdown that a wiki serves and an OKF consumer can
  read. Covers the LeafWiki on-disk layout (sections = folder + index.md, leaf
  pages = <slug>.md, assets/<pageID>/), reserved vs. preservable frontmatter, the
  edit-then-resync loop (SIGUSR1/SIGHUP), and the exact frontmatter to add so
  pages carry OKF provenance/trust/lifecycle without breaking LeafWiki.
---

# LeafWiki as an LLM-maintained, OKF-compatible knowledge base

LeafWiki is a lightweight self-hosted wiki. Its defining property for our purposes:
**the filesystem is the source of truth.** Every page is a plain markdown file on
disk under `<data-dir>/root/`. You (the agent) edit those files directly, trigger a
resync, and the running server picks up the changes. This makes LeafWiki an ideal
substrate for the "LLM wiki" pattern: the LLM incrementally builds and maintains a
persistent, interlinked wiki; the human curates sources and asks questions; LeafWiki
serves and renders the result in a browser.

This skill has three jobs:

1. Operate LeafWiki (run it, find its content, resync after edits).
2. Write and maintain the wiki as a compounding artifact (ingest / query / lint).
3. Shape every page so it is *also* a conformant **OKF v0.2** concept, so the
   corpus is portable to any OKF consumer, not just LeafWiki.

---

## 1. Mental model: three layers

Map the LLM-wiki pattern onto LeafWiki:

- **Raw sources** — your immutable inputs (articles, PDFs, transcripts, notes).
  Keep these *outside* `root/` (e.g. a sibling `sources/` dir, or reference them by
  URL). LeafWiki should never treat them as pages. The LLM reads them; never edits.
- **The wiki** — `<data-dir>/root/`: LLM-owned markdown. Entity pages, concept
  pages, summaries, comparisons, an overview, `index.md` listings, `log.md`. This
  is the layer you write.
- **The schema** — this SKILL plus any per-wiki conventions doc you co-evolve with
  the user. It's what makes you a disciplined maintainer instead of a chatbot.

The human runs sourcing, exploration, and questions. You do the summarizing,
cross-referencing, filing, and bookkeeping — and you keep it OKF-clean.

---

## 2. Running LeafWiki

LeafWiki is primarily a **server**, not a rich CLI. The binary's subcommands are
only `reset-admin-password`, `restore-snapshot`, and `--help`; everything else is
the server. You interact with *content* through the filesystem, not CLI verbs.

Build from the local checkout (Go toolchain required):

```sh
cd ~/Documents/git/leafwiki
go build -o /usr/local/bin/leafwiki ./cmd/leafwiki   # or any dir on PATH
# or use the repo's install.sh / release binaries
```

Simplest local single-user setup (personal KB on loopback, no auth):

```sh
leafwiki --disable-auth --data-dir ./wiki-data
# serves http://127.0.0.1:8080 ; content lives at ./wiki-data/root/
```

`--disable-auth` implies public access and is fine **only** on a trusted local
machine. For anything networked, run with auth instead:

```sh
leafwiki --jwt-secret "$LEAFWIKI_JWT_SECRET" \
         --admin-password "$LEAFWIKI_ADMIN_PASSWORD" \
         --data-dir ./wiki-data --host 127.0.0.1 --port 8080
```

Config precedence is **CLI flag > env var > default**; every flag has a
`LEAFWIKI_*` env equivalent (see `--help`). Useful flags for a KB:

- `--data-dir <DIR>` — where `root/`, `assets/`, `users.db`, `snapshots/` live.
- `--enable-revision` — keep page history (recommended; you rewrite pages a lot).
- `--git-backup` + `--git-backup-remote <ssh-url>` — push `root/` + `assets/` to a
  git remote on an interval. The wiki is a git repo of markdown either way.
- `--public-access` — read-only public, edits require login.

The user usually runs the server themselves. If you need them to start or restart
it, suggest they type it as a `! <command>` in the prompt so the output lands here.

---

## 3. On-disk layout — this is what you edit

Everything below is under `<data-dir>/root/`.

| Thing | On disk |
|-------|---------|
| **Leaf page** (no children) | `<slug>.md` |
| **Section** (has children) | folder `<slug>/` containing `index.md` (the section's own page) + child `.md` files / subfolders |
| **Child order** | `.order.json` in each folder — order is explicit, *not* alphabetical |
| **Assets** (images, files) | `<data-dir>/assets/<pageID>/<filename>`, served at `/assets/<pageID>/<filename>` — keyed by page **ID**, not slug |
| **Ignore rules** | `.leafwikiignore` (gitignore-style) in `root/`; read **only at startup** |

Rules and gotchas:

- **Slug ≠ identity.** A page's identity is `leafwiki_id` in its frontmatter, which
  survives renames/moves. The filename is just the slug (URL segment). Slugs are
  lowercase-kebab, no extension in the slug itself.
- **A `<slug>.md` file and a `<slug>/` folder cannot coexist** in the same
  directory — that's a hard conflict. To give a leaf page children, convert it:
  make a `<slug>/` folder and move its content into `<slug>/index.md`.
- **Page title** comes from `leafwiki_title` if present, else the frontmatter
  `title`, else the first `# H1` / filename. For sections, the title comes from
  `index.md`.
- **Manual ordering:** if you care about sidebar order, you generally set it in the
  UI (which writes `.order.json`). New pages default to creation order. Don't
  hand-maintain `.order.json` unless asked.

---

## 4. The edit → resync loop (the core workflow)

LeafWiki does **not** watch the filesystem. After you create/edit/delete/move `.md`
files on disk, changes are invisible until a **resync** (rebuilds tree, links,
tags, search index). Trigger it one of two ways:

- **OS signal** (best for agents): `kill -USR1 <pid>` or `kill -HUP <pid>` on the
  running LeafWiki process. No restart needed.
- **Admin UI:** Settings → maintenance → trigger resync (four phases: tree, links,
  tags, search).

```sh
# find the pid and resync
pkill -USR1 -f 'leafwiki .*--data-dir'      # or: kill -USR1 $(pgrep -f leafwiki)
```

**`leafwiki_id` write-back:** any `.md` file you add *without* a `leafwiki_id` gets
one generated and **written back into the file on disk** on the next resync. This is
expected and automatic, but it means your file changes after resync (an extra diff
if you manage `root/` under your own git). You may leave `leafwiki_id` out and let
resync stamp it, or omit it knowingly.

`.leafwikiignore` changes are read only at **startup**, not on resync — restart to
apply them.

---

## 5. Frontmatter: what LeafWiki reserves vs. preserves

This is the crux of OKF compatibility. LeafWiki parses frontmatter into a fixed set
of reserved keys and an `ExtraFields` bag; **unknown keys are preserved and
round-tripped** through save/resync (re-emitted, sorted alphabetically, with the
`leafwiki_*` keys appended last). So you can add OKF frontmatter freely.

**Reserved / managed by LeafWiki (do not repurpose):**

- `leafwiki_id`, `leafwiki_title`, `leafwiki_created_at`, `leafwiki_updated_at`,
  `leafwiki_creator_id`, `leafwiki_last_author_id`, `leafwiki_pinned` — LeafWiki
  owns these. Timestamps are RFC3339.
- `tags` — a **managed** key: LeafWiki reads it and drives its tag feature from it.
  This is *good* — OKF also uses `tags`, so one `tags:` list serves both. Use it.

**Preserved (safe for OKF), everything else**, including:
`type`, `title`, `description`, `resource`, `sources`, `generated`, `verified`,
`status`, `stale_after`, and any `runtime`/`parameters`/`executor`/`attester`
(Attested Computation) keys.

Compatibility caveats — internalize these:

1. **Quote date/datetime values.** A bare `at: 2026-06-20T22:53:05Z` may be parsed
   as a timestamp and reformatted on round-trip. Quote OKF dates so they stay
   verbatim strings: `at: "2026-06-20T22:53:05Z"`, `stale_after: "2026-09-23"`.
2. **`title` vs `leafwiki_title`.** If you set OKF `title:` and not
   `leafwiki_title:`, LeafWiki uses `title` for display — good. If it later writes
   back it may add a separate `leafwiki_title`; both can coexist harmlessly. To pin
   display text, set `leafwiki_title` explicitly; keep `title` for OKF.
3. **Key order is normalized.** Extra keys get sorted alphabetically on rewrite, so
   `type` won't stay first. OKF doesn't care about order — this is fine.
4. **`index.md` gets a `leafwiki_id`.** OKF §8 says index files carry no
   frontmatter (except root `okf_version`). LeafWiki stamps `leafwiki_id` into every
   section `index.md`. This is a soft OKF divergence; OKF consumers MUST tolerate
   unknown keys, so it's acceptable. Embrace folder + `index.md` as the OKF
   directory node (see §7).

---

## 6. The page template (LeafWiki + OKF v0.2)

Use this shape for every concept page. `type` is the only OKF-required field; the
rest are recommended and make the corpus trustable.

```markdown
---
type: Reference                      # OKF required: kind of concept (free string)
title: Vannevar Bush                 # display name (also LeafWiki title fallback)
description: Engineer who proposed the Memex, a precursor to hypertext.
tags: [people, hypertext]            # LeafWiki tags AND OKF tags — one list
status: stable                       # draft | stable | deprecated
generated: { by: "claude/opus-4-8", at: "2026-07-30T12:00:00Z" }
verified: { by: "human:steve", at: "2026-07-30T13:00:00Z" }   # omit if unverified
stale_after: "2027-01-30"            # optional; agent marks facts that expire
sources:
  - id: memex-1945
    resource: https://www.theatlantic.com/.../as-we-may-think/303881/
    title: "As We May Think (1945)"
    last_modified: "1945-07-01"
---

# Overview

Structural markdown over prose. Bush proposed the [Memex](/concepts/memex.md),
an associative knowledge store.[^memex-1945]

# Connections

- Influenced [hypertext](/concepts/hypertext.md).

[^memex-1945]: As We May Think (1945)
```

Notes:
- **`generated.by` / `verified[].by` use the OKF actor convention:** `<agent>/<ver>`
  for you (e.g. `claude/opus-4-8`), `human:<id>` for a person, `process:<id>` for
  automation. A page verified by a `human:` actor is "human-reviewed"; machine-only
  verification is "machine-confirmed"; no `verified` key is "unverified." Add a
  `verified` entry only when a check actually happened — never fabricate human
  sign-off.
- **Per-claim citations** use markdown footnotes whose label equals a
  `sources[].id`. This is how OKF attributes individual claims.
- Leave `leafwiki_id` out and let resync stamp it (or set it if you already know it).

---

## 7. Links, index.md, log.md

**Links (OKF §6).** LeafWiki supports two styles:

- **Standard markdown links** — `[Memex](/concepts/memex.md)`. Prefer these with
  **bundle-relative absolute paths** (leading `/`, relative to `root/`, with `.md`).
  This is the OKF-recommended form and is stable across moves. Use this style for
  portability.
- **Wikilinks** — `[[Memex]]` or `[[Folder/Title]]`, resolved by page title. Native
  to LeafWiki and convenient, but **not** OKF markdown links. Prefer standard links
  in filed pages; wikilinks are fine in scratch/drafts.

A broken link is not an error in either system — it can mark not-yet-written
knowledge. Consumers tolerate it.

**`index.md` (OKF §8, LeafWiki section page).** In LeafWiki a section's `index.md`
is both its landing page and a natural OKF directory listing. Make it a catalog:

```markdown
# People

* [Vannevar Bush](bush.md) — proposed the Memex.
* [Ted Nelson](nelson.md) — coined "hypertext".
```

Update the relevant `index.md` on every ingest. It's your progressive-disclosure
map: read it first when answering a query, then drill into linked pages. (LeafWiki
will add a `leafwiki_id` to it — accepted divergence, §5.4.)

**`log.md` (OKF §9).** Keep an append-only, newest-first log so both you and the
human can see the wiki's evolution. In LeafWiki it becomes a normal browsable page.
Use ISO date headings and a consistent, greppable entry prefix:

```markdown
# Update Log

## 2026-07-30
* **Ingest**: [As We May Think](/sources/as-we-may-think.md); updated
  [Memex](/concepts/memex.md) and [Vannevar Bush](/people/bush.md).
* **Creation**: [hypertext](/concepts/hypertext.md).
```

`grep "^## " log.md | head` then gives you a quick timeline.

---

## 8. Operations (what to actually do)

**Ingest a source.** The human drops/points you at a raw source.
1. Read it fully (view referenced images separately if any — one pass can't read
   inline images).
2. Discuss key takeaways with the human if they're in the loop.
3. Write/update a **source summary** page (`type: Reference`, with `sources`).
4. **Propagate:** update every entity/concept page the source touches — a single
   source often edits 10–15 pages. Add/strengthen cross-links. Flag contradictions
   explicitly on the affected page ("Source X (2026) contradicts the earlier claim
   from Y…") rather than silently overwriting.
5. Update the relevant `index.md` and append a `log.md` entry.
6. Set `generated`/`stale_after`; add `verified: {by: "human:…"}` only if the human
   confirmed.
7. **Resync** (`kill -USR1`) so it shows up in the running wiki.

**Query.** Read `index.md` → drill into relevant pages → synthesize with citations
(footnotes keyed to `sources[].id`). **File good answers back into the wiki** as new
pages (a comparison, an analysis, a discovered connection) so exploration compounds
— then update `index.md`/`log.md` and resync. Don't let insight vanish into chat.

**Lint / health check.** Periodically sweep for: contradictions between pages; stale
claims (esp. past `stale_after`); orphan pages (no inbound links); important
concepts mentioned but lacking a page; missing cross-references; `sources`-less
claims. Propose new questions and sources to fill gaps. Report findings; apply fixes
with the human's direction; resync.

---

## 9. OKF conformance checklist (per page, before resync)

- [ ] Frontmatter parses as YAML and has a non-empty `type`.
- [ ] Dates/datetimes are **quoted** strings.
- [ ] `generated.by` present; actor convention used (`agent/ver`, `human:id`,
      `process:id`). `verified` only where a real check happened.
- [ ] `sources` entries have a `resource`; ids used by any footnote citations.
- [ ] Links are standard markdown, bundle-relative (`/…/page.md`) where possible.
- [ ] `status` set when not the default `stable`; `stale_after` on expiring facts.
- [ ] `tags` used (serves LeafWiki + OKF at once).
- [ ] `index.md` and `log.md` updated for this change.

---

## 10. Advanced: Attested Computations (OKF §10)

If a page reports a number that must be reproducibly computed (a metric, a query
result), model it as an OKF `type: Attested Computation` page — a standalone concept
carrying `runtime`, `parameters`, an `executor`, an `attester`, and the computation
under a `# Computation` fenced block. Concepts that *use* the value link to it. These
keys all live in LeafWiki's preserved `ExtraFields`, so such pages render fine in the
wiki and stay OKF-attestable. Reach for this only when reproducibility of a figure
matters; for narrative knowledge, the §6 template is enough. See the OKF spec §10 for
the full contract and worked example.

---

## 11. Don'ts

- **Don't edit files and forget to resync** — the wiki won't reflect them.
- **Don't create a `<slug>.md` and `<slug>/` with the same name** — hard conflict.
- **Don't put raw sources inside `root/`** — they'd become editable wiki pages.
- **Don't touch `users.db`, `*.db-wal`, `snapshots/`** by hand — use the server /
  `restore-snapshot` for recovery.
- **Don't hand-write `leafwiki_*` timestamps or fake `verified: {by: human:…}`** —
  let LeafWiki manage its keys; only record verification that actually occurred.
- **Don't leave OKF dates unquoted** — they may be reformatted on round-trip.
