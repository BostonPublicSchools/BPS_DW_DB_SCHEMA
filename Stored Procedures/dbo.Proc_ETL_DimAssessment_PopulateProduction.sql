SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_DimAssessment_PopulateProduction]
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
		               FROM dbo.DimAssessment WHERE _sourceKey = '')
				BEGIN
				   INSERT INTO dbo.DimAssessment
				   (
				       _sourceKey,
				       AssessmentCategoryDescriptor_CodeValue,
				       AssessmentCategoryDescriptor_Description,
				       AssessmentFamilyTitle,
				       AdaptiveAssessment_Indicator,
				       AssessmentIdentifier,
				       AssessmentTitle,
				       ReportingMethodDescriptor_CodeValue,
				       ReportingMethodDescriptor_Description,
				       ResultDatatypeTypeDescriptor_CodeValue,
				       ResultDatatypeTypeDescriptor_Description,
				       AssessmentScore_Indicator,
				       AssessmentPerformanceLevel_Indicator,
				       ObjectiveAssessmentScore_Indicator,
				       ObjectiveAssessmentPerformanceLevel_Indicator,
				       ValidFrom,
				       ValidTo,
				       IsCurrent,
					   IsLatest,
				       LineageKey
				   )
				   VALUES
				   (   N'',       -- _sourceKey - nvarchar(2000)
				       N'N/A',       -- AssessmentCategoryDescriptor_CodeValue - nvarchar(50)
				       N'N/A',       -- AssessmentCategoryDescriptor_Description - nvarchar(1024)
				       N'N/A',       -- AssessmentFamilyTitle - nvarchar(100)
				       0,      -- AdaptiveAssessment_Indicator - bit
				       N'N/A',       -- AssessmentIdentifier - nvarchar(60)
				       N'N/A',       -- AssessmentTitle - nvarchar(500)
				       N'N/A',       -- ReportingMethodDescriptor_CodeValue - nvarchar(50)
				       N'N/A',       -- ReportingMethodDescriptor_Description - nvarchar(1024)
				       N'N/A',       -- ResultDatatypeTypeDescriptor_CodeValue - nvarchar(50)
				       N'N/A',       -- ResultDatatypeTypeDescriptor_Description - nvarchar(1024)
				       0,      -- AssessmentScore_Indicator - bit
				       0,      -- AssessmentPerformanceLevel_Indicator - bit
				       0,      -- ObjectiveAssessmentScore_Indicator - bit
				       0,      -- ObjectiveAssessmentPerformanceLevel_Indicator - bit
				       '07/01/2015', -- ValidFrom - datetime
					   '9999-12-31', -- ValidTo - datetime
					   0,      -- IsCurrent - bit
					   1,      -- IsLatest - bit
					   -1          -- LineageKey - int
				       )
				   
				  
				END

		--staging table holds newer records. 
		--the matching prod records will be valid until the date in which the newest data change was identified		
		UPDATE prod
		SET prod.ValidTo = stage.ValidFrom,
		    prod.IsLatest = 0
		FROM 
			[dbo].DimAssessment AS prod
			INNER JOIN Staging.Assessment AS stage ON prod._sourceKey = stage._sourceKey
		WHERE prod.ValidTo = '12/31/9999'


		INSERT INTO dbo.DimAssessment
		(
		    _sourceKey,
		    AssessmentCategoryDescriptor_CodeValue,
		    AssessmentCategoryDescriptor_Description,
		    AssessmentFamilyTitle,
		    AdaptiveAssessment_Indicator,
		    AssessmentIdentifier,
		    AssessmentTitle,
		    ReportingMethodDescriptor_CodeValue,
		    ReportingMethodDescriptor_Description,
		    ResultDatatypeTypeDescriptor_CodeValue,
		    ResultDatatypeTypeDescriptor_Description,
		    AssessmentScore_Indicator,
		    AssessmentPerformanceLevel_Indicator,
		    ObjectiveAssessmentScore_Indicator,
		    ObjectiveAssessmentPerformanceLevel_Indicator,
		    ValidFrom,
		    ValidTo,
		    IsCurrent,
			IsLatest,
		    LineageKey
		)
		
		
		SELECT 
		    _sourceKey,
		    AssessmentCategoryDescriptor_CodeValue,
		    AssessmentCategoryDescriptor_Description,
		    AssessmentFamilyTitle,
		    AdaptiveAssessment_Indicator,
		    AssessmentIdentifier,
		    AssessmentTitle,
		    ReportingMethodDescriptor_CodeValue,
		    ReportingMethodDescriptor_Description,
		    ResultDatatypeTypeDescriptor_CodeValue,
		    ResultDatatypeTypeDescriptor_Description,
		    AssessmentScore_Indicator,
		    AssessmentPerformanceLevel_Indicator,
		    ObjectiveAssessmentScore_Indicator,
		    ObjectiveAssessmentPerformanceLevel_Indicator,
		    ValidFrom,
		    ValidTo,
		    IsCurrent,
			1 AS IsLatest,
		    @LineageKey
		FROM Staging.Assessment

		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE LineageKey = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.DimAssessment';

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
