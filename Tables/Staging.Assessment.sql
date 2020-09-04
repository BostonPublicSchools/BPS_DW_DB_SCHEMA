CREATE TABLE [Staging].[Assessment]
(
[AssessmentKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AssessmentCategoryDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AssessmentCategoryDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AssessmentFamilyTitle] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AdaptiveAssessment_Indicator] [bit] NOT NULL,
[AssessmentIdentifier] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AssessmentTitle] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ReportingMethodDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ReportingMethodDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ResultDatatypeTypeDescriptor_CodeValue] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ResultDatatypeTypeDescriptor_Description] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AssessmentScore_Indicator] [bit] NOT NULL,
[AssessmentPerformanceLevel_Indicator] [bit] NOT NULL,
[ObjectiveAssessmentScore_Indicator] [bit] NOT NULL,
[ObjectiveAssessmentPerformanceLevel_Indicator] [bit] NOT NULL,
[AssessmentModifiedDate] [datetime] NOT NULL,
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[Assessment] ADD CONSTRAINT [PK_StaginAssessment] PRIMARY KEY CLUSTERED  ([AssessmentKey]) ON [PRIMARY]
GO
