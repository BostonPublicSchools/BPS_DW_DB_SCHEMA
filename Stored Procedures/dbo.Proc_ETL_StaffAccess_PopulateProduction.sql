SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- Staff Access
CREATE   PROCEDURE [dbo].[Proc_ETL_StaffAccess_PopulateProduction]
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
	    
		
		DECLARE @currenSchoolYear INT
		SELECT TOP(1) @currenSchoolYear = syt.SchoolYear
		FROM  [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.SchoolYearType syt
		WHERE syt.CurrentSchoolYear = 1 
		ORDER BY syt.SchoolYear DESC

		CREATE TABLE #currentYearStaff_DistrictAdmins(StaffSourceKey NVARCHAR(50))
		INSERT INTO #currentYearStaff_DistrictAdmins(StaffSourceKey)
		SELECT DISTINCT CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StaffUniqueId))
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSchoolAssociation ssa
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff s ON ssa.StaffUSI = s.StaffUSI
		WHERE ssa.SchoolYear = @currenSchoolYear
		  AND ssa.SchoolId = 9035 -- central office BPS;

		CREATE TABLE #currentYearStaff_Teachers(StaffSourceKey NVARCHAR(50))
		INSERT INTO #currentYearStaff_Teachers(StaffSourceKey)
		SELECT DISTINCT CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StaffUniqueId))
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSchoolAssociation ssa		
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff s ON ssa.StaffUSI = s.StaffUSI
		WHERE ssa.SchoolYear = @currenSchoolYear
		  AND EXISTS (SELECT 1
		                  FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSectionAssociation s_sect_a
						  WHERE ssa.StaffUSI = s_sect_a.StaffUSI
						    AND ssa.SchoolYear = s_sect_a.SchoolYear)
          AND NOT EXISTS (SELECT 1
						  FROM  #currentYearStaff_DistrictAdmins da
						  WHERE  CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),ssa.StaffUSI)) = da.StaffSourceKey);

		CREATE TABLE #currentYearStaff_SchoolAdmins(StaffSourceKey NVARCHAR(50), SchoolSourceKey NVARCHAR(50))
		INSERT INTO #currentYearStaff_SchoolAdmins(StaffSourceKey, SchoolSourceKey)
		SELECT DISTINCT CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StaffUniqueId)) ,
		                 CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),ssa.SchoolId)) 
		FROM [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSchoolAssociation ssa		
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff s ON ssa.StaffUSI = s.StaffUSI
		WHERE ssa.SchoolYear = @currenSchoolYear
		  AND ssa.SchoolId <> 9035 -- central office BPS;
		  AND NOT EXISTS (SELECT 1
						  FROM  #currentYearStaff_DistrictAdmins da
						  WHERE  CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StaffUniqueId)) = da.StaffSourceKey)
		  AND NOT EXISTS (SELECT 1
						  FROM  #currentYearStaff_Teachers t
						  WHERE  CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StaffUniqueId)) = t.StaffSourceKey);


		



		--Staff Current Schools
		-------------------------------------------------------------------------------------
		--dropping the columnstore index
		DROP INDEX IF EXISTS CSI_Derived_StaffCurrentSchool ON [Derived].[StaffCurrentSchools];
		
		TRUNCATE TABLE [Derived].[StaffCurrentSchools];
		
		--district admins - they can see all schools except "Central Office BPS"
		INSERT INTO [Derived].[StaffCurrentSchools]
		(
		    [StaffKey],
		    [SchoolKey]
		)		
		SELECT DISTINCT 
		       ds.StaffKey,
		       dschool.SchoolKey
		FROM dbo.DimStaff ds
		     CROSS JOIN dbo.DimSchool dschool
		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1		  
		  AND dschool.DistrictSchoolCode <>  '9035' -- central office BPS
		  AND dschool.IsCurrent = 1
		  AND EXISTS (SELECT 1 
		              FROM #currentYearStaff_DistrictAdmins t
					  WHERE ds._sourceKey = t.StaffSourceKey)


		--non-district admins - they can see only their respective schools
		INSERT INTO [Derived].[StaffCurrentSchools]
		(
		    [StaffKey],
		    [SchoolKey]
		)
		SELECT DISTINCT 
		       ds.StaffKey,
		       dschool.SchoolKey
		FROM dbo.DimStaff ds
		     INNER join #currentYearStaff_SchoolAdmins sa ON ds._sourceKey	= sa.StaffSourceKey
			 INNER JOIN dbo.DimSchool dschool ON sa.SchoolSourceKey  = dschool._sourceKey	 
		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1		  
		  AND dschool.IsCurrent = 1
        
	    --re-creating the columnstore index
		CREATE COLUMNSTORE INDEX CSI_Derived_StaffCurrentSchool  ON [Derived].[StaffCurrentSchools] ( [StaffKey],[SchoolKey])		
		
        

		--Staff Current GradeLevels
		----------------------------------------------------------------------------------------
		--dropping the columnstore index
		DROP INDEX IF EXISTS CSI_Derived_StaffCurrentGradeLevels ON [Derived].StaffCurrentGradeLevels;

		TRUNCATE TABLE Derived.StaffCurrentGradeLevels

		--district admins - they can see all schools except "Central Office BPS"
		;WITH allGradeLevels AS
        (
		  SELECT DISTINCT case GradeLevelDescriptor_CodeValue
		  			when 'Eighth grade' then 	'08'
		  			when 'Eleventh grade' then 	'11'
		  			when 'Fifth grade' then 	'05'
		  			when 'First grade' then 	'01'
		  			when 'Fourth grade' then 	'04'
		  			when 'Kindergarten'  then 'K'
		  			when 'Ninth grade' then 	'09'
		  			when 'Preschool/Prekindergarten' then 'PK'
		  			when 'Second grade' then 	'02'
		  			when 'Seventh grade' then 	'07'
		  			when 'Sixth grade' then 	'06'
		  			when 'Tenth grade' then 	'10'
		  			when 'Third grade' then 	'03'
		  			when 'Twelfth grade' then 	'12'
					when '' then 	'Unknown'
		  			ELSE GradeLevelDescriptor_CodeValue 
				  end  AS GradeLevel
		  FROM dbo.DimStudent 
		  WHERE IsCurrent = 1 
		) 
		INSERT INTO Derived.StaffCurrentGradeLevels
	    (
	        StaffKey,
	        GradeLevel
	    )
        
		SELECT DISTINCT 
		       ds.StaffKey,
		       scgl.GradeLevel
		FROM dbo.DimStaff ds		     
			 CROSS JOIN allGradeLevels scgl 
		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1
		  AND EXISTS (SELECT 1 
		              FROM #currentYearStaff_DistrictAdmins t
					  WHERE ds._sourceKey = t.StaffSourceKey)
		  

		--school admins  they can only see the grade levels of their respective schools
	    INSERT INTO Derived.StaffCurrentGradeLevels
	    (
	        StaffKey,
	        GradeLevel
	    )
		SELECT DISTINCT 
		       ds.StaffKey,
			   case dst.GradeLevelDescriptor_CodeValue
		  			when 'Eighth grade' then 	'08'
		  			when 'Eleventh grade' then 	'11'
		  			when 'Fifth grade' then 	'05'
		  			when 'First grade' then 	'01'
		  			when 'Fourth grade' then 	'04'
		  			when 'Kindergarten'  then 'K'
		  			when 'Ninth grade' then 	'09'
		  			when 'Preschool/Prekindergarten' then 'PK'
		  			when 'Second grade' then 	'02'
		  			when 'Seventh grade' then 	'07'
		  			when 'Sixth grade' then 	'06'
		  			when 'Tenth grade' then 	'10'
		  			when 'Third grade' then 	'03'
		  			when 'Twelfth grade' then 	'12'
					when '' then 	'Unknown'
		  			ELSE dst.GradeLevelDescriptor_CodeValue 
				  end  AS GradeLevel
		      
		FROM dbo.DimStaff ds
		     INNER join #currentYearStaff_SchoolAdmins sa ON ds._sourceKey	= sa.StaffSourceKey
			 INNER JOIN dbo.DimSchool dschool ON  sa.SchoolSourceKey  = dschool._sourceKey	
			 INNER JOIN dbo.DimStudent dst ON dschool.SchoolKey	 = dst.SchoolKey
		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1		  
		  AND dst.IsCurrent = 1
		  AND dschool.IsCurrent = 1;
		

	   --teachers
		INSERT INTO Derived.StaffCurrentGradeLevels
	    (
	        StaffKey,
	        GradeLevel
	    )
		SELECT DISTINCT 
		       ds.StaffKey,
			    case dst.GradeLevelDescriptor_CodeValue
		  			when 'Eighth grade' then 	'08'
		  			when 'Eleventh grade' then 	'11'
		  			when 'Fifth grade' then 	'05'
		  			when 'First grade' then 	'01'
		  			when 'Fourth grade' then 	'04'
		  			when 'Kindergarten'  then 'K'
		  			when 'Ninth grade' then 	'09'
		  			when 'Preschool/Prekindergarten' then 'PK'
		  			when 'Second grade' then 	'02'
		  			when 'Seventh grade' then 	'07'
		  			when 'Sixth grade' then 	'06'
		  			when 'Tenth grade' then 	'10'
		  			when 'Third grade' then 	'03'
		  			when 'Twelfth grade' then 	'12'
					when '' then 	'Unknown'
		  			ELSE dst.GradeLevelDescriptor_CodeValue 
				  end  AS GradeLevel	      
		FROM dbo.DimStaff ds
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff s ON ds._sourceKey	= CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StaffUniqueId))  
		     INNER join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSectionAssociation  sa_staff ON s.StaffUSI = sa_staff.StaffUSI
			 INNER join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSectionAssociation sa_stud ON sa_staff.SectionIdentifier = sa_stud.SectionIdentifier	
			                                                                                       AND  sa_staff.SchoolId = sa_stud.SchoolId
																								   AND  sa_staff.SchoolYear = sa_stud.SchoolYear
			 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student st ON sa_stud.StudentUSI = st.StudentUSI
			 INNER JOIN dbo.DimStudent dst ON CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),st.StudentUSI)) = dst._sourceKey

		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1		  
		  AND dst.IsCurrent = 1		  		    
		  AND ds.IsLatest = 1
		  AND dst.IsLatest = 1

		  AND EXISTS (SELECT 1 
		              FROM #currentYearStaff_Teachers t
					  WHERE ds._sourceKey = t.StaffSourceKey)
		  AND sa_staff.SchoolYear = @currenSchoolYear
		 


        CREATE COLUMNSTORE INDEX CSI_Derived_StaffCurrentGradeLevels  ON [Derived].StaffCurrentGradeLevels ( [StaffKey],GradeLevel)		

		--Staff Current Students
		---------------------------------------------------------------------------------------
		--dropping the columnstore index
		DROP INDEX IF EXISTS CSI_Derived_StaffCurrentStudents ON [Derived].StaffCurrentStudents;

		/*
		TRUNCATE TABLE Derived.StaffCurrentStudents

		--district admins
		INSERT INTO Derived.StaffCurrentStudents
		(
		    StaffKey,
		    StudentKey
		)
		SELECT DISTINCT 
		       ds.StaffKey,
			   dst.StudentKey		      
		FROM dbo.DimStaff ds		     
			 CROSS JOIN dbo.DimStudent dst 
		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1
		  AND dst.IsCurrent = 1
		  AND EXISTS (SELECT 1 
		              FROM #currentYearStaff_DistrictAdmins t
					  WHERE ds._sourceKey = t.StaffSourceKey)
		


		--school admins
		INSERT INTO Derived.StaffCurrentStudents
		(
		    StaffKey,
		    StudentKey
		)
		SELECT DISTINCT 
		       ds.StaffKey,
			   dst.StudentKey		      
		FROM dbo.DimStaff ds
		     INNER join #currentYearStaff_SchoolAdmins sa ON ds._sourceKey	= sa.StaffSourceKey 
			 INNER JOIN dbo.DimSchool dschool ON  sa.SchoolSourceKey  = dschool._sourceKey	
			 INNER JOIN dbo.DimStudent dst ON dschool.SchoolKey	 = dst.SchoolKey
		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1
		  AND dst.IsCurrent = 1		*/  
		  

		--teachers
		INSERT INTO Derived.StaffCurrentStudents
		(
		    StaffKey,
		    StudentKey
		)
		SELECT DISTINCT 
		       ds.StaffKey,
			   dst.StudentKey		      
		FROM dbo.DimStaff ds
		     INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Staff s ON ds._sourceKey	= CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),s.StaffUniqueId))  
		     INNER join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StaffSectionAssociation  sa_staff ON s.StaffUSI = sa_staff.StaffUSI		     
			 INNER join [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.StudentSectionAssociation sa_stud ON sa_staff.SectionIdentifier = sa_stud.SectionIdentifier	
			                                                                                       AND  sa_staff.SchoolId = sa_stud.SchoolId
																								   AND  sa_staff.SchoolYear = sa_stud.SchoolYear
			 INNER JOIN [EDFISQL01].[v34_EdFi_BPS_Production_Ods].edfi.Student st ON sa_stud.StudentUSI = st.StudentUSI
			 INNER JOIN dbo.DimStudent dst ON CONCAT_WS('|','Ed-Fi',Convert(NVARCHAR(MAX),st.StudentUSI)) = dst._sourceKey

		WHERE 1=1 --ssa.StaffUSI = 9786
		  AND ds.IsCurrent = 1		  
		  AND dst.IsCurrent = 1		  
		  AND EXISTS (SELECT 1 
		              FROM #currentYearStaff_Teachers t
					  WHERE ds._sourceKey = t.StaffSourceKey)
		  AND sa_staff.SchoolYear = @currenSchoolYear
		
					 
        CREATE COLUMNSTORE INDEX CSI_Derived_StaffCurrentStudents  ON [Derived].StaffCurrentStudents ( [StaffKey],StudentKey)		
		
	    DROP TABLE IF EXISTS #currentYearStaff_DistrictAdmins;
		DROP TABLE IF EXISTS #currentYearStaff_SchoolAdmins;
		DROP TABLE IF EXISTS #currentYearStaff_Teachers;
	
	END TRY
	BEGIN CATCH
		
		--constructing exception details
		DECLARE
		   @errorMessage nvarchar( MAX ) = ERROR_MESSAGE( );		
     
		DECLARE
		   @errorDetails nvarchar( MAX ) = CONCAT('An error had ocurred executing SP:',OBJECT_NAME(@@PROCID),'. Error details: ', @errorMessage);

		PRINT @errorDetails;
		THROW 51000, @errorDetails, 1;

		
	END CATCH;
END;
GO
