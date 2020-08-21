SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[View_StudentRoster]
WITH SCHEMABINDING
AS(
SELECT  
		ds.StudentKey AS StudentKey,
		ds.StudentUniqueId AS StudentId,
		ds.StateId AS StudentStateId,
		ds.FirstName,
		ds.MiddleName,
		ds.MiddleInitial,
		ds.FullName,
		ds.LastSurname AS LastName,
		ds.PrimaryElectronicMailAddress AS StudentEmail,
		ds.GradeLevelDescriptor_CodeValue AS GradeLevel,
		ds.BirthDate,
		ds.StudentAge,
		ds.[GraduationSchoolYear],
		dsc.DistrictSchoolCode AS DistrictSchoolCode,
		dsc.StateSchoolCode AS StateSchoolCode,
		dsc.UmbrellaSchoolCode AS SchoolUmbrellaCode,
		dsc.NameOfInstitution AS SchoolName,
		
		ds.Homeroom,
		ds.HomeroomTeacher,
		ds.SexType_Code AS Sex,
		ds.[SexType_Male_Indicator],
	    ds.[SexType_Female_Indicator],
	    ds.[SexType_NotSelected_Indicator],


		ds.StateRaceCode AS StateRace,
		ds.Race_AmericanIndianAlaskanNative_Indicator,
		ds.Race_Asian_Indicator,
		ds.Race_BlackAfricaAmerican_Indicator,
		ds.Race_NativeHawaiianPacificIslander_Indicator,
		ds.Race_White_Indicator,
		ds.Race_MultiRace_Indicator,
		ds.Race_ChooseNotRespond_Indicator,
		ds.Race_Other_Indicator,

		ds.[EthnicityCode],
		ds.[EthnicityHispanicLatino_Indicator],
		ds.[Migrant_Indicator],
		ds.Homeless_Indicator,
		ds.IEP_Indicator,		
		ds.[English_Learner_Code_Value] AS LEPCode,
		ds.[English_Learner_Indicator],
		ds.[Former_English_Learner_Indicator],
		ds.[Never_English_Learner_Indicator],
		ds.[EconomicDisadvantage_Indicator],

		ds.EntryDate,
		ds.EntrySchoolYear,
		ds.EntryCode,

		ds.ExitWithdrawDate,
		ds.ExitWithdrawSchoolYear,
		ds.ExitWithdrawCode,

		ds.ValidFrom,
		ds.ValidTo,
		ds.IsCurrent
		
		
FROM dbo.DimStudent ds 		
     INNER JOIN dbo.DimSchool dsc ON ds.SchoolKey = dsc.SchoolKey
		
);

GO

CREATE UNIQUE CLUSTERED INDEX [CLU_View_StudentRoster] ON [dbo].[View_StudentRoster] ([StudentKey]) ON [PRIMARY]
GO
