SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_DimStudent_PopulateProduction]
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
		
		--empty row technique
		--fact table should not have null foreign keys references
		--this empty record will be used in those cases
		IF NOT EXISTS (SELECT 1 
		               FROM dbo.DimStudent WHERE _sourceKey = '')
				BEGIN
				   INSERT INTO [dbo].DimStudent
				   (
				       _sourceKey,
				       StudentUniqueId,
				       StateId,
				       PrimaryElectronicMailAddress,
				       PrimaryElectronicMailTypeDescriptor_CodeValue,
				       PrimaryElectronicMailTypeDescriptor_Description,
				       SchoolKey,
				       ShortNameOfInstitution,
				       NameOfInstitution,
				       GradeLevelDescriptor_CodeValue,
				       GradeLevelDescriptor_Description,
				       FirstName,
				       MiddleInitial,
				       MiddleName,
				       LastSurname,
				       FullName,
				       BirthDate,
				       StudentAge,
				       GraduationSchoolYear,
				       Homeroom,
				       HomeroomTeacher,
				       SexType_Code,
				       SexType_Description,
				       SexType_Male_Indicator,
				       SexType_Female_Indicator,
				       SexType_NotSelected_Indicator,
				       RaceCode,
				       RaceDescription,
				       StateRaceCode,
				       Race_AmericanIndianAlaskanNative_Indicator,
				       Race_Asian_Indicator,
				       Race_BlackAfricaAmerican_Indicator,
				       Race_NativeHawaiianPacificIslander_Indicator,
				       Race_White_Indicator,
				       Race_MultiRace_Indicator,
				       Race_ChooseNotRespond_Indicator,
				       Race_Other_Indicator,
				       EthnicityCode,
				       EthnicityDescription,
				       EthnicityHispanicLatino_Indicator,
				       Migrant_Indicator,
				       Homeless_Indicator,
				       IEP_Indicator,
				       English_Learner_Code_Value,
				       English_Learner_Description,
				       English_Learner_Indicator,
				       Former_English_Learner_Indicator,
				       Never_English_Learner_Indicator,
				       EconomicDisadvantage_Indicator,
				       EntryDate,
				       EntrySchoolYear,
				       EntryCode,
				       ExitWithdrawDate,
				       ExitWithdrawSchoolYear,
				       ExitWithdrawCode,
				       ValidFrom,
				       ValidTo,
				       IsCurrent,
				       LineageKey
				   )
				   VALUES
				   (   N'',           -- _sourceKey - nvarchar(50)
				       N'N/A',           -- StudentUniqueId - nvarchar(32)
				       N'N/A',           -- StateId - nvarchar(32)
				       N'N/A',           -- PrimaryElectronicMailAddress - nvarchar(128)
				       N'N/A',           -- PrimaryElectronicMailTypeDescriptor_CodeValue - nvarchar(128)
				       N'N/A',           -- PrimaryElectronicMailTypeDescriptor_Description - nvarchar(128)
				       0,             -- SchoolKey - int
				       N'N/A',           -- ShortNameOfInstitution - nvarchar(500)
				       N'N/A',           -- NameOfInstitution - nvarchar(500)
				       N'N/A',           -- GradeLevelDescriptor_CodeValue - nvarchar(100)
				       N'N/A',           -- GradeLevelDescriptor_Description - nvarchar(500)
				       N'N/A',           -- FirstName - nvarchar(100)
				       '',            -- MiddleInitial - char(1)
				       N'N/A',           -- MiddleName - nvarchar(100)
				       N'N/A',           -- LastSurname - nvarchar(100)
				       N'N/A',           -- FullName - nvarchar(500)
				       GETDATE(),     -- BirthDate - date
				       0,             -- StudentAge - int
				       0,             -- GraduationSchoolYear - int
				       N'N/A',           -- Homeroom - nvarchar(500)
				       N'N/A',           -- HomeroomTeacher - nvarchar(500)
				       N'N/A',           -- SexType_Code - nvarchar(100)
				       N'N/A',           -- SexType_Description - nvarchar(100)
				       0,          -- SexType_Male_Indicator - bit
				       0,          -- SexType_Female_Indicator - bit
				       0,          -- SexType_NotSelected_Indicator - bit
				       N'N/A',           -- RaceCode - nvarchar(1000)
				       N'N/A',           -- RaceDescription - nvarchar(1000)
				       N'N/A',           -- StateRaceCode - nvarchar(1000)
				       0,          -- Race_AmericanIndianAlaskanNative_Indicator - bit
				       0,          -- Race_Asian_Indicator - bit
				       0,          -- Race_BlackAfricaAmerican_Indicator - bit
				       0,          -- Race_NativeHawaiianPacificIslander_Indicator - bit
				       0,          -- Race_White_Indicator - bit
				       0,          -- Race_MultiRace_Indicator - bit
				       0,          -- Race_ChooseNotRespond_Indicator - bit
				       0,          -- Race_Other_Indicator - bit
				       N'N/A',           -- EthnicityCode - nvarchar(100)
				       N'N/A',           -- EthnicityDescription - nvarchar(100)
				       0,          -- EthnicityHispanicLatino_Indicator - bit
				       0,          -- Migrant_Indicator - bit
				       0,          -- Homeless_Indicator - bit
				       0,          -- IEP_Indicator - bit
				       N'',           -- English_Learner_Code_Value - nvarchar(100)
				       N'',           -- English_Learner_Description - nvarchar(100)
				       0,          -- English_Learner_Indicator - bit
				       0,          -- Former_English_Learner_Indicator - bit
				       0,          -- Never_English_Learner_Indicator - bit
				       0,          -- EconomicDisadvantage_Indicator - bit
				       SYSDATETIME(), -- EntryDate - datetime2(7)
				       0,             -- EntrySchoolYear - int
				       N'N/A',        -- EntryCode - nvarchar(25)
				       SYSDATETIME(), -- ExitWithdrawDate - datetime2(7)
				       0,           -- ExitWithdrawSchoolYear - int
				       N'N/A',        -- ExitWithdrawCode - nvarchar(100)
				      '07/01/2015', -- ValidFrom - datetime
					  '9999-12-31', -- ValidTo - datetime
					   0,      -- IsCurrent - bit
					   -1          -- LineageKey - int
				       )
				    
				END

		--staging table holds newer records. 
		--the matching prod records will be valid until the date in which the newest data change was identified
		UPDATE prod
		SET prod.ValidTo = stage.ValidFrom,
		    prod.IsCurrent = 0
		FROM 
			[dbo].[DimStudent] AS prod
			INNER JOIN Staging.Student AS stage ON prod._sourceKey = stage._sourceKey
		WHERE prod.ValidTo = '12/31/9999'


		INSERT INTO dbo.DimStudent
		(
		    [_sourceKey]
           ,[PrimaryElectronicMailAddress]
		   ,[PrimaryElectronicMailTypeDescriptor_CodeValue]
		   ,[PrimaryElectronicMailTypeDescriptor_Description]
           ,[StudentUniqueId]
           ,[StateId]
           ,[SchoolKey]
           ,[ShortNameOfInstitution]
           ,[NameOfInstitution]
           ,[GradeLevelDescriptor_CodeValue]
           ,[GradeLevelDescriptor_Description]
           ,[FirstName]
           ,[MiddleInitial]
           ,[MiddleName]
           ,[LastSurname]
           ,[FullName]
           ,[BirthDate]
           ,[StudentAge]
           ,[GraduationSchoolYear]
           ,[Homeroom]
           ,[HomeroomTeacher]
           ,[SexType_Code]
           ,[SexType_Description]
           ,[SexType_Male_Indicator]
           ,[SexType_Female_Indicator]
           ,[SexType_NotSelected_Indicator]
           ,[RaceCode]
           ,[RaceDescription]
		   ,[StateRaceCode]
           ,[Race_AmericanIndianAlaskanNative_Indicator]
           ,[Race_Asian_Indicator]
           ,[Race_BlackAfricaAmerican_Indicator]
           ,[Race_NativeHawaiianPacificIslander_Indicator]
           ,[Race_White_Indicator]
           ,[Race_MultiRace_Indicator]
           ,[Race_ChooseNotRespond_Indicator]
           ,[Race_Other_Indicator]
           ,[EthnicityCode]
           ,[EthnicityDescription]
           ,[EthnicityHispanicLatino_Indicator]
           ,[Migrant_Indicator]
           ,[Homeless_Indicator]
           ,[IEP_Indicator]
           ,[English_Learner_Code_Value]
           ,[English_Learner_Description]
           ,[English_Learner_Indicator]
           ,[Former_English_Learner_Indicator]
           ,[Never_English_Learner_Indicator]
           ,[EconomicDisadvantage_Indicator]
           ,[EntryDate]
           ,[EntrySchoolYear]
           ,[EntryCode]
           ,[ExitWithdrawDate]
           ,[ExitWithdrawSchoolYear]
           ,[ExitWithdrawCode]
           ,[ValidFrom]
           ,[ValidTo]
           ,[IsCurrent]
           ,[LineageKey]
		)
		SELECT 
		    [_sourceKey]
           ,[PrimaryElectronicMailAddress]
		   ,[PrimaryElectronicMailTypeDescriptor_CodeValue]
		   ,[PrimaryElectronicMailTypeDescriptor_Description]
           ,[StudentUniqueId]
           ,[StateId]
           ,[SchoolKey]
           ,[ShortNameOfInstitution]
           ,[NameOfInstitution]
           ,[GradeLevelDescriptor_CodeValue]
           ,[GradeLevelDescriptor_Description]
           ,[FirstName]
           ,[MiddleInitial]
           ,[MiddleName]
           ,[LastSurname]
           ,[FullName]
           ,[BirthDate]
           ,[StudentAge]
           ,[GraduationSchoolYear]
           ,[Homeroom]
           ,[HomeroomTeacher]
           ,[SexType_Code]
           ,[SexType_Description]
           ,[SexType_Male_Indicator]
           ,[SexType_Female_Indicator]
           ,[SexType_NotSelected_Indicator]
           ,[RaceCode]
           ,[RaceDescription]
		   ,[StateRaceCode]
           ,[Race_AmericanIndianAlaskanNative_Indicator]
           ,[Race_Asian_Indicator]
           ,[Race_BlackAfricaAmerican_Indicator]
           ,[Race_NativeHawaiianPacificIslander_Indicator]
           ,[Race_White_Indicator]
           ,[Race_MultiRace_Indicator]
           ,[Race_ChooseNotRespond_Indicator]
           ,[Race_Other_Indicator]
           ,[EthnicityCode]
           ,[EthnicityDescription]
           ,[EthnicityHispanicLatino_Indicator]
           ,[Migrant_Indicator]
           ,[Homeless_Indicator]
           ,[IEP_Indicator]
           ,[English_Learner_Code_Value]
           ,[English_Learner_Description]
           ,[English_Learner_Indicator]
           ,[Former_English_Learner_Indicator]
           ,[Never_English_Learner_Indicator]
           ,[EconomicDisadvantage_Indicator]
           ,[EntryDate]
           ,[EntrySchoolYear]
           ,[EntryCode]
           ,[ExitWithdrawDate]
           ,[ExitWithdrawSchoolYear]
           ,[ExitWithdrawCode]
           ,[ValidFrom]
           ,[ValidTo]
           ,[IsCurrent]           
		   ,@LineageKey
		FROM Staging.Student

		--BPS is having data quality issues with exit/withdrawal dates in the ODS
		--this is patch to overcome the problem and maintain the data clean momentarily
		--------------------------------------------------------------------------------------------------
		UPDATE dbo.DimStudent
		SET IsCurrent = 0;

		DECLARE @currentSchoolYear INT 
		SELECT TOP (1) @currentSchoolYear =  SchoolYear 
		FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.SchoolYearType syt
		WHERE syt.CurrentSchoolYear = 1;
		

		;WITH LatestEntryDatePerStudent AS
        (
			SELECT DISTINCT 
				   ds.StudentUniqueId, 
				   ds.StudentKey, 
				   ROW_NUMBER() OVER (PARTITION BY ds.StudentUniqueId ORDER BY ds.EntryDate DESC) AS RowRankId
			FROM dbo.DimStudent ds 
			WHERE ds.EntrySchoolYear = @currentSchoolYear
		)

		UPDATE ds 
		SET ds.IsCurrent = 1
		FROM dbo.DimStudent ds 
		WHERE ds.EntrySchoolYear = @currentSchoolYear
		      AND EXISTS (SELECT 1 
			              FROM LatestEntryDatePerStudent ledps 
						  WHERE ds.StudentKey = ledps.StudentKey 
						    AND ledps.RowRankId = 1);
		---------------------------------------------------------------------------------------------------


		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE [LineageKey] = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.DimStudent';

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
