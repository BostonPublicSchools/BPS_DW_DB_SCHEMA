CREATE TABLE [dbo].[ETL_Lineage]
(
[LineageKey] [int] NOT NULL IDENTITY(1, 1),
[TableName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StartTime] [datetime] NOT NULL,
[EndTime] [datetime] NULL,
[LoadType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ETL_Lineage] ADD CONSTRAINT [PK_ETL_Lineage] PRIMARY KEY CLUSTERED  ([LineageKey]) ON [PRIMARY]
GO
