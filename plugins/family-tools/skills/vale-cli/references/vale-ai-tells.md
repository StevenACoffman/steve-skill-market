# The `vale-ai-tells` Package (Cleaning up AI-Assisted Writing)

[`vale-ai-tells`](https://github.com/StevenACoffman/vale-ai-tells) helps clean up AI-assisted
technical documentation. It ships two styles as separate release zips so you can opt into
each independently:

- **`ai-tells`** — prose rules for docs, READMEs, and articles.
- **`ai-tells-commits`** — 13 rules tuned for commit messages. It is deliberately kept
  apart from the prose style so you can lint commit messages without pulling those checks
  into your documentation (and vice versa). Pair this with the `unconventional-commits`
  skill to polish commit prose.

Because it is a third-party package, `Packages =` needs full release-zip URLs rather than
a bare hub name. Pin a specific version rather than tracking `latest`, so `vale sync` is
reproducible and a new upstream release can't silently change your lint results.

**Step 1 — make sure Vale itself is installed** (see [Quick Start](../SKILL.md#quick-start); on
macOS `brew install vale`). The version-discovery step below also needs `curl`.

**Step 2 — discover the latest release tag** and print the two lines to append to
`Packages =`. This follows GitHub's `/releases/latest` redirect to learn the current tag
(for example `v1.26.0`) without hardcoding it:

```bash
#!/bin/bash
# Discover the latest vale-ai-tells release and print the `Packages =` value.
gh-find-latest() {
  local owner=$1 project=$2
  local release_url=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/${owner}/${project}/releases/latest")
  export release_tag=$(basename $release_url)
}

gh-find-latest StevenACoffman vale-ai-tells
echo "https://github.com/StevenACoffman/vale-ai-tells/releases/download/${release_tag}/ai-tells.zip, \\
  https://github.com/StevenACoffman/vale-ai-tells/releases/download/${release_tag}/ai-tells-commits.zip"
```

**Step 3 — write `.vale.ini`** with both packages pinned to that tag. If a user has no
existing `.vale.ini` and wants to lint a commit message in a scratch directory (with the
latest release being `v1.26.0`), this is the recommended config to create:

```ini
StylesPath = styles
MinAlertLevel = suggestion

Packages = https://github.com/StevenACoffman/vale-ai-tells/releases/download/v1.26.0/ai-tells.zip, \
  https://github.com/StevenACoffman/vale-ai-tells/releases/download/v1.26.0/ai-tells-commits.zip

[*.md]
BasedOnStyles = ai-tells, ai-tells-commits
```

To lint **only** commit messages (not docs), list just `ai-tells-commits` in
`BasedOnStyles`; to lint **only** prose, list just `ai-tells`. Both are shown together
above because the scratch-directory workflow drafts the commit message as a `.md` file and
wants both the prose and commit checks.

**Step 4 — sync** to download the packages into `StylesPath`:

```bash
vale sync
```

Then lint the message — pass `--no-global` so this self-contained config isn't merged with
your global platform config (otherwise global styles like `Readability` and spelling leak
in and bury the AI-tell alerts):

```bash
vale --config="$SCRATCH/.vale.ini" --no-global "$SCRATCH/COMMIT_EDITMSG.md"
```

For the end-to-end commit-message lint-and-fix loop, see the **`vale`** skill.
