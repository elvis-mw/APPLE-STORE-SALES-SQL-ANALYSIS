IF OBJECT_ID('Apple') IS NOT NULL DROP DATABASE Apple;
CREATE DATABASE Apple;
GO

USE Apple
GO

IF OBJECT_ID('category') IS NOT NULL DROP TABLE category;
CREATE TABLE category (
    category_id VARCHAR(10) NOT NULL PRIMARY KEY,
    category_name VARCHAR(50)
);
GO

IF OBJECT_ID('products') IS NOT NULL DROP TABLE products;
CREATE TABLE products (
    product_id VARCHAR(10) NOT NULL PRIMARY KEY,
    product_name VARCHAR(50),
    category_id VARCHAR(10),
    launch_date DATE,
    price INT,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);
GO

IF OBJECT_ID('stores') IS NOT NULL DROP TABLE stores;
CREATE TABLE stores (
    store_id VARCHAR(10) NOT NULL PRIMARY KEY,
    store_name VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50)
);
GO

IF OBJECT_ID('sales') IS NOT NULL DROP TABLE sales;
CREATE TABLE sales (
    sale_id VARCHAR(50) NOT NULL PRIMARY KEY,
    sale_date DATE,
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity INT,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);
GO

IF OBJECT_ID('warranty') IS NOT NULL DROP TABLE warranty;
CREATE TABLE warranty (
    claim_id VARCHAR(10) NOT NULL PRIMARY KEY,
    claim_date DATE,
    sale_id VARCHAR(50),
    repair_status VARCHAR(100),
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);
GO


SELECT * FROM INFORMATION_SCHEMA.TABLES
GO

BULK INSERT sales
FROM 'C:\Users\Administrator\Desktop\Practice\APPLE\sales.csv'
WITH (FORMAT='CSV')

SELECT * FROM sales
GO


BULK INSERT category
FROM 'C:\Users\Administrator\Desktop\Practice\APPLE\category.csv'
WITH (FORMAT='CSV')

SELECT * FROM category
GO

BULK INSERT products
FROM 'C:\Users\Administrator\Desktop\Practice\APPLE\products.csv'
WITH (FORMAT='CSV')

SELECT * FROM products
GO

BULK INSERT warranty
FROM 'C:\Users\Administrator\Desktop\Practice\APPLE\warranty.csv'
WITH (FORMAT='CSV')

SELECT * FROM warranty
GO

BULK INSERT stores
FROM 'C:\Users\Administrator\Desktop\Practice\APPLE\stores.csv'
WITH (FORMAT='CSV')

SELECT * FROM stores
GO



--- 1. STORES & PRODUCTS PERFORMANCE (Store Performance, Product Sales & Categories)


-- 1. Find the number of stores in each country.

SELECT Country, COUNT(*) AS Store_Count -- Counts the total number of stores.
FROM Stores
GROUP BY Country;                      -- Groups records by Country, so we get a count of stores for each country.
GO

-- 2. Calculate the total number of units sold by each store.

SELECT store_id, SUM(Quantity) AS Total_Units_Sold -- Calculates the total number of products sold.
FROM Sales										
GROUP BY store_id;								 -- Groups the sales records by store ID.
GO

-- 3. Identify which store had the highest total units sold in the last year.

SELECT TOP 1 WITH TIES store_id, SUM(Quantity) AS Total_Units_Sold -- Retrieves the store(s) with the highest total sales
FROM Sales
WHERE sale_date >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE)) -- Filters sales from the last year
GROUP BY store_id
ORDER BY Total_Units_Sold DESC; -- Sorts stores by highest sales
GO

-- 4. Analyze the year-by-year growth ratio for each store.

SELECT  store_id, YEAR(sale_date) AS Year,
       SUM(Quantity) AS TotalSales,
       LAG(SUM(Quantity)) OVER (PARTITION BY store_id ORDER BY YEAR(sale_date)) AS PreviousYearSales,      -- Uses LAG() to retrieve sales from the previous year
       (SUM(Quantity) - LAG(SUM(Quantity)) OVER (PARTITION BY store_id ORDER BY YEAR(sale_date))) * 100.0 / 
       NULLIF(LAG(SUM(Quantity)) OVER (PARTITION BY store_id ORDER BY YEAR(sale_date)), 0) AS GrowthPercentage -- Computes year-over-year growth rate for each store.
	                                                                                                         -- NULLIF(..., 0): Prevents division by zero errors
FROM Sales
GROUP BY  store_id, YEAR(sale_date);
GO

-- 5. Identify the least selling product in each country for each year.

