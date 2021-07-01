CREATE TABLE [Staging].[Course]
(
[CourseKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LocalCourseCode] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CourseCode] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseTitle] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseDescription] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseLevelCharacteristicTypeDescriptor_CodeValue] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseLevelCharacteristicTypeDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AcademicSubjectDescriptor_CodeValue] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AcademicSubjectDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[HighSchoolCourseRequirement_Indicator] [bit] NOT NULL,
[MinimumAvailableCredits] [int] NULL,
[MaximumAvailableCredits] [int] NULL,
[GPAApplicabilityType_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GPAApplicabilityType_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SecondaryCourseLevelCharacteristicTypeDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SecondaryCourseLevelCharacteristicTypeDescriptor_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseModifiedDate] [datetime] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[Course] ADD CONSTRAINT [PK_StagingCourse] PRIMARY KEY CLUSTERED  ([CourseKey]) ON [PRIMARY]
GO
