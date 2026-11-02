#!/bin/sh
# Read-only snapshot of the repository for the consistency-model-selection skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Cache reads (potential stale-read sources)"
grep -rn 'cache\|Cache\|memcache\|redis\|Redis' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Strong-consistency read paths (Datastore, SQL)"
grep -rn 'datastore\|Datastore\|pgx\|sqlc\|sql\.DB' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Replica or read-replica references"
grep -rn 'replica\|readOnly\|read_only\|secondary' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
