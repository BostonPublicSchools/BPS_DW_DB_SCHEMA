CREATE TABLE [dbo].[DimDisciplineIncidentLocation]
(
[DisciplineIncidentLocationKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LocationDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LocationDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimDisciplineIncidentLocation] ADD CONSTRAINT [PK_DimDisciplineIncidentLocation] PRIMARY KEY CLUSTERED  ([DisciplineIncidentLocationKey]) ON [PRIMARY]
GO
