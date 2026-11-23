USE shop_db;
ANALYZE TABLE orders;

-- BEFORE (slow)
EXPLAIN
SELECT o.order_id, o.order_date, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2025 AND QUARTER(o.order_date) = 1 AND o.status = 'delivered';

EXPLAIN ANALYZE
SELECT o.order_id, o.order_date, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2025 AND QUARTER(o.order_date) = 1 AND o.status = 'delivered';

-- FIX
CREATE INDEX idx_orders_status_date ON orders (status, order_date);
ANALYZE TABLE orders;

-- AFTER (fixed)
EXPLAIN
SELECT o.order_id, o.order_date, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'delivered' AND o.order_date >= '2025-01-01' AND o.order_date < '2025-04-01';

EXPLAIN ANALYZE
SELECT o.order_id, o.order_date, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'delivered' AND o.order_date >= '2025-01-01' AND o.order_date < '2025-04-01';

-- CHECK: old query with the index present
EXPLAIN
SELECT o.order_id, o.order_date, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2025 AND QUARTER(o.order_date) = 1 AND o.status = 'delivered';
