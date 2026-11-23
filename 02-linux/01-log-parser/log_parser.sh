#!/bin/bash
# log_parser.sh - count errors in a log file and alert if there are too many
# Usage: ./log_parser.sh [LOG_FILE] [THRESHOLD]
set -euo pipefail

LOG_FILE="${1:-sample.log}"
THRESHOLD="${2:-5}"
ALERT_FILE="alerts.log"

if [ ! -f "$LOG_FILE" ]; then
  echo "Log file not found: $LOG_FILE"
  exit 1
fi

errors=$(grep -c " ERROR " "$LOG_FILE" || true)
warnings=$(grep -c " WARN " "$LOG_FILE" || true)

echo "Log file : $LOG_FILE"
echo "Errors   : $errors"
echo "Warnings : $warnings"

echo
echo "Top error messages:"
grep " ERROR " "$LOG_FILE" | cut -d' ' -f6- | sort | uniq -c | sort -rn || true

echo
echo "IPs with most errors/warnings:"
grep -E " (ERROR|WARN) " "$LOG_FILE" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -rn || true

if [ "$errors" -gt "$THRESHOLD" ]; then
  echo
  echo "$(date '+%F %T') ALERT: $errors errors in $LOG_FILE (limit $THRESHOLD)" | tee -a "$ALERT_FILE"
  exit 2
fi

echo
echo "OK: errors are within the limit"

