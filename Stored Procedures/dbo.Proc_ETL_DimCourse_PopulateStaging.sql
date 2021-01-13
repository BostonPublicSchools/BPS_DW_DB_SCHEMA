SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Dim Course
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimCourse_PopulateStaging]
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

		
		TRUNCATE TABLE Staging.Course
		INSERT INTO Staging.Course
		(
		    _sourceKey,
		    CourseCode,
		    CourseTitle,
		    CourseDescription,
		    CourseLevelCharacteristicTypeDescriptor_CodeValue,
		    CourseLevelCharacteristicTypeDescriptor_Description,
		    AcademicSubjectDescriptor_CodeValue,
		    AcademicSubjectDescriptor_Description,
		    HighSchoolCourseRequirement_Indicator,
		    MinimumAvailableCredits,
		    MaximumAvailableCredits,
		    GPAApplicabilityType_CodeValue,
		    GPAApplicabilityType_Description,
		    SecondaryCourseLevelCharacteristicTypeDescriptor_CodeValue,
		    SecondaryCourseLevelCharacteristicTypeDescriptor_Description,
		    CourseModifiedDate,
		    ValidFrom,
		    ValidTo,
		    IsCurrent
		)
		
        --declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT DISTINCT 
			   CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),c.CourseCode)) AS [_sourceKey],
			   c.CourseCode,
			   c.CourseTitle,
			   c.CourseDescription,
			   COALESCE(clct_d.CodeValue,'N/A') AS [CourseLevelCharacteristicTypeDescriptor_CodeValue],
			   COALESCE(clct_d.[Description],'N/A') AS [CourseLevelCharacteristicTypeDescriptor_Descriptor],

			   COALESCE(ast_d.CodeValue,'N/A') AS [AcademicSubjectDescriptor_CodeValue],
			   COALESCE(ast_d.[Description],'N/A') AS [AcademicSubjectDescriptor_Descriptor],
			   COALESCE(c.HighSchoolCourseRequirement,0) AS [HighSchoolCourseRequirement_Indicator],

			   c.MinimumAvailableCredits,
			   c.MaximumAvailableCredits,
			   COALESCE(cgat_d.CodeValue,'N/A')  AS GPAApplicabilityType_CodeValue,
			   COALESCE(cgat_d.[Description],'N/A') AS GPAApplicabilityType_Description,
	   
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
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Course c --WHERE c.CourseCode = '094'
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.CourseLevelCharacteristic clc ON c.CourseCode = clc.CourseCode
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor clct_d ON clc.CourseLevelCharacteristicDescriptorId = clct_d.DescriptorId
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor ast_d ON c.AcademicSubjectDescriptorId = ast_d.DescriptorId
			 LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor cgat_d ON c.CourseGPAApplicabilityDescriptorId = cgat_d.DescriptorId
		WHERE EXISTS (SELECT 1 
					  FROM  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.CourseOffering co 
					  WHERE c.CourseCode = co.CourseCode
						AND co.SchoolYear >= 2019) AND
			 (c.LastModifiedDate > @LastLoadDate AND c.LastModifiedDate <= @NewLoadDate)
			
					
					
		
		--[v34_v34_EdFi_BPS_Production_Ods]
		--loading legacy data if it has not been loaded.
		--load types are ignored as this data will only be loaded once.
		IF NOT EXISTS(SELECT 1 
		              FROM dbo.DimCourse 
					  WHERE CHARINDEX('LegacyDW',_sourceKey,1) > 0)
			BEGIN
			   INSERT INTO Staging.Course
				   (_sourceKey,
				    CourseCode,
					CourseTitle,
					CourseDescription,
					CourseLevelCharacteristicTypeDescriptor_CodeValue,
					CourseLevelCharacteristicTypeDescriptor_Description,
					AcademicSubjectDescriptor_CodeValue,
					AcademicSubjectDescriptor_Description,
					HighSchoolCourseRequirement_Indicator,
					MinimumAvailableCredits,
					MaximumAvailableCredits,
					GPAApplicabilityType_CodeValue,
					GPAApplicabilityType_Description,
					SecondaryCourseLevelCharacteristicTypeDescriptor_CodeValue,
					SecondaryCourseLevelCharacteristicTypeDescriptor_Description,
					CourseModifiedDate,
					ValidFrom,
					ValidTo,
					IsCurrent)
				 SELECT DISTINCT 
					   CONCAT('LegacyDW|',c.CourseNumber,'-',CASE WHEN s.SectionID = '' THEN 'N/A' ELSE s.SectionID END) AS [_sourceKey],
					   CONCAT_WS('-',c.CourseNumber,CASE WHEN s.SectionID = '' THEN 'N/A' ELSE s.SectionID END) AS [CourseCode],
					   c.TitleFull,
					   c.TitleFull,
					   COALESCE(c.LevelCode,'N/A') AS [CourseLevelCharacteristicTypeDescriptor_CodeValue],
					   COALESCE(c.LevelCode,'N/A') AS [CourseLevelCharacteristicTypeDescriptor_Description],

					   COALESCE(c.Department,'N/A') AS [AcademicSubjectDescriptor_CodeValue],
					   COALESCE(c.Department,'N/A') AS [AcademicSubjectDescriptor_Description],
					   0 AS [HighSchoolCourseRequirement_Indicator],

					   NULL AS MinimumAvailableCredits,
					   NULL AS MaximumAvailableCredits,
					   CASE WHEN COALESCE(c.InGPA,'N') = 'Y' THEN 'Applicable' ELSE 'Not Applicable' END  AS GPAApplicabilityType_CodeValue,
					   CASE WHEN COALESCE(c.InGPA,'N') = 'Y' THEN 'Applicable' ELSE 'Not Applicable' END AS GPAApplicabilityType_Description,
					   COALESCE(c.MassCore,'N/A') AS [SecondaryCourseLevelCharacteristicTypeDescriptor_CodeValue],
					   COALESCE(c.MassCore,'N/A') AS [SecondaryCourseLevelCharacteristicTypeDescriptor_Description],
					   '07/01/2015' AS CourseModifiedDate,
					   '07/01/2015' AS ValidFrom,
					    GETDATE() as ValidTo,
						0 AS IsCurrent
				--select *
				FROM [BPSGranary02].[RAEDatabase].[dbo].[CourseCatalog_aspen] c  --   WHERE CourseNumber = '094' AND SchoolYear IN ('2017-2018','2016-2017','2015-2016')
					 INNER JOIN [BPSGranary02].[RAEDatabase].[dbo].[StudentCourseGrade_aspenNewFormat] s ON c.CourseNumber = s.CourseNumber
																										AND c.SchoolYear = s.SchoolYear
				WHERE c.SchoolYear IN ('2017-2018','2016-2017','2015-2016');
			

			END

		
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
