#!/bin/sh
# Read-only snapshot of the repository for the replication-topology-selection skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Database connection configuration"
grep -rn 'dsn\|DSN\|DATABASE_URL\|postgres\|Postgres\|datastore\|Datastore' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Multi-region or replica endpoint references"
grep -rn 'region\|replica\|primary\|secondary\|failover\|ReadReplica' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Cloud Datastore usage (managed replication)"
grep -rln 'cloud\.google\.com/go/datastore' --include='*.go' . 2>/dev/null | head -5
echo
