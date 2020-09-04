SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Fact StudentDiscipline
----------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentDiscipline_PopulateStaging] 
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

		BEGIN TRANSACTION;   
		SELECT 1;
		/*
		TRUNCATE TABLE Staging.StudentAttendanceByDay
		INSERT INTO Staging.StudentAttendanceByDay
		(
		    _sourceKey,
		    StudentKey,
		    TimeKey,
		    SchoolKey,
		    AttendanceEventCategoryKey,
		    AttendanceEventReason,
		    ModifiedDate,
		    _sourceStudentKey,
		    _sourceTimeKey,
		    _sourceSchoolKey,
		    _sourceAttendanceEventCategoryKey
		)
		
		
        --declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT DISTINCT 
			   CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),c.CourseCode)) AS [_sourceKey],
			   c.CourseCode,
			   c.CourseTitle,
			   c.CourseDescription,
			   COALESCE(clct.CodeValue,'N/A') AS [CourseLevelCharacteristicTypeDescriptor_CodeValue],
			   COALESCE(clct.[Description],'N/A') AS [CourseLevelCharacteristicTypeDescriptor_Descriptor],

			   COALESCE(ast.CodeValue,'N/A') AS [AcademicSubjectDescriptor_CodeValue],
			   COALESCE(ast.[Description],'N/A') AS [AcademicSubjectDescriptor_Descriptor],
			   COALESCE(c.HighSchoolCourseRequirement,0) AS [HighSchoolCourseRequirement_Indicator],

			   c.MinimumAvailableCredits,
			   c.MaximumAvailableCredits,
			   COALESCE(cgat.CodeValue,'N/A')  AS GPAApplicabilityType_CodeValue,
			   COALESCE(cgat.[Description],'N/A') AS GPAApplicabilityType_Description,
	   
			   'N/A' AS [SecondaryCourseLevelCharacteristicTypeDescriptor_CodeValue],
			   'N/A' AS [SecondaryCourseLevelCharacteristicTypeDescriptor_Description],
			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(c.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS CourseModifiedDate,

				--Making sure the first time, the ValidFrom is set to beginning of time 
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (c.LastModifiedDate)                                               
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
				END AS ValidFrom,
			   '12/31/9999' as ValidTo,
				1 AS IsCurrent
		--select *
		FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Course c --WHERE c.CourseCode = '094'
			 LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CourseLevelCharacteristic clc ON c.CourseCode = clc.CourseCode
			 LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CourseLevelCharacteristicType clct ON clc.CourseLevelCharacteristicTypeId = clct.CourseLevelCharacteristicTypeId
			 LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.AcademicSubjectType ast ON c.AcademicSubjectDescriptorId = ast.AcademicSubjectTypeId
			 LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CourseGPAApplicabilityType cgat ON c.CourseGPAApplicabilityTypeId = cgat.CourseGPAApplicabilityTypeId
		WHERE EXISTS (SELECT 1 
					  FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CourseOffering co 
					  WHERE c.CourseCode = co.CourseCode
						AND co.SchoolYear IN (2019,2020)) AND
			 (c.LastModifiedDate > @LastLoadDate AND c.LastModifiedDate <= @NewLoadDate)
			
		 */				
			
		

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

		
		PRINT CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);
		
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
