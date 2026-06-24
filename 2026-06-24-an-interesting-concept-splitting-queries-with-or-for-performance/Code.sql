USE AdventureWorks2025
GO

SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < 500
   OR  ProductId = 741


SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < 400
   
SELECT *
FROM   Sales.SalesOrderDetail
WHERE  ProductId = 741

CREATE NONCLUSTERED INDEX index_1
ON [Sales].[SalesOrderDetail] ([UnitPrice])
INCLUDE (
            [CarrierTrackingNumber],
            [OrderQty],
            [ProductID],
            [SpecialOfferID],
            [UnitPriceDiscount],
            [LineTotal],
            [rowguid],
            [ModifiedDate]
        );


SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < 500
UNION
SELECT *
FROM   Sales.SalesOrderDetail
WHERE  ProductId = 741;


SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < 500
  AND  ProductId <> 741
UNION ALL
SELECT *
FROM   Sales.SalesOrderDetail
WHERE  ProductId = 741


SET STATISTICS IO ON;
SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < 500
   OR  ProductId = 741
SET STATISTICS IO OFF; 

SET STATISTICS IO ON;
SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < 500
  AND  ProductId <> 741
UNION ALL
SELECT *
FROM   Sales.SalesOrderDetail
WHERE  ProductId = 741
SET STATISTICS IO OFF; 


GO
CREATE OR ALTER PROCEDURE Testharness_TwoIndexedQueries
(
    @ProductId INT,
    @UnitPriceGT MONEY
)
WITH RECOMPILE AS

SET STATISTICS IO ON;
SET NOCOUNT ON;

DECLARE @parameterMessage varchar(60) = 
    CONCAT('ProductId=',@productId, ' and UnitPrice > ', @UnitPriceGT)

PRINT '-----------------------------------------------------------'
PRINT ' Parameters'
PRINT   @parameterMessage
PRINT '-----------------------------------------------------------'

PRINT '-----------------------------------------------------------'
PRINT'All rows - show cost of full table scan'
PRINT '-----------------------------------------------------------'

SELECT *
FROM Sales.SalesOrderDetail

PRINT '-----------------------------------------------------------'
PRINT'ProductId = '
PRINT '-----------------------------------------------------------'

SELECT *
FROM Sales.SalesOrderDetail
WHERE ProductId = @productId;

PRINT '-----------------------------------------------------------'
PRINT  'UnitPrice less than '
PRINT '-----------------------------------------------------------'

SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < @UnitPriceGT
PRINT '-----------------------------------------------------------'
PRINT 'Simple OR condition'
PRINT '-----------------------------------------------------------'

SELECT *
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice < @UnitPriceGT
   OR  ProductId = @productId
PRINT '-----------------------------------------------------------'
PRINT 'UNION ALL approach'
PRINT '-----------------------------------------------------------'

SELECT *
FROM   Sales.SalesOrderDetail
WHERE  ProductId = @productId   
UNION ALL  
SELECT *
FROM   Sales.SalesOrderDetail
WHERE  (UnitPrice < @UnitPriceGT AND productid <> @productId)

SET STATISTICS IO OFF;
GO


EXEC dbo.Testharness_TwoIndexedQueries @ProductId = 741,     -- int
                @UnitPriceGT = 500 -- money

EXEC dbo.Testharness_TwoIndexedQueries @ProductId = 943,     -- int
                @UnitPriceGT = 500 -- money

EXEC dbo.Testharness_TwoIndexedQueries @ProductId = 0,     -- int
                @UnitPriceGT = 10 -- money



EXEC dbo.Testharness_TwoIndexedQueries @ProductId = 870,
                @UnitPriceGT = 10000 -- money

/*
In order to get a much larger set of data, I grabbed a copy of StackOverflow's database from [Brent Ozar's site:](https://www.brentozar.com/archive/2021/03/download-the-current-stack-overflow-database-for-free-2021-02/). They Votes table has 52,928,720 rows which is a pretty good size on my [query testing rig](https://drsql.link/simple-query-performance-testing-rig/). 
*/



