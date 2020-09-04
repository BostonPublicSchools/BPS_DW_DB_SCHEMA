SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--create function to derive schoolyear from a date
CREATE FUNCTION [dbo].[Func_ETL_GetFullName]
(
    @fName NVARCHAR(256),
    @mName NVARCHAR(256),
    @lName NVARCHAR(256)
)
RETURNS NVARCHAR(768)
AS
BEGIN
    DECLARE @fullName NVARCHAR(768);
    SELECT @fullName   = CONCAT_WS(' ',RTRIM(LTRIM(@fName)), LTRIM(COALESCE(@mName, '')), RTRIM(LTRIM(@lName)));
    RETURN @fullName;
END;

GO
