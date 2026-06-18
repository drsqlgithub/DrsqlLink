--Example code to run to see the plans and statistics for example queries.

USE AdventureWorks2025
GO
SET NOCOUNT ON;
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

-- Query to show each company's sum of sales if they have more than 400 in sales for 2013
SELECT c.CustomerID,
       s.Name AS CompanyName,
       SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.Customer c
        ON soh.CustomerID = c.CustomerID
    INNER JOIN Sales.Store AS s
        ON s.BusinessEntityID = c.StoreID
WHERE EXISTS (SELECT 1
               FROM  Sales.SalesOrderHeader sohExists
               WHERE sohExists.OrderDate >= '2022-01-01'
                 AND sohExists.OrderDate < '2023-01-01'
                 AND c.CustomerID = sohExists.CustomerID
               GROUP BY sohExists.CustomerID
                HAVING SUM(sohExists.TotalDue) > 290000)
GROUP BY c.CustomerID , s.Name              
ORDER BY TotalSales DESC;

SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'Row Filter Moved to CTE';

SET STATISTICS IO ON;

WITH SalesOrderHeaderCTE AS (
               SELECT CustomerId, TotalDue
               FROM  Sales.SalesOrderHeader sohExists
               WHERE sohExists.OrderDate >= '2022-01-01'
                 AND sohExists.OrderDate < '2023-01-01'
)
SELECT c.CustomerID,
       s.Name AS CompanyName,
       SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.Customer c
        ON soh.CustomerID = c.CustomerID
    INNER JOIN Sales.Store AS s
        ON s.BusinessEntityID = c.StoreID
WHERE EXISTS ( SELECT 1
                FROM  SalesOrderHeaderCTE AS sohExists
                WHERE c.CustomerID = sohExists.CustomerID
               GROUP BY sohExists.CustomerID
                HAVING SUM(sohExists.TotalDue) > 290000)
GROUP BY c.CustomerID , s.Name              
ORDER BY TotalSales DESC;

SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'Grouping and Row Filter Moved to CTE';

SET STATISTICS IO ON;

WITH SalesOrderHeaderCTE AS (
               SELECT CustomerId
               FROM  Sales.SalesOrderHeader sohExists
               WHERE sohExists.OrderDate >= '2022-01-01'
                 AND sohExists.OrderDate < '2023-01-01'
               GROUP BY sohExists.CustomerID
                HAVING SUM(sohExists.TotalDue) > 290000
)
SELECT c.CustomerID,
       s.Name AS CompanyName,
       SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.Customer c
        ON soh.CustomerID = c.CustomerID
    INNER JOIN Sales.Store AS s
        ON s.BusinessEntityID = c.StoreID
WHERE EXISTS ( SELECT 1
                FROM  SalesOrderHeaderCTE AS sohExists
                WHERE c.CustomerID = sohExists.CustomerID
               )
GROUP BY c.CustomerID , s.Name              
ORDER BY TotalSales DESC;

SET STATISTICS IO OFF;    

EXEC #OutputMessageNOW 'Done';
