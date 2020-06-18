CREATE TABLE [dbo].[DimDisciplineIncidentBehavior]
(
[DisciplineIncidentBehaviorKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BehaviorDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BehaviorDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimDisciplineIncidentBehavior] ADD CONSTRAINT [PK_DimDisciplineIncidentBehavior] PRIMARY KEY CLUSTERED  ([DisciplineIncidentBehaviorKey]) ON [PRIMARY]
GO
