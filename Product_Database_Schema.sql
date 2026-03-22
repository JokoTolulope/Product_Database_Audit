-- ================================================
-- Product Database Audit System | Tolulope Jokosenumi
-- Schema Creation Script
-- Author: Tolulope Jokosenumi
-- ================================================

-- Create Suppliers Table
CREATE TABLE suppliers (
    supplier_id   INT IDENTITY(1,1) PRIMARY KEY,
    supplier_name VARCHAR(100),
    country       VARCHAR(50),
    contact_email VARCHAR(100)
);

-- Create Products Table
CREATE TABLE products (
    product_id     INT IDENTITY(1,1) PRIMARY KEY,
    product_name   VARCHAR(100),
    category       VARCHAR(50),
    price          DECIMAL(10,2),
    stock_quantity INT,
    supplier_id    INT,
    created_at     DATETIME
);

-- Create Orders Table
CREATE TABLE orders (
    order_id    INT IDENTITY(1,1) PRIMARY KEY,
    product_id  INT,
    customer_id INT,
    quantity    INT,
    order_date  DATETIME,
    status      VARCHAR(20)
);
