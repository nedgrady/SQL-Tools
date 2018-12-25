CREATE OR ALTER FUNCTION tfnC#MaybeNullableParameter
(
	@procedure_object_id int,
	@parameter_id int
)
RETURNS TABLE
AS
RETURN
SELECT	N.C#Type +
	CASE
		WHEN P.is_nullable = 1 AND N.IsStruct = 1 THEN N'?' ELSE N''
	END [TypeName]
FROM	vwProcedures P
	CROSS APPLY tfnC#TypeName(P.system_type_id) N
WHERE	P.object_id = @procedure_object_id
AND	P.parameter_id = @parameter_id

