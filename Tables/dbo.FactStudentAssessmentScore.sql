CREATE TABLE [dbo].[FactStudentAssessmentScore]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[AssessmentKey] [int] NOT NULL,
[Score_AssessmentReportingMethodDescriptor_RawScore] [int] NULL,
[Score_AssessmentReportingMethodDescriptor_ScaleScore] [int] NULL,
[Score_AssessmentReportingMethodDescriptor_ProficiencyLevel] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Score_AssessmentReportingMethodDescriptor_Percentile] [float] NULL,
[MCAS_PerformanceLevel_Descriptor_Failing_Indicator] [bit] NOT NULL,
[MCAS_PerformanceLevel_Descriptor_Warning_Indicator] [bit] NOT NULL,
[MCAS_PerformanceLevel_Descriptor_NeedsImprovement_Indicator] [bit] NOT NULL,
[MCAS_PerformanceLevel_Descriptor_Proficient_Indicator] [bit] NOT NULL,
[MCAS_PerformanceLevel_Descriptor_Advanced_Indicator] [bit] NOT NULL,
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
