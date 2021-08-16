CREATE TABLE [Staging].[StudentSection]
(
[StudentSectionKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NULL,
[SchoolKey] [int] NULL,
[CourseKey] [int] NULL,
[StaffKey] [int] NULL,
[StudentSectionBeginDate] [date] NOT NULL,
[StudentSectionEndDate] [date] NOT NULL,
[SchoolYear] [int] NOT NULL,
[ModifiedDate] [datetime] NOT NULL,
[_sourceStudentKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceSchoolKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceCourseKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceStaffKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentSection] ADD CONSTRAINT [PK_StagingStudentSection] PRIMARY KEY CLUSTERED  ([StudentSectionKey]) ON [PRIMARY]
GO
