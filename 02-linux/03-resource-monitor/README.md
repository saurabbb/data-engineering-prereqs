# Resource Monitor → CSV

Records CPU, memory, disk and load average at a fixed interval and appends
each reading as a row in a CSV file.

## Usage
```bash
./monitor.sh resource_usage.csv 5 10
```
- 1st argument: CSV file (default `resource_usage.csv`)
- 2nd argument: seconds between readings (default 5)
- 3rd argument: number of readings (default 10)

## Columns
| Column | Taken from |
|--------|-----------|
| cpu_pct | `vmstat` (100 minus idle) |
| mem_pct | `free` |
| disk_pct | `df /` |
| load_1m | `/proc/loadavg` |

The header is only written once, so running it again keeps adding to the same file.

Uses: vmstat, free, df, /proc, awk, tee
