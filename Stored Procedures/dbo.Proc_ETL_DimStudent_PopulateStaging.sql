SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--Dim Student
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimStudent_PopulateStaging]
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

		--BEGIN TRANSACTION;   

		TRUNCATE TABLE Staging.[Student]

		SELECT DISTINCT 
			   s.StudentUSI, 
			   COUNT(sr.StudentUSI) AS RaceCount,
			   STRING_AGG(rt.CodeValue,',') AS RaceCodes,
			   STRING_AGG(rt.Description,',') AS RaceDescriptions,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr
									   WHERE s.StudentUSI = sr.StudentUSI
										 AND sr.RaceTypeId = 1) THEN 1
			   ELSE 
				   0	             
			   END AS Race_AmericanIndianAlaskanNative_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr
									   WHERE s.StudentUSI = sr.StudentUSI
										 AND sr.RaceTypeId = 2) THEN 1
			   ELSE 
				   0	             
			   END AS Race_Asian_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr
									   WHERE s.StudentUSI = sr.StudentUSI
										 AND sr.RaceTypeId = 3) THEN 1
			   ELSE 
				   0	             
			   END AS Race_BlackAfricaAmerican_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr
									   WHERE s.StudentUSI = sr.StudentUSI
										 AND sr.RaceTypeId = 5) THEN 1
			   ELSE 
				   0	             
			   END AS Race_NativeHawaiianPacificIslander_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr
									   WHERE s.StudentUSI = sr.StudentUSI
										 AND sr.RaceTypeId = 7) THEN 1
			   ELSE 
				   0	             
			   END AS Race_White_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr
									   WHERE s.StudentUSI = sr.StudentUSI
										 AND sr.RaceTypeId = 4) THEN 1
			   ELSE 
				   0	             
			   END AS Race_ChooseNotRespond_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr
									   WHERE s.StudentUSI = sr.StudentUSI
										 AND sr.RaceTypeId = 6) THEN 1
			   ELSE 
				   0	             
			   END AS Race_Other_Indicator into #StudentRaces    

		FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Student s
			  LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentRace sr ON s.StudentUSI = sr.StudentUSI		
			  LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.RaceType rt ON sr.RaceTypeId = rt.RaceTypeId
	    WHERE (s.LastModifiedDate > @LastLoadDate AND s.LastModifiedDate <= @NewLoadDate) --OR
			  --(rt.LastModifiedDate > @LastLoadDate AND rt.LastModifiedDate <= @NewLoadDate)
		GROUP BY s.StudentUSI, s.HispanicLatinoEthnicity
				
				
		--;WITH StudentHomeRooomByYear AS
		--(
			SELECT DISTINCT std_sa.StudentUSI, 
							std_sa.SchoolYear, 
							std_sa.SchoolId,  
							std_sa.ClassroomIdentificationCode AS HomeRoom,
							dbo.Func_ETL_GetFullName(staff.FirstName,staff.MiddleName,staff.LastSurname) AS HomeRoomTeacher,
							ROW_NUMBER() OVER (PARTITION BY std_sa.StudentUSI, 
															std_sa.SchoolYear, 
															std_sa.SchoolId ORDER BY staff_sa.BeginDate DESC) AS RowRankId INTO #StudentHomeRooomByYear
			FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Student s
			INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentSectionAssociation std_sa ON s.StudentUSI = std_sa.StudentUSI			
				 INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StaffSectionAssociation staff_sa  ON std_sa.UniqueSectionCode = staff_sa.UniqueSectionCode
																										AND std_sa.SchoolYear = staff_sa.SchoolYear
				 INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Staff staff on staff_sa.StaffUSI = staff.StaffUSI
			WHERE std_sa.HomeroomIndicator = 1
				 AND std_sa.SchoolYear >= 2019
				 AND std_sa.EndDate > GETDATE()
				 --AND s.StudentUniqueId = 269159 
				 AND (
				       (s.LastModifiedDate > @LastLoadDate AND s.LastModifiedDate <= @NewLoadDate) 
				     )
					 
        --)
		
		INSERT INTO Staging.[Student]
				   ([_sourceKey]
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

				   
				   ,StudentMainInfoModifiedDate
	               ,StudentSchoolAssociationModifiedDate

				   ,[ValidFrom]
				   ,[ValidTo]
				   ,[IsCurrent])
        SELECT distinct
			   CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StudentUSI)) AS [_sourceKey],
			   sem.ElectronicMailAddress AS [PrimaryElectronicMailAddress],
			   emt.CodeValue AS [PrimaryElectronicMailTypeDescriptor_CodeValue],
			   emt.Description AS [PrimaryElectronicMailTypeDescriptor_Description],
			   s.StudentUniqueId,       
			   sic.IdentificationCode AS StateId,
       
			   dschool.SchoolKey,
			   edorg.ShortNameOfInstitution,
			   edorg.NameOfInstitution,
			   gld.CodeValue GradeLevelDescriptor_CodeValue,
			   gld.Description AS GradeLevelDescriptor_Description,

			   s.FirstName,
			   LEFT(LTRIM(s.MiddleName),1) AS MiddleInitial,
			   s.MiddleName,	   
			   s.LastSurname,
			   dbo.Func_ETL_GetFullName(s.FirstName,s.MiddleName,s.LastSurname) AS FullName,
			   s.BirthDate,
			   DATEDIFF(YEAR, s.BirthDate, GetDate()) AS StudentAge,
			   ssa.GraduationSchoolYear,

			   COALESCE(shrby.Homeroom,'N/A') AS Homeroom,
			   COALESCE(shrby.HomeroomTeacher,'N/A') AS HomerHomeroomTeacheroom,
			   
			   CASE 
					WHEN sex.CodeValue  = 'Male' THEN 'M'
					WHEN sex.CodeValue  = 'Female' THEN 'F'
					ELSE 'NS' -- not selected
			   END AS SexType_Code,
			   sex.Description AS SexType_Description,
			   CASE WHEN sex.CodeValue  = 'Male' THEN 1 ELSE 0 END AS SexType_Male_Indicator,
			   CASE WHEN sex.CodeValue  = 'Female' THEN 1 ELSE 0 END AS SexType_Female_Indicator,
			   CASE WHEN sex.CodeValue  = 'Not Selected' THEN 1 ELSE 0 END AS SexType_NotSelected_Indicator, 
       
			   COALESCE(sr.RaceCodes,'N/A') AS RaceCode,	   
			   COALESCE(sr.RaceDescriptions,'N/A') AS RaceDescription,
			   CASE WHEN sr.RaceCount > 1 AND s.HispanicLatinoEthnicity = 0 THEN 'Multirace' 
					WHEN s.HispanicLatinoEthnicity = 1 THEN 'Latinx'
					ELSE COALESCE(sr.RaceCodes,'N/A')
			   END AS StateRaceCode,
			   sr.Race_AmericanIndianAlaskanNative_Indicator,
			   sr.Race_Asian_Indicator ,

			   sr.Race_BlackAfricaAmerican_Indicator,
			   sr.Race_NativeHawaiianPacificIslander_Indicator,
			   sr.Race_White_Indicator,
			   CASE WHEN sr.RaceCount > 1 AND s.HispanicLatinoEthnicity = 0 THEN 1 ELSE 0 END AS Race_MultiRace_Indicator, 
			   sr.Race_ChooseNotRespond_Indicator,
			   sr.Race_Other_Indicator,

			   CASE WHEN s.HispanicLatinoEthnicity = 1 THEN 'L' ELSE 'Non-L' END  AS EthnicityCode,
			   CASE WHEN s.HispanicLatinoEthnicity = 1 THEN 'Latinx' ELSE 'Non Latinx' END  AS EthnicityDescription,
			   s.HispanicLatinoEthnicity AS EthnicityHispanicLatino_Indicator,

			   CASE WHEN EXISTS (
							   SELECT 1
							   FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentProgramAssociation spa
							   WHERE CHARINDEX('Migrant', spa.ProgramName,1) > 1
									 AND spa.StudentUSI = s.StudentUSI
									 AND spa.EndDate IS NULL
						   ) THEN 1 ELSE 0 End AS Migrant_Indicator,
			   CASE WHEN EXISTS (
							   SELECT 1
							   FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentProgramAssociation spa
							   WHERE CHARINDEX('Homeless', spa.ProgramName,1) > 1
									 AND spa.StudentUSI = s.StudentUSI
									 AND spa.EndDate IS NULL
						   ) THEN 1 ELSE 0 End AS Homeless_Indicator,
				CASE WHEN EXISTS (
							   SELECT 1
							   FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentSpecialEducationProgramAssociation spa
							   WHERE CHARINDEX('IEP', spa.ProgramName,1) > 1
									 AND spa.StudentUSI = s.StudentUSI
									 AND spa.IEPEndDate IS NULL
						   ) THEN 1 ELSE 0 End AS IEP_Indicator,
	   
			   COALESCE(lepd.CodeValue,'N/A') AS LimitedEnglishProficiencyDescriptor_CodeValue,
			   COALESCE(lepd.CodeValue,'N/A') AS LimitedEnglishProficiencyDescriptor_Description,
			   CASE WHEN COALESCE(lepd.CodeValue,'N/A') = 'Limited' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_EnglishLearner_Indicator,
			   CASE WHEN COALESCE(lepd.CodeValue,'N/A') = 'Formerly Limited' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_Former_Indicator,
			   CASE WHEN COALESCE(lepd.CodeValue,'N/A') = 'NotLimited' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_NotEnglisLearner_Indicator,

			   COALESCE(s.EconomicDisadvantaged,0) AS EconomicDisadvantage_Indicator,
	   
			   --entry
			   ssa.EntryDate,
			   dbo.Func_ETL_GetSchoolYear((ssa.EntryDate)) AS EntrySchoolYear, 
			   COALESCE(eglrt.CodeValue,'N/A') AS EntryCode,
       
			   --exit
			   ssa.ExitWithdrawDate,
			   dbo.Func_ETL_GetSchoolYear((ssa.ExitWithdrawDate)) AS ExitWithdrawSchoolYear, 
			   ewt.CodeValue ExitWithdrawCode,              

			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(s.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolCategoryModifiedDate,
			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(ssa.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolTitle1StatusModifiedDate,

				
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (s.LastModifiedDate)
                             , (ssa.LastModifiedDate)                                                    
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      ssa.EntryDate
				END AS ValidFrom,
			   CASE when ssa.ExitWithdrawDate is null then '12/31/9999'  else ssa.ExitWithdrawDate END  AS ValidTo,
			   case when ssa.ExitWithdrawDate is NULL AND EXISTS(SELECT 1 FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.SchoolYearType syt WHERE syt.CurrentSchoolYear = 1 AND syt.SchoolYear = ssa.SchoolYear) then 1 else 0 end AS IsCurrent
			   	
		--select ssa.SchoolYear, ssa.ExitWithdrawDate , case  when ssa.ExitWithdrawDate is NULL and EXISTS(SELECT 1 FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.SchoolYearType syt WHERE syt.CurrentSchoolYear = 1 AND syt.SchoolYear = ssa.SchoolYear)   then 1 else 0 end 
		FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Student s
			INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentSchoolAssociation ssa ON s.StudentUSI = ssa.StudentUSI
			INNER JOIN dbo.DimSchool dschool ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),ssa.SchoolId)   = dschool._sourceKey
			INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor gld  ON ssa.EntryGradeLevelDescriptorId = gld.DescriptorId			
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.EntryGradeLevelReasonType eglrt ON ssa.EntryGradeLevelReasonTypeId = eglrt.EntryGradeLevelReasonTypeId
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.ExitWithdrawTypeDescriptor ewtd ON ssa.ExitWithdrawTypeDescriptorId = ewtd.ExitWithdrawTypeDescriptorId
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor ewtdd ON ewtd.ExitWithdrawTypeDescriptorId = ewtdd.DescriptorId
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.ExitWithdrawType ewt ON ewtd.ExitWithdrawTypeId = ewt.ExitWithdrawTypeId
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentElectronicMail sem ON s.StudentUSI = sem.StudentUSI
																		   AND sem.PrimaryEmailAddressIndicator = 1
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.ElectronicMailType emt ON sem.ElectronicMailTypeId = emt.ElectronicMailTypeId
			INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.EducationOrganization edorg ON ssa.SchoolId = edorg.EducationOrganizationId

			--lunch
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor food ON s.SchoolFoodServicesEligibilityDescriptorId = food.DescriptorId
			--sex
			INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.SexType sex ON s.SexTypeId = sex.SexTypeId
			--state id
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentIdentificationCode sic ON s.StudentUSI = sic.StudentUSI
																							   AND sic.AssigningOrganizationIdentificationCode = 'State' 
			--lep
			LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor lepd ON s.LimitedEnglishProficiencyDescriptorId = lepd.DescriptorId
	
			--races
			LEFT JOIN #StudentRaces sr ON s.StudentUSI = sr.StudentUsi
			
			--homeroom
			LEFT JOIN #StudentHomeRooomByYear shrby ON  s.StudentUSI = shrby.StudentUSI
												   AND ssa.SchoolId = shrby.SchoolId
												   AND ssa.SchoolYear = shrby.SchoolYear
												   AND shrby.RowRankId = 1
	
		WHERE ssa.SchoolYear >= 2019 AND
		     (
			   (s.LastModifiedDate > @LastLoadDate AND s.LastModifiedDate <= @NewLoadDate) --OR
			   --(ssa.LastModifiedDate > @LastLoadDate AND ssa.LastModifiedDate <= @NewLoadDate)			 
			 )
			 
		DROP TABLE #StudentRaces, #StudentHomeRooomByYear;
				
			
		--loading legacy data if it has not been loaded.
		--load types are ignored as this data will only be loaded once.
		IF NOT EXISTS(SELECT 1 
		              FROM dbo.DimStudent 
					  WHERE CHARINDEX('LegacyDW',_sourceKey,1) > 0)
			BEGIN
			    ;WITH HomelessStudentsByYear AS (
				--Sch year 2015:
				  SELECT studentno, 2016 AS schyear
				  FROM [BPSGranary02].[RMUStudentBackup].[dbo].[Homeless2015Final] 
				  WHERE McKinneyVento = 'Y'
				  UNION ALL 
				--Sch year 2016:
				  SELECT studentno, 2017 AS schyear
				  FROM [BPSGranary02].[RMUStudentBackup].[dbo].[Homeless2016Final] 
				  WHERE McKinneyVento = 'Y'  
				  UNION ALL
				--Sch year 2017:
				  SELECT studentno, 2018 AS schyear
				  FROM [BPSGranary02].[RMUStudentBackup].[dbo].[Homeless2017Final] 
				  WHERE McKinneyVento = 'Y'  
				)
			   INSERT INTO Staging.[Student]
				   ([_sourceKey]
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

				   
				   ,StudentMainInfoModifiedDate
	               ,StudentSchoolAssociationModifiedDate

				   ,[ValidFrom]
				   ,[ValidTo]
				   ,[IsCurrent])
			   SELECT DISTINCT
						CONCAT_WS('|','LegacyDW',Convert(NVARCHAR(MAX),s.StudentNo)) AS [_sourceKey],
						null AS [PrimaryElectronicMailAddress],
						null AS [PrimaryElectronicMailTypeDescriptor_CodeValue],
						null AS [PrimaryElectronicMailTypeDescriptor_Description],

						s.StudentNo AS [StudentUniqueId],       
						s.sasid AS StateId,
       
						dschool.SchoolKey,
						dschool.ShortNameOfInstitution,
						dschool.NameOfInstitution,
						s.Grade as GradeLevelDescriptor_CodeValue,
						s.Grade as GradeLevelDescriptor_Description,

						s.FirstName,
						LEFT(LTRIM(s.MiddleName),1) AS MiddleInitial,
						s.MiddleName,	   
						s.LastName AS LastSurname,
						dbo.Func_ETL_GetFullName(s.FirstName,s.MiddleName,s.LastName) AS FullName,
						s.DOB AS BirthDate,
						DATEDIFF(YEAR, s.DOB, GetDate()) AS StudentAge,
						s.YOG AS GraduationSchoolYear,

						s.Homeroom,
						NULL AS HomeroomTeacher,

						CASE 
							WHEN s.Sex = 'M' THEN 'M'
							WHEN s.Sex = 'F' THEN 'F'
							ELSE 'NS' -- not selected
						END AS SexType_Code,
						CASE 
							WHEN s.Sex = 'M' THEN 'Male'
							WHEN s.Sex = 'F' THEN 'Female'
							ELSE 'Not Selected' -- not selected
						END AS SexType_Description,
						CASE WHEN s.Sex = 'M' THEN 1 ELSE 0 END AS SexType_Male_Indicator,
						CASE WHEN s.Sex = 'F' THEN 1 ELSE 0 END AS SexType_Female_Indicator,
						CASE WHEN s.Sex not in ( 'M','F') THEN 1 ELSE 0 END AS SexType_NotSelected_Indicator, -- NON BINARY

						CASE WHEN sdir.IsNatAmer = 1 THEN 'American Indian - Alaskan Native'
							WHEN sdir.IsAsian = 1 THEN 'Asian'
							WHEN sdir.IsBlack = 1 THEN 'Black - African American'
							WHEN sdir.IsPacIsland = 1 THEN 'Native Hawaiian - Pacific Islander'
							WHEN sdir.IsWhite = 1 THEN 'White'
							WHEN sdir.IsHispanic = 1 THEN 'Hispanic'
							ELSE 'Choose Not Respond'
						END AS RaceCode,
						CASE WHEN sdir.IsNatAmer = 1 THEN 'American Indian - Alaskan Native'
							WHEN sdir.IsAsian = 1 THEN 'Asian'
							WHEN sdir.IsBlack = 1 THEN 'Black - African American'
							WHEN sdir.IsPacIsland = 1 THEN 'Native Hawaiian - Pacific Islander'
							WHEN sdir.IsWhite = 1 THEN 'White'
							WHEN sdir.IsHispanic = 1 THEN 'Hispanic'
							ELSE 'Choose Not Respond'
						END AS RaceDescription,
						CASE WHEN sdir.IsNatAmer = 1 THEN 'American Indian - Alaskan Native'
							WHEN sdir.IsAsian = 1 THEN 'Asian'
							WHEN sdir.IsBlack = 1 THEN 'Black - African American'
							WHEN sdir.IsPacIsland = 1 THEN 'Native Hawaiian - Pacific Islander'
							WHEN sdir.IsWhite = 1 THEN 'White'
							WHEN sdir.IsHispanic = 1 THEN 'Hispanic'
							ELSE 'Choose Not Respond'
						END AS StateRaceCode,
						sdir.IsNatAmer AS Race_AmericanIndianAlaskanNative_Indicator,
						sdir.IsAsian AS Race_Asian_Indicator,
						sdir.IsBlack AS Race_BlackAfricaAmerican_Indicator,
						sdir.IsPacIsland AS Race_NativeHawaiianPacificIslander_Indicator,
						sdir.IsWhite AS Race_White_Indicator,
						0 AS Race_MultiRace_Indicator, 
						CASE WHEN sdir.IsNatAmer = 0 AND
									sdir.IsAsian = 0 AND 
									sdir.IsBlack = 0 AND 
									sdir.IsPacIsland = 0 AND
									sdir.IsWhite = 0 AND 
									sdir.IsHispanic = 0 THEN 1 
									ELSE 0
						END AS Race_ChooseNotRespond_Indicator,
						0 AS Race_Other_Indicator,

						CASE WHEN sdir.IsHispanic = 1 THEN 'H' ELSE 'Non-H' END  AS EthnicityCode,
						CASE WHEN sdir.IsHispanic = 1 THEN 'Hispanic' ELSE 'Non Hispanic' END  AS EthnicityDescription,
						sdir.IsHispanic AS EthnicityHispanicLatino_Indicator,
	   
						0 AS Migrant_Indicator,
						CASE WHEN hsby.studentno IS NULL THEN 0 ELSE 1 END AS Homeless_Indicator,	   
						case WHEN COALESCE(s.SnCode,'None') <> 'None' THEN 1  ELSE 0 END  AS IEP_Indicator,
	   
						COALESCE(s.Lep_Status,'N/A') AS LimitedEnglishProficiencyDescriptor_CodeValue,
						COALESCE(s.Lep_Status,'N/A') AS LimitedEnglishProficiencyDescriptor_Description,
						CASE WHEN COALESCE(s.Lep_Status,'N/A') = 'L' THEN 1 ELSE 0 END [LimitedEnglishProficiency_EnglishLearner_Indicator],
						CASE WHEN COALESCE(s.Lep_Status,'N/A') = 'F' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_Former_Indicator,
						CASE WHEN COALESCE(s.Lep_Status,'N/A') = 'N' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_NotEnglisLearner_Indicator,
						CASE WHEN COALESCE(s.foodgroup,'None') <> 'None' THEN 1 ELSE 0 END AS EconomicDisadvantage_Indicator,
       
						--entry	   
						CASE WHEN MONTH(s.entdate) >= 7 THEN 
								DATEADD(YEAR,s.schyear  - YEAR(s.entdate),s.entdate)
							ELSE 
								DATEADD(YEAR,s.schyear + 1  - YEAR(s.entdate),s.entdate)
						END AS EntryDate,

						s.schyear + 1 AS EntrySchoolYear, 
						COALESCE(s.entcode,'N/A') AS EntryCode,
       
						--exit
						CASE WHEN s.schyearsequenceno =  999999 AND s.withdate IS null   THEN '6/30/' + CAST(s.schyear AS NVARCHAR(max)) 
							ELSE s.withdate
						END AS ExitWithdrawDate,
						s.schyear + 1 AS ExitWithdrawSchoolYear, 
						COALESCE(s.withcode,'N/A') AS ExitWithdrawCode,
				
						'07/01/2015' AS SchoolCategoryModifiedDate,
						'07/01/2015' AS SchoolTitle1StatusModifiedDate

						,s.entdate AS ValidFrom
						,COALESCE(s.withdate,s.entdate) AS ValidTo
						,0 IsCurrent
				--select distinct top 1000 *
				FROM [BPSGranary02].[BPSDW].[dbo].[student] s 
					--WHERE schyear IN (2017,2016,2015) AND s.StudentNo = '210191' ORDER BY s.StudentNo, s.entdate
						INNER JOIN [BPSGranary02].[RAEDatabase].[dbo].[studentdir] sdir ON s.StudentNo = sdir.studentno
						INNER JOIN dbo.DimSchool dschool ON  CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.sch))  = dschool._sourceKey	 
						LEFT JOIN HomelessStudentsByYear hsby ON s.StudentNo = hsby.studentno 
															and s.schyear = hsby.schyear
				WHERE s.schyear IN (2017,2016,2015)
						and s.sch between '1000' and '4700'
				ORDER BY s.StudentNo;

			END

		--COMMIT TRANSACTION;		
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

		---- Test whether the transaction is uncommittable.
		--IF XACT_STATE( ) = -1
		--	BEGIN
		--		--The transaction is in an uncommittable state. Rolling back transaction
		--		ROLLBACK TRANSACTION;
		--	END;

		---- Test whether the transaction is committable.
		--IF XACT_STATE( ) = 1
		--	BEGIN
		--		--The transaction is committable. Committing transaction
		--		COMMIT TRANSACTION;
		--	END;
	END CATCH;
END;
GO
