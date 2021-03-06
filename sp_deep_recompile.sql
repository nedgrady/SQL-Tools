USE [Test]
GO
/****** Object:  StoredProcedure [dbo].[sp_deep_recompile]    Script Date: 13/06/2017 00:58:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_deep_recompile]	@ObjectName sysname,
					@Depth int = NULL
AS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Name sysname

CREATE TABLE #Names
(
	fromName sysname, 
	fromID int, 
	fromDesc nvarchar(60), 
	toName sysname, 
	toID int, 
	toDesc nvarchar(60), 
	[Level] int
)
INSERT	#Names
EXEC	sp_dependencies	@ObjectName = @ObjectName,
			@Depth = @Depth,
			@FilterTypes = 1


DECLARE Objs CURSOR FOR
SELECT	DISTINCT toName
FROM	#Names

OPEN Objs
FETCH NEXT FROM Objs 
INTO @Name

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sys.sp_recompile @Name

	FETCH NEXT FROM Objs INTO @Name
END

CLOSE Objs
DEALLOCATE Objs