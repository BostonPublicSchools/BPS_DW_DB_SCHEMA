CREATE TABLE [Staging].[GradingPeriod]
(
[GradingPeriodKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GradingPeriodDescriptor_CodeValue] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolKey] [int] NOT NULL,
[BeginDate] [date] NOT NULL,
[EndDate] [date] NOT NULL,
[TotalInstructionalDays] [int] NOT NULL,
[PeriodSequence] [int] NOT NULL,
[ModifiedDate] [datetime] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[GradingPeriod] ADD CONSTRAINT [PK_StagingGradingPeriod] PRIMARY KEY CLUSTERED  ([GradingPeriodKey]) ON [PRIMARY]
GO
