ALTER PROCEDURE sp_exec_into_table	@SprocName nvarchar(max),
				@CommaParameters nvarchar(max) ='',
				@Log bit = 0,
				@ExecGuid uniqueidentifier = NULL OUTPUT		
AS
/*	This Stored procedure takes a SprocName and some parameters to execute it with, storing the results in a server temp table called ##SprocName
	
	
	Parameters:	@SprocName - The name of the stored procedure we want to capture the results of
			
			@CommaParameters - A comma separated list of parameters (can be named or ordered)

			@Log - If set to 1 then the execution will be logged to ##SprocHistory table (Must have sp_exec_log to use this!)

			@ExecGuid - OUTPUT parameter that can be used to distinguish between the different execution runs of sp_exec_into_table
	
	sp_exec_into_table works by querying sys.dm_exec_describe_first_result_set, passing the sproc and parameters the user passes to sp_exec_into_table
	sys.dm_exec_describe_first_result_set tells us some information about what the passed sproc will return (importantly, the name and data type of each column).
	A server wide (##name) temp table is then created (unless it already exists) that takes the same name as the sproc passed, using the information we pull out regarding the result set 
	We can then simply do an Insert..Exec.. into the temp table

	As a helping hand, sp_exec_into_table will also throw in the SPID and a new GUID for every time it is called into this server wide temp table
	So in the case that this sproc is run multiple times on the same stored procedure, we can differentiate between the results.

	The @ExecGuid out parameter is the afore mentioned GUID that is plopped into the temp table.

	Example Usage:

		DROP PROCEDURE spTest
		GO
		DROP TABLE ##spTest
		GO

		CREATE PROCEDURE spTest @a int, @b nvarchar(20)
		AS
		SELECT	@a [First], @b
		GO

		DECLARE @Guid uniqueidentifier
		EXEC sp_exec_into_table 'spTest', '1, N''Test''', @Guid OUTPUT

		SELECT	*
		FROM	##spTest
		WHERE	ExecGuid = @Guid

	LIMITATIONS: This WILL fail if your stored procedure changes any column names/types it returns

	If you find this sproc is giving odd errors, try dropping the ##sprocName table
*/
DECLARE	@SQL nvarchar(max),
	@Parameters nvarchar(max),
	@ColumnList nvarchar(max) = '',
	@ColumnListNoType nvarchar(max) ='',
	@GuidNvarchar char(36)

SELECT	@ExecGuid = NEWID()
SELECT	@GuidNvarchar = CAST(@ExecGuid AS char(36))

-- We need to deal with NULL column names, so just call that column Col1, Col2 etc
SELECT	@ColumnList = @ColumnList + ISNULL(RS.name, 'Col' + CAST (ROW_NUMBER() OVER(ORDER BY RS.column_ordinal) AS nvarchar)) + ' ' + RS.system_type_name + ',',
	@ColumnListNoType = @ColumnListNoType + ISNULL(RS.name, 'Col' + CAST (ROW_NUMBER() OVER(ORDER BY RS.column_ordinal) AS nvarchar)) + ','
FROM	sys.procedures P
	CROSS APPLY sys.dm_exec_describe_first_result_set('EXEC ' + @SprocName + ' ' + @CommaParameters,NULL,1) RS
WHERE	p.object_id = OBJECT_ID(@SprocName)

SELECT	@ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 1),
	@ColumnListNoType = LEFT(@ColumnListNoType, LEN(@ColumnListNoType) - 1)

IF OBJECT_ID('tempdb..##' + @SprocName) IS NULL
BEGIN	
	SELECT	@SQL = N'CREATE TABLE ##' + @SprocName + '(' + ISNULL(@ColumnList, '') + ', Spid int, ExecGUID uniqueidentifier '+ ')'

	EXEC	sys.sp_executeSQL @SQL
END

EXEC
(
	N'DECLARE	@ExecGuid uniqueidentifier = NEWID() ' +

	N'INSERT	##' + @SprocName + ' (' + @ColumnListNoType + ') ' +
	N' EXEC ' + @SprocName + ' ' + @CommaParameters + 
		
	N'UPDATE	##' + @SprocName + ' SET Spid = ' + @@SPID + ', ExecGUID = ''' + @GuidNvarchar + ''' WHERE ISNULL(Spid, ''-1'') = -1'
)


IF @Log > 0
BEGIN
	EXEC sp_exec_log	@SprocName = @SprocName,
			@CommaParameters = @CommaParameters,
			@ExecGuid = @ExecGuid,
			@DropTempTables = 0
END