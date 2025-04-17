![APP](https://github.com/user-attachments/assets/a37a5a25-e479-4842-81c1-8c62bbda70d5)

# APPLE-STORE-SALES-SQL-ANALYSIS
## TABLE OF CONTENT 

[Project Overview](#project-overview)

[Project Focus](#project-focus)

[Data Sources](#data-sources)

[Datasets structure](#datasets-structure)

[Tools](#tools)

[DATA ANALYSIS](#data-analysis)

[Objective](#objective)

[STORES AND PRODUCTS PERFORMANCE(Store Performance, Product Sales and Categories)](#store-and-product-performance(store-performance,-product-sales-and-categories))

[SALES TRENDS(Sales Trends, Seasonal Patterns and Bestselling Insights)](#sale-trend(sales-trends,-seasonal-patterns-and-bestselling-insights))

[WARRANTY AND QUALITY ISSUES(Warranty Claims, Product Quality And Customer Service)](#waranty-and-quality-issues(warranty-claims,-Product-quality-and-customer-service))

[key takeaways and implication](#key-takeaways-and-implication)

## Project Overview
This project showcases advanced SQL querying techniques through the analysis of over 1 million rows of Apple Store sales data. The dataset includes details on products, stores, sales transactions, and warranty claims from Apple retail locations worldwide.

By leveraging SQL, this project uncovers key business insights, including:

1.  Sales performance trends across different stores and regions
   
2. Store performance analysis to evaluate profitability and efficiency
   
3. Warranty claims patterns and their impact on revenue

## Project Focus

This project emphasizes:
- **Complex Joins and Aggregations**: Advanced SQL joins and aggregations.
- **Window Functions and CTEs**: Utilizing functions for running totals, growth analysis, and time-based queries.
- **Data Segmentation**: Time-based analysis for product performance.
- **Correlation Analysis**: Identifying relationships between variables like product price and warranty claims.
- **Real-World Problem Solving**: addressing some hypothetical business problems.

### Data Sources.
Data used in this project is secondary data sourced from kaggle.com. The data is contained in multiple tables as described below.

## Datasets structure.
1.**Category Data:** Contains category_id and category_name, mapping product categories.

2.**Products Data:** Contains product_id, product_name, category_id, launch_date, and price, linking products to categories.

3.**Sales Data:** Contains sale_id, sale_date, store_id, product_id, and quantity, tracking sales transactions.

4.**Stores Data:** Contains store_id, store_name, city, and country, identifying store locations.

5.**Warranty Data:** Contains claim_id, claim_date, sale_id, and repair_status, recording warranty claims.

### Entity-Relationship Diagram (ERD)
![ERD](https://github.com/user-attachments/assets/d7ce849a-3f99-4e0c-98b6-264f6854a084)

### Tools.
![pp](https://github.com/user-attachments/assets/91e29a1d-f22b-40c1-975f-bfa2c1247b8f)

- **Excel** - Data cleaning.
   - [Download here](https://www.microsoft.com/en-us/download/details.aspx?id=49117)
- **SQL(SSMS)**- Data analysis.
   - [Download here](https://learn.microsoft.com/en-us/ssms/download-sql-server-management-studio-ssms)
- **Power BI**- Data reporing and visualization.
   - [Download here](https://www.microsoft.com/en-us/download/details.aspx?id=58494)

# DATA ANALYSIS.

### Objective:

This analysis seeks to answer real-world business questions, such as:

- Which Apple stores generate the highest revenue?

- How do stores compare in terms of sales growth and profitability?

- What are the top-performing products in terms of sales?

- How do warranty claims vary across different regions and product types?

- Are there seasonal trends in sales and warranty claims?

# STORES AND PRODUCTS PERFORMANCE(Store Performance, Product Sales and Categories)

## 1. Find the number of stores in each country.
Objective:
•	Determine the distribution of stores across different countries.

```SQL
SELECT Country, COUNT(*) AS Store_Count 
FROM Stores
GROUP BY Country;                      
GO
```
Insight

- This query helps understand the geographical distribution of stores. Identifying countries with a high number of stores can reveal key markets, while countries with fewer stores might present expansion opportunities.

## 2. Calculate the total number of units sold by each store.
Objective:
•	Measure sales volume across different stores.

```sql
SELECT store_id, SUM(Quantity) AS Total_Units_Sold 
FROM Sales										
GROUP BY store_id   
ORDER BY Total_Units_Sold DESC; 
GO
```
Insight

- This metric highlights the sales volume of each store, allowing comparisons between high-performing and underperforming stores. It would helps in resource allocation, inventory management and marketing efforts.

## 3. Identify which store had the highest total units sold in the last year.
Objective:
•	Determine the top-performing store based on units sold.

```sql
SELECT TOP 1 WITH TIES store_id, SUM(Quantity) AS Total_Units_Sold 
FROM Sales
WHERE sale_date >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE))
GROUP BY store_id
ORDER BY Total_Units_Sold DESC;
GO
```
Insight

- Understanding which store sold the most units over the past year can highlight best practices, store location advantages, or successful promotional strategies. Other stores can learn from this top-performing store.

## 4. Analyze the year-by-year growth ratio for each store.
Objective:
•	Track store performance over time.

```sql
SELECT  store_id, YEAR(sale_date) AS Year,
       SUM(Quantity) AS TotalSales,
       LAG(SUM(Quantity)) OVER (PARTITION BY store_id ORDER BY YEAR(sale_date)) AS PreviousYearSales,     
       (SUM(Quantity) - LAG(SUM(Quantity)) OVER (PARTITION BY store_id ORDER BY YEAR(sale_date))) * 100.0 / 
       NULLIF(LAG(SUM(Quantity)) OVER (PARTITION BY store_id ORDER BY YEAR(sale_date)), 0) AS GrowthPercentage 
	                                                                                                         
FROM Sales
GROUP BY  store_id, YEAR(sale_date);
GO
```
Insight

- This analysis identifies stores experiencing significant growth or decline. Stores with consistent positive growth indicate successful business strategies, while stores with declining sales may need operational changes or additional support.

## 5. Find the average price of products in each category.
Objective:
•	Determine price variations across different product categories.

```sql
SELECT category_id, AVG(Price) AS Avg_Price 
FROM Products
GROUP BY category_id;                   
GO
```
Insight

- Understanding category-wise pricing helps in pricing strategy adjustments. If a category's average price is too high, it may lead to lower sales, while a low price might indicate undervaluation of a product segment

## 6. Identify the product category with the most warranty claims filed in the last two years.
Objective:
•	Analyze product reliability based on customer claims to Identify  product categories with potential quality issues.

```sql
SELECT TOP 1 
    p.category_id, 
    COUNT(*) AS Claim_Count
FROM warranty w
JOIN sales s ON w.sale_id = s.sale_id  
JOIN products p ON s.product_id = p.product_id  
WHERE w.claim_date >= DATEADD(YEAR, -2, GETDATE())  
GROUP BY p.category_id
ORDER BY Claim_Count DESC;
GO
```
Insight

- A high number of warranty claims in a category could indicate product quality issues. The company can use this data to improve manufacturing processes or adjust warranty policies.

## 7. Identify the least selling product in each country for each year.
Objective:
•	Find underperforming products by region and year using CTE with.

```sql
WITH ProductSales AS (                                   
    SELECT s. store_id, s.Country, YEAR(sa.sale_date) AS SaleYear, sa.product_id, SUM(sa.Quantity) AS TotalSales
    FROM Sales sa
    JOIN Stores s ON sa. store_id = s. store_id
    GROUP BY s. store_id, s.Country, YEAR(sa.sale_date), sa.product_id
)                                                                   .
SELECT Country, SaleYear, product_id, MIN(TotalSales) AS Least_Sold 
FROM ProductSales
GROUP BY Country, SaleYear, product_id;
GO
```
Insight

- The results provide an additional opportunity to cross-check underperforming products and investigate regional consumer preferences.

# SALES TRENDS(Sales Trends, Seasonal Patterns and Bestselling Insights)
---

## 8. Count the number of unique products sold in the last year Per Store & Category.
Objective:
•	Measure product diversity in each store to understand product preferences by location.

```sql
SELECT s.store_id, p.category_id, c.category_name, COUNT(DISTINCT s.product_id) AS Unique_Products_Sold  
FROM Sales s  
JOIN Products p ON s.product_id = p.product_id  
JOIN Category c ON p.category_id = c.category_id  
WHERE s.sale_date >= DATEADD(YEAR, -1, GETDATE())  
GROUP BY s.store_id, p.category_id, c.category_name;
GO
```
Insight

- Identifying stores that sell a diverse range of products can highlight locations with high customer engagement. Stores with limited product variety may need to expand their offerings to drive sales.

## 9. Identify the best-selling day for each store.
Objective:
•	Determine peak sales days for each store.

```sql
WITH DailySales AS (
    SELECT store_id, sale_date, SUM(quantity) AS Total_Sales  
    FROM Sales
    GROUP BY store_id, sale_date
),
RankedSales AS (
    SELECT store_id, sale_date, Total_Sales,
           RANK() OVER (PARTITION BY store_id ORDER BY Total_Sales DESC) AS rnk 
    FROM DailySales
)
SELECT store_id, sale_date, Total_Sales
FROM RankedSales
WHERE rnk = 1; 
GO
```
Insight

- Recognizing peak sales days can help stores optimize staffing, inventory, and promotions. Stores can capitalize on high-traffic days by running targeted marketing campaigns.

## 10. Identify how many sales occurred in December 2022.
Objective:
•	Measure sales performance in a specific month to helps in seasonal trend analysis 

```sql
SELECT COUNT(*) AS Sales_Count                          
FROM Sales
WHERE YEAR(sale_date) = 2022 AND MONTH(sale_date) = 12; 
GO
```
Insight

- December sales trends are essential for evaluating holiday season performance. A high volume may indicate successful seasonal campaigns, while low sales might suggest the need for better holiday promotions.

## 11. List the months in the last three years where sales exceeded 1,000 units in the USA.
Objective:
•	Identify peak sales periods in the USA to understand demand surges.

```sql
SELECT YEAR(sale_date) AS Year, MONTH(sale_date) AS Month
FROM Sales sa
JOIN Stores s ON sa. store_id = s. store_id
WHERE s.Country = 'USA' AND sale_date >= DATEADD(YEAR, -3, GETDATE()) 
GROUP BY YEAR(sale_date), MONTH(sale_date)
HAVING SUM(Quantity) > 1000;                                       
GO
```
Insight

- Identifying peak sales months helps businesses prepare for demand surges. It enables better inventory planning, staffing, and marketing initiatives tailored to high-sales periods.

## 12. Calculate the monthly running total of sales for each store over the past four years and compare trends.
Objective:
•	Track long-term sales trends at a store level to identify sales growth or decline trends.

```sql
SELECT  store_id, YEAR(sale_date) AS Year, MONTH(sale_date) AS Month, 
       SUM(Quantity) AS MonthlySales,
       SUM(SUM(Quantity)) OVER (PARTITION BY  store_id ORDER BY YEAR(sale_date), MONTH(sale_date)) AS Running_Total
	                                                                                                        
FROM Sales
WHERE sale_date >= DATEADD(YEAR, -4, GETDATE())    
GROUP BY  store_id, YEAR(sale_date), MONTH(sale_date)
ORDER BY  store_id, Year, Month;
GO
```
Insight

- A running total helps in visualizing long-term sales trends. Stores with fluctuating sales may require investigation into seasonal effects, economic conditions, or store-level operational challenges.

# WARRANTY AND QUALITY ISSUES(Warranty Claims, Product Quality and Customer Service)

## 13. Calculate the percentage of warranty claims marked as "Warranty Void".

Objective:
•	Determine the proportion of rejected warranty claims to understand the warranty policy effectiveness.

```sql
SELECT (COUNT(CASE WHEN repair_status = 'Warranty Void' THEN 1 END) * 100.0 / COUNT(*)) AS Percentage_Void
FROM warranty;
GO
```
Insight

- A high percentage of voided claims may indicate customer misunderstanding of warranty policies or an issue with policy transparency. stores may need to improve communication regarding warranty coverage.

## 14. How many warranty claims were filed in 2023?
Objective:
•	Measure customer complaints related to product quality in 2023.

```sql
SELECT COUNT(*) AS Claims_Filed 
FROM warranty
WHERE YEAR(claim_date) = 2023;
GO
```
Insight

- Tracking total warranty claims helps gauge overall product quality and customer post-purchase satisfaction. An increase in claims could indicate emerging quality control issues.

##15. Determine how many warranty claims were filed for products launched in the last two years.
Objective:
•	Evaluate product reliability for newly launched items to identify defective or unreliable new products.

```sql
SELECT COUNT(*) AS Claims_For_Recent_Products
FROM warranty wc
JOIN sales sa ON wc.sale_id = sa.sale_id 
JOIN products p ON sa.product_id = p.product_id  
WHERE p.launch_date >= DATEADD(YEAR, -2, GETDATE()); 
GO
```
Insight

- High claims for recently launched products might point to manufacturing defects or design flaws. Store could use this data to adjust production and improve new product testing.

## 16. Calculate how many warranty claims were filed within 100 days of a product sale.
Objective:
•	Measure early failure rates of products to help detect manufacturing defects.

```sql
SELECT COUNT(*) AS Claims_Filed_Within_180Days
FROM warranty wc
JOIN Sales sa ON wc.sale_id = sa.sale_id
WHERE DATEDIFF(DAY, sa.sale_date, wc.claim_date) <= 100; 
GO
```
Insight

- Warranty claims shortly after purchase could signal defects, transportation damage, or misrepresented product expectations. This insight is crucial for refining quality control and post-sale support.

## 17. Calculate the correlation between product price and warranty claims for products sold in the last five years.
Objective:
•	Understand if higher or lower-priced products have more warranty claims to help identify whether price correlates with product quality.

```sql
SELECT 
    CASE 
        WHEN p.Price < 500 THEN 'Low Price'
        WHEN p.Price BETWEEN 500 AND 1000 THEN 'Medium Price'
        ELSE 'High Price'                                     
    END AS PriceRange,
    COUNT(wc.claim_id) AS Claim_Count,                       
    COUNT(sa.sale_id) AS SaleCount,
    (COUNT(wc.claim_id) * 100.0 / NULLIF(COUNT(sa.sale_id), 0)) AS Claim_Percentage 
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
```
Insight

- If higher-priced products have more claims, it might indicate premium product defects or unrealistic customer expectations. Conversely, if lower-priced products dominate claims, quality compromises might be the issue.

## 18. Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed.
Objective:
•	Identify stores with the highest paid warranty repairs.

```sql
SELECT TOP 1 s. store_id, 
       (COUNT(CASE WHEN wc.repair_status = 'Paid Repaired' THEN 1 END) * 100.0 / COUNT(wc.claim_id)) AS Paid_Repaired_Percentage 
	                                                                                                                       
FROM warranty wc
JOIN Sales sa ON wc.sale_id = sa.sale_id
JOIN Stores s ON sa. store_id = s. store_id
GROUP BY s. store_id
ORDER BY Paid_Repaired_Percentage DESC; 
GO
```
Insight

- Stores with a high percentage of paid repairs might indicate customers opting for repairs over replacements. It could highlight warranty policy inefficiencies or affordability concerns.

## 19. Determine how many stores have never had a warranty claim filed.
Objective:
•	Identify stores with no recorded warranty claims.

```sql
SELECT COUNT(DISTINCT s. store_id) AS Stores_Without_Claims 
FROM Stores s
LEFT JOIN Sales sa ON s. store_id = sa. store_id            
LEFT JOIN warranty wc ON sa.sale_id = wc.sale_id
WHERE wc.claim_id IS NULL;                         
GO
```
Insight

- Stores with no claims could indicate high product reliability or low sales volume. Cross-referencing with sales data will reveal whether customers simply aren't filing claims or if the store isn't selling high-risk products.

## 20. Determine the percentage chance of receiving warranty claims after each purchase for each country.
Objective:
•	Identify stores with no recorded warranty claims to help in product quality analysis across different markets.

```sql
SELECT s.Country,                                                       
       (COUNT(wc.claim_id) * 100.0 / COUNT(sa.sale_id)) AS Claim_Percentage 
FROM Sales sa
JOIN Stores s ON sa. store_id = s. store_id
LEFT JOIN warranty wc ON sa.sale_id = wc.sale_id                     
GROUP BY s.Country;
GO
```
Insight

- Understanding the likelihood of warranty claims by country helps tailor warranty policies to regional customer behaviors. Higher claim rates in specific countries may indicate stricter consumer protection laws or quality perception issues.


### key takeaways and implications.

1. Store-Level Insights.
	- High-performing stores can serve as benchmarks for improving underperforming stores.
	- Sales trends can guide inventory stocking and marketing strategies.
	- Peak sales days and months would help in planning for promotional events.

2. Product & Category-Level Insights.
	- Least-selling products should be evaluated for discontinuation or rebranding.
	- The relationship between pricing and warranty claims would help to guide pricing and product quality decisions.
	- Categories with high warranty claims need quality control improvements.

3. Customer Experience & Warranty Issues.
	- High warranty claim percentages could indicate manufacturing issues or unclear warranty policies.
	- Stores with a high "Paid Repair" percentage may need warranty policy improvements.
	- Regional variations in claim rates help stores tailor their after-sales service strategies.

**AUTHOR: ELVIS MWANGI**
