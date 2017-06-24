USE [Test]
GO
/****** Object:  StoredProcedure [dbo].[sp_dependencies]    Script Date: 13/06/2017 00:59:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_exec_stats]	@ObjectName sysname,
				@Depth int = NULL				
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@ObjectID int = OBJECT_ID(@ObjectName)
;WITH DependenciesCTE 
(
	fromName, 
	fromID, 
	fromDesc, 	
	[From Last Execution Time],
	[From Last Execution Total Duration],
	[From CPU time (μs)],
	[From Execs since compile],
	toName, 
	toID, 
	toDesc,
	[To Last Execution Time],
	[To Last Execution Total Duration],
	[To CPU time (μs)],
	[To Execs since compile],
	[Level]
)
AS
(	
	SELECT	@ObjectName referencing_name,
		referencing_id, 
		O1.type_desc,
		S1.last_execution_time,
		S1.last_elapsed_time,
		S1.last_worker_time,
		S1.execution_count,
		referenced_entity_name,
		OBJECT_ID(referenced_entity_name) referenced_id,
		O2.type_desc,
		S2.last_execution_time [Last Execution Time],
		S2.last_elapsed_time [Last Execution Total Duration],
		S2.last_worker_time [CPU time (μs)],
		S2.execution_count [Execs since compile],
		0
	FROM	sys.sql_expression_dependencies D
		LEFT JOIN sys.objects O1 ON O1.object_id = D.referencing_id
		LEFT JOIN sys.objects O2 ON O2.object_id = OBJECT_ID(D.referenced_entity_name)
		LEFT JOIN sys.dm_exec_procedure_stats S1 ON O1.object_id = S1.object_id
		LEFT JOIN sys.dm_exec_procedure_stats S2 ON O2.object_id = S2.object_id
	WHERE	D.referencing_id = @ObjectID
	AND	D.referenced_class = 1
	AND	D.referencing_minor_id = 0
	AND	O2.type IN ('P', 'FN', 'IF')

	UNION ALL

	SELECT	C.toName,
		C.toID,
		O1.type_desc,
		S1.last_execution_time [Last Execution Time],
		S1.last_elapsed_time [Last Execution Total Duration],
		S1.last_worker_time [CPU time (μs)],
		S1.execution_count [Execs since compile],
		D.referenced_entity_name,
		OBJECT_ID(D.referenced_entity_name) referenced_id,
		O2.type_desc,
		S2.last_execution_time [Last Execution Time],
		S2.last_elapsed_time [Last Execution Total Duration],
		S2.last_worker_time [CPU time (μs)],
		S2.execution_count [Execs since compile],
		C.Level + 1
	FROM	sys.sql_expression_dependencies D
		JOIN DependenciesCTE C ON D.referencing_id = C.toID 
		INNER JOIN sys.objects O1 ON O1.object_id = D.referencing_id
		INNER JOIN sys.objects O2 ON O2.object_id = OBJECT_ID(D.referenced_entity_name)
		INNER JOIN sys.dm_exec_procedure_stats S1 ON O1.object_id = S1.object_id
		INNER JOIN sys.dm_exec_procedure_stats S2 ON O2.object_id = S2.object_id
	WHERE	C.Level < ISNULL(@Depth, C.Level+1)
	AND	D.referenced_class = 1
	AND	D.referencing_minor_id = 0
	AND	O2.type IN ('P', 'FN', 'IF')
)
SELECT	fromName, 
	fromID, 
	fromDesc, 	
	[From Last Execution Time],
	[From Last Execution Total Duration],
	[From CPU time (μs)],
	[From Execs since compile],
	toName, 
	toID, 
	toDesc,
	[To Last Execution Time],
	[To Last Execution Total Duration],
	[To CPU time (μs)],
	[To Execs since compile],
	[Level]
FROM	DependenciesCTE