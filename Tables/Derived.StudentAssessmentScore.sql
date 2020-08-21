CREATE TABLE [Derived].[StudentAssessmentScore]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[AssessmentKey] [int] NOT NULL,
[AchievementProficiencyLevel] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CompositeRating] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CompositeScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PercentileRank] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ProficiencyLevel] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PromotionScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RawScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ScaleScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StudentAssessmentScore] ADD CONSTRAINT [PK_Derived_StudentAssessmentScore] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [AssessmentKey]) ON [PRIMARY]
GO
