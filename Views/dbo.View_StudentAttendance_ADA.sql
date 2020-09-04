SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[View_StudentAttendance_ADA]
WITH SCHEMABINDING
AS (
     select  StudentId, 
			 StudentStateId, 
			 FirstName, 
			 LastName, 
			 [DistrictSchoolCode],
			 [UmbrellaSchoolCode],	   
			 SchoolName, 	   
			 SchoolYear,
			 [NumberOfDaysPresent]
			,[NumberOfDaysAbsent]
			,[NumberOfDaysAbsentUnexcused]
			,[NumberOfDaysMembership]
			,[ADA]
	 FROM [Derived].[StudentAttendanceADA]
	 
);
GO

CREATE UNIQUE CLUSTERED INDEX [CLU_View_StudentAttendance_ADA] ON [dbo].[View_StudentAttendance_ADA] ([StudentId], [DistrictSchoolCode], [SchoolYear]) ON [PRIMARY]
GO
