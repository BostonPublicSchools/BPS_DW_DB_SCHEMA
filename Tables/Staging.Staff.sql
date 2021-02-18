CREATE TABLE [Staging].[Staff]
(
[StaffKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PrimaryElectronicMailAddress] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PrimaryElectronicMailTypeDescriptor_CodeValue] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PrimaryElectronicMailTypeDescriptor_Description] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StaffUniqueId] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PersonalTitlePrefix] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FirstName] [nvarchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MiddleName] [nvarchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MiddleInitial] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastSurname] [nvarchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FullName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GenerationCodeSuffix] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaidenName] [nvarchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BirthDate] [date] NULL,
[StaffAge] [int] NULL,
[SexType_Code] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SexType_Description] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SexType_Male_Indicator] [bit] NOT NULL,
[SexType_Female_Indicator] [bit] NOT NULL,
[SexType_NotSelected_Indicator] [bit] NOT NULL,
[HighestLevelOfEducationDescriptorDescriptor_CodeValue] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HighestLevelOfEducationDescriptorDescriptor_Description] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[YearsOfPriorProfessionalExperience] [decimal] (5, 2) NULL,
[YearsOfPriorTeachingExperience] [decimal] (5, 2) NULL,
[HighlyQualifiedTeacher_Indicator] [bit] NULL,
[StaffClassificationDescriptor_CodeValue] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StaffClassificationDescriptor_CodeDescription] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StaffMainInfoModifiedDate] [datetime] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[Staff] ADD CONSTRAINT [PK_DimStaff] PRIMARY KEY CLUSTERED  ([StaffKey]) ON [PRIMARY]
GO
