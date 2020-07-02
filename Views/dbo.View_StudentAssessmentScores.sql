SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[View_StudentAssessmentScores]
AS(
SELECT StudentId, 
       StudentStateId, 
	   FirstName, 
	   LastName, 
	   AssessmentIdentifier, 
	   AssessmentTitle,
	   AssessmentDate,  
	   --pivoted from row values
	   [Achievement/proficiency level] AS AchievementProficiencyLevel ,
	   [Composite Rating] AS CompositeRating,
	   [Composite Score] AS CompositeScore,
	   [Percentile rank] AS PercentileRank,
	   [Proficiency level] AS ProficiencyLevel,
	   [Promotion score] AS PromotionScore,
	   [Raw score] AS RawScore,
	   [Scale score] AS ScaleScore
FROM (
		SELECT ds.StudentUniqueId AS StudentId,
			   ds.StateId AS StudentStateId,
			   ds.FirstName,
			   ds.LastSurname AS LastName,
			   da.AssessmentIdentifier,
			   da.AssessmentTitle,
			   dt.SchoolDate AS AssessmentDate, 
			   da.[ReportingMethodDescriptor_CodeValue] AS ScoreType,
			   fas.ScoreResult AS Score
		FROM dbo.FactStudentAssessmentScore fas 
			 INNER JOIN dbo.DimStudent ds ON fas.StudentKey = ds.StudentKey
			 INNER JOIN dbo.DimTime dt ON fas.TimeKey = dt.TimeKey	 
			 INNER JOIN dbo.DimAssessment da ON fas.AssessmentKey = da.AssessmentKey
		WHERE da.AssessmentIdentifier = 'MCAS 03 Grade ELA Standard 2018'
	) AS SourceTable 
PIVOT 
   (
      MAX(Score)
	  FOR ScoreType IN ([Achievement/proficiency level],
	                    [Composite Rating],[Composite Score],
						[Percentile rank],
						[Proficiency level],
						[Promotion score],
						[Raw score],
						[Scale score])
   ) AS PivotTable
);
GO
