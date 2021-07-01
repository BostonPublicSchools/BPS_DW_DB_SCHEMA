SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--********************************************************************************
--**                              ETL RELATED OBJECTS                           **
--********************************************************************************


--functions
--------------------------------------------------------------
--create function to derive schoolyear from a date
CREATE FUNCTION [dbo].[Func_ETL_GetSchoolYear]
(
    @CurrentDate DATETIME
)
RETURNS INT
WITH SCHEMABINDING
AS
BEGIN

    -- Declare the return variable here
    DECLARE @Result INT;

    DECLARE @schoolYearRolloverDate DATE = '07/01/9999';


    IF (DATEPART(DAYOFYEAR, @CurrentDate) >= DATEPART(DAYOFYEAR, @schoolYearRolloverDate))
    BEGIN
        SET @Result = YEAR(@CurrentDate) + 1;
    END;
    ELSE
    BEGIN
        SET @Result = YEAR(@CurrentDate);
    END;

    -- Return the result of the function
    RETURN @Result;

END;
GO
