#!/bin/sh
# Read-only snapshot of the repository for the system-of-record-vs-derived-data skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Dual-write patterns (writing to two systems in the same function)"
grep -rn -A2 '\.Put(\|\.Upsert(\|\.Insert(' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | grep -c '\.Put(\|\.Upsert(\|\.Insert(' || true
echo

echo "== Cache invalidation on write"
grep -rn 'cache\|Cache' --include='*.go' . 2>/dev/null | grep -i 'delete\|invalidat\|flush\|evict\|clear' | grep -v '_test.go\|vendor' | head -5
echo

echo "== Derived/secondary storage that mirrors primary"
grep -rn 'sync\|Sync\|replicate\|Replicate\|propagate\|Propagate' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
