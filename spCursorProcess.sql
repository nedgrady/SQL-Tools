CREATE OR ALTER PROCEDURE spCursorProcess 
	@Stmt nvarchar(max),
	@spName nvarchar(200)
AS

DECLARE	@Decls nvarchar(max) = N'',
		@Vars nvarchar(max) = N'',
		@Sql nvarchar(max)


SELECT @Decls = @Decls + N' @' + CONVERT(nvarchar(3), column_ordinal) + N' ' + S.system_type_name + N','
FROM   sys.dm_exec_describe_first_result_set(@Stmt, NULL, NULL) S
SELECT	@Decls = N'DECLARE ' + @Decls

SELECT	@Decls = [Str]
FROM	tfnRemoveRight(@Decls)

SELECT @Vars = @Vars + N'@' + CONVERT(nvarchar(3), column_ordinal) + N','
FROM   sys.dm_exec_describe_first_result_set(@Stmt, NULL, NULL) S

SELECT	@Vars = [Str] 
FROM	tfnRemoveRight (@Vars)

SELECT @Sql = 
@Decls +
N'
DECLARE Curs CURSOR LOCAL FAST_FORWARD FOR
' +
@Stmt +
N'
OPEN Curs
WHILE 1=1
BEGIN
	FETCH Curs INTO
	' + @Vars +
N'
	IF @@fetch_status <> 0
	   BREAK

	EXEC ' + @spName + N' ' + @Vars +
N'
END
DEALLOCATE Curs
'

EXEC sp_executesql @Sql