CREATE OR ALTER FUNCTION tfnC#ParameterName
(
	@SqlName nvarchar(200)
)
RETURNS TABLE
AS
RETURN
SELECT	N'p' + N.Str [Name]
FROM	tfnRemoveFirstCharacter(@SqlName) N


