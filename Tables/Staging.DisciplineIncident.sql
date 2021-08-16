CREATE TABLE [Staging].[DisciplineIncident]
(
[DisciplineIncidentKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolKey] [int] NULL,
[ShortNameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchoolYear] [int] NOT NULL,
[IncidentDate] [date] NOT NULL,
[IncidentTime] [time] NOT NULL,
[IncidentDescription] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[IncidentModifiedDate] [datetime] NOT NULL,
[_sourceSchoolKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[DisciplineIncident] ADD CONSTRAINT [PK_StagingDisciplineIncident] PRIMARY KEY CLUSTERED  ([DisciplineIncidentKey]) ON [PRIMARY]
GO
