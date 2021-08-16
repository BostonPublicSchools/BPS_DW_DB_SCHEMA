SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--Stored Procedures
----------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_Lineage_GetKey]
@LoadType nvarchar(1),
@TableName nvarchar(100)
AS
BEGIN
    --added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

    --current session wont be the deadlock victim if it is involved in a deadlock with other sessions with the deadlock priority set to LOW
	SET DEADLOCK_PRIORITY HIGH;
	
	--When SET XACT_ABORT is ON, if a Transact-SQL statement raises a run-time error, the entire transaction is terminated and rolled back.
	SET XACT_ABORT ON;

	--This will allow for dirty reads. By default SQL Server uses "READ COMMITED" 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;



	BEGIN TRY

		BEGIN TRANSACTION;   
		
		DECLARE @StartLoad datetime = SYSDATETIME(); -- SYSDATETIME return datetime2 which is more precise
	
		INSERT INTO [dbo].[ETL_Lineage](
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
				UPDATE [dbo].[ETL_IncrementalLoads]
				SET LoadDate = '07/01/2015'
				WHERE TableName = @TableName
			END;

		-- Select the key of the previously inserted row
		SELECT MAX(LineageKey) AS LineageKey
		FROM dbo.[ETL_Lineage]
		WHERE 
			[TableName] = @TableName
			AND StartTime = @StartLoad

	    COMMIT TRANSACTION;		
	END TRY
	BEGIN CATCH
		
		--constructing exception details
		DECLARE
		   @errorMessage nvarchar( MAX ) = ERROR_MESSAGE( );		
     
		DECLARE
		   @errorDetails nvarchar( MAX ) = CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);

		PRINT @errorDetails;
		THROW 51000, @errorDetails, 1;
		
		-- Test XACT_STATE:
		-- If  1, the transaction is committable.
		-- If -1, the transaction is uncommittable and should be rolled back.
		-- XACT_STATE = 0 means that there is no transaction and a commit or rollback operation would generate an error.

		-- Test whether the transaction is uncommittable.
		IF XACT_STATE( ) = -1
			BEGIN
				--The transaction is in an uncommittable state. Rolling back transaction
				ROLLBACK TRANSACTION;
			END;

		-- Test whether the transaction is committable.
		IF XACT_STATE( ) = 1
			BEGIN
				--The transaction is committable. Committing transaction
				COMMIT TRANSACTION;
			END;
	END CATCH;
END;
GO
