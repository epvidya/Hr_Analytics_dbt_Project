-- analyses/headcount_trend.sql
-- Business question: How does headcount change over time by department?
-- Metrics: total headcount, active headcount, FTE headcount, attrition count
-- FTE headcount counts only full time employees for budget planning

with joined as (

    select
        f.attrition_flag,
        f.overtime_flag,
        e.is_full_time,
        e.employment_type,
        o.department,
        j.job_level,
        j.job_level_label,
        l.region,
        d.snapshot_date_sk,
        d.calendar_year,
        d.month_number,
        d.month_name,
        d.month_year

    from gold.fact_employee_snapshot f
    join gold.dim_employee e
        on f.employee_sk        = e.employee_sk
    join gold.dim_org o
        on f.org_sk             = o.org_sk
    join gold.dim_job_role j
        on f.job_role_sk        = j.job_role_sk
    join gold.dim_location l
        on f.location_sk        = l.location_sk
    join gold.dim_date d
        on f.snapshot_date_sk   = d.date_sk

),

aggregated as (

    select
        department,
        job_level,
        job_level_label,
        region,
        snapshot_date_sk,
        calendar_year,
        month_number,
        month_name,
        month_year,

        COUNT(*)                                                AS total_headcount,
        SUM(CASE WHEN attrition_flag = false THEN 1 END)        AS active_headcount,
        SUM(CASE WHEN attrition_flag = true  THEN 1 END)        AS attrited_headcount,
        SUM(CASE WHEN is_full_time = true
                 AND attrition_flag = false THEN 1 END)         AS fte_headcount,
        SUM(CASE WHEN is_full_time = false
                 AND attrition_flag = false THEN 1 END)         AS non_fte_headcount,
        SUM(CASE WHEN overtime_flag = true
                 AND attrition_flag = false THEN 1 END)         AS overtime_headcount

    from joined
    group by
        department,
        job_level,
        job_level_label,
        region,
        snapshot_date_sk,
        calendar_year,
        month_number,
        month_name,
        month_year

)

select *
from aggregated
order by
    calendar_year,
    month_number,
    department,
    job_level;