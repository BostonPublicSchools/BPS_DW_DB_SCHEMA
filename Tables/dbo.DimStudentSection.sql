CREATE TABLE [dbo].[DimStudentSection]
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
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[IsLatest] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimStudentSection] ADD CONSTRAINT [PK_DimStudentSection] PRIMARY KEY CLUSTERED  ([StudentSectionKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [DimStudentSection_CoveringIndex] ON [dbo].[DimStudentSection] ([_sourceKey], [ValidFrom], [ValidTo]) INCLUDE ([StudentSectionKey]) ON [PRIMARY]
GO
