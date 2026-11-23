# 01 - SQL & Relational Databases

This folder has my practice database for the SQL part of the prerequisites.
I designed a small e-commerce database called `shop_db` in MySQL 8, filled it
with test data, wrote 10 queries for a mini business brief, and did an EXPLAIN
analysis on one slow query.

## Files

| File | What it contains |
|------|------------------|
| `schema.sql` | Creates the database and 6 tables with primary keys, foreign keys, UNIQUE and CHECK constraints |
| `seed.sql` | Inserts test data: 6 categories, 24 products, 500 customers, 50k orders, ~100k order items, ~42.5k payments |
| `queries.sql` | 10 queries answering business questions (joins, aggregates, CTEs, window functions) |
| `explain_run.sql` | The statements I ran for the EXPLAIN analysis |
| `explain_analysis.md` | My analysis of a slow query, the fix, and before/after results |

## Data model

```
customers 1 ──< orders 1 ──< order_items >── 1 products >── 1 categories
                   │
                   └──< payments
```

- One customer can have many orders.
- One order can have many order items, and one product can be in many orders.
- Each product belongs to one category.
- An order can have one or more payments.

## Normalization (3NF)

- **1NF:** every column holds a single value, and every table has a primary key.
- **2NF:** no column depends on only part of a key. `order_items` has its own
  `order_item_id`, plus `UNIQUE(order_id, product_id)` so the same product
  can't appear twice in one order.
- **3NF:** no column depends on another non-key column. Category names live
  only in `categories`, and customer details live only in `customers`. Orders
  just store the `customer_id`.

`order_items.unit_price` looks like it duplicates `products.unit_price`, but it
doesn't. It stores the price at the time of sale. If a product's price changes
later, old orders should still show what the customer actually paid.

## Test data

The seed data is generated with recursive CTEs instead of `RAND()`, so it's the
same every time it runs. The data has a few things built in on purpose:

- Orders are spread from January 2025 to around October 2026.
- Order status is a mix of delivered, shipped, pending and cancelled.
- Only shipped and delivered orders have payments.
- Customers 481-500 have no orders (used to test query 4).
- Payment amounts always match the order total (query 10 should return 0 rows).

## How to run

```bash
sudo mysql < schema.sql
sudo mysql < seed.sql
sudo mysql shop_db < queries.sql
```

You can also open the files in MySQL Workbench and run them there.
`seed.sql` ends with a row count for each table, so you can check that
everything loaded.

## Queries

| # | Question | What it uses |
|---|----------|--------------|
| 1 | Monthly revenue and order count for 2025 | JOIN, GROUP BY |
| 2 | Top 5 customers by total spend | multiple JOINs, aggregate, LIMIT |
| 3 | Revenue per category and % of total | window function over an aggregate |
| 4 | Customers who never ordered | LEFT JOIN with IS NULL |
| 5 | Latest order for each customer | CTE, ROW_NUMBER |
| 6 | Month-over-month revenue growth | CTE, LAG, named window |
| 7 | Running revenue total per city | SUM() OVER with PARTITION BY |
| 8 | Top 3 products in each category | two CTEs, DENSE_RANK |
| 9 | Payment method breakdown | aggregate, window % |
| 10 | Orders where payment doesn't match the item total | CTEs, data quality check |

Revenue in these queries means `quantity × unit_price` for orders that are
shipped or delivered.

## EXPLAIN analysis (summary)

My query for delivered orders in Q1 2025 used `YEAR()` and `QUARTER()` on
`order_date`, so MySQL scanned all 50,000 rows. I added an index on
`(status, order_date)` and rewrote the filter as a date range. The plan changed
from a full table scan to an index range scan, and it read 4,320 rows instead
of 50,000. Execution time went from 28.6 ms to 7.96 ms.
Full details are in [explain_analysis.md](explain_analysis.md).


