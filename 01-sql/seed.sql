-- =========================================
-- shop_db : seed data
-- Run AFTER schema.sql on an empty database.
-- Data is deterministic (no RAND()), so results are reproducible.
-- =========================================
USE shop_db;
SET SESSION cte_max_recursion_depth = 100000;

-- ---------- 1. Categories (hand-written) ----------
INSERT INTO categories (category_name) VALUES
('Electronics'), ('Clothing'), ('Home & Kitchen'),
('Books'), ('Sports'), ('Groceries');

-- ---------- 2. Products (hand-written, prices in NPR) ----------
INSERT INTO products (product_name, category_id, unit_price, stock_qty) VALUES
('Wireless Earbuds',      1,  3500.00, 120),
('Smartphone 128GB',      1, 32000.00,  40),
('USB-C Charger',         1,  1200.00, 300),
('Laptop Backpack',       1,  2800.00,  90),
('Cotton T-Shirt',        2,   900.00, 500),
('Denim Jeans',           2,  2500.00, 200),
('Winter Jacket',         2,  6500.00,  60),
('Pressure Cooker 5L',    3,  3200.00,  80),
('Non-stick Pan',         3,  1800.00, 150),
('Electric Kettle',       3,  2200.00, 110),
('SQL for Beginners',     4,   850.00, 250),
('Data Engineering 101',  4,  1500.00, 180),
('Nepali Novel',          4,   600.00, 400),
('Football',              5,  1600.00, 140),
('Yoga Mat',              5,  1300.00, 160),
('Badminton Racket',      5,  2100.00,  75),
('Basmati Rice 5kg',      6,  1100.00, 600),
('Masala Tea 500g',       6,   450.00, 800),
('Ghee 1L',               6,  1400.00, 300),
('Mixed Dry Fruits 1kg',  6,  2400.00, 120);

-- ---------- 3. Customers (1,000 generated) ----------
INSERT INTO customers (first_name, last_name, email, phone, city, created_at)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 1000
)
SELECT
    ELT(1 + n % 10, 'Aarav','Sita','Ram','Gita','Bikash','Anita','Suman','Puja','Rajesh','Kriti') AS first_name,
    ELT(1 + (n * 7) % 10, 'Sharma','Shrestha','Thapa','Gurung','Karki','Adhikari','Rai','Tamang','Kharel','Magar') AS last_name,
    CONCAT('user', n, '@example.com') AS email,
    CONCAT('98', LPAD((n * 7919) % 100000000, 8, '0')) AS phone,
    ELT(1 + (n * 3) % 8, 'Kathmandu','Lalitpur','Bhaktapur','Pokhara','Biratnagar','Butwal','Dharan','Chitwan') AS city,
    DATE_ADD('2023-01-01', INTERVAL n % 365 DAY) AS created_at
FROM seq;

-- ---------- 4. Orders (50,000 generated, Jan 2024 – Dec 2025) ----------
-- Customers 951–1000 deliberately never order (useful for LEFT JOIN / anti-join queries).
INSERT INTO orders (customer_id, order_date, status)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 50000
)
SELECT
    1 + (n * 31) % 950 AS customer_id,
    DATE_ADD('2024-01-01', INTERVAL (n * 7919) % (730 * 24 * 60) MINUTE) AS order_date,
    CASE
        WHEN n % 20 = 0 THEN 'cancelled'
        WHEN n % 10 = 0 THEN 'pending'
        WHEN n %  4 = 0 THEN 'shipped'
        ELSE 'delivered'
    END AS status
FROM seq;

-- ---------- 5. Order items (1–3 distinct products per order) ----------
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.order_id,
    p.product_id,
    1 + (o.order_id + k.n) % 4 AS quantity,
    p.unit_price                         -- price captured at time of sale
FROM orders o
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) k
     ON k.n <= 1 + o.order_id % 3
JOIN products p
     ON p.product_id = 1 + (o.order_id * 7 + k.n * 13) % 20;

-- ---------- 6. Payments (only for shipped / delivered orders) ----------
INSERT INTO payments (order_id, amount, payment_method, paid_at)
SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) AS amount,
    ELT(1 + o.order_id % 5, 'cash','card','esewa','khalti','bank') AS payment_method,
    DATE_ADD(o.order_date, INTERVAL 1 + o.order_id % 48 HOUR) AS paid_at
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status IN ('shipped', 'delivered')
GROUP BY o.order_id, o.order_date;
