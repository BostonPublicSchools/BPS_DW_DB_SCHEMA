SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[View_StudentDiscipline]
AS
SELECT DISTINCT 
             ds.StudentUniqueId AS StudentId, ds.StateId AS StudentStateId, ds.FirstName, ds.LastSurname AS LastName, dsc.NameOfInstitution AS SchoolName, dt.SchoolDate AS IncidentDate, ddi.BehaviorDescriptor_CodeValue AS IncidentType, 
             ddi.LocationDescriptor_CodeValue AS IncidentLocation, ddi.DisciplineDescriptor_CodeValue AS IncidentAction, ddi.ReporterDescriptor_CodeValue AS IncidentReporter, ddi.DisciplineDescriptor_ISS_Indicator AS IsISS, ddi.DisciplineDescriptor_OSS_Indicator AS IsOSS
FROM   dbo.FactStudentDiscipline AS fsd INNER JOIN
             dbo.DimStudent AS ds ON fsd.StudentKey = ds.StudentKey INNER JOIN
             dbo.DimTime AS dt ON fsd.TimeKey = dt.TimeKey INNER JOIN
             dbo.DimSchool AS dsc ON fsd.SchoolKey = dsc.SchoolKey INNER JOIN
             dbo.DimDisciplineIncident AS ddi ON fsd.DisciplineIncidentKey = ddi.DisciplineIncidentKey
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "fsd"
            Begin Extent = 
               Top = 9
               Left = 57
               Bottom = 206
               Right = 327
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ds"
            Begin Extent = 
               Top = 207
               Left = 57
               Bottom = 404
               Right = 577
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "dt"
            Begin Extent = 
               Top = 405
               Left = 57
               Bottom = 602
               Right = 462
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "dsc"
            Begin Extent = 
               Top = 603
               Left = 57
               Bottom = 800
               Right = 520
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ddi"
            Begin Extent = 
               Top = 801
               Left = 57
               Bottom = 998
               Right = 462
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 4530
         Alias = 900
         Table = 1170
         Output = 1930
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
', 'SCHEMA', N'dbo', 'VIEW', N'View_StudentDiscipline', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'End
', 'SCHEMA', N'dbo', 'VIEW', N'View_StudentDiscipline', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'View_StudentDiscipline', NULL, NULL
GO
