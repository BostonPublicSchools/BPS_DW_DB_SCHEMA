SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[View_StudentDiscipline]
AS(
SELECT DISTINCT 
		ds.StudentUniqueId AS StudentId,
		ds.StateId AS StudentStateId,
		ds.FirstName,
		ds.LastSurname AS LastName,
		dsc.NameOfInstitution AS SchoolName,
		dt.SchoolDate AS IncidentDate, 		
		ddi.IncidentTime,
		ddi.IncidentDescription,
		ddi.BehaviorDescriptor_CodeValue AS IncidentType,
		ddi.LocationDescriptor_CodeValue AS IncidentLocation,
		ddi.DisciplineDescriptor_CodeValue AS IncidentAction ,
		ddi.ReporterDescriptor_CodeValue AS IncidentReporter,
		ddi.DisciplineDescriptor_ISS_Indicator AS IsISS,
		ddi.DisciplineDescriptor_OSS_Indicator AS IsOSS
FROM dbo.FactStudentDiscipline fsd 
		INNER JOIN dbo.DimStudent ds ON fsd.StudentKey = ds.StudentKey
		INNER JOIN dbo.DimTime dt ON fsd.TimeKey = dt.TimeKey	 
		INNER JOIN dbo.DimSchool dsc ON fsd.SchoolKey = dsc.SchoolKey	 
		INNER JOIN dbo.DimDisciplineIncident ddi ON fsd.DisciplineIncidentKey = ddi.DisciplineIncidentKey		
);
GO
DECLARE @xp int
SELECT @xp=2

GO
