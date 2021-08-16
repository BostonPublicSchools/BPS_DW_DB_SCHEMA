SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Dim StudentSection
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimStudentSection_PopulateStaging]
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

		--declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		TRUNCATE TABLE Staging.StudentSection
		


		INSERT INTO Staging.StudentSection
		(
		    _sourceKey,
		    StudentKey,
		    SchoolKey,
		    CourseKey,
		    StaffKey,
		    StudentSectionBeginDate,
		    StudentSectionEndDate,
		    SchoolYear,
		    ModifiedDate,

			[_sourceStudentKey],
			[_sourceSchoolKey],
			[_sourceCourseKey],
			[_sourceStaffKey],

		    ValidFrom,
		    ValidTo,
		    IsCurrent
		)
			
		--declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT 
		    CONCAT_WS('|','Ed-Fi',s.StudentUniqueId,ssa.SchoolId,ssa.LocalCourseCode,staff.StaffUniqueId,ssa.SchoolYear,ssa.SectionIdentifier,ssa.SessionName,CONVERT(NVARCHAR, ssa.BeginDate, 112) ) [_sourceKey],			
			NULL AS StudentKey,
			NULL AS SchoolKey,
			NULL AS CourseKey,
			NULL AS StaffKey,	        
	        ssa.BeginDate,
			ssa.EndDate,
			ssa.SchoolYear,

			CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(ssa.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS LastModifiedDate,

			CONCAT_WS('|', 'Ed-Fi', s.StudentUniqueId)  AS [_sourceStudentKey],
			CONCAT_WS('|', 'Ed-Fi', ssa.SchoolId)  AS [_sourceSchoolKey],
			CONCAT_WS('|', 'Ed-Fi', co.CourseCode) AS [_sourceCourseKey],
			CONCAT_WS('|', 'Ed-Fi', staff.StaffUniqueId) AS [_sourceStaffKey],

			CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				        (SELECT MAX(t) FROM
                            (VALUES
                            (ssa.LastModifiedDate)                             
                            ) AS [MaxLastModifiedDate](t)
                        )
				ELSE 
					    '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
			END AS ValidFrom,
			'12/31/9999' AS ValidTo,
			1 AS IsCurrent	
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student s
		         INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSectionAssociation ssa ON s.StudentUSI = ssa.StudentUSI
				 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSectionAssociation staff_sa ON ssa.SchoolId = staff_sa.SchoolId
																											  AND ssa.LocalCourseCode = staff_sa.LocalCourseCode
																											  AND ssa.SchoolYear = staff_sa.SchoolYear
																											  AND ssa.SectionIdentifier = staff_sa.SectionIdentifier
																											  AND ssa.SessionName = staff_sa.SessionName
				 INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff staff ON staff_sa.StaffUSI = staff.StaffUSI
				 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.CourseOffering co ON ssa.SchoolId = co.SchoolId
				                                                                       AND ssa.LocalCourseCode = co.LocalCourseCode
																					   AND ssa.SchoolYear = co.SchoolYear
																					   AND ssa.SessionName = co.SessionName	
		WHERE ssa.SchoolYear >= 2019
				AND (
			  		 (ssa.LastModifiedDate > @LastLoadDate AND ssa.LastModifiedDate <= @NewLoadDate)
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
