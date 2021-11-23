SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[Proc_BPSDashboard_production_SAT_SKL_School]
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

    set identity_insert BPSDashboard.dbo.SKL_School on;

    insert BPSDashboard.dbo.SKL_School
    (
        SKL_SIS_ID
      , SKL_REF_ID
      , SKL_LOCAL_ID
      , SKL_STATE_ID
      , SKL_NAME
      , SKL_ZIP_CODE
      , SKL_NEIGHBORHOOD
      , SKL_TLT
      , SKL_LVL_TYPE
      , SKL_ID
    )
    select SKL_SIS_ID
         , SKL_REF_ID
         , SKL_LOCAL_ID
         , SKL_STATE_ID
         , SKL_NAME
         , SKL_ZIP_CODE
         , SKL_NEIGHBORHOOD
         , SKL_TLT
         , SKL_LVL_TYPE
         , SKL_ID
    from BPSDashboard.staging.SKL_School
    where not SKL_LOCAL_ID in
              (
                  select SKL_LOCAL_ID from BPSDashboard.dbo.SKL_School
              );

    set identity_insert BPSDashboard.dbo.SKL_School off;

    update BPSDashboard.dbo.SKL_School
    set SKL_SIS_ID = ss.SKL_SIS_ID
      , SKL_REF_ID = ss.SKL_REF_ID
      , SKL_LOCAL_ID = ss.SKL_LOCAL_ID
      , SKL_STATE_ID = ss.SKL_STATE_ID
      , SKL_NAME = ss.SKL_NAME
      , SKL_ZIP_CODE = ss.SKL_ZIP_CODE
      , SKL_NEIGHBORHOOD = ss.SKL_NEIGHBORHOOD
      , SKL_TLT = ss.SKL_TLT
      , SKL_LVL_TYPE = ss.SKL_LVL_TYPE
    from
    (
        select SKL_SIS_ID
             , SKL_REF_ID
             , SKL_LOCAL_ID
             , SKL_STATE_ID
             , SKL_NAME
             , SKL_ZIP_CODE
             , SKL_NEIGHBORHOOD
             , SKL_TLT
             , SKL_LVL_TYPE
             , SKL_ID
        from BPSDashboard.staging.SKL_School
        except
        select SKL_SIS_ID
             , SKL_REF_ID
             , SKL_LOCAL_ID
             , SKL_STATE_ID
             , SKL_NAME
             , SKL_ZIP_CODE
             , SKL_NEIGHBORHOOD
             , SKL_TLT
             , SKL_LVL_TYPE
             , SKL_ID
        from BPSDashboard.dbo.SKL_School
    ) ss
    where BPSDashboard.dbo.SKL_School.SKL_ID = ss.SKL_ID;
end;
GO
