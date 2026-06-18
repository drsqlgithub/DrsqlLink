USE AdventureWorks2025
GO

/*
To add for testing
CREATE NONCLUSTERED INDEX Index1 ON [Sales].[SalesOrderHeader] ([Status],[OrderDate],[TotalDue]) INCLUDE ([CustomerID],[SalesPersonID],[TerritoryID])
CREATE NONCLUSTERED INDEX Index2 ON [Person].[Person] ([Suffix]) INCLUDE ([FirstName],[LastName])
--I doubt I would actually include this index, but I was just doing what it told me for this demo
CREATE NONCLUSTERED INDEX Index3 ON [Sales].[SalesOrderHeader] ([Status],[TerritoryID],[OrderDate],[TotalDue]) INCLUDE ([CustomerID],[SalesPersonID])
*/
--This is the source queries for testing the performance improvement of using a CTE to filter data before joining it with other tables. 

DROP TABLE IF EXISTS #SalesOrderHeaderTT,#SalesTerritoryTT, #PersonTT;
GO

--https://drsql.link/2025/11/12/using-formatmessage-in-sql-server-to-enhance-my-temporary-procedure/
CREATE OR ALTER PROCEDURE #OutputMessageNOW 
@Message nvarchar(1000) = 'Default Message', --set null if not needed
@AddTimeToMessageFlag bit = 1, --adds system time to the message
@AddSpidToMessageFlag bit = 0, --add spid to the message
@AddOriginalLoginToOutputFlag bit = 0 --add the user who is logged in
AS 
BEGIN 
-----------------------------------------------
DECLARE @output nvarchar(1000)
SET @output = FORMATMESSAGE(N'%s%s%s%s',
       --message
       COALESCE(@Message,''),
       --messagetime
       CASE WHEN @AddTimeToMessageFlag = 1 
            THEN CONCAT('Message Time - ',
                     CAST(SYSDATETIME() AS varchar(100)),' : ')
            ELSE '' END,
       --process id
       CASE WHEN @AddSpidToMessageFlag = 1 
            THEN CONCAT('ProcessId - ',@@SPID,' : ')
            ELSE '' END,
       --logged in user
       CASE WHEN @AddOriginalLoginToOutputFlag = 1 
            THEN CONCAT('LoggedInUserId - ',ORIGINAL_LOGIN(),' : ')
            ELSE '' END)
------------------------------------------------
SET @output = SUBSTRING(@output,1,LEN(@output) - 2);
RAISERROR(@output,10,1) WITH NOWAIT; 
END;

GO

EXEC #OutputMessageNOW 'Original query'

SET STATISTICS IO ON;

SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    sp.FirstName + ' ' + sp.LastName AS SalesPersonName,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    p.Suffix 
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesPerson sps ON soh.SalesPersonID = sps.BusinessEntityID
INNER JOIN Person.Person sp ON sps.BusinessEntityID = sp.BusinessEntityID
INNER JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
WHERE 
    soh.OrderDate >= '2013-01-01'
    AND soh.TotalDue > 1000
    AND st.[Group] = 'North America'
    AND soh.Status = 5
    AND p.Suffix IS NOT NULl
    ;
SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'First partial filtering query';

SET STATISTICS IO ON;

--partial filtering of Sales Order Header table using CTE
WITH SalesOrderHeaderCTE as
(
    SELECT *
    FROM   Sales.SalesOrderHeader
    WHERE  TotalDue > 1000
)

SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    sp.FirstName + ' ' + sp.LastName AS SalesPersonName,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    p.Suffix 
FROM SalesOrderHeaderCTE soh
INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesPerson sps ON soh.SalesPersonID = sps.BusinessEntityID
INNER JOIN Person.Person sp ON sps.BusinessEntityID = sp.BusinessEntityID
INNER JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
WHERE 
    soh.OrderDate >= '2013-01-01'
    AND st.[Group] = 'North America'
    AND soh.Status = 5
    AND p.Suffix IS NOT NULl;

SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'All filters into CTE';

SET STATISTICS IO ON;
    

WITH SalesOrderHeaderCTE as
(
    SELECT *
    FROM   Sales.SalesOrderHeader
    WHERE  TotalDue > 1000
      AND  OrderDate >= '2013-01-01'
      AND  Status = 5
),
SalesTerritoryCTE AS 
(
    SELECT *
    FROM Sales.SalesTerritory
    WHERE [Group] = 'North America'
),
PersonCTE AS
(
    SELECT *
    FROM Person.Person
    WHERE Suffix IS NOT NULL
)

SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    sp.FirstName + ' ' + sp.LastName AS SalesPersonName,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    p.Suffix 
FROM SalesOrderHeaderCTE soh
INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN PersonCTE  p ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesPerson sps ON soh.SalesPersonID = sps.BusinessEntityID
INNER JOIN Person.Person sp ON sps.BusinessEntityID = sp.BusinessEntityID
INNER JOIN SalesTerritoryCTE st ON soh.TerritoryID = st.TerritoryID;

SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'Only used columns in the CTE''s';

SET STATISTICS IO ON;    


--full filtering of Sales Order Table.    
WITH SalesOrderHeaderCTE as
(
    SELECT SalesOrderID
           ,OrderDate
           ,CustomerID
           ,SalesPersonID
           ,TerritoryID
           ,TotalDue
    FROM   Sales.SalesOrderHeader
    WHERE  TotalDue > 1000
      AND  OrderDate >= '2013-01-01'
      AND  Status = 5
),
SalesTerritoryCTE AS 
(
    SELECT TerritoryID
            ,Name
            ,[Group]
    FROM Sales.SalesTerritory
    WHERE [Group] = 'North America'
),
PersonCTE AS
(
    SELECT BusinessEntityID
           ,FirstName
           ,LastName
        ,Suffix
    FROM Person.Person
    WHERE Suffix IS NOT NULL
)

SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    sp.FirstName + ' ' + sp.LastName AS SalesPersonName,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    p.Suffix 
FROM SalesOrderHeaderCTE soh
INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN PersonCTE  p ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesPerson sps ON soh.SalesPersonID = sps.BusinessEntityID
INNER JOIN Person.Person sp ON sps.BusinessEntityID = sp.BusinessEntityID
INNER JOIN SalesTerritoryCTE st ON soh.TerritoryID = st.TerritoryID;

SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'Temp Tables';

SET STATISTICS IO ON;


    SELECT SalesOrderID
           ,OrderDate
           ,CustomerID
           ,SalesPersonID
           ,TerritoryID
           ,TotalDue
    INTO #SalesOrderHeaderTT
    FROM   Sales.SalesOrderHeader
    WHERE  TotalDue > 1000
      AND  OrderDate >= '2013-01-01'
      AND  Status = 5

    SELECT TerritoryID
            ,Name
            ,[Group]
    INTO #SalesTerritoryTT
    FROM Sales.SalesTerritory
    WHERE [Group] = 'North America'


    SELECT BusinessEntityID
           ,FirstName
           ,LastName
        ,Suffix
    INTO #PersonTT
    FROM Person.Person
    WHERE Suffix IS NOT NULL

SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    sp.FirstName + ' ' + sp.LastName AS SalesPersonName,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    p.Suffix 
FROM #SalesOrderHeaderTT soh
INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN #PersonTT  p ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesPerson sps ON soh.SalesPersonID = sps.BusinessEntityID
INNER JOIN Person.Person sp ON sps.BusinessEntityID = sp.BusinessEntityID
INNER JOIN #SalesTerritoryTT st ON soh.TerritoryID = st.TerritoryID;

SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'Done';



GO