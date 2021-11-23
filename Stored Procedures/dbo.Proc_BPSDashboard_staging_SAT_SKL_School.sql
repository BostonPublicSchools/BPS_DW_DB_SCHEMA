SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[Proc_BPSDashboard_staging_SAT_SKL_School]
as
begin
    truncate table BPSDashboard.staging.SKL_School;

    insert into BPSDashboard.staging.SKL_School
    (
        SKL_SIS_ID
      , SKL_REF_ID
      , SKL_LOCAL_ID
      , SKL_STATE_ID
      , SKL_NAME

    )
    select SchoolKey
         , 'EdFiDW - ' + cast(SchoolKey as varchar(10))
         , DistrictSchoolCode
         , StateSchoolCode
         , substring(ShortNameOfInstitution, 0, 50)
    from dbo.DimSchool
    where OperationalStatusTypeDescriptor_CodeValue in ( 'Active' )
          and IsCurrent = 1
          and not StateSchoolCode = 'N/A'
          and BPSSchool_Indicator = 1;

    update BPSGranary02.BPSDashboard.dbo.SKL_School
    set SKL_ZIP_CODE = schoollocation.zip
      , SKL_NEIGHBORHOOD = COBCity
    from [BPSDATA-03].BPSInterface.dbo.schoollocation
        join [BPSDATA-03].BPSInterface.dbo.AddressFile
            on AddressFile.AddressID = schoollocation.addressID
    where SKL_LOCAL_ID = sch;
end;
GO
