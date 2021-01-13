SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Dim Assessment
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimAssessment_PopulateStaging]
@LastLoadDate datetime,
@NewLoadDate datetime
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

			
		DECLARE @Assessment TABLE
		(   
			AssessmentCategoryDescriptor_CodeValue NVARCHAR(50) NOT NULL,    
			AssessmentCategoryDescriptor_Description NVARCHAR(1024) NOT NULL,    
			AssessmentFamilyTitle NVARCHAR(100) NULL,    	
			AdaptiveAssessment_Indicator bit NOT NULL, 
			AssessmentIdentifier NVARCHAR(60) NOT NULL,   
			ObjectiveAssessmentIdentificationCode NVARCHAR(60) NOT NULL,   
			AssessmentTitle NVARCHAR(500) NOT NULL,

			ReportingMethodDescriptor_CodeValue NVARCHAR(50) NOT NULL,   
			ReportingMethodDescriptor_Description NVARCHAR(1024) NOT NULL,   
	
			ResultDatatypeTypeDescriptor_CodeValue  NVARCHAR(50) NOT NULL,   
			ResultDatatypeTypeDescriptor_Description NVARCHAR(1024) NOT NULL,   


			AssessmentScore_Indicator  BIT NOT NULL,
			AssessmentPerformanceLevel_Indicator  BIT NOT NULL,

			ObjectiveAssessmentScore_Indicator  BIT NOT NULL,
			ObjectiveAssessmentPerformanceLevel_Indicator  BIT NOT NULL,

			AssessmentModifiedDate [datetime] NOT NULL,

			ValidFrom DATETIME NOT NULL, 
			ValidTo DATETIME NOT NULL, 
			IsCurrent BIT NOT NULL,
			IsLegacy BIT NOT NULL

		);



		--Assessmnent
		INSERT INTO @Assessment
		(
			AssessmentCategoryDescriptor_CodeValue,
			AssessmentCategoryDescriptor_Description,
			AssessmentFamilyTitle,
			AdaptiveAssessment_Indicator,
			AssessmentIdentifier,
			ObjectiveAssessmentIdentificationCode,
			AssessmentTitle,

			ReportingMethodDescriptor_CodeValue,   
			ReportingMethodDescriptor_Description,   
	
			ResultDatatypeTypeDescriptor_CodeValue,   
			ResultDatatypeTypeDescriptor_Description,   


			AssessmentScore_Indicator,
			AssessmentPerformanceLevel_Indicator,

			ObjectiveAssessmentScore_Indicator,
			ObjectiveAssessmentPerformanceLevel_Indicator,

			AssessmentModifiedDate,
			ValidFrom, 
			ValidTo, 
			IsCurrent,
			IsLegacy
		)

		SELECT DISTINCT 
			   a_d.CodeValue AS [AssessmentCategoryDescriptor_CodeValue],
			   a_d.[Description] AS [AssessmentCategoryDescriptor_Description],
			   a.AssessmentFamily AS [AssessmentFamilyTitle],
			   ISNULL(a.AdaptiveAssessment,0) AS [AdaptiveAssessment_Indicator], 
			   a.AssessmentIdentifier,
			   'N/A' AS ObjectiveAssessmentIdentificationCode,
			   a.AssessmentTitle,	   

			   as_arm_d.CodeValue AS ReportingMethodDescriptor_CodeValue,
			   as_arm_d.[Description] AS ReportingMethodDescriptor_Description,
			   asdt_d.CodeValue AS ResultDatatypeTypeDescriptor_CodeValue,
			   asdt_d.[Description] AS ResultDatatypeTypeDescriptor_Description,

			   1 AS AssessmentScore_Indicator,
			   0 AS AssessmentPerformanceLevel_Indicator,
  
			   0 AS ObjectiveAssessmentScore_Indicator,
			   0 AS ObjectiveAssessmentPerformanceLevel_Indicator,
			   
			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(a.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS AssessmentModifiedDate,
			   --Making sure the first time, the ValidFrom is set to beginning of time 
			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (a.LastModifiedDate)                             
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
			   END AS ValidFrom,
			   '12/31/9999' AS ValidTo,
			   1 AS IsCurrent,
			   0 AS IsLegacy
		--select *
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Assessment a 
			 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor a_d ON a.AssessmentCategoryDescriptorId = a_d.DescriptorId
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.AssessmentScore a_s ON a.AssessmentIdentifier = a_s.AssessmentIdentifier 
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor as_arm_d ON a_s.AssessmentReportingMethodDescriptorId = as_arm_d.DescriptorId
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor asdt_d ON a_s.ResultDatatypeTypeDescriptorId = asdt_d.DescriptorId
		WHERE CHARINDEX('MCAS',a.AssessmentIdentifier,1) = 1 
		      AND (a.LastModifiedDate > @LastLoadDate AND a.LastModifiedDate <= @NewLoadDate)
		Union
		SELECT DISTINCT 
			   a_d.CodeValue AS [AssessmentCategoryDescriptor_CodeValue],
			   a_d.[Description] AS [AssessmentCategoryDescriptor_Description],
			   a.AssessmentFamily AS [AssessmentFamilyTitle],
			   ISNULL(a.AdaptiveAssessment,0) AS [AdaptiveAssessment_Indicator], 
			   a.AssessmentIdentifier,
				'N/A' AS ObjectiveAssessmentIdentificationCode,
			   a.AssessmentTitle,	   
	   
			   a_pl_arm_d.CodeValue AS ReportingMethodDescriptor_CodeValue,
			   a_pl_arm_d.[Description] AS ReportingMethodDescriptor_Description,
			   a_pl_dt_d.CodeValue AS ResultDatatypeTypeDescriptor_CodeValue,
			   a_pl_dt_d.[Description] AS ResultDatatypeTypeDescriptor_Description,

			   0 AS AssessmentScore_Indicator,
			   1 AS AssessmentPerformanceLevel_Indicator,
  
			   0 AS ObjectiveAssessmentScore_Indicator,
			   0 AS ObjectiveAssessmentPerformanceLevel_Indicator,
			   
			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(a.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS AssessmentModifiedDate,
			   ---Making sure the first time, the ValidFrom is set to beginning of time 
			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (a.LastModifiedDate)                             
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
			   END AS ValidFrom,
			   '12/31/9999' AS ValidTo,
			   1 AS IsCurrent,
			   0 AS IsLegacy
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Assessment a 
			 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor a_d ON a.AssessmentCategoryDescriptorId = a_d.DescriptorId
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.AssessmentPerformanceLevel a_pl ON a.AssessmentIdentifier = a_pl.AssessmentIdentifier 
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor a_pl_d ON a_pl.PerformanceLevelDescriptorId = a_pl_d.DescriptorId
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor a_pl_arm_d ON a_pl.AssessmentReportingMethodDescriptorId = a_pl_arm_d.DescriptorId
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor a_pl_dt_d ON a_pl.ResultDatatypeTypeDescriptorId = a_pl_dt_d.DescriptorId
		WHERE CHARINDEX('MCAS',a.AssessmentIdentifier,1) = 1 
		      AND (a.LastModifiedDate > @LastLoadDate AND a.LastModifiedDate <= @NewLoadDate)
		--ORDER BY a.AssessmentIdentifier, ObjectiveAssessmentIdentificationCode, ReportingMethodDescriptor_CodeValue

		
			
							
			
		--loading legacy data if it has not been loaded.
		--load types are ignored as this data will only be loaded once.
		IF NOT EXISTS(SELECT 1 
		              FROM dbo.DimAssessment 
					  WHERE CHARINDEX('LegacyDW',_sourceKey,1) > 0)
			BEGIN
			   ;WITH UnpivotedScores AS 
				(
					SELECT testid,schyear,testtime,studentno,adminyear,grade, scoretype, scorevalue, CASE WHEN a.scoretype IN ('Proficiency level','Proficiency level 2') THEN 1 ELSE 0 END AS isperflevel
					--INTO [Raw_LegacyDW].[MCASAssessmentScores]
					FROM (  
							 --ensuring all score columns have the same data type to avoid conflicts with unpivot
							 SELECT testid,schyear,testtime,studentno,adminyear,grade,teststatus ,
								  CAST(rawscore AS NVARCHAR(MAX)) AS [Raw score],
								  CAST(scaledscore AS NVARCHAR(MAX)) AS [Scale score],
								  CAST(perflevel AS NVARCHAR(MAX)) AS  [Proficiency level],
								  CAST(sgp AS NVARCHAR(MAX)) AS [Percentile rank],
								  CAST(cpi AS NVARCHAR(MAX)) AS [Composite Performance Index],
								  CAST(perf2 AS NVARCHAR(MAX)) AS [Proficiency level 2]
     
							FROM [BPSGranary02].[RAEDatabase].[dbo].[mcasitems] 
							WHERE schyear in (2015,2016,2017) ) scores
					UNPIVOT
					(
					   scorevalue
					   FOR scoretype IN ([Raw score],[Scale score],[Proficiency level],[Percentile rank],[Composite Performance Index],[Proficiency level 2])
					) AS a
				)

			   INSERT INTO @Assessment
				(
					AssessmentCategoryDescriptor_CodeValue,
					AssessmentCategoryDescriptor_Description,
					AssessmentFamilyTitle,
					AdaptiveAssessment_Indicator,
					AssessmentIdentifier,
					ObjectiveAssessmentIdentificationCode,
					AssessmentTitle,

					ReportingMethodDescriptor_CodeValue,   
					ReportingMethodDescriptor_Description,   
	
					ResultDatatypeTypeDescriptor_CodeValue,   
					ResultDatatypeTypeDescriptor_Description,   


					AssessmentScore_Indicator,
					AssessmentPerformanceLevel_Indicator,

					ObjectiveAssessmentScore_Indicator,
					ObjectiveAssessmentPerformanceLevel_Indicator,

					AssessmentModifiedDate,
					ValidFrom, 
					ValidTo, 
					IsCurrent,
			        IsLegacy
				)

				SELECT DISTINCT 
					   'State assessment' AS [AssessmentCategoryDescriptor_CodeValue],
					   'State assessment' AS [AssessmentCategoryDescriptor_Description],
					   NULL AS [AssessmentFamilyTitle],
					   0 AS [AdaptiveAssessment_Indicator], 
					   testid AS AssessmentIdentifier,
					   'N/A' AS ObjectiveAssessmentIdentificationCode,
					   testid AS AssessmentTitle,	   

					   scoretype AS ReportingMethodDescriptor_CodeValue,
					   scoretype AS ReportingMethodDescriptor_Description,
					   CASE WHEN isperflevel = 1 THEN 'Level' ELSE 'Integer' end   AS ResultDatatypeTypeDescriptor_CodeValue,
					   CASE WHEN isperflevel = 1 THEN 'Level' ELSE 'Integer' end AS ResultDatatypeTypeDescriptor_Description,
	   
					   CASE WHEN isperflevel = 1 THEN 0 ELSE 1 end AS AssessmentScore_Indicator,
					   isperflevel AS AssessmentPerformanceLevel_Indicator,
  
					   0 AS ObjectiveAssessmentScore_Indicator,
					   0 AS ObjectiveAssessmentPerformanceLevel_Indicator,

					   '07/01/2015' AS AssessmentModifiedDate,
					   '07/01/2015' AS ValidFrom,
					   GETDATE() AS ValidTo,
					   0 AS IsCurrent,
					   1 AS IsLegacy
				FROM UnpivotedScores
			END

		TRUNCATE TABLE Staging.Assessment
		INSERT INTO Staging.Assessment
				   ([_sourceKey]
				   ,[AssessmentCategoryDescriptor_CodeValue]
				   ,[AssessmentCategoryDescriptor_Description]
				   ,[AssessmentFamilyTitle]
				   ,[AdaptiveAssessment_Indicator]
				   ,[AssessmentIdentifier]
				   ,[AssessmentTitle]

				   ,[ReportingMethodDescriptor_CodeValue]
				   ,[ReportingMethodDescriptor_Description]

				   ,[ResultDatatypeTypeDescriptor_CodeValue]
				   ,[ResultDatatypeTypeDescriptor_Description]

				   ,[AssessmentScore_Indicator]
				   ,[AssessmentPerformanceLevel_Indicator]

				   ,[ObjectiveAssessmentScore_Indicator]
				   ,[ObjectiveAssessmentPerformanceLevel_Indicator]
				   
				   ,AssessmentModifiedDate

				   ,[ValidFrom]
				   ,[ValidTo]
				   ,[IsCurrent])
        --declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT DISTINCT 
				CONCAT_WS('|',CASE WHEN IsLegacy = 0 THEN 'Ed-Fi' ELSE 'LegacyDW' END , Convert(NVARCHAR(MAX),AssessmentIdentifier)  + '|' + Convert(NVARCHAR(MAX),ObjectiveAssessmentIdentificationCode) + '|' + Convert(NVARCHAR(MAX),ReportingMethodDescriptor_CodeValue)) AS [_sourceKey]
				
				,[AssessmentCategoryDescriptor_CodeValue]
			    ,[AssessmentCategoryDescriptor_Description]
			    ,[AssessmentFamilyTitle]
			    ,[AdaptiveAssessment_Indicator]
			    ,[AssessmentIdentifier]
			    ,[AssessmentTitle]
			    
			    ,[ReportingMethodDescriptor_CodeValue]
			    ,[ReportingMethodDescriptor_Description]
			    
			    ,[ResultDatatypeTypeDescriptor_CodeValue]
			    ,[ResultDatatypeTypeDescriptor_Description]
			    
			    ,[AssessmentScore_Indicator]
			    ,[AssessmentPerformanceLevel_Indicator]
			    
			    ,[ObjectiveAssessmentScore_Indicator]
			    ,[ObjectiveAssessmentPerformanceLevel_Indicator]
	  		    ,AssessmentModifiedDate
			    ,ValidFrom
			    ,ValidTo
			    ,IsCurrent
		FROM @Assessment;			    

				
	END TRY
	BEGIN CATCH
		
		--constructing exception details
		DECLARE
		   @errorMessage nvarchar( MAX ) = ERROR_MESSAGE( );		
     
		DECLARE
		   @errorDetails nvarchar( MAX ) = CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);

		PRINT @errorDetails;
		THROW 51000, @errorDetails, 1;

		
		PRINT CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);
		
		-- Test XACT_STATE:
		-- If  1, the transaction is committable.
		-- If -1, the transaction is uncommittable and should be rolled back.
		-- XACT_STATE = 0 means that there is no transaction and a commit or rollback operation would generate an error.

		-- Test whether the transaction is uncommittable.
		
	END CATCH;
END;
GO
