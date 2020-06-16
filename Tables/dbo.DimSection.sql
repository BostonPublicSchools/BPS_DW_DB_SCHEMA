CREATE TABLE [dbo].[DimSection]
(
[SectionKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolYear] [smallint] NOT NULL,
[SchoolKey] [int] NOT NULL,
[ShortNameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ClassPeriodName] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ClassroomIdentificationCode] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LocalCourseCode] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolTermDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolTermDescriptor_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimSection] ADD CONSTRAINT [PK_DimSection] PRIMARY KEY CLUSTERED  ([SectionKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimSection] ADD CONSTRAINT [FK_DimSection_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
