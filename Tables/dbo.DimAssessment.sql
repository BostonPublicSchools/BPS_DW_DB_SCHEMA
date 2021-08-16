CREATE TABLE [dbo].[DimAssessment]
(
[AssessmentKey] [int] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
[ValidFrom] [datetime] NOT NULL,
[ValidTo] [datetime] NOT NULL,
[IsCurrent] [bit] NOT NULL,
[IsLatest] [bit] NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimAssessment] ADD CONSTRAINT [PK_DimAssessment] PRIMARY KEY CLUSTERED  ([AssessmentKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [DimAssessment_CoveringIndex] ON [dbo].[DimAssessment] ([_sourceKey], [ValidFrom], [ValidTo]) INCLUDE ([AssessmentKey]) ON [PRIMARY]
GO
