--analysis: department_job_satisfaction_trend
-- This analysis calculates the average, minimum, and maximum job satisfaction scores for each department over time, along with the headcount for each department in each month. 
-- The results are ordered by calendar year, month number, and department.

SELECT
    o.department,
    f.snapshot_date_sk,
    d.month_year,
    d.calendar_year,
    d.month_number,
    d.month_name,
    ROUND(AVG(f.job_satisfaction), 2)       AS avg_job_satisfaction,
    MIN(f.job_satisfaction)                 AS min_job_satisfaction,
    MAX(f.job_satisfaction)                 AS max_job_satisfaction,
    COUNT(*)                                AS headcount
FROM gold.fact_employee_snapshot f
JOIN gold.dim_org o
    ON f.org_sk             = o.org_sk
JOIN gold.dim_date d
    ON f.snapshot_date_sk   = d.date_sk
GROUP BY
    o.department,
    f.snapshot_date_sk,
    d.month_year,
    d.calendar_year,
    d.month_number,
    d.month_name
ORDER BY
    d.calendar_year,
    d.month_number,
    o.department;