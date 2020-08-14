SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[View_StudentCourseTranscript]
WITH SCHEMABINDING
AS(
SELECT  ds.StudentKey,
		ds.StudentUniqueId AS StudentId,
		ds.StateId AS StudentStateId,
		ds.FirstName,
		ds.LastSurname AS LastName,		
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
