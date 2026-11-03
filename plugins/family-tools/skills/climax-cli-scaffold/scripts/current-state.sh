#!/bin/sh
# Read-only snapshot of the repository for the climax-cli-scaffold skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

# has_cmd NAME — true if NAME is an executable file on $PATH.
# Ignores shell functions, aliases, and builtins of the same name.
has_cmd() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        builtin whence -p -- "$1" >/dev/null 2>&1
    elif [ -n "${BASH_VERSION:-}" ]; then
        builtin type -P -- "$1" >/dev/null 2>&1
    else
        command -v -- "$1" >/dev/null 2>&1
    fi
}

echo "== climax installed"
if has_cmd climax; then
    echo "climax ok"
else
    echo "climax not found; install: go install github.com/StevenACoffman/climax@latest"
fi
echo

echo "== Is this a climax app (climax markers in cmd/cmd.go)"
grep -l 'climax:name\|climax:root-pkg\|register new commands here' cmd/cmd.go 2>/dev/null && echo "yes" || echo "no (or cmd/cmd.go not present)"
echo

echo "== Commands registered"
grep 'New(' cmd/cmd.go 2>/dev/null | grep -v '//' | head -10
echo

echo "== go.mod module path"
grep '^module' go.mod 2>/dev/null || echo "no go.mod found"
echo

echo "== Lint status"
if has_cmd climax; then
    climax lint . 2>/dev/null || echo "(not a climax app)"
else
    echo "(climax not installed)"
fi
echo
