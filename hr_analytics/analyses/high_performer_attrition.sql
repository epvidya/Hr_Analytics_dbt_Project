-- analyses/high_performer_attrition.sql
-- Business question: Which high performing employees have already left?
-- Use: Post mortem analysis — understand what drove top talent out

with joined as (

    select
        e.emp_id,
        e.full_name,
        o.department,
        j.job_role,
        j.job_level,
        j.job_level_label,
        f.performance_rating,
        f.performance_rating_label,
        f.attrition_flag,
        f.termination_reason,
        f.termination_category,
        f.is_voluntary,
        f.tenure_years,
        f.months_before_exit,
        f.overall_engagement_score,
        f.job_satisfaction,
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

)

select
    emp_id,
    full_name,
    department,
    job_role,
    job_level,
    job_level_label,
    snapshot_date_sk,
    month_year,
    calendar_year,
    month_number,
    month_name,
    performance_rating,
    performance_rating_label,
    termination_reason,
    termination_category,
    is_voluntary,
    tenure_years,
    months_before_exit,
    overall_engagement_score,
    job_satisfaction

from joined
where performance_rating    >= 3
  and attrition_flag        = true
order by
    calendar_year,
    month_number,
    months_before_exit asc;