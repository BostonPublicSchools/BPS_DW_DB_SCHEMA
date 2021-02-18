SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--Fact StudentDiscipline
----------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[Proc_ETL_FactStudentDiscipline_PopulateStaging] 
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
    
		--DECLARE @LastLoadDate datetime = '07/01/2015' declare @NewLoadDate datetime = getdate();
		TRUNCATE TABLE Staging.StudentDiscipline
			
		INSERT INTO Staging.StudentDiscipline
		(
		    _sourceKey,
		    StudentKey,
		    TimeKey,
		    SchoolKey,
		    DisciplineIncidentKey,
		    ModifiedDate,
		    _sourceStudentKey,
		    _sourceTimeKey,
		    _sourceSchoolKey,
		    _sourceDisciplineIncidentKey
		)
		
		SELECT DISTINCT 
		       CONCAT_WS('|',Convert(NVARCHAR(MAX),sdia.StudentUSI),di.IncidentIdentifier) AS _sourceKey,
			   NULL AS StudentKey,
			   NULL AS TimeKey,	  
			   NULL AS SchoolKey,  
			   NULL AS DisciplineIncidentKey,  
			   di.IncidentDate AS ModifiedDate,
			   CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),sdia.StudentUSI)) AS _sourceStudentKey,
		       di.IncidentDate AS _sourceTimeKey,		          
			   CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),di.SchoolId))  AS _sourceSchoolKey,
		       CONCAT_WS('|','Ed-Fi', Convert(NVARCHAR(MAX),di.IncidentIdentifier))  AS  _sourceDisciplineIncidentKey

		FROM  [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.DisciplineIncident di       
			  INNER JOIN [EDFISQL01].[EdFi_BPS_Production_Ods].edfi.StudentDisciplineIncidentAssociation sdia ON di.IncidentIdentifier = sdia.IncidentIdentifier
		WHERE di.IncidentDate >= '07/01/2018'	  
		 AND  (
		       (di.LastModifiedDate > @LastLoadDate  AND di.LastModifiedDate <= @NewLoadDate)
			     OR
		       (sdia.LastModifiedDate > @LastLoadDate  AND sdia.LastModifiedDate <= @NewLoadDate)
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
		
		
	END CATCH;
END;
GO
