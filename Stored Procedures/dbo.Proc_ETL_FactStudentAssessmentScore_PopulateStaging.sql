SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Fact StudentAssessmentScore
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentAssessmentScore_PopulateStaging]
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
    
		--DECLARE @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate();
		--select * from Staging.StudentAssessmentScore
		TRUNCATE TABLE Staging.StudentAssessmentScore
			
		INSERT INTO Staging.StudentAssessmentScore
		(
		    _sourceKey,
		    StudentKey,
		    TimeKey,
		    AssessmentKey,
		    ScoreResult,
		    IntegerScoreResult,
		    DecimalScoreResult,
		    LiteralScoreResult,
		    ModifiedDate,
		    _sourceStudentKey,
		    _sourceTimeKey,
		    _sourceAssessmentKey
		)
		
		
		SELECT   DISTINCT 
			      CONCAT_WS('|',s.StudentUniqueId, CONVERT(NVARCHAR, sa.AdministrationDate, 112), sa.AssessmentIdentifier,'N/A',armt_d.CodeValue) AS _sourceKey,				  
				  NULL AS StudentKey,
				  NULL AS TimeKey,	  
				  NULL AS AssessmentKey,
				  sas.Result AS [SoreResult],
				  CASE when ascr_dt_d.CodeValue in ('Integer') AND TRY_CAST(sas.Result AS INTEGER) IS NOT NULL AND sas.Result <> '-' THEN sas.Result ELSE NULL END AS IntegerScoreResult,
				  CASE when ascr_dt_d.CodeValue in ('Decimal','Percentage','Percentile')  AND TRY_CAST(sas.Result AS FLOAT)  IS NOT NULL THEN sas.Result ELSE NULL END AS DecimalScoreResult,
				  CASE when ascr_dt_d.CodeValue not in ('Integer','Decimal','Percentage','Percentile') THEN sas.Result ELSE NULL END AS LiteralScoreResult,
				  CONVERT(DATE ,sa.AdministrationDate) AS ModifiedDate ,
				  CONCAT_WS('|','Ed-Fi',s.StudentUniqueId) AS  _sourceStudentKey,
				  CONVERT(DATE ,sa.AdministrationDate) AS  _sourceTimeKey,
				  CONCAT_WS('|','Ed-Fi',sa.AssessmentIdentifier,'N/A',armt_d.CodeValue) AS  _sourceAssessmentKey
			--select top 1 'Ed-Fi|' + Convert(NVARCHAR(MAX),sa.AssessmentIdentifier)  + '|N/A|' + Convert(NVARCHAR(MAX),armt.CodeValue), sa.AdministrationDate,*  
			FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].Student s 
      
				--student assessment
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].StudentAssessment sa on sa.StudentUSI = s.StudentUSI
      
				--student assessment score results
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].StudentAssessmentScoreResult sas on sa.StudentAssessmentIdentifier = sas.StudentAssessmentIdentifier
																and sa.AssessmentIdentifier = sas.AssessmentIdentifier
																and sa.StudentUSI = sas.StudentUSI
				--assessment 
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].Assessment a on sa.AssessmentIdentifier = a.AssessmentIdentifier 

				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].AssessmentScore ascr on sas.AssessmentIdentifier = ascr.AssessmentIdentifier 
													and sas.AssessmentReportingMethodDescriptorId = ascr.AssessmentReportingMethodDescriptorId
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].Descriptor armt_d on ascr.AssessmentReportingMethodDescriptorId = armt_d.DescriptorId

				INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor ascr_dt_d ON ascr.ResultDatatypeTypeDescriptorId = ascr_dt_d.DescriptorId	
				
			WHERE CHARINDEX('MCAS',a.AssessmentIdentifier,1) = 1 
				 AND sa.AdministrationDate >= '07/01/2018'		
				 AND sa.AdministrationDate <= GETDATE()
				 AND  (
					   (sa.LastModifiedDate > @LastLoadDate  AND sa.LastModifiedDate <= @NewLoadDate)			     
					  )

		UNION ALL
		SELECT   DISTINCT 
			      CONCAT_WS('|',s.StudentUniqueId, CONVERT(NVARCHAR, sa.AdministrationDate, 112), sa.AssessmentIdentifier,'N/A',apl_armd_d.CodeValue) AS _sourceKey,				  
				  NULL AS StudentKey,
				  NULL AS TimeKey,	  
				  NULL AS AssessmentKey,
				  apl_ld.CodeValue AS [SoreResult],
				  NULL AS IntegerScoreResult,
				  NULL AS DecimalScoreResult,
				  apl_ld.CodeValue AS LiteralScoreResult,	  
				  CONVERT(DATE ,sa.AdministrationDate) AS ModifiedDate ,
				  CONCAT_WS('|','Ed-Fi',CONVERT(NVARCHAR(MAX),s.StudentUSI)) AS  _sourceStudentKey,
				  CONVERT(DATE ,sa.AdministrationDate) AS  _sourceTimeKey,
				  CONCAT_WS('|','Ed-Fi',sa.AssessmentIdentifier,'N/A',apl_armd_d.CodeValue) AS  _sourceAssessmentKey
			--select top 100 *  
			FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].Student s 
      
				--student assessment
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].StudentAssessment sa on sa.StudentUSI = s.StudentUSI 
	
				inner  join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].StudentAssessmentPerformanceLevel sapl on sa.StudentAssessmentIdentifier = sapl.StudentAssessmentIdentifier
																		 and sa.AssessmentIdentifier = sapl.AssessmentIdentifier
															             and sa.StudentUSI = sapl.StudentUSI
    
				--assessment 
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].Assessment a on sa.AssessmentIdentifier = a.AssessmentIdentifier 

				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].[AssessmentPerformanceLevel] apl on sa.AssessmentIdentifier = apl.AssessmentIdentifier 
																 and sapl.AssessmentReportingMethodDescriptorId = apl.AssessmentReportingMethodDescriptorId
																 and sapl.PerformanceLevelDescriptorId = apl.PerformanceLevelDescriptorId
    
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].Descriptor apl_armd_d on apl.AssessmentReportingMethodDescriptorId = apl_armd_d.DescriptorId
				inner join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].Descriptor apl_ld on apl.PerformanceLevelDescriptorId = apl_ld.DescriptorId 

			WHERE CHARINDEX('MCAS',a.AssessmentIdentifier,1) = 1           
				  AND sa.AdministrationDate >= '07/18/2018'
				  AND sa.AdministrationDate <= GETDATE()
				  AND  (
					     (sa.LastModifiedDate > @LastLoadDate  AND sa.LastModifiedDate <= @NewLoadDate)			     
					   );
		 
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
		
		
	END CATCH;
END;
GO
