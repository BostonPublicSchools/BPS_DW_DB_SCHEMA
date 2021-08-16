SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentDiscipline_PopulateProduction]
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
			s.TimeKey =  	COALESCE(
			                 (SELECT TOP (1) dt.TimeKey
							  FROM dbo.DimTime dt
									INNER JOIN dbo.DimSchool ds ON dt.SchoolKey = ds.SchoolKey
							  WHERE s._sourceSchoolKey = ds._sourceKey
							    AND s._sourceTimeKey = dt.SchoolDate
							 ORDER BY dt.SchoolDate),
							 (SELECT TOP (1) dt.TimeKey
							  FROM dbo.DimTime dt									
							  WHERE s._sourceTimeKey = dt.SchoolDate
							 ORDER BY dt.SchoolDate)
							 ),
			s.SchoolKey =  COALESCE(
									(SELECT TOP (1) ds.SchoolKey
									FROM dbo.DimSchool ds
									WHERE s._sourceSchoolKey = ds._sourceKey									
										AND s.[ModifiedDate] >= ds.[ValidFrom]
										AND s.[ModifiedDate] < ds.[ValidTo]
									ORDER BY ds.[ValidFrom] DESC),
									(SELECT ds.SchoolKey
										FROM dbo.DimSchool ds
										WHERE ds._sourceKey = '')
							      ),		
			s.DisciplineIncidentKey =COALESCE(
										(SELECT TOP (1) ddi.DisciplineIncidentKey
										FROM dbo.DimDisciplineIncident ddi
										WHERE s._sourceDisciplineIncidentKey = ddi._sourceKey									
											AND s.[ModifiedDate] >= ddi.[ValidFrom]
											AND s.[ModifiedDate] < ddi.[ValidTo]
										ORDER BY ddi.[ValidFrom] DESC),
										(SELECT ds.DisciplineIncidentKey
										FROM dbo.DimDisciplineIncident ds
										WHERE ds._sourceKey = '')
									)  
										             
        FROM Staging.StudentDiscipline s;
		
		DELETE FROM  Staging.StudentDiscipline
		WHERE TimeKey IS NULL;

		;WITH DuplicateKeys AS 
		(
		  SELECT [StudentKey], [TimeKey],[SchoolKey],[DisciplineIncidentKey]
		  FROM  Staging.StudentDiscipline
		  GROUP BY [StudentKey], [TimeKey],[SchoolKey],[DisciplineIncidentKey]
		  HAVING COUNT(*) > 1
		)
		
		DELETE sd 
		FROM Staging.StudentDiscipline sd
		WHERE EXISTS(SELECT 1 
		             FROM DuplicateKeys dk 
					 WHERE sd.[StudentKey] = dk.StudentKey
					   AND sd.[TimeKey] = dk.[TimeKey]
					   AND sd.[SchoolKey] = dk.[SchoolKey]
					   AND sd.[DisciplineIncidentKey] = dk.[DisciplineIncidentKey])
		    

		--dropping the columnstore index
        DROP INDEX IF EXISTS CSI_FactStudentDiscipline ON dbo.FactStudentDiscipline;
	    
		--deleting changed records
		DELETE prod
		FROM [dbo].[FactStudentDiscipline] AS prod
		WHERE EXISTS (SELECT 1 
		              FROM [Staging].StudentDiscipline stage
					  WHERE prod._sourceKey = stage._sourceKey)



		INSERT INTO [dbo].[FactStudentDiscipline]
		   		([_sourceKey]
				,[StudentKey]
		   		,[TimeKey]
		   		,[SchoolKey]
		   		,[DisciplineIncidentKey]           
		   		,LineageKey)
		SELECT DISTINCT 
		    _sourceKey,
		    StudentKey,
		   	TimeKey,
		   	SchoolKey,	   
		   	DisciplineIncidentKey,	   
		   	@lineageKey AS LineageKey
		FROM Staging.StudentDiscipline


		--loading from legacy dw just once
		IF (NOT EXISTS(SELECT 1  
		               FROM dbo.FactStudentDiscipline 
		               WHERE _sourceKey = 'LegacyDW'))
             BEGIN					
					INSERT INTO [dbo].[FactStudentDiscipline]
							   ([_sourceKey]
								,[StudentKey]
							   ,[TimeKey]
							   ,[SchoolKey]
							   ,[DisciplineIncidentKey]           
							   ,LineageKey)

					SELECT DISTINCT 
						   'LegacyDW',
						   ds.StudentKey,
						   dt.TimeKey,
						   dschool.SchoolKey,	   
						   d_di.[DisciplineIncidentKey],	   
						   @lineageKey AS LineageKey
					FROM  [Raw_LegacyDW].[DisciplineIncidents] di    
						  INNER JOIN dbo.DimStudent ds  ON CONCAT_WS('|', 'LegacyDW', Convert(NVARCHAR(MAX),di.BPS_Student_ID))   = ds._sourceKey
															 AND	 di.CND_INCIDENT_DATE BETWEEN ds.ValidFrom AND ds.ValidTo
						  INNER JOIN dbo.DimSchool dschool ON CONCAT_WS('|', 'Ed-Fi', Convert(NVARCHAR(MAX),di.[SKL_SCHOOL_ID]))   = dschool._sourceKey 
															 AND	 di.CND_INCIDENT_DATE BETWEEN dschool.ValidFrom AND dschool.ValidTo
						  INNER JOIN dbo.DimTime dt ON di.CND_INCIDENT_DATE = dt.SchoolDate
														  AND dt.SchoolKey is not null   
														  AND dschool.SchoolKey = dt.SchoolKey
						  INNER JOIN dbo.DimDisciplineIncident d_di ON CONCAT_WS('|','LegacyDW',Convert(NVARCHAR(MAX),di.CND_INCIDENT_ID))    = d_di._sourceKey
					WHERE TRY_CAST(di.CND_INCIDENT_DATE AS DATETIME)  BETWEEN '2015-09-01' AND '2018-06-30' 
			 END;

        --re-creating the columnstore index
		CREATE COLUMNSTORE INDEX CSI_FactStudentDiscipline
				ON dbo.FactStudentDiscipline
				([StudentKey]
				,[TimeKey]
				,[SchoolKey]
				,[DisciplineIncidentKey]
				,LineageKey)
				

		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE LineageKey = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.FactStudentDiscipline';

		
	    
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
