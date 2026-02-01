CREATE TABLE #ExampleData
(
ExampleDataId int NOT NULL,
TimeValue   datetime2(0) --data to the minute
)
INSERT INTO #ExampleData(ExampleDataId, TimeValue)
SELECT VALUE AS ExampleDataId, DATEADD(MINUTE, value - 1,'2025-01-01')
FROM   GENERATE_SERIES(1,525600);
GO

SELECT COUNT(*)
FROM   #ExampleData;
GO

SELECT DATE_BUCKET(month,12,TimeValue) as DateGroup, COUNT(*) as GroupCount
FROM   #ExampleData
GROUP BY DATE_BUCKET(month,12,TimeValue);
GO


SELECT DATE_BUCKET(year,1,TimeValue) as DateGroup, COUNT(*) as GroupCount
FROM   #ExampleData
GROUP BY DATE_BUCKET(year,1,TimeValue);
GO

SELECT DATE_BUCKET(year,.5,TimeValue) as DateGroup, COUNT(*) as GroupCount
FROM   #ExampleData
GROUP BY DATE_BUCKET(year,.5,TimeValue);
GO

/*
Months
*/


SELECT DATE_BUCKET(month,1,TimeValue) as DateGroup, COUNT(*) as GroupCount
FROM   #ExampleData
GROUP BY DATE_BUCKET(month,1,TimeValue)
ORDER BY DateGroup;
GO


SELECT DATE_BUCKET(month,6,TimeValue) as DateGroup, COUNT(*) as GroupCount
FROM   #ExampleData
GROUP BY DATE_BUCKET(month,6,TimeValue)
ORDER BY DateGroup;
GO

SELECT DATE_BUCKET(month,3,TimeValue) as DateGroup, COUNT(*) as GroupCount
FROM   #ExampleData
GROUP BY DATE_BUCKET(month,3,TimeValue)
ORDER BY DateGroup;

/*
Weeks
*/

SELECT DATE_BUCKET(Week,4,TimeValue) as DateGroup, COUNT(*) as GroupCount
FROM   #ExampleData
GROUP BY DATE_BUCKET(Week,4,TimeValue)
ORDER BY DateGroup;
GO

/*
The Starting Point
*/

SELECT @@DATEFIRST;
GO

WITH BaseRows AS (
  SELECT DATE_BUCKET(Week,4,TimeValue) as DateGroup, COUNT(*) as GroupCount
  FROM   #ExampleData
  GROUP BY DATE_BUCKET(Week,4,TimeValue)
)
SELECT *, DATENAME(weekday,DateGroup) as DayOfTheWeek
FROM   BaseRows
ORDER BY DateGroup;
GO


WITH BaseRows AS (
  SELECT DATE_BUCKET(Week,4,TimeValue,cast('2025-01-01' as datetime2)) as DateGroup,
         COUNT(*) as GroupCount
  FROM   #ExampleData
  GROUP BY DATE_BUCKET(Week,4,TimeValue,cast('2025-01-01' as datetime2))
)
SELECT *, DATENAME(weekday,DateGroup) as DayOfTheWeek
FROM   BaseRows
ORDER BY DateGroup;
GO

/*
A brief example at a grain less than a day
*/

SELECT TOP 10 *
FROM   #ExampleData
ORDER BY TimeValue asc;
GO

WITH BaseRows AS (
  SELECT DATE_BUCKET(Minute,10,TimeValue,cast('2025-01-01' as datetime2)) 
                                                    as   DateGroup, 
         COUNT(*) as GroupCount
  FROM   #ExampleData
  GROUP BY DATE_BUCKET(Minute,10,TimeValue,cast('2025-01-01' as datetime2))
)
SELECT Top 10</em>, DATENAME(weekday,DateGroup) as DayOfTheWeek
FROM   BaseRows
ORDER BY DateGroup;
GO

WITH BaseRows AS (
  SELECT DATE_BUCKET(Minute,10,TimeValue,cast('2025-01-01 00:02'
                                         as datetime2)) as DateGroup, 
       COUNT(*) as GroupCount
  FROM   #ExampleData
  GROUP BY DATE_BUCKET(Minute,10,TimeValue,cast('2025-01-01 00:02' as datetime2))
)
SELECT Top 10 *, DATENAME(weekday,DateGroup) as DayOfTheWeek
FROM   BaseRows
ORDER BY DateGroup;
GO

WITH BaseRows AS (
   SELECT DATE_BUCKET(Week,4,TimeValue,cast('2025-01-01'
                           as datetime2)) as DateGroup,   
          COUNT(*) as GroupCount
   FROM   #ExampleData
   GROUP BY DATE_BUCKET(Week,4,TimeValue,cast('2025-01-01' as datetime2))
)
SELECT *, DATENAME(weekday,DateGroup) as DayOfTheWeek
FROM   BaseRows
ORDER BY DateGroup;
GO