WITH ProductSales AS (                                   
    SELECT 
        s.store_id, 
        s.Country, 
        YEAR(sa.sale_date) AS SaleYear, 
        sa.product_id, 
        SUM(sa.Quantity) AS Total_Sales
    FROM Sales sa
    JOIN Stores s ON sa.store_id = s.store_id
    GROUP BY s.store_id, s.Country, YEAR(sa.sale_date), sa.product_id
)
SELECT Country, SaleYear, product_id, Total_Sales
FROM (
    SELECT 
        Country, 
        SaleYear, 
        product_id, 
        Total_Sales,
        RANK() OVER (PARTITION BY Country, SaleYear ORDER BY Total_Sales ASC) AS rnk
    FROM ProductSales
) RankedSales
WHERE rnk = 1;  -- Selects the product with the lowest sales per country and year.
GO


-- 6. Find the average price of products in each category.

SELECT category_id, AVG(Price) AS Avg_Price -- Calculates the average price of products
FROM Products
GROUP BY category_id;                      -- Groups by product category.
GO

-- 7. Identify the product category with the most warranty claims filed in the last two years.

SELECT TOP 1 
    p.category_id, 
    COUNT(*) AS Claim_Count
FROM warranty w
JOIN sales s ON w.sale_id = s.sale_id  -- Linking warranty claims to sales
JOIN products p ON s.product_id = p.product_id  -- Linking sales to products
WHERE w.claim_date >= DATEADD(YEAR, -2, GETDATE())  -- Filtering claims from the last two years
GROUP BY p.category_id
ORDER BY Claim_Count DESC;
GO

-- 8. Identify the least selling product in each country for each year.

WITH ProductSales AS (                                   
    SELECT s. store_id, s.Country, YEAR(sa.sale_date) AS SaleYear, sa.product_id, SUM(sa.Quantity) AS TotalSales
    FROM Sales sa
    JOIN Stores s ON sa. store_id = s. store_id
    GROUP BY s. store_id, s.Country, YEAR(sa.sale_date), sa.product_id
)                                                                    -- Uses a Common Table Expression (CTE) (WITH) to calculate total sales per product.
SELECT Country, SaleYear, product_id, MIN(TotalSales) AS Least_Sold -- Finds the product with the lowest sales per country and year.
FROM ProductSales
GROUP BY Country, SaleYear, product_id;
GO


--- 2. SALES TRENDS (Sales Trends, Seasonal Patterns & Best-Selling Insights)


-- 9. Count the number of unique products sold in the last year Per Store & Category.

SELECT s.store_id, p.category_id, c.category_name, COUNT(DISTINCT s.product_id) AS Unique_Products_Sold  
FROM Sales s  
JOIN Products p ON s.product_id = p.product_id  
JOIN Category c ON p.category_id = c.category_id  
WHERE s.sale_date >= DATEADD(YEAR, -1, GETDATE())  
GROUP BY s.store_id, p.category_id, c.category_name;
GO

-- 10. Identify the best-selling day for each store.

WITH DailySales AS (
    SELECT store_id, sale_date, SUM(quantity) AS Total_Sales  -- Summing sales for each store per day
    FROM Sales
    GROUP BY store_id, sale_date
),
RankedSales AS (
    SELECT store_id, sale_date, Total_Sales,
           RANK() OVER (PARTITION BY store_id ORDER BY Total_Sales DESC) AS rnk  -- Ranking highest sales per store
    FROM DailySales
)
SELECT store_id, sale_date, Total_Sales
FROM RankedSales
WHERE rnk = 1;  -- Picks the highest sales day for each store
GO

-- 11. Identify how many sales occurred in December 2022.

SELECT COUNT(*) AS Sales_Count                           -- Counts the number of sales.
FROM Sales
WHERE YEAR(sale_date) = 2022 AND MONTH(sale_date) = 12; -- Filters only sales made in December 2022.
GO

-- 12. List the months in the last three years where sales exceeded 1,000 units in the USA.

SELECT YEAR(sale_date) AS Year, MONTH(sale_date) AS Month
FROM Sales sa
JOIN Stores s ON sa. store_id = s. store_id
WHERE s.Country = 'USA' AND sale_date >= DATEADD(YEAR, -3, GETDATE()) 
GROUP BY YEAR(sale_date), MONTH(sale_date)
HAVING SUM(Quantity) > 1000;                                        -- Groups sales by month and filters those with total sales exceeding 1,000.
GO

-- 13. Calculate the monthly running total of sales for each store over the past four years and compare trends.

SELECT  store_id, YEAR(sale_date) AS Year, MONTH(sale_date) AS Month, 
       SUM(Quantity) AS MonthlySales,
       SUM(SUM(Quantity)) OVER (PARTITION BY  store_id ORDER BY YEAR(sale_date), MONTH(sale_date)) AS Running_Total -- Computes total monthly sales for each store.
	                                                                                                           -- Uses window function (SUM() OVER ()) to calculate a running total.
