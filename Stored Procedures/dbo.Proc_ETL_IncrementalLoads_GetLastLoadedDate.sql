SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[Proc_ETL_IncrementalLoads_GetLastLoadedDate]
@TableName nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	-- If the procedure is executed with a wrong table name, throw an error.
	IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = @TableName AND Type = N'U')
	BEGIN
        PRINT N'The table does not exist in the data warehouse.';
        THROW 51000, N'The table does not exist in the data warehouse.', 1;
        RETURN -1;
	END
	
    -- If the table exists, but was never loaded before, there won't have a record for it
	-- A record is created for the @TableName with the minimum possible date in the LoadDate column
	IF NOT EXISTS (SELECT 1 FROM LongitudinalPOC.[dbo].[IncrementalLoads] WHERE TableName = @TableName)
		INSERT INTO LongitudinalPOC.[dbo].[IncrementalLoads](TableName,LoadDate)
		SELECT @TableName, '1753-01-01'

    -- Select the LoadDate for the @TableName
	SELECT 
		[LoadDate] AS [LoadDate]
    FROM LongitudinalPOC.[dbo].[IncrementalLoads]
    WHERE 
		TableName = @TableName;

    RETURN 0;
END;
GO
