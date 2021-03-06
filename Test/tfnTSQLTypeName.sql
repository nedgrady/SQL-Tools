CREATE FUNCTION [dbo].[tfnTSQLTypeName]
(
	@object_id int,
	@column_id int
)
RETURNS TABLE
AS
RETURN
SELECT	T.name +	CASE WHEN TI.length = 1	THEN N'('+CAST(C.max_length AS nvarchar(10))+N')' ELSE
					CASE WHEN TI.Scale = 1	THEN N'('+CAST(C.scale AS nvarchar(10))+N')' ELSE
					CASE WHEN TI.scale_precision = 1 THEN N'('+CAST(C.precision AS nvarchar(10))+N','+CAST(C.scale AS nvarchar(10))+N')' ELSE N'' END END END [TSQLName]
FROM	sys.all_columns C
		INNER JOIN sys.types T ON C.system_type_id = T.user_type_id
		LEFT JOIN meta.TypeInfo TI ON C.user_type_id = TI.system_type_id
WHERE	C.column_id = @column_id
AND		C.object_id = @object_id