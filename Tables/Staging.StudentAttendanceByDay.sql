CREATE TABLE [Staging].[StudentAttendanceByDay]
(
[StudentAttendanceByDayKey] [bigint] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NULL,
[TimeKey] [int] NULL,
[SchoolKey] [int] NULL,
[AttendanceEventCategoryKey] [int] NULL,
[AttendanceEventReason] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ModifiedDate] [datetime] NULL,
[_sourceStudentKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceTimeKey] [date] NULL,
[_sourceSchoolKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceAttendanceEventCategoryKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentAttendanceByDay] ADD CONSTRAINT [PK_StagingStudentAttendanceByDay] PRIMARY KEY CLUSTERED  ([StudentAttendanceByDayKey]) ON [PRIMARY]
GO
