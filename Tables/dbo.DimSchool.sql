CREATE TABLE [dbo].[DimSchool]
(
[SchoolKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DistrictSchoolCode] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StateSchoolCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UmbrellaSchoolCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShortNameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolCategoryType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolCategoryType_Elementary_Indicator] [bit] NOT NULL,
[SchoolCategoryType_Middle_Indicator] [bit] NOT NULL,
[SchoolCategoryType_HighSchool_Indicator] [bit] NOT NULL,
[SchoolCategoryType_Combined_Indicator] [bit] NOT NULL,
[SchoolCategoryType_Other_Indicator] [bit] NOT NULL,
[TitleIPartASchoolDesignationTypeCodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TitleIPartASchoolDesignation_Indicator] [bit] NOT NULL,
[OperationalStatusTypeDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OperationalStatusTypeDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[IsLatest] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimSchool] ADD CONSTRAINT [PK_DimSchool] PRIMARY KEY CLUSTERED  ([SchoolKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [DimSchool_CoveringIndex] ON [dbo].[DimSchool] ([_sourceKey], [ValidFrom]) INCLUDE ([ValidTo], [SchoolKey]) ON [PRIMARY]
GO
