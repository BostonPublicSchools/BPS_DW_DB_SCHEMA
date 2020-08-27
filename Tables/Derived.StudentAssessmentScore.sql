CREATE TABLE [Derived].[StudentAssessmentScore]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[AssessmentKey] [int] NOT NULL,
[AchievementProficiencyLevel] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompositeRating] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompositeScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PercentileRank] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProficiencyLevel] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PromotionScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RawScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScaleScore] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Derived].[StudentAssessmentScore] ADD CONSTRAINT [PK_Derived_StudentAssessmentScore] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [AssessmentKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [CSI_Derived_StudentAssessmentScore] ON [Derived].[StudentAssessmentScore] ([StudentKey], [TimeKey], [AssessmentKey], [AchievementProficiencyLevel], [CompositeRating], [CompositeScore], [PercentileRank], [ProficiencyLevel], [PromotionScore], [RawScore], [ScaleScore]) ON [PRIMARY]
GO
