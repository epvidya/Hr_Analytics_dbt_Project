-- analyses/attrition_rate.sql
-- Business question: What is the attrition rate by department, job level
-- and recruitment source for the snapshot period?
-- Metric: attrition rate = attrited employees / total employees * 100

with joined as (

    select
        f.attrition_flag,
        f.is_voluntary,
        f.termination_category,
        o.department,
        o.business_travel,
        j.job_level,
        j.job_level_label,
        j.job_role,
        e.recruitment_source,
        e.recruitment_category,
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

aggregated as (

    select
        department,
        job_level,
        job_level_label,
        recruitment_source,
        recruitment_category,
        calendar_year,
        month_name,
        COUNT(*)                                                AS total_employees,
        SUM(CASE WHEN attrition_flag = true  THEN 1 END)       AS attrited_employees,
        SUM(CASE WHEN attrition_flag = false THEN 1 END)        AS active_employees,
        SUM(CASE WHEN is_voluntary = true    THEN 1 END)        AS voluntary_attrition,
        SUM(CASE WHEN is_voluntary = false
                 AND attrition_flag = true   THEN 1 END)        AS involuntary_attrition

    from joined
    group by
        department,
        job_level,
        job_level_label,
        recruitment_source,
        recruitment_category,
        calendar_year,
        month_name

),

final as (

    select
        department,
        job_level,
        job_level_label,
        recruitment_source,
        recruitment_category,
        calendar_year,
        month_name,
        total_employees,
        attrited_employees,
        active_employees,
        voluntary_attrition,
        involuntary_attrition,

        -- attrition rate
        ROUND(attrited_employees / total_employees * 100, 1)    AS attrition_rate_pct,

        -- voluntary vs involuntary split
        ROUND(voluntary_attrition / NULLIF(attrited_employees, 0) * 100, 1)
                                                                AS voluntary_pct,
        ROUND(involuntary_attrition / NULLIF(attrited_employees, 0) * 100, 1)
                                                                AS involuntary_pct

    from aggregated

)

select *
from final
order by
    attrition_rate_pct desc,
    department,
    job_level;