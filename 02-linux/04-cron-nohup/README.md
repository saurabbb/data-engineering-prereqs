# Cron Job with nohup / screen

`cron_job.sh` takes one resource reading (saved to `~/metrics.csv`) and runs the
log parser. Everything is logged to `~/cron_job.log`.

## 1. Run with cron (every 5 minutes)
```bash
crontab -e
```
Add this line:
```
*/5 * * * * /home/saurab/data-engineering-prereqs/02-linux/04-cron-nohup/cron_job.sh
```
Check:
```bash
crontab -l
tail -f ~/cron_job.log
```

## 2. Run in the background with nohup
The job keeps running after I log out of SSH:
```bash
nohup ../03-resource-monitor/monitor.sh ~/long_run.csv 10 100 > ~/nohup.out 2>&1 &
echo $!              # process ID
ps aux | grep monitor
kill <PID>           # stop it
```

## 3. Run inside screen
```bash
sudo apt install screen -y
screen -S monitor
../03-resource-monitor/monitor.sh ~/screen_run.csv 5 50
# Ctrl+A then D to detach
screen -ls           # list sessions
screen -r monitor    # come back to it
```

## Difference
- **cron**: runs on a schedule by itself
- **nohup**: keeps a job running after logout
- **screen**: keeps a session you can come back to and watch

Uses: crontab, nohup, &, $!, ps, kill, screen, redirection (`>>`, `2>&1`)
