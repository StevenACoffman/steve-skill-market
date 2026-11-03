#!/bin/sh
# Read-only snapshot of the repository for the clock-skew-ordering-hazard skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Wall-clock time usage (time.Now)"
grep -rn 'time\.Now()' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Timestamp comparisons used for ordering or conflict detection"
grep -rn '\.Before(\|\.After(\|\.Unix()\|CreatedAt\|UpdatedAt\|LastModified' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Logical clocks or vector clocks"
grep -rn 'version\|Version\|etag\|ETag\|revision\|Revision' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
