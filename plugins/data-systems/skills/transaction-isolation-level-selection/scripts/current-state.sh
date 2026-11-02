#!/bin/sh
# Read-only snapshot of the repository for the transaction-isolation-level-selection skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== SQL transaction usage"
grep -rn 'BeginTx\|\.Begin(\|pgx\.Tx\|sql\.Tx\|WithTransaction\|RunInTransaction' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Isolation level settings"
grep -rn 'IsolationLevel\|isolation\|SERIALIZABLE\|REPEATABLE READ\|READ COMMITTED' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Check-then-act patterns (read-modify-write)"
grep -rn -A3 'SELECT.*FOR UPDATE\|\.Get(\|\.QueryRow' --include='*.go' . 2>/dev/null | grep -B1 '\.Update(\|\.Put(\|\.Exec(' | grep -v '_test.go\|vendor' | head -8
echo
