#!/bin/sh
# Read-only snapshot of the repository for the go-http-service-di-composition skill.
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

echo "== run() functions"
grep -rn '^func run(' --include='*.go' . 2>/dev/null | head -5
echo

echo "== Application/server struct definitions"
grep -rn '^type application struct\|^type app struct\|^type server struct\|^type Server struct' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -5
echo

echo "== Package-level vars (global state risk)"
grep -rn '^var ' --include='*.go' . 2>/dev/null | grep -v '_test.go\|_gen.go' | head -10
echo
