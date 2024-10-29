---Calculate the company's KPI indicators
--Net profit

SELECT 
    YEAR(soh.OrderDate) AS Year,
    SUM(LineTotal) - SUM(sod.OrderQty*p.StandardCost) AS TotalProfit
FROM 
    Sales.SalesOrderHeader soh
LEFT JOIN 
	Sales.SalesOrderDetail sod ON sod.SalesOrderID=soh.SalesOrderID
LEFT JOIN
    Production.Product p ON sod.ProductID = p.ProductID
GROUP BY YEAR(soh.OrderDate)
ORDER BY Year 


---Average Order Value - AOV

WITH SalesTable AS(
SELECT 
	YEAR(OrderDate) AS Year,
    SUM(soh.SubTotal) AS 'Tổng doanh thu',
	COUNT(DISTINCT soh.SalesOrderID) AS 'Tổng đơn hàng'
FROM 
    Sales.SalesOrderHeader soh
GROUP BY YEAR(OrderDate)
	)
SELECT
Year,
[Tổng doanh thu]/[Tổng đơn hàng] AS 'Average Order Value'
FROM SalesTable
ORDER BY Year

---Net Profit Margin

SELECT 
    YEAR(soh.OrderDate) AS Year,
    (SUM(sod.LineTotal - sod.OrderQty*p.StandardCost)*100)/SUM(sod.LineTotal) AS NetProfitMargin
FROM 
    Sales.SalesOrderHeader soh
LEFT JOIN 
	Sales.SalesOrderDetail sod ON sod.SalesOrderID=soh.SalesOrderID
LEFT JOIN
    Production.Product p ON sod.ProductID = p.ProductID
GROUP BY YEAR(soh.OrderDate)
ORDER BY Year 

---Average delivery time

SELECT 
	SUM(DATEDIFF(DAY,OrderDate,ShipDate))/
    COUNT(DISTINCT SalesOrderID) AS TotalOrders
FROM 
    Sales.SalesOrderHeader

---Production Cost per Unit
SELECT
SUM(sod.OrderQty*p.StandardCost)/SUM(sod.OrderQty)
FROM Sales.SalesOrderDetail sod 
LEFT JOIN
    Production.Product p ON sod.ProductID = p.ProductID




















