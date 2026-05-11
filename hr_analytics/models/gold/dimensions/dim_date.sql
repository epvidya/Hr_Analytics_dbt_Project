{{ config(
    materialized = 'table',
    schema       = 'gold'
) }}

with date_spine as (

    select CAST('2010-01-01' AS DATE) AS calendar_date

    union all

    select DATEADD(DAY, 1, calendar_date)
    from   date_spine
    where  calendar_date < '2030-12-31'

)

select

    CAST(TO_CHAR(calendar_date, 'YYYYMMDD') AS INT)         AS date_sk,
    calendar_date                                            AS full_date,

    DAY(calendar_date)                                       AS day_of_month,

    CASE DAYNAME(calendar_date)
        WHEN 'Sun' THEN 1
        WHEN 'Mon' THEN 2
        WHEN 'Tue' THEN 3
        WHEN 'Wed' THEN 4
        WHEN 'Thu' THEN 5
        WHEN 'Fri' THEN 6
        WHEN 'Sat' THEN 7
    END                                                      AS day_of_week,

    DAYNAME(calendar_date)                                   AS day_name,
    DAYOFYEAR(calendar_date)                                 AS day_of_year,
    WEEKISO(calendar_date)                                   AS week_of_year,

    CASE DAYNAME(calendar_date)
        WHEN 'Sat' THEN TRUE
        WHEN 'Sun' THEN TRUE
        ELSE FALSE
    END                                                      AS is_weekend,

    CASE DAYNAME(calendar_date)
        WHEN 'Sat' THEN FALSE
        WHEN 'Sun' THEN FALSE
        ELSE TRUE
    END                                                      AS is_workday,

    MONTH(calendar_date)                                     AS month_number,
    TO_CHAR(calendar_date, 'MMMM')                           AS month_name,
    TO_CHAR(calendar_date, 'Mon')                            AS month_short,
    DATE_TRUNC('MONTH', calendar_date)                       AS first_day_of_month,
    LAST_DAY(calendar_date)                                  AS last_day_of_month,

    QUARTER(calendar_date)                                   AS quarter_number,
    'Q' || QUARTER(calendar_date)                            AS quarter_label,
    DATE_TRUNC('QUARTER', calendar_date)                     AS first_day_of_quarter,

    YEAR(calendar_date)                                      AS calendar_year,
    YEAR(calendar_date) || ' Q' || QUARTER(calendar_date)    AS year_quarter,
    TO_CHAR(calendar_date, 'Mon YYYY')                       AS month_year,

    CASE
        WHEN MONTH(calendar_date) >= 4 THEN YEAR(calendar_date)
        ELSE YEAR(calendar_date) - 1
    END                                                      AS fiscal_year,

    CASE
        WHEN MONTH(calendar_date) IN (4, 5, 6)    THEN 1
        WHEN MONTH(calendar_date) IN (7, 8, 9)    THEN 2
        WHEN MONTH(calendar_date) IN (10, 11, 12) THEN 3
        WHEN MONTH(calendar_date) IN (1, 2, 3)    THEN 4
    END                                                      AS fiscal_quarter,

    FALSE                                                    AS is_holiday,
    NULL::VARCHAR                                            AS holiday_name

from date_spine
order by calendar_date