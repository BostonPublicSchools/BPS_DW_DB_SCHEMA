SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Dim Staff
CREATE   PROCEDURE [dbo].[Proc_ETL_DimStaff_PopulateStaging]
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
		TRUNCATE TABLE Staging.Staff
		INSERT INTO Staging.Staff
		(
		    _sourceKey,
		    PrimaryElectronicMailAddress,
		    PrimaryElectronicMailTypeDescriptor_CodeValue,
		    PrimaryElectronicMailTypeDescriptor_Description,
			EducationOrganizationId,
            ShortNameOfInstitution,
            NameOfInstitution,
		    StaffUniqueId,
		    PersonalTitlePrefix,
		    FirstName,
		    MiddleName,
		    MiddleInitial,
		    LastSurname,
		    FullName,
		    GenerationCodeSuffix,
		    MaidenName,
		    BirthDate,
		    StaffAge,
		    SexType_Code,
		    SexType_Description,
		    SexType_Male_Indicator,
		    SexType_Female_Indicator,
		    SexType_NotSelected_Indicator,
		    HighestLevelOfEducationDescriptorDescriptor_CodeValue,
		    HighestLevelOfEducationDescriptorDescriptor_Description,
		    YearsOfPriorProfessionalExperience,
		    YearsOfPriorTeachingExperience,
		    HighlyQualifiedTeacher_Indicator,
		    StaffClassificationDescriptor_CodeValue,
		    StaffClassificationDescriptor_CodeDescription,			
			StaffMainInfoModifiedDate,			
            StaffEdOrgAssignmentModifiedDate,  
            StaffEdOrgEmploymentModifiedDate,  
		    ValidFrom,
		    ValidTo,
		    IsCurrent
		)
	
        --declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT  DISTINCT 
			    CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),s.StaffUniqueId)) AS [_sourceKey]
				,sem.ElectronicMailAddress AS [PrimaryElectronicMailAddress]
				,sem_d.CodeValue AS [PrimaryElectronicMailTypeDescriptor_CodeValue]
				,sem_d.Description AS [PrimaryElectronicMailTypeDescriptor_Description]
				,eo.EducationOrganizationId
				,COALESCE(eo.ShortNameOfInstitution,'N/A') AS ShortNameOfInstitution
				,eo.NameOfInstitution
				,s.StaffUniqueId
				,s.PersonalTitlePrefix
				,s.FirstName
				,s.MiddleName
				,LEFT(LTRIM(s.MiddleName),1) AS MiddleInitial	    
				,s.LastSurname
				,dbo.Func_ETL_GetFullName(s.FirstName,s.MiddleName,s.LastSurname) AS FullName
				,s.GenerationCodeSuffix
				,s.MaidenName        
				,s.BirthDate
				,DATEDIFF(YEAR, s.BirthDate, GetDate()) AS [StaffAge]
				,CASE 
					WHEN d_sex.CodeValue  = 'Male' THEN 'M'
					WHEN d_sex.CodeValue  = 'Female' THEN 'F'
					ELSE 'NS' -- not selected
				END AS SexType_Code
				,COALESCE(d_sex.CodeValue,'Not Selected') AS SexType_Description
				,CASE WHEN COALESCE(d_sex.CodeValue,'Not Selected')  = 'Male' THEN 1 ELSE 0 END AS SexType_Male_Indicator
				,CASE WHEN COALESCE(d_sex.CodeValue,'Not Selected')  = 'Female' THEN 1 ELSE 0 END AS SexType_Female_Indicator
				,CASE WHEN COALESCE(d_sex.CodeValue,'Not Selected')  = 'Not Selected' THEN 1 ELSE 0 END AS SexType_NotSelected_Indicator
				,COALESCE(d_le.CodeValue,'N/A') as [HighestLevelOfEducationDescriptorDescriptor_CodeValue]
				,COALESCE(d_le.Description,'N/A') as [HighestLevelOfEducationDescriptorDescriptor_Description]
				,s.YearsOfPriorProfessionalExperience
				,s.YearsOfPriorTeachingExperience
				,s.HighlyQualifiedTeacher
				,COALESCE(d_sc.CodeValue,'N/A') as StaffClassificationDescriptor_CodeValue
				,COALESCE(d_sc.Description,'N/A') as StaffClassificationDescriptor_Description
				,CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(s.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS StaffMainInfoModifiedDate
				,CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(seoaa.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS StaffEdOrgAssignmentModifiedDate
				,GETDATE() AS StaffEdOrgEmploymentModifiedDate
				--,CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(seoea.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS StaffEdOrgEmploymentModifiedDate
				--Making sure the first time, the ValidFrom is set to beginning of time 
				,CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                                (s.LastModifiedDate)
							   ,(seoaa.LastModifiedDate)							   
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      seoaa.BeginDate 
				END AS ValidFrom
				,COALESCE(seoaa.EndDate,'12/31/9999') ValidTo
				,CASE WHEN COALESCE(seoaa.EndDate,'12/31/9999') >= GETDATE() then 1 
                     ELSE 0 
			     END AS IsCurrent

		--SELECT distinct *
		FROM  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff s 
			  INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffEducationOrganizationAssignmentAssociation seoaa ON s.StaffUSI = seoaa.StaffUSI
			  --INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffEducationOrganizationEmploymentAssociation seoea ON seoaa.StaffUSI = seoea.StaffUSI
			                                                                                                         --AND seoaa.EmploymentEducationOrganizationId = seoea.EducationOrganizationId
			  INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.EducationOrganization eo ON seoaa.EducationOrganizationId = eo.EducationOrganizationId
			  --sex	 
			  left JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d_sex ON s.SexDescriptorId = d_sex.DescriptorId
			  left join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d_le on s.HighestCompletedLevelOfEducationDescriptorId = d_le.DescriptorId

			  LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffElectronicMail sem ON s.StaffUSI = sem.StaffUSI
			  LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor sem_d ON sem.ElectronicMailTypeDescriptorId = sem_d.DescriptorId 
			                                                                             AND sem_d.CodeValue = 'Primary' 	
			 															  	  
			  left join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d_sc on seoaa.StaffClassificationDescriptorId = d_sc.DescriptorId			  
			
		WHERE NOT EXISTS(SELECT 1
			             FROM dbo.DimStaff ds
					     WHERE CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),s.StaffUniqueId)) = ds._sourceKey)
			

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
