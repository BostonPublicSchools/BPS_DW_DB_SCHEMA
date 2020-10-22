CREATE TABLE [Staging].[StudentDiscipline]
(
[StudentDisciplineKey] [bigint] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NULL,
[TimeKey] [int] NULL,
[SchoolKey] [int] NULL,
[DisciplineIncidentKey] [int] NULL,
[ModifiedDate] [datetime] NULL,
[_sourceStudentKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceTimeKey] [date] NULL,
[_sourceSchoolKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceDisciplineIncidentKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentDiscipline] ADD CONSTRAINT [PK_StagingStudentDiscipline] PRIMARY KEY CLUSTERED  ([StudentDisciplineKey]) ON [PRIMARY]
GO
