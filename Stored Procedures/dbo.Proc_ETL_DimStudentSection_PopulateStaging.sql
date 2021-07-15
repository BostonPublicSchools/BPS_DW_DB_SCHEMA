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
		SELECT   DISTINCT 
            ssa.StudentUSI,
            ssa.SchoolId, 
			ssa.LocalCourseCode,
			ssa.SchoolYear,
			staff_sa.StaffUSI,
			ssa.UniqueSectionCode,
			ssa.TermDescriptorId,
			ssa.BeginDate,
			ssa.EndDate,
			CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(ssa.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS LastModifiedDate,
			--Making sure the first time, the ValidFrom is set to beginning of time 
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
			INTO #studentSectionAssociation
		FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentSectionAssociation ssa
				 INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StaffSectionAssociation staff_sa ON ssa.SchoolId = staff_sa.SchoolId
																											  AND ssa.LocalCourseCode = staff_sa.LocalCourseCode
																											  AND ssa.SchoolYear = staff_sa.SchoolYear
																											  AND ssa.UniqueSectionCode = staff_sa.UniqueSectionCode
																											  AND ssa.TermDescriptorId = staff_sa.TermDescriptorId
		WHERE ssa.SchoolYear >= 2019
				AND (
			  					(ssa.LastModifiedDate > @LastLoadDate AND ssa.LastModifiedDate <= @NewLoadDate)
   					)


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
		    ValidFrom,
		    ValidTo,
		    IsCurrent
		)
			
		--declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT 
		    CONCAT_WS('|','Ed-Fi',ssa.StudentUSI,ssa.SchoolId,ssa.LocalCourseCode,ssa.SchoolYear,ssa.UniqueSectionCode,td.CodeValue,CONVERT(NVARCHAR, ssa.BeginDate, 112) ) [_sourceKey],			
			ds.StudentKey,
			dschool.SchoolKey,
			dc.CourseKey,
			dstaff.StaffKey,	        
	        ssa.BeginDate,
			ssa.EndDate,
			ssa.SchoolYear,

			ssa.LastModifiedDate,
			ssa.ValidFrom,
			ssa.ValidTo,
			ssa.IsCurrent		
		--SELECT  *
		FROM
			    #studentSectionAssociation AS ssa
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CourseOffering co ON ssa.SchoolId = co.SchoolId
				                                                                       AND ssa.LocalCourseCode = co.LocalCourseCode
																					   AND ssa.SchoolYear = co.SchoolYear
																					   AND ssa.TermDescriptorId = co.TermDescriptorId
		        INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor td ON co.TermDescriptorId = td.DescriptorId
			
																									  
				INNER JOIN dbo.DimStudent ds  ON CONCAT_WS('|', 'Ed-Fi', ssa.StudentUSI)   = ds._sourceKey
															      AND  ssa.BeginDate BETWEEN ds.ValidFrom AND ds.ValidTo
				INNER JOIN dbo.DimSchool dschool ON CONCAT_WS('|', 'Ed-Fi', ssa.SchoolId) = dschool._sourceKey
				                                                  AND  ssa.BeginDate BETWEEN dschool.ValidFrom AND dschool.ValidTo
				INNER JOIN dbo.DimCourse dc ON CONCAT_WS('|', 'Ed-Fi', co.CourseCode) = dc._sourceKey
				                                                  AND  ssa.BeginDate BETWEEN dc.ValidFrom AND dc.ValidTo
				INNER JOIN dbo.DimStaff dstaff ON CONCAT_WS('|', 'Ed-Fi', ssa.StaffUSI) = dstaff._sourceKey
				                                                  AND  ssa.BeginDate BETWEEN dstaff.ValidFrom AND dstaff.ValidTo
		
		DROP TABLE #studentSectionAssociation
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
