#!/bin/sh
# Read-only snapshot of the repository for the replication-lag-as-correctness skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Read-after-write patterns (user reads own data immediately after write)"
grep -rn 'Get.*After\|read.*write\|ReadYour\|afterCreate\|afterUpdate' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Database read paths (potential replica reads)"
grep -rn '\.Query\|\.QueryRow\|\.Get\|\.Select' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Replication lag handling or stale-read guards"
grep -rn 'lag\|stale\|consistency\|ReadConsistency\|StrongRead' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
