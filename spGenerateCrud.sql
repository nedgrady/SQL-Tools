CREATE PROCEDURE [dbo].[spGenerateCrud]
	@object_id int
AS
DECLARE @ColList nvarchar(1000), @ColVarList nvarchar(1000), @ColVarDeclList nvarchar(1000)
DECLARE @NL nchar(2) = CHAR(13)+CHAR(10)
DECLARE @Tab nchar(1) = CHAR(9)
DECLARE @NT nchar(3) = @NL + @Tab

DECLARE @TableName sysname =
(
	SELECT	TOP (1) name
	FROM	sys.tables
	WHERE	object_id = @object_id
)

DECLARE @Cols dbo.Col

INSERT	@Cols
(
	Name,
	Type,
	IsIdentity
)
SELECT	C.name,
		T.TSQLName,
		C.is_identity
FROM	sys.all_columns C
		CROSS APPLY dbo.[tfnTSQLTypeName](C.object_id, C.column_id) T
WHERE	C.object_id = @object_id


SELECT	@ColList = 
(
	SELECT	N',' + C.Name
	FROM	@Cols C
	WHERE	IsIdentity < 1
	FOR XML PATH ('')
)
-- Remove pesky leading comma
SELECT	@ColList = dbo.fnRemoveFirstCharacter(@ColList)
-- Format list so each column is tabbed in and on new line.
SELECT	@ColList = @Tab + REPLACE(@ColList, N',', N',' + @NT)

SELECT	@ColVarList = 
(
	SELECT	N',@' + C.Name
	FROM	@Cols C
	WHERE	IsIdentity < 1
	FOR XML PATH ('')
)
SELECT	@ColVarList = dbo.fnRemoveFirstCharacter(@ColVarList)
-- Format list so each column is tabbed in and on new line.
SELECT	@ColVarList = @Tab + REPLACE(@ColVarList, N',', N',' + @NT)

SELECT	@ColVarDeclList = 
(
	SELECT	N',@' + C.Name + N' ' + C.Type
	FROM	@Cols C
	WHERE	IsIdentity < 1
	FOR XML PATH ('')
)
SELECT	@ColVarDeclList = dbo.fnRemoveFirstCharacter(@ColVarDeclList)
-- Format list so each column is tabbed in and on new line.
SELECT	@ColVarDeclList = @Tab + REPLACE(@ColVarDeclList, N',', N',' + @NT)

-- CREATE SP Text Start ====================================================
DECLARE @SP nvarchar(max) =
N'CREATE PROCEDURE sp' + @TableName + N'Create' + @NL + @ColVarDeclList + @NL + N'AS' + @NL

DECLARE @InsertStmt nvarchar(max) = 
	N'INSERT INTO ' + @TableName + @NL + N'(' + @NL + @ColList + @NL + N')' +
	@NL + N'VALUES' + @NL + N'(' + @NL + @ColVarList + @NL + N');'

SELECT	@SP = @SP + @InsertStmt

SELECT @SP
-- CREATE SP Text End ====================================================

DECLARE @IDCol nvarchar(50),
		@IDType nvarchar(50),
		@IDVar nvarchar(50)

SELECT	@IDCol = C.Name,
		@IDType = C.Type,
		@IDVar = N'@' + C.Name
FROM	@Cols C
WHERE	IsIdentity = 1

-- Shove our identity onto start of parameter list
SELECT	@ColVarDeclList = @Tab + @IDCol + N' ' + @IDType + N',' + @NL + @ColVarDeclList

-- Will take form of col = @col in update statement
DECLARE @UpdateList nvarchar(max)
SELECT	@UpdateList = 
(
	SELECT	N',' + C.Name + N' = ' + N'@' + C.Name
	FROM	@Cols C
	FOR XML PATH('')
)
SELECT	@UpdateList = dbo.fnRemoveFirstCharacter(@UpdateList)
SELECT	@UpdateList = REPLACE(@UpdateList, N',', N',' + @NT)

-- UPDATE SP Text Start ====================================================
SELECT	@SP = N'CREATE PROCEDURE sp' + @TableName + N'Update' + @NL + @ColVarDeclList + @NL + N'AS' + @NL
DECLARE @UpdateStmt nvarchar(max) = 
	N'UPDATE' + @Tab + @TableName + @NL +
	N'SET' + @Tab + @UpdateList + @NL + 
	N'WHERE' + @Tab + @IDCol + N' = ' + @IDVar  + N';'

SELECT	@SP = @SP + @UpdateStmt
SELECT	@SP
PRINT N'Update End'
-- UPDATE SP Text End ====================================================

-- DELETE SP Text Start ====================================================
SELECT	@SP = N'CREATE PROCEDURE sp' + @TableName + N'Delete' + @NT + @IDVar + N' ' + @IDType + @NL + N'AS' + @NL
DECLARE @DeleteStmt nvarchar(max) = 
	N'DELETE' + @Tab + @TableName + @NL +
	N'WHERE' + @Tab + @IDCol + N'=' + @IDVar
SELECT @SP = @SP + @DeleteStmt
SELECT @SP
-- DELETE SP Text End ====================================================


