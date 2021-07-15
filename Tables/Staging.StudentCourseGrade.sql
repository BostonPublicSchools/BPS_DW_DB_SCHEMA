CREATE TABLE [Staging].[StudentCourseGrade]
(
[StudentCourseGradetKey] [bigint] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TimeKey] [int] NULL,
[GradingPeriodKey] [int] NULL,
[StudentSectionKey] [int] NULL,
[LetterGradeEarned] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NumericGradeEarned] [decimal] (9, 2) NULL,
[ModifiedDate] [datetime] NULL,
[_sourceGradingPeriodey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceStudentSectionKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentCourseGrade] ADD CONSTRAINT [PK_StagingStudentCourseGrade] PRIMARY KEY CLUSTERED  ([StudentCourseGradetKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Staging_StudentCourseGrade__SourceGradingPeriodey] ON [Staging].[StudentCourseGrade] ([_sourceGradingPeriodey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Staging_StudentCourseGrade__SourceStudentSectionKey] ON [Staging].[StudentCourseGrade] ([_sourceStudentSectionKey]) ON [PRIMARY]
GO
