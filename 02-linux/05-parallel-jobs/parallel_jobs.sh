#!/bin/bash
# parallel_jobs.sh - compress files one by one, then in parallel, and compare the time
# Usage: ./parallel_jobs.sh [NUMBER_OF_FILES]
set -euo pipefail

FILES="${1:-6}"
WORK="/tmp/parallel_demo"

rm -rf "$WORK"
mkdir -p "$WORK"

echo "Creating $FILES test files (~10 MB each)..."
for i in $(seq 1 "$FILES"); do
  head -c 7500000 /dev/urandom | base64 > "$WORK/file_$i.txt"
done

# one by one
start=$(date +%s.%N)
for f in "$WORK"/*.txt; do
  gzip -kf "$f"
done
end=$(date +%s.%N)
serial=$(awk -v s="$start" -v e="$end" 'BEGIN {printf "%.2f", e - s}')

rm -f "$WORK"/*.gz

# all at the same time
start=$(date +%s.%N)
for f in "$WORK"/*.txt; do
  gzip -kf "$f" &
done
wait
end=$(date +%s.%N)
parallel=$(awk -v s="$start" -v e="$end" 'BEGIN {printf "%.2f", e - s}')

echo
echo "CPU cores : $(nproc)"
echo "Serial    : ${serial}s"
echo "Parallel  : ${parallel}s"
awk -v a="$serial" -v b="$parallel" 'BEGIN {printf "Speedup   : %.2fx\n", a / b}'
