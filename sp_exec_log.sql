CREATE PROCEDURE sp_exec_log	@SprocName nvarchar(max),
			@CommaParameters nvarchar(max) ='',
			@ExecGuid uniqueidentifier = NULL,
			@DropTempTables bit = 1,
			@SprocHistoryID int = NULL OUTPUT		
AS
/*
	This stored procedure takes a a stored procedure name, and comma separated list of parameters, calls the sproc with supplied parameters, then logs the results to ##SprocHistory.
	
	Parameters:	@SprocName - The name of the stored procedure we want to capture the results of
			
			@CommaParameters - A comma separated list of parameters (can be named or ordered)
			
			@ExecGuid - Mainly here for when this is called from sp_exec_into_table with logging set to 1. This parameter can be ignored if you just want to use sp_exec_log

			@DropTempTables - Another sproc here mainly for when this is called from sp_exec_into_table with logging set to 1. Change this flag if you want stored procedure specific tables to be dropped after execution.

			@SprocHistoryID - OUTPUT parameter that links to the ##SprocHistory table (where this sproc logs results to)

	This has quite a large dependency on sp_exec_into_table, although could work without it the SQL to create the server wide temp tables 
	for each stored procedure passed to sp_exec_into_table. 

	Example Usage:

		DROP PROCEDURE spTest
		GO

		CREATE PROCEDURE spTest @a int, @b nvarchar(20)
		AS
		SELECT	@a [First], @b
		GO

		DECLARE @ID int
		EXEC sp_exec_log N'spTest', '1, N''Test''', NULL, 1, @ID OUTPUT

		SELECT	*
		FROM	##SprocHistory
		WHERE	ID = @ID

	LIMITATIONS: This WILL fail if your stored procedure changes any column names/types it returns

	If you find this sproc is giving odd errors, try dropping the ##sprocName table created in sp_exec_into_table
*/
DECLARE	@SQL nvarchar(max),
	@Parameters nvarchar(max),
	@ColumnList nvarchar(max) = '',
	@Results XML,
	@Guidnvarchar nvarchar(36)

IF @ExecGuid IS NULL
BEGIN
	EXEC sp_exec_into_table	@SprocName = @SprocName,
				@CommaParameters = @CommaParameters,
				@Log = 0,
				@ExecGuid = @ExecGuid OUTPUT
END

SELECT	@Guidnvarchar = CAST(@ExecGuid AS nvarchar(36))

CREATE TABLE #Results (Results XML)
EXEC
(
	'DECLARE	@Results XML
	SELECT	@Results = 
	(
		SELECT	*
		FROM	##' + @SprocName + ' 
		 WHERE	ExecGUID = ''' + @ExecGuid + '''
		FOR XML PATH (''ResultRow'')
	)  
	 
	INSERT	#Results
	(
		Results
	)
	VALUES	
	(
		@Results
	)'
)


-- We COULD insert into the SprocHistory inside the dynamic sql above, to avoid having to pass the results out of it via #results
-- Chose not to so SPID would be more meaningful

SELECT	@Results = Results
FROM	#Results

IF OBJECT_ID('tempdb..##SprocHistory') IS NULL
BEGIN
	CREATE TABLE ##SprocHistory
	(
		ID int IDENTITY(1,1),
		Created smalldatetime,
		SpName nvarchar(200),
		Results XML,
		Spid int,
		ParameterList nvarchar(max)
	)
END

INSERT	##SprocHistory
(
	Created,
	SpName,
	Results,
	Spid,
	ParameterList
)
VALUES
(
	GETDATE(),
	@SprocName,
	@Results,
	@@SPID,
	@CommaParameters	
)

SELECT	@SprocHistoryID = SCOPE_IDENTITY()

IF @DropTempTables > 0 
BEGIN
	EXEC
	(
		'DROP TABLE ##' + @SprocName
	)
END

DROP TABLE #Results