SELECT count(*)
FROM   dbo.Votes
WHERE  id = 11846083
  OR   id = 28341294
  OR   id = 5086021
  OR   id = 32039430
  OR   voteTypeId = 4 --733 matching rows

  
SELECT *
FROM   dbo.Votes
WHERE  id = 11846083
  OR   id = 28341294
  OR   id = 5086021
  OR   id = 32039430
UNION ALL
SELECT *
FROM   dbo.Votes
WHERE  voteTypeId = 4 
  AND NOT (id = 11846083
  OR   id = 28341294
  OR   id = 5086021
  OR   id = 32039430)


  
SELECT *
FROM   dbo.Votes
WHERE  id = 11846083
  OR   id = 28341294
  OR   id = 5086021
  OR   id = 32039430
  OR   voteTypeId = 10 --2039371 matching rows 

  
SELECT *
FROM   dbo.Votes
WHERE  id = 11846083
  OR   id = 28341294
  OR   id = 5086021
  OR   id = 32039430
UNION ALL
SELECT *
FROM   dbo.Votes
WHERE  voteTypeId = 10 
  AND NOT (id = 11846083
  OR   id = 28341294
  OR   id = 5086021
  OR   id = 32039430)

GO

CREATE OR ALTER PROCEDURE Testharness_TwoNewIndexedQueries
(
@id1 INT ,
@id2 INT ,
@id3 INT ,
@id4 INT ,
@voteTypeId INT 
)
WITH RECOMPILE AS

SET STATISTICS IO ON;
SET NOCOUNT ON;

DECLARE @parameterMessage varchar(1000) = 
    CONCAT('Parameters ID1:', @id1, ' ID2: ', @id2, ' ID3: ', @id3, 
           CHAR(13), CHAR(10), ' ID4: ', @id4, ' voteTypeId: ', @voteTypeId)

PRINT '-----------------------------------------------------------'
PRINT ' Parameters'
PRINT  @parameterMessage
PRINT '-----------------------------------------------------------'

PRINT '-----------------------------------------------------------'
PRINT'All rows - show cost of full table scan'
PRINT '-----------------------------------------------------------'

SELECT *
FROM   dbo.Votes

PRINT '-----------------------------------------------------------'
PRINT ' Four id = OR condition'
PRINT '-----------------------------------------------------------'

SELECT *
FROM   dbo.Votes
WHERE  id = @id1
  OR   id = @id2
  OR   id = @id3
  OR   id = @id4
  
PRINT '-----------------------------------------------------------'
PRINT 'Votetype = a value'
PRINT '-----------------------------------------------------------'

SELECT *
FROM   dbo.Votes
WHERE  voteTypeId = @voteTypeId
  
PRINT '-----------------------------------------------------------'
PRINT 'Simple OR condition'
PRINT '-----------------------------------------------------------'

SELECT *
FROM   dbo.Votes
WHERE  id = @id1
  OR   id = @id2
  OR   id = @id3
  OR   id = @id4
  OR   voteTypeId = @voteTypeId
  
PRINT '-----------------------------------------------------------'
PRINT 'UNION ALL approach'
PRINT '-----------------------------------------------------------'

SELECT *
FROM   dbo.Votes
WHERE  id = @id1
  OR   id = @id2
  OR   id = @id3
  OR   id = @id4
UNION ALL  
SELECT *
FROM   dbo.Votes
WHERE  NOT (id = @id1
  OR   id = @id2
  OR   id = @id3
  OR   id = @id4)
  AND voteTypeId = @voteTypeId


SET STATISTICS IO OFF;
GO

EXEC Testharness_TwoNewIndexedQueries

@id1 = 11846083,
@id2 = 28341294,
@id3 = 5086021,
@id4 = 32039430,
@voteTypeId = 4 --733 matching rows

EXEC Testharness_TwoNewIndexedQueries

@id1 = 11846083, --same rows
@id2 = 28341294,
@id3 = 5086021,
@id4 = 32039430,
@voteTypeId = 10 --2039371 matching rows 


