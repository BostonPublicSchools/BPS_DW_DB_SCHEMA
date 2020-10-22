CREATE TABLE [Derived].[StudentAttendanceByDay]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[AttendanceEventCategoryKey] [int] NOT NULL,
[EarlyDeparture] [bit] NOT NULL,
[ExcusedAbsence] [bit] NOT NULL,
[UnexcusedAbsence] [bit] NOT NULL,
[NoContact] [bit] NOT NULL,
[InAttendance] [bit] NOT NULL,
[Tardy] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StudentAttendanceByDay] ADD CONSTRAINT [PK_Derived_StudentAttendanceByDay] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [SchoolKey], [AttendanceEventCategoryKey]) ON [PRIMARY]
GO
