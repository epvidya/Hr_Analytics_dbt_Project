-- analyses/tenure_analysis.sql
-- Business question: How does tenure distribution look across departments
-- and job levels? Do longer tenured employees have higher satisfaction?
-- Are long tenured employees more likely to attrite?
-- Metrics: avg tenure, tenure bands, satisfaction by tenure, attrition by tenure

with joined as (

    select
        e.emp_id,
        e.full_name,
        o.department,
        j.job_role,
        j.job_level,
        j.job_level_label,
        f.tenure_years,
        f.tenure_months,
        f.years_at_company,
        f.years_in_current_role,
        f.years_with_curr_manager,
        f.years_since_last_promotion,
        f.num_companies_worked,
        f.total_working_years,
        f.overall_engagement_score,
        f.job_satisfaction,
        f.attrition_flag,
        f.is_voluntary,
        d.calendar_year,
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

),

banded as (

    select
        emp_id,
        full_name,
        department,
        job_role,
        job_level,
        job_level_label,
        tenure_years,
        tenure_months,
        years_at_company,
        years_in_current_role,
        years_with_curr_manager,
        years_since_last_promotion,
        num_companies_worked,
        total_working_years,
        overall_engagement_score,
        job_satisfaction,
        attrition_flag,
        is_voluntary,
        calendar_year,
        month_name,

        -- tenure band
        case
            when tenure_years < 1   then '0-1 years'
            when tenure_years < 3   then '1-3 years'
            when tenure_years < 5   then '3-5 years'
            when tenure_years < 10  then '5-10 years'
            else                         '10+ years'
        end                                                     as tenure_band,

        -- tenure band sort order
        case
            when tenure_years < 1   then 1
            when tenure_years < 3   then 2
            when tenure_years < 5   then 3
            when tenure_years < 10  then 4
            else                         5
        end                                                     as tenure_band_order

    from joined

),

aggregated as (

    select
        department,
        job_level,
        job_level_label,
        tenure_band,
        tenure_band_order,
        calendar_year,
        month_name,

        COUNT(*)                                                AS headcount,
        ROUND(AVG(tenure_years), 1)                             AS avg_tenure_years,
        ROUND(AVG(years_in_current_role), 1)                    AS avg_years_in_role,
        ROUND(AVG(years_since_last_promotion), 1)               AS avg_years_since_promotion,
        ROUND(AVG(overall_engagement_score), 2)                 AS avg_engagement,
        ROUND(AVG(job_satisfaction), 2)                         AS avg_job_satisfaction,
        SUM(CASE WHEN attrition_flag = true THEN 1 END)         AS attrited,
        ROUND(
            SUM(CASE WHEN attrition_flag = true THEN 1 END)
            / COUNT(*) * 100, 1
        )                                                       AS attrition_rate_pct

    from banded
    group by
        department,
        job_level,
        job_level_label,
        tenure_band,
        tenure_band_order,
        calendar_year,
        month_name

)

select *
from aggregated
order by
    department,
    job_level,
    tenure_band_order;