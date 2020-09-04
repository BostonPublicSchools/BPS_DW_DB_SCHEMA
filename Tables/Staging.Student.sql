CREATE TABLE [Staging].[Student]
(
[StudentKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentUniqueId] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StateId] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PrimaryElectronicMailAddress] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PrimaryElectronicMailTypeDescriptor_CodeValue] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PrimaryElectronicMailTypeDescriptor_Description] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchoolKey] [int] NOT NULL,
[ShortNameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NameOfInstitution] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GradeLevelDescriptor_CodeValue] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GradeLevelDescriptor_Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FirstName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MiddleInitial] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MiddleName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastSurname] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FullName] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BirthDate] [date] NOT NULL,
[StudentAge] [int] NOT NULL,
[GraduationSchoolYear] [int] NULL,
[Homeroom] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HomeroomTeacher] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SexType_Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SexType_Description] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SexType_Male_Indicator] [bit] NOT NULL,
[SexType_Female_Indicator] [bit] NOT NULL,
[SexType_NotSelected_Indicator] [bit] NOT NULL,
[RaceCode] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RaceDescription] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StateRaceCode] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Race_AmericanIndianAlaskanNative_Indicator] [bit] NOT NULL,
[Race_Asian_Indicator] [bit] NOT NULL,
[Race_BlackAfricaAmerican_Indicator] [bit] NOT NULL,
[Race_NativeHawaiianPacificIslander_Indicator] [bit] NOT NULL,
[Race_White_Indicator] [bit] NOT NULL,
[Race_MultiRace_Indicator] [bit] NOT NULL,
[Race_ChooseNotRespond_Indicator] [bit] NOT NULL,
[Race_Other_Indicator] [bit] NOT NULL,
[EthnicityCode] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EthnicityDescription] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EthnicityHispanicLatino_Indicator] [bit] NOT NULL,
[Migrant_Indicator] [bit] NOT NULL,
[Homeless_Indicator] [bit] NOT NULL,
[IEP_Indicator] [bit] NOT NULL,
[English_Learner_Code_Value] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[English_Learner_Description] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[English_Learner_Indicator] [bit] NOT NULL,
[Former_English_Learner_Indicator] [bit] NOT NULL,
[Never_English_Learner_Indicator] [bit] NOT NULL,
[EconomicDisadvantage_Indicator] [bit] NOT NULL,
[EntryDate] [datetime2] NOT NULL,
[EntrySchoolYear] [int] NOT NULL,
[EntryCode] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ExitWithdrawDate] [datetime2] NULL,
[ExitWithdrawSchoolYear] [int] NULL,
[ExitWithdrawCode] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StudentMainInfoModifiedDate] [datetime] NOT NULL,
[StudentSchoolAssociationModifiedDate] [datetime] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[Student] ADD CONSTRAINT [PK_StagingStudent] PRIMARY KEY CLUSTERED  ([StudentKey]) ON [PRIMARY]
GO
