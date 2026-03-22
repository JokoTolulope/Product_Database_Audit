-- Product Database Audit System | Tolulope Jokosenumi
USE [Portfolio Projects]

--Product with Null price
Select count(*) Null_price_count
from products
where price is null or price <= 0

--Duplicate product names
select product_name, count(*) as duplicate_product
from products
group by product_name
having count(*) > 1

--Zero stock quantity
select count(*) zero_stock_count
from products
where stock_quantity = 0

select count(*) total_products
from products

--How many products have duplicate names total
SELECT COUNT(*) as total_duplicate_name_rows
FROM products
WHERE product_name IN (
    SELECT product_name
    FROM products
    GROUP BY product_name
    HAVING COUNT(*) > 1)

--Orphaned orders (orders with no matching product)
SELECT COUNT(*) as orphaned_orders_count
FROM orders o
LEFT JOIN products p ON o.product_id = p.product_id
WHERE p.product_id IS NULL

--Completed orders with NULL quantity
SELECT COUNT(*) as logic_violation_count
FROM orders
WHERE quantity IS NULL
AND status = 'Completed'

-- Check what product_id range actually exists
SELECT MIN(product_id) as min_id, MAX(product_id) as max_id
FROM products

-- BEFORE index - note the execution time in Messages tab
SET STATISTICS TIME ON

SELECT * FROM orders
WHERE order_date > '2024-01-01'

SET STATISTICS TIME OFF

--create index on order_date column
CREATE INDEX idx_order_date ON orders(order_date)
