CREATE TABLE [dbo].[FactStudentCourseTranscript]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[CourseKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[EarnedCredits] [int] NOT NULL,
[PossibleCredits] [int] NOT NULL,
[FinalLetterGradeEarned] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FinalNumericGradeEarned] [decimal] (9, 2) NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentCourseTranscript] ADD CONSTRAINT [PK_FactStudentCourseTranscript] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [CourseKey], [SchoolKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [CSI_FactStudentCourseTranscript] ON [dbo].[FactStudentCourseTranscript] ([StudentKey], [TimeKey], [CourseKey], [SchoolKey], [EarnedCredits], [PossibleCredits], [FinalLetterGradeEarned], [FinalNumericGradeEarned], [LineageKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentCourseTranscript] ADD CONSTRAINT [FK_FactStudentCourseTranscript_CourseKey] FOREIGN KEY ([CourseKey]) REFERENCES [dbo].[DimCourse] ([CourseKey])
GO
ALTER TABLE [dbo].[FactStudentCourseTranscript] ADD CONSTRAINT [FK_FactStudentCourseTranscript_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentCourseTranscript] ADD CONSTRAINT [FK_FactStudentCourseTranscript_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentCourseTranscript] ADD CONSTRAINT [FK_FactStudentCourseTranscript_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentCourseTranscript] ADD CONSTRAINT [FK_FactStudentCourseTranscript_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
