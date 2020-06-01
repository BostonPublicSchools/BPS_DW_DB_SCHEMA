SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--create function to derive schoolyear from a date
CREATE FUNCTION [dbo].[Func_GetSchoolYear]( @CurrentDate datetime )
RETURNS int
AS
BEGIN

	-- Declare the return variable here
	DECLARE
	   @Result int;

	DECLARE
	   @schoolYearRolloverDate date = '07/01/9999';

	
	IF (DATEPART(dayofyear, @CurrentDate)  >= DATEPART(dayofyear, @schoolYearRolloverDate))
		BEGIN
			SET @Result = YEAR( @CurrentDate ) + 1;
		END;
	ELSE
		BEGIN
			SET @Result = YEAR( @CurrentDate );
		END;
   
      	    	    
	-- Return the result of the function
	RETURN @Result;

END;
GO
