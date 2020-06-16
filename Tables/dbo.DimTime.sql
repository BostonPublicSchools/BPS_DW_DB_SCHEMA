CREATE TABLE [dbo].[DimTime]
(
[TimeKey] [int] NOT NULL IDENTITY(1, 1),
[SchoolDate] [date] NOT NULL,
[SchoolDate_MMYYYY] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolDate_Fomat1] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolDate_Fomat2] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolDate_Fomat3] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolYear] [smallint] NOT NULL,
[SchoolYearDescription] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CalendarYear] [smallint] NOT NULL,
[DayOfMonth] [tinyint] NOT NULL,
[DaySuffix] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DayName] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DayNameShort] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DayOfWeek] [tinyint] NOT NULL,
[WeekInMonth] [tinyint] NOT NULL,
[WeekOfMonth] [tinyint] NOT NULL,
[Weekend_Indicator] [bit] NOT NULL,
[WeekOfYear] [tinyint] NOT NULL,
[FirstDayOfWeek] [date] NOT NULL,
[LastDayOfWeek] [date] NOT NULL,
[WeekBeforeChristmas_Indicator] [bit] NOT NULL,
[Month] [tinyint] NOT NULL,
[MonthName] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MonthNameShort] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FirstDayOfMonth] [date] NOT NULL,
[LastDayOfMonth] [date] NOT NULL,
[FirstDayOfNextMonth] [date] NOT NULL,
[LastDayOfNextMonth] [date] NOT NULL,
[DayOfYear] [smallint] NULL,
[LeapYear_Indicator] [bit] NOT NULL,
[FederalHolidayName] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FederalHoliday_Indicator] [bit] NOT NULL,
[SchoolKey] [int] NULL,
[DayOfSchoolYear] [smallint] NULL,
[SchoolCalendarEventType_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchoolCalendarEventType_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchoolTermDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchoolTermDescriptor_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
