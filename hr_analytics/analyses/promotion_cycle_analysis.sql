-- analyses/promotion_cycle_analysis.sql
-- Business question: How long does it take employees to get promoted?
-- Are promotion cycles consistent across departments and job levels?
-- Do employees with longer promotion cycles have lower satisfaction?
-- Metrics: avg months since promotion, promotion cycle by dept and level,
--          satisfaction vs promotion recency correlation

with joined as (

    select
        e.emp_id,
        e.full_name,
        o.department,
        j.job_role,
        j.job_level,
        j.job_level_label,
        f.months_since_last_promotion,
        f.years_since_last_promotion,
        f.tenure_years,
        f.job_satisfaction,
        f.overall_engagement_score,
        f.attrition_flag,
        f.is_voluntary,
        f.overtime_flag,
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
        months_since_last_promotion,
        years_since_last_promotion,
        tenure_years,
        job_satisfaction,
        overall_engagement_score,
        attrition_flag,
        is_voluntary,
        overtime_flag,
        calendar_year,
        month_name,

        -- promotion recency band
        case
            when months_since_last_promotion < 12   then 'Within 1 year'
            when months_since_last_promotion < 24   then '1-2 years'
            when months_since_last_promotion < 36   then '2-3 years'
            when months_since_last_promotion < 60   then '3-5 years'
            else                                         '5+ years'
        end                                             as promotion_recency_band,

        -- sort order for band
        case
            when months_since_last_promotion < 12   then 1
            when months_since_last_promotion < 24   then 2
            when months_since_last_promotion < 36   then 3
            when months_since_last_promotion < 60   then 4
            else                                         5
        end                                             as promotion_recency_order,

        -- overdue promotion flag
        case
            when years_since_last_promotion >= 3    then true
            else                                         false
        end                                             as promotion_overdue

    from joined

),

aggregated as (

    select
        department,
        job_level,
        job_level_label,
        promotion_recency_band,
        promotion_recency_order,
        calendar_year,
        month_name,

        COUNT(*)                                                AS headcount,
        ROUND(AVG(months_since_last_promotion), 1)              AS avg_months_since_promotion,
        ROUND(AVG(job_satisfaction), 2)                         AS avg_job_satisfaction,
        ROUND(AVG(overall_engagement_score), 2)                 AS avg_engagement,
        SUM(CASE WHEN promotion_overdue = true THEN 1 END)      AS overdue_promotion_count,
        SUM(CASE WHEN attrition_flag = true THEN 1 END)         AS attrited,
        ROUND(
            SUM(CASE WHEN attrition_flag = true THEN 1 END)
            / COUNT(*) * 100, 1
        )                                                       AS attrition_rate_pct,

        -- are overdue employees more likely to attrite
        ROUND(
            SUM(CASE WHEN promotion_overdue = true
                     AND attrition_flag = true THEN 1 END)
            / NULLIF(SUM(CASE WHEN promotion_overdue = true THEN 1 END), 0) * 100, 1
        )                                                       AS overdue_attrition_rate_pct

    from banded
    group by
        department,
        job_level,
        job_level_label,
        promotion_recency_band,
        promotion_recency_order,
        calendar_year,
        month_name

)

select *
from aggregated
order by
    department,
    job_level,
    promotion_recency_order;