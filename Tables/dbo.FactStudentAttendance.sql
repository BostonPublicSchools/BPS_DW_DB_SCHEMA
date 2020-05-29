CREATE TABLE [dbo].[FactStudentAttendance]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[NumberOfDaysPresent] [int] NOT NULL,
[NumberOfDaysAbsent] [int] NOT NULL,
[NumberOfDaysAbsentUnexcused] [int] NOT NULL,
[NumberOfDaysMembership] [int] NOT NULL,
[ADA] [int] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendance] ADD CONSTRAINT [PK_FactStudentAttendance] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAttendance] ADD CONSTRAINT [FK_FactStudentAttendance_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentAttendance] ADD CONSTRAINT [FK_FactStudentAttendance_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentAttendance] ADD CONSTRAINT [FK_FactStudentAttendance_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
