CREATE OR ALTER FUNCTION tfnC#SqlParameter
(
	@procedure_object_id int,
	@paramter_id int,
	@IndentationLevel int

)
RETURNS TABLE
AS
RETURN
SELECT	
REPLICATE(char(9),@IndentationLevel) + N'new SqlParameter()
'
+ REPLICATE(char(9),@IndentationLevel) + N'{
'+ REPLICATE(char(9),@IndentationLevel+1) + N'ParameterName = "' + PA.name + N'",
'+ REPLICATE(char(9),@IndentationLevel+1) + N'SqlDbType = SqlDbType.' + C#T.SqlDbType + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'SqlValue = ' + C#N.Name + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Size = ' + CONVERT(nvarchar(5), T.max_length) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Precision = ' + CONVERT(nvarchar(5),T.precision) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Scale = ' + CONVERT(nvarchar(5), T.Scale) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'IsNullable = ' + CASE WHEN PA.is_nullable = 1 THEN N'true' ELSE N'false' END + N'
' + REPLICATE(char(9),@IndentationLevel) + N'}' Parameter
FROM	sys.procedures PR
		INNER JOIN sys.all_parameters PA ON PR.object_id = PA.object_id
		INNER JOIN sys.types T ON PA.system_type_id = T.system_type_id
		CROSS APPLY tfnC#SqlDbType(T.system_type_id) C#T
		CROSS APPLY tfnC#ParameterName(PA.name) C#N
WHERE	PR.object_id = @procedure_object_id
AND		PA.parameter_id = @paramter_id
AND		T.name <> N'sysname'