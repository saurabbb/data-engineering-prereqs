#!/bin/bash
# backup.sh - make a tar.gz backup of a folder and keep only the newest ones
# Usage: ./backup.sh SOURCE_DIR [DEST_DIR] [KEEP]
set -euo pipefail

SOURCE="${1:?Usage: ./backup.sh SOURCE_DIR [DEST_DIR] [KEEP]}"
DEST="${2:-$HOME/backups}"
KEEP="${3:-5}"

if [ ! -d "$SOURCE" ]; then
  echo "Folder not found: $SOURCE"
  exit 1
fi

mkdir -p "$DEST"
name=$(basename "$SOURCE")
file="$DEST/${name}_$(date +%Y%m%d_%H%M%S).tar.gz"

tar -czf "$file" -C "$(dirname "$SOURCE")" "$name"
chmod 600 "$file"
echo "$(date '+%F %T') Created $file" | tee -a "$DEST/backup.log"

# keep only the newest $KEEP backups, delete the rest
ls -1t "$DEST"/"${name}"_*.tar.gz | tail -n +$((KEEP + 1)) | while read -r old; do
  rm -f "$old"
  echo "$(date '+%F %T') Deleted old backup $old" | tee -a "$DEST/backup.log"
done
