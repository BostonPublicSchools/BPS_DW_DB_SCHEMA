CREATE TABLE [dbo].[DimCourse]
(
[CourseKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseCode] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseTitle] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CourseDescription] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AcademicSubjectDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AcademicSubjectDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AcademicSubjectDescriptor_Math_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_ELA_Indicator] [bit] NOT NULL,
[AcademicSubjectDescriptor_Science_Indicator] [bit] NOT NULL,
[HighSchoolCourseRequirement_Indicator] [bit] NOT NULL,
[MinimumAvailableCredits] [int] NULL,
[MaximumAvailableCredits] [int] NULL,
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
