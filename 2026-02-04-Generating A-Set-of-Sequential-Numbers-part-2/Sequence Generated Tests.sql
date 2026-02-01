USE SequenceTest;
GO
--search for the first instance of @MaxValue for the start of the 
--code to work with. Fetch the create I used from github here:
--<link>



--this procedure simply outputs a message with optional additions
--like time, process id, and login name
--it uses FORMATMESSAGE so it can handle null values gracefully
--and is used in this script to be able to spit out immediate 
--messages becuase it can take a while when your rowcount is high.

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
       COALESCE(@Message,' : '),
 
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
SET NOCOUNT ON;
GO
--this table will hold the times for each method so we can compare them
--the final query of the output pivots the times (presented in microseconds)
IF OBJECT_ID('dbo.HoldTimes') is null
 BEGIN
    CREATE TABLE dbo.HoldTimes (
       sectionName varchar(30),
       starttime datetime2, 
       endtime datetime2, 
       sampleSize int, 
       DurationMilliseconds as (DATEDIFF(millisecond,starttime, endtime))
    );
END;

--in order to be really complete, I wanted to include the simiplest
--technique possible. Just a query from a table. So this table is
--just a simple table of numbers from 1 to 2,000,000,000 which will be
--created in your tempdb. You can lower the number of rows if you want
--to save time.
IF OBJECT_ID('dbo.Number') is null
 BEGIN
    CREATE TABLE dbo.Number
    (
        value INT NOT NULL PRIMARY KEY
    );
    --trying to get bulk inserts, took five minutes on 
    --"my machine", but it is did insert a billion rows
    --with a clustered index :)
    INSERT INTO dbo.Number WITH (TABLOCKX) (value) 
    SELECT value
    FROM   GENERATE_SERIES(1,1000000000);   
 END
GO


DROP TABLE IF EXISTS #holdValues;
CREATE TABLE #holdValues (value INT NOT NULL PRIMARY KEY (value));

--i have tested to 100 million rows, and then my queries turned 
--complicated.
DECLARE @maxValue INT = 100000000;

--this will clear out the table for the first run
--so you can increment.
IF @maxValue = 1
  BEGIN
    TRUNCATE TABLE dbo.HoldTimes;
    THROW 50000, 'Times Reset',0;
  END
ELSE
  --otherwise, delete the times for the max value
  --you send in. 
  DELETE FROM dbo.HoldTimes WHERE sampleSize = @maxValue;

--------------------------------------------------------

EXEC #OutputMessageNOW  'Recursive CTE';

TRUNCATE TABLE #holdValues;

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('Recursive CTE',SYSDATETIME(),@maxValue);

WITH BaseRows AS (
SELECT 1 AS value
UNION ALL
SELECT value + 1
FROM   BaseRows
WHERE  value BETWEEN 1 AND (@MaxValue - 1)
) 
INSERT INTO #holdValues  WITH (TABLOCKX) (value)
SELECT Value
FROM   BaseRows
OPTION (MAXRECURSION 0);

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
    BEGIN
    EXEC #OutputMessageNOW 'RecursiveCTE failed to insert all rows'
    END
ELSE
    UPDATE dbo.HoldTimes
    SET    EndTime = sysdatetime()
    WHERE  sectionName = 'Recursive CTE'
        AND  sampleSize = @maxValue

--------------------------------------------------------
if @MaxValue <= 10000000 --kept crashing at 100 million
                         
 BEGIN

    EXEC #OutputMessageNOW  'While Loop';

    TRUNCATE TABLE #holdValues;

    INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
    VALUES ('While Loop',SYSDATETIME(),@maxValue);


    DECLARE @counter INT = 1
    WHILE @counter <= @maxvalue
        BEGIN
	    INSERT INTO #holdValues  WITH (TABLOCKX) (value)
	    SELECT @counter

	    SET @counter = @counter + 1
        END
 
    IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
        OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
        BEGIN
            EXEC #OutputMessageNOW 'While Loop failed to insert all rows'
        END
    ELSE
        UPDATE dbo.HoldTimes
        SET    EndTime = sysdatetime()
        WHERE  sectionName = 'While Loop'
            AND  sampleSize = @maxValue
 END;

