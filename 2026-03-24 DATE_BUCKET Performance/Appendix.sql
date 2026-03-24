USE Tempdb;

SET NOCOUNT ON; --don't send a lot of messages about row affected
SET XACT_ABORT ON; --stop processing on error

IF OBJECT_ID(   'EventLog',
                'U'
            ) IS NOT NULL
    DROP TABLE dbo.EventLog;

CREATE TABLE EventLog
(
    EventId INT IDENTITY(1, 1) PRIMARY KEY,
    EventName NVARCHAR(255) NOT NULL,
    EventDescription NVARCHAR(MAX),
    EventTime DATETIME2 NOT NULL
        DEFAULT SYSUTCDATETIME(),
    Location NVARCHAR(255)
);


-- SQL script to generate a parameterized number of random events between 2020-01-01 and 2025-12-31 for the EventLog table. Default to 1000

--1,000,000 took an hour on my machine. <machine stats>

DECLARE @NumberOfEvents INT = 1000000; -- Parameter for number of events to generate
DECLARE @StartDate DATETIME2 = '2020-01-01';
DECLARE @EndDate DATETIME2 = '2025-12-31';

DECLARE @EventNames TABLE
(
    EventName NVARCHAR(255)
);

DECLARE @Locations TABLE
(
    Location NVARCHAR(255)
);

DECLARE @i INT = 1;

-- Populate sample event names
INSERT INTO @EventNames
(
    EventName
)
VALUES('System Start'),
      ('System Shutdown'),
      ('Login Attempt'),
      ('Login Success'),
      ('Login Failure'),
      ('Data Export'),
      ('Data Import'),
      ('Configuration Change'),
      ('Backup Completed'),
      ('Restore Operation'),
      ('Security Alert'),
      ('Database Maintenance'),
      ('User Created'),
      ('User Deleted'),
      ('Permission Change'),
      ('Server Error'),
      ('Application Error'),
      ('Memory Warning'),
      ('Disk Space Warning'),
      ('Performance Threshold Exceeded');

-- Populate sample locations
INSERT INTO @Locations
(
    Location
)
VALUES('Server Room A'),
      ('Server Room B'),
      ('Data Center 1'),
      ('Data Center 2'),
      ('Cloud Instance East'),
      ('Cloud Instance West'),
      ('Office Network'),
      ('Remote Location'),
      ('Disaster Recovery Site'),
      ('Development Environment'),
      ('Testing Environment'),
      ('Production Environment'),
      ('Branch Office'),
      ('Headquarters'),
      ('Mobile Device'),
      ('Client Location');

-- Generate random events
WHILE @i <= @NumberOfEvents
    BEGIN
        DECLARE @RandomEventName NVARCHAR(255);
        DECLARE @RandomLocation NVARCHAR(255);
        DECLARE @RandomDescription NVARCHAR(MAX);
        DECLARE @RandomDate DATETIME2;

        -- Select random event name
        SELECT   TOP(1)
                 @RandomEventName = EventName
        FROM     @EventNames
        ORDER BY NEWID();

        -- Select random location
        SELECT   TOP(1)
                 @RandomLocation = Location
        FROM     @Locations
        ORDER BY NEWID();

        -- Generate random date between start and end date
        SET @RandomDate
            = DATEADD(   SECOND,
                         ABS(CHECKSUM(NEWID())) % DATEDIFF(   SECOND,
                                                              @StartDate,
                                                              @EndDate
                                                          ),
                         @StartDate
                     );

        -- Generate random description
        SET @RandomDescription
            = 'Event ' + @RandomEventName + ' occurred at ' + @RandomLocation
              + ' on ' + CONVERT(   NVARCHAR,
                                    @RandomDate,
                                    120
                                ) + '. Reference ID: '
              + CONVERT(   NVARCHAR,
                           ABS(CHECKSUM(NEWID()))
                       );

        -- Insert event
        INSERT INTO dbo.EventLog
        (
            EventName,
            EventDescription,
            EventTime,
            Location
        )
        VALUES(@RandomEventName,
               @RandomDescription,
               @RandomDate,
               @RandomLocation);

        SET @i = @i + 1;
    END

-- Verify the number of rows inserted
SELECT COUNT(*) AS [Total Events Generated]
FROM   dbo.EventLog;

SELECT   TOP(10)
         *
FROM     dbo.EventLog
ORDER BY EventTime;



--create and load a date table that will group data by day, month, quarter, year, and hour
-- Create a Date dimension table
DROP TABLE IF EXISTS dbo.DateDimension;
CREATE TABLE dbo.DateDimension
(
    Date DATETIME2(0) NOT NULL,
    Hour INT NOT NULL,
    DateTimeValue datetime2(0),
    Day INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName NVARCHAR(10) NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfYear INT NOT NULL,
    WeekOfYear INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(10) NOT NULL,
    Quarter INT NOT NULL,
    QuarterName NVARCHAR(6) NOT NULL,
    Year INT NOT NULL,
    IsWeekend BIT NOT NULL
    CONSTRAINT PKDateDimension PRIMARY KEY (Date, Hour),
    YearStartTime as (date_bucket(year,1, DateTimeValue)) PERSISTED,
    QuarterStartTime as date_bucket(quarter,1, DateTimeValue)  PERSISTED,
    MonthStartTime as date_bucket(month,1, DateTimeValue)  PERSISTED
);


GO

SET NOCOUNT ON;
SET STATISTICS IO OFF;
set statistics time OFF;

-- Declare variables for date range - adjust as needed for your data
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2027-01-01';
DECLARE @CurrentDate DATE = @StartDate;

-- Populate the date dimension table
WHILE @CurrentDate <= @EndDate
BEGIN
    -- Loop through each hour of the day
    DECLARE @Hour INT = 0;

    WHILE @Hour < 24
    BEGIN
        INSERT INTO dbo.DateDimension
        (
            Date,
            Hour,
            DateTimeValue,
            Day,
            DayOfWeek,
            DayName,
            DayOfMonth,
            DayOfYear,
            WeekOfYear,
            Month,
            MonthName,
            Quarter,
            QuarterName,
            Year,
            IsWeekend
        )
        SELECT @CurrentDate,
               @hour,
               DATEADD(hour,@hour,cast(@CurrentDate as datetime2(0))),
               DAY(@CurrentDate),
               DATEPART(WEEKDAY, @CurrentDate),
               DATENAME(WEEKDAY, @CurrentDate),
               DAY(@CurrentDate),
               DATEPART(DAYOFYEAR, @CurrentDate),
               DATEPART(WEEK, @CurrentDate),
               MONTH(@CurrentDate),
               DATENAME(MONTH, @CurrentDate),
               DATEPART(QUARTER, @CurrentDate),
               'Q' + CAST(DATEPART(QUARTER, @CurrentDate) AS VARCHAR(1)),
               YEAR(@CurrentDate),
               CASE
                   WHEN DATEPART(WEEKDAY, @CurrentDate) IN ( 1, 7 ) THEN
                       1
                   ELSE
                       0
               END;

        SET @Hour = @Hour + 1;
    END

    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END;