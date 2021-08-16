SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Fact StudentCourseTranscript
----------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentCourseTranscript_PopulateStaging] 
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
		TRUNCATE TABLE Staging.StudentCourseTranscript	
		INSERT INTO Staging.StudentCourseTranscript
		(
		    _sourceKey,
		    StudentKey,
		    TimeKey,
		    CourseKey,
		    SchoolKey,
		    EarnedCredits,
		    PossibleCredits,
		    FinalLetterGradeEarned,
		    FinalNumericGradeEarned,
		    ModifiedDate,
		    _sourceStudentKey,
		    _sourceSchoolYear,
			_sourceTerm,
		    _sourceCourseKey,
		    _sourceSchoolKey
		)
		
		SELECT DISTINCT
			   CONCAT_WS('|',s.StudentUniqueId,Convert(NVARCHAR(MAX),ct.SchoolYear),Convert(NVARCHAR(MAX),ct.EducationOrganizationId),Convert(NVARCHAR(MAX),ct.CourseCode),td.CodeValue) AS _sourceKey,
			   NULL AS StudentKey,
			   NULL AS TimeKey,	  
			   NULL AS CourseKey,
			   NULL AS SchoolKey,  
			   ct.EarnedCredits,
			   ct.AttemptedCredits,
			   ct.FinalLetterGradeEarned,
			   ct.FinalNumericGradeEarned,			   
			   ct.LastModifiedDate AS ModifiedDate,
			   CONCAT_WS('|','Ed-Fi',s.StudentUniqueId) AS _sourceStudentKey,
		       ct.SchoolYear AS _sourceSchoolYear,		          
			   td.CodeValue AS _sourceTerm,		          
			   CONCAT_WS('|','Ed-Fi',ct.CourseCode)  AS _sourceCourseKey,
			   CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),ct.EducationOrganizationId))  AS _sourceSchoolKey
		--select *  
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.CourseTranscript ct		    
		    INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student s ON ct.StudentUSI = s.StudentUSI
			INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor td ON ct.TermDescriptorId = td.DescriptorId
		WHERE  			
			  ct.SchoolYear >= 2019			
			 AND  (
					   (ct.LastModifiedDate > @LastLoadDate  AND ct.LastModifiedDate <= @NewLoadDate)			     
				  )
				  
		SELECT * FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.EducationOrganization eo
		SELECT * FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.School eo
		SELECT * FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.LocalEducationAgency 
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
