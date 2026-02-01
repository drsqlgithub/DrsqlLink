SET NOCOUNT ON;

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

DROP TABLE IF EXISTS #holdValues;
CREATE TABLE #holdValues (value INT NOT NULL PRIMARY KEY (value));


DECLARE @maxValue INT = 100000 --0000;

IF @maxValue = 10
TRUNCATE TABLE dbo.HoldTimes

--------------------------------------------------------
PRINT 'Recursive CTE';

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
INSERT INTO #holdValues (value)
SELECT Value
FROM   BaseRows
OPTION (MAXRECURSION 0);

UPDATE dbo.HoldTimes
SET    EndTime = sysdatetime()
WHERE  sectionName = 'Recursive CTE'
  AND  sampleSize = @maxValue

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    THROW 50000,'ERROR Occurred',1;

--------------------------------------------------------
PRINT 'WHILE Loop';

TRUNCATE TABLE #holdValues;

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('WHILE Loop',SYSDATETIME(),@maxValue);


DECLARE @counter INT = 1
WHILE @counter <= @maxvalue
 BEGIN
	INSERT INTO #holdValues(value)
	SELECT @counter

	SET @counter = @counter + 1
 END
 
UPDATE dbo.HoldTimes
SET    EndTime = sysdatetime()
WHERE  sectionName = 'WHILE Loop'
  and  sampleSize = @maxValue

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    THROW 50000,'ERROR Occurred',1;


--------------------------------------------------------
PRINT 'CROSS JOIN ROWNUMBER';

TRUNCATE TABLE #holdValues

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('CROSS JOIN ROWNUMBER',SYSDATETIME(),@maxValue);

INSERT INTO #holdValues(value)
SELECT TOP (@MaxValue) ROW_NUMBER() OVER (ORDER BY i2.object_id) as value
FROM   master.sys.indexes
         CROSS JOIN  master.sys.indexes as i2
         CROSS JOIN  master.sys.indexes as i3;

UPDATE dbo.HoldTimes
SET    EndTime = sysdatetime()
WHERE  sectionName = 'CROSS JOIN ROWNUMBER'
  and  sampleSize = @maxValue

IF (SELECT COUNT(*) from #holdValues) <> @MaxValue
    THROW 50000,'ERROR Occurred',1;

--------------------------------------------------------
PRINT 'CROSS JOIN Digits';
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
INSERT INTO #holdValues (value)
SELECT I + 1
FROM   Integers
WHERE  I <= @MaxValue - 1;

UPDATE dbo.HoldTimes
SET    EndTime = SYSDATETIME()
WHERE  sectionName = 'CROSS JOIN Digits'
  AND  sampleSize = @maxValue

IF (SELECT COUNT(*) FROM #holdValues) <> @MaxValue
    THROW 50000,'ERROR Occurred',1;

--------------------------------------------------------
PRINT 'GENERATE_SERIES'

TRUNCATE TABLE #holdValues;

INSERT INTO dbo.HoldTimes (SectionName,StartTime,SampleSize)
VALUES ('GENERATE_SERIES',SYSDATETIME(),@maxValue);

INSERT INTO #holdValues (value)
SELECT value
FROM   GENERATE_SERIES(1,@MaxValue)


UPDATE dbo.HoldTimes
SET    EndTime = SYSDATETIME()
WHERE  sectionName = 'GENERATE_SERIES'
  AND  sampleSize = @maxValue;

IF (SELECT COUNT(*) FROM #holdValues) <> @MaxValue
    THROW 50000,'ERROR Occurred',1;

--------------------------------------------------------
PRINT 'That'' All'

SELECT SectionName, 
       MAX(CASE WHEN SampleSize = 10 THEN DurationMilliseconds ELSE -1 END) AS [10 Rows],
       MAX(CASE WHEN SampleSize = 100 THEN DurationMilliseconds ELSE -1 END) AS [100 Rows],
       MAX(CASE WHEN SampleSize = 1000 THEN DurationMilliseconds ELSE -1 END) AS [1000 Rows],
       MAX(CASE WHEN SampleSize = 10000 THEN DurationMilliseconds ELSE -1 END) AS [10000 Rows],
       MAX(CASE WHEN SampleSize = 100000 THEN DurationMilliseconds ELSE -1 END) AS [100000 Rows],
       MAX(CASE WHEN SampleSize = 1000000 THEN DurationMilliseconds ELSE -1 END) AS [1000000 Rows]
FROM   dbo.HoldTimes
GROUP  BY SectionName