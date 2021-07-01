CREATE TABLE [Staging].[StudentSection]
(
[StudentSectionKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[CourseKey] [int] NOT NULL,
[StaffKey] [int] NOT NULL,
[StudentSectionBeginDate] [date] NOT NULL,
[StudentSectionEndDate] [date] NOT NULL,
[SchoolYear] [int] NOT NULL,
[ModifiedDate] [datetime] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentSection] ADD CONSTRAINT [PK_StagingStudentSection] PRIMARY KEY CLUSTERED  ([StudentSectionKey]) ON [PRIMARY]
GO
