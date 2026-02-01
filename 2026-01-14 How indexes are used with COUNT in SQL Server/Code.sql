--Queries should work with any version of Adventureworks
--https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms

USE AdventureWorks;

SELECT TOP 1 OBJECT_SCHEMA_NAME(p.object_id) AS SchemaName,
       MAX(o.name) AS OjectName,
       SUM(p.rows) AS Rows
--there may be > 1 partition
FROM   sys.partitions AS p
          JOIN sys.objects AS o
             ON o.object_id = p.object_id
WHERE p.index_id IN (0,1) -- heap or clustered
  AND OBJECT_SCHEMA_NAME(o.object_id) != 'sys'
GROUP BY p.object_id, p.index_id
ORDER by Rows DESC;
GO

EXEC sp_help 'sales.salesorderdetail';

/*
COUNT(*)
*/

USE AdventureWorks2022;
GO
 
SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT(*)
FROM   Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SELECT COUNT(*)
FROM   Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO

SELECT SalesOrderDetailID, ProductId
FROM   Demo.Salesorderdetail;


/*
COUNT(Literal)
*/

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] 
 ON [Demo].[SalesOrderDetail]
  (
     [ProductID] ASC
  );
  
GO

--only showing the query now, you can use the code from the COUNT(*) section.
SELECT COUNT(1)
FROM   Demo.SalesOrderDetail;



SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT(1)
FROM   Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SET STATISTICS TIME ON;
GO
SELECT COUNT(1)
FROM   Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO
SET STATISTICS TIME OFF;
GO


/*
COUNT(Literal Expression)
*/

SELECT COUNT(1+1)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(COALESCE(NULL,2))
FROM   Demo.SalesOrderDetail;
 
DECLARE @value INT = 1
SELECT COUNT(@value)
FROM   Demo.SalesOrderDetail;
GO


SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT(1+1)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(COALESCE(NULL,2))
FROM   Demo.SalesOrderDetail;
 
DECLARE @value INT = 1
SELECT COUNT(@value)
FROM   Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SET STATISTICS TIME ON;
GO
SELECT COUNT(1+1)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(COALESCE(NULL,2))
FROM   Demo.SalesOrderDetail;
 
DECLARE @value INT = 1
SELECT COUNT(@value)
FROM   Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO
SET STATISTICS TIME OFF;
GO

DECLARE @value int = NULL;
 
SELECT COUNT(@value)
FROM   Demo.Salesorderdetail;
GO

/*
COUNT(Simple PRIMARY KEY column)
*/

SELECT COUNT(SalesOrderDetailId)
FROM   Demo.SalesOrderDetail;
GO


SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT(SalesOrderDetailId)
FROM   Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SET STATISTICS TIME ON;
GO
SELECT COUNT(SalesOrderDetailId)
FROM   Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO
SET STATISTICS TIME OFF;
GO

ALTER TABLE Demo.SalesOrderDetail
  DROP CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID];
 
ALTER TABLE Demo.[SalesOrderDetail] 
  ADD CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID]
     PRIMARY KEY CLUSTERED
     (
        [SalesOrderID] ASC,
        [SalesOrderDetailID] ASC
     );

GO

SELECT COUNT(SalesOrderId)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(SalesOrderDetailId)
FROM   Demo.SalesOrderDetail;
GO


SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT(SalesOrderId)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(SalesOrderDetailId)
FROM   Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SET STATISTICS TIME ON;
GO
SELECT COUNT(SalesOrderId)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(SalesOrderDetailId)
FROM   Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO
SET STATISTICS TIME OFF;
GO

/*
COUNT(Column that doesn't allow NULL values)
*/

CREATE UNIQUE NONCLUSTERED INDEX
   [AK_SalesOrderDetail_rowguid] 
    ON [Demo].[SalesOrderDetail]
       (
          [rowguid] ASC
       );
GO


SELECT COUNT(rowguid)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(UnitPrice)
FROM   Demo.SalesOrderDetail;
GO


SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT(rowguid)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(UnitPrice)
FROM   Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SET STATISTICS TIME ON;
GO
SELECT COUNT(rowguid)
FROM   Demo.SalesOrderDetail;
 
SELECT COUNT(UnitPrice)
FROM   Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO
SET STATISTICS TIME OFF;
GO

/*
COUNT(Column that Allows NULL values)
*/

SELECT COUNT([CarrierTrackingNumber])
FROM   Demo.SalesOrderDetail;
GO

SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT([CarrierTrackingNumber])
FROM   Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SET STATISTICS TIME ON;
GO
SELECT COUNT([CarrierTrackingNumber])
FROM   Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO
SET STATISTICS TIME OFF;
GO


CREATE INDEX CarrierTrackingNumber 
  ON Demo.SalesOrderDetail (CarrierTrackingNumber);
GO

SELECT COUNT([CarrierTrackingNumber])
FROM Demo.SalesOrderDetail;
GO


SET SHOWPLAN_TEXT ON;
GO
SELECT COUNT([CarrierTrackingNumber])
FROM Demo.SalesOrderDetail;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
GO
SET STATISTICS TIME ON;
GO
SELECT COUNT([CarrierTrackingNumber])
FROM Demo.SalesOrderDetail;
GO
SET STATISTICS IO OFF;
GO
SET STATISTICS TIME OFF;
GO









