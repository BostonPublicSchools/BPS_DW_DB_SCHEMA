CREATE TABLE [Staging].[StudentCourseTranscript]
(
[StudentCourseTranscriptKey] [bigint] NOT NULL IDENTITY(1, 1),
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StudentKey] [int] NULL,
[TimeKey] [int] NULL,
[CourseKey] [int] NULL,
[SchoolKey] [int] NULL,
[EarnedCredits] [int] NOT NULL,
[PossibleCredits] [int] NOT NULL,
[FinalLetterGradeEarned] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FinalNumericGradeEarned] [decimal] (9, 2) NULL,
[ModifiedDate] [datetime] NULL,
[_sourceStudentKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceSchoolYear] [int] NULL,
[_sourceTerm] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceCourseKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[_sourceSchoolKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Staging].[StudentCourseTranscript] ADD CONSTRAINT [PK_StagingStudentCourseTranscript] PRIMARY KEY CLUSTERED  ([StudentCourseTranscriptKey]) ON [PRIMARY]
GO
