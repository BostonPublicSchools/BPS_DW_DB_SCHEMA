CREATE TABLE [dbo].[DimDisciplineIncidentAction]
(
[DisciplineIncidentActionKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DisciplineDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DisciplineDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DisciplineDescriptor_ISS_Indicator] [bit] NOT NULL,
[DisciplineDescriptor_OSS_Indicator] [bit] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimDisciplineIncidentAction] ADD CONSTRAINT [PK_DimDisciplineIncidentAction] PRIMARY KEY CLUSTERED  ([DisciplineIncidentActionKey]) ON [PRIMARY]
GO
