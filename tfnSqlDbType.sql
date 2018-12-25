CREATE OR ALTER FUNCTION tfnC#SqlDbType
(
	@system_type_id int
)
RETURNS TABLE
AS
RETURN
SELECT	CASE
			WHEN @system_type_id = 34 THEN	N'Image'
			WHEN @system_type_id = 35 THEN	N'Text'
			WHEN @system_type_id = 36 THEN  N'UniqueIdentifier'
			WHEN @system_type_id = 40 THEN  N'Date'
			WHEN @system_type_id = 41 THEN  N'Time'
			WHEN @system_type_id = 42 THEN	N'DateTime2'
			WHEN @system_type_id = 43 THEN	N'DateTimeOffset'
			WHEN @system_type_id = 48 THEN	N'TinyInt'
			WHEN @system_type_id = 52 THEN	N'SmallInt'
			WHEN @system_type_id = 56 THEN	N'Int'
			WHEN @system_type_id = 58 THEN	N'DateTime'
			WHEN @system_type_id = 59 THEN	N'Real'
			WHEN @system_type_id = 60 THEN	N'Money'
			WHEN @system_type_id = 61 THEN	N'DateTime'
			WHEN @system_type_id = 62 THEN	N'Float'
			WHEN @system_type_id = 98 THEN	N'Variant'
			WHEN @system_type_id = 99 THEN	N'NText'
			WHEN @system_type_id = 104 THEN	N'Bit'
			WHEN @system_type_id = 106 THEN	N'Decimal'
			WHEN @system_type_id = 108 THEN	N'Float'
			WHEN @system_type_id = 122 THEN	N'SmallMoney'
			WHEN @system_type_id = 127 THEN	N'BigInt'
			--WHEN @system_type_id = 240 THEN	N'hierarchyid'
			--WHEN @system_type_id = 240 THEN	N'geometry'
			--WHEN @system_type_id = 240 THEN	N'geography'
			WHEN @system_type_id = 165 THEN	N'VarBinary'
			WHEN @system_type_id = 167 THEN	N'VarChar'
			WHEN @system_type_id = 173 THEN	N'Binary'
			WHEN @system_type_id = 175 THEN	N'Char'
			WHEN @system_type_id = 189 THEN	N'Timestamp'
			WHEN @system_type_id = 231 THEN	N'NVarChar'
			WHEN @system_type_id = 239 THEN	N'NChar'
			WHEN @system_type_id = 241 THEN	N'Xml'
			--WHEN @system_type_id = 231 THEN	N'sysname'
		END [SqlDbType]