CREATE TABLE [dbo].[DimTime]
(
[TimeKey] [int] NOT NULL IDENTITY(1, 1),
[SchoolDay] [date] NOT NULL,
[SchoolKey] [int] NULL,
[InstructionnalDay] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InstructionnalDayType] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InstructionnalDayType_FullDay] [bit] NOT NULL,
[InstructionnalDayType_PartialDay] [bit] NOT NULL,
[InstructionnalDayType_EarlyRelease] [bit] NOT NULL,
[InstructionnalDayType_MakeUpDay] [bit] NOT NULL,
[BlockScheduleDay] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BlockScheduleDay_ADay] [bit] NOT NULL,
[BlockScheduleDay_BDay] [bit] NOT NULL,
[Semester] [int] NULL,
[SemesterCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SemesterDescription] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Trimester] [int] NULL,
[TrimesterCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TrimesterDescription] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Quarter] [int] NULL,
[QuarterCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QuarterDescription] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Weekend_Indicator] [bit] NOT NULL,
[Holiday_Indicator] [bit] NOT NULL,
[HolidayName] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SpecialDay] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[WeekBeforeChristmas_Indicator] [bit] NOT NULL,
[StateExaminationPeriod_Indicator] [bit] NOT NULL,
[SchoolYear] [int] NOT NULL,
[SchoolYearDescription] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Month] [tinyint] NOT NULL,
[MonthName] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MonthNameShort] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MonthNameFirstLetter] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DayOfMonth] [int] NOT NULL,
[DayOfWeek] [int] NOT NULL,
[DayName] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CalendarYear] [int] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimTime] ADD CONSTRAINT [PK_DimTime] PRIMARY KEY CLUSTERED  ([TimeKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimTime] ADD CONSTRAINT [FK_DimTime_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[DimTime] ADD CONSTRAINT [FK_DimTime_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
