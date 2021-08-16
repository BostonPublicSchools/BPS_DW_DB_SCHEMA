SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Dim School
--------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_DimSchool_PopulateStaging]
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
	
		TRUNCATE TABLE Staging.[School]
		INSERT INTO Staging.[School]
				   ([_sourceKey]
				   ,[DistrictSchoolCode]
				   ,[StateSchoolCode]
				   ,[UmbrellaSchoolCode]
				   ,[ShortNameOfInstitution]
				   ,[NameOfInstitution]
				   ,[SchoolCategoryType]
				   ,[SchoolCategoryType_Elementary_Indicator]
				   ,[SchoolCategoryType_Middle_Indicator]
				   ,[SchoolCategoryType_HighSchool_Indicator]
				   ,[SchoolCategoryType_Combined_Indicator]       
				   ,[SchoolCategoryType_Other_Indicator]
				   ,[TitleIPartASchoolDesignationTypeCodeValue]
				   ,[TitleIPartASchoolDesignation_Indicator]
				   ,OperationalStatusTypeDescriptor_CodeValue
				   ,OperationalStatusTypeDescriptor_Description		   

				   ,SchoolNameModifiedDate
 				   ,SchoolOperationalStatusTypeModifiedDate
				   ,SchoolCategoryModifiedDate 
				   ,SchoolTitle1StatusModifiedDate

				   ,[ValidFrom]
				   ,[ValidTo]
				   ,[IsCurrent])
        --declare @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate()
		SELECT  DISTINCT 
			    CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),s.SchoolId)) AS [_sourceKey],
				eoic_sch.IdentificationCode AS DistrictSchoolCode,
				(SELECT TOP 1 eoic.IdentificationCode
				 FROM  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.EducationOrganizationIdentificationCode eoic 
				        INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d_sea ON eoic.EducationOrganizationIdentificationSystemDescriptorId = d_sea.DescriptorId
			                                                                                       AND d_sea.CodeValue = 'SEA' -- state code
				 WHERE  edorg.EducationOrganizationId = eoic.EducationOrganizationId
				        )	AS StateSchoolCode,
				CASE
					WHEN eoic_sch.IdentificationCode IN ('1291', '1292', '1293', '1294') THEN '1290'
					when eoic_sch.IdentificationCode IN ('1440','1441') THEN '1440' 
					WHEN eoic_sch.IdentificationCode IN ('4192','4192') THEN '4192' 
					WHEN eoic_sch.IdentificationCode IN ('4031','4033') THEN '4033' 
					WHEN eoic_sch.IdentificationCode IN ('1990','1991') THEN '1990' 
					WHEN eoic_sch.IdentificationCode IN ('1140','4391') THEN '1140' 
					ELSE eoic_sch.IdentificationCode
				END AS UmbrellaSchoolCode,
				edorg.ShortNameOfInstitution, 
				edorg.NameOfInstitution,
				sc_d.CodeValue AS SchoolCategoryType, 
				CASE  WHEN sc_d.CodeValue  IN ('Elementary School') THEN 1 ELSE 0 END  [SchoolCategoryType_Elementary_Indicator],
				CASE  WHEN sc_d.CodeValue  IN ('Middle School') THEN 1 ELSE 0 END  [SchoolCategoryType_Middle_Indicator],
				CASE  WHEN sc_d.CodeValue  IN ('High School') THEN 1 ELSE 0 END  [SchoolCategoryType_HighSchool_Indicator],
				CASE  WHEN sc_d.CodeValue  NOT IN ('Elementary School','Middle School','High School') THEN 1 ELSE 0 END  [SchoolCategoryType_Combined_Indicator],
				0  AS [SchoolCategoryType_Other_Indicator],
				COALESCE(t1_d.CodeValue,'N/A') AS TitleIPartASchoolDesignationTypeCodeValue,
				CASE WHEN t1_d.CodeValue NOT IN ('Not designated as a Title I Part A school','N/A') THEN 1 ELSE 0 END AS TitleIPartASchoolDesignation_Indicator,
				COALESCE(os_d.CodeValue,'N/A') AS OperationalStatusTypeDescriptor_CodeValue,	
				COALESCE(os_d.[Description],'N/A') AS OperationalStatusTypeDescriptor_Description,
				 
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(edorg.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolNameModifiedDate,
 				CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(os_d.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolOperationalStatusTypeModifiedDate,
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(sc_d.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolCategoryModifiedDate,
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN COALESCE(t1_d.LastModifiedDate,'07/01/2015') ELSE '07/01/2015' END AS SchoolTitle1StatusModifiedDate,

				--Making sure the first time, the ValidFrom is set to beginning of time 
				CASE WHEN @LastLoadDate <> '07/01/2015' THEN
				           (SELECT MAX(t) FROM
                             (VALUES
                               (edorg.LastModifiedDate)
                             , (os_d.LastModifiedDate)
                             , (sc_d.LastModifiedDate)
                             , (t1_d.LastModifiedDate)                             
                             ) AS [MaxLastModifiedDate](t)
                           )
					ELSE 
					      '07/01/2015' -- setting the validFrom to beggining of time during thre first load. 
				END AS ValidFrom,
				'12/31/9999' AS ValidTo,
				CASE WHEN COALESCE(os_d.CodeValue,'N/A') IN ('Active','Added','Changed Agency','Continuing','New','Reopened') THEN 1  ELSE 0  END AS IsCurrent		
		--SELECT distinct *
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.School s
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.EducationOrganization edorg on s.SchoolId = edorg.EducationOrganizationId
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor os_d ON edorg.OperationalStatusDescriptorId = os_d.DescriptorId
		     INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.EducationOrganizationIdentificationCode eoic_sch ON edorg.EducationOrganizationId = eoic_sch.EducationOrganizationId 																					   
			 INNER JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor d_lea ON eoic_sch.EducationOrganizationIdentificationSystemDescriptorId = d_lea.DescriptorId
			                                                                   AND d_lea.CodeValue = 'LEA' -- local/district code
			 LEFT JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.SchoolCategory sc on s.SchoolId = sc.SchoolId
		     LEFT JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor sc_d on sc.SchoolCategoryDescriptorId = sc_d.DescriptorId
		     LEFT JOIN  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Descriptor t1_d on s.TitleIPartASchoolDesignationDescriptorId = t1_d.DescriptorId
		     
		WHERE  
			(edorg.LastModifiedDate > @LastLoadDate AND edorg.LastModifiedDate <= @NewLoadDate) OR
			(os_d.LastModifiedDate > @LastLoadDate AND os_d.LastModifiedDate <= @NewLoadDate) OR
			(sc_d.LastModifiedDate > @LastLoadDate AND sc_d.LastModifiedDate <= @NewLoadDate) OR
			(t1_d.LastModifiedDate > @LastLoadDate AND t1_d.LastModifiedDate <= @NewLoadDate) 	
			
		
		--loading legacy data if it has not been loaded.
		--load types are ignored as this data will only be loaded once.
		IF NOT EXISTS(SELECT 1 
		              FROM dbo.DimSchool 
					  WHERE CHARINDEX('LegacyDW',_sourceKey,1) > 0)
			BEGIN
			   INSERT INTO Staging.[School]
				   ([_sourceKey]
				   ,[DistrictSchoolCode]
				   ,[StateSchoolCode]
				   ,[UmbrellaSchoolCode]
				   ,[ShortNameOfInstitution]
				   ,[NameOfInstitution]
				   ,[SchoolCategoryType]
				   ,[SchoolCategoryType_Elementary_Indicator]
				   ,[SchoolCategoryType_Middle_Indicator]
				   ,[SchoolCategoryType_HighSchool_Indicator]
				   ,[SchoolCategoryType_Combined_Indicator]       
				   ,[SchoolCategoryType_Other_Indicator]
				   ,[TitleIPartASchoolDesignationTypeCodeValue]
				   ,[TitleIPartASchoolDesignation_Indicator]
				   ,OperationalStatusTypeDescriptor_CodeValue
				   ,OperationalStatusTypeDescriptor_Description		   

				   ,SchoolNameModifiedDate
 				   ,SchoolOperationalStatusTypeModifiedDate
				   ,SchoolCategoryModifiedDate 
				   ,SchoolTitle1StatusModifiedDate

				   ,[ValidFrom]
				   ,[ValidTo]
				   ,[IsCurrent])
			 SELECT DISTINCT 
				    CONCAT_WS('|','LegacyDW',Convert(NVARCHAR(MAX),LTRIM(RTRIM(sd.sch)))) AS [_sourceKey],
					LTRIM(RTRIM(sd.sch)) AS [DistrictSchoolCode],
					CASE WHEN ISNULL(LTRIM(RTRIM(statecd)),'N/A') IN ('','N/A') THEN 'N/A' ELSE ISNULL(LTRIM(RTRIM(statecd)),'N/A') END AS StateSchoolCode,
					CASE
						WHEN LTRIM(RTRIM(sd.sch)) IN ('1291', '1292', '1293', '1294') THEN '1290'
						when LTRIM(RTRIM(sd.sch)) IN ('1440','1441') THEN '1440' 
						WHEN LTRIM(RTRIM(sd.sch)) IN ('4192','4192') THEN '4192' 
						WHEN LTRIM(RTRIM(sd.sch)) IN ('4031','4033') THEN '4033' 
						WHEN LTRIM(RTRIM(sd.sch)) IN ('1990','1991') THEN '1990' 
						WHEN LTRIM(RTRIM(sd.sch)) IN ('1140','4391') THEN '1140' 
						ELSE LTRIM(RTRIM(sd.sch))
					END AS UmbrellaSchoolCode,
					LTRIM(RTRIM(sd.[schname_f]))  AS ShortNameOfInstitution, 
					LTRIM(RTRIM(sd.[schname_f])) AS NameOfInstitution,
					'Combined' AS SchoolCategoryType, 
					0  [SchoolCategoryType_Elementary_Indicator],
					0  [SchoolCategoryType_Middle_Indicator],
					0  [SchoolCategoryType_HighSchool_Indicator],
					1  [SchoolCategoryType_Combined_Indicator],
					0  [SchoolCategoryType_Other_Indicator],
					'N/A' AS TitleIPartASchoolDesignationTypeCodeValue,
					0 AS TitleIPartASchoolDesignation_Indicator,
					'Inactive' AS OperationalStatusTypeDescriptor_CodeValue,	
					'Inactive' AS OperationalStatusTypeDescriptor_Description,

					'07/01/2015' AS SchoolNameModifiedDate,
 				    '07/01/2015' AS SchoolOperationalStatusTypeModifiedDate,
				    '07/01/2015' AS SchoolCategoryModifiedDate,
				    '07/01/2015' AS SchoolTitle1StatusModifiedDate,

					'07/01/2015' AS ValidFrom,
					GETDATE() AS ValidTo,
					0 AS IsCurrent
				--SELECT *
				FROM [Raw_LegacyDW].[SchoolData] sd
				WHERE NOT EXISTS(SELECT 1 
									FROM Staging.[School] ds 
									WHERE 'Ed-Fi|' + Convert(NVARCHAR(MAX),LTRIM(RTRIM(sd.sch))) = ds._sourceKey);
			END

		
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
