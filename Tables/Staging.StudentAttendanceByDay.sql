CREATE TABLE [Staging].[StudentAttendanceByDay]
(
[StudentAttendanceByDayKey] [bigint] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NULL,
[TimeKey] [int] NULL,
[SchoolKey] [int] NULL,
[AttendanceEventCategoryKey] [int] NULL,
[AttendanceEventReason] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ModifiedDate] [datetime] NULL,
[_sourceStudentKey] [int] NULL,
[_sourceTimeKey] [int] NULL,
[_sourceSchoolKey] [int] NULL,
[_sourceAttendanceEventCategoryKey] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentAttendanceByDay] ADD CONSTRAINT [PK_StagingStudentAttendanceByDay] PRIMARY KEY CLUSTERED  ([StudentAttendanceByDayKey]) ON [PRIMARY]
GO
