SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[View_StudentAttendanceByDay]
AS(
SELECT StudentId, 
       StudentStateId, 
	   FirstName, 
	   LastName, 
	   SchoolName, 
	   AttedanceDate,

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
			   dact.AttendanceEventCategoryDescriptor_CodeValue AS AttendanceType			   
		FROM dbo.[FactStudentAttendanceByDay] fsabd 
			 INNER JOIN dbo.DimStudent ds ON fsabd.StudentKey = ds.StudentKey
			 INNER JOIN dbo.DimTime dt ON fsabd.TimeKey = dt.TimeKey	 
			 INNER JOIN dbo.DimSchool dsc ON fsabd.SchoolKey = dsc.SchoolKey	 
			 INNER JOIN dbo.DimAttendanceEventCategory dact ON fsabd.AttendanceEventCategoryKey = dact.AttendanceEventCategoryKey		
	    WHERE ds.StudentUniqueId = 363896
		--AND dt.SchoolDate = '2019-09-10'

		
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
