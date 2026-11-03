#!/bin/sh
# Read-only snapshot of the repository for the sharding-strategy-selection skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Partition key or shard key patterns"
grep -rn 'shard\|Shard\|partition\|Partition\|bucket\|Bucket' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Hot-key or load distribution concerns"
grep -rn 'hotkey\|hot_key\|loadbalance\|hash.*key\|consistent.*hash' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
