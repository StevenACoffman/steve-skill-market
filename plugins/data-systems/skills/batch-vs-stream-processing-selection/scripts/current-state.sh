#!/bin/sh
# Read-only snapshot of the repository for the batch-vs-stream-processing-selection skill.
# Run it from the root of the repository the skill is being applied to.
# Every command only reads files.

echo "== Pub/Sub topics and subscriptions (streaming entry points)"
grep -rn 'pubsub\|PubSub\|topic\|subscription' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8
echo

echo "== Batch/cron job patterns"
grep -rn 'cron\|batch\|job\|scheduler' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo

echo "== Event log / Kafka / stream processing references"
grep -rn 'kafka\|stream\|eventlog\|event_log' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5
echo
