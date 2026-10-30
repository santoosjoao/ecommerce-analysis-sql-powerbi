-- =====================================================================
-- 01_criacao_tabelas.sql  |  MySQL 8.0+
-- Cria o banco, as tabelas (com chaves) e importa os CSVs do Olist.
-- Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
-- =====================================================================

CREATE DATABASE IF NOT EXISTS olist CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
                     customers, products, sellers, category_translation;

CREATE TABLE customers (
    customer_id              VARCHAR(32) PRIMARY KEY,   -- muda a cada pedido
    customer_unique_id       VARCHAR(32) NOT NULL,      -- identifica a pessoa
    customer_zip_code_prefix CHAR(5),
    customer_city            VARCHAR(100),
    customer_state           CHAR(2),
    INDEX idx_unique (customer_unique_id)
);

CREATE TABLE sellers (
    seller_id              VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix CHAR(5),
    seller_city            VARCHAR(100),
    seller_state           CHAR(2)
);

CREATE TABLE category_translation (
    product_category_name         VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE products (
    product_id                 VARCHAR(32) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_length        INT,
    product_description_length INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE orders (
    order_id                      VARCHAR(32) PRIMARY KEY,
    customer_id                   VARCHAR(32) NOT NULL,
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    INDEX idx_customer (customer_id),
    INDEX idx_purchase (order_purchase_timestamp),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id            VARCHAR(32) NOT NULL,
    order_item_id       INT NOT NULL,
    product_id          VARCHAR(32) NOT NULL,
    seller_id           VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_product (product_id),
    INDEX idx_seller (seller_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id             VARCHAR(32) NOT NULL,
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- review_id NÃO é único na base original (há duplicatas), por isso sem PK.
CREATE TABLE order_reviews (
    review_id               VARCHAR(32),
    order_id                VARCHAR(32) NOT NULL,
    review_score            TINYINT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    INDEX idx_order (order_id)
);

-- =====================================================================
-- IMPORTAÇÃO
-- Troque C:/olist/ pelo caminho da pasta onde estão os CSVs.
-- Requer local_infile ativo no servidor e no cliente
-- (Workbench: Edit Connection > Advanced > Others: OPT_LOCAL_INFILE=1).
-- Se der erro de linhas, troque '\n' por '\r\n' em LINES TERMINATED BY.
-- Alternativa sem comandos: Workbench > clique direito na tabela >
-- "Table Data Import Wizard".
-- =====================================================================
SET GLOBAL local_infile = 1;
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA LOCAL INFILE 'C:/olist/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(product_id, @cat, @nl, @dl, @ph, @w, @l, @h, @wd)
SET product_category_name      = NULLIF(@cat,''),
    product_name_length        = NULLIF(@nl,''),
    product_description_length = NULLIF(@dl,''),
    product_photos_qty         = NULLIF(@ph,''),
    product_weight_g           = NULLIF(@w,''),
    product_length_cm          = NULLIF(@l,''),
    product_height_cm          = NULLIF(@h,''),
    product_width_cm           = NULLIF(@wd,'');

LOAD DATA LOCAL INFILE 'C:/olist/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(order_id, customer_id, order_status, @pur, @app, @car, @del, @est)
SET order_purchase_timestamp      = NULLIF(@pur,''),
    order_approved_at             = NULLIF(@app,''),
    order_delivered_carrier_date  = NULLIF(@car,''),
    order_delivered_customer_date = NULLIF(@del,''),
    order_estimated_delivery_date = NULLIF(@est,'');

LOAD DATA LOCAL INFILE 'C:/olist/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, @ship, price, freight_value)
SET shipping_limit_date = NULLIF(@ship,'');

LOAD DATA LOCAL INFILE 'C:/olist/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Reviews: título/mensagem são ignorados (texto livre com quebras de linha)
LOAD DATA LOCAL INFILE 'C:/olist/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(review_id, order_id, review_score, @title, @msg, @created, @answered)
SET review_creation_date    = NULLIF(@created,''),
    review_answer_timestamp = NULLIF(@answered,'');

SET FOREIGN_KEY_CHECKS = 1;

-- Conferência (esperado: ~99k customers/orders, ~112k items, ~103k payments)
SELECT 'customers' tabela, COUNT(*) linhas FROM customers UNION ALL
SELECT 'orders', COUNT(*) FROM orders UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews UNION ALL
SELECT 'products', COUNT(*) FROM products UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers;
