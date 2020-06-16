CREATE TABLE [dbo].[DimCourse]
(
[CourseKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseCode] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseTitle] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseDescription] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AcademicSubjectDescriptor_Biology_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_CareerAndTechnicalEducation_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Chemistry_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Composite_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_CriticalReading_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_EnglishLanguageArts_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_English_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_FineAndPerformingArts_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_ForeignLanguageAndLiterature_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_IntroductoryPhysics_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_LifeAndPhysicalSciences_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Mathematics_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_MilitaryScience_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Other_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_PhysicalHealthAndSafetyEducation_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Reading_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_ReligiousEducationAndTheology_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Science_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_SocialSciencesAndHistory_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_SocialStudies_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_TechnologyEngineering_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Writing_Indicator] [bit] NOT NULL,
[HighSchoolCourseRequirement_Indicator] [bit] NOT NULL,
[MinimumAvailableCredits] [int] NULL,
[MaximumAvailableCredits] [int] NULL,
[GPAApplicabilityType_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GPAApplicabilityType_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimCourse] ADD CONSTRAINT [PK_DimCourse] PRIMARY KEY CLUSTERED  ([CourseKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimCourse] ADD CONSTRAINT [FK_DimCourse_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
