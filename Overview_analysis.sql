USE AdventureWorks2019
GO
---Top 3 products with the highest sales each year
DROP TABLE IF EXISTS #Productsales
SELECT
	PP.Name AS ProductName,
	PPS.Name AS ProductSubCategoryName,
	YEAR(SOH.OrderDate) AS Year,
	SUM(SOD.OrderQty) AS TotalQuantity,
	SUM(SOD.OrderQty*SOD.UnitPrice) AS TotalSales,
	ROW_NUMBER() OVER(
		PARTITION BY YEAR(SOH.OrderDate)
		ORDER BY SUM(SOD.OrderQty*SOD.UnitPrice) DESC
		) AS Rank
into #Productsales
FROM (
	Production.Product PP
	LEFT JOIN Sales.SalesOrderDetail SOD 
	ON PP.ProductID=SOD.ProductID
	LEFT JOIN Sales.SalesOrderHeader SOH 
	ON SOD.SalesOrderID=SOH.SalesOrderID
	LEFT JOIN Production.ProductSubcategory PPS 
	ON PPS.ProductSubcategoryID=PP.ProductSubcategoryID
	)
GROUP BY 
	PP.Name, 
	PPS.Name, 
	YEAR(SOH.OrderDate)
HAVING 
	SUM(SOD.OrderQty*SOD.UnitPrice) IS NOT NULL
SELECT
*
FROM #Productsales
WHERE Rank<=3
ORDER BY Year

---	Overview of company revenue by year			

SELECT
    YEAR(OrderDate) AS Year,
    COUNT(DISTINCT SalesOrderID) AS OrdersQty,
    SUM(SubTotal) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY
     YEAR(OrderDate)
ORDER BY Year

---Top RESELLER customers spend the most
SELECT TOP 5
	SS.BusinessEntityID,
	SS.Name,
	SUM(SubTotal) AS 'TotalStoreSales'
FROM (
	Sales.Store SS
	LEFT JOIN Sales.Customer SC 
	ON SS.BusinessEntityID=SC.StoreID
	LEFT JOIN Sales.SalesOrderHeader SSOH 
	ON SC.CustomerID=SSOH.CustomerID
	)
WHERE OnlineOrderFlag=0
GROUP BY 
	SS.BusinessEntityID,
	SS.Name
ORDER BY TotalStoreSales DESC

---Top online customers spend the most
SELECT TOP 5
	PP.BusinessEntityID,
	CONCAT_WS(' ',FirstName, MiddleName, LastName) AS 'FullName',
	PE.EmailAddress,
	PPP.PhoneNumber,
	SUM(SubTotal) AS 'TotalOnlinePaid'
FROM (
	Sales.SalesOrderHeader SSOH
	LEFT JOIN Sales.Customer SC 
	ON SC.CustomerID=SSOH.CustomerID
	LEFT JOIN Person.Person PP 
	ON SC.CustomerID=PP.BusinessEntityID
	LEFT JOIN Person.EmailAddress PE 
	ON PP.BusinessEntityID=PE.BusinessEntityID
	LEFT JOIN Person.PersonPhone PPP 
	ON PP.BusinessEntityID=PPP.BusinessEntityID
	)
WHERE 
	OnlineOrderFlag=1
	AND PP.BusinessEntityID IS NOT NULL
GROUP BY 
	PP.BusinessEntityID,
	CONCAT_WS(' ',FirstName, MiddleName, LastName),
	PE.EmailAddress,
	PPP.PhoneNumber
ORDER BY TotalOnlinePaid DESC


--- Online sales and resells per year
SELECT
    YEAR(soh.OrderDate) AS Year,
    SUM(CASE WHEN soh.OnlineOrderFlag = 0 
	THEN sod.LineTotal ELSE 0 END) 
	AS TotalStoreSales,
    SUM(CASE WHEN soh.OnlineOrderFlag = 1 
	THEN sod.LineTotal  ELSE 0 END) 
	AS TotalOnlineSales
FROM 
    Sales.SalesOrderHeader soh
LEFT JOIN 
    Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY 
    YEAR(soh.OrderDate)
ORDER BY 
    Year

---The reasons for selling helps the company sell the most products
WITH SalesReasonTable AS(
	SELECT
		YEAR(OrderDate) AS Year,
		SSR.Name AS SalesReasonName,
		SUM(SSOD.OrderQty) AS TotalQuantity,
		ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate) 
		ORDER BY SUM(SSOH.SubTotal) DESC) AS Rank
	FROM Sales.SalesReason SSR
		LEFT JOIN Sales.SalesOrderHeaderSalesReason SSOHS 
		ON SSR.SalesReasonID=SSOHS.SalesReasonID
		LEFT JOIN Sales.SalesOrderHeader SSOH 
		ON SSOHS.SalesOrderID=SSOH.SalesOrderID
		LEFT JOIN Sales.SalesOrderDetail SSOD
		ON SSOH.SalesOrderID=SSOD.SalesOrderID
	GROUP BY 
		YEAR(OrderDate),
		SSR.Name
	)
