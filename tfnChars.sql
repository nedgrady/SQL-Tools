CREATE OR ALTER FUNCTION tfnChars
(
	@str nvarchar(100)
)
RETURNS TABLE AS
RETURN
WITH cteNumbers AS
(
	SELECT	1 Num
	UNION ALL
	SELECT	Num + 1
	FROM	cteNumbers
)
SELECT	TOP(LEN(@str)) Num,
		SUBSTRING(@Str, Num, 1) [Char],
		ASCII(SUBSTRING(@Str, Num, 1)) [ASCII],
		UNICODE(SUBSTRING(@Str, Num, 1)) [UNICODE]
FROM	cteNumbers