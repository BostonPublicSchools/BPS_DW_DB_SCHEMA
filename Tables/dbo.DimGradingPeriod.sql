CREATE TABLE [dbo].[DimGradingPeriod]
(
[GradingPeriodKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GradingPeriodDescriptor_CodeValue] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolKey] [int] NOT NULL,
[BeginDate] [date] NOT NULL,
[EndDate] [date] NOT NULL,
[TotalInstructionalDays] [int] NOT NULL,
[PeriodSequence] [int] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimGradingPeriod] ADD CONSTRAINT [PK_DimGradingPeriod] PRIMARY KEY CLUSTERED  ([GradingPeriodKey]) ON [PRIMARY]
GO