SELECT
	*
FROM SalesReasonTable
WHERE 
	Rank<=3
	AND TotalQuantity IS NOT NULL

---Top products on the decline (sales decline year by year)
WITH SalesTrend AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
		ps.Name AS ProductSubCategoryName,
        YEAR(soh.OrderDate) AS Year,
        SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales,
        LAG(SUM(sod.OrderQty * sod.UnitPrice)) 
		OVER (PARTITION BY p.ProductID 
		ORDER BY YEAR(soh.OrderDate)) AS PreviousYearSales
    FROM 
        Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh 
	ON sod.SalesOrderID = soh.SalesOrderID
    JOIN Production.Product p 
	ON sod.ProductID = p.ProductID
	JOIN Production.ProductSubcategory ps 
	ON p.ProductSubcategoryID=ps.ProductSubcategoryID
    GROUP BY 
        p.ProductID, p.Name,ps.Name, YEAR(soh.OrderDate)
)
SELECT
	ProductName,
	ProductSubCategoryName,
	Year,
	(SUM(PreviousYearSales-TotalSales)/SUM(PreviousYearSales)) AS '%GapSales'
FROM SalesTrend
WHERE 
    PreviousYearSales IS NOT NULL
    AND TotalSales < PreviousYearSales
GROUP BY 
	ProductName,
	ProductSubCategoryName,
	Year
HAVING 
	(SUM(PreviousYearSales-TotalSales)/SUM(PreviousYearSales))>0.5
ORDER BY '%GapSales' DESC, Year

---Sales by Region
SELECT TOP 3
    t.TerritoryID,
    t.Name AS TerritoryName,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales
FROM (
    Sales.SalesOrderDetail sod
	LEFT JOIN Sales.SalesOrderHeader soh 
	ON sod.SalesOrderID = soh.SalesOrderID
	LEFT JOIN Sales.Customer c 
	ON soh.CustomerID = c.CustomerID
	LEFT JOIN Sales.SalesTerritory t 
	ON c.TerritoryID = t.TerritoryID
	)
GROUP BY 
    t.TerritoryID, t.Name
ORDER BY 
    TotalSales DESC

---PRODUCTS WITH HIGHEST INVENTORY QUANTITY AND LONGEST INVENTORY

SELECT 
	p.ProductID,
	p.Name AS ProductName,
	SUM(pi.Quantity) AS TotalStock,
	DATEDIFF(MONTH, pi.ModifiedDate,'2014-08-30') 
	AS MonthsInInventory
FROM 
	Production.ProductInventory pi
	LEFT JOIN Production.Product p
	ON pi.ProductID = p.ProductID
WHERE 
	DATEDIFF(MONTH, pi.ModifiedDate,'2014-08-30')>12
GROUP BY 
	p.Name, 
	P.ProductID,
	DATEDIFF(MONTH, pi.ModifiedDate,'2014-08-30')
HAVING SUM(pi.Quantity)>1000
ORDER BY 
	TotalStock DESC, 
	MonthsInInventory DESC

----Best selling products by year

DROP TABLE IF EXISTS #ProductQuantity
SELECT
	PP.Name AS ProductName,
	PPS.Name AS ProductSubCategoryName,
	YEAR(SOH.OrderDate) AS Year,
	SUM(SOD.OrderQty) AS TotalQuantity,
	ROW_NUMBER() OVER(
		PARTITION BY YEAR(SOH.OrderDate)
		ORDER BY SUM(SOD.OrderQty) DESC
		) AS Rank
into #ProductQuantity
FROM (
	Production.Product PP
	LEFT JOIN Sales.SalesOrderDetail SOD 
	ON PP.ProductID=SOD.ProductID
	LEFT JOIN Sales.SalesOrderHeader SOH 
	ON SOD.SalesOrderID=SOH.SalesOrderID
	LEFT JOIN Production.ProductSubcategory PPS 
	ON PPS.ProductSubcategoryID=PP.ProductSubcategoryID
	)
WHERE YEAR(SOH.OrderDate) IS NOT NULL
GROUP BY 
	PP.Name, 
	PPS.Name, 
	YEAR(SOH.OrderDate)
SELECT
*
FROM #ProductQuantity
WHERE Rank <=3
ORDER BY Year
