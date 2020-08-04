SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[Proc_ETL_Lineage_GetKey]
@LoadType nvarchar(1),
@TableName nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	-- The load for @TableName starts now 
	DECLARE @StartLoad datetime = SYSDATETIME();

	
	INSERT INTO EdFiDW.[dbo].[Lineage](
		 [TableName]
		,StartTime
		,EndTime
		,[Status]
		,[LoadType]
		)
	VALUES (
		 @TableName
		,@StartLoad
		,NULL
		,'P' --  P = In progress, E = Error, S = Success
		,@LoadType -- F = Full load	- I = Incremental load
		);

	-- If we're doing an initial load, remove the date of the most recent load for this table
	IF (@LoadType = 'F')
		BEGIN
			UPDATE EdFiDW.[dbo].[IncrementalLoads]
			SET LoadDate = '1753-01-01'
			WHERE TableName = @TableName

			DECLARE @sqlCmd NVARCHAR(MAX) = 'TRUNCATE TABLE ' + @TableName;
			EXEC sp_executesql @sqlCmd;
		END;

	-- Select the key of the previously inserted row
	SELECT MAX([LineageKey]) AS LineageKey
	FROM EdFiDW.dbo.[Lineage]
	WHERE 
		[TableName] = @TableName
		AND StartTime = @StartLoad

	RETURN 0;
END;
GO
