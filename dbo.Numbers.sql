IF(OBJECT_ID(N'dbo.Numbers') IS NULL)
BEGIN
	CREATE TABLE dbo.Numbers
	(
		Num int PRIMARY KEY CLUSTERED
	)

	INSERT	dbo.Numbers
	(
		Num
	)
	SELECT	TOP (100000) ROW_NUMBER() OVER (ORDER BY @@SPID)
	FROM	sys.all_objects O
		CROSS JOIN sys.all_objects O2
END