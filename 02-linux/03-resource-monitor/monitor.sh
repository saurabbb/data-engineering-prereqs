#!/bin/bash
# monitor.sh - write CPU, memory, disk and load usage to a CSV file
# Usage: ./monitor.sh [OUTPUT_CSV] [INTERVAL_SECONDS] [COUNT]
set -euo pipefail

OUTPUT="${1:-resource_usage.csv}"
INTERVAL="${2:-5}"
COUNT="${3:-10}"

if [ ! -f "$OUTPUT" ]; then
  echo "timestamp,cpu_pct,mem_pct,disk_pct,load_1m" > "$OUTPUT"
fi

for ((i = 1; i <= COUNT; i++)); do
  time_now=$(date '+%F %T')
  cpu=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
  mem=$(free | awk '/Mem:/ {printf "%.1f", $3 / $2 * 100}')
  disk=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
  load=$(cut -d' ' -f1 /proc/loadavg)

  echo "$time_now,$cpu,$mem,$disk,$load" | tee -a "$OUTPUT"

  if [ "$i" -lt "$COUNT" ]; then
    sleep "$INTERVAL"
  fi
done
