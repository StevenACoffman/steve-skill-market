#!/bin/sh
# Read-only snapshot of the repository for the timeliness-vs-integrity-distinction skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Eventual consistency or async propagation patterns"
grep -rn 'async\|Async\|eventual\|background\|goroutine\|go func' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Integrity constraints (foreign keys, unique checks)"
grep -rn 'UNIQUE\|FOREIGN KEY\|CHECK\|NOT NULL\|constraint\|Constraint' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Stale-read tolerance annotations or comments"
grep -rn 'stale\|eventual\|approximate\|best.effort\|best_effort' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
