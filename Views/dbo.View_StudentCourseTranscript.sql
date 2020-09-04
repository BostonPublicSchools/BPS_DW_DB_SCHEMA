SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[View_StudentCourseTranscript]
WITH SCHEMABINDING
AS(
SELECT  fsct.StudentKey,
        fsct.TimeKey,
		fsct.SchoolKey,
		fsct.CourseKey,
		ds.StudentUniqueId AS StudentId,
		ds.StateId AS StudentStateId,
		ds.FirstName,
		ds.LastSurname AS LastName,		
		case ds.GradeLevelDescriptor_CodeValue 
			when 'Eighth grade' then 	'08'
			when 'Eleventh grade' then 	'11'
			when 'Fifth grade' then 	'05'
			when 'First grade' then 	'01'
			when 'Fourth grade' then 	'04'
			when 'Kindergarten'  then 'K'
			when 'Ninth grade' then 	'09'
			when 'Preschool/Prekindergarten' then 'PK'
			when 'Second grade' then 	'02'
			when 'Seventh grade' then 	'07'
			when 'Sixth grade' then 	'06'
			when 'Tenth grade' then 	'10'
			when 'Third grade' then 	'03'
			when 'Twelfth grade' then 	'12'
			ELSE ds.GradeLevelDescriptor_CodeValue 
		end  AS GradeLevel,
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

		dsc.DistrictSchoolCode AS DistrictSchoolCode,
		dsc.UmbrellaSchoolCode AS UmbrellaSchoolCode,
		dsc.NameOfInstitution AS SchoolName,
		dc.CourseCode,
		dc.CourseTitle,
		dc.CourseLevelCharacteristicTypeDescriptor_CodeValue AS CourseType,
		dc.SecondaryCourseLevelCharacteristicTypeDescriptor_CodeValue AS MassCore,
		dt.SchoolTermDescriptor_CodeValue AS Term, 		
		fsct.EarnedCredits,
		fsct.PossibleCredits,
		fsct.FinalLetterGradeEarned,
		fsct.FinalNumericGradeEarned
FROM dbo.FactStudentCourseTranscript fsct
		INNER JOIN dbo.DimStudent ds ON fsct.StudentKey = ds.StudentKey
		INNER JOIN dbo.DimTime dt ON fsct.TimeKey = dt.TimeKey	 
		INNER JOIN dbo.DimSchool dsc ON fsct.SchoolKey = dsc.SchoolKey		
		INNER JOIN dbo.DimCourse dc ON fsct.CourseKey = dc.CourseKey		
);

GO

CREATE UNIQUE CLUSTERED INDEX [CLU_View_StudentCourseTranscript] ON [dbo].[View_StudentCourseTranscript] ([StudentKey], [TimeKey], [SchoolKey], [CourseKey]) ON [PRIMARY]
GO
