CREATE TABLE [dbo].[FactStudentAttendanceByDay]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[AttendanceEventCategoryKey] [int] NOT NULL,
[AttendanceEventReason] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [PK_FactStudentAttendanceByDay] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [SchoolKey], [AttendanceEventCategoryKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [CSI_FactStudentAttendanceByDay] ON [dbo].[FactStudentAttendanceByDay] ([StudentKey], [TimeKey], [SchoolKey], [AttendanceEventCategoryKey], [AttendanceEventReason], [LineageKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendanceByDay_AttendanceEventCategoryKey] FOREIGN KEY ([AttendanceEventCategoryKey]) REFERENCES [dbo].[DimAttendanceEventCategory] ([AttendanceEventCategoryKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendanceByDay_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendanceByDay_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendanceByDay_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendanceByDay_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
