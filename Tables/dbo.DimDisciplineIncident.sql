CREATE TABLE [dbo].[DimDisciplineIncident]
(
[DisciplineIncidentKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolKey] [int] NOT NULL,
[ShortNameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolYear] [int] NOT NULL,
[IncidentDate] [date] NOT NULL,
[IncidentTime] [time] NOT NULL,
[IncidentDescription] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BehaviorDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BehaviorDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LocationDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LocationDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DisciplineDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DisciplineDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DisciplineDescriptor_ISS_Indicator] [bit] NOT NULL,
[DisciplineDescriptor_OSS_Indicator] [bit] NOT NULL,
[ReporterDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ReporterDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IncidentReporterName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ReportedToLawEnforcement_Indicator] [bit] NOT NULL,
[IncidentCost] [money] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimDisciplineIncident] ADD CONSTRAINT [PK_DimDisciplineIncident] PRIMARY KEY CLUSTERED  ([DisciplineIncidentKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimDisciplineIncident] ADD CONSTRAINT [FK_DimDisciplineIncident_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
