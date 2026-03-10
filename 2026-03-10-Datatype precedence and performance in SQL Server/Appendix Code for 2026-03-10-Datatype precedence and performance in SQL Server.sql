--This script will built a series of tables for the datatype demos.

DROP TABLE IF EXISTS dbo.DemoVarcharPK;
DROP TABLE IF EXISTS dbo.DemoIntPK;

-- Create first demo table with VARCHAR primary key
CREATE TABLE dbo.DemoVarcharPK
(
    KeyColumn VARCHAR(10) PRIMARY KEY,
    PaddingColumn CHAR(100) NOT NULL
        DEFAULT (REPLICATE('A', 100))
);

-- Create second demo table with INTEGER primary key
CREATE TABLE dbo.DemoIntPK
(
    KeyColumn INT PRIMARY KEY,
    PaddingColumn CHAR(100) NOT NULL
        DEFAULT (REPLICATE('A', 100))
);

INSERT INTO dbo.DemoIntPK
(
    KeyColumn
)
SELECT Value
FROM GENERATE_SERIES(1, 1000000);

INSERT INTO dbo.DemoVarcharPK
(
    KeyColumn
)
SELECT Value
FROM GENERATE_SERIES(1, 1000000);


---------------------================


CREATE OR ALTER FUNCTION dbo.ExamineExpression
(
    @Expression nvarchar(max)
) 
RETURNS @Output TABLE
(
    Datatype sysname,
    Nullability varchar(10),
    Expression nvarchar(max)
)
AS
 BEGIN
    --add the expression to a simple SELECT statement
    DECLARE @SQL nvarchar(max) = 'SELECT ' + @expression + ' AS CheckMe'

    --then add it to a query:
    insert into @output(Datatype, Nullability, Expression)
    SELECT
        coalesce(system_type_name,'Invalid expression'),
        case when system_type_name is null then 'Error'
             when is_nullable = 1 then 'NULL' 
             WHEN is_nullable = 0 then 'NOT NULL' 
             else 'UNKNOWN' END as nullability,
        @Expression
    FROM   sys.dm_exec_describe_first_result_set (@SQL,null,0) as dedfrs;
 RETURN;
END;
