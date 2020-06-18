CREATE TABLE [dbo].[DimAttendanceEventCategory]
(
[AttendanceEventCategoryKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AttendanceEventCategoryDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AttendanceEventCategoryDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InAttendance_Indicator] [bit] NOT NULL,
[UnexcusedAbsence_Indicator] [bit] NOT NULL,
[ExcusedAbsence_Indicator] [bit] NOT NULL,
[Tardy_Indicator] [bit] NOT NULL,
[EarlyDeparture_Indicator] [bit] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimAttendanceEventCategory] ADD CONSTRAINT [PK_DimAttendanceEventCategory] PRIMARY KEY CLUSTERED  ([AttendanceEventCategoryKey]) ON [PRIMARY]
GO
