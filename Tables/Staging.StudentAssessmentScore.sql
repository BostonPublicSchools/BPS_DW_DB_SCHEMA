CREATE TABLE [Staging].[StudentAssessmentScore]
(
[StudentAssessmentScoreKey] [bigint] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NULL,
[TimeKey] [int] NULL,
[AssessmentKey] [int] NULL,
[ScoreResult] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IntegerScoreResult] [int] NULL,
[DecimalScoreResult] [float] NULL,
[LiteralScoreResult] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ModifiedDate] [datetime] NULL,
[_sourceStudentKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceTimeKey] [date] NULL,
[_sourceAssessmentKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentAssessmentScore] ADD CONSTRAINT [PK_StagingStudentAssessmentScore] PRIMARY KEY CLUSTERED  ([StudentAssessmentScoreKey]) ON [PRIMARY]
GO
