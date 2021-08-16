SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_DimStudentSection_PopulateProduction]
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
		 
		--empty row technique
		--fact table should not have null foreign keys references
		--this empty record will be used in those cases
		IF NOT EXISTS (SELECT 1 
		               FROM dbo.DimStudentSection WHERE _sourceKey = '')
				BEGIN
				   INSERT INTO dbo.DimStudentSection
				   (
				       _sourceKey,
				       StudentKey,
				       SchoolKey,
				       CourseKey,
				       StaffKey,
				       StudentSectionBeginDate,
				       StudentSectionEndDate,
				       SchoolYear,
				       ValidFrom,
				       ValidTo,
				       IsCurrent,
					   IsLatest,
				       LineageKey
				   )
				   VALUES
				   (   N'',       -- _sourceKey - nvarchar(50)
				       0,         -- StudentKey - int
				       0,         -- SchoolKey - int
				       0,         -- CourseKey - int
				       0,         -- StaffKey - int
				       GETDATE(), -- StudentSectionBeginDate - date
				       GETDATE(), -- StudentSectionEndDate - date
				       0,         -- SchoolYear - int
				       '07/01/2015', -- ValidFrom - datetime
					   '9999-12-31', -- ValidTo - datetime
				       0,      -- IsCurrent - bit
					   1,      -- IsLatest - bit
				       -1          -- LineageKey - int
				       )
				
				END
        --updating staging keys
		UPDATE s 
		SET s.StudentKey = COALESCE(
								(SELECT TOP (1) ds.StudentKey
								FROM dbo.DimStudent ds
								WHERE s._sourceStudentKey = ds._sourceKey									
									AND s.ValidFrom >= ds.[ValidFrom]
									AND s.ValidFrom < ds.[ValidTo]
								ORDER BY ds.[ValidFrom] DESC),
								(SELECT ds.StudentKey
								 FROM dbo.DimStudent ds
								 WHERE ds._sourceKey = '')
							),
			s.SchoolKey = COALESCE(
									(SELECT TOP (1) ds.SchoolKey
									 FROM dbo.DimSchool ds
									 WHERE s.[_sourceSchoolKey] = ds._sourceKey									
										AND s.ValidFrom >= ds.[ValidFrom]
										AND s.ValidFrom < ds.[ValidTo]
									ORDER BY ds.[ValidFrom] DESC),
									(SELECT ds.SchoolKey
									 FROM dbo.DimSchool ds
									 WHERE ds._sourceKey = '')
							      ) ,
			s.CourseKey = COALESCE(
								(SELECT TOP (1) dc.CourseKey
								FROM dbo.DimCourse dc
								WHERE s._sourceCourseKey = dc._sourceKey									
									AND s.ValidFrom >= dc.[ValidFrom]
									AND s.ValidFrom < dc.[ValidTo]
								ORDER BY dc.[ValidFrom] DESC),
								(SELECT ds.CourseKey
								 FROM dbo.DimCourse ds
								 WHERE ds._sourceKey = '')

							)	,
			s.StaffKey = COALESCE(
								(SELECT TOP (1) ds.StaffKey
								FROM dbo.DimStaff ds
								WHERE s._sourceCourseKey = ds._sourceKey									
									AND s.ValidFrom >= ds.[ValidFrom]
									AND s.ValidFrom < ds.[ValidTo]
								ORDER BY ds.[ValidFrom] DESC),
								(SELECT ds.StaffKey
								 FROM dbo.DimStaff ds
								 WHERE ds._sourceKey = '')
							)
        FROM Staging.StudentSection s;


		--staging table holds newer records. 
		--the matching prod records will be valid until the date in which the newest data change was identified		
		UPDATE prod
		SET prod.ValidTo = stage.ValidFrom,
		    prod.IsLatest = 0
		FROM 
			[dbo].DimStudentSection AS prod
			INNER JOIN Staging.StudentSection AS stage ON prod._sourceKey = stage._sourceKey
		WHERE prod.ValidTo = '12/31/9999'


		INSERT INTO dbo.DimStudentSection
		(
		    _sourceKey,
		    StudentKey,
		    SchoolKey,
		    CourseKey,
		    StaffKey,
		    StudentSectionBeginDate,
		    StudentSectionEndDate,
		    SchoolYear,
		    ValidFrom,
		    ValidTo,
		    IsCurrent,
			IsLatest,
		    LineageKey
		)
		

		SELECT [_sourceKey]
			  ,[StudentKey]
			  ,[SchoolKey]
			  ,[CourseKey]
			  ,[StaffKey]
			  ,[StudentSectionBeginDate]
			  ,[StudentSectionEndDate]
			  ,[SchoolYear]      
			  ,[ValidFrom]
			  ,[ValidTo]
			  ,[IsCurrent]
			  ,1 AS [IsLatest]
		      ,@LineageKey
		FROM Staging.StudentSection

		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE LineageKey = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.DimStudentSection';

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
