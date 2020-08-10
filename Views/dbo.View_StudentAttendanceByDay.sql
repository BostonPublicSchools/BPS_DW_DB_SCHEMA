SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[View_StudentAttendanceByDay]
WITH SCHEMABINDING
AS(
SELECT StudentId, 
       StudentStateId, 
	   FirstName, 
	   LastName, 
	   [DistrictSchoolCode],
	   [UmbrellaSchoolCode],	   
	   SchoolName, 
	   AttedanceDate,
	   SchoolYear,
	   --pivoted from row values	  
	   [Early departure],
	   [Excused Absence],
	   [Unexcused Absence],
	   [No Contact],
	   [In Attendance],
	   [Tardy]
	   
FROM (
		SELECT DISTINCT 
		       ds.StudentUniqueId AS StudentId,
			   ds.StateId AS StudentStateId,
			   ds.FirstName,
			   ds.LastSurname AS LastName,
			   dsc.NameOfInstitution AS SchoolName,
			   dt.SchoolDate AS AttedanceDate, 		
			   dt.SchoolYear,
			   dact.AttendanceEventCategoryDescriptor_CodeValue AS AttendanceType,
		       dsc.DistrictSchoolCode AS DistrictSchoolCode,
		       dsc.UmbrellaSchoolCode AS UmbrellaSchoolCode			 			 			   
		FROM dbo.[FactStudentAttendanceByDay] fsabd 
			 INNER JOIN dbo.DimStudent ds ON fsabd.StudentKey = ds.StudentKey
			 INNER JOIN dbo.DimTime dt ON fsabd.TimeKey = dt.TimeKey	 
			 INNER JOIN dbo.DimSchool dsc ON fsabd.SchoolKey = dsc.SchoolKey	 
			 INNER JOIN dbo.DimAttendanceEventCategory dact ON fsabd.AttendanceEventCategoryKey = dact.AttendanceEventCategoryKey		
	    WHERE 1=1 
		AND ds.StudentUniqueId = 363896
		--AND dt.SchoolDate = '2018-10-26'

		
	) AS SourceTable 
PIVOT 
   (
      count(AttendanceType)
	  FOR AttendanceType IN ([Early departure],
							 [Excused Absence],
							 [Unexcused Absence],
							 [No Contact],
							 [In Attendance],
							 [Tardy]
						)
   ) AS PivotTable
);
GO
