SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_DimDisciplineIncident_PopulateProduction]
@LineageKey INT,
@LastDateLoaded DATETIME
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
		 
		--empty row technique
		--fact table should not have null foreign keys references
		--this empty record will be used in those cases
		IF NOT EXISTS (SELECT 1 
		               FROM dbo.DimDisciplineIncident WHERE _sourceKey = '')
				BEGIN
				   INSERT INTO dbo.DimDisciplineIncident
				   (
				       _sourceKey,
				       SchoolKey,
				       ShortNameOfInstitution,
				       NameOfInstitution,
				       SchoolYear,
				       IncidentDate,
				       IncidentTime,
				       IncidentDescription,
				       BehaviorDescriptor_CodeValue,
				       BehaviorDescriptor_Description,
				       LocationDescriptor_CodeValue,
				       LocationDescriptor_Description,
				       DisciplineDescriptor_CodeValue,
				       DisciplineDescriptor_Description,
				       DisciplineDescriptor_ISS_Indicator,
				       DisciplineDescriptor_OSS_Indicator,
				       ReporterDescriptor_CodeValue,
				       ReporterDescriptor_Description,
				       IncidentReporterName,
				       ReportedToLawEnforcement_Indicator,
				       IncidentCost,
					   ValidFrom,
					   ValidTo,
					   IsCurrent,
					   IsLatest,
				       LineageKey
				   )
				   VALUES
				   (   N'',        -- _sourceKey - nvarchar(50)
				       -1,          -- SchoolKey - int
				       N'',        -- ShortNameOfInstitution - nvarchar(500)
				       N'',        -- NameOfInstitution - nvarchar(500)
				       -1,          -- SchoolYear - int
				       GETDATE(),  -- IncidentDate - date
				       '10:50:24', -- IncidentTime - time(7)
				       N'N/A',        -- IncidentDescription - nvarchar(max)
				       N'N/A',        -- BehaviorDescriptor_CodeValue - nvarchar(50)
				       N'N/A',        -- BehaviorDescriptor_Description - nvarchar(1024)
				       N'N/A',        -- LocationDescriptor_CodeValue - nvarchar(50)
				       N'N/A',        -- LocationDescriptor_Description - nvarchar(1024)
				       N'N/A',        -- DisciplineDescriptor_CodeValue - nvarchar(50)
				       N'N/A',        -- DisciplineDescriptor_Description - nvarchar(1024)
				       0,       -- DisciplineDescriptor_ISS_Indicator - bit
				       0,       -- DisciplineDescriptor_OSS_Indicator - bit
				       N'N/A',        -- ReporterDescriptor_CodeValue - nvarchar(50)
				       N'N/A',        -- ReporterDescriptor_Description - nvarchar(1024)
				       N'N/A',        -- IncidentReporterName - nvarchar(100)
				       0,       -- ReportedToLawEnforcement_Indicator - bit
				       0,       -- IncidentCost - money
				       '07/01/2015', -- ValidFrom - datetime
					   '9999-12-31', -- ValidTo - datetime
					   0,      -- IsCurrent - bit
					   1,      -- IsLatest - bit
					   -1      -- LineageKey - int
				       )
				  
				END
        --updating keys
		UPDATE t
		SET t.SchoolKey =  COALESCE(
									(SELECT TOP (1) ds.SchoolKey
									 FROM dbo.DimSchool ds
									 WHERE t._sourceSchoolKey = ds._sourceKey									
										AND t.ValidFrom >= ds.[ValidFrom]
										AND t.ValidFrom < ds.[ValidTo]
									ORDER BY ds.[ValidFrom] DESC),
									(SELECT ds.SchoolKey
									 FROM dbo.DimSchool ds
									 WHERE ds._sourceKey = '')
							      ) 
        FROM Staging.DisciplineIncident t;

		--updating school names
		UPDATE di
		SET [ShortNameOfInstitution] = ds.ShortNameOfInstitution,
		    [NameOfInstitution] = ds.NameOfInstitution
		FROM Staging.DisciplineIncident di
		     INNER JOIN dbo.DimSchool ds ON di.SchoolKey = ds.SchoolKey;

	     

		--staging table holds newer records. 
		--the matching prod records will be valid until the date in which the newest data change was identified		
		UPDATE prod
		SET prod.ValidTo = stage.ValidFrom,
		    prod.IsLatest = 0
		FROM 
			[dbo].[DimDisciplineIncident] AS prod
			INNER JOIN Staging.DisciplineIncident AS stage ON prod._sourceKey = stage._sourceKey
		WHERE prod.ValidTo = '12/31/9999'


		INSERT INTO dbo.DimDisciplineIncident
		(
		    _sourceKey,
		    SchoolKey,
		    ShortNameOfInstitution,
		    NameOfInstitution,
		    SchoolYear,
		    IncidentDate,
		    IncidentTime,
		    IncidentDescription,
		    BehaviorDescriptor_CodeValue,
		    BehaviorDescriptor_Description,
		    LocationDescriptor_CodeValue,
		    LocationDescriptor_Description,
		    DisciplineDescriptor_CodeValue,
		    DisciplineDescriptor_Description,
		    DisciplineDescriptor_ISS_Indicator,
		    DisciplineDescriptor_OSS_Indicator,
		    ReporterDescriptor_CodeValue,
		    ReporterDescriptor_Description,
		    IncidentReporterName,
		    ReportedToLawEnforcement_Indicator,
		    IncidentCost,
		    [ValidFrom],
		    [ValidTo],
		    [IsCurrent],
			[IsLatest],
			LineageKey
		)
		
		SELECT 
		    _sourceKey,
		    SchoolKey,
		    ShortNameOfInstitution,
		    NameOfInstitution,
		    SchoolYear,
		    IncidentDate,
		    IncidentTime,
		    IncidentDescription,
		    BehaviorDescriptor_CodeValue,
		    BehaviorDescriptor_Description,
		    LocationDescriptor_CodeValue,
		    LocationDescriptor_Description,
		    DisciplineDescriptor_CodeValue,
		    DisciplineDescriptor_Description,
		    DisciplineDescriptor_ISS_Indicator,
		    DisciplineDescriptor_OSS_Indicator,
		    ReporterDescriptor_CodeValue,
		    ReporterDescriptor_Description,
		    IncidentReporterName,
		    ReportedToLawEnforcement_Indicator,
		    IncidentCost,
			[ValidFrom],
		    [ValidTo],
		    [IsCurrent],
			1 AS [IsLatest],
		    @LineageKey
		FROM Staging.DisciplineIncident

		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE [LineageKey] = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.DimDisciplineIncident';

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
