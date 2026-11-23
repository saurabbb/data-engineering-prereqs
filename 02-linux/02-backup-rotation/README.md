# Backup with Rotation

Creates a timestamped `.tar.gz` backup of a folder and keeps only the newest N backups.

## Usage
```bash
./backup.sh ~/data-engineering-prereqs/01-sql ~/backups 5
```
- 1st argument: folder to back up (required)
- 2nd argument: where to save backups (default `~/backups`)
- 3rd argument: how many to keep (default 5)

Every action is logged to `backup.log` in the backup folder.
Backup files get `chmod 600`, so only the owner can read them.

Restore:
```bash
tar -xzf ~/backups/01-sql_20261123_120000.tar.gz -C /tmp
```

Uses: tar, date, ls -t, tail, chmod, tee
