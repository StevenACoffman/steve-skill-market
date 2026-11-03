#!/bin/sh
# Read-only snapshot of the repository for the mdformat skill.
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

echo "== Tool and version check"
for t in uv mdformat shfmt gofmt; do
    if has_cmd "$t"; then
        echo "$t ok ($("$t" --version 2>/dev/null || echo version unknown))"
    else
        echo "$t MISSING"
    fi
done
echo
