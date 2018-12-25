DROP TABLE IF EXISTS dbo.TypeFilter
GO
CREATE TABLE dbo.TypeFilter
(
	system_type_id int PRIMARY KEY CLUSTERED
)
GO
INSERT	dbo.TypeFilter
SELECT	243 -- Exclude table types.. for now
UNION ALL
SELECT	240 -- exclude CLR types (hierarchyid, geometry, geography) as i couldn't find their .NET equivalent
UNION ALL
SELECT	34 -- exclude image
UNION ALL
SELECT	35 --exclude text