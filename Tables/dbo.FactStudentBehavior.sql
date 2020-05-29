CREATE TABLE [dbo].[FactStudentBehavior]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[NumberOfISSIncidents] [int] NOT NULL,
[NumberOfOSSIncidents] [int] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [PK_FactStudentBehavior] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [FK_FactStudentBehavior_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [FK_FactStudentBehavior_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentBehavior] ADD CONSTRAINT [FK_FactStudentBehavior_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
