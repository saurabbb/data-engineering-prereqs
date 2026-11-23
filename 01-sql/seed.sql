-- =========================================
-- shop_db : seed data (deterministic, re-runnable after schema.sql)
-- Volumes: 6 categories, 24 products, 500 customers,
--          20,000 orders, ~40,000 order_items, ~17,000 payments
-- =========================================
USE shop_db;
SET SESSION cte_max_recursion_depth = 25000;

-- ---------- categories ----------
INSERT INTO categories (category_name) VALUES
('Electronics'), ('Groceries'), ('Clothing'),
('Home & Kitchen'), ('Books'), ('Sports');

-- ---------- products (4 per category, prices in NPR) ----------
INSERT INTO products (product_name, category_id, unit_price, stock_qty) VALUES
('Wireless Earbuds',        1,  3500.00, 120),
('Power Bank 20000mAh',     1,  2800.00,  90),
('USB-C Charger 65W',       1,  2200.00, 150),
('Bluetooth Speaker',       1,  4500.00,  60),
('Basmati Rice 5kg',        2,  1150.00, 300),
('Masoor Dal 1kg',          2,   220.00, 400),
('Ilam Tea 500g',           2,   450.00, 250),
('Mustard Oil 1L',          2,   340.00, 350),
('Cotton Kurta',            3,  1800.00,  80),
('Denim Jeans',             3,  2500.00,  70),
('Dhaka Topi',              3,   650.00, 110),
('Down Jacket',             3,  6500.00,  40),
('Pressure Cooker 5L',      4,  3200.00,  50),
('Copper Water Bottle',     4,  1200.00, 130),
('Non-stick Pan',           4,  1900.00,  75),
('Electric Kettle',         4,  2100.00,  85),
('Python Crash Course',     5,  1600.00,  45),
('Designing Data-Intensive Applications', 5, 3200.00, 30),
('Muna Madan',              5,   250.00, 200),
('SQL Cookbook',            5,  2400.00,  35),
('Football',                6,  1500.00,  95),
('Cricket Bat',             6,  4200.00,  40),
('Yoga Mat',                6,  1300.00, 140),
('Trekking Poles (pair)',   6,  3800.00,  55);

-- ---------- customers (500) ----------
INSERT INTO customers (first_name, last_name, email, phone, city, created_at)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 500
)
SELECT
    ELT(1 + n % 10, 'Aarav','Sita','Ram','Gita','Bikash','Anjali','Suman','Priya','Nabin','Kriti'),
    ELT(1 + (n DIV 10) % 8, 'Shrestha','Sharma','Thapa','Gurung','Rai','Karki','Adhikari','Maharjan'),
    CONCAT('customer', n, '@example.com'),
    CONCAT('98', LPAD(n, 8, '0')),
    ELT(1 + n % 7, 'Kathmandu','Lalitpur','Bhaktapur','Pokhara','Biratnagar','Butwal','Chitwan'),
    TIMESTAMP('2024-01-01') + INTERVAL (n % 300) DAY
FROM seq;

-- ---------- orders (20,000) ----------
-- customer_id cycles over 1..480, so customers 481-500 never order (used in query 4)
INSERT INTO orders (customer_id, order_date, status)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 20000
)
SELECT
    1 + (n * 7919) % 480,
    TIMESTAMP('2025-01-01')
        + INTERVAL ((n * 37) % 640) DAY
        + INTERVAL (n % 24) HOUR
        + INTERVAL ((n * 7) % 60) MINUTE,
    CASE
        WHEN n % 20 = 0 THEN 'cancelled'
        WHEN n % 10 = 1 THEN 'pending'
        WHEN n % 3  = 0 THEN 'shipped'
        ELSE 'delivered'
    END
FROM seq;

-- ---------- order_items (1-3 distinct products per order) ----------
-- offsets 7,14,21 mod 24 are distinct, so UNIQUE(order_id, product_id) always holds
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.order_id,
    p.product_id,
    1 + (o.order_id * m.k) % 4,
    p.unit_price
FROM orders o
JOIN (SELECT 1 AS k UNION ALL SELECT 2 UNION ALL SELECT 3) AS m
     ON m.k <= 1 + o.order_id % 3
JOIN products p
     ON p.product_id = 1 + (o.order_id + m.k * 7) % 24;

-- ---------- payments (only shipped/delivered orders are paid) ----------
INSERT INTO payments (order_id, amount, payment_method, paid_at)
SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price),
    ELT(1 + o.order_id % 5, 'cash','card','esewa','khalti','bank'),
    o.order_date + INTERVAL 2 HOUR
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status IN ('shipped','delivered')
GROUP BY o.order_id, o.order_date;

-- ---------- sanity check ----------
SELECT 'categories' AS tbl, COUNT(*) AS row_count FROM categories
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'customers',   COUNT(*) FROM customers
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments',    COUNT(*) FROM payments;
