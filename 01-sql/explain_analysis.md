# EXPLAIN Analysis - Slow Query on orders

## What I was trying to do
I wanted to get all delivered orders from Q1 2025 along with the customer's city.
My first version of the query worked and gave correct results (4,320 orders), but
when I checked it with EXPLAIN I saw it was scanning the whole orders table,
which has 50,000 rows.

## Step 1: My first query (slow)

Before running EXPLAIN I ran ANALYZE TABLE so the row estimates are up to date.

```sql
ANALYZE TABLE orders;

EXPLAIN
SELECT o.order_id, o.order_date, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2025
  AND QUARTER(o.order_date) = 1
  AND o.status = 'delivered';
```

Output I got:
```
id  select_type  table  type    possible_keys  key      key_len  ref                    rows   filtered  Extra
1   SIMPLE       o      ALL     customer_id    NULL     NULL     NULL                   50436  25.00     Using where
1   SIMPLE       c      eq_ref  PRIMARY        PRIMARY  4        shop_db.o.customer_id  1      100.00    NULL
```

For the orders table, type is ALL and key is NULL. So MySQL did not use any index.
It planned to read about 50,000 rows and check the WHERE condition on each one
("Using where"). The only possible key it saw was customer_id (the index
created for the foreign key), which doesn't help with this filter.

I found two reasons for this:

1. There was no index on status or order_date.
2. I used YEAR() and QUARTER() on the order_date column. When you put a function
   around a column in WHERE, MySQL can't use an index on that column, because it
   has to calculate the function for every row first. This is called a
   non-sargable condition.

EXPLAIN ANALYZE confirmed it:
```
-> Nested loop inner join  (cost=19052 rows=12609) (actual time=4.53..28.6 rows=4320 loops=1)
    -> Filter: ((o.status = 'delivered') and (year(o.order_date) = 2025) and (quarter(o.order_date) = 1))
       (cost=5182 rows=12609) (actual time=2.58..21.9 rows=4320 loops=1)
        -> Table scan on o  (cost=5182 rows=50436) (actual time=2.49..17.2 rows=50000 loops=1)
    -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)
       (cost=1 rows=1) (actual time=0.0014..0.00141 rows=1 loops=4320)
```
It actually read all 50,000 rows to return only 4,320. Also, the optimizer
estimated 12,609 matching rows, almost 3x the real number, because it can't
estimate well through functions like YEAR() and QUARTER().

## Step 2: What I changed

First I added a composite index:

```sql
CREATE INDEX idx_orders_status_date ON orders (status, order_date);
```

I put status first because I filter it with "=", and order_date second because
I filter it with a range. With this order MySQL can jump straight to
status = 'delivered' and then read only the date range inside that part.

Then I rewrote the date filter as a normal range, without functions:

```sql
EXPLAIN
SELECT o.order_id, o.order_date, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'delivered'
  AND o.order_date >= '2025-01-01'
  AND o.order_date <  '2025-04-01';
```

I used < '2025-04-01' instead of <= '2025-03-31' because order_date is DATETIME,
and <= '2025-03-31' would miss orders placed later on 31 March.

Output after the change:
```
id  select_type  table  type    possible_keys                       key                     key_len  ref                    rows  filtered  Extra
1   SIMPLE       o      range   customer_id,idx_orders_status_date  idx_orders_status_date  6        NULL                   4320  100.00    Using index condition
1   SIMPLE       c      eq_ref  PRIMARY                             PRIMARY                 4        shop_db.o.customer_id  1     100.00    NULL
```

Now type is range and key is idx_orders_status_date. The rows estimate went
from 50,436 down to 4,320, which is exactly the real result count, so the
optimizer's estimate is now accurate too. key_len is 6, which means both columns
of the index are used: 1 byte for the status ENUM plus 5 bytes for the DATETIME.
The customers table uses eq_ref because it joins on the primary key, so that
part was already fine.

EXPLAIN ANALYZE after the change:
```
-> Nested loop inner join  (cost=3456 rows=4320) (actual time=0.508..7.96 rows=4320 loops=1)
    -> Index range scan on o using idx_orders_status_date
       over (status = 'delivered' AND '2025-01-01 00:00:00' <= order_date < '2025-04-01 00:00:00')
       (cost=1944 rows=4320) (actual time=0.501..4.37 rows=4320 loops=1)
    -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)
       (cost=0.25 rows=1) (actual time=725e-6..740e-6 rows=1 loops=4320)
```

## Step 3: Comparison

| Version | Access type      | Rows read from orders | Estimated cost | Actual time |
|---------|------------------|-----------------------|----------------|-------------|
| Before  | ALL (full scan)  | 50,000                | 19,052         | 28.6 ms     |
| After   | range (index)    | 4,320                 | 3,456          | 7.96 ms     |

The fixed query reads about 11x fewer rows and ran about 3.6x faster.

## Step 4: Was it the index or the rewrite?

To check, I ran EXPLAIN on my original query (with YEAR/QUARTER) again, after
the index already existed:

```
id  select_type  table  type    possible_keys                       key                     key_len  ref    rows   filtered  Extra
1   SIMPLE       o      ref     customer_id,idx_orders_status_date  idx_orders_status_date  1        const  25218  100.00    Using index condition
1   SIMPLE       c      eq_ref  PRIMARY                             PRIMARY                 4        shop_db.o.customer_id  1  100.00  NULL
```

This time it used the index, but key_len is only 1, so it used only the status
part. It found all ~25,000 delivered orders and still had to check YEAR() and
QUARTER() on each one. So the index alone only helped half-way. Rewriting the
date condition as a range is what let MySQL use the order_date part of the
index and go from ~25,000 rows down to 4,320.

## What I learned
- Don't put functions around a column in WHERE if you want an index to be used.
  Use a date range with >= and < instead.
- For a composite index, put the "=" columns first and the range column last.
- key_len in EXPLAIN tells you how much of a composite index is actually being used.
- Functions in WHERE also make the optimizer's row estimates wrong
  (12,609 estimated vs 4,320 actual), which can lead to bad plans in bigger queries.
- Indexes are not free. Every index makes INSERT and UPDATE a bit slower and uses
  extra space, so I only added one for a query pattern I actually use.
- With 50,000 rows the difference is milliseconds, but a full scan keeps growing
  with the table while the index range scan stays close to the size of the result.
