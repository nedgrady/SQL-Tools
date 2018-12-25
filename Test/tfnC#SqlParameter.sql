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
'+ REPLICATE(char(9),@IndentationLevel+1) + N'ParameterName = "' + P.PAName + N'",
'+ REPLICATE(char(9),@IndentationLevel+1) + N'SqlDbType = SqlDbType.' + C#T.SqlDbType + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'SqlValue = ' + C#N.Name + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Size = ' + CONVERT(nvarchar(5), P.max_length) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Precision = ' + CONVERT(nvarchar(5),P.precision) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Scale = ' + CONVERT(nvarchar(5), P.Scale) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'IsNullable = ' + CASE WHEN P.is_nullable = 1 THEN N'true' ELSE N'false' END + N'
' + REPLICATE(char(9),@IndentationLevel) + N'}' Parameter
FROM	vwProcedures P
	CROSS APPLY tfnC#SqlDbType(P.system_type_id) C#T
	CROSS APPLY tfnC#ParameterName(P.PAName) C#N
WHERE	P.object_id = @procedure_object_id
AND	P.parameter_id = @paramter_id