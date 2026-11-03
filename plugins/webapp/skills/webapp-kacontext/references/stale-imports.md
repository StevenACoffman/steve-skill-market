# Cleaning up Stale Imports After Context Edits

When you remove a sub-interface from a `ctx` parameter (e.g. dropping
`log.KAContext` because the function no longer logs), the corresponding import
often becomes unused. `go vet ./...` flags these as `imported and not used`.
The script below collects the offending file paths and runs `goimports -w`
on each:

```bash
#!/usr/bin/env bash
# Run `go vet ./...` from the webapp module root, collect any "imported and
# not used" errors, and apply `goimports -w` to each unique offending file.
set -u

go vet ./... 2>&1 |
	grep -E '^[^[:space:]]+\.go:[0-9]+:[0-9]+: .*imported and not used' |
	awk -F: '{print $1}' |
	sort -u |
	xargs -I{} goimports -w {}
```

**Cascading-fix variant.** Fixing one file can unblock a downstream package
that `go vet` previously refused to type-check. Loop until the output is
empty (capped to avoid an infinite loop on something the script can't fix):

```bash
#!/usr/bin/env bash
set -u

for _ in 1 2 3 4 5; do
	hits=$(go vet ./... 2>&1 |
		grep -E '^[^[:space:]]+\.go:[0-9]+:[0-9]+: .*imported and not used' |
		awk -F: '{print $1}' |
		sort -u)
	[ -z "$hits" ] && break
	xargs -I{} goimports -w {} <<<"$hits"
done
```

**Before running:**

- Commit or stash first — `goimports -w` rewrites in place.
- Ensure `goimports` is in `PATH`
  (`go install golang.org/x/tools/cmd/goimports@latest` if missing).
- Run from the webapp module root, not a subdirectory, so file paths in
  `go vet` output are resolvable from the current directory.

**Known limitation.** When `go vet` emits errors under a `# package/path`
header, the diagnostic line uses a package-relative path
(e.g. `client.go:5:2:` rather than `./pkg/foo/client.go:5:2:`). The script
won't find those files and `goimports` will print "no such file" for them;
the rest of the batch still completes. Re-run from the affected package
directory, or fix those by hand.
