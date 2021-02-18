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
		    ValidFrom,
		    ValidTo,
		    IsCurrent
		)
	
        
		SELECT  DISTINCT 
			    CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),s.StaffUSI)) AS [_sourceKey]
				,sem.ElectronicMailAddress AS [PrimaryElectronicMailAddress]
				,emt.CodeValue AS [PrimaryElectronicMailTypeDescriptor_CodeValue]
				,emt.Description AS [PrimaryElectronicMailTypeDescriptor_Description]
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
					WHEN sex.CodeValue  = 'Male' THEN 'M'
					WHEN sex.CodeValue  = 'Female' THEN 'F'
					ELSE 'NS' -- not selected
				END AS SexType_Code
				,COALESCE(sex.CodeValue,'Not Selected') AS SexType_Description
				,CASE WHEN COALESCE(sex.CodeValue,'Not Selected')  = 'Male' THEN 1 ELSE 0 END AS SexType_Male_Indicator
				,CASE WHEN COALESCE(sex.CodeValue,'Not Selected')  = 'Female' THEN 1 ELSE 0 END AS SexType_Female_Indicator
				,CASE WHEN COALESCE(sex.CodeValue,'Not Selected')  = 'Not Selected' THEN 1 ELSE 0 END AS SexType_NotSelected_Indicator
				,COALESCE(d_le.CodeValue,'N/A') as [HighestLevelOfEducationDescriptorDescriptor_CodeValue]
				,COALESCE(d_le.Description,'N/A') as [HighestLevelOfEducationDescriptorDescriptor_Description]
				,s.YearsOfPriorProfessionalExperience
				,s.YearsOfPriorTeachingExperience
				,s.HighlyQualifiedTeacher
				,COALESCE(d_sc.CodeValue,'N/A') as StaffClassificationDescriptor_CodeValue
				,COALESCE(d_sc.Description,'N/A') as StaffClassificationDescriptor_Description
				,CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(s.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS StaffMainInfoModifiedDate
				--Making sure the first time, the ValidFrom is set to beginning of time 
				,CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (s.LastModifiedDate)
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      seoaa.BeginDate 
				END AS ValidFrom
				,case when seoaa.EndDate IS null then  '12/31/9999' else seoaa.EndDate  END AS ValidTo
				,case when seoaa.EndDate IS NULL OR seoaa.EndDate > GETDATE() THEN  1 else 0 end AS IsCurrent 
		--SELECT distinct *
		FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Staff s 
			  INNER JOIN  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StaffEducationOrganizationAssignmentAssociation seoaa ON s.StaffUSI = seoaa.StaffUSI
			  --sex	 
			  left JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.SexType sex ON s.SexTypeId = sex.SexTypeId
			  left join [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.OldEthnicityType oet on s.OldEthnicityTypeId = oet.OldEthnicityTypeId
			  left join [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CitizenshipStatusType cst on s.CitizenshipStatusTypeId = cst.CitizenshipStatusTypeId
			  left join [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor d_le on s.HighestCompletedLevelOfEducationDescriptorId = d_le.DescriptorId
			  LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StaffElectronicMail sem ON s.StaffUSI = sem.StaffUSI
			 															  AND sem.PrimaryEmailAddressIndicator = 1
			  LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.ElectronicMailType emt ON sem.ElectronicMailTypeId = emt.ElectronicMailTypeId
			  left join [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor d_sc on seoaa.StaffClassificationDescriptorId = d_sc.DescriptorId
			 
		WHERE 
			(s.LastModifiedDate > @LastLoadDate AND s.LastModifiedDate <= @NewLoadDate)
						
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
