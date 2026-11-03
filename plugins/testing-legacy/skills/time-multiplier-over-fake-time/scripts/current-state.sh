#!/bin/sh
# Read-only snapshot of the repository for the time-multiplier-over-fake-time skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Fake clock injection (interfaces spreading through production code)"
grep -rn 'Clock\|FakeClock\|MockClock\|fakeClock\|clock\.Now' --include='*.go' . 2>/dev/null | grep -v vendor | head -8
echo

echo "== time.Sleep in tests (potential flakiness source)"
grep -rn 'time\.Sleep' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -8
echo

echo "== timeMultiplier pattern already in use"
grep -rn 'timeMultiplier\|TimeMultiplier\|time\.Duration(1)' --include='*.go' . 2>/dev/null | grep -v vendor | head -5
echo

echo "== select + time.After timeout patterns in tests"
grep -rn 'time\.After\|time\.NewTimer' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -5
echo
