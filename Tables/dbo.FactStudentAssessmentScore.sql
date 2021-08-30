CREATE TABLE [dbo].[FactStudentAssessmentScore]
(
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[AssessmentKey] [int] NOT NULL,
[ScoreResult] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IntegerScoreResult] [int] NULL,
[DecimalScoreResult] [float] NULL,
[LiteralScoreResult] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [PK_FactStudentAssessmentScores] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [AssessmentKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [FK_FactStudentAssessmentScore_TimeKey] FOREIGN KEY ([AssessmentKey]) REFERENCES [dbo].[DimAssessment] ([AssessmentKey])
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [FK_FactStudentAssessmentScores_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentAssessmentScore] ADD CONSTRAINT [FK_FactStudentAssessmentScores_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
