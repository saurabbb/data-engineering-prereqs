# Data Engineering Prerequisites

My work for the prerequisite assignments of the 6-week Data Engineering Program.
It covers three areas: SQL, Linux shell scripting, and Python with pandas.

## Repository structure
```
data-engineering-prereqs/
├── 01-sql/        MySQL schema, seed data, queries, EXPLAIN analysis
├── 02-linux/      5 bash utility scripts
└── 03-python/     data cleaning package with tests, pandas exercises
```

## 01 - SQL & Relational Databases
[Go to folder](01-sql)

- Normalized (3NF) e-commerce database `shop_db` with 6 tables
- Seed data with 50,000 orders
- 10 queries for a business brief using joins, aggregates, CTEs and window functions
- EXPLAIN analysis of a slow query: full table scan → index range scan, 28.6 ms → 7.96 ms

**Tools:** MySQL 8, MySQL Workbench

## 02 - Linux & Shell Scripting
[Go to folder](02-linux)

| Script | What it does |
|--------|--------------|
| Log parser | Counts errors in a log file and writes an alert above a limit |
| Backup | Backs up a folder and keeps only the newest N backups |
| Resource monitor | Saves CPU, memory, disk and load to a CSV |
| Cron job | Scheduled job with cron, plus nohup and screen examples |
| Parallel jobs | Compares running tasks one by one vs in parallel |

**Tools:** bash, grep, awk, cron, nohup, screen. Tested on an Ubuntu Server VM over SSH.

## 03 - Python & pandas
[Go to folder](03-python)

- `cleaning_pipeline`: a reusable Python package that cleans CSV/JSON/Parquet files
  (column names, spaces, duplicates, types, missing values), with logging,
  a command line interface and 11 pytest tests
- `pandas_exercises`: solutions to guipsamora/pandas_exercises (in progress)

**Tools:** Python, pandas, pyarrow, requests, pytest, venv

## Git workflow
Each module was built on its own feature branch (`feature/sql-...`,
`feature/linux-...`, `feature/python-...`) and merged into `main` when finished.

## Certificates
- HackerRank SQL(basic,intermediate)


## Author
Saurab Kharel
