CREATE OR ALTER FUNCTION [dbo].[tfnChars]
(
	@str nvarchar(100),
	@Start int,
	@Chars int
)
RETURNS TABLE AS
RETURN
SELECT	TOP(@Chars) Num,
	SUBSTRING(@Str, Num, 1) [Char],
	ASCII(SUBSTRING(@Str, Num, 1)) [ASCII],
	UNICODE(SUBSTRING(@Str, Num, 1)) [UNICODE]
FROM	dbo.Numbers
WHERE	Num >= @Start
AND	Num < @Start + @Chars
ORDER BY	Num ASC