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
			WHEN PA.is_nullable = 1 AND N.IsStruct = 1 THEN N'?' ELSE N''
		END [TypeName]
FROM	sys.procedures PR
		INNER JOIN sys.all_parameters PA ON PR.object_id = PA.object_id
		INNER JOIN sys.types T ON PA.system_type_id = T.system_type_id
		CROSS APPLY tfnC#TypeName(T.system_type_id) N
WHERE	PR.object_id = @procedure_object_id
AND		PA.parameter_id = @parameter_id
AND		T.name <> N'sysname'
