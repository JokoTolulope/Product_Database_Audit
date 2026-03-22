USE [Portfolio Projects]
--Test Data Insertion into Product table


CREATE TABLE #product_names (id INT IDENTITY(1,1), name VARCHAR(100), category VARCHAR(50), base_price DECIMAL(10,2))

INSERT INTO #product_names (name, category, base_price) VALUES
-- Electronics
('Samsung 55 Inch Smart TV', 'Electronics', 450000),
('LG 43 Inch LED TV', 'Electronics', 280000),
('Sony Bravia 50 Inch TV', 'Electronics', 380000),
('iPhone 14 Pro Max', 'Electronics', 850000),
('Samsung Galaxy S23', 'Electronics', 620000),
('Tecno Spark 10 Pro', 'Electronics', 95000),
('Infinix Hot 30', 'Electronics', 85000),
('HP Laptop 15 inch', 'Electronics', 320000),
('Dell Inspiron 15', 'Electronics', 380000),
('Lenovo IdeaPad 3', 'Electronics', 290000),
('MacBook Air M2', 'Electronics', 980000),
('iPad 10th Generation', 'Electronics', 450000),
('Samsung Galaxy Tab', 'Electronics', 180000),
('Xiaomi Redmi Note 12', 'Electronics', 110000),
('Huawei MatePad', 'Electronics', 160000),
('JBL Bluetooth Speaker', 'Electronics', 35000),
('Sony WH1000XM5 Headphones', 'Electronics', 120000),
('Oraimo FreePods', 'Electronics', 12000),
('Canon EOS Rebel Camera', 'Electronics', 280000),
('Epson L3250 Printer', 'Electronics', 95000),
-- Clothing
('Nike Air Max Sneakers', 'Clothing', 45000),
('Adidas Ultraboost Shoes', 'Clothing', 52000),
('Puma Running Shoes', 'Clothing', 28000),
('Zara Casual Shirt', 'Clothing', 15000),
('HM Slim Fit Jeans', 'Clothing', 18000),
('Under Armour Polo Shirt', 'Clothing', 22000),
('Adidas Track Jacket', 'Clothing', 35000),
('Nike Dri Fit Shorts', 'Clothing', 12000),
('Reebok Classic Tshirt', 'Clothing', 9500),
('Zara Formal Blazer', 'Clothing', 48000),
-- Food
('Dangote Sugar 1kg', 'Food', 1800),
('Nestle Milo 900g', 'Food', 4500),
('Indomie Noodles Carton', 'Food', 8500),
('Golden Penny Spaghetti', 'Food', 2200),
('Honeywell Semovita 1kg', 'Food', 1500),
('Chi Chivita Juice 1L', 'Food', 1200),
('Peak Milk Tin 400g', 'Food', 3800),
('Cadbury Bournvita 900g', 'Food', 4200),
('Kelloggs Cornflakes 500g', 'Food', 3500),
('Quaker Oats 1kg', 'Food', 3200),
-- Furniture
('Office Executive Chair', 'Furniture', 85000),
('Gaming Chair RGB', 'Furniture', 120000),
('Wooden Study Desk', 'Furniture', 65000),
('L Shaped Office Desk', 'Furniture', 95000),
('3 Seater Sofa', 'Furniture', 180000),
('Queen Size Bed Frame', 'Furniture', 145000),
('Wardrobe 4 Door', 'Furniture', 165000),
('Bookshelf 5 Tier', 'Furniture', 45000),
('Dining Table Set 6 Seater', 'Furniture', 220000),
('TV Stand Cabinet', 'Furniture', 55000),
-- Beauty
('Neutrogena Face Wash', 'Beauty', 4500),
('Nivea Body Lotion 400ml', 'Beauty', 3200),
('Dove Shampoo 700ml', 'Beauty', 2800),
('Olay Total Effects Cream', 'Beauty', 8500),
('Maybelline Foundation', 'Beauty', 6500),
('LOreal Paris Serum', 'Beauty', 12000),
('Vaseline Petroleum Jelly', 'Beauty', 1500),
('Dettol Antiseptic 500ml', 'Beauty', 2200),
('Colgate Total Toothpaste', 'Beauty', 1800),
('Oral B Electric Toothbrush', 'Beauty', 18000),
-- Sports
('Wilson Tennis Racket', 'Sports', 35000),
('Adidas Football Size 5', 'Sports', 8500),
('Nike Basketball', 'Sports', 12000),
('Speedo Swimming Goggles', 'Sports', 6500),
('Decathlon Yoga Mat', 'Sports', 9500),
('Dumbell Set 20kg', 'Sports', 28000),
('Treadmill Electric', 'Sports', 185000),
('Exercise Bike Stationary', 'Sports', 145000),
('Jump Rope Speed', 'Sports', 3500),
('Gym Gloves Weightlifting', 'Sports', 4500);

-- Now generate 1000 products by cycling through these base products
INSERT INTO products (product_name, category, price, stock_quantity, supplier_id, created_at)
SELECT TOP 1000
        CONCAT(p.name, CASE (ROW_NUMBER() OVER (ORDER BY NEWID()) % 5)
        WHEN 0 THEN ' - Black'
        WHEN 1 THEN ' - White'
        WHEN 2 THEN ' - Pro Edition'
        WHEN 3 THEN ' - Limited'
        WHEN 4 THEN ' - Standard'
    END),
    p.category,
    CASE (ROW_NUMBER() OVER (ORDER BY NEWID()) % 10)
        WHEN 0 THEN NULL  -- deliberate null prices for audit
        ELSE ROUND(p.base_price * (0.8 + (ABS(CHECKSUM(NEWID())) % 40) / 100.0), 2)
    END,
    CASE (ABS(CHECKSUM(NEWID())) % 15)
        WHEN 0 THEN 0     -- deliberate zero stock
        ELSE ABS(CHECKSUM(NEWID())) % 500 + 1
    END,
    (ABS(CHECKSUM(NEWID())) % 100) + 1,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 730), GETDATE())
FROM #product_names p
CROSS JOIN (SELECT TOP 15 1 as x FROM sys.objects) multiplier;

DROP TABLE #product_names

--select top 100 * from Products