--------------------------------------------------------
if @MaxValue <= 10000000 --failed on 100 million, and adding another
                         --CROSS JOIN was too slow all around
 BEGIN

    EXEC #OutputMessageNOW  'CROSS JOIN ROWNUMBER';

    TRUNCATE TABLE #holdValues

    INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
    VALUES ('CROSS JOIN ROWNUMBER',SYSDATETIME(),@maxValue);

    INSERT INTO #holdValues  WITH (TABLOCKX) (value)
    SELECT TOP (@maxValue) ROW_NUMBER() OVER (ORDER BY i2.object_id) as value
    FROM   master.sys.indexes
             CROSS JOIN  master.sys.indexes as i2
             CROSS JOIN  master.sys.indexes as i3
             ;

    IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
        OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
      BEGIN
        EXEC #OutputMessageNOW 'CROSS JOIN ROWNUMBER failed to insert all rows'
      END
    ELSE
        UPDATE dbo.HoldTimes
        SET    EndTime = sysdatetime()
        WHERE  sectionName = 'CROSS JOIN ROWNUMBER'
          AND  sampleSize = @maxValue
 END;

--------------------------------------------------------

if @MaxValue <= 10000000 --is slow with D8 in there for lower
                         --amounts. Next section is where I 
                         --optimized this algorithm.
 BEGIN
    EXEC #OutputMessageNOW  'CROSS JOIN Digits';
    TRUNCATE TABLE #holdValues

    INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
    VALUES ('CROSS JOIN Digits',SYSDATETIME(),@maxValue);

    ;WITH digits (I) AS (--set up a set of numbers from 0-9
            SELECT I
            FROM   (VALUES (0),(1),(2),(3),(4),(5),
                           (6),(7),(8),(9)) AS digits (I))
    --builds a set of data from from 0 to 999999
    ,Integers (I) AS (
            SELECT D1.I + (10*D2.I) + (100*D3.I) + 
                   (1000*D4.I) + (10000*D5.I) + (100000*D6.I) +
                   (1000000*D7.I) + (10000000*D8.I) 
            FROM digits AS D1 CROSS JOIN digits AS D2 
                 CROSS JOIN digits AS D3
                 CROSS JOIN digits AS D4 
                 CROSS JOIN digits AS D5
                 CROSS JOIN digits AS D6 
                 CROSS JOIN digits AS D7 
                 CROSS JOIN digits AS D8 )
    --insert into table
    INSERT INTO #holdValues WITH (TABLOCKX) (value)
    SELECT I + 1
    FROM   Integers
    WHERE  I <= @MaxValue - 1;

    IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
        OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
      BEGIN
        EXEC #OutputMessageNOW 'CROSS JOIN Digits failed to insert all rows'
      END
    ELSE
        UPDATE dbo.HoldTimes
        SET    EndTime = sysdatetime()
        WHERE  sectionName = 'CROSS JOIN Digits'
          AND  sampleSize = @maxValue
END;

--------------------------------------------------------

EXEC #OutputMessageNOW  'Modified CROSS JOIN Digits';
TRUNCATE TABLE #holdValues

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('Modified CROSS JOIN Digits',SYSDATETIME(),@maxValue);

;WITH digits (I) AS (--set up a set of numbers from 0-9
            SELECT I
            FROM   (VALUES (0),(1),(2),(3),(4),(5),
                           (6),(7),(8),(9)) AS digits (I))
    --builds a set of data from from 0 to 999999
    ,Integers  AS (
            SELECT D1.I + 
                   (10*D2.I) +
                   (100*D3.I) + 
                   (1000*D4.I) + 
                   (10000*D5.I) + 
                   (100000*D6.I) +
                   (1000000*D7.I) + 
                   (10000000*D8.I) + 
                   (100000000*D9.I) +
                   (1000000000*D10.I) 
                   AS I
            --the >= or i=0 effectively removes a cross join from the set, making small 
            --numbers (the normal) much faster, while allowing a lot higher digit count.
            FROM digits AS D1 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue > 10 OR i = 0) AS D2 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 100 OR i = 0) AS D3 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 1000 OR i = 0) AS D4 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 10000 OR i = 0) AS D5 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 100000 OR i = 0) AS D6 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 1000000 OR i = 0) AS D7 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 10000000 OR i = 0) AS D8 
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 100000000 OR i = 0) AS D9
                 CROSS JOIN (SELECT * FROM digits WHERE @MaxValue >= 1000000000 OR i = 0) AS D10
                 )
    --insert into table
    INSERT INTO #holdValues WITH (TABLOCKX) (value)
    SELECT I + 1
    FROM   Integers
    WHERE  I < @MaxValue 
    

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
  BEGIN
    EXEC #OutputMessageNOW 'Modified CROSS JOIN Digits failed to insert all rows'
  END
