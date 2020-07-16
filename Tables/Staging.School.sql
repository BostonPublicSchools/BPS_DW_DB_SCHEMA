CREATE TABLE [Staging].[School]
(
[SchoolKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
[SchoolNameModifiedDate] [datetime] NOT NULL,
[SchoolOperationalStatusTypeModifiedDate] [datetime] NOT NULL,
[SchoolCategoryModifiedDate] [datetime] NOT NULL,
[SchoolTitle1StatusModifiedDate] [datetime] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[School] ADD CONSTRAINT [PK_StagingSchool] PRIMARY KEY CLUSTERED  ([SchoolKey]) ON [PRIMARY]
GO
