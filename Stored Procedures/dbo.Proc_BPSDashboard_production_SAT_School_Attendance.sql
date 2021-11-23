SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[Proc_BPSDashboard_production_SAT_School_Attendance]
as
begin
    --added to prevent extra result sets from interfering with SELECT statements.
    set nocount on;

    --current session wont be the deadlock victim if it is involved in a deadlock with other sessions with the deadlock priority set to LOW
    set deadlock_priority high;

    --When SET XACT_ABORT is ON, if a Transact-SQL statement raises a run-time error, the entire transaction is terminated and rolled back.
    set xact_abort on;

    --This will allow for dirty reads. By default SQL Server uses "READ COMMITED" 
    set transaction isolation level read uncommitted;

    set identity_insert BPSDashboard.dbo.SAT_School_Attendance on;

    insert BPSDashboard.dbo.SAT_School_Attendance
    (
        SAT_SKL_ID
      , SAT_BATCH
      , SAT_RECORD_DATE
      , SAT_CREATE_DATE
      , SAT_COUNT_TOTAL
      , SAT_COUNT_PRESENT
      , SAT_COUNT_ABSENT
      , SAT_COUNT_TARDY
      , SATID
    )
    select SAT_SKL_ID
         , SAT_BATCH
         , SAT_RECORD_DATE
         , SAT_CREATE_DATE
         , SAT_COUNT_TOTAL
         , SAT_COUNT_PRESENT
         , SAT_COUNT_ABSENT
         , SAT_COUNT_TARDY
         , SATID
    from BPSDashboard.staging.SAT_School_Attendance
    where not (
                  SAT_SKL_ID = BPSDashboard.staging.SAT_School_Attendance.SAT_SKL_ID
                  and SAT_RECORD_DATE = BPSDashboard.staging.SAT_School_Attendance.SAT_RECORD_DATE
              );


    set identity_insert BPSDashboard.dbo.SAT_School_Attendance off;

    update BPSDashboard.dbo.SAT_School_Attendance
    set SAT_SKL_ID = sa.SAT_SKL_ID
      , SAT_BATCH = sa.SAT_BATCH
      , SAT_RECORD_DATE = sa.SAT_RECORD_DATE
      , SAT_CREATE_DATE = getdate()
      , SAT_COUNT_TOTAL = sa.SAT_COUNT_TOTAL
      , SAT_COUNT_PRESENT = sa.SAT_COUNT_PRESENT
      , SAT_COUNT_ABSENT = sa.SAT_COUNT_ABSENT
      , SAT_COUNT_TARDY = sa.SAT_COUNT_TARDY
    from
    (
        select SAT_SKL_ID
             , SAT_BATCH
             , SAT_RECORD_DATE
             , SAT_COUNT_TOTAL
             , SAT_COUNT_PRESENT
             , SAT_COUNT_ABSENT
             , SAT_COUNT_TARDY
        from BPSDashboard.staging.SAT_School_Attendance
        except
        select SAT_SKL_ID
             , SAT_BATCH
             , SAT_RECORD_DATE
             , SAT_COUNT_TOTAL
             , SAT_COUNT_PRESENT
             , SAT_COUNT_ABSENT
             , SAT_COUNT_TARDY
        from BPSDashboard.dbo.SAT_School_Attendance
    ) sa
    where BPSDashboard.dbo.SAT_School_Attendance.SAT_SKL_ID = sa.SAT_SKL_ID
          and BPSDashboard.dbo.SAT_School_Attendance.SAT_RECORD_DATE = sa.SAT_RECORD_DATE;
end;
GO
