#!/bin/sh
# Read-only snapshot of the repository for the storage-engine-workload-selection skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Storage backends in use"
grep -rln 'cloud\.google\.com/go/datastore\|github\.com/jackc/pgx\|go\.mongodb\.org\|redis' --include='*.go' . 2>/dev/null | head -10
echo

echo "== OLAP / analytics query patterns"
grep -rn 'GROUP BY\|SUM(\|COUNT(\|AVG(\|analytics\|report\|aggregate' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Write-heavy vs read-heavy indicators"
grep -rn '\.Put(\|\.Upsert(\|\.Insert(\|\.Update(' --include='*.go' . 2>/dev/null | grep -cv '_test.go\|vendor'
echo
