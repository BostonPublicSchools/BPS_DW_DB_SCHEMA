SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentAttendanceByDay_PopulateProduction]
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
		SET s.StudentKey = (
								SELECT TOP (1) ds.StudentKey
								FROM dbo.DimStudent ds
								WHERE s._sourceStudentKey = ds._sourceKey									
									AND s.[ModifiedDate] >= ds.[ValidFrom]
									AND s.[ModifiedDate] < ds.[ValidTo]
								ORDER BY ds.[ValidFrom] DESC
							),
			s.TimeKey = (
							SELECT TOP (1) dt.TimeKey
							FROM dbo.DimTime dt
									INNER JOIN dbo.DimSchool ds ON dt.SchoolKey = ds.SchoolKey
							WHERE s._sourceSchoolKey = ds._sourceKey
								AND s._sourceTimeKey = dt.SchoolDate
							ORDER BY dt.SchoolDate
						),
			s.SchoolKey = (
								SELECT TOP (1) ds.SchoolKey
								FROM dbo.DimSchool ds
								WHERE s._sourceSchoolKey = ds._sourceKey									
									AND s.[ModifiedDate] >= ds.[ValidFrom]
									AND s.[ModifiedDate] < ds.[ValidTo]
								ORDER BY ds.[ValidFrom] DESC
							),		
			s.AttendanceEventCategoryKey = COALESCE(
													(
														SELECT TOP (1) daec.AttendanceEventCategoryKey
														FROM dbo.DimAttendanceEventCategory daec
														WHERE s._sourceAttendanceEventCategoryKey = daec._sourceKey									
														  AND s.[ModifiedDate] >= daec.[ValidFrom]
														  AND s.[ModifiedDate] < daec.[ValidTo]
														ORDER BY daec.[ValidFrom]
													), 
													(
													 SELECT TOP(1) AttendanceEventCategoryKey 
													 FROM [dbo].DimAttendanceEventCategory 
													 WHERE AttendanceEventCategoryDescriptor_CodeValue = 'In Attendance'
													)  
										          )     
        FROM Staging.StudentAttendanceByDay s;
		
		DELETE FROM Staging.StudentAttendanceByDay
		WHERE StudentKey IS NULL OR 
		      TimeKey IS NULL OR
			  SchoolKey IS NULL OR
			  AttendanceEventCategoryKey IS NULL;

		--dropping the columnstore index
		DROP INDEX IF EXISTS CSI_FactStudentAttendanceByDay ON dbo.FactStudentAttendanceByDay;

		--deleting changed records
		DELETE prod
		FROM [dbo].FactStudentAttendanceByDay AS prod
		WHERE EXISTS (SELECT 1 
		              FROM [Staging].StudentAttendanceByDay stage
					  WHERE prod._sourceKey = stage._sourceKey)
					  
	    
		
		INSERT INTO dbo.FactStudentAttendanceByDay
		(
		    _sourceKey,
		    StudentKey,
		    TimeKey,
		    SchoolKey,
		    AttendanceEventCategoryKey,
		    AttendanceEventReason,
		    LineageKey
		)
		SELECT DISTINCT 
		    _sourceKey,
		    StudentKey,
		    TimeKey,
		    SchoolKey,
		    AttendanceEventCategoryKey,
		    AttendanceEventReason,
			@LineageKey		
		FROM Staging.StudentAttendanceByDay

			
		--loading from legacy dw just once
		IF (NOT EXISTS(SELECT 1  
		               FROM dbo.FactStudentAttendanceByDay 
		               WHERE _sourceKey = 'LegacyDW'))
			  BEGIN
			     INSERT INTO EdFiDW.[dbo].[FactStudentAttendanceByDay]
					   (_sourceKey,
					    [StudentKey]
					   ,[TimeKey]
					   ,[SchoolKey]
					   ,[AttendanceEventCategoryKey]
					   ,[AttendanceEventReason]
					   ,[LineageKey])
				SELECT 
				      'LegacyDW' AS _sourceKey,
					  ds.StudentKey,
					  dt.TimeKey,	  
					  dschool.SchoolKey,      
					  daec.AttendanceEventCategoryKey,
					  'N/A' AS  AttendanceEventReason,
					  @LineageKey AS [LineageKey]
				--select top 100  a.*
				FROM [BPSGranary02].[BPSDW].[dbo].[Attendance] a	
					--joining DW tables
					INNER JOIN EdFiDW.dbo.DimStudent ds  ON CONCAT_WS('|', 'LegacyDW', Convert(NVARCHAR(MAX),a.[StudentNo]))   = ds._sourceKey
													   AND a.[Date] BETWEEN ds.ValidFrom AND ds.ValidTo
					INNER JOIN EdFiDW.dbo.DimSchool dschool ON CONCAT_WS('|', 'Ed-Fi', Convert(NVARCHAR(MAX),a.Sch))   = dschool._sourceKey -- all schools except one (inactive) are Ed-Fi
													   AND a.[Date] BETWEEN dschool.ValidFrom AND dschool.ValidTo
					INNER JOIN EdFiDW.dbo.DimTime dt ON a.[Date] = dt.SchoolDate
													and dt.SchoolKey is not null   
													and dschool.SchoolKey = dt.SchoolKey
					INNER JOIN EdFiDW.[dbo].DimAttendanceEventCategory daec ON CASE 
																					WHEN a.AttendanceCodeDesc IN ('Absent') THEN 'Unexcused Absence'
																					WHEN a.AttendanceCodeDesc IN ('Absent, Bus Strike','Bus / Transportation','Excused Absent','In School, Suspended','Suspended') THEN 'Excused Absence'
																					WHEN a.AttendanceCodeDesc IN ('Early Dismissal','Dismissed')  THEN 'Early departure'
																					WHEN a.AttendanceCodeDesc = 'No Contact'  THEN 'No Contact'
																					WHEN CHARINDEX('Tardy',a.AttendanceCodeDesc,1) > 0 THEN 'Tardy'
																					ELSE 'In Attendance' 	                                                                   
																				END = daec.AttendanceEventCategoryDescriptor_CodeValue
 
				WHERE  a.[Date] >= '2015-07-01'
			  END

		--re-creating the columnstore index
		CREATE COLUMNSTORE INDEX CSI_FactStudentAttendanceByDay
			  ON dbo.FactStudentAttendanceByDay
			  ([StudentKey]
			  ,[TimeKey]
			  ,[SchoolKey]
			  ,[AttendanceEventCategoryKey]
			  ,[AttendanceEventReason]
			  ,[LineageKey])

		--Deriving
		--dropping the columnstore index
		DROP INDEX IF EXISTS CSI_Derived_StudentAttendanceByDay ON Derived.StudentAttendanceByDay;

		--ByDay
		delete d_sabd
		FROM  [Derived].[StudentAttendanceByDay] d_sabd
		WHERE EXISTS(SELECT 1 
		             FROM Staging.StudentAttendanceByDay s_sabd
					 WHERE d_sabd.StudentKey = s_sabd.StudentKey
					    AND d_sabd.[TimeKey] = s_sabd.[TimeKey])

		INSERT INTO [Derived].[StudentAttendanceByDay]
					([StudentKey]
					,[TimeKey]
					,[SchoolKey]
					,AttendanceEventCategoryKey
					,[EarlyDeparture]
					,[ExcusedAbsence]
					,[UnexcusedAbsence]
					,[NoContact]
					,[InAttendance]
					,[Tardy])

		SELECT 
				StudentKey, 
				TimeKey, 
				SchoolKey,
				AttendanceEventCategoryKey,
				--pivoted from row values	  
				CASE WHEN [Early departure] IS NULL THEN 0 ELSE 1 END AS EarlyDeparture,
				CASE WHEN [Excused Absence] IS NULL THEN 0 ELSE 1 END AS [ExcusedAbsence],
				CASE WHEN [Unexcused Absence] IS NULL THEN 0 ELSE 1 END AS [UnexcusedAbsence],
				CASE WHEN [No Contact] IS NULL THEN 0 ELSE 1 END AS [NoContact],
				CASE WHEN [In Attendance] IS NULL THEN 0 ELSE 1 END AS [InAttendance],
				CASE WHEN [Tardy] IS NULL THEN 0 ELSE 1 END AS [Tardy]	     
	   
		FROM (
				SELECT fsabd.StudentKey,
						fsabd.TimeKey,
						fsabd.SchoolKey,
						fsabd.AttendanceEventCategoryKey,
						dact.AttendanceEventCategoryDescriptor_CodeValue AS AttendanceType	       	 			 			   
				FROM dbo.[FactStudentAttendanceByDay] fsabd 
				        INNER JOIN Staging.StudentAttendanceByDay s_sabd ON fsabd.StudentKey = s_sabd.StudentKey
					                                                    AND fsabd.[TimeKey] = s_sabd.[TimeKey]
						INNER JOIN dbo.DimStudent ds ON fsabd.StudentKey = ds.StudentKey
						INNER JOIN dbo.DimAttendanceEventCategory dact ON fsabd.AttendanceEventCategoryKey = dact.AttendanceEventCategoryKey		
				WHERE 1=1 
				--AND ds.StudentUniqueId = 341888
				--AND dt.SchoolDate = '2018-10-26'

		
			) AS SourceTable 
		PIVOT 
			(
				MAX(AttendanceType)
				FOR AttendanceType IN ([Early departure],
										[Excused Absence],
										[Unexcused Absence],
										[No Contact],
										[In Attendance],
										[Tardy]
								)
			) AS PivotTable;
			
		CREATE COLUMNSTORE INDEX CSI_Derived_StudentAttendanceByDay
			ON Derived.StudentAttendanceByDay
			([StudentKey]
			,[TimeKey]
			,[SchoolKey]
			,[EarlyDeparture]
			,[ExcusedAbsence]
			,[UnexcusedAbsence]
			,[NoContact]
			,[InAttendance]
			,[Tardy])
			
		--ADA
		
		DELETE d_sabd
		FROM  [Derived].[StudentAttendanceADA] d_sabd
		WHERE EXISTS(SELECT 1 
		             FROM Staging.StudentAttendanceByDay s_sabd
					      INNER JOIN dbo.DimTime dt ON s_sabd.TimeKey = dt.TimeKey
						  INNER JOIN dbo.DimStudent st ON s_sabd.StudentKey = st.StudentKey
					 WHERE d_sabd.StudentId = st.StudentUniqueId
					   AND d_sabd.[SchoolYear] = dt.SchoolYear)
					   
		INSERT INTO [Derived].[StudentAttendanceADA]([StudentId]
																
																,[FirstName]
																,[LastName]
																,[DistrictSchoolCode]
																,[UmbrellaSchoolCode]
																,[SchoolName]
																,[SchoolYear]
																,[NumberOfDaysPresent]
																,[NumberOfDaysAbsent]
																,[NumberOfDaysAbsentUnexcused]
																,[NumberOfDaysMembership]
																,[ADA])

		SELECT     DISTINCT
					v_sabd.StudentId, 
					v_sabd.FirstName, 
					v_sabd.LastName, 
					v_sabd.[DistrictSchoolCode],
					v_sabd.[UmbrellaSchoolCode],	   
					v_sabd.SchoolName, 	   
					v_sabd.SchoolYear,	   
					COUNT(DISTINCT (CASE WHEN v_sabd.InAttendance =1 THEN v_sabd.AttedanceDate ELSE NULL END))   AS NumberOfDaysPresent,
					COUNT(DISTINCT (CASE WHEN v_sabd.InAttendance =0 THEN v_sabd.AttedanceDate ELSE NULL END))  AS NumberOfDaysAbsent,
					COUNT(DISTINCT (CASE WHEN v_sabd.[UnexcusedAbsence] =1 THEN v_sabd.AttedanceDate ELSE NULL END))    AS NumberOfDaysAbsentUnexcused,
					COUNT(DISTINCT v_sabd.AttedanceDate)   AS NumberOfDaysMembership,
					COUNT(DISTINCT (CASE WHEN v_sabd.InAttendance =1 THEN v_sabd.AttedanceDate ELSE NULL END)) / CONVERT(Float,COUNT(DISTINCT v_sabd.AttedanceDate)) * 100 AS ADA			
		FROM dbo.View_StudentAttendanceByDay v_sabd		
		WHERE EXISTS(SELECT 1 
		             FROM Staging.StudentAttendanceByDay s_sabd
					      INNER JOIN dbo.DimTime dt ON s_sabd.TimeKey = dt.TimeKey
						  INNER JOIN dbo.DimStudent st ON s_sabd.StudentKey = st.StudentKey
					 WHERE v_sabd.StudentId = st.StudentUniqueId
					   AND v_sabd.[SchoolYear] = dt.SchoolYear)
		GROUP BY    v_sabd.StudentId, 
					
					v_sabd.FirstName, 
					v_sabd.LastName, 
					v_sabd.[DistrictSchoolCode],
					v_sabd.[UmbrellaSchoolCode],	   
					v_sabd.SchoolName, 	   
					v_sabd.SchoolYear

		

        -- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE [LineageKey] = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.FactStudentAttendanceByDay';
		
	    
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
