# Log Parser with Alerts

Counts ERROR and WARN lines in a log file, shows the most common errors and IPs,
and writes an alert to `alerts.log` if errors are above a limit.

## Usage
```bash
./log_parser.sh sample.log 5
```
- 1st argument: log file (default `sample.log`)
- 2nd argument: error limit (default 5)

Exit code is 2 when an alert is raised, so cron or another script can check it.
`sample.log` has 7 errors, so it raises an alert.

Uses: grep, regex (`grep -oE` for IPs), cut, sort, uniq, pipes, tee
