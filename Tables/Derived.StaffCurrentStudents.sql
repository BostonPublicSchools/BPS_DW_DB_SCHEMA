CREATE TABLE [Derived].[StaffCurrentStudents]
(
[StaffKey] [int] NOT NULL,
[StudentKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StaffCurrentStudents] ADD CONSTRAINT [PK_Derived_StaffCurrentStudents] PRIMARY KEY CLUSTERED  ([StaffKey], [StudentKey]) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StaffCurrentStudents] ADD CONSTRAINT [FK_Derived_StaffCurrentStudents_StaffKey] FOREIGN KEY ([StaffKey]) REFERENCES [dbo].[DimStaff] ([StaffKey])
GO
ALTER TABLE [Derived].[StaffCurrentStudents] ADD CONSTRAINT [FK_Derived_StaffCurrentStudents_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
