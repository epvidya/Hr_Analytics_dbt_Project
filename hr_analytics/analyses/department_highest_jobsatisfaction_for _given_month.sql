SELECT
    o.department,
    d.calendar_year,
    d.month_number,
    d.month_name,
    ROUND(AVG(f.job_satisfaction), 2)       AS avg_job_satisfaction,
    MIN(f.job_satisfaction)                 AS min_job_satisfaction,
    MAX(f.job_satisfaction)                 AS max_job_satisfaction,
    COUNT(f.employee_sk)                    AS headcount
FROM gold.fact_employee_snapshot f
JOIN gold.dim_org o
    ON f.org_sk             = o.org_sk
JOIN gold.dim_date d
    ON f.snapshot_date_sk   = d.date_sk
WHERE d.date_sk             = 20240101      -- filter to Jan 2024
GROUP BY
    o.department,
    d.calendar_year,
    d.month_number,
    d.month_name
ORDER BY
    avg_job_satisfaction DESC;             -- highest satisfaction first