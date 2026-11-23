-- =========================================
-- shop_db : mini brief - 10 business questions
-- =========================================
USE shop_db;

-- Q1. Monthly revenue and order count for 2025.            [JOIN, aggregate]
SELECT DATE_FORMAT(o.order_date, '%Y-%m')   AS month,
       COUNT(DISTINCT o.order_id)           AS orders,
       SUM(oi.quantity * oi.unit_price)     AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status IN ('shipped','delivered')
  AND o.order_date >= '2025-01-01' AND o.order_date < '2026-01-01'
GROUP BY month
ORDER BY month;

-- Q2. Top 5 customers by lifetime spend.                    [multi-JOIN, aggregate, LIMIT]
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS customer,
       c.city,
       COUNT(DISTINCT o.order_id)             AS orders,
       SUM(oi.quantity * oi.unit_price)       AS lifetime_spend
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.status IN ('shipped','delivered')
GROUP BY c.customer_id, c.first_name, c.last_name, c.city
ORDER BY lifetime_spend DESC
LIMIT 5;

-- Q3. Revenue per category and its share of total revenue.  [window over aggregate]
SELECT cat.category_name,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       ROUND(100 * SUM(oi.quantity * oi.unit_price)
                 / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 2) AS pct_of_total
FROM order_items oi
JOIN orders o       ON o.order_id      = oi.order_id
JOIN products p     ON p.product_id    = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
WHERE o.status IN ('shipped','delivered')
GROUP BY cat.category_id, cat.category_name
ORDER BY revenue DESC;

-- Q4. Customers who have never placed an order.             [LEFT JOIN anti-join]
SELECT c.customer_id, c.first_name, c.last_name, c.email, c.created_at
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Q5. Each customer's most recent order.                    [CTE + ROW_NUMBER]
WITH ranked AS (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY o.customer_id
                              ORDER BY o.order_date DESC, o.order_id DESC) AS rn
    FROM orders o
)
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS customer,
       r.order_id, r.order_date, r.status
FROM ranked r
JOIN customers c ON c.customer_id = r.customer_id
WHERE r.rn = 1
ORDER BY c.customer_id;

-- Q6. Month-over-month revenue growth.                      [CTE + LAG]
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
           SUM(oi.quantity * oi.unit_price)   AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status IN ('shipped','delivered')
    GROUP BY month
)
SELECT month,
       revenue,
       LAG(revenue) OVER w AS prev_revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER w) / LAG(revenue) OVER w, 2) AS mom_growth_pct
FROM monthly
WINDOW w AS (ORDER BY month)
ORDER BY month;

-- Q7. Cumulative (running) revenue per city by month.       [CTE + running SUM window]
WITH city_month AS (
    SELECT c.city,
           DATE_FORMAT(o.order_date, '%Y-%m') AS month,
           SUM(oi.quantity * oi.unit_price)   AS revenue
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    WHERE o.status IN ('shipped','delivered')
    GROUP BY c.city, month
)
SELECT city, month, revenue,
       SUM(revenue) OVER (PARTITION BY city ORDER BY month
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue
FROM city_month
ORDER BY city, month;

-- Q8. Top 3 best-selling products (by units) in each category.  [chained CTEs + DENSE_RANK]
WITH product_sales AS (
    SELECT p.product_id, p.product_name, p.category_id,
           SUM(oi.quantity) AS units_sold
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    JOIN orders o       ON o.order_id    = oi.order_id
    WHERE o.status IN ('shipped','delivered')
    GROUP BY p.product_id, p.product_name, p.category_id
),
ranked AS (
    SELECT ps.*,
           DENSE_RANK() OVER (PARTITION BY ps.category_id ORDER BY ps.units_sold DESC) AS rnk
    FROM product_sales ps
)
SELECT cat.category_name, r.product_name, r.units_sold, r.rnk
FROM ranked r
JOIN categories cat ON cat.category_id = r.category_id
WHERE r.rnk <= 3
ORDER BY cat.category_name, r.rnk;

-- Q9. Payment-method mix: count, total and average order value.  [aggregate]
SELECT payment_method,
       COUNT(*)              AS payments,
       SUM(amount)           AS total_amount,
       ROUND(AVG(amount), 2) AS avg_order_value,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_payments
FROM payments
GROUP BY payment_method
ORDER BY total_amount DESC;

-- Q10. Data-quality reconciliation: paid orders whose payment total
--      doesn't match the item total (expected: 0 rows).      [CTEs + LEFT JOIN]
WITH item_totals AS (
    SELECT order_id, SUM(quantity * unit_price) AS items_total
    FROM order_items
    GROUP BY order_id
),
paid AS (
    SELECT order_id, SUM(amount) AS paid_total
    FROM payments
    GROUP BY order_id
)
SELECT o.order_id, o.status,
       it.items_total,
       COALESCE(p.paid_total, 0)                  AS paid_total,
       it.items_total - COALESCE(p.paid_total, 0) AS difference
FROM orders o
JOIN item_totals it ON it.order_id = o.order_id
LEFT JOIN paid p    ON p.order_id  = o.order_id
WHERE o.status IN ('shipped','delivered')
  AND it.items_total <> COALESCE(p.paid_total, 0);
