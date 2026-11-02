#!/bin/sh
# Read-only snapshot of the repository for the test-helper-process-subprocess-mock skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== exec.Command usage in production code (subprocess calls to mock)"
grep -rn 'exec\.Command\|exec\.CommandContext' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Existing subprocess mock patterns"
grep -rn 'GO_WANT_HELPER_PROCESS\|TestHelperProcess\|helperProcess' --include='*.go' . 2>/dev/null | grep -v vendor | head -5
echo

echo "== os.Exec or os/exec imports"
grep -rln '"os/exec"' --include='*.go' . 2>/dev/null | grep -v vendor | head -5
echo
