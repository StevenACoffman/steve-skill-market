#!/bin/sh
# Read-only snapshot of the repository for the domain-repository-contract skill.
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

echo "== Current branch"
if has_cmd git; then
    git branch --show-current 2>/dev/null
else
    echo "git not found"
fi
echo

echo "== Repository interface declarations"
grep -rn 'type.*Repository interface\|type.*Repo interface\|type.*Store interface' --include='*.go' . 2>/dev/null | head -10
echo

echo "== Domain files importing infra packages"
grep -rn '".*postgres\|".*mongo\|".*mysql\|".*datastore' --include='*.go' . 2>/dev/null | grep -v '_test.go\|infrastructure\|store\|cmd/' | head -10
echo
