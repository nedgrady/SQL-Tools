CREATE OR ALTER FUNCTION [dbo].[tfnC#MethodText]
(
	@procedure_object_id int,
	@IndentationLevel int
)
RETURNS @Text TABLE
(
	Text nvarchar(max)
)
AS
BEGIN
	DECLARE	@C# nvarchar(max) = N'',
		@SqlParameters nvarchar(max),
		@ParameterCount int = 0,
		@Tab nvarchar(10) = Char(9)

	DECLARE	@1 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel),
		@2 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 1),
		@3 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 2),
		@4 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 3),
		@5 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 4)
	
	
	DECLARE	@SpName sysname =
	(
		SELECT	name
		FROM	sys.procedures
		WHERE	object_id = @procedure_object_id
	)
	
	SET @C# = @1 + N'public static async Task Execute_' + @SpName + N'Async ('
	
	
	SELECT	@C# = @C# + STRING_AGG(C#T.TypeName + N' ' + C#N.Name, N', '),
		@SqlParameters = STRING_AGG(C#P.Parameter, N',' + CHAR(13) + CHAR(10)),
		@ParameterCount = MAX(P.parameter_id)
	FROM	vwProcedures P
		CROSS APPLY tfnC#MaybeNullableParameter(P.object_id, P.parameter_id) C#T
		CROSS APPLY tfnC#ParameterName(P.PAName) C#N
		CROSS APPLY tfnC#SqlParameter(P.object_id, P.parameter_id, 8) C#P
	WHERE	P.object_id = @procedure_object_id
	
	SET @C# = @C# + CASE WHEN @ParameterCount > 0 THEN ', ' ELSE N' ' END + N' TaskCallback<SqlDataReader> callback)
' + @1 + N'{
' + @2 + N'using (SqlConnection conn = new SqlConnection(CONNECTION))
' + @2 + N'{
' + @3 +	N'await conn.OpenAsync();
' + @3 +	N'using (SqlCommand command = new SqlCommand()
' + @3 +	N'{
' + @4 +		N'CommandText = "' + @SpName + N'",
' + @4 +		N'CommandType = CommandType.StoredProcedure,
' + @4 +		N'Connection = conn
' + @3 +	N'})
' + @3 +	N'{
' + @4 +		N'command.Parameters.AddRange(
' + @5 +		N'new SqlParameter[] {
' +					@SqlParameters + N'
' + @5 +		N'}
' + @4 +		N');
' + @4 +		N'using (SqlDataReader reader = await command.ExecuteReaderAsync())
' + @4 +		N'{
' + @5 +		N'await callback(reader);
' + @4 +		N'}
' + @3 +	N'}
' + @2 + N'}
' + @1 + N'}'

	INSERT	@Text
	SELECT	@C#
	RETURN
END