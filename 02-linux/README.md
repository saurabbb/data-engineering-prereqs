# 02 - Linux & Shell Scripting

Five bash scripts for common pipeline tasks, tested on a Linux VM that I access over SSH.

## Setup
- VM: Ubuntu Server on VMware Workstation Pro


```bash
ssh saurab@<vm-ip>
```

## Scripts
| # | Script | What it does |
|---|--------|--------------|
| 1 | `01-log-parser/log_parser.sh` | Counts errors in a log and writes an alert above a limit |
| 2 | `02-backup-rotation/backup.sh` | Backs up a folder and keeps only the newest N backups |
| 3 | `03-resource-monitor/monitor.sh` | Saves CPU, memory, disk and load to a CSV |
| 4 | `04-cron-nohup/cron_job.sh` | Job run by cron, plus examples with nohup and screen |
| 5 | `05-parallel-jobs/parallel_jobs.sh` | Compares compressing files one by one vs in parallel |

Each folder has its own README.

