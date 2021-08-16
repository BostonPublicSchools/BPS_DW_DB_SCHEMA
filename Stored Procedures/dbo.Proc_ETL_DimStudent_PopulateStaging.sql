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

		
		TRUNCATE TABLE Staging.[Student]

		--DECLARE @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate();
		SELECT DISTINCT s.StudentUSI INTO #StudentsWithChanges
		FROM  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student s		      
		      INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSchoolAssociation ssa ON s.StudentUSI = ssa.StudentUSI
        WHERE  ssa.SchoolYear >= 2019 AND
			   (
				(s.LastModifiedDate > @LastLoadDate AND s.LastModifiedDate <= @NewLoadDate) OR
				(ssa.LastModifiedDate > @LastLoadDate AND ssa.LastModifiedDate <= @NewLoadDate)						
			   )			 
		


		
		SELECT DISTINCT 
			   s.StudentUSI,			   
			   COUNT(sr.StudentUSI) AS RaceCount,
			   STRING_AGG(d.CodeValue,',') AS RaceCodes,
			   STRING_AGG(d.Description,',') AS RaceDescriptions,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr 
			                          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId
								 WHERE s.StudentUSI = sr.StudentUSI
								 AND d.CodeValue = 'American Indian - Alaska Native') THEN 1
			   ELSE 
				   0	             
			   END AS Race_AmericanIndianAlaskanNative_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr 
			                          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId
								 WHERE s.StudentUSI = sr.StudentUSI
								 AND d.CodeValue = 'Asian') THEN 1
			   ELSE 
				   0	             
			   END AS Race_Asian_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr 
			                          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId
								 WHERE s.StudentUSI = sr.StudentUSI
								 AND d.CodeValue = 'Black - African American') THEN 1
			   ELSE 
				   0	             
			   END AS Race_BlackAfricaAmerican_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr 
			                          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId
								 WHERE s.StudentUSI = sr.StudentUSI
								 AND d.CodeValue = 'Native Hawaiian - Pacific Islander') THEN 1
			   ELSE 
				   0	             
			   END AS Race_NativeHawaiianPacificIslander_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr 
			                          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId
								 WHERE s.StudentUSI = sr.StudentUSI
								 AND d.CodeValue = 'White') THEN 1
			   ELSE 
				   0	             
			   END AS Race_White_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr 
			                          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId
								 WHERE s.StudentUSI = sr.StudentUSI
								 AND d.CodeValue = 'Choose Not to Respond') THEN 1
			   ELSE 
				   0	             
			   END AS Race_ChooseNotRespond_Indicator,
			   CASE WHEN EXISTS (SELECT 1 
								 FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr 
			                          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId
								 WHERE s.StudentUSI = sr.StudentUSI
								 AND d.CodeValue = 'Other') THEN 1
			   ELSE 
				   0	             
			   END AS Race_Other_Indicator  into #StudentRaces    
        --select * 
		FROM  #StudentsWithChanges s
			  LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationRace sr  ON s.StudentUSI = sr.StudentUSI		
			  LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON sr.RaceDescriptorId = d.DescriptorId	    
		GROUP BY s.StudentUSI
			
			
		 
		;WITH StudentHomeRooomByYear AS
		(
			SELECT DISTINCT std_sa.StudentUSI, 
							std_sa.SchoolYear, 
							std_sa.SchoolId,  
							std_sa.LocalCourseCode AS HomeRoom,
							dbo.Func_ETL_GetFullName(staff.FirstName,staff.MiddleName,staff.LastSurname) AS HomeRoomTeacher,
							ROW_NUMBER() OVER (PARTITION BY std_sa.StudentUSI, 
															std_sa.SchoolYear, 
															std_sa.SchoolId ORDER BY staff_sa.BeginDate DESC) AS RowRankId 
			FROM  #StudentsWithChanges s
			      INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSectionAssociation std_sa ON s.StudentUSI = std_sa.StudentUSI			
				  INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSectionAssociation staff_sa  ON std_sa.SectionIdentifier = staff_sa.SectionIdentifier
																										AND std_sa.SchoolYear = staff_sa.SchoolYear
				 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff staff on staff_sa.StaffUSI = staff.StaffUSI
			WHERE std_sa.HomeroomIndicator = 1
				 AND std_sa.SchoolYear >= 2019
				 AND std_sa.EndDate > GETDATE()				 
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
				   ,[SexType_NonBinary_Indicator]
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
                   
				   ,[_sourceSchoolKey]

				   ,[ValidFrom]
				   ,[ValidTo]
				   ,[IsCurrent])
		--DECLARE @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate();
        SELECT distinct
			   CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StudentUniqueId)) AS [_sourceKey],
			   seoae.ElectronicMailAddress AS [PrimaryElectronicMailAddress],
			   seoae_d.CodeValue AS [PrimaryElectronicMailTypeDescriptor_CodeValue],
			   seoae_d.Description AS [PrimaryElectronicMailTypeDescriptor_Description],
			   s.StudentUniqueId,       
			   (SELECT TOP 1  sic.IdentificationCode 
			    FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociationStudentIdentificationCode sic 
			          INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor sicd ON sic.[StudentIdentificationSystemDescriptorId] = sicd.DescriptorId
																					AND sicd.CodeValue = 'State'
				WHERE  s.StudentUSI = sic.StudentUSI
			    ) AS StateId,
       
			   NULL AS SchoolKey,
			   NULL AS ShortNameOfInstitution,
			   NULL AS NameOfInstitution,
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
					WHEN sexd.CodeValue  = 'Male' THEN 'M'
					WHEN sexd.CodeValue  = 'Female' THEN 'F'
					WHEN sexd.CodeValue  = 'NB' THEN 'Non-Binary' -- todo: update code when BPS is ready
					ELSE 'NS' -- not selected
			   END AS SexType_Code,
			   COALESCE(sexd.Description,'Not Selected') AS SexType_Description,
			   CASE WHEN sexd.CodeValue  = 'Male' THEN 1 ELSE 0 END AS SexType_Male_Indicator,
			   CASE WHEN sexd.CodeValue  = 'Female' THEN 1 ELSE 0 END AS SexType_Female_Indicator,
			   CASE WHEN sexd.CodeValue = 'NB' THEN 1 ELSE 0 END AS SexType_NonBinary_Indicator, -- todo: update code when BPS is ready
			   CASE WHEN sexd.CodeValue  = 'Not Selected' THEN 1 ELSE 0 END AS SexType_NotSelected_Indicator,                
			   COALESCE(sr.RaceCodes,'N/A') AS RaceCode,	   
			   COALESCE(sr.RaceDescriptions,'N/A') AS RaceDescription,
			   CASE WHEN sr.RaceCount > 1 AND COALESCE(seoa.HispanicLatinoEthnicity,0) = 0 THEN 'Multirace' 
					WHEN seoa.HispanicLatinoEthnicity = 1 THEN 'Latinx'
					ELSE COALESCE(sr.RaceCodes,'N/A')
			   END AS StateRaceCode,

			   COALESCE(sr.Race_AmericanIndianAlaskanNative_Indicator,0) AS Race_AmericanIndianAlaskanNative_Indicator,
			   COALESCE(sr.Race_Asian_Indicator,0) AS Race_Asian_Indicator ,
			   COALESCE(sr.Race_BlackAfricaAmerican_Indicator,0) AS Race_BlackAfricaAmerican_Indicator ,
			   COALESCE(sr.Race_NativeHawaiianPacificIslander_Indicator,0) AS Race_NativeHawaiianPacificIslander_Indicator ,
			   COALESCE(sr.Race_White_Indicator,0) AS Race_White_Indicator ,
			   
			   
			   CASE WHEN sr.RaceCount > 1 AND COALESCE(seoa.HispanicLatinoEthnicity,0) = 0 THEN 1 ELSE 0 END AS Race_MultiRace_Indicator, 
			   sr.Race_ChooseNotRespond_Indicator,
			   sr.Race_Other_Indicator,

			   CASE WHEN seoa.HispanicLatinoEthnicity = 1 THEN 'L' ELSE 'Non-L' END  AS EthnicityCode,
			   CASE WHEN seoa.HispanicLatinoEthnicity = 1 THEN 'Latinx' ELSE 'Non Latinx' END  AS EthnicityDescription,
			   COALESCE(seoa.HispanicLatinoEthnicity,0) AS EthnicityHispanicLatino_Indicator,

			   CASE WHEN EXISTS (
								   SELECT 1
								   FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.[StudentProgramAssociationService] spas
										INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON spas.ProgramTypeDescriptorId = d.DescriptorId 
																											   AND CHARINDEX('Migrant', d.CodeValue ,1) > 1
								   WHERE spas.StudentUSI = s.StudentUSI									 
										 AND GETDATE() BETWEEN spas.BeginDate AND COALESCE(spas.ServiceEndDate,'12/31/9999')
							   ) THEN 1 ELSE 0 End AS Migrant_Indicator,
			   CASE WHEN EXISTS (
							       SELECT 1
								   FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.[StudentProgramAssociationService] spas
										INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d ON spas.ProgramTypeDescriptorId = d.DescriptorId 
																											   AND CHARINDEX('Homeless', d.CodeValue ,1) > 1
								   WHERE spas.StudentUSI = s.StudentUSI									 
										 AND GETDATE() BETWEEN spas.BeginDate AND COALESCE(spas.ServiceEndDate,'12/31/9999')
						   ) THEN 1 ELSE 0 End AS Homeless_Indicator,
			   CASE WHEN EXISTS (  SELECT 1
										FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSpecialEducationProgramAssociationSpecialEducationProgramService spas
											INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d
												ON spas.ProgramTypeDescriptorId = d.DescriptorId
												   AND CHARINDEX('504 Plan', d.CodeValue, 1) = 0
											INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[studentindividualeducationplan].[StudentSpecialEducationProgramAssociationExtension] sspe
												ON sspe.StudentUSI = spas.StudentUSI
												   AND spas.ProgramEducationOrganizationId = sspe.ProgramEducationOrganizationId
												   AND spas.ProgramName = sspe.ProgramName
												   AND spas.ProgramTypeDescriptorId = sspe.ProgramTypeDescriptorId
												   AND spas.BeginDate = sspe.BeginDate
										WHERE spas.StudentUSI = s.StudentUSI
											  AND GETDATE()
											  BETWEEN spas.BeginDate AND COALESCE(spas.ServiceEndDate, '12/31/9999')
											  AND sspe.IEPExitDate IS NULL) THEN 1 ELSE 0 END AS IEP_Indicator,
	   
			   COALESCE(lepd.CodeValue,'N/A') AS LimitedEnglishProficiencyDescriptor_CodeValue,
			   COALESCE(lepd.CodeValue,'N/A') AS LimitedEnglishProficiencyDescriptor_Description,
			   CASE WHEN COALESCE(lepd.CodeValue,'N/A') = 'Limited' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_EnglishLearner_Indicator,
			   CASE WHEN COALESCE(lepd.CodeValue,'N/A') = 'Formerly Limited' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_Former_Indicator,
			   CASE WHEN COALESCE(lepd.CodeValue,'N/A') = 'NotLimited' THEN 1 ELSE 0 END AS LimitedEnglishProficiency_NotEnglisLearner_Indicator,

			   --COALESCE(s.EconomicDisadvantaged,0) AS EconomicDisadvantage_Indicator,
			   0 AS EconomicDisadvantage_Indicator, -- todo:review with bps team. Reviewed with BPS team and this is still pending. -- 
			   --StudentEducationOrganizationAssociation, StudentEducationOrganizationAssociationStudentCharacteristic,  
			   --SELECT * FROM edfi.Descriptor WHERE Namespace like '%uri://ed-fi.org/StudentCharacteristicDescriptor%'
	

			   --entry
			   ssa.EntryDate,
			   dbo.Func_ETL_GetSchoolYear((ssa.EntryDate)) AS EntrySchoolYear, 
			   COALESCE(eglrtd.CodeValue,'N/A') AS EntryCode,
       
			   --exit
			   ssa.ExitWithdrawDate,
			   dbo.Func_ETL_GetSchoolYear((ssa.ExitWithdrawDate)) AS ExitWithdrawSchoolYear, 
			   ewtdd.CodeValue ExitWithdrawCode,              

			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(s.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolCategoryModifiedDate,
			   CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(ssa.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolTitle1StatusModifiedDate,

			   CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),ssa.SchoolId)) AS [_sourceSchoolKey],
				
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
			   CASE WHEN ssa.ExitWithdrawDate is NULL OR ssa.ExitWithdrawDate >= GETDATE() then '12/31/9999'  else ssa.ExitWithdrawDate END  AS ValidTo,
			   CASE WHEN (ssa.ExitWithdrawDate is NULL OR ssa.ExitWithdrawDate >= GETDATE()) 
			             AND 
						 EXISTS(SELECT 1 
						        FROM  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.SchoolYearType syt 
								WHERE syt.CurrentSchoolYear = 1 
								  AND syt.SchoolYear = ssa.SchoolYear) then 1 
                     ELSE 0 
			   END AS IsCurrent
			   
		--select distinct s.StudentUSI,*
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student s
		    INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentEducationOrganizationAssociation seoa ON s.StudentUSI = seoa.StudentUSI		    
			INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSchoolAssociation ssa ON s.StudentUSI = ssa.StudentUSI		    
			INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor gld  ON ssa.EntryGradeLevelDescriptorId = gld.DescriptorId		
			LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor eglrtd ON ssa.[EntryGradeLevelReasonDescriptorId] = eglrtd.DescriptorId
			LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.ExitWithdrawTypeDescriptor ewtd ON ssa.ExitWithdrawTypeDescriptorId = ewtd.ExitWithdrawTypeDescriptorId
			LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor ewtdd ON ewtd.ExitWithdrawTypeDescriptorId = ewtdd.DescriptorId
			
			LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].[edfi].[StudentEducationOrganizationAssociationElectronicMail] seoae ON s.StudentUSI = seoae.StudentUSI
			LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor seoae_d ON seoae.ElectronicMailTypeDescriptorId = seoae_d.DescriptorId 
			                                                                             AND seoae_d.CodeValue = 'Primary' 																		   
	
			INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.EducationOrganization edorg ON ssa.SchoolId = edorg.EducationOrganizationId
						
			--sex
			LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor sexd ON seoa.SexDescriptorId = sexd.DescriptorId

			
			--lep
			LEFT JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor lepd ON seoa.LimitedEnglishProficiencyDescriptorId = lepd.DescriptorId 

			--races
			LEFT JOIN #StudentRaces sr ON s.StudentUSI = sr.StudentUsi
			
			--homeroom
			LEFT JOIN StudentHomeRooomByYear shrby ON  s.StudentUSI = shrby.StudentUSI
												   AND ssa.SchoolId = shrby.SchoolId
												   AND ssa.SchoolYear = shrby.SchoolYear
												   AND shrby.RowRankId = 1
	
		WHERE ssa.SchoolYear >= 2019 and
		     (
			   (s.LastModifiedDate > @LastLoadDate AND s.LastModifiedDate <= @NewLoadDate) OR
			   (ssa.LastModifiedDate > @LastLoadDate AND ssa.LastModifiedDate <= @NewLoadDate)			 
			 )
			 
		DROP TABLE #StudentRaces, #StudentsWithChanges;
				
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
				   ,[SexType_NonBinary_Indicator]
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

				   ,[_sourceSchoolKey]

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
       
						NULL AS SchoolKey,
						edorg.ShortNameOfInstitution,
						edorg.NameOfInstitution,
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
							WHEN s.Sex = 'NB' THEN 'Non-Binary'
							ELSE 'Not Selected' -- not selected
						END AS SexType_Description,
						CASE WHEN s.Sex = 'M' THEN 1 ELSE 0 END AS SexType_Male_Indicator,
						CASE WHEN s.Sex = 'F' THEN 1 ELSE 0 END AS SexType_Female_Indicator, 
						CASE WHEN s.Sex = 'NB' THEN 1 ELSE 0 END AS SexType_NonBinary_Indicator, -- todo: update code when BPS is ready
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
						CASE WHEN s.schyearsequenceno =  999999 AND s.withdate IS null   THEN '6/30/' + CAST(s.schyear + 1 AS NVARCHAR(max)) 
							ELSE s.withdate
						END AS ExitWithdrawDate,
						s.schyear + 1 AS ExitWithdrawSchoolYear, 
						COALESCE(s.withcode,'N/A') AS ExitWithdrawCode,
				
						'07/01/2015' AS SchoolCategoryModifiedDate,
						'07/01/2015' AS SchoolTitle1StatusModifiedDate,

						CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.sch)) AS [_sourceSchoolKey],

						CASE WHEN MONTH(s.entdate) >= 7 THEN 
								DATEADD(YEAR,s.schyear  - YEAR(s.entdate),s.entdate)
							ELSE 
								DATEADD(YEAR,s.schyear + 1  - YEAR(s.entdate),s.entdate)
						END AS ValidFrom,
						CASE WHEN s.schyearsequenceno =  999999 AND s.withdate IS null   THEN '6/30/' + CAST(s.schyear + 1 AS NVARCHAR(max)) 
						      WHEN s.schyearsequenceno <>  999999 AND s.withdate IS null   THEN s.entdate
							  ELSE s.withdate
						END AS ValidTo
						,0 IsCurrent
				--select distinct top 1000 *
				FROM [BPSGranary02].[BPSDW].[dbo].[student] s 
					--WHERE schyear IN (2017,2016,2015) AND s.StudentNo = '210191' ORDER BY s.StudentNo, s.entdate
						INNER JOIN [BPSGranary02].[RAEDatabase].[dbo].[studentdir] sdir ON s.StudentNo = sdir.studentno		
						INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.EducationOrganization edorg ON s.sch = edorg.EducationOrganizationId
						LEFT JOIN HomelessStudentsByYear hsby ON s.StudentNo = hsby.studentno 
															and s.schyear = hsby.schyear
				WHERE s.schyear IN (2017,2016,2015)
						and s.sch between '1000' and '4700'
				ORDER BY s.StudentNo;
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
