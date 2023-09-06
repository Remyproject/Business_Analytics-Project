Use [Bussiness Analyst] ;

-- 1. HOW MUCH DID THE SELLER EARN ON THE NEW PRODUCTS IN 2020.

-- Create a Temporary table for the two tables

SELECT order_number, Client_ID, Product_code, Date_of_delivery, Delivery_amount
INTO #TempData
FROM (
    SELECT * FROM business
    UNION ALL
    SELECT * FROM business2
) CombinedData;

SELECT * FROM #TempData;

-- Filter for 2020

SELECT Order_number, Client_ID, Product_code, Date_of_delivery, Delivery_amount
INTO #Data2020
FROM #TempData
WHERE YEAR(Date_of_delivery) = 2020;


-- Identify New Products

SELECT DISTINCT Product_code
INTO #NewProducts
FROM #Data2020
EXCEPT
SELECT DISTINCT Product_code
FROM #TempData
WHERE YEAR(Date_of_delivery) = 2019;

-- Calculate Earnings for New Products

SELECT Product_code, SUM(Delivery_amount) As TotalEarning
INTO #Newproductearning
FROM #Data2020
WHERE Product_code
IN (SELECT Product_code FROM #NewProducts)
GROUP BY Product_code;

---2. FIND THE PRODUCT WITH THE BIGGEST INCREASE IN 2020 COMPARED TO 2019:

-- Sum Up Total Earnings

SELECT SUM(TotalEarning) AS TotalAmtofNewProduct
FROM #Newproductearning;

SELECT
    Product_code,
    SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
   SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
FROM #TempData
GROUP BY Product_code;


--Calculate the gain (difference) between sales in 2020 and 2019:
SELECT
    Product_code,
    TotalSales2020 - TotalSales2019 AS Gain
FROM (SELECT
    Product_code,
    SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
   SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
FROM #TempData
GROUP BY Product_code
) SalesByProduct;

-- Identify the product with the highest gain:

SELECT TOP 1
    Product_code,
    Gain
FROM (
   SELECT
    Product_code,
    TotalSales2020 - TotalSales2019 AS Gain
FROM (SELECT
    Product_code,
    SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
   SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
FROM #TempData
GROUP BY Product_code
) SalesByProduct
)  AS Gains
ORDER BY Gain DESC;

--3. CONDUCT AN ABC ANALYSIS AND CALCULATE THE NUMBER OF PRODUCTS IN GROUP ABC FOR 2 YEARS:

-- Calculate the Total sales per Unique Product

SELECT 
    Product_code,
    TotalSales2020 + TotalSales2019 AS SalesByProduct
FROM ( SELECT
    Product_code,
    SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
   SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
FROM #TempData
GROUP BY Product_code
) AS TotalSalesByProduct
ORDER BY SalesByProduct DESC;

--. Calculate cumulative sales and percentages:

SELECT
    Product_code,
    SalesByProduct,
    SUM(SalesByProduct) OVER (ORDER BY SalesByProduct DESC) AS CumulativeSales,
    CAST(SUM(SalesByProduct) OVER (ORDER BY SalesByProduct DESC) AS FLOAT) / SUM(SalesByProduct) OVER () AS CumulativePercentage
FROM (
   SELECT 
    Product_code,
    TotalSales2020 + TotalSales2019 AS SalesByProduct
FROM ( SELECT
    Product_code,
    SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
   SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
FROM #TempData
GROUP BY Product_code
) AS TotalSalesByProduct
) SortedTotalSalesByProduct;

-- Divide products into A, B, and C categories based on the Pareto principle:

SELECT
    Product_code
    SalesByProduct,
	    CASE
        WHEN CumulativePercentage <= 0.8 THEN 'A'
        WHEN CumulativePercentage <= 0.95 THEN 'B'
        ELSE 'C'
    END AS Category
FROM (
    SELECT
    Product_code,
    SalesByProduct,
    SUM(SalesByProduct) OVER (ORDER BY SalesByProduct DESC) AS CumulativeSales,
    CAST(SUM(SalesByProduct) OVER (ORDER BY SalesByProduct DESC) AS FLOAT) / SUM(SalesByProduct) OVER () AS CumulativePercentage
FROM (
   SELECT 
    Product_code,
    TotalSales2020 + TotalSales2019 AS SalesByProduct
FROM ( SELECT
    Product_code,
    SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
   SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
FROM #TempData
GROUP BY Product_code
) AS TotalSalesByProduct
) SortedTotalSalesByProduct) CumulativeSalesAndPercentage;

--Calculate the Number of Products in each group for 2 years:
SELECT
    Category,
    COUNT(*) AS TotalProductsInCategory
	FROM
(
SELECT
    Product_code
    SalesByProduct,
	    CASE
        WHEN CumulativePercentage <= 0.8 THEN 'A'
        WHEN CumulativePercentage <= 0.95 THEN 'B'
        ELSE 'C'
    END AS Category
FROM (
    SELECT
    Product_code,
    SalesByProduct,
    SUM(SalesByProduct) OVER (ORDER BY SalesByProduct DESC) AS CumulativeSales,
    CAST(SUM(SalesByProduct) OVER (ORDER BY SalesByProduct DESC) AS FLOAT) / SUM(SalesByProduct) OVER () AS CumulativePercentage
FROM (
   SELECT 
    Product_code,
    TotalSales2020 + TotalSales2019 AS SalesByProduct
FROM ( SELECT
    Product_code,
    SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
   SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
FROM #TempData
GROUP BY Product_code
) AS TotalSalesByProduct
) SortedTotalSalesByProduct
) CumulativeSalesAndPercentage
) AS Categories
GROUP BY Category;

--4. ANALYSE CUSTOMER REVENUE GROWTH IN 2020:

WITH CustomerRevenue AS (
    SELECT
        Client_ID,
        SUM(CASE WHEN YEAR(Date_of_delivery) = 2019 THEN Delivery_amount ELSE 0 END) AS TotalSales2019,
        SUM(CASE WHEN YEAR(Date_of_delivery) = 2020 THEN Delivery_amount ELSE 0 END) AS TotalSales2020
    FROM #TempData
    GROUP BY Client_ID
)
SELECT
	Client_ID,
    TotalSales2019,
	TotalSales2020,
	 CASE
        WHEN TotalSales2020 - TotalSales2019 > 0 THEN 'Positive Growth'
        WHEN TotalSales2020 - TotalSales2019 < 0 THEN 'Negative Growth'
        ELSE 'No Change'
    END AS RevenueGrowth
FROM CustomerRevenue;

  --5. CONDUCT AN RFM (RECENCY, FREQUENCY, AND MONETARY VALUE) ANALYSIS:

SELECT
    Client_ID,
    DATEDIFF(DAY, MAX(Date_of_delivery), GETDATE()) AS Recency,
    COUNT(DISTINCT Order_number) AS Frequency,
    SUM(Delivery_amount) AS MonetaryValue
INTO #RFMAnalysis
FROM #TempData
GROUP BY Client_ID;

WITH RFMSegments AS (
    SELECT
        Client_ID,
        Recency,
        Frequency,
        MonetaryValue,
        NTILE(5) OVER (ORDER BY Recency ASC) AS R_Segment,
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Segment,
        NTILE(5) OVER (ORDER BY MonetaryValue DESC) AS M_Segment
    FROM #RFMAnalysis
)

SELECT
    R_Segment,
    F_Segment,
    M_Segment,
    COUNT(*) AS CustomerCount
FROM RFMSegments
GROUP BY R_Segment, F_Segment, M_Segment
ORDER BY R_Segment, F_Segment, M_Segment;

-- 6. CHECK THE SELLER'S INCOME BY MONTH. IS THERE SEASONALITY?

SELECT
    YEAR(Date_of_delivery) AS SalesYear,
    MONTH(Date_of_delivery) AS SalesMonth,
    SUM(Delivery_amount) AS TotalIncome
INTO #MonthlyIncome
FROM #TempData
GROUP BY YEAR(Date_of_delivery), MONTH(Date_of_delivery)
ORDER BY SalesYear, SalesMonth;

WITH MonthYearAvg AS (
    SELECT
        SalesYear,
        SalesMonth,
        TotalIncome,
        AVG(TotalIncome) OVER (PARTITION BY SalesMonth) AS AvgIncome
    FROM #MonthlyIncome
)

SELECT
    SalesYear,
    SalesMonth,
    TotalIncome,
    AvgIncome,
    CASE
        WHEN TotalIncome > AvgIncome THEN 'Above Average'
        WHEN TotalIncome < AvgIncome THEN 'Below Average'
        ELSE 'Average'
    END AS IncomeComparison
FROM MonthYearAvg
ORDER BY SalesYear, SalesMonth;






