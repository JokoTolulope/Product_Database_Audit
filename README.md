# Product Database Audit System
### A SQL-based data quality audit built on Microsoft SQL Server (MSSQL) using SSMS

## Project Overview

This project simulates a real-world retail product database and implements a structured audit system to detect, investigate, and document data quality issues across 1,000 products and 10,000 orders.

The goal was to move beyond reactive database fixes — building a proactive system that identifies problems before they affect business operations. Every finding in this project mirrors real issues encountered in production retail databases.

**Tools Used:** Microsoft SQL Server (MSSQL) | SSMS | T-SQL

---

## Database Schema

Three tables were designed and populated to simulate a retail business environment:

- **suppliers** — 101 supplier records across 5 countries
- **products** — 1,000 product records across 6 categories (Electronics, Clothing, Food, Furniture, Beauty, Sports)
- **orders** — 10,000 order records with statuses: Completed, Pending, Cancelled, Returned

```sql
CREATE TABLE suppliers (
    supplier_id   INT IDENTITY(1,1) PRIMARY KEY,
    supplier_name VARCHAR(100),
    country       VARCHAR(50),
    contact_email VARCHAR(100)
);

CREATE TABLE products (
    product_id     INT IDENTITY(1,1) PRIMARY KEY,
    product_name   VARCHAR(100),
    category       VARCHAR(50),
    price          DECIMAL(10,2),
    stock_quantity INT,
    supplier_id    INT,
    created_at     DATETIME
);

CREATE TABLE orders (
    order_id    INT IDENTITY(1,1) PRIMARY KEY,
    product_id  INT,
    customer_id INT,
    quantity    INT,
    order_date  DATETIME,
    status      VARCHAR(20)
);
```

### Known Design Limitations
The schema was intentionally kept simple to focus on the audit layer. Identified normalization gaps include:
- No **customers** table — customer_id in orders is an unresolved integer with no referential integrity
- No foreign key constraint between orders.product_id and products.product_id at creation time
- supplier_id in products has no formal foreign key constraint

These limitations are addressed in **Repository 2 — Product Price Integrity System**, which implements a fully normalized schema with enforced constraints.

---

## Audit Findings

### Finding 1: NULL and Zero Prices

**Query:**
```sql
SELECT COUNT(*) as null_price_count
FROM products
WHERE price IS NULL OR price <= 0;
```

**Result:** 100 products (10% of total) have NULL or zero prices.

**Impact:** Products with missing prices cannot be included in revenue calculations, order totals, or financial reporting. In a live system this would silently corrupt any dashboard or report that aggregates revenue.

**Recommendation:** Add a CHECK constraint to prevent future NULL or zero price insertions:
```sql
ALTER TABLE products
ADD CONSTRAINT chk_price_positive CHECK (price > 0);
```

---

### Finding 2: Duplicate Product Names

**Query:**
```sql
SELECT product_name, COUNT(*) as duplicate_count
FROM products
GROUP BY product_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
```

**Result:** 902 out of 1,000 rows have duplicate product names.

**Deeper Investigation:**

A surface-level duplicate check flagged 902 rows. However, a deeper composite investigation revealed no true identical duplicates — all duplicates had different prices, supplier IDs, or dates:

```sql
SELECT product_name, category, price, supplier_id, COUNT(*) as exact_duplicate_count
FROM products
GROUP BY product_name, category, price, supplier_id
HAVING COUNT(*) > 1;
```

**Result:** 0 rows — no exact duplicates exist.

**Conclusion:** The 902 duplicate names represent legitimate multi-supplier inventory — the same product stocked from different suppliers at different prices. These are not data entry errors and no deletion is required.

**Important Distinction:** Treating all name duplicates as errors would incorrectly remove valid inventory records. Context determines whether duplicated data is dirty or simply misunderstood.

**Recommendation:** Add a composite unique constraint on (product_name, supplier_id) to prevent the same supplier from entering the same product twice:
```sql
ALTER TABLE products
ADD CONSTRAINT uq_product_supplier UNIQUE (product_name, supplier_id);
```

---

### Finding 3: Zero Stock Products

**Query:**
```sql
SELECT COUNT(*) as zero_stock_count
FROM products
WHERE stock_quantity = 0;
```

**Result:** 60 products (6% of total) have zero stock.

**Impact:** Zero stock products being visible in a customer-facing system would allow orders to be placed against unavailable inventory — leading to fulfilment failures and poor customer experience.

**Recommendation:** Implement an active status flag on the products table:
```sql
ALTER TABLE products ADD is_active BIT DEFAULT 1;

-- Automatically deactivate zero stock products
UPDATE products
SET is_active = 0
WHERE stock_quantity = 0;
```

---

### Finding 4: Orphaned Orders

**Query:**
```sql
SELECT COUNT(*) as orphaned_orders_count
FROM orders o
LEFT JOIN products p ON o.product_id = p.product_id
WHERE p.product_id IS NULL;
```

**Result:** 10,000 orders (100%) have no matching product record.

**Root Cause Investigation:** A check of the products table revealed product_id values range from 1001 to 2000, while the orders table references product_id values between 1 and 1000. This mismatch occurred because the data was generated independently from the product data.

