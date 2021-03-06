USE [Test]
GO
/****** Object:  StoredProcedure [dbo].[spCursorProcess]    Script Date: 26/08/2018 14:58:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[spCursorProcess] 
	@Stmt nvarchar(max),
	@spName nvarchar(200)
AS

DECLARE	@Decls nvarchar(max) = N'',
		@Vars nvarchar(max) = N'',
		@Sql nvarchar(max)


SELECT	@Decls = @Decls + N' @' + CONVERT(nvarchar(3), column_ordinal) + N' ' + S.system_type_name + N',',
		@Vars = @Vars + N'@' + CONVERT(nvarchar(3), column_ordinal) + N','
FROM	sys.dm_exec_describe_first_result_set(@Stmt, NULL, NULL) S
SELECT	@Decls = N'DECLARE ' + @Decls

SELECT	@Decls = [Str]
FROM	tfnRemoveRight(@Decls)

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
	IF @@FETCH_STATUS <> 0
	   BREAK

	EXEC ' + @spName + N' ' + @Vars +
N'
END
DEALLOCATE Curs
'

EXEC sp_executesql @Sql