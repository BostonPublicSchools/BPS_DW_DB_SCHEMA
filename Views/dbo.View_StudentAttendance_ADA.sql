SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[View_StudentAttendance_ADA]
WITH SCHEMABINDING
AS (
	 SELECT DISTINCT 
		   v_sabd.StudentId, 
		   v_sabd.StudentStateId, 
		   v_sabd.FirstName, 
		   v_sabd.LastName, 
		   v_sabd.[DistrictSchoolCode],
		   v_sabd.[UmbrellaSchoolCode],	   
		   v_sabd.SchoolName, 	   
		   v_sabd.SchoolYear,	   
		   SUM(v_sabd.[In Attendance]) OVER (PARTITION BY v_sabd.StudentId,v_sabd.SchoolName,v_sabd.SchoolYear) AS NumberOfDaysPresent,
		   SUM(CASE WHEN v_sabd.[In Attendance] = 1 THEN 0 ELSE 1 end) OVER (PARTITION BY v_sabd.StudentId,v_sabd.SchoolName,v_sabd.SchoolYear) AS NumberOfDaysAbsent,
		   SUM(v_sabd.[Unexcused Absence]) OVER (PARTITION BY v_sabd.StudentId,v_sabd.SchoolName,v_sabd.SchoolYear) AS NumberOfDaysAbsentUnexcused,
		   COUNT(*) OVER (PARTITION BY v_sabd.StudentId,v_sabd.SchoolName,v_sabd.SchoolYear) AS NumberOfDaysMembership,
		   SUM(v_sabd.[In Attendance]) OVER (PARTITION BY v_sabd.StudentId,v_sabd.SchoolName,v_sabd.SchoolYear) / CONVERT(Float,COUNT(*) OVER (PARTITION BY v_sabd.StudentId,v_sabd.SchoolName,v_sabd.SchoolYear)) * 100 AS ADA
	--select *
	FROM dbo.View_StudentAttendanceByDay v_sabd
);
GO
