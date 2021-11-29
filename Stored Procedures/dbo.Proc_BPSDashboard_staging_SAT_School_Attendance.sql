SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[Proc_BPSDashboard_staging_SAT_School_Attendance]
as
begin
    truncate table BPSDashboard.staging.SAT_School_Attendance;

    insert into BPSDashboard.staging.SAT_School_Attendance
    (
        SAT_SKL_ID
      , SAT_BATCH
      , SAT_RECORD_DATE
      , SAT_CREATE_DATE
      , SAT_COUNT_TOTAL
      , SAT_COUNT_PRESENT
      , SAT_COUNT_ABSENT
      , SAT_COUNT_TARDY
    )
    select
	 DimSchool.SchoolKey
      , null
      , SchoolDate
      , getdate()
      , count(distinct StudentUniqueId) SAT_COUNT_TOTAL
      , sum(   case
                   when InAttendance_Indicator = 1 then
                       1
                   when EarlyDeparture_Indicator = 1 then
                       1
                   else
                       0
               end
           )                            SAT_COUNT_PRESENT
      , sum(   case
                   when UnexcusedAbsence_Indicator = 1 then
                       1
                   when UnexcusedAbsence_Indicator = 1 then
                       1
                   when ExcusedAbsence_Indicator = 1 then
                       1
                   else
                       0
               end
           )                            SAT_COUNT_ABSENT
      , sum(   case
                   when Tardy_Indicator = 1 then
                       1
                   else
                       0
               end
           )                            SAT_COUNT_TARDY
    --, cast(sum(   case
    --                  when InAttendance_Indicator = 1 then
    --                      1
    --                  when EarlyDeparture_Indicator = 1 then
    --                      1
    --                  else
    --                      0
    --              end
    --          ) as decimal) * 100 / cast(count(distinct StudentUniqueId) as decimal) as Precentage
    from dbo.FactStudentAttendanceByDay
        inner join dbo.DimTime
            on DimTime.TimeKey = FactStudentAttendanceByDay.TimeKey
        inner join dbo.DimAttendanceEventCategory
            on DimAttendanceEventCategory.AttendanceEventCategoryKey = FactStudentAttendanceByDay.AttendanceEventCategoryKey
        inner join dbo.DimSchool
            on DimSchool.SchoolKey = DimTime.SchoolKey
        inner join dbo.DimStudent
            on DimStudent.StudentKey = FactStudentAttendanceByDay.StudentKey
    where SchoolYear = 2022
          and BPSSchool_Indicator = 1
    --      and SchoolDate = '2021-10-29'
    group by SchoolDate
           , DimSchool.SchoolKey
           , DistrictSchoolCode
           , DimSchool.ShortNameOfInstitution
    order by SchoolDate desc;
end;
GO
