--analysis: attrition_rate
-- This SQL query calculates the attrition rate for employees in different departments over time. 
--It joins the FACT_EMPLOYEE_SNAPSHOT table with the DIM_ORG and DIM_DATE tables to get relevant information about the organization and date. 
--The query groups the results by department and date, and calculates the total number of employees, the number of attrited employees, active employees, voluntary and involuntary attritions, and the attrition rate percentage. 
--The results are ordered by calendar year, month number, and department.

SELECT
    o.department,
    d.snapshot_date_sk,
    d.month_year,
    d.calendar_year,
    d.month_number,
    COUNT(*)                                                AS total_employees,
    SUM(CASE WHEN f.attrition_flag = true  THEN 1 END)     AS attrited,
    SUM(CASE WHEN f.attrition_flag = false THEN 1 END)      AS active,
    SUM(CASE WHEN f.is_voluntary = true    THEN 1 END)      AS voluntary,
    SUM(CASE WHEN f.is_voluntary = false
             AND f.attrition_flag = true   THEN 1 END)      AS involuntary,
    ROUND(
        SUM(CASE WHEN f.attrition_flag = true THEN 1 END)
        / COUNT(*) * 100, 1
    )                                                       AS attrition_rate_pct
FROM HR_ANALYTICS_DBT.GOLD.FACT_EMPLOYEE_SNAPSHOT f
JOIN HR_ANALYTICS_DBT.GOLD.DIM_ORG o
    ON f.org_sk             = o.org_sk
JOIN HR_ANALYTICS_DBT.GOLD.DIM_DATE d
    ON f.snapshot_date_sk   = d.date_sk
GROUP BY
    o.department,
    d.snapshot_date_sk,
    d.month_year,
    d.calendar_year,
    d.month_number
ORDER BY
    d.calendar_year,
    d.month_number,
    o.department;