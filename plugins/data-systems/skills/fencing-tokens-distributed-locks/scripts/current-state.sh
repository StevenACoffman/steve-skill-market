#!/bin/sh
# Read-only snapshot of the repository for the fencing-tokens-distributed-locks skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Distributed lock or mutex usage"
grep -rn 'sync\.Mutex\|sync\.RWMutex\|lock\|Lock\|distributed' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Optimistic concurrency / version checks"
grep -rn 'compare.*swap\|CAS\|version\|etag\|ETag\|revision' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Leader election or singleton job guards"
grep -rn 'leader\|election\|singleton\|once\|Once' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
