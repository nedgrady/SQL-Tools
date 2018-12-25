CREATE OR ALTER PROCEDURE spC#CreateMethod
	@procedure_object_id int
AS
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE	@C# nvarchar(max) = N'',
		@SqlParameters nvarchar(max),
		@ParameterCount int = 0


DECLARE	@SpName sysname =
(
	SELECT	name
	FROM	sys.procedures
	WHERE	object_id = @procedure_object_id
)

SET @C# = N'public static async Task Execute_' + @SpName + N'Async ('


SELECT	@C# = @C# + STRING_AGG(C#T.TypeName + N' ' + C#N.Name, N', '),
		@SqlParameters = STRING_AGG(C#P.Parameter, N',' + CHAR(13) + CHAR(10)),
		@ParameterCount = MAX(PA.parameter_id)
FROM	sys.procedures PR
		INNER JOIN sys.all_parameters PA ON PR.object_id = PA.object_id
		CROSS APPLY tfnC#MaybeNullableParameter(PR.object_id, PA.parameter_id) C#T
		CROSS APPLY tfnC#ParameterName(PA.name) C#N
		CROSS APPLY tfnC#SqlParameter(Pr.object_id, PA.parameter_id, 5) C#P
WHERE	PR.object_id = @procedure_object_id

SET @C# = @C# + CASE WHEN @ParameterCount > 0 THEN ', ' ELSE N' ' END + N' TaskCallback<SqlDataReader> callback)
{
	using (SqlConnection conn = new SqlConnection(CONNECTION))
	{
		await conn.OpenAsync();
		using (SqlCommand command = new SqlCommand()
		{
			CommandText = "' + @SpName + N'",
			CommandType = CommandType.StoredProcedure,
			Connection = conn
		})
		{
			command.Parameters.AddRange(
				new SqlParameter[] {
' + @SqlParameters + N'
				}
			);
			using (SqlDataReader reader = await command.ExecuteReaderAsync())
			{
				await callback(reader);
			}
		}
	}
}'

SELECT @C#