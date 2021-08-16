SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[Proc_ETL_DimTime_PopulateProduction]
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
		UPDATE t
		SET t.SchoolKey =  COALESCE(
									(SELECT TOP (1) ds.SchoolKey
									 FROM dbo.DimSchool ds
									 WHERE t._sourceSchoolKey = ds._sourceKey									
										AND t.ValidFrom >= ds.[ValidFrom]
										AND t.ValidFrom < ds.[ValidTo]
									ORDER BY ds.[ValidFrom] DESC),
									(SELECT ds.SchoolKey
									 FROM dbo.DimSchool ds
									 WHERE ds._sourceKey = '')
							      ) 
        --select *
		FROM Staging.[Time] t
		WHERE t._sourceSchoolKey IS NOT NULL; -- schools are not always required

		
		
		--staging table holds newer records. 
		--the matching prod records will be valid until the date in which the newest data change was identified
		UPDATE prod
		SET prod.ValidTo = stage.ValidFrom,
		    prod.IsLatest = 0
		FROM 
			[dbo].[DimTime] AS prod
			INNER JOIN Staging.[Time] AS stage ON prod.SchoolDate = stage.SchoolDate
		WHERE prod.ValidTo = '12/31/9999'
		
		INSERT INTO dbo.DimTime
		(
		    [SchoolDate]
           ,[SchoolDate_MMYYYY]
           ,[SchoolDate_Fomat1]
           ,[SchoolDate_Fomat2]
           ,[SchoolDate_Fomat3]
           ,[SchoolYear]
           ,[SchoolYearDescription]
           ,[CalendarYear]
           ,[DayOfMonth]
           ,[DaySuffix]
           ,[DayName]
           ,[DayNameShort]
           ,[DayOfWeek]
           ,[WeekInMonth]
           ,[WeekOfMonth]
           ,[Weekend_Indicator]
           ,[WeekOfYear]
           ,[FirstDayOfWeek]
           ,[LastDayOfWeek]
           ,[WeekBeforeChristmas_Indicator]
           ,[Month]
           ,[MonthName]
           ,[MonthNameShort]
           ,[FirstDayOfMonth]
           ,[LastDayOfMonth]
           ,[FirstDayOfNextMonth]
           ,[LastDayOfNextMonth]
           ,[DayOfYear]
           ,[LeapYear_Indicator]
           ,[FederalHolidayName]
           ,[FederalHoliday_Indicator]
           
		   ,[SchoolKey]
		   ,DayOfSchoolYear
           ,SchoolCalendarEventType_CodeValue
           ,SchoolCalendarEventType_Description
           ,SchoolTermDescriptor_CodeValue
           ,SchoolTermDescriptor_Description
		   
           ,[ValidFrom]
           ,[ValidTo]
           ,[IsCurrent]
		   ,[IsLatest]
           ,LineageKey
		)
		SELECT 
		    st.[SchoolDate]
           ,st.[SchoolDate_MMYYYY]
           ,st.[SchoolDate_Fomat1]
           ,st.[SchoolDate_Fomat2]
           ,st.[SchoolDate_Fomat3]
           ,st.[SchoolYear]
           ,st.[SchoolYearDescription]
           ,st.[CalendarYear]
           ,st.[DayOfMonth]
           ,st.[DaySuffix]
           ,st.[DayName]
           ,st.[DayNameShort]
           ,st.[DayOfWeek]
           ,st.[WeekInMonth]
           ,st.[WeekOfMonth]
           ,st.[Weekend_Indicator]
           ,st.[WeekOfYear]
           ,st.[FirstDayOfWeek]
           ,st.[LastDayOfWeek]
           ,st.[WeekBeforeChristmas_Indicator]
           ,st.[Month]
           ,st.[MonthName]
           ,st.[MonthNameShort]
           ,st.[FirstDayOfMonth]
           ,st.[LastDayOfMonth]
           ,st.[FirstDayOfNextMonth]
           ,st.[LastDayOfNextMonth]
           ,st.[DayOfYear]
           ,st.[LeapYear_Indicator]
           ,st.[FederalHolidayName]
           ,st.[FederalHoliday_Indicator]
           ,st.SchoolKey		   
		   ,st.DayOfSchoolYear
           ,st.SchoolCalendarEventType_CodeValue
           ,st.SchoolCalendarEventType_Description
           ,st.SchoolTermDescriptor_CodeValue
           ,st.SchoolTermDescriptor_Description
		   
           ,st.[ValidFrom]
           ,st.[ValidTo]
           ,st.[IsCurrent]
		   ,1 AS [IsLatest]
		   ,@LineageKey
		FROM Staging.[Time] st

		-- updating the EndTime to now and status to Success		
		UPDATE dbo.ETL_Lineage
			SET 
				EndTime = SYSDATETIME(),
				Status = 'S' -- success
		WHERE LineageKey = @LineageKey;
	
	
		-- Update the LoadDates table with the most current load date
		UPDATE [dbo].[ETL_IncrementalLoads]
		SET [LoadDate] = @LastDateLoaded
		WHERE [TableName] = N'dbo.DimTime';

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
