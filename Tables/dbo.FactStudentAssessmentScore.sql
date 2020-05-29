CREATE TABLE [dbo].[FactStudentAssessmentScore]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[AssessmentKey] [int] NOT NULL,
[Result] [nvarchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Score_AssessmentReportingMethodDescriptor_RawScore_Indicator] [bit] NOT NULL,
[Score_AssessmentReportingMethodDescriptor_ScaleScore_Indicator] [bit] NOT NULL,
[Score_AssessmentReportingMethodDescriptor_ProficiencyLevel_Indicator] [bit] NOT NULL,
[Score_AssessmentReportingMethodDescriptor_Percentile_Indicator] [bit] NOT NULL,
[Score_ResultDatatypeType_Level_Indicator] [bit] NOT NULL,
[Score_ResultDatatypeType_Integer_Indicator] [bit] NOT NULL,
[Score_ResultDatatypeType_Decimal_Indicator] [bit] NOT NULL,
[Score_ResultDatatypeType_Percentage_Indicator] [bit] NOT NULL,
[Score_ResultDatatypeType_Percentile_Indicator] [bit] NOT NULL,
[Score_ResultDatatypeType_Range_Indicator] [bit] NOT NULL,
[PerformanceLevel_Descriptor_Failing_Indicator] [bit] NOT NULL,
[PerformanceLevel_Descriptor_Warning_Indicator] [bit] NOT NULL,
[PerformanceLevel_Descriptor_NeedsImprovement_Indicator] [bit] NOT NULL,
[PerformanceLevel_Descriptor_Proficient_Indicator] [bit] NOT NULL,
[PerformanceLevel_Descriptor_Advanced_Indicator] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [PK_FactStudentAssessmentScores] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [AssessmentKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [FK_FactStudentAssessmentScore_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [FK_FactStudentAssessmentScore_TimeKey] FOREIGN KEY ([AssessmentKey]) REFERENCES [dbo].[DimAssessment] ([AssessmentKey])
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [FK_FactStudentAssessmentScores_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [FK_FactStudentAssessmentScores_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
