#!/bin/sh
# Read-only snapshot of the repository for the grpc-test-pyramid-interceptors-and-infrastructure skill.
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

echo "== bufconn usage (interceptor integration tests)"
grep -rn 'bufconn\|google.golang.org/grpc/test/bufconn' --include='*.go' . 2>/dev/null | head -5
echo

echo "== testcontainers usage (infrastructure tests)"
grep -rn 'testcontainers\|testcontainers-go' --include='*.go' . 2>/dev/null | head -5
echo

echo "== grpc.NewServer in tests (unit tier)"
grep -rn 'grpc\.NewServer()' --include='*_test.go' . 2>/dev/null | head -5
echo
