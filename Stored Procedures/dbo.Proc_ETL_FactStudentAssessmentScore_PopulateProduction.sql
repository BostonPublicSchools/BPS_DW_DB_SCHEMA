SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentAssessmentScore_PopulateProduction]
@LineageKey INT,
@LastDateLoaded DATETIME
AS
BEGIN
    --added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	--current session wont be the deadlock victim if it is involved in a deadlock with other sessions with the deadlock priority set to LOW
	SET DEADLOCK_PRIORITY HIGH;
	
	--When SET XACT_ABORT is ON, if a Transact-SQL statement raises a run-time error, the entire transaction is terminated and rolled back.
	SET XACT_ABORT ON;

	--This will allow for dirty reads. By default SQL Server uses "READ COMMITED" 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;



	BEGIN TRY
	    
		BEGIN TRANSACTION;   
		 
		--updating staging keys
		UPDATE s 
		SET s.StudentKey = COALESCE(
								(SELECT TOP (1) ds.StudentKey
								 FROM dbo.DimStudent ds
								 WHERE s._sourceStudentKey = ds._sourceKey									
									AND s.[ModifiedDate] >= ds.[ValidFrom]
									AND s.[ModifiedDate] < ds.[ValidTo]
								 ORDER BY ds.[ValidFrom] DESC),
								(SELECT ds.StudentKey
								 FROM dbo.DimStudent ds
								 WHERE ds._sourceKey = '')
							),
			s.TimeKey = (
							SELECT TOP (1) dt.TimeKey
							FROM dbo.DimTime dt									
							WHERE s._sourceTimeKey = dt.SchoolDate
							ORDER BY dt.SchoolDate
						),		
			s.AssessmentKey =COALESCE(
								(SELECT TOP (1) da.AssessmentKey
								 FROM dbo.DimAssessment da
								 WHERE s._sourceAssessmentKey = da._sourceKey									
									 AND s.[ModifiedDate] >= da.[ValidFrom]
									 AND s.[ModifiedDate] < da.[ValidTo]
								 ORDER BY da.[ValidFrom] DESC),
								 (SELECT da.AssessmentKey
								 FROM dbo.DimAssessment da
								 WHERE da._sourceKey = '')

						 	 )  										             
        FROM Staging.StudentAssessmentScore s;
		
		DELETE FROM Staging.StudentAssessmentScore 
		WHERE TimeKey IS NULL
        
		;WITH DuplicateKeys AS 
		(
		  SELECT [StudentKey], [TimeKey],[AssessmentKey]
		  FROM  Staging.StudentAssessmentScore
		  GROUP BY [StudentKey], [TimeKey],[AssessmentKey]
		  HAVING COUNT(*) > 1
		)
		
		DELETE sd 
		FROM Staging.StudentAssessmentScore sd
		WHERE EXISTS(SELECT 1 
		             FROM DuplicateKeys dk 
					 WHERE sd.[StudentKey] = dk.StudentKey
					   AND sd.[TimeKey] = dk.[TimeKey]
					   AND sd.[AssessmentKey] = dk.[AssessmentKey])


		--dropping the columnstore index
        DROP INDEX IF EXISTS CSI_FactStudentAssessmentScore ON dbo.FactStudentAssessmentScore;
	    
		--deleting changed records
		DELETE prod
		FROM [dbo].FactStudentAssessmentScore AS prod
		WHERE EXISTS (SELECT 1 
		              FROM [Staging].StudentAssessmentScore stage
					  WHERE prod._sourceKey = stage._sourceKey)



		 INSERT INTO [dbo].[FactStudentAssessmentScore]
						   ([_sourceKey]
						   ,[StudentKey]
						   ,[TimeKey]
						   ,[AssessmentKey]
						   ,ScoreResult
						   ,IntegerScoreResult
						   ,DecimalScoreResult
						   ,LiteralScoreResult
						   ,LineageKey)
		SELECT DISTINCT 
		  LEN( [_sourceKey]),
		   [StudentKey],
		   [TimeKey],
		   [AssessmentKey],
		   ScoreResult,
		   IntegerScoreResult,
		   DecimalScoreResult,
		   LiteralScoreResult,
		   @lineageKey AS LineageKey
		FROM Staging.StudentAssessmentScore
		ORDER BY LEN( [_sourceKey]) DESC 
		--loading from legacy dw just once
		IF (NOT EXISTS(SELECT 1  
		               FROM dbo.FactStudentAssessmentScore 
		               WHERE _sourceKey = 'LegacyDW'))
             BEGIN		
			       ;WITH UnpivotedScores AS 
					(
						SELECT testid,schyear,testtime,studentno,adminyear,grade, scoretype, scorevalue,lastupdate, CASE WHEN a.scoretype IN ('Proficiency level','Proficiency level 2') THEN 1 ELSE 0 END AS isperflevel
						--INTO [Raw_LegacyDW].[MCASAssessmentScores]
						FROM (  
								 --ensuring all score columns have the same data type to avoid conflicts with unpivot
								 SELECT testid,schyear,testtime,studentno,adminyear,grade,teststatus , lastupdate,
									  CAST(rawscore AS NVARCHAR(MAX)) AS [Raw score],
									  CAST(scaledscore AS NVARCHAR(MAX)) AS [Scale score],
									  CAST(perflevel AS NVARCHAR(MAX)) AS  [Proficiency level],
									  CAST(sgp AS NVARCHAR(MAX)) AS [Percentile rank],
									  CAST(cpi AS NVARCHAR(MAX)) AS [Composite Performance Index],
									  CAST(perf2 AS NVARCHAR(MAX)) AS [Proficiency level 2]
     
								FROM [BPSGranary02].[RAEDatabase].[dbo].[mcasitems] 
								WHERE schyear >= 2015 ) scores
						UNPIVOT
						(
						   scorevalue
						   FOR scoretype IN ([Raw score],[Scale score],[Proficiency level],[Percentile rank],[Composite Performance Index],[Proficiency level 2])
						) AS a

					)
				   INSERT INTO [dbo].[FactStudentAssessmentScore]
						   ([_sourceKey]
						   ,[StudentKey]
						   ,[TimeKey]
						   ,[AssessmentKey]
						   ,ScoreResult
						   ,IntegerScoreResult
						   ,DecimalScoreResult
						   ,LiteralScoreResult
						   ,LineageKey)

					SELECT   DISTINCT 
						  'LegacyDW',
						  ds.StudentKey,
						  dt.TimeKey,	  
						  da.AssessmentKey,
						  us.scorevalue AS [SoreResult],
						  CASE when da.ResultDatatypeTypeDescriptor_CodeValue in ('Integer') AND TRY_CAST(us.scorevalue AS INTEGER) IS NOT NULL AND us.scorevalue <> '-' THEN us.scorevalue ELSE NULL END AS IntegerScoreResult,
						  CASE when da.ResultDatatypeTypeDescriptor_CodeValue in ('Decimal','Percentage','Percentile')  AND TRY_CAST(us.scorevalue AS FLOAT)  IS NOT NULL THEN us.scorevalue ELSE NULL END AS DecimalScoreResult,
						  CASE when da.ResultDatatypeTypeDescriptor_CodeValue not in ('Integer','Decimal','Percentage','Percentile') THEN us.scorevalue ELSE NULL END AS LiteralScoreResult,
						  --us.*
						  @lineageKey AS LineageKey
					--select top 100 *  
					FROM UnpivotedScores us

						--joining DW tables
						INNER JOIN dbo.DimTime dt ON CONVERT(DATE ,CASE WHEN SUBSTRING(us.testid,LEN(us.testid)-1,1) IN ('E','X') THEN DATEADD(YEAR, CASE WHEN MONTH(us.lastupdate) >= 7 THEN us.schyear ELSE us.schyear + 1 end  - YEAR(us.lastupdate), us.lastupdate)
																						WHEN us.testid = 'MCAS03AE' and us.testtime = 'S' and us.schyear = '2015' then '3/21/2016'
																						WHEN us.testid = 'MCAS03AM' and us.testtime = 'S' and us.schyear = '2015' then '5/9/2016'
																						WHEN us.testid = 'MCAS04AE' and us.testtime = 'S' and us.schyear = '2015' then '3/22/2016'
																						WHEN us.testid = 'MCAS04AM' and us.testtime = 'S' and us.schyear = '2015' then '5/9/2016'
																						WHEN us.testid = 'MCAS05AE' and us.testtime = 'S' and us.schyear = '2015' then '3/21/2016'
																						WHEN us.testid = 'MCAS05AM' and us.testtime = 'S' and us.schyear = '2015' then '5/9/2016'
																						WHEN us.testid = 'MCAS05AS' and us.testtime = 'S' and us.schyear = '2015' then '5/10/2016'
																						WHEN us.testid = 'MCAS06AE' and us.testtime = 'S' and us.schyear = '2015' then '3/21/2016'
																						WHEN us.testid = 'MCAS06AM' and us.testtime = 'S' and us.schyear = '2015' then '5/9/2016'
																						WHEN us.testid = 'MCAS07AE' and us.testtime = 'S' and us.schyear = '2015' then '3/22/2016'
																						WHEN us.testid = 'MCAS07AM' and us.testtime = 'S' and us.schyear = '2015' then '5/9/2016'
																						WHEN us.testid = 'MCAS08AE' and us.testtime = 'S' and us.schyear = '2015' then '3/21/2016'
																						WHEN us.testid = 'MCAS08AM' and us.testtime = 'S' and us.schyear = '2015' then '5/9/2016'
																						WHEN us.testid = 'MCAS08AS' and us.testtime = 'S' and us.schyear = '2015' then '5/10/2016'
																						WHEN us.testid = 'MCAS10AE' and us.testtime = 'S' and us.schyear = '2015' then '3/22/2016'
																						WHEN us.testid = 'MCAS10AM' and us.testtime = 'S' and us.schyear = '2015' then '3/23/2016'
																						WHEN us.testid = 'MCAS10BE' and us.testtime = 'F' and us.schyear = '2015' then '11/4/2015'
																						WHEN us.testid = 'MCAS10BE' and us.testtime = 'W' and us.schyear = '2015' then '3/2/2016'
																						WHEN us.testid = 'MCAS10BM' and us.testtime = 'F' and us.schyear = '2015' then '11/9/2015'
																						WHEN us.testid = 'MCAS10BM' and us.testtime = 'W' and us.schyear = '2015' then '3/2/2016'
																						WHEN us.testid = 'MCASHSAB' and us.testtime = 'W' and us.schyear = '2015' then '2/1/2016'
																						WHEN us.testid = 'MCASHSAB' and us.testtime = 'S' and us.schyear = '2015' then '6/1/2016'
																						WHEN us.testid = 'MCASHSAC' and us.testtime = 'S' and us.schyear = '2015' then '6/1/2016'
																						WHEN us.testid = 'MCASHSAP' and us.testtime = 'S' and us.schyear = '2015' then '6/1/2016'
																						WHEN us.testid = 'MCASHSAT' and us.testtime = 'S' and us.schyear = '2015' then '6/1/2016'
																						WHEN us.testid = 'MCAS03AE' and us.testtime = 'S' and us.schyear = '2016' then '4/3/2017'
																						WHEN us.testid = 'MCAS03AM' and us.testtime = 'S' and us.schyear = '2016' then '4/4/2017'
																						WHEN us.testid = 'MCAS04AE' and us.testtime = 'S' and us.schyear = '2016' then '4/3/2017'
																						WHEN us.testid = 'MCAS04AM' and us.testtime = 'S' and us.schyear = '2016' then '4/4/2017'
																						WHEN us.testid = 'MCAS05AE' and us.testtime = 'S' and us.schyear = '2016' then '4/3/2017'
																						WHEN us.testid = 'MCAS05AM' and us.testtime = 'S' and us.schyear = '2016' then '4/4/2017'
																						WHEN us.testid = 'MCAS05AS' and us.testtime = 'S' and us.schyear = '2016' then '4/5/2017'
																						WHEN us.testid = 'MCAS06AE' and us.testtime = 'S' and us.schyear = '2016' then '4/3/2017'
																						WHEN us.testid = 'MCAS06AM' and us.testtime = 'S' and us.schyear = '2016' then '4/4/2017'
																						WHEN us.testid = 'MCAS07AE' and us.testtime = 'S' and us.schyear = '2016' then '4/3/2017'
																						WHEN us.testid = 'MCAS07AM' and us.testtime = 'S' and us.schyear = '2016' then '4/4/2017'
																						WHEN us.testid = 'MCAS08AE' and us.testtime = 'S' and us.schyear = '2016' then '4/3/2017'
																						WHEN us.testid = 'MCAS08AM' and us.testtime = 'S' and us.schyear = '2016' then '4/4/2017'
																						WHEN us.testid = 'MCAS08AS' and us.testtime = 'S' and us.schyear = '2016' then '4/5/2017'
																						WHEN us.testid = 'MCAS10AE' and us.testtime = 'S' and us.schyear = '2016' then '3/21/2017'
																						WHEN us.testid = 'MCAS10AM' and us.testtime = 'S' and us.schyear = '2016' then '5/16/2017'
																						WHEN us.testid = 'MCAS10BE' and us.testtime = 'F' and us.schyear = '2016' then '11/2/2016'
																						WHEN us.testid = 'MCAS10BE' and us.testtime = 'W' and us.schyear = '2016' then '3/1/2017'
																						WHEN us.testid = 'MCAS10BM' and us.testtime = 'F' and us.schyear = '2016' then '11/9/2016'
																						WHEN us.testid = 'MCAS10BM' and us.testtime = 'W' and us.schyear = '2016' then '3/1/2017'
																						WHEN us.testid = 'MCASHSAB' and us.testtime = 'W' and us.schyear = '2016' then '2/6/2017'
																						WHEN us.testid = 'MCASHSAB' and us.testtime = 'S' and us.schyear = '2016' then '6/5/2017'
																						WHEN us.testid = 'MCASHSAC' and us.testtime = 'S' and us.schyear = '2016' then '6/5/2017'
																						WHEN us.testid = 'MCASHSAP' and us.testtime = 'S' and us.schyear = '2016' then '6/5/2017'
																						WHEN us.testid = 'MCASHSAT' and us.testtime = 'S' and us.schyear = '2016' then '6/5/2017'
																						WHEN us.testid = 'MCAS03AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS03AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS04AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS04AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS05AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS05AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS05AS' and us.testtime = 'S' and us.schyear = '2017' then '4/4/2018'
																						WHEN us.testid = 'MCAS06AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS06AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS07AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS07AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS08AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS08AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS08AS' and us.testtime = 'S' and us.schyear = '2017' then '4/4/2018'
																						WHEN us.testid = 'MCAS10AE' and us.testtime = 'S' and us.schyear = '2017' then '3/27/2018'
																						WHEN us.testid = 'MCAS10AM' and us.testtime = 'S' and us.schyear = '2017' then '5/23/2018'
																						WHEN us.testid = 'MCAS10BE' and us.testtime = 'F' and us.schyear = '2017' then '11/8/2017'
																						WHEN us.testid = 'MCAS10BE' and us.testtime = 'W' and us.schyear = '2017' then '2/28/2018'
																						WHEN us.testid = 'MCAS10BM' and us.testtime = 'W' and us.schyear = '2017' then '2/28/2018'
																						WHEN us.testid = 'MCAS10BM' and us.testtime = 'F' and us.schyear = '2017' then '11/15/2017'
																						WHEN us.testid = 'MCAS3 AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS3 AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS4 AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS4 AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS5 AE' and us.testtime = 'S' and us.schyear = '2017' then '4/2/2018'
																						WHEN us.testid = 'MCAS5 AM' and us.testtime = 'S' and us.schyear = '2017' then '4/3/2018'
																						WHEN us.testid = 'MCAS5 AS' and us.testtime = 'S' and us.schyear = '2017' then '4/4/2018'
																						WHEN us.testid = 'MCASHSAB' and us.testtime = 'S' and us.schyear = '2017' then '2/1/2018'
																						WHEN us.testid = 'MCASHSAB' and us.testtime = 'W' and us.schyear = '2017' then '6/1/2018'
																						WHEN us.testid = 'MCASHSAC' and us.testtime = 'S' and us.schyear = '2017' then '6/1/2018'
																						WHEN us.testid = 'MCASHSAP' and us.testtime = 'S' and us.schyear = '2017' then '6/1/2018'
																						WHEN us.testid = 'MCASHSAT' and us.testtime = 'S' and us.schyear = '2017' then '6/1/2018'
																						ELSE '1900/01/01'
																				   END ) = dt.SchoolDate
	                               
						INNER JOIN dbo.DimStudent ds  ON 'LegacyDW|' + Convert(NVARCHAR(MAX),us.studentno)   = ds._sourceKey
																	  AND dt.SchoolKey = ds.SchoolKey
																	  AND dt.SchoolDate BETWEEN ds.ValidFrom AND ds.ValidTo
						INNER JOIN [dbo].DimAssessment da ON 'LegacyDW|' + Convert(NVARCHAR(MAX),us.testid)  + '|N/A|' + Convert(NVARCHAR(MAX),us.scoretype)  = da._sourceKey
	
					WHERE  dt.SchoolDate BETWEEN '07/01/2015' AND '2018-06-30';

			 END;
		
        --re-creating the columnstore index
		CREATE COLUMNSTORE INDEX CSI_FactStudentAssessmentScore
			  ON dbo.FactStudentAssessmentScore
			  ([StudentKey]
			  ,[TimeKey]
			  ,[AssessmentKey]
			  ,[ScoreResult]
			  ,[IntegerScoreResult]
			  ,[DecimalScoreResult]
			  ,[LiteralScoreResult]
			  ,LineageKey)

		--Deriving
		--dropping the columnstore index
		DROP INDEX IF EXISTS CSI_Derived_StudentAssessmentScore ON Derived.StudentAssessmentScore;
		
		delete d_sas
		FROM  [Derived].[StudentAssessmentScore] d_sas
		WHERE EXISTS(SELECT 1 
		             FROM Staging.StudentAssessmentScore s_sas
					 WHERE d_sas.StudentKey = s_sas.StudentKey
					    AND d_sas.[TimeKey] = s_sas.[TimeKey]
						AND d_sas.[AssessmentKey] =  s_sas.[AssessmentKey])
						
		INSERT INTO [Derived].[StudentAssessmentScore]
					([StudentKey]
					,[TimeKey]
					,[AssessmentKey]
					,[AchievementProficiencyLevel]
					,[CompositeRating]
					,[CompositeScore]
					,[PercentileRank]
					,[ProficiencyLevel]
					,[PromotionScore]
					,[RawScore]
					,[ScaleScore])
    
		SELECT  [StudentKey],
				[TimeKey],
				[AssessmentKey],
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
				SELECT  
				        fas.[StudentKey],
						fas.[TimeKey],
						fas.[AssessmentKey],
						da.[ReportingMethodDescriptor_CodeValue] AS ScoreType,
						fas.ScoreResult AS Score
				FROM dbo.FactStudentAssessmentScore fas  
						INNER JOIN dbo.DimAssessment da ON fas.AssessmentKey = da.AssessmentKey
				WHERE EXISTS(SELECT 1 
							 FROM Staging.StudentAssessmentScore s_sas
							 WHERE fas.StudentKey = s_sas.StudentKey
								AND fas.[TimeKey] = s_sas.[TimeKey]
								AND fas.[AssessmentKey] =  s_sas.[AssessmentKey])
			 
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
			) AS PivotTable;


		CREATE COLUMNSTORE INDEX CSI_Derived_StudentAssessmentScore
			ON Derived.StudentAssessmentScore
			([StudentKey]
			,[TimeKey]
			,[AssessmentKey]
			,[AchievementProficiencyLevel]
			,[CompositeRating]
			,[CompositeScore]
			,[PercentileRank]
			,[ProficiencyLevel]
			,[PromotionScore]
			,[RawScore]
			,[ScaleScore])


		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE LineageKey = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.FactStudentAssessmentScore';

		
	    
		COMMIT TRANSACTION;		
	END TRY
	BEGIN CATCH
		
		--constructing exception details
		DECLARE
		   @errorMessage nvarchar( MAX ) = ERROR_MESSAGE( );		
     
		DECLARE
		   @errorDetails nvarchar( MAX ) = CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);

		PRINT @errorDetails;
		THROW 51000, @errorDetails, 1;

		-- Test XACT_STATE:
		-- If  1, the transaction is committable.
		-- If -1, the transaction is uncommittable and should be rolled back.
		-- XACT_STATE = 0 means that there is no transaction and a commit or rollback operation would generate an error.

		-- Test whether the transaction is uncommittable.
		IF XACT_STATE( ) = -1
			BEGIN
				--The transaction is in an uncommittable state. Rolling back transaction
				ROLLBACK TRANSACTION;
			END;

		-- Test whether the transaction is committable.
		IF XACT_STATE( ) = 1
			BEGIN
				--The transaction is committable. Committing transaction
				COMMIT TRANSACTION;
			END;
	END CATCH;
END;
GO
