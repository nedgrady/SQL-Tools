DROP DATABASE IF EXISTS C#Generator
GO
CREATE DATABASE C#Generator
GO
USE C#Generator
GO
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
GO
/****** Object:  Table [dbo].[Numbers]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
DROP TABLE IF EXISTS dbo.Numbers
GO
CREATE TABLE [dbo].[Numbers](
	[Num] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Num] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
INSERT	dbo.Numbers
(
	Num
)
SELECT	TOP (100000) ROW_NUMBER() OVER (ORDER BY O.object_id)
FROM	sys.all_objects O
	CROSS JOIN sys.all_objects O2
/****** Object:  StoredProcedure [dbo].[spC#ViewHelper]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[spC#ViewHelper]
	@DBName nvarchar(max)
AS
DECLARE @SQL nvarchar(max)

IF EXISTS
(
	SELECT	*
	FROM	sys.views
	WHERE	name = N'vwProcedures'
)
BEGIN
	DROP VIEW vwProcedures
END

IF EXISTS
(
	SELECT	*
	FROM	sys.views
	WHERE	name = N'vwParameters'
)
BEGIN
	DROP VIEW vwParameters
END

SET @SQL = N'
CREATE VIEW vwParameters
AS
SELECT	PR.object_id,
	PR.name PRName,
	PA.parameter_id,
	PA.system_type_id,
	PA.name PAName,
	PA.is_nullable,
	PA.scale,
	PA.precision,
	PA.max_length
FROM	' + QUOTENAME(@DBName) + N'.sys.procedures PR
	INNER JOIN ' + QUOTENAME(@DBName) + N'.sys.all_parameters PA ON PR.object_id = PA.object_id
	INNER JOIN ' + QUOTENAME(@DBName) + N'.sys.types T ON PA.system_type_id = T.system_type_id
WHERE	T.name <> N''sysname''
AND	NOT EXISTS
	(
		SELECT	*
		FROM	dbo.TypeFilter TF
		WHERE	TF.system_type_id = PA.system_type_id
	)'

EXEC sp_executesql @SQL

SET @SQL = N'
CREATE VIEW vwProcedures
AS
SELECT	PR.object_id,
	PR.name PRName,
	S.name [SchemaName]
FROM	' + QUOTENAME(@DBName) + N'.sys.procedures PR
	INNER JOIN ' + QUOTENAME(@DBName) + N'.sys.schemas S ON S.schema_id = PR.schema_id'

EXEC sp_executesql @SQL
GO
DECLARE @Name sysname = DB_NAME()
EXEC [dbo].[spC#ViewHelper] @DBName = @Name
/****** Object:  UserDefinedFunction [dbo].[tfnC#MethodText]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[tfnC#MethodText]
(
	@procedure_object_id int,
	@IndentationLevel int,
	@AppendText nvarchar(32) = NULL
)
RETURNS @Text TABLE
(
	Text nvarchar(max)
)
AS
BEGIN
	DECLARE	@C# nvarchar(max) = N'',
		@SqlParameters nvarchar(max),
		@ParameterCount int = 0,
		@Tab nvarchar(10) = Char(9),
		@SpName nvarchar(200),
		@SchemaName nvarchar(200),
		@SchemaSafeName nvarchar(200),
		@SpSafeName nvarchar(200),
		@ConnVar nvarchar(50) = N'@connection_' + ISNULL(@AppendText, N''),
		@CommandVar char(50) = N'@command_' + ISNULL(@AppendText, N''),
		@ReaderVar char(50) = N'@reader_' + ISNULL(@AppendText, N'')

	DECLARE	@1 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel),
		@2 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 1),
		@3 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 2),
		@4 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 3),
		@5 nvarchar(10) = REPLICATE(@Tab, @IndentationLevel + 4)
	
	SELECT	TOP (1) 
		@SpName = PRName,
		@SchemaName = SchemaName
	FROM	vwProcedures
	WHERE	object_id = @procedure_object_id

	SELECT	TOP (1) @SpSafeName = N.Str
	FROM	tfnReplaceNonAlpha(@SpName, 1, LEN(@SpName), N'_') N

	SELECT	TOP (1) @SchemaSafeName = N.Str
	FROM	tfnReplaceNonAlpha(@SchemaName, 1, LEN(@SchemaName), N'_') N
	
	SET @C# = @1 + N'public static async Task Execute_' + @SpSafeName + N'_' + @SchemaSafeName + N'Async ('
	
	
	SELECT	@C# = @C# + STRING_AGG(CAST(C#T.TypeName + N' ' + C#N.SafeName AS nvarchar(max)), N', '),
		@SqlParameters = STRING_AGG(CAST(ISNULL(C#P.Parameter, N'') AS nvarchar(max)), N',' + CHAR(13) + CHAR(10)),
		@ParameterCount = MAX(P.parameter_id)
	FROM	vwParameters P
		CROSS APPLY tfnC#MaybeNullableType(P.object_id, P.parameter_id) C#T
		CROSS APPLY tfnC#SafeName(P.PAName) C#N
		CROSS APPLY dbo.tfnC#SqlParameter(P.object_id, P.parameter_id, @IndentationLevel + 5) C#P
	WHERE	P.object_id = @procedure_object_id
	
	SET @C# = @C# + CASE WHEN @ParameterCount > 0 THEN ', ' ELSE N' ' END + N' Func<SqlDataReader, Task> callback)
' + @1 + N'{
' + @2 + N'using (SqlConnection ' + @ConnVar + N' = new SqlConnection(CONNECTION_' + @AppendText + N'))
' + @2 + N'{
' + @3 +	N'await ' + @ConnVar + N'.OpenAsync().ConfigureAwait(false);
' + @3 +	N'using (SqlCommand ' + @CommandVar + N' = new SqlCommand()
' + @3 +	N'{
' + @4 +		N'CommandText = "' + @SpName + N'",
' + @4 +		N'CommandType = CommandType.StoredProcedure,
' + @4 +		N'Connection = ' + @ConnVar + N'
' + @3 +	N'})
' + @3 +	N'{
' + @4 +		@CommandVar + N'.Parameters.AddRange(
' + @5 +		N'new SqlParameter[] {
' +					@SqlParameters + N'
' + @5 +		N'}
' + @4 +		N');
' + @4 +		N'using (SqlDataReader ' + @ReaderVar + N' = await ' + @CommandVar + N'.ExecuteReaderAsync().ConfigureAwait(false))
' + @4 +		N'{
' + @5 +		N'await callback(' + @ReaderVar + N').ConfigureAwait(false);
' + @4 +		N'}
' + @3 +	N'}
' + @2 + N'}
' + @1 + N'}'

	INSERT	@Text
	SELECT	@C#
	RETURN
END
GO
/****** Object:  UserDefinedFunction [dbo].[tfnChars]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[tfnChars]
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
GO
/****** Object:  UserDefinedFunction [dbo].[tfnReplaceNonAlpha]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[tfnReplaceNonAlpha]
(
	@Str nvarchar(200),
	@Start int,
	@Chars int,
	@Replace char(1)
)
RETURNS TABLE
AS
RETURN
SELECT	STRING_AGG
	(
		CASE
			WHEN 
			(
				(LOWER(C.Char) NOT BETWEEN 'a' AND 'z') AND
				(C.Char NOT BETWEEN '0' AND '9')
			) THEN @Replace
			ELSE C.Char
		END, ''
	) [Str]
FROM	tfnChars(@Str, @Start, @Chars) C

GO
/****** Object:  UserDefinedFunction [dbo].[tfnC#Prepend@]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[tfnC#Prepend@]
(
	@SqlName nvarchar(200)
)
RETURNS TABLE
AS
RETURN
SELECT	CASE
		WHEN SUBSTRING(@SqlName, 1, 1) = N'@' THEN @SqlName 
		ELSE N'@' + @SqlName 
	END [SafeName]
GO
/****** Object:  UserDefinedFunction [dbo].[tfnC#SafeName]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[tfnC#SafeName]
(
	@Name nvarchar(200)
)
RETURNS TABLE
AS
RETURN
SELECT	N.SafeName
FROM	tfnC#Prepend@
	(
		(SELECT	TOP (1) Str 
		FROM	tfnReplaceNonAlpha
			(
				@Name, 
				CASE WHEN LEFT(@Name, 1) = N'@' THEN 2 ELSE 1 END, 
				CASE WHEN LEFT(@Name, 1) = N'@' THEN LEN(@Name) - 1 ELSE LEN(@Name) END, 
				'_')
			)
	) N
GO
/****** Object:  UserDefinedFunction [dbo].[tfnC#TypeName]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[tfnC#TypeName]
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
			WHEN @system_type_id = 104 THEN	N'byte'
			WHEN @system_type_id = 106 THEN	N'Decimal'
			WHEN @system_type_id = 108 THEN	N'Double'
			WHEN @system_type_id = 122 THEN	N'Decimal'
			WHEN @system_type_id = 127 THEN	N'Int64'
			--WHEN @system_type_id = 240 THEN	N'hierarchyid'
			--WHEN @system_type_id = 240 THEN	N'geometry'
			--WHEN @system_type_id = 240 THEN	N'geography'
			WHEN @system_type_id = 165 THEN	N'byte[]'
			WHEN @system_type_id = 167 THEN	N'string'
			WHEN @system_type_id = 173 THEN	N'Byte[]'
			WHEN @system_type_id = 175 THEN	N'char'
			WHEN @system_type_id = 189 THEN	N'byte[]'
			WHEN @system_type_id = 231 THEN	N'string'
			WHEN @system_type_id = 239 THEN	N'string'
			WHEN @system_type_id = 241 THEN	N'SqlXml'

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

GO
/****** Object:  UserDefinedFunction [dbo].[tfnC#MaybeNullableType]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     FUNCTION [dbo].[tfnC#MaybeNullableType]
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
FROM	vwParameters P
	CROSS APPLY tfnC#TypeName(P.system_type_id) N
WHERE	P.object_id = @procedure_object_id
AND	P.parameter_id = @parameter_id
GO
/****** Object:  UserDefinedFunction [dbo].[tfnRemoveFirstCharacter]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[tfnRemoveFirstCharacter]
(
	@Str nvarchar(max)
)
RETURNS TABLE
AS
RETURN
SELECT	RIGHT(@str, LEN(@Str)-1) [Str]

GO
/****** Object:  UserDefinedFunction [dbo].[tfnC#ParameterName]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[tfnC#ParameterName]
(
	@SqlName nvarchar(200)
)
RETURNS TABLE
AS
RETURN
SELECT	N'p' + N.Str [Name]
FROM	tfnRemoveFirstCharacter(@SqlName) N
GO
/****** Object:  UserDefinedFunction [dbo].[tfnC#SqlDbType]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[tfnC#SqlDbType]
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
GO
/****** Object:  UserDefinedFunction [dbo].[tfnC#SqlParameter]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[tfnC#SqlParameter]
(
	@procedure_object_id int,
	@paramter_id int,
	@IndentationLevel int
)
RETURNS TABLE
AS
RETURN
SELECT	
REPLICATE(char(9),@IndentationLevel) + N'new SqlParameter()
'
+ REPLICATE(char(9),@IndentationLevel) + N'{
'+ REPLICATE(char(9),@IndentationLevel+1) + N'ParameterName = "' + P.PAName + N'",
'+ REPLICATE(char(9),@IndentationLevel+1) + N'SqlDbType = SqlDbType.' + C#T.SqlDbType + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'SqlValue = ' + C#N.SafeName + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Size = ' + CONVERT(nvarchar(5), P.max_length) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Precision = ' + CONVERT(nvarchar(5),P.precision) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'Scale = ' + CONVERT(nvarchar(5), P.Scale) + N',
'+ REPLICATE(char(9),@IndentationLevel+1) + N'IsNullable = ' + CASE WHEN P.is_nullable = 1 THEN N'true' ELSE N'false' END + N'
' + REPLICATE(char(9),@IndentationLevel) + N'}' Parameter
FROM	vwParameters P
	CROSS APPLY tfnC#SqlDbType(P.system_type_id) C#T
	CROSS APPLY tfnC#SafeName(P.PAName) C#N
WHERE	P.object_id = @procedure_object_id
AND	P.parameter_id = @paramter_id
GO
/****** Object:  StoredProcedure [dbo].[spC#GenerateAllMethods]    Script Date: 03/09/2018 22:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[spC#GenerateAllMethods]
	@DBName nvarchar(max),
	@ConnectionString nvarchar(max),
	@Namespace nvarchar(max) = null,
	@ClassName nvarchar(max) = null,
	@AppendText nvarchar(32) = null
AS

SET CONCAT_NULL_YIELDS_NULL OFF

IF NOT EXISTS
(
	SELECT	*
	FROM	sys.databases
	WHERE	name LIKE @DBName
)
BEGIN
	RAISERROR(N'Error generating class for database %s - database does not exist.', 15, 1, @DbName)
END

BEGIN TRY
	EXEC spC#ViewHelper @DBName

	DECLARE	@C# nvarchar(max) = N''
	
	IF @Namespace IS NOT NULL
	BEGIN

		SET @C# = 
N'using System;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using System.Data.SqlTypes;
namespace ' + @Namespace + N'
{
'
	END
	
	SET @C# = @C# + 
	N'
	/// <summary>
	/// Class autogenerated by ned''s SQL to C# utility....
	/// </summary>
	public static class ' + ISNULL(@ClassName, @DBName) + N'Database
	{
		public const string CONNECTION_' + @AppendText + N'= @"' + @ConnectionString + N'";

'
	
	
	SELECT	@C# = @C# + T.Text + CHAR(13) + CHAR(10)
	FROM	vwProcedures P
		CROSS APPLY tfnC#MethodText(P.object_id, 2, @AppendText) T
	
	SELECT	@C# = @C# + N'	}
}'

	SELECT @C#

	DROP VIEW vwProcedures
	DROP VIEW vwParameters
END TRY
BEGIN CATCH
	DROP VIEW vwProcedures
	DROP VIEW vwParameters
	;THROW
END CATCH
GO