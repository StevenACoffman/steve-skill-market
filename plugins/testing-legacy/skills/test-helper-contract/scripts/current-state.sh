#!/bin/sh
# Read-only snapshot of the repository for the test-helper-contract skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Test helpers that return errors instead of calling t.Fatal (anti-pattern)"
grep -rn 'func.*testing\.T.*error' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -8
echo

echo "== Helpers using the correct contract (t.Fatal + cleanup func)"
grep -rn 'func.*\*testing\.T.*func()' --include='*.go' . 2>/dev/null | grep -v vendor | head -5
echo

echo "== defer cleanup() pattern in use"
grep -rn 'defer.*()$\|, cleanup :=' --include='*_test.go' . 2>/dev/null | grep -v vendor | head -5
echo
