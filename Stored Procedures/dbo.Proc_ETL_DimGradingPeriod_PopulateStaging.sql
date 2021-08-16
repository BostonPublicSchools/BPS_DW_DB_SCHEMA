SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Dim GradingPeriod
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimGradingPeriod_PopulateStaging]
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

		--declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		TRUNCATE TABLE Staging.GradingPeriod
		INSERT INTO Staging.GradingPeriod
		(
		    _sourceKey,
			GradingPeriodDescriptor_CodeValue,
		    SchoolKey,
		    BeginDate,
		    EndDate,
		    TotalInstructionalDays,
		    PeriodSequence,
		    ModifiedDate,
			_sourceSchoolKey,
		    ValidFrom,
		    ValidTo,
		    IsCurrent
		)		
		--declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT
		    CONCAT_WS('|','Ed-Fi',gpd.CodeValue,CAST(gp.SchoolId AS NVARCHAR),CONVERT(NVARCHAR, gp.BeginDate, 112)) AS [_sourceKey],
			COALESCE(gpd.CodeValue,'N/A') AS GradingPeriodDescriptor_CodeValue,
			NULL AS SchoolKey,
			gp.BeginDate,
			gp.EndDate,
			gp.TotalInstructionalDays,
			gp.PeriodSequence,
			CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(gp.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS LastModifiedDate,

			CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),gp.SchoolId))  AS _sourceSchoolKey,
			--Making sure the first time, the ValidFrom is set to beginning of time 
			CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				        (SELECT MAX(t) FROM
                            (VALUES
                            (gp.LastModifiedDate)                             
                            ) AS [MaxLastModifiedDate](t)
                        )
				ELSE 
					    '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
			END AS ValidFrom,
			'12/31/9999' AS ValidTo,
			1 AS IsCurrent		
		--SELECT *
		FROM
			[EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.GradingPeriod AS gp
				INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor AS gpd ON	gp.GradingPeriodDescriptorId = gpd.DescriptorId
				
		WHERE gp.BeginDate < GETDATE()		      		      
		      AND dbo.Func_ETL_GetSchoolYear(gp.BeginDate) >= 2019 
		      AND (
			  	    (gp.LastModifiedDate > @LastLoadDate AND gp.LastModifiedDate <= @NewLoadDate)
				  )
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

		
	END CATCH;
END;
GO
