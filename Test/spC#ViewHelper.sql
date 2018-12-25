CREATE OR ALTER PROCEDURE spC#ViewHelper
	@DBName nvarchar(max)
AS
DECLARE @SQL nvarchar(max)

IF EXISTS
(
	SELECT	*
	FROM	sys.views
	WHERE	name = N'vwProcedures'
)
BEGIN
	DROP VIEW vwProcedures
END

SET @SQL = N'
CREATE VIEW vwProcedures
AS
SELECT	PR.object_id,
	PR.name PRName,
	PA.parameter_id,
	PA.system_type_id,
	PA.name PAName,
	PA.is_nullable,
	PA.scale,
	PA.precision,
	PA.max_length
FROM	' + QUOTENAME(@DBName) + N'.sys.procedures PR
	INNER JOIN ' + QUOTENAME(@DBName) + N'.sys.all_parameters PA ON PR.object_id = PA.object_id
	INNER JOIN ' + QUOTENAME(@DBNAME) + N'.sys.types T ON PA.system_type_id = T.system_type_id
WHERE	T.name <> N''sysname'' '

EXEC sp_executesql @SQL