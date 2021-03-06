ALTER PROCEDURE [dbo].[sp_dependencies]	@ObjectName sysname,
					@Depth int = NULL,
					@FilterTypes bit = 1				
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@ObjectID int = OBJECT_ID(@ObjectName)
;WITH DependenciesCTE 
(
	fromName, 
	fromID, 
	fromDesc, 
	toName, 
	toID, 
	toDesc, 
	[Level]
)
AS
(	
	SELECT	@ObjectName referencing_name,
		referencing_id, 
		O1.type_desc,
		referenced_entity_name,
		OBJECT_ID(referenced_entity_name) referenced_id,
		O2.type_desc,
		0
	FROM	sys.sql_expression_dependencies D
		LEFT JOIN sys.objects O1 ON O1.object_id = D.referencing_id
		LEFT JOIN sys.objects O2 ON O2.object_id = OBJECT_ID(D.referenced_entity_name)
	WHERE	D.referencing_id = @ObjectID
	AND	D.referenced_class = 1
	AND	D.referencing_minor_id = 0
	AND	(O2.type IN ('P', 'FN', 'IF') OR @FilterTypes = 0)

	UNION ALL

	SELECT	C.toName,
		C.toID,
		O1.type_desc,
		D.referenced_entity_name,
		OBJECT_ID(D.referenced_entity_name) referenced_id,
		O2.type_desc,
		C.Level + 1
	FROM	sys.sql_expression_dependencies D
		INNER JOIN DependenciesCTE C ON D.referencing_id = C.toID 
		INNER JOIN sys.objects O1 ON O1.object_id = D.referencing_id
		INNER JOIN sys.objects O2 ON O2.object_id = OBJECT_ID(D.referenced_entity_name)
	WHERE	C.Level < ISNULL(@Depth, C.Level+1)
	AND	D.referenced_class = 1
	AND	D.referencing_minor_id = 0
	AND	(O2.type IN ('P', 'FN', 'IF') OR @FilterTypes = 0)
)
SELECT	fromName, 
	fromID, 
	fromDesc,
	toName, 
	toID, 
	toDesc, 
	[Level]
FROM	DependenciesCTE