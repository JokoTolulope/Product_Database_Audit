use [Portfolio Projects]
--Test data migration into order table

INSERT INTO orders (product_id, customer_id, quantity, order_date, status)
SELECT TOP 10000
    (ABS(CHECKSUM(NEWID())) % 1000) + 1,
    (ABS(CHECKSUM(NEWID())) % 500) + 1,
    CASE (ABS(CHECKSUM(NEWID())) % 20)
        WHEN 0 THEN NULL
        ELSE (ABS(CHECKSUM(NEWID())) % 50) + 1
    END,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 365), GETDATE()),
    CASE (ABS(CHECKSUM(NEWID())) % 4)
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Cancelled'
        WHEN 3 THEN 'Returned'
		ELSE 'Pending'
    END
FROM sys.objects a
CROSS JOIN sys.objects b
CROSS JOIN sys.objects c

--select top 1000 * from Orders

--DELETE FROM orders