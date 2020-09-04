SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Dim DisciplineIncident
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimDisciplineIncident_PopulateStaging]
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

		BEGIN TRANSACTION;   

		TRUNCATE TABLE Staging.DisciplineIncident
		INSERT INTO Staging.DisciplineIncident
				   (_sourceKey
				    ,[SchoolKey]
				    ,[ShortNameOfInstitution]
				    ,[NameOfInstitution]
				    ,[SchoolYear]
				    ,[IncidentDate]
				    ,[IncidentTime]
				    ,[IncidentDescription]
				    ,[BehaviorDescriptor_CodeValue]
				    ,[BehaviorDescriptor_Description]
				    ,[LocationDescriptor_CodeValue]
				    ,[LocationDescriptor_Description]
				    ,[DisciplineDescriptor_CodeValue]
				    ,[DisciplineDescriptor_Description]
				    ,DisciplineDescriptor_ISS_Indicator
				    ,DisciplineDescriptor_OSS_Indicator
				    ,[ReporterDescriptor_CodeValue]
				    ,[ReporterDescriptor_Description]
			 	    
				    ,[IncidentReporterName]
				    ,[ReportedToLawEnforcement_Indicator]
				    ,[IncidentCost]

					,IncidentModifiedDate

				    ,[ValidFrom]
				    ,[ValidTo]
				    ,[IsCurrent])
        --declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT DISTINCT 
				CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),di.IncidentIdentifier)) AS [_sourceKey],
				dschool.SchoolKey,
				dschool.ShortNameOfInstitution,
				dschool.NameOfInstitution,
				dbo.Func_ETL_GetSchoolYear(di.IncidentDate),
				di.IncidentDate,
				COALESCE(di.IncidentTime,'00:00:00.0000000') AS IncidentTime,
				di.IncidentDescription,
				COALESCE(d_dib.CodeValue,'N/A') as [BehaviorDescriptor_CodeValue],
				COALESCE(d_dib.Description,'N/A') as [BehaviorDescriptor_Description],
	  
				COALESCE(d_dil.CodeValue,'N/A') as [LocationDescriptor_CodeValue],
				COALESCE(d_dil.Description,'N/A') as [LocationDescriptor_Description],

				COALESCE(d_dia.CodeValue,'N/A') as [DisciplineDescriptor_CodeValue],
				COALESCE(d_dia.Description,'N/A') as [DisciplineDescriptor_Description],
				CASE WHEN  COALESCE(d_dia.CodeValue,'N/A') IN ('In School Suspension','In-School Suspension') THEN 1 ELSE 0 END as DisciplineDescriptor_ISS_Indicator,
				CASE WHEN  COALESCE(d_dia.CodeValue,'N/A') IN ('Out of School Suspension','Out-Of-School Suspension') THEN 1 ELSE 0 END as DisciplineDescriptor_OSS_Indicator,
	  
				COALESCE(d_dirt.CodeValue,'N/A') as ReporterDescriptor_CodeValue,
				COALESCE(d_dirt.Description,'N/A') as ReporterDescriptor_Description,

				COALESCE(di.ReporterName,'N/A'),
				COALESCE(di.ReportedToLawEnforcement,0) AS ReportedToLawEnforcement,
				COALESCE(di.IncidentCost,0) AS IncidentCost,
				
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(di.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS IncidentModifiedDate,

				--Making sure the first time, the ValidFrom is set to beginning of time 
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (di.LastModifiedDate)                             
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
				END AS ValidFrom,
				'12/31/9999' AS ValidTo,
				1 AS IsCurrent		
		FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.DisciplineIncident di       
				LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.DisciplineIncidentBehavior dib ON di.IncidentIdentifier = dib.IncidentIdentifier
				LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.DisciplineActionDisciplineIncident dadi ON di.IncidentIdentifier = dadi.IncidentIdentifier
				LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.DisciplineActionDiscipline dad ON dadi.DisciplineActionIdentifier = dad.DisciplineActionIdentifier

				INNER JOIN dbo.DimSchool dschool ON 'Ed-Fi|' + Convert(NVARCHAR(MAX),di.SchoolId)   = dschool._sourceKey
				INNER JOIN dbo.DimTime dt ON di.IncidentDate = dt.SchoolDate
												AND dt.SchoolKey is not null   
												AND dschool.SchoolKey = dt.SchoolKey
				LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor d_dib ON dib.BehaviorDescriptorId   = d_dib.DescriptorId
				LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.IncidentLocationType d_dil ON di.IncidentLocationTypeId   = d_dil.IncidentLocationTypeId
				LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor d_dia ON dad.DisciplineDescriptorId   = d_dia.DescriptorId
				LEFT JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.Descriptor d_dirt ON di.ReporterDescriptionDescriptorId   = d_dirt.DescriptorId
		WHERE dbo.Func_ETL_GetSchoolYear(di.IncidentDate) >= 2019 AND
		    (
			  	(di.LastModifiedDate > @LastLoadDate AND di.LastModifiedDate <= @NewLoadDate)
			)

			
							
			
		--loading legacy data if it has not been loaded.
		--load types are ignored as this data will only be loaded once.
		IF NOT EXISTS(SELECT 1 
		              FROM dbo.DimDisciplineIncident 
					  WHERE CHARINDEX('LegacyDW',_sourceKey,1) > 0)
			BEGIN
			   INSERT INTO Staging.DisciplineIncident
				   (_sourceKey
				    ,[SchoolKey]
				    ,[ShortNameOfInstitution]
				    ,[NameOfInstitution]
				    ,[SchoolYear]
				    ,[IncidentDate]
				    ,[IncidentTime]
				    ,[IncidentDescription]
				    ,[BehaviorDescriptor_CodeValue]
				    ,[BehaviorDescriptor_Description]
				    ,[LocationDescriptor_CodeValue]
				    ,[LocationDescriptor_Description]
				    ,[DisciplineDescriptor_CodeValue]
				    ,[DisciplineDescriptor_Description]
				    ,DisciplineDescriptor_ISS_Indicator
				    ,DisciplineDescriptor_OSS_Indicator
				    ,[ReporterDescriptor_CodeValue]
				    ,[ReporterDescriptor_Description]
			 	    
				    ,[IncidentReporterName]
				    ,[ReportedToLawEnforcement_Indicator]
				    ,[IncidentCost]

					,IncidentModifiedDate

				    ,[ValidFrom]
				    ,[ValidTo]
				    ,[IsCurrent])
			 SELECT DISTINCT 
					  CONCAT_WS('|','LegacyDW',Convert(NVARCHAR(MAX),di.[CND_INCIDENT_ID])) AS [_sourceKey],    
					  dschool.SchoolKey,
					  dschool.ShortNameOfInstitution,
					  dschool.NameOfInstitution,
					  dbo.Func_ETL_GetSchoolYear(di.[CND_INCIDENT_DATE]) AS [SchoolYear],
					  di.CND_INCIDENT_DATE AS [IncidentDate],
					 -- TRY_CAST(di.CND_INCIDENT_TIME AS DATETIME2) ,
					  CONVERT(char(12),TRY_CAST(di.CND_INCIDENT_TIME AS DATETIME2), 108) IncidentTime,
					  --'00:00:00.0000000' AS ,
					  di.[CND_INCIDENT_DESCRIPTION] AS [IncidentDescription],
					  COALESCE(di.CND_INCIDENT_CODE,'N/A') as [BehaviorDescriptor_CodeValue],
					  COALESCE(di.CND_INCIDENT_CODE,'N/A') as [BehaviorDescriptor_Description],
	  
					  COALESCE(di.[CND_INCIDENT_LOCATION],'N/A') as [LocationDescriptor_CodeValue],
					  COALESCE(di.[CND_INCIDENT_LOCATION],'N/A') as [LocationDescriptor_Description],

					  COALESCE(di.[ACT_ACTION_CODE],'N/A') as [DisciplineDescriptor_CodeValue],
					  COALESCE(di.[ACT_ACTION_CODE],'N/A') as [DisciplineDescriptor_Description],
					  CASE WHEN  COALESCE(di.ACT_ACTION_CODE,'N/A') IN ('In-School Suspension)') THEN 1 ELSE 0 END,
					  CASE WHEN  COALESCE(di.ACT_ACTION_CODE,'N/A') IN ('Out of School Suspension') THEN 1 ELSE 0 END,
	  
					  'N/A' as ReporterDescriptor_CodeValue,
					  'N/A' as ReporterDescriptor_Description,

					  'N/A' AS [IncidentReporterName],
					  0 AS ReportedToLawEnforcement,
					  0 AS IncidentCost,

					  '07/01/2015' AS IncidentModifiedDate,
					  
					  '07/01/2015' AS ValidFrom,
					  GETDATE() AS ValidTo,
					  0 AS IsCurrent		
					  
				--select distinct *
				FROM  [EdFiDW].[Raw_LegacyDW].[DisciplineIncidents] di
					  INNER JOIN dbo.DimSchool dschool ON CONCAT_WS('|', 'Ed-Fi', Convert(NVARCHAR(MAX),di.[SKL_SCHOOL_ID]))   = dschool._sourceKey 
					  INNER JOIN dbo.DimTime dt ON di.CND_INCIDENT_DATE = dt.SchoolDate
														 AND dt.SchoolKey is not null   
														 AND dschool.SchoolKey = dt.SchoolKey	
				WHERE TRY_CAST(di.CND_INCIDENT_DATE AS DATETIME)  > '2015-09-01'
			END

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

		
		PRINT CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);
		
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
