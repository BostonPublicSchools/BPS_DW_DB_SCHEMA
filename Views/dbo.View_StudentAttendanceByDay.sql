SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[View_StudentAttendanceByDay]
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
			dt.SchoolDate AS AttedanceDate, 		
			dt.SchoolYear,
			sabd.[EarlyDeparture],
			sabd.[ExcusedAbsence],
			sabd.[UnexcusedAbsence],
			sabd.[NoContact],
			sabd.[InAttendance]
	FROM Derived.[StudentAttendanceByDay] sabd 
			INNER JOIN dbo.DimStudent ds ON sabd.StudentKey = ds.StudentKey
			INNER JOIN dbo.DimTime dt ON sabd.TimeKey = dt.TimeKey	 
			INNER JOIN dbo.DimSchool dsc ON sabd.SchoolKey = dsc.SchoolKey	 			 
	WHERE 1=1 
	--AND ds.StudentUniqueId = 341888
	--AND dt.SchoolDate = '2018-10-26'
);
GO

CREATE UNIQUE CLUSTERED INDEX [CLU_View_StudentAttendanceByDay] ON [dbo].[View_StudentAttendanceByDay] ([StudentKey], [AttedanceDate]) ON [PRIMARY]
GO
