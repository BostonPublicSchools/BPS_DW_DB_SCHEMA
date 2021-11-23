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

    declare @sklId        int
          , @recordDate   date
          , @countTotal   int
          , @countPresent int
          , @countAbsent  int
          , @countTardy   int
          , @batch        varchar(25);

    declare db_cursor cursor for
    select SAT_SKL_ID
         , SAT_RECORD_DATE
         , SAT_COUNT_TOTAL
         , SAT_COUNT_PRESENT
         , SAT_COUNT_ABSENT
         , SAT_COUNT_TARDY
         , SAT_BATCH
    from BPSDashboard.staging.SAT_School_Attendance
    except
    select SAT_SKL_ID
         , SAT_RECORD_DATE
         , SAT_COUNT_TOTAL
         , SAT_COUNT_PRESENT
         , SAT_COUNT_ABSENT
         , SAT_COUNT_TARDY
         , SAT_BATCH
    from BPSDashboard.dbo.SAT_School_Attendance;

    open db_cursor;
    fetch next from db_cursor
    into @sklId
       , @recordDate
       , @countTotal
       , @countPresent
	   , @countAbsent
       , @countTardy
       , @batch;
    while @@fetch_status = 0
    begin
        update BPSDashboard.dbo.SAT_School_Attendance
        set SAT_BATCH = @batch
          , SAT_CREATE_DATE = getdate()
          , SAT_COUNT_TOTAL = @countTotal
          , SAT_COUNT_PRESENT = @countPresent
          , SAT_COUNT_ABSENT = @countAbsent
          , SAT_COUNT_TARDY = @countTardy
        where SAT_SKL_ID = @sklId
              and SAT_RECORD_DATE = @recordDate;

        fetch next from db_cursor
        into @sklId
           , @recordDate
           , @countTotal
           , @countPresent
		   , @countAbsent
           , @countTardy
           , @batch;
    end;

    close db_cursor;
    deallocate db_cursor;
end;
GO