FROM Sales
WHERE sale_date >= DATEADD(YEAR, -4, GETDATE())    -- Analyzes sales trends over four years.
GROUP BY  store_id, YEAR(sale_date), MONTH(sale_date)
ORDER BY  store_id, Year, Month;
GO


--- 3. WARRANTY & QUALITY ISSUES (Warranty Claims, Product Quality & Customer Service)


-- 14. Calculate the percentage of warranty claims marked as "Warranty Void".

SELECT (COUNT(CASE WHEN repair_status = 'Warranty Void' THEN 1 END) * 100.0 / COUNT(*)) AS Percentage_Void -- Counts claims marked as Warranty Void.
FROM warranty;
GO

-- 15. How many warranty claims were filed in 2023?

SELECT COUNT(*) AS Claims_Filed -- Counts all claims.
FROM warranty
WHERE YEAR(claim_date) = 2023; -- Filters only claims made in 2023.
GO

--16. Determine how many warranty claims were filed for products launched in the last two years.

SELECT COUNT(*) AS Claims_For_Recent_Products
FROM warranty wc
JOIN sales sa ON wc.sale_id = sa.sale_id  -- Correctly linking warranty claims to sales
JOIN products p ON sa.product_id = p.product_id  -- Linking sales to products
WHERE p.launch_date >= DATEADD(YEAR, -2, GETDATE()); -- Filtering for products launched in the last two years
GO


-- 17. Calculate how many warranty claims were filed within 100 days of a product sale.

SELECT COUNT(*) AS Claims_Filed_Within_180Days
FROM warranty wc
JOIN Sales sa ON wc.sale_id = sa.sale_id
WHERE DATEDIFF(DAY, sa.sale_date, wc.claim_date) <= 100; --Filters claims filed within 100 days (DATEDIFF(DAY, sa.SaleDate, wc.ClaimDate) <= 100)
GO

-- 18. Calculate the correlation between product price and warranty claims for products sold in the last five years.

SELECT 
    CASE 
        WHEN p.Price < 500 THEN 'Low Price'
        WHEN p.Price BETWEEN 500 AND 1000 THEN 'Medium Price'
        ELSE 'High Price'                                     -- Classifies products into price ranges (Low, Medium, High).
    END AS PriceRange,
    COUNT(wc.claim_id) AS Claim_Count,                          -- Counts total sales and warranty claims per price range.
    COUNT(sa.sale_id) AS SaleCount,
    (COUNT(wc.claim_id) * 100.0 / NULLIF(COUNT(sa.sale_id), 0)) AS Claim_Percentage -- Computes the percentage of sales that resulted in claims.
FROM Sales sa
JOIN Products p ON sa.product_id = p.product_id
LEFT JOIN warranty wc ON sa.sale_id = wc.sale_id
WHERE sa.sale_date >= DATEADD(YEAR, -5, GETDATE())
GROUP BY CASE 
        WHEN p.Price < 500 THEN 'Low Price'
        WHEN p.Price BETWEEN 500 AND 1000 THEN 'Medium Price'
        ELSE 'High Price'
    END;
GO

-- 19. Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed.

SELECT TOP 1 s. store_id, 
       (COUNT(CASE WHEN wc.repair_status = 'Paid Repaired' THEN 1 END) * 100.0 / COUNT(wc.claim_id)) AS Paid_Repaired_Percentage -- Filters claims with status "Paid Repaired"
	                                                                                                                        -- Computes the percentage of claims that resulted in a paid repair for each store.
FROM warranty wc
JOIN Sales sa ON wc.sale_id = sa.sale_id
JOIN Stores s ON sa. store_id = s. store_id
GROUP BY s. store_id
ORDER BY Paid_Repaired_Percentage DESC; 
GO

-- 20. Determine how many stores have never had a warranty claim filed.

SELECT COUNT(DISTINCT s. store_id) AS Stores_Without_Claims -- Counts unique stores that never had a claim.
FROM Stores s
LEFT JOIN Sales sa ON s. store_id = sa. store_id            -- A LEFT JOIN ensures all stores are included, even those without claims.
LEFT JOIN warranty wc ON sa.sale_id = wc.sale_id
WHERE wc.claim_id IS NULL;                               -- Identifies stores with no claims.
GO

-- 21. Determine the percentage chance of receiving warranty claims after each purchase for each country.

SELECT s.Country,                                                        -- Counts sales and warranty claims per country.
       (COUNT(wc.claim_id) * 100.0 / COUNT(sa.sale_id)) AS Claim_Percentage -- Calculates the percentage of purchases that result in a claim.
FROM Sales sa
JOIN Stores s ON sa. store_id = s. store_id
LEFT JOIN warranty wc ON sa.sale_id = wc.sale_id                     -- Uses LEFT JOIN to include sales without claims.
GROUP BY s.Country;
GO


-- END --