```sql
SELECT MIN(product_id) as min_id, MAX(product_id) as max_id
FROM products;
-- Result: min_id = 1001, max_id = 2000
```

**Impact:** Every order in the system is orphaned. No order can be joined to a product — making revenue analysis, inventory tracking, and order fulfilment reporting completely impossible.

**Recommendation:** Enforce referential integrity with a foreign key constraint and reseed the identity to align ranges:
```sql
-- Reseed identity to prevent future mismatches
DBCC CHECKIDENT ('orders', RESEED, 0);

-- Enforce referential integrity
ALTER TABLE orders
ADD CONSTRAINT fk_orders_products
FOREIGN KEY (product_id) REFERENCES products(product_id);
```

---

### Finding 5: Query Performance Optimization

**Objective:** Measure query execution improvement after adding an index on a frequently filtered column.

**Before Index:**
```sql
SET STATISTICS TIME ON;
SELECT * FROM orders WHERE order_date > '2024-01-01';
SET STATISTICS TIME OFF;
-- Result: 10,000 rows returned
```

**Index Created:**
```sql
CREATE INDEX idx_order_date ON orders(order_date);
```

**After Index:**
```sql
SET STATISTICS TIME ON;
SELECT * FROM orders WHERE order_date > '2024-01-01';
SET STATISTICS TIME OFF;
-- Result: 0 rows additional scan time
```

**Note:** With 10,000 rows the execution time difference is negligible and not measurable at millisecond precision in SSMS. In a production environment with millions of rows, an index on a high-frequency filter column like order_date would produce significant and measurable performance gains. The principle demonstrated here — identifying unindexed columns on large filtered queries and adding targeted indexes — is a standard database performance tuning technique.

---

### Finding 6: Business Logic Violations

**Query:**
```sql
SELECT COUNT(*) as logic_violation_count
FROM orders
WHERE quantity IS NULL
AND status = 'Completed';
```

**Result:** 116 orders are marked Completed but have no quantity recorded.

**Why This Matters:** This is more sophisticated than a simple NULL check. These records are not technically invalid — no column constraint is violated. But they are **logically impossible**: an order cannot be completed without a quantity. This type of contradiction occurs in production when two systems write to the same database independently — one system marks the order complete while another fails to record the quantity.

**Impact:** These 116 records would silently corrupt any revenue or fulfilment report that assumes Completed orders have valid quantities. A SUM(quantity) on Completed orders would undercount actual sales.

**Recommendation:** Add a conditional check constraint:
```sql
ALTER TABLE orders
ADD CONSTRAINT chk_completed_quantity
CHECK (status != 'Completed' OR quantity IS NOT NULL);
```

This enforces the business rule: if an order is Completed, quantity cannot be NULL.

---

## Audit Summary

| Finding | Records Affected | Severity | Action Required |
|---|---|---|---|
| NULL / Zero Prices | 100 (10%) | High | Add CHECK constraint |
| Duplicate Product Names | 902 (90%) | Investigated — Low | Add composite UNIQUE constraint |
| Zero Stock Products | 60 (6%) | Medium | Add is_active flag |
| Orphaned Orders | 10,000 (100%) | Critical | Fix identity seed, add FK constraint |
| Query Performance | All order queries | Medium | Index on order_date added |
| Business Logic Violations | 116 orders | High | Add conditional CHECK constraint |

---

## Key Learnings

**Not all duplicates are errors.** 902 duplicate product names initially appeared to be a data quality crisis. Deeper investigation revealed they represented legitimate multi-supplier inventory. Jumping to delete duplicates without investigation would have destroyed valid business data.

**Identity columns don't reset on failure.** Failed insert attempts consume identity values permanently. In this project, multiple failed inserts caused product_id to start at 1001 instead of 1 — making all 10,000 orders orphaned. In production, identity gaps and mismatches must be monitored.

**Business logic violations are harder to find than NULLs.** Finding 6 required understanding what the data should mean, not just what constraints exist. A Completed order with NULL quantity passes all column-level constraints but fails business logic. This class of problem requires domain knowledge combined with data analysis.

**Constraint enforcement often requires prior remediation.** Attempting to add the unique constraint on (product_name, supplier_id) failed because existing data already violated it. In production, adding constraints to existing tables always requires auditing and cleaning the data first.

---

## How To Run This Project

1. Install Microsoft SQL Server (Express edition is free) and SSMS
2. Create a new database called `PortfolioProjects`
3. Run `Product_Database_Schema.sql` to create the three tables
4. Run `Supplier_Data_Migration_Portfolio.sql` to populate 101 supplier records
5. Run `Product_Data_Migration_Portfolio.sql` to populate 1,000 product records
6. Run `Order_Data_Migration_Portfolio.sql` to populate 10,000 order records
7. Run `product_database_audit.sql` to execute all six audit queries
8. Review findings against this README

---

## Repository Structure

```
product-database-audit/
│
├── README.md
├── Product_Database_Schema.sql
├── Supplier_Data_Migration_Portfolio.sql
├── Product_Data_Migration_Portfolio.sql
├── Order_Data_Migration_Portfolio.sql
└── product_database_audit.sql
