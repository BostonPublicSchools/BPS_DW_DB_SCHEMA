SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--Fact StudentCourseGrades
----------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentCourseGrade_PopulateStaging] 
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
		--select * from Staging.StudentCourseTranscript
		TRUNCATE TABLE Staging.StudentCourseGrade	
		INSERT INTO Staging.StudentCourseGrade
		(
		    _sourceKey,
		    TimeKey,		    
		    GradingPeriodKey,
		    StudentSectionKey,
		    LetterGradeEarned,
		    NumericGradeEarned,
		    ModifiedDate,		    
		    _sourceGradingPeriodey,
		    _sourceStudentSectionKey
		)
		
		SELECT DISTINCT
			   CONCAT_WS('|','Ed-Fi',s.StudentUSI,g.SchoolId,g.LocalCourseCode,g.SchoolYear,g.UniqueSectionCode,td.CodeValue,CONVERT(NVARCHAR, g.BeginDate, 112),gp.GradingPeriodDescriptorId,CONVERT(NVARCHAR, gp.BeginDate, 112)) AS _sourceKey,
			   NULL AS TimeKey,	  			   
			   NULL AS GradingPeriodKey,
			   NULL AS StudentSectionKey,
			   g.LetterGradeEarned,
			   g.NumericGradeEarned,
			   g.LastModifiedDate AS ModifiedDate,			   			   
			   CONCAT_WS('|','Ed-Fi',gp.GradingPeriodDescriptorId,gp.SchoolId,CONVERT(NVARCHAR, gp.BeginDate, 112)) AS _sourceGradingPeriodKey,		          
			   CONCAT_WS('|','Ed-Fi',s.StudentUSI,g.SchoolId,g.LocalCourseCode,g.SchoolYear,g.UniqueSectionCode,td.CodeValue, CONVERT(NVARCHAR, g.BeginDate, 112) ) AS _sourceStudentSectionKey
		
		FROM
			[EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Grade AS g
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Student AS s ON	g.StudentUSI = s.StudentUSI
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.GradeType AS gt ON g.GradeTypeId = gt.GradeTypeId
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.GradingPeriod AS gp ON g.GradingPeriodDescriptorId = gp.GradingPeriodDescriptorId
				                                                                         AND g.SequenceOfCourse = gp.PeriodSequence
																						 AND g.SchoolId = gp.SchoolId
																						 AND g.SchoolYear = dbo.Func_ETL_GetSchoolYear(gp.BeginDate) 
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor AS td ON g.TermDescriptorId = td.DescriptorId
		WHERE gt.CodeValue = 'Grading Period'
		      AND g.SchoolYear >= 2019 
		      AND (
			  	    (g.LastModifiedDate > @LastLoadDate AND g.LastModifiedDate <= @NewLoadDate)
				  )
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

	END CATCH;
END; 
GO
