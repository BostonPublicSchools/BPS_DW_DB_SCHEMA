CREATE TABLE [Derived].[StaffCurrentSchools]
(
[StaffKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StaffCurrentSchools] ADD CONSTRAINT [PK_Derived_StaffCurrentSchools] PRIMARY KEY CLUSTERED ([StaffKey], [SchoolKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [CSI_Derived_StaffCurrentSchool] ON [Derived].[StaffCurrentSchools] ([StaffKey], [SchoolKey]) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StaffCurrentSchools] ADD CONSTRAINT [FK_Derived_StaffCurrentSchools_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [Derived].[StaffCurrentSchools] ADD CONSTRAINT [FK_Derived_StaffCurrentSchools_StaffKey] FOREIGN KEY ([StaffKey]) REFERENCES [dbo].[DimStaff] ([StaffKey])
GO
