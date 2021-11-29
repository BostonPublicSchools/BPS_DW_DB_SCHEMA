CREATE TABLE [dbo].[FactStudentDiscipline]
(
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[DisciplineIncidentKey] [int] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [PK_FactStudentDiscipline] PRIMARY KEY CLUSTERED ([StudentKey], [TimeKey], [SchoolKey], [DisciplineIncidentKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [CSI_FactStudentDiscipline] ON [dbo].[FactStudentDiscipline] ([StudentKey], [TimeKey], [SchoolKey], [DisciplineIncidentKey], [LineageKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_DisciplineIncidentKey] FOREIGN KEY ([DisciplineIncidentKey]) REFERENCES [dbo].[DimDisciplineIncident] ([DisciplineIncidentKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
