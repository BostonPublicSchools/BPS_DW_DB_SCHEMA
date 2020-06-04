SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[Func_GetEasterHolidays]
(
    @TheYear INT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH x
    AS (SELECT TheDate = DATEFROMPARTS(@TheYear, [Month], [Day])
        FROM
        (
            SELECT [Month],
                   [Day] = DaysToSunday + 28 - (31 * ([Month] / 4))
            FROM
            (
                SELECT [Month] = 3 + (DaysToSunday + 40) / 44,
                       DaysToSunday
                FROM
                (
                    SELECT DaysToSunday = paschal - ((@TheYear + (@TheYear / 4) + paschal - 13) % 7)
                    FROM
                    (
                        SELECT paschal = epact - (epact / 28)
                        FROM
                        (SELECT epact = (24 + 19 * (@TheYear % 19)) % 30) AS epact
                    ) AS paschal
                ) AS dts
            ) AS m
        ) AS d )
    SELECT TheDate,
           HolidayText = 'Easter Sunday'
    FROM x
    UNION ALL
    SELECT DATEADD(DAY, -2, TheDate),
           'Good Friday'
    FROM x
    UNION ALL
    SELECT DATEADD(DAY, 1, TheDate),
           'Easter Monday'
    FROM x
);
GO
