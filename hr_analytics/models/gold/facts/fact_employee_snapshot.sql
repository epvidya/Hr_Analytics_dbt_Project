{{ config(
    materialized = 'table',
    schema       = 'gold'
) }}

with source as (
    select * from {{ ref('silver_hr_cleaned') }}
),

dim_employee as (
    select * from {{ ref('dim_employee') }}
),

dim_manager as (
    select * from {{ ref('dim_manager') }}
),

dim_job_role as (
    select * from {{ ref('dim_job_role') }}
),

dim_org as (
    select * from {{ ref('dim_org') }}
),

dim_location as (
    select * from {{ ref('dim_location') }}
),

final as (

    select

        -- -------------------------------------------------------
        -- fact surrogate key
        -- grain: one row per employee per snapshot date
        -- -------------------------------------------------------
        {{ dbt_utils.generate_surrogate_key(['s.emp_id', 's.snapshot_date']) }}     AS fact_sk,

  
        e.employee_sk,
        e.emp_id,
        e.manager_id
        m.manager_sk,
        j.job_role_sk,
        o.org_sk,
        l.location_sk,


        CAST(TO_CHAR(s.snapshot_date,       'YYYYMMDD') AS INT)                     AS snapshot_date_sk,
        CAST(TO_CHAR(s.join_date,           'YYYYMMDD') AS INT)                     AS join_date_sk,
        CAST(TO_CHAR(s.last_promotion_date, 'YYYYMMDD') AS INT)                     AS last_promotion_date_sk,

        -- NULL for active employees
        CASE
            WHEN s.exit_date IS NULL THEN NULL
            ELSE CAST(TO_CHAR(s.exit_date, 'YYYYMMDD') AS INT)
        END                                                                         AS exit_date_sk,


        s.attrition_flag,
        s.overtime_flag,
        s.is_voluntary,
        s.termination_reason,
        s.termination_category,


        s.monthly_income,
        s.salary_slab,
        s.salary_slab_min,
        s.salary_slab_max,
        s.daily_rate,
        s.hourly_rate,
        s.monthly_rate,
        s.percent_salary_hike,
        s.stock_option_level,
        s.stock_option_label,
        s.stock_option_description,


        s.performance_rating,
        s.performance_rating_label,

        s.environment_satisfaction,
        s.environment_satisfaction_label,

        s.job_satisfaction,
        s.job_satisfaction_label,

        s.relationship_satisfaction,
        s.relationship_satisfaction_label,

        s.work_life_balance,
        s.work_life_balance_label,

        s.job_involvement,
        s.job_involvement_label,

        s.overall_engagement_score,


        s.tenure_years,
        s.tenure_months,
        s.months_before_exit,
        s.months_since_last_promotion,


        s.distance_from_home,
        s.num_companies_worked,
        s.total_working_years,
        s.years_at_company,
        s.years_in_current_role,
        s.years_since_last_promotion,
        s.years_with_curr_manager,
        s.training_times_last_year,

        -- -------------------------------------------------------
        -- pipeline metadata
        -- -------------------------------------------------------
        s._source_file_name,
        s._load_timestamp,
        CURRENT_TIMESTAMP()                                                         AS _fact_created_at

    from source s

    -- employee — Left JOIN, scd2 implementation
    left join dim_employee e
    on  s.emp_id        = e.emp_id
    and s.snapshot_date >= e.valid_from
    and (e.valid_to is null or s.snapshot_date < e.valid_to)

    -- manager — LEFT JOIN, level 5 employees have no manager
    left join dim_manager m
        on s.manager_id         = m.manager_id

    -- job role — INNER JOIN, every employee has a valid role and level
    join dim_job_role j
        on s.job_role           = j.job_role
        and s.job_level         = j.job_level

    -- org — INNER JOIN, every employee has a valid department and travel
    join dim_org o
        on s.department         = o.department
        and s.business_travel   = o.business_travel

    -- location — INNER JOIN, every employee has a valid location
    join dim_location l
        on s.location           = l.location

)

select * from final