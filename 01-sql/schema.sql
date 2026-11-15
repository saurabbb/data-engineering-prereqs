-- =========================================
-- shop_db : normalized practice schema (3NF)
-- =========================================
DROP DATABASE IF EXISTS shop_db;
CREATE DATABASE shop_db;
USE shop_db;

CREATE TABLE customers (
    customer_id   INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    city          VARCHAR(50),
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category_id   INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    stock_qty     INT NOT NULL DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT NOT NULL,
    order_date    DATETIME NOT NULL,
    status        ENUM('pending','shipped','delivered','cancelled') NOT NULL DEFAULT 'pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    DECIMAL(10,2) NOT NULL,   -- price at time of sale (historical, not duplication)
    UNIQUE (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    order_id       INT NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash','card','esewa','khalti','bank') NOT NULL,
    paid_at        DATETIME NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
