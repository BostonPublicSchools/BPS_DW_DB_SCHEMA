SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_DimStaff_PopulateProduction]
@LineageKey INT,
@LastDateLoaded DATETIME
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
				 
	    DECLARE @IsFirstLoad bit = 0;

		--empty row technique
		--fact table should not have null foreign keys references
		--this empty record will be used in those cases
		IF NOT EXISTS (SELECT 1 
		               FROM dbo.DimStaff WHERE _sourceKey = '')
				BEGIN
				   SET @IsFirstLoad = 1;
				   INSERT INTO [dbo].DimStaff
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
				       ValidFrom,
				       ValidTo,
				       IsCurrent,
					   IsLatest,
				       LineageKey
				   )
				   VALUES
				   (   N'',       -- _sourceKey - nvarchar(50)
				       N'N/A',       -- PrimaryElectronicMailAddress - nvarchar(128)
				       N'N/A',       -- PrimaryElectronicMailTypeDescriptor_CodeValue - nvarchar(128)
				       N'N/A',       -- PrimaryElectronicMailTypeDescriptor_Description - nvarchar(128)
					   N'N/A',       -- EducationOrganizationId - int
					   N'N/A',       -- ShortNameOfInstitution - nvarchar(500)
					   N'N/A',       -- NameOfInstitution - nvarchar(500)
				       N'N/A',       -- StaffUniqueId - nvarchar(32)
				       N'N/A',       -- PersonalTitlePrefix - nvarchar(30)
				       N'N/A',       -- FirstName - nvarchar(75)
				       N'N/A',       -- MiddleName - nvarchar(75)
				       '',        -- MiddleInitial - char(1)
				       N'N/A',       -- LastSurname - nvarchar(75)
				       N'N/A',       -- FullName - nvarchar(50)
				       N'N/A',       -- GenerationCodeSuffix - nvarchar(10)
				       N'N/A',       -- MaidenName - nvarchar(75)
				       GETDATE(), -- BirthDate - date
				       0,         -- StaffAge - int
				       N'',       -- SexType_Code - nvarchar(15)
				       N'',       -- SexType_Description - nvarchar(100)
				       0,      -- SexType_Male_Indicator - bit
				       0,      -- SexType_Female_Indicator - bit
				       1,      -- SexType_NotSelected_Indicator - bit
				       N'',       -- HighestLevelOfEducationDescriptorDescriptor_CodeValue - nvarchar(100)
				       N'',       -- HighestLevelOfEducationDescriptorDescriptor_Description - nvarchar(100)
				       NULL,      -- YearsOfPriorProfessionalExperience - decimal(5, 2)
				       NULL,      -- YearsOfPriorTeachingExperience - decimal(5, 2)
				       NULL,      -- HighlyQualifiedTeacher_Indicator - bit
				       N'',       -- StaffClassificationDescriptor_CodeValue - nvarchar(100)
				       N'',       -- StaffClassificationDescriptor_CodeDescription - nvarchar(100)
				      '07/01/2015', -- ValidFrom - datetime
					  '9999-12-31', -- ValidTo - datetime
					   0,      -- IsCurrent - bit
					   1,      -- IsLatest - bit
					  -1          -- LineageKey - int
				       )
				END

		
		--staging table holds newer records. 
		--the matching prod records will be valid until the date in which the newest data change was identified		
		UPDATE prod
		SET prod.ValidTo = stage.ValidFrom,
		    prod.IsLatest = 0 
		FROM 
			[dbo].[DimSchool] AS prod
			INNER JOIN Staging.School AS stage ON prod._sourceKey = stage._sourceKey
		WHERE prod.ValidTo = '12/31/9999'


		INSERT INTO dbo.DimStaff
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
		    ValidFrom,
		    ValidTo,
		    IsCurrent,
			IsLatest,
		    LineageKey
		)
		
		SELECT 
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
		    ValidFrom,
		    ValidTo,
		    IsCurrent,		
			1 AS IsLatest,
		    @LineageKey
		FROM Staging.Staff

		--during the first load, let's set the IsLatest flag
		--incremental changes will keep this flag updated after the first load
		if (@IsFirstLoad = 1)
		 BEGIN
		    UPDATE dbo.DimStaff
			SET IsLatest = 0;
			
			;WITH LatestEntry AS
			(
				SELECT DISTINCT 
					   d._sourceKey, 
					   d.StaffKey AS TheKey, 
					   d.ValidFrom, 
					   d.ValidTo,
					   d.IsLatest,
					   ROW_NUMBER() OVER (PARTITION BY d._sourceKey ORDER BY d.ValidFrom Desc, d.ValidTo DESC) AS RowRankId
				FROM dbo.DimStaff d 
			)

			UPDATE d
			SET d.IsLatest = 1
			FROM dbo.DimStaff d
			WHERE EXISTS (SELECT 1 
							  FROM LatestEntry le
							  WHERE d.StaffKey = le.TheKey 
								AND le.RowRankId = 1);
		 END
         
		


		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE LineageKey = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.DimStaff';

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
