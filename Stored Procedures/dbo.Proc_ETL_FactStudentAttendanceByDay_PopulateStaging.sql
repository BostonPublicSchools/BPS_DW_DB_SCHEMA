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
		                                     EventDate DATE ,
											 LastModifiedDate DATETIME )
		  
		CREATE TABLE #AttedanceEventRankedByReason (StudentUSI INT, 
		                                            SchoolId INT, 
													SchoolYear SMALLINT, 
													EventDate DATE, 
													LastModifiedDate DATETIME,
													AttendanceEventCategoryDescriptorId INT,
													AttendanceEventReason NVARCHAR(max) , 
													RowId INT  )
	    CREATE TABLE #DistinctAttedanceEvents (StudentUSI INT, 
		                                       SchoolId INT, 
											   SchoolYear SMALLINT, 
											   EventDate DATE, 
											   LastModifiedDate DATETIME,
											   AttendanceEventCategoryDescriptorId INT,
											   AttendanceEventReason NVARCHAR(max))
	
		CREATE NONCLUSTERED INDEX [#AttedanceEventRankedByReason_MainCovering]
		ON [dbo].[#AttedanceEventRankedByReason] ([StudentUSI],[SchoolId],[EventDate],[RowId])
		INCLUDE ([AttendanceEventCategoryDescriptorId],[AttendanceEventReason])


		INSERT INTO #DistinctAttedanceEvents
		(
		    StudentUSI,
		    SchoolId,
		    SchoolYear,
		    EventDate,
			LastModifiedDate,
		    AttendanceEventCategoryDescriptorId,
		    AttendanceEventReason
		)
		SELECT   DISTINCT 
					StudentUSI, 
					SchoolId, 
					SchoolYear, 
					EventDate,
					LastModifiedDate,
					AttendanceEventCategoryDescriptorId,					
					LTRIM(RTRIM(COALESCE(AttendanceEventReason,''))) AS AttendanceEventReason 
		FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentSchoolAttendanceEvent
		WHERE SchoolYear >= 2019
			AND (LastModifiedDate > @LastLoadDate  AND LastModifiedDate <= @NewLoadDate)
		

		INSERT INTO #AttedanceEventRankedByReason
		(
			StudentUSI,
			SchoolId,
			SchoolYear,
			EventDate,
			LastModifiedDate,
			AttendanceEventCategoryDescriptorId,
			AttendanceEventReason,
			RowId
		)
		SELECT DISTINCT  
		            StudentUSI, 
					SchoolId, 
					SchoolYear, 
					EventDate,
					LastModifiedDate,
					AttendanceEventCategoryDescriptorId,
					AttendanceEventReason , 
					ROW_NUMBER() OVER (PARTITION BY StudentUSI, 
													SchoolId, 
													SchoolYear, 
													EventDate,
													AttendanceEventCategoryDescriptorId
										ORDER BY AttendanceEventReason DESC) AS RowId 
			FROM #DistinctAttedanceEvents

			
		IF (@LastLoadDate <> '07/01/2015')
			BEGIN
				INSERT INTO #StudentsToBeProcessed (StudentUSI, EventDate, LastModifiedDate)
				SELECT DISTINCT StudentUSI, EventDate, LastModifiedDate
				FROM #DistinctAttedanceEvents
			END
	    ELSE --this first time all students will be processed
			BEGIN
				INSERT INTO #StudentsToBeProcessed (StudentUSI, EventDate, LastModifiedDate)
				SELECT DISTINCT StudentUSI, NULL AS EventDate, NULL AS LastModifiedDate --we don't care about event changes the first this runs. 
				FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentSchoolAssociation
				WHERE SchoolYear >= 2019
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
		SELECT DISTINCT         
				  CONCAT_WS('|',Convert(NVARCHAR(MAX),ssa.StudentUSI),CONVERT(CHAR(10), cdce.Date, 101)) AS _sourceKey,
				  NULL AS StudentKey,
				  NULL AS TimeKey,	  
				  NULL AS SchoolKey,  
				  NULL AS AttendanceEventCategoryKey,				  
				  ISNULL(ssae.AttendanceEventReason,'') AS AttendanceEventReason,
				  --stbp.LastModifiedDate only makes sense when identifying deltas, the first time we just follow the calendar date
				  cdce.Date AS ModifiedDate,
				  CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),ssa.StudentUSI)) AS _sourceStudentKey,
		          cdce.Date AS _sourceTimeKey,		          
				  CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),ssa.SchoolId))  AS _sourceSchoolKey,
		          CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),ssae.AttendanceEventCategoryDescriptorId))  AS _sourceAttendanceEventCategoryKey
				  				  
			--select *  
			FROM [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentSchoolAssociation ssa 
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CalendarDate cda on ssa.SchoolId = cda.SchoolId 														   
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.CalendarDateCalendarEvent cdce on cda.Date=cdce.Date 
																					 and cda.SchoolId=cdce.SchoolId
				INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor d_cdce on cdce.CalendarEventDescriptorId = d_cdce.DescriptorId
																	  and d_cdce.CodeValue='Instructional day' -- ONLY Instructional days
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
