CREATE TABLE [dbo].[FactStudentCourseGrade]
(
[StudentKey] [int] NOT NULL,
[TimeKey] [int] NOT NULL,
[CourseKey] [int] NOT NULL,
[SchoolKey] [int] NOT NULL,
[CreditsEarned] [int] NOT NULL,
[CreditsPossible] [int] NOT NULL,
[FinalMark] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [PK_FactStudentCourseGrade] PRIMARY KEY CLUSTERED  ([StudentKey], [TimeKey], [CourseKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_CourseKey] FOREIGN KEY ([CourseKey]) REFERENCES [dbo].[DimCourse] ([CourseKey])
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_LineageKey] FOREIGN KEY ([LineageKey]) REFERENCES [dbo].[Lineage] ([LineageKey])
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_SchoolKey] FOREIGN KEY ([SchoolKey]) REFERENCES [dbo].[DimSchool] ([SchoolKey])
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_StudentKey] FOREIGN KEY ([StudentKey]) REFERENCES [dbo].[DimStudent] ([StudentKey])
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
