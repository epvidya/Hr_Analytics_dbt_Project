-- analyses/tenure_analysis.sql
-- Business question: Do longer tenured employees have lower satisfaction
-- and are they more likely to attrite?

select
    e.emp_id,
    e.full_name,
    o.department,
    j.job_role,
    j.job_level,
    j.job_level_label,
    f.tenure_years,
    f.years_in_current_role,
    f.years_since_last_promotion,
    f.years_with_curr_manager,
    f.job_satisfaction,
    f.overall_engagement_score,
    f.attrition_flag,
    f.is_voluntary,
    d.snapshot_date_sk,
    d.month_year,
    d.calendar_year,
    d.month_number,
    d.month_name,

    -- tenure band for Tableau grouping
    case
        when f.tenure_years < 1   then '0-1 years'
        when f.tenure_years < 3   then '1-3 years'
        when f.tenure_years < 5   then '3-5 years'
        when f.tenure_years < 10  then '5-10 years'
        else                           '10+ years'
    end                               as tenure_band

from gold.fact_employee_snapshot f
join gold.dim_employee e
    on f.employee_sk        = e.employee_sk
join gold.dim_org o
    on f.org_sk             = o.org_sk
join gold.dim_job_role j
    on f.job_role_sk        = j.job_role_sk
join gold.dim_date d
    on f.snapshot_date_sk   = d.date_sk

order by
    d.calendar_year,
    d.month_number,
    f.tenure_years desc;