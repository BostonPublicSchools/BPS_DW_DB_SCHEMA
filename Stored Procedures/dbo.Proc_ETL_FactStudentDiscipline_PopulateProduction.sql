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

		IF NOT exists ( SELECT 1 FROM dbo.FactStudentDiscipline)
		BEGIN
		   DROP INDEX IF EXISTS CSI_FactStudentDiscipline ON dbo.FactStudentDiscipline;
		   		   	   
		   INSERT INTO [dbo].[FactStudentDiscipline]
		   			([_sourceKey]
					,[StudentKey]
		   			,[TimeKey]
		   			,[SchoolKey]
		   			,[DisciplineIncidentKey]           
		   			,[LineageKey])
		   
		   SELECT DISTINCT 
		       'EdFi',
		   		ds.StudentKey,
		   		dt.TimeKey,
		   		dschool.SchoolKey,	   
		   		d_di.[DisciplineIncidentKey],	   
		   		@lineageKey AS LineageKey
		   FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.DisciplineIncident di       
		   		INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentDisciplineIncidentAssociation sdia ON di.IncidentIdentifier = sdia.IncidentIdentifier
		   		INNER JOIN dbo.DimSchool dschool ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),di.SchoolId)   = dschool._sourceKey
		   												AND di.IncidentDate BETWEEN dschool.ValidFrom AND dschool.ValidTo
		   		INNER JOIN dbo.DimTime dt ON di.IncidentDate = dt.SchoolDate
		   												AND dt.SchoolKey is not null   
		   	                 							AND dschool.SchoolKey = dt.SchoolKey
		   		INNER JOIN dbo.DimStudent ds  ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),sdia.StudentUSI)   = ds._sourceKey
		   											AND di.IncidentDate BETWEEN ds.ValidFrom AND ds.ValidTo
	  	   
		   		INNER JOIN dbo.DimDisciplineIncident d_di ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),di.IncidentIdentifier)   = d_di._sourceKey

			--legacy 			
			INSERT INTO [dbo].[FactStudentDiscipline]
					   ([_sourceKey]
					    ,[StudentKey]
					   ,[TimeKey]
					   ,[SchoolKey]
					   ,[DisciplineIncidentKey]           
					   ,[LineageKey])

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
			WHERE TRY_CAST(di.CND_INCIDENT_DATE AS DATETIME)  > '2015-09-01'
			--re-creating the columnstore index
			CREATE COLUMNSTORE INDEX CSI_FactStudentDiscipline
				  ON dbo.FactStudentDiscipline
				  ([StudentKey]
				  ,[TimeKey]
				  ,[SchoolKey]
				  ,[DisciplineIncidentKey]
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
