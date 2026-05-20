-- This dynamic table calculates the count of employees who have left the company (attrition) by department and termination category, 
--along with the snapshot date and month-year for each record. 
-- The table is refreshed incrementally every hour, and the results are ordered by snapshot date and termination category.

 CREATE OR REPLACE DYNAMIC TABLE hr_analytics_dbt.gold.dt_attrition_summary
    TARGET_LAG = '1 hour'
    WAREHOUSE = compute_wh
    REFRESH_MODE=INCREMENTAL
    AS
      WITH base AS 
            ( SELECT
                o.department                AS DEPARTMENT,
                f.termination_category      AS CATEGORY,
                f.snapshot_date_sk          AS SNAPSHOT_DATE,
                d.month_year                AS MONTH_YEAR
            FROM HR_ANALYTICS_DBT.GOLD.FACT_EMPLOYEE_SNAPSHOT f
            join HR_ANALYTICS_DBT.GOLD.DIM_ORG o
            on f.org_sk=o.org_sk
            JOIN HR_ANALYTICS_DBT.GOLD.DIM_DATE d
            ON f.snapshot_date_sk       = d.date_sk
           -- WHERE f.snapshot_date_sk        = {snapshot}
        )
        SELECT department,
            category,
            snapshot_date,
            month_year,
            COUNT(*)                        AS EMPLOYEE_COUNT
        FROM base
        GROUP BY
            category,
            department,
            snapshot_date,
            month_year
        ORDER BY
            snapshot_date,
            category;