ELSE
    UPDATE dbo.HoldTimes
    SET    EndTime = sysdatetime()
    WHERE  sectionName = 'Modified CROSS JOIN Digits'
      AND  sampleSize = @maxValue

--------------------------------------------------------
EXEC #OutputMessageNOW  'GENERATE_SERIES'

TRUNCATE TABLE #holdValues;

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('GENERATE_SERIES',SYSDATETIME(),@maxValue);

INSERT INTO #holdValues WITH (TABLOCKX) (value)
SELECT value
FROM   GENERATE_SERIES(1,@MaxValue)

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
  BEGIN
    EXEC #OutputMessageNOW 'GENERATE_SERIES failed to insert all rows'
  END
ELSE
    UPDATE dbo.HoldTimes
    SET    EndTime = sysdatetime()
    WHERE  sectionName = 'GENERATE_SERIES'
      AND  sampleSize = @maxValue

---------------------------------------------------------
EXEC #OutputMessageNOW  'STRING_SPLIT REPLICATE'

TRUNCATE TABLE #holdValues;

/*
Inspired by Aaron Bertrand post here. 
[GENERATE_SERIES to Build a Set](https://www.red-gate.com/simple-talk/databases/sql-server/t-sql-programming-sql-server/generate-series-to-build-a-set/)

Slight mod to his  
STRING_SPLIT + REPLICATE method to use an nvarchar(max) 
instead of varchar so I could generate LARGE sets.
Post: 
*/

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('STRING_SPLIT REPLICATE',SYSDATETIME(),@maxValue);

INSERT INTO #holdValues WITH (TABLOCKX) (value)
SELECT TOP (@maxValue ) 
	   ROW_NUMBER() OVER (ORDER BY @@SPID) AS Value
FROM STRING_SPLIT(REPLICATE(CAST(',' AS NVARCHAR(MAX)), @maxValue - 1), ',')
ORDER BY value

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
  BEGIN
    EXEC #OutputMessageNOW 'STRING_SPLIT REPLICATE failed to insert all rows'
  END
ELSE
    UPDATE dbo.HoldTimes
    SET    EndTime = sysdatetime()
    WHERE  sectionName = 'STRING_SPLIT REPLICATE'
      AND  sampleSize = @maxValue
      

---------------------------------------------------------
EXEC #OutputMessageNOW  'Numbers Table'

TRUNCATE TABLE #holdValues;

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('Numbers Table',SYSDATETIME(),@maxValue);

INSERT INTO #holdValues WITH (TABLOCKX) (value)
SELECT value
FROM  dbo.Number
WHERE value BETWEEN 1 AND @MaxValue

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    OR EXISTS(SELECT * FROM #holdValues where value > @MaxValue)
  BEGIN
    EXEC #OutputMessageNOW 'Numbers Table failed to insert all rows'
  END
ELSE
    UPDATE dbo.HoldTimes
    SET    EndTime = sysdatetime()
    WHERE  sectionName = 'Numbers Table'
      AND  sampleSize = @maxValue

--------------------------------------------------------
EXEC #OutputMessageNOW  'That'' All'

SELECT SectionName, 
       MAX(CASE WHEN SampleSize = 10 THEN DurationMilliseconds ELSE -1 END) AS [10 Rows],
       MAX(CASE WHEN SampleSize = 100 THEN DurationMilliseconds ELSE -1 END) AS [100 Rows],
       MAX(CASE WHEN SampleSize = 1000 THEN DurationMilliseconds ELSE -1 END) AS [1000 Rows],
       MAX(CASE WHEN SampleSize = 10000 THEN DurationMilliseconds ELSE -1 END) AS [10000 Rows],
       MAX(CASE WHEN SampleSize = 100000 THEN DurationMilliseconds ELSE -1 END) AS [100000 Rows]    
FROM   dbo.HoldTimes
GROUP  BY SectionName;


SELECT SectionName, 
       MAX(CASE WHEN SampleSize = 1000000 THEN DurationMilliseconds ELSE -1 END) AS [1000000 Rows], 
       MAX(CASE WHEN SampleSize = 10000000 THEN DurationMilliseconds ELSE -1 END) AS [10000000 Rows],
       MAX(CASE WHEN SampleSize = 100000000 THEN DurationMilliseconds ELSE -1 END) AS [100000000 Rows]      
FROM   dbo.HoldTimes
GROUP  BY SectionName



