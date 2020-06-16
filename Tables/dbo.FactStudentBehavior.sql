CREATE TABLE [dbo].[FactStudentBehavior]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[IncidentDateTime] [datetime2] NOT NULL,
[IncidentTypeCode] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IncidentActionCode] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IncidentLocationCode] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ISS_Indicator] [bit] NOT NULL,
[OSS_Indicator] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [PK_FactStudentBehavior] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [IncidentDateTime]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [FK_FactStudentBehavior_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [FK_FactStudentBehavior_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [FK_FactStudentBehavior_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
