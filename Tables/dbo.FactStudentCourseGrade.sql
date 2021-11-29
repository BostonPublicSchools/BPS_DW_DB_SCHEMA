CREATE TABLE [dbo].[FactStudentCourseGrade]
(
[_sourceKey] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TimeKey] [int] NOT NULL,
[GradingPeriodKey] [int] NOT NULL,
[StudentSectionKey] [int] NOT NULL,
[LetterGradeEarned] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NumericGradeEarned] [decimal] (9, 2) NULL,
[LineageKey] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [PK_FactStudentCourseGrade] PRIMARY KEY CLUSTERED ([TimeKey], [GradingPeriodKey], [StudentSectionKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [CSI_FactStudentCourseGrades] ON [dbo].[FactStudentCourseGrade] ([TimeKey], [GradingPeriodKey], [StudentSectionKey], [LetterGradeEarned], [NumericGradeEarned], [LineageKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_GradingPeriodKey] FOREIGN KEY ([GradingPeriodKey]) REFERENCES [dbo].[DimGradingPeriod] ([GradingPeriodKey])
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_StudentSectionKey] FOREIGN KEY ([StudentSectionKey]) REFERENCES [dbo].[DimStudentSection] ([StudentSectionKey])
GO
ALTER TABLE [dbo].[FactStudentCourseGrade] ADD CONSTRAINT [FK_FactStudentCourseGrade_TimeKey] FOREIGN KEY ([TimeKey]) REFERENCES [dbo].[DimTime] ([TimeKey])
GO
