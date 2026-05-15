-- analyses/compensation_distribution.sql
-- Business question: How is compensation distributed across salary bands,
-- departments and job levels? Are employees paid within their salary band?
-- Metrics: headcount per band, avg salary, band breach detection

with joined as (

    select
        e.emp_id,
        e.full_name,
        o.department,
        j.job_role,
        j.job_level,
        j.job_level_label,
        f.monthly_income,
        f.salary_slab,
        f.salary_slab_min,
        f.salary_slab_max,
        f.percent_salary_hike,
        f.stock_option_level,
        f.stock_option_label,
        f.attrition_flag,
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

band_analysis as (

    select
        department,
        job_level,
        job_level_label,
        salary_slab,
        ANY_VALUE(salary_slab_min)      AS salary_slab_min,   -- carry through
        ANY_VALUE(salary_slab_max)      AS salary_slab_max,
        calendar_year,
        month_name,

        COUNT(*)                                                AS headcount,
        ROUND(AVG(monthly_income), 0)                           AS avg_monthly_income,
        MIN(monthly_income)                                     AS min_monthly_income,
        MAX(monthly_income)                                     AS max_monthly_income,
        ROUND(AVG(percent_salary_hike), 1)                      AS avg_salary_hike_pct,

        -- how many employees are paid within their declared band
        SUM(CASE WHEN monthly_income >= salary_slab_min
                 AND monthly_income <= salary_slab_max
                 THEN 1 END)                                    AS within_band_count,

        -- how many are outside their band
        SUM(CASE WHEN monthly_income < salary_slab_min
                 OR  monthly_income > salary_slab_max
                 THEN 1 END)                                    AS outside_band_count

    from joined
    group by
        department,
        job_level,
        job_level_label,
        salary_slab,
        calendar_year,
        month_name

),

final as (

    select
        department,
        job_level,
        job_level_label,
        salary_slab,
        salary_slab_min,
        salary_slab_max,
        calendar_year,
        month_name,
        headcount,
        avg_monthly_income,
        min_monthly_income,
        max_monthly_income,
        avg_salary_hike_pct,
        within_band_count,
        outside_band_count,

        -- band compliance rate
        ROUND(within_band_count / headcount * 100, 1)           AS band_compliance_pct

    from band_analysis

)

select *
from final
order by
    department,
    job_level,
    salary_slab_min;