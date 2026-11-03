#!/bin/sh
# Read-only snapshot of the repository for the testing-go-public-test-api skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== testing.go files (public test API exported for other packages)"
find . -name 'testing.go' -not -path '*/vendor/*' 2>/dev/null
echo

echo "== Test helpers defined only in \_test.go (not importable by other packages)"
find . -name '*_test.go' -not -path '*/vendor/*' -exec grep -l 'func Test\|func New.*testing\.T\|func Setup' {} + 2>/dev/null | head -8
echo

echo "== Packages that import test helpers from sibling packages"
grep -rn '".*test\|testutil\|testhelper\|testing"' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
