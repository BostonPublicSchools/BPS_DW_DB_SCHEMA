CREATE TABLE [dbo].[ETL_IncrementalLoads]
(
[LoadDateKey] [int] NOT NULL IDENTITY(1, 1),
[TableName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LoadDate] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ETL_IncrementalLoads] ADD CONSTRAINT [PK_LoadDates] PRIMARY KEY CLUSTERED  ([LoadDateKey]) ON [PRIMARY]
GO
