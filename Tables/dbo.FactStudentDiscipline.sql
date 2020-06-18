CREATE TABLE [dbo].[FactStudentDiscipline]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[IncidentTime] [time] NOT NULL,
[DisciplineIncidentBehaviorKey] [int] NOT NULL,
[DisciplineIncidentLocationKey] [int] NOT NULL,
[DisciplineIncidentActionKey] [int] NOT NULL,
[DisciplineIncidentReporterTypeKey] [int] NOT NULL,
[IncidentReporterName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReportedToLawEnforcement_Indicator] [bit] NOT NULL,
[IncidentCost] [money] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [PK_FactStudentDiscipline] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [SchoolKey], [IncidentTime]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_DisciplineIncidentActionKey] FOREIGN KEY ([DisciplineIncidentActionKey]) REFERENCES [dbo].[DimDisciplineIncidentAction] ([DisciplineIncidentActionKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_DisciplineIncidentBehaviorKey] FOREIGN KEY ([DisciplineIncidentBehaviorKey]) REFERENCES [dbo].[DimDisciplineIncidentBehavior] ([DisciplineIncidentBehaviorKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_DisciplineIncidentLocationKey] FOREIGN KEY ([DisciplineIncidentLocationKey]) REFERENCES [dbo].[DimDisciplineIncidentLocation] ([DisciplineIncidentLocationKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_DisciplineIncidentReporterTypeKey] FOREIGN KEY ([DisciplineIncidentReporterTypeKey]) REFERENCES [dbo].[DimDisciplineIncidentReporterType] ([DisciplineIncidentReporterTypeKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentDiscipline] ADD CONSTRAINT [FK_FactStudentDiscipline_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
