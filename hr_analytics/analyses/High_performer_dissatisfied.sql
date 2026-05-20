-- analyses/high_performer_dissatisfied.sql
-- Business question: Which high performing employees are currently dissatisfied?
-- Use: Proactive retention — intervene before they decide to leave

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
        f.job_satisfaction,
        f.job_satisfaction_label,
        f.environment_satisfaction,
        f.work_life_balance,
        f.work_life_balance_label,
        f.overall_engagement_score,
        f.overtime_flag,
        f.tenure_years,
        f.years_since_last_promotion,
        f.attrition_flag,
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
    job_satisfaction,
    job_satisfaction_label,
    environment_satisfaction,
    work_life_balance,
    work_life_balance_label,
    overall_engagement_score,
    overtime_flag,
    tenure_years,
    years_since_last_promotion

from joined
where performance_rating    >= 3
  and attrition_flag        = false
  and job_satisfaction      <= 2
order by
    calendar_year,
    month_number,
    overall_engagement_score asc,
    job_satisfaction asc;