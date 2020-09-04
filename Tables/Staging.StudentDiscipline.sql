CREATE TABLE [Staging].[StudentDiscipline]
(
[StudentDisciplineKey] [bigint] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NULL,
[TimeKey] [int] NULL,
[SchoolKey] [int] NULL,
[DisciplineIncidentKey] [int] NULL,
[ModifiedDate] [datetime] NULL,
[_sourceStudentKey] [int] NULL,
[_sourceTimeKey] [int] NULL,
[_sourceSchoolKey] [int] NULL,
[_sourceDisciplineIncidentKey] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentDiscipline] ADD CONSTRAINT [PK_StagingStudentDiscipline] PRIMARY KEY CLUSTERED  ([StudentDisciplineKey]) ON [PRIMARY]
GO
