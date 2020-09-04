SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentCourseTranscript_PopulateProduction]
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
		 
		--dropping the columnstore index
		--DROP INDEX IF EXISTS CSI_FactStudentAttendanceByDay ON dbo.FactStudentAttendanceByDay;
      
	    --updating staging keys

		/*
		--deleting changed records
		DELETE prod
		FROM [dbo].FactStudentAttendanceByDay AS prod
		WHERE EXISTS (SELECT 1 
		              FROM [Staging].StudentAttendanceByDay stage
					  WHERE prod._sourceAttendanceEvent = stage._sourceAttendanceEvent);
	    
		
		INSERT INTO dbo.FactStudentAttendanceByDay
		(
		    StudentKey,
		    TimeKey,
		    SchoolKey,
		    AttendanceEventCategoryKey,
		    AttendanceEventReason,
		    LineageKey
		)
		SELECT 
		    StudentKey,
		    TimeKey,
		    SchoolKey,
		    AttendanceEventCategoryKey,
		    AttendanceEventReason,
			@LineageKey		
		FROM Staging.StudentAttendanceByDay
		*/

		IF NOT exists ( SELECT 1 FROM dbo.FactStudentCourseTranscript)
		BEGIN
		   DROP INDEX IF EXISTS CSI_FactStudentCourseTranscript ON dbo.FactStudentCourseTranscript;
		   ;WITH SchoolTermsFirstDates AS 
			(
			  SELECT DISTINCT SchoolKey, 
							  SchoolTermDescriptor_CodeValue AS Term,
							  SchoolYear,
							  MIN(SchoolDate) OVER (PARTITION BY SchoolKey, SchoolTermDescriptor_CodeValue, SchoolYear) AS MinTermDate
			  FROM EdFiDW.dbo.DimTime 
			  WHERE SchoolKey IS NOT NULL

			)
		   INSERT INTO [dbo].FactStudentCourseTranscript
		   			([_sourceKey]
					,[StudentKey]
					,[TimeKey]
					,[CourseKey]
					,[SchoolKey]
					,EarnedCredits
					,PossibleCredits 
					,FinalLetterGradeEarned
					,FinalNumericGradeEarned
					,[LineageKey])
		    
			SELECT DISTINCT
					'EdFi',
					ds.StudentKey,
					dt.TimeKey,
					dcourse.CourseKey,	  
					dschool.SchoolKey,      
					ct.EarnedCredits,
					ct.AttemptedCredits,
					ct.FinalLetterGradeEarned,
					ct.FinalNumericGradeEarned,
					@lineageKey AS [LineageKey]
			--select *  
			FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CourseTranscript ct
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor td ON ct.TermDescriptorId = td.DescriptorId
	
				--joining DW tables
				INNER JOIN EdFiDW.dbo.DimStudent ds  ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),ct.StudentUSI)   = ds._sourceKey
				INNER JOIN EdFiDW.dbo.DimSchool dschool ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),ct.SchoolId)   = dschool._sourceKey
				INNER JOIN EdFiDW.dbo.DimCourse dcourse ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),ct.CourseCode)   = dcourse._sourceKey
	
				INNER JOIN EdFiDW.dbo.DimTime dt on dt.SchoolKey is not null   
												and dschool.SchoolKey = dt.SchoolKey
												and td.CodeValue = dt.SchoolTermDescriptor_CodeValue
												AND ct.SchoolYear = dt.SchoolYear

			WHERE  dt.SchoolDate BETWEEN ds.ValidFrom  AND ds.ValidTo
				AND dt.SchoolDate BETWEEN dschool.ValidFrom AND dschool.ValidTo
				AND dt.SchoolDate BETWEEN dcourse.ValidFrom AND dcourse.ValidTo
				AND dt.SchoolDate <= GETDATE()   
				--AND dt.SchoolTermDescriptor_CodeValue = 'Other' --year long only
				AND ct.SchoolYear IN (2019, 2020)
				AND EXISTS (SELECT 1
							FROM SchoolTermsFirstDates std 
							WHERE dschool.SchoolKey = std.SchoolKey
								AND dt.SchoolTermDescriptor_CodeValue = std.Term
								AND dt.SchoolYear = std.SchoolYear
								AND dt.SchoolDate = std.MinTermDate)

			--legacy 			
			INSERT INTO [dbo].FactStudentCourseTranscript
					   ([_sourceKey]
					    ,[StudentKey]
						,[TimeKey]
						,[CourseKey]
						,[SchoolKey]
						,EarnedCredits
						,PossibleCredits 
						,FinalLetterGradeEarned
						,FinalNumericGradeEarned
						,[LineageKey])
		    
			SELECT DISTINCT
                    'LegacyDW',
					ds.StudentKey,
					dt.TimeKey,
					dcourse.CourseKey,	  
					dschool.SchoolKey,      
					COALESCE(scg.CreditsEarned,0) AS EarnedCredits,
					scg.CreditsPossible AS PossibleCredits,
					CASE WHEN scg.CreditsEarned = 0 AND scg.FinalMark IS NULL THEN 'NC'
					ELSE
						CASE WHEN TRY_CAST(scg.FinalMark AS DECIMAL) IS NULL THEN scg.FinalMark 
						ELSE NULL 
						END 
					END AS FinalLetterGradeEarned,
					CASE WHEN TRY_CAST(scg.FinalMark AS DECIMAL) IS NOT NULL THEN scg.FinalMark ELSE NULL END AS FinalNumericGradeEarned,
					--dt.SchoolDate, *
					@lineageKey AS [LineageKey]
			--select *  
			FROM [BPSGranary02].[RAEDatabase].[dbo].[StudentCourseGrade_aspenNewFormat] scg
    
				--joining DW tables
				INNER JOIN EdFiDW.dbo.DimStudent ds  ON CONCAT_WS('|','LegacyDW',Convert(NVARCHAR(MAX),scg.StudentNo))  = ds._sourceKey
	      
				INNER JOIN EdFiDW.dbo.DimSchool dschool ON CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),scg.SchoolID))   = dschool._sourceKey
				INNER JOIN EdFiDW.dbo.DimCourse dcourse ON CONCAT('LegacyDW|',scg.CourseNumber,'-',CASE WHEN scg.SectionID = '' THEN 'N/A' ELSE scg.SectionID END)  = dcourse._sourceKey	
				INNER JOIN EdFiDW.dbo.DimTime dt on dt.SchoolKey is not null   
												and dschool.SchoolKey = dt.SchoolKey
												and CASE WHEN scg.Semester IN ('A','MS Pre-Algebra','Advisory') AND dt.SchoolTermDescriptor_CodeValue = 'Other' THEN 1									         
															WHEN scg.Semester IN ('SS') AND dt.SchoolTermDescriptor_CodeValue = 'Summer Semester' THEN 1
															WHEN scg.Semester IN ('1') AND dt.SchoolTermDescriptor_CodeValue = 'Fall Semester' THEN 1
															WHEN scg.Semester IN ('2') AND dt.SchoolTermDescriptor_CodeValue = 'Spring Semester' THEN 1
										
															WHEN scg.Semester IN ('Q1') AND dt.SchoolTermDescriptor_CodeValue = 'First Quarter' THEN 1
															WHEN scg.Semester IN ('Q123','Q13','Q14','Q23','Q24','T124','T234') AND dt.SchoolTermDescriptor_CodeValue = 'Other' THEN 1											 
															WHEN scg.Semester IN ('Q2') AND dt.SchoolTermDescriptor_CodeValue = 'Second Quarter' THEN 1
															WHEN scg.Semester IN ('Q3') AND dt.SchoolTermDescriptor_CodeValue = 'Third Quarter' THEN 1
															WHEN scg.Semester IN ('Q4','T4') AND dt.SchoolTermDescriptor_CodeValue = 'Fourth Quarter' THEN 1											 

											 

															WHEN scg.Semester IN ('T1') AND scg.SchoolID IN ('4580','1064','1420') AND dt.SchoolTermDescriptor_CodeValue = 'First Quarter' THEN 1
															WHEN scg.Semester IN ('T1') AND dt.SchoolTermDescriptor_CodeValue = 'First Trimester' THEN 1

															WHEN scg.Semester IN ('T2') AND scg.SchoolID IN ('4580','1064','1420') AND dt.SchoolTermDescriptor_CodeValue = 'Second Quarter' THEN 1
															WHEN scg.Semester IN ('T2') AND dt.SchoolTermDescriptor_CodeValue = 'Second Trimester' THEN 1

															WHEN scg.Semester IN ('T3') AND scg.SchoolID IN ('4580','1064','1420') AND dt.SchoolTermDescriptor_CodeValue = 'Third Quarter' THEN 1
															WHEN scg.Semester IN ('T3') AND dt.SchoolTermDescriptor_CodeValue = 'Third Trimester' THEN 1
															ELSE 0
													END = 1
												AND RIGHT(RTRIM(scg.SchoolYear),4) = dt.SchoolYear

			WHERE   dt.SchoolDate BETWEEN ds.ValidFrom  AND ds.ValidTo
				AND dt.SchoolDate BETWEEN dschool.ValidFrom AND dschool.ValidTo
				AND dt.SchoolDate BETWEEN dcourse.ValidFrom AND dcourse.ValidTo
				AND scg.SchoolYear IN ('2015-2016','2016-2017', '2017-2018')	   
				AND scg.FinalMark IS NOT NULL
					AND EXISTS (SELECT 1
							FROM SchoolTermsFirstDates std 
							WHERE dschool.SchoolKey = std.SchoolKey
								AND dt.SchoolTermDescriptor_CodeValue = std.Term
								AND dt.SchoolYear = std.SchoolYear
								AND dt.SchoolDate = std.MinTermDate)
					AND COALESCE(scg.CreditsEarned,0) > 0

			--re-creating the columnstore index			
			CREATE COLUMNSTORE INDEX CSI_FactStudentCourseTranscript
				ON dbo.FactStudentCourseTranscript
				([StudentKey]
				,[TimeKey]
				,[CourseKey]
				,[SchoolKey]
				,[EarnedCredits]
				,[PossibleCredits]
				,[FinalLetterGradeEarned]
				,[FinalNumericGradeEarned]
				,[LineageKey])
			

        END;

		


		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE [LineageKey] = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.FactStudentCourseTranscript';

		
	    
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
