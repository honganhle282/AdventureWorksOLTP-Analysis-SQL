----ABC Inventory Classification Model

WITH Inventory_Value AS(
	SELECT
		SOD.ProductID,
		SUM(OrderQty) AS AnnualQuantitySold,
		SUM(OrderQty*UnitPrice) AS AnnualUsageValue
	FROM 
		Sales.SalesOrderDetail SOD 
		LEFT JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID=SOH.SalesOrderID
	WHERE YEAR(SOH.OrderDate) IS NOT NULL
	GROUP BY 
		SOD.ProductID,
		YEAR(SOH.OrderDate)
	),
Ranked_Products AS (
    SELECT 
        ProductID,
        AnnualQuantitySold,
        AnnualUsageValue,
        SUM(AnnualUsageValue) OVER () AS TotalAnnualUsageValue,
        SUM(AnnualUsageValue) OVER (ORDER BY AnnualUsageValue DESC) AS CumulativeUsageValue
    FROM 
        Inventory_Value
	)
SELECT 
    ProductID,
    AnnualQuantitySold,
    AnnualUsageValue,
    CASE 
        WHEN CumulativeUsageValue <= 0.7 * TotalAnnualUsageValue THEN 'A'
        WHEN CumulativeUsageValue <= 0.9 * TotalAnnualUsageValue THEN 'B'
        ELSE 'C'
    END AS ABC_Category
FROM 
    Ranked_Products
ORDER BY 
    AnnualUsageValue DESC