# Cleaning Pipeline

A small Python package I made to clean messy data files with pandas.
It reads CSV, JSON or Parquet files (or JSON from an API), cleans the data,
and saves the result in any of those formats.

## Setup
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
```

## How to run
```bash
python -m cleaner.pipeline sample_data/orders_raw.csv output/orders_clean.csv \
  --dates order_date \
  --numbers quantity,unit_price \
  --required order_id,customer_email \
  --fill status=pending
```

| Option | What it does |
|--------|--------------|
| `--dates` | columns to convert to dates |
| `--numbers` | columns to convert to numbers |
| `--required` | rows missing any of these columns are dropped |
| `--fill` | default values for empty cells, e.g. `status=pending` |

It can also be used from Python:
```python
from cleaner.pipeline import run_pipeline

df = run_pipeline("sample_data/orders_raw.csv", "output/orders_clean.parquet",
                  date_cols=["order_date"], required_cols=["customer_email"])
```

## Cleaning steps
1. **standardize_columns**: `" Order ID "` becomes `order_id`
2. **strip_text**: removes extra spaces, and empty text becomes NaN
3. **drop_duplicates**: removes repeated rows
4. **convert_types**: converts dates and numbers, and bad values like `abc` become NaN
5. **fill_missing**: fills empty cells with default values
6. **drop_missing**: removes rows missing important columns

Every step logs what it did, for example how many rows were removed.

## Result on the sample data
`sample_data/orders_raw.csv` is deliberately messy. 7 rows go in, 5 come out:
- the duplicate of order 2 is removed
- order 4 is dropped because it has no email
- the bad date, quantity `abc` and blank price become empty values
- the empty status of order 3 becomes `pending`

Numbers like quantity show as `2.0` in the output because a number column
with empty values becomes float in pandas.

## Tests
```bash
pytest -v
```
11 tests: one for each cleaning step, reading/writing CSV and Parquet,
a wrong file type, the API reader (using a fake response so no internet
is needed), and the full pipeline on the sample data.

## Folder structure
```
cleaner/
  file_io.py     read/write files, read from API
  clean.py       cleaning functions
  pipeline.py    runs all steps, command line
tests/
  test_clean.py
sample_data/
  orders_raw.csv
```
