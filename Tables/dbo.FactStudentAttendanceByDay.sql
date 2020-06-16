CREATE TABLE [dbo].[FactStudentAttendanceByDay]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[AttendanceEventCategoryDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AttendanceEventCategoryDescriptor_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AttendanceEventReason] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InAttendance_Indicator] [bit] NOT NULL,
[UnexcusedAbsence_Indicator] [bit] NOT NULL,
[ExcusedAbsence_Indicator] [bit] NOT NULL,
[Tardy_Indicator] [bit] NOT NULL,
[EarlyDeparture_Indicator] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [PK_FactStudentAttendance] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendance_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendance_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendance_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentAttendanceByDay] ADD CONSTRAINT [FK_FactStudentAttendance_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
