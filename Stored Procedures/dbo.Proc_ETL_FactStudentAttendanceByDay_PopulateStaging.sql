SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Fact StudentAttendanceByDay
----------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentAttendanceByDay_PopulateStaging]
@LastLoadDate datetime,
@NewLoadDate datetime
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
	
		--DECLARE @LastLoadDate datetime= '07/01/2015' DECLARE @NewLoadDate datetime = GETDATE()
		TRUNCATE TABLE Staging.StudentAttendanceByDay	
		CREATE TABLE #StudentsToBeProcessed (StudentUSI INT, 
		                                     StudentUniqueId NVARCHAR(32), 
		                                     EventDate DATE ,
											 LastModifiedDate DATETIME )
		  
		CREATE TABLE #AttedanceEventRankedByReason (StudentUSI INT, 		                                            
		                                            SchoolId INT, 
													SchoolYear SMALLINT, 
													EventDate DATE, 
													LastModifiedDate DATETIME,
													AttendanceEventCategoryDescriptor_CodeValue NVARCHAR(50),
													AttendanceEventReason NVARCHAR(max) , 
													RowId INT  )
	    CREATE TABLE #DistinctAttedanceEvents (StudentUSI INT, 
		                                       StudentUniqueId NVARCHAR(32), 
		                                       SchoolId INT, 
											   SchoolYear SMALLINT, 
											   EventDate DATE, 
											   LastModifiedDate DATETIME,
											   AttendanceEventCategoryDescriptor_CodeValue NVARCHAR(50),
											   AttendanceEventReason NVARCHAR(max))
	
		CREATE NONCLUSTERED INDEX [#AttedanceEventRankedByReason_MainCovering]
		ON [dbo].[#AttedanceEventRankedByReason] ([StudentUSI],[SchoolId],[EventDate],[RowId])
		INCLUDE (AttendanceEventCategoryDescriptor_CodeValue,[AttendanceEventReason])

		CREATE NONCLUSTERED INDEX [#StudentsToBeProcessed_MainConvering]
		ON [dbo].[#StudentsToBeProcessed] (StudentUSI,[EventDate])
		INCLUDE ([StudentUniqueId])

		INSERT INTO #DistinctAttedanceEvents
		(
		    StudentUSI,
			StudentUniqueId,
		    SchoolId,
		    SchoolYear,
		    EventDate,
			LastModifiedDate,
		    AttendanceEventCategoryDescriptor_CodeValue,
		    AttendanceEventReason
		)
		SELECT   DISTINCT 
					ssae.StudentUSI, 
					s.StudentUniqueId,
					ssae.SchoolId, 
					ssae.SchoolYear, 
					ssae.EventDate,
					ssae.LastModifiedDate,
					d_ssae.CodeValue AS AttendanceEventCategoryDescriptor_CodeValue,					
					LTRIM(RTRIM(COALESCE(ssae.AttendanceEventReason,''))) AS AttendanceEventReason 
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSchoolAttendanceEvent ssae
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student s ON ssae.StudentUSI = s.StudentUSI
			 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d_ssae ON ssae.AttendanceEventCategoryDescriptorId = d_ssae.DescriptorId
		WHERE SchoolYear >= 2019
			AND (ssae.LastModifiedDate > @LastLoadDate  AND ssae.LastModifiedDate <= @NewLoadDate)
		

		INSERT INTO #AttedanceEventRankedByReason
		(
			StudentUSI,
			SchoolId,
			SchoolYear,
			EventDate,
			LastModifiedDate,
			AttendanceEventCategoryDescriptor_CodeValue,
			AttendanceEventReason,
			RowId
		)
		SELECT DISTINCT  
		            StudentUSI, 
					SchoolId, 
					SchoolYear, 
					EventDate,
					LastModifiedDate,
					AttendanceEventCategoryDescriptor_CodeValue,
					AttendanceEventReason , 
					ROW_NUMBER() OVER (PARTITION BY StudentUSI, 
													SchoolId, 
													SchoolYear, 
													EventDate,
													AttendanceEventCategoryDescriptor_CodeValue
										ORDER BY AttendanceEventReason DESC) AS RowId 
			FROM #DistinctAttedanceEvents

			
		IF (@LastLoadDate <> '07/01/2015')
			BEGIN
				INSERT INTO #StudentsToBeProcessed (StudentUSI, StudentUniqueId, EventDate, LastModifiedDate)
				SELECT DISTINCT StudentUSI, StudentUniqueId, EventDate, LastModifiedDate
				FROM #DistinctAttedanceEvents
			END
	    ELSE --this first time all students will be processed
			BEGIN
				INSERT INTO #StudentsToBeProcessed (StudentUSI, StudentUniqueId, EventDate, LastModifiedDate)
				SELECT DISTINCT s.StudentUSI, s.StudentUniqueId, NULL AS EventDate, NULL AS LastModifiedDate --we don't care about event changes the first this runs. 
				FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSchoolAssociation ssa
				     INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student s ON ssa.StudentUSI = s.StudentUSI
				WHERE ssa.SchoolYear >= 2019
			END;
		
		
		
		INSERT INTO Staging.StudentAttendanceByDay
		(
		    _sourceKey,
		    StudentKey,
		    TimeKey,
		    SchoolKey,
		    AttendanceEventCategoryKey,
		    AttendanceEventReason,
		    ModifiedDate,
		    _sourceStudentKey,
		    _sourceTimeKey,
		    _sourceSchoolKey,
		    _sourceAttendanceEventCategoryKey
		)	
		SELECT    DISTINCT 
				  CONCAT_WS('|','Ed-Fi',stbp.StudentUniqueId,CONVERT(CHAR(10), cdce.Date, 101)) AS _sourceKey,
				  NULL AS StudentKey,
				  NULL AS TimeKey,	  
				  NULL AS SchoolKey,  
				  NULL AS AttendanceEventCategoryKey,				  
				  ISNULL(ssae.AttendanceEventReason,'') AS AttendanceEventReason,
				  --stbp.LastModifiedDate only makes sense when identifying deltas, the first time we just follow the calendar date
				  cdce.Date AS ModifiedDate,
				  CONCAT_WS('|','Ed-Fi',stbp.StudentUniqueId) AS _sourceStudentKey,
		          cdce.Date AS _sourceTimeKey,		          
				  CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),ssa.SchoolId))  AS _sourceSchoolKey,
		          CONCAT_WS('|','Ed-Fi', ssae.AttendanceEventCategoryDescriptor_CodeValue)  AS _sourceAttendanceEventCategoryKey
				  				  
			--select *  
			FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSchoolAssociation ssa 
				INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.CalendarDate cda on ssa.SchoolId = cda.SchoolId 														   
				INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.CalendarDateCalendarEvent cdce on cda.Date=cdce.Date 
																					 and cda.SchoolId=cdce.SchoolId				
	            INNER JOIN  #StudentsToBeProcessed stbp ON ssa.StudentUSI = stbp.StudentUSI
				                                      AND (stbp.EventDate IS NULL OR 
													       cdce.Date = stbp.EventDate)
				LEFT JOIN #AttedanceEventRankedByReason ssae on ssa.StudentUSI = ssae.StudentUSI
															   AND ssa.SchoolId = ssae.SchoolId 
															   AND cda.Date = ssae.EventDate
															   AND ssae.RowId= 1	
		        
			WHERE  cdce.Date >= ssa.EntryDate 
			   AND cdce.Date <= GETDATE()
			   AND (
					 (ssa.ExitWithdrawDate is null) 
					  OR
					 (ssa.ExitWithdrawDate is not null and cdce.Date<=ssa.ExitWithdrawDate) 
				   )
				AND ssa.SchoolYear >= 2019
				AND EXISTS(SELECT 1 
				           FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d_cdce 
				           WHERE  cdce.CalendarEventDescriptorId = d_cdce.DescriptorId
								and d_cdce.CodeValue='Instructional day') -- ONLY Instructional days)
				
			DROP TABLE #StudentsToBeProcessed, #AttedanceEventRankedByReason, #DistinctAttedanceEvents;
			
			
		
	END TRY
	BEGIN CATCH
		
		--constructing exception details
		DECLARE
		   @errorMessage nvarchar( MAX ) = ERROR_MESSAGE( );		
     
		DECLARE
		   @errorDetails nvarchar( MAX ) = CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);

		PRINT @errorDetails;
		THROW 51000, @errorDetails, 1;

		
		PRINT CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);
		
		
	END CATCH;
END;
GO
