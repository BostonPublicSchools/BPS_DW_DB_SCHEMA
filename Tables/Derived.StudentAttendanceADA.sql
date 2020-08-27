CREATE TABLE [Derived].[StudentAttendanceADA]
(
[StudentId] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentStateId] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FirstName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LastName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DistrictSchoolCode] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UmbrellaSchoolCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolName] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolYear] [int] NOT NULL,
[NumberOfDaysPresent] [int] NOT NULL,
[NumberOfDaysAbsent] [int] NOT NULL,
[NumberOfDaysAbsentUnexcused] [int] NOT NULL,
[NumberOfDaysMembership] [int] NOT NULL,
[ADA] [float] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StudentAttendanceADA] ADD CONSTRAINT [PK_Derived_StudentAttendanceADA] PRIMARY KEY CLUSTERED  ([StudentId], [DistrictSchoolCode], [SchoolYear]) ON [PRIMARY]
GO
