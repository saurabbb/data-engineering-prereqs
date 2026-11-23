# Parallel Jobs

Creates test files and compresses them twice: first one by one, then all at
the same time using `&` and `wait`. Then it prints both times and the speedup.

## Usage
```bash
./parallel_jobs.sh 6
```
- 1st argument: number of test files (default 6, about 10 MB each)

## How it works
- `gzip file &` starts each compression in the background
- `wait` waits until all background jobs are finished
- Time is measured with `date +%s.%N` before and after

The speedup depends on the number of CPU cores on the VM (`nproc`).
With 1 core there is no speedup.

For many files, `xargs -P 4` can limit how many jobs run at once:
```bash
ls /tmp/parallel_demo/*.txt | xargs -P 4 -n 1 gzip -kf
```

Uses: &, wait, gzip, seq, nproc, date, awk
