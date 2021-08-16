SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--Dim AttendanceEventCategory
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimAttendanceEventCategory_PopulateStaging]
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

		TRUNCATE TABLE Staging.AttendanceEventCategory
		INSERT INTO Staging.AttendanceEventCategory
				   ([_sourceKey]
					,[AttendanceEventCategoryDescriptor_CodeValue]
					,[AttendanceEventCategoryDescriptor_Description]
					,[InAttendance_Indicator]
					,[UnexcusedAbsence_Indicator]
					,[ExcusedAbsence_Indicator]
					,[Tardy_Indicator]
					,[EarlyDeparture_Indicator]
					,[CategoryModifiedDate]
					,[ValidFrom]
					,[ValidTo]
					,[IsCurrent])
        --declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT  DISTINCT 
			    CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),d.CodeValue)) AS [_sourceKey],
				COALESCE(d.CodeValue,'In Attendance') as AttendanceEventCategoryDescriptor_CodeValue,
				COALESCE(d.CodeValue,'In Attendance') as AttendanceEventCategoryDescriptor_Description,
				case when COALESCE(d.CodeValue,'In Attendance') in ('In Attendance','Tardy','Early departure','Partial','Remote Present','In-Person Present') then 1 else 0 end as [InAttendance_Indicator], -- todo: waiting for BPS team to finalize all codes
				case when COALESCE(d.CodeValue,'In Attendance') in ('Unexcused Absence','Remote Absent','In-Person Absent') then 1 else 0 end as [UnexcusedAbsence_Indicator],
				case when COALESCE(d.CodeValue,'In Attendance') in ('Excused Absence') then 1 else 0 end as [ExcusedAbsence_Indicator],
				case when COALESCE(d.CodeValue,'In Attendance') in ('Tardy','In-Person Tardy','Remote Tardy') then 1 else 0 end as [Tardy_Indicator],	   
				case when COALESCE(d.CodeValue,'In Attendance') in ('Partial') then 1 else 0 end as [EarlyDeparture_Indicator],	  
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(d.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS [CategoryModifiedDate],
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (d.LastModifiedDate)                             
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
				END AS ValidFrom,
				'12/31/9999' AS ValidTo,
				1  AS IsCurrent				
		--select *  
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d
		WHERE d.Namespace IN ('uri://ed-fi.org/AttendanceEventCategoryDescriptor',
		                      'uri://mybps.org/AttendanceEventCategoryDescriptor')	
			  AND (d.LastModifiedDate > @LastLoadDate AND d.LastModifiedDate <= @NewLoadDate);
		


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
		
		-- Test XACT_STATE:
		-- If  1, the transaction is committable.
		-- If -1, the transaction is uncommittable and should be rolled back.
		-- XACT_STATE = 0 means that there is no transaction and a commit or rollback operation would generate an error.

		-- Test whether the transaction is uncommittable.
		
	END CATCH;
END;
GO
