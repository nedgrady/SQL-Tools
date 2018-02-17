DROP TABLE IF EXISTS meta.TypeInfo
GO
CREATE TABLE [meta].[TypeInfo]
(
	[system_type_id] [int] PRIMARY KEY CLUSTERED,
	[length] [bit] NOT NULL,
	[scale_precision] [bit] NOT NULL,
	[Scale] [bit] NOT NULL
)
GO
INSERT INTO	[meta].[TypeInfo]
(
	[system_type_id],
	[length],
	[scale_precision],
	[Scale]
)
SELECT 106,	0,	1,	0
UNION ALL
SELECT 108,	0,	1,	0
UNION ALL
SELECT 62,	1,	0,	0
UNION ALL
SELECT 41,	0,	0,	1
UNION ALL
SELECT 42,	0,	0,	1
UNION ALL
SELECT 43,	0,	0,	1
UNION ALL
SELECT 175,	1,	0,	0
UNION ALL
SELECT 239,	1,	0,	0
UNION ALL
SELECT 167,	1,	0,	0
UNION ALL
SELECT 231,	1,	0,	0
UNION ALL
SELECT 173,	1,	0,	0
UNION ALL
SELECT 165,	1,	0,	0