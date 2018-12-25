CREATE OR ALTER FUNCTION tfnC#TypeName
(
	@system_type_id int
)
RETURNS TABLE
AS
RETURN
SELECT	CASE
			--WHEN @system_type_id = 34 THEN	N'Image'
			--WHEN @system_type_id = 35 THEN	N'Text'
			WHEN @system_type_id = 36 THEN  N'Guid'
			WHEN @system_type_id = 40 THEN  N'DateTime'
			WHEN @system_type_id = 41 THEN  N'DateTime'
			WHEN @system_type_id = 42 THEN	N'DateTime'
			WHEN @system_type_id = 43 THEN	N'DateTimeOffset'
			WHEN @system_type_id = 48 THEN	N'byte'
			WHEN @system_type_id = 52 THEN	N'Int16'
			WHEN @system_type_id = 56 THEN	N'Int32'
			WHEN @system_type_id = 58 THEN	N'DateTime'
			WHEN @system_type_id = 59 THEN	N'Single'
			WHEN @system_type_id = 60 THEN	N'Decimal'
			WHEN @system_type_id = 61 THEN	N'DateTime'
			WHEN @system_type_id = 62 THEN	N'Double'
			WHEN @system_type_id = 98 THEN	N'object'
			WHEN @system_type_id = 99 THEN	N'bool'
			WHEN @system_type_id = 104 THEN	N'Bit'
			WHEN @system_type_id = 106 THEN	N'Decimal'
			WHEN @system_type_id = 108 THEN	N'Double'
			WHEN @system_type_id = 122 THEN	N'Decimal'
			WHEN @system_type_id = 127 THEN	N'Int64'
			--WHEN @system_type_id = 240 THEN	N'hierarchyid'
			--WHEN @system_type_id = 240 THEN	N'geometry'
			--WHEN @system_type_id = 240 THEN	N'geography'
			WHEN @system_type_id = 165 THEN	N'Byte[]'
			WHEN @system_type_id = 167 THEN	N'string'
			WHEN @system_type_id = 173 THEN	N'Byte[]'
			WHEN @system_type_id = 175 THEN	N'char'
			WHEN @system_type_id = 189 THEN	N'Byte[]'
			WHEN @system_type_id = 231 THEN	N'string'
			WHEN @system_type_id = 239 THEN	N'string'
			WHEN @system_type_id = 241 THEN	N'Xml'
			--WHEN @system_type_id = 231 THEN	N'sysname'
		END [C#Type],
	CASE
		--WHEN @system_type_id = 34 THEN
		--WHEN @system_type_id = 35 THENxt'
		WHEN @system_type_id = 36 THEN 1
		WHEN @system_type_id = 40 THEN  1
		WHEN @system_type_id = 41 THEN  1
		WHEN @system_type_id = 42 THEN	1
		WHEN @system_type_id = 43 THEN	1
		WHEN @system_type_id = 48 THEN	1
		WHEN @system_type_id = 52 THEN	1
		WHEN @system_type_id = 56 THEN	1
		WHEN @system_type_id = 58 THEN	1
		WHEN @system_type_id = 59 THEN	1
		WHEN @system_type_id = 60 THEN	1
		WHEN @system_type_id = 61 THEN	1
		WHEN @system_type_id = 62 THEN	1
		WHEN @system_type_id = 98 THEN	0
		WHEN @system_type_id = 99 THEN	0
		WHEN @system_type_id = 104 THEN	1
		WHEN @system_type_id = 106 THEN	1
		WHEN @system_type_id = 108 THEN	1
		WHEN @system_type_id = 122 THEN 1
		WHEN @system_type_id = 127 THEN	1
		--WHEN @system_type_id = 240 THEerarchyid'
		--WHEN @system_type_id = 240 THEometry'
		--WHEN @system_type_id = 240 THEography'
		WHEN @system_type_id = 165 THEN	0
		WHEN @system_type_id = 167 THEN	0
		WHEN @system_type_id = 173 THEN	0
		WHEN @system_type_id = 175 THEN	1
		WHEN @system_type_id = 189 THEN	0
		WHEN @system_type_id = 231 THEN 0
		WHEN @system_type_id = 239 THEN 0
		WHEN @system_type_id = 241 THEN	0
	END [IsStruct]


