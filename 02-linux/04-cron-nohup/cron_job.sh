#!/bin/bash
# cron_job.sh - job to run from cron: takes a resource reading and checks the log
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$HOME/cron_job.log"

echo "$(date '+%F %T') START" >> "$LOG"

"$DIR/03-resource-monitor/monitor.sh" "$HOME/metrics.csv" 1 1 >> "$LOG" 2>&1

"$DIR/01-log-parser/log_parser.sh" "$DIR/01-log-parser/sample.log" 5 >> "$LOG" 2>&1 \
  || echo "$(date '+%F %T') log parser raised an alert" >> "$LOG"

echo "$(date '+%F %T') END" >> "$LOG"
