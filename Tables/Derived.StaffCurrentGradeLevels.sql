CREATE TABLE [Derived].[StaffCurrentGradeLevels]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[StaffKey] [int] NOT NULL,
[GradeLevel] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StaffCurrentGradeLevels] ADD CONSTRAINT [PK_Derived_StaffCurrentGradeLevels] PRIMARY KEY CLUSTERED  ([Id]) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StaffCurrentGradeLevels] ADD CONSTRAINT [FK_Derived_StaffCurrentGradeLevels_StaffKey] FOREIGN KEY ([StaffKey]) REFERENCES [dbo].[DimStaff] ([StaffKey])
GO
