CREATE TABLE [dbo].[DimDisciplineIncidentReporterType]
(
[DisciplineIncidentReporterTypeKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ReporterDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ReporterDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimDisciplineIncidentReporterType] ADD CONSTRAINT [PK_DimDisciplineIncidentReporterType] PRIMARY KEY CLUSTERED  ([DisciplineIncidentReporterTypeKey]) ON [PRIMARY]
GO
