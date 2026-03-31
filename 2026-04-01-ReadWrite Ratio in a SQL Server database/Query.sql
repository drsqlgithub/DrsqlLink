SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; --don't lock or honor locks

--uses a like comparison to only include databases you desire (could easily be rewritten to group by database)
DECLARE @databaseName        SYSNAME,
        @excludeLogFilesFlag bit;

SET @databaseName = '%'; --'%' gives all databases together 

SET @excludeLogFilesFlag = 1; --excludes log files by default because they would not be 
                              --considered in the sys.dm_db_index_usage_stats numbers
SET NOCOUNT ON;

SELECT  'Ratio bases on magnitude of data - sys.dm_io_virtual_file_stats';
        
        --magnitude of data read
SELECT  FORMAT(CAST(SUM(divfs.num_of_bytes_read) AS decimal) / 
            --magnitude of all bytes read or written
            (CAST(SUM(divfs.num_of_bytes_written) AS decimal) + 
                     CAST(SUM(divfs.num_of_bytes_read) AS decimal)),'##.####') AS RatioOfReads,
 
        --magnitude of data written
        FORMAT(CAST(SUM(divfs.num_of_bytes_written) AS decimal) / 
            --magnitude of all bytes read or written
                        (CAST(SUM(divfs.num_of_bytes_written) AS decimal) + 
                        CAST(SUM(divfs.num_of_bytes_read) AS decimal)),'##.####') AS RatioOfWrites,
        --if your totals come close to that format, let me know. That would be awesome!
        FORMAT(SUM(divfs.num_of_bytes_read + divfs.num_of_bytes_written),
                    '###,###,###,###,###,###,###,###,###') AS TotalBytesReadAndWriten,
        FORMAT(SUM(divfs.num_of_bytes_read),'###,###,###,###,###,###,###,###,###') AS num_of_bytes_read,
        FORMAT(SUM(divfs.num_of_bytes_written),'###,###,###,###,###,###,###,###,###') as num_of_bytes_written
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs --params database/file, but used filter so could group 
                                                          --multiple databases
        JOIN sys.master_files mf
            ON mf.database_id = divfs.database_id
                AND mf.file_id = divfs.file_id
WHERE   DB_NAME(divfs.database_id) LIKE @databaseName
    AND (mf.type_desc <> 'LOG' OR   @excludeLogFilesFlag = 0);

SELECT  'Ratio bases on count of operations-sys.dm_io_virtual_file_stats';

        --count of read operations
SELECT  FORMAT(CAST(SUM(divfs.num_of_reads) AS decimal) / 
                        --total read or write operations
                        (CAST(SUM(divfs.num_of_writes) AS decimal) + 
                        CAST(SUM(divfs.num_of_reads) AS decimal)),'##.####') AS RatioOfReads,
        --count of write operations
        FORMAT(CAST(SUM(divfs.num_of_writes) AS decimal) / 
                      --total read or write operations
                      (CAST(SUM(divfs.num_of_reads) AS decimal) + 
                       CAST(SUM(divfs.num_of_writes) AS decimal)),'##.####') AS RatioOfWrites,
        FORMAT(SUM(divfs.num_of_reads + divfs.num_of_writes),
                                  '###,###,###,###,###,###,###,###,###') AS TotalReadWriteCount,

        FORMAT(SUM(divfs.num_of_reads),'###,###,###,###,###,###,###,###,###') AS num_of_reads,
        FORMAT(SUM(divfs.num_of_writes),'###,###,###,###,###,###,###,###,###') AS num_of_writes
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
        JOIN sys.master_files mf
            ON mf.database_id = divfs.database_id
                AND mf.file_id = divfs.file_id
WHERE   DB_NAME(divfs.database_id) LIKE @databaseName
    AND (mf.type_desc <> 'LOG' OR   @excludeLogFilesFlag = 0);

SELECT  'Ratio bases on count of operations - sys.dm_db_index_usage_stats';

        --number of read operations on the index.NULL of there are no read or write operations
SELECT  FORMAT(case when (SUM(user_updates + user_seeks + user_scans + user_lookups) = 0)
                then NULL
             --Read operations
             else (CAST(SUM(user_seeks + user_scans + user_lookups) AS DECIMAL) / 
                       --all operations
                       CAST(SUM(user_updates + user_seeks + user_scans + user_lookups) AS DECIMAL))
        end,'##.####') AS RatioOfReads,
         --number of read operations on the index.NULL of there are no read or write operations
        FORMAT(case when (SUM(user_updates + user_seeks + user_scans + user_lookups) = 0)
             then NULL
             --write operations
             else (CAST(SUM(user_updates) AS DECIMAL) / 
                      --all operations
                       CAST(SUM(user_updates + user_seeks + user_scans + user_lookups) AS DECIMAL))
        end,'##.####') AS RatioOfWrites,
        FORMAT(SUM(user_updates + user_seeks + user_scans + user_lookups),'###,###,###,###,###,###,###,###,###') as TotalOperations,
        FORMAT(SUM(user_seeks + user_scans + user_lookups),'###,###,###,###,###,###,###,###,###') as TotalReadOperations,
        FORMAT(SUM(user_updates),'###,###,###,###,###,###,###,###,###') as TotalWriteOperations
        ,FORMAT(SUM(user_seeks),'###,###,###,###,###,###,###,###,###') as user_seeks,
        FORMAT(SUM(user_scans),'###,###,###,###,###,###,###,###,###') as user_scans,
        FORMAT(SUM(user_lookups),'###,###,###,###,###,###,###,###,###') as user_lookups,
        FORMAT(SUM(user_updates),'###,###,###,###,###,###,###,###,###') as user_updates
FROM    sys.dm_db_index_usage_stats AS ddius --gives you a look at how it is used
WHERE   DB_NAME(database_id) LIKE @databaseName
  AND  index_id <> 0; --ignore heaps

SELECT  'Ratio bases on count of operations - note that this isn''t exactly a 1-1 ratio of operations'
UNION ALL
SELECT  'because an index scan could be a lot more than an index write while a seek could be less than a write';