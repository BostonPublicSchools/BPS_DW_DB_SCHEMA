SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[View_StudentCourseGrade]
WITH SCHEMABINDING
AS(
SELECT  fsct.TimeKey,
		fsct.StudentSectionKey,
		fsct.GradingPeriodKey,
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
		dc.LocalCourseCode,
		dc.CourseCode,
		dc.CourseTitle,
		dc.CourseLevelCharacteristicTypeDescriptor_CodeValue AS CourseType,
		dc.SecondaryCourseLevelCharacteristicTypeDescriptor_CodeValue AS MassCore,
		dt.SchoolTermDescriptor_CodeValue AS Term, 		
		dgp.GradingPeriodDescriptor_CodeValue AS GradingPeriod,
		dgp.TotalInstructionalDays AS GradingPeriod_TotalInstructionalDays,
		dgp.PeriodSequence AS GradingPeriod_PeriodSequence,
		dstaff.StaffUniqueId AS TeacherStaffId,
		dstaff.FirstName AS TeacherFirstName,
		dstaff.LastSurname AS TeacherLastName,
		fsct.LetterGradeEarned,
		fsct.NumericGradeEarned
FROM dbo.FactStudentCourseGrade fsct		
		INNER JOIN dbo.DimTime dt ON fsct.TimeKey = dt.TimeKey	 		
		INNER JOIN dbo.DimStudentSection dst_sect ON fsct.StudentSectionKey = dst_sect.StudentSectionKey		
		INNER JOIN dbo.DimStudent ds ON dst_sect.StudentKey = ds.StudentKey
		INNER JOIN dbo.DimSchool dsc ON dst_sect.SchoolKey = dsc.SchoolKey		
		INNER JOIN dbo.DimCourse dc ON dst_sect.CourseKey = dc.CourseKey		
		INNER JOIN dbo.DimStaff dstaff ON dst_sect.StaffKey = dstaff.StaffKey		
		INNER JOIN dbo.DimGradingPeriod dgp ON fsct.GradingPeriodKey = dgp.GradingPeriodKey		
);

GO
CREATE UNIQUE CLUSTERED INDEX [CLU_View_StudentCourseGrade] ON [dbo].[View_StudentCourseGrade] ([TimeKey], [StudentSectionKey], [GradingPeriodKey]) ON [PRIMARY]
GO
