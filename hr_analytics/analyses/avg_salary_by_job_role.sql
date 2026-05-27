--analyses/avg_salary_by_job_role.sql

select
    o.department,
    j.job_role,
    j.job_level,
    j.job_level_label,
    d.month_year,
    d.month_number,
    d.calendar_year,
    ROUND(AVG(f.monthly_income), 0)     AS avg_monthly_income,
    COUNT(*)                            AS headcount
from gold.fact_employee_snapshot f
join gold.dim_org o
    on f.org_sk         = o.org_sk
join gold.dim_job_role j
    on f.job_role_sk    = j.job_role_sk
join gold.dim_date d
    on f.snapshot_date_sk = d.date_sk
group by
    o.department,
    j.job_role,
    j.job_level,
    j.job_level_label,
    d.month_year,
    d.month_number,
    d.calendar_year
order by
    d.month_number,
    o.department,
    avg_monthly_income desc;