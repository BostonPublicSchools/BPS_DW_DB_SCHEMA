SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[View_StudentAssessmentScores]
WITH SCHEMABINDING
AS(
   SELECT ds.StudentKey,
          ds.StudentUniqueId AS StudentId,
		  ds.StateId AS StudentStateId,
		  ds.FirstName,
		  ds.LastSurname AS LastName,
		  da.AssessmentIdentifier,
		  da.AssessmentTitle,
		  dt.SchoolDate AS AssessmentDate, 
		  sas.AchievementProficiencyLevel,
		  sas.CompositeRating,
		  sas.CompositeScore,
		  sas.PercentileRank,
		  sas.ProficiencyLevel,
		  sas.PromotionScore,
		  sas.RawScore,
		  sas.ScaleScore 
FROM Derived.StudentAssessmentScore sas 
		INNER JOIN dbo.DimStudent ds ON sas.StudentKey = ds.StudentKey
		INNER JOIN dbo.DimTime dt ON sas.TimeKey = dt.TimeKey	 
		INNER JOIN dbo.DimAssessment da ON sas.AssessmentKey = da.AssessmentKey
);
GO

CREATE UNIQUE CLUSTERED INDEX [CLU_View_StudentAssessmentScores] ON [dbo].[View_StudentAssessmentScores] ([StudentKey], [AssessmentIdentifier], [AssessmentDate]) ON [PRIMARY]
GO
