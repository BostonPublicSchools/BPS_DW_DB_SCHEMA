SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentCourseGrade_PopulateProduction]
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
		SET  s.TimeKey =    (
								SELECT TOP (1) dt.TimeKey
								FROM dbo.DimTime dt										
								WHERE EXISTS (SELECT 1 
								              FROM [dbo].[DimStudentSection] dss
											  WHERE dt.SchoolKey = dss.SchoolKey
											    AND s.[_sourceStudentSectionKey] = dss._sourceKey									
												AND s.[ModifiedDate] >= dss.[ValidFrom]
												AND s.[ModifiedDate] < dss.[ValidTo]
												AND dt.SchoolDate = dss.StudentSectionBeginDate
											  )
								ORDER BY dt.SchoolDate
							),
		     s.[GradingPeriodKey] = COALESCE(
												(SELECT TOP (1) dgp.GradingPeriodKey
												FROM dbo.DimGradingPeriod dgp
												WHERE s.[_sourceGradingPeriodey] = dgp._sourceKey									
													AND s.[ModifiedDate] >= dgp.[ValidFrom]
													AND s.[ModifiedDate] < dgp.[ValidTo]
												ORDER BY dgp.[ValidFrom] DESC),
												(SELECT dgp.GradingPeriodKey
												FROM dbo.DimGradingPeriod dgp
												WHERE dgp._sourceKey = '')
											),
			s.[StudentSectionKey] = COALESCE(
												(SELECT TOP (1) dss.StudentSectionKey
												 FROM dbo.DimStudentSection dss
												 WHERE s.[_sourceStudentSectionKey] = dss._sourceKey									
													AND s.[ModifiedDate] >= dss.[ValidFrom]
													AND s.[ModifiedDate] < dss.[ValidTo]
												 ORDER BY dss.[ValidFrom] DESC),
												(SELECT dss.StudentSectionKey
												 FROM dbo.DimStudentSection dss
												 WHERE dss._sourceKey = '')
									       )													             
        FROM Staging.StudentCourseGrade s;

		
		DELETE FROM Staging.[StudentCourseGrade]
		WHERE TimeKey IS NULL;

		;WITH DuplicateKeys AS 
		(
		  SELECT [TimeKey],[GradingPeriodKey],[StudentSectionKey]
		  FROM  Staging.[StudentCourseGrade]
		  GROUP BY [TimeKey],[GradingPeriodKey],[StudentSectionKey]
		  HAVING COUNT(*) > 1
		)
		
		DELETE sd	
		FROM Staging.[StudentCourseGrade] sd
		WHERE EXISTS(SELECT 1 
		             FROM DuplicateKeys dk 
					 WHERE sd.[TimeKey] = dk.[TimeKey]
					   AND sd.[GradingPeriodKey] = dk.[GradingPeriodKey]
					   AND sd.[StudentSectionKey] = dk.[StudentSectionKey])
		
		--dropping the columnstore index
        DROP INDEX IF EXISTS CSI_FactStudentCourseGrades ON dbo.FactStudentCourseGrade;		   

		--deleting changed records
		DELETE prod
		FROM [dbo].FactStudentCourseGrade AS prod
		WHERE EXISTS (SELECT 1 
		              FROM [Staging].[StudentCourseGrade] stage
					  WHERE prod._sourceKey = stage._sourceKey)

         INSERT INTO [dbo].FactStudentCourseGrade
         (
             _sourceKey,
             TimeKey,
             GradingPeriodKey,
             StudentSectionKey,
             LetterGradeEarned,
             NumericGradeEarned,
             LineageKey
         )
         
		SELECT DISTINCT 
		      [_sourceKey],
			  [TimeKey],
			  GradingPeriodKey,
              StudentSectionKey,
              LetterGradeEarned,
              NumericGradeEarned,
			  @LineageKey AS LineageKey
        FROM [Staging].[StudentCourseGrade]
		
		

		--re-creating the columnstore index			
		CREATE COLUMNSTORE INDEX CSI_FactStudentCourseGrades
			ON dbo.FactStudentCourseGrade
			(TimeKey,
             GradingPeriodKey,
             StudentSectionKey,
             LetterGradeEarned,
             NumericGradeEarned,
             LineageKey)
			
		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
		SET 
			EndTime = SYSDATETIME(),
			Status = 'S' -- success
		WHERE LineageKey = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.FactStudentCourseGrade';

	
	    
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
