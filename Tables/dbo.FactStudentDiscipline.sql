CREATE TABLE [dbo].[FactStudentDiscipline]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[DisciplineIncidentKey] [int] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [PK_FactStudentDiscipline] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [SchoolKey], [DisciplineIncidentKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_DisciplineIncidentKey] FOREIGN KEY ([DisciplineIncidentKey]) REFERENCES [dbo].[DimDisciplineIncident] ([DisciplineIncidentKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
