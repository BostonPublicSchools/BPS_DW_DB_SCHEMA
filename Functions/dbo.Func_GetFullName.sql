SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[Func_GetFullName]
(
    @fName NVARCHAR(256),
    @mName NVARCHAR(256),
    @lName NVARCHAR(256)
)
RETURNS NVARCHAR(768)
AS
BEGIN
    DECLARE @fullName NVARCHAR(768);
    SELECT @fullName
        = LTRIM(RTRIM(LTRIM(@fName)) + RTRIM(' ' + LTRIM(ISNULL(@mName, ''))) + RTRIM(' ' + LTRIM(@lName)));
    RETURN @fullName;
END;

GO
