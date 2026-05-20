-- analyses/promotion_overdue_active.sql
-- Business question: Which active employees have not been promoted in 3+ years?
-- Use: HR intervention list — who needs promotion review now

select
    e.emp_id,
    e.full_name,
    o.department,
    j.job_role,
    j.job_level,
    j.job_level_label,
    f.years_since_last_promotion,
    f.months_since_last_promotion,
    f.tenure_years,
    f.job_satisfaction,
    f.overall_engagement_score,
    f.overtime_flag,
    d.snapshot_date_sk,
    d.month_year,
    d.calendar_year,
    d.month_number,
    d.month_name

from gold.fact_employee_snapshot f
join gold.dim_employee e
    on f.employee_sk        = e.employee_sk
join gold.dim_org o
    on f.org_sk             = o.org_sk
join gold.dim_job_role j
    on f.job_role_sk        = j.job_role_sk
join gold.dim_date d
    on f.snapshot_date_sk   = d.date_sk

where f.years_since_last_promotion  >= 3
  and f.attrition_flag              = false

order by
    d.calendar_year,
    d.month_number,
    f.years_since_last_promotion desc,
    f.overall_engagement_score asc;