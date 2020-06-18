CREATE TABLE [dbo].[FactStudentAttendanceBySection]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[SectionKey] [int] NOT NULL,
[StaffKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[AttendanceEventCategoryKey] [int] NOT NULL,
[AttendanceEventReason] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [PK_FactStudentAttendanceBySection] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [SectionKey], [StaffKey], [AttendanceEventCategoryKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [FK_FactStudentAttendanceBySection_AttendanceEventCategoryKey] FOREIGN KEY ([AttendanceEventCategoryKey]) REFERENCES [dbo].[DimAttendanceEventCategory] ([AttendanceEventCategoryKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [FK_FactStudentAttendanceBySection_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [FK_FactStudentAttendanceBySection_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [FK_FactStudentAttendanceBySection_SectionKey] FOREIGN KEY ([SectionKey]) REFERENCES [dbo].[DimSection] ([SectionKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [FK_FactStudentAttendanceBySection_StaffKey] FOREIGN KEY ([StaffKey]) REFERENCES [dbo].[DimStaff] ([StaffKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [FK_FactStudentAttendanceBySection_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceBySection] ADD CONSTRAINT [FK_FactStudentAttendanceBySection_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
