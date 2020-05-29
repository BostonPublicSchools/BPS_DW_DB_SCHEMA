CREATE TABLE [dbo].[DimSchool]
(
[SchoolKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShortNameOfInstitution] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NameOfInstitution] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolCategoryType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchoolCategoryType_Elementary] [bit] NOT NULL,
[SchoolCategoryType_Middle] [bit] NOT NULL,
[SchoolCategoryType_HighSchool] [bit] NOT NULL,
[SchoolCategoryType_Combined] [bit] NOT NULL,
[SchoolGradeLevel_Lowest_Descriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchoolGradeLevel_Highest_Descriptor_CodeValue] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchoolGradeLevel_AdultEducation_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_EarlyEducation_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Eighthgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Eleventhgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Fifthgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Firstgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Fourthgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Grade13_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Infanttoddler_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Kindergarten_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Ninthgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Other_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Postsecondary_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_PreschoolPrekindergarten_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Secondgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Seventhgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Sixthgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Tenthgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Thirdgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Twelfthgrade_Indicator] [bit] NOT NULL,
[SchoolGradeLevel_Ungraded_Indicator] [bit] NOT NULL,
[TitleIPartASchoolDesignationTypeCodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TitleIPartASchoolDesignation_Indicator] [bit] NOT NULL,
[AYP_Indicator] [bit] NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimSchool] ADD CONSTRAINT [PK_DimSchool] PRIMARY KEY CLUSTERED  ([SchoolKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimSchool] ADD CONSTRAINT [FK_DimSchool_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
