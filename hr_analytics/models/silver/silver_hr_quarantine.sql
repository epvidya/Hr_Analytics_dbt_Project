{{ config(materialized='table') }}

-- ============================================================
-- SILVER QUARANTINE — silver_hr_quarantine
-- Captures rows rejected from hr_cleaned with failure reason
-- Two types of failures captured:
--   1. NULL checks — critical columns missing
--   2. Seed validation — values not in allowed lists
-- One row per rejected employee
-- Ops team reviews this table to investigate and fix source data
-- ============================================================

with
bronze as (
    select *
    from {{ ref('bronze_hr_data_raw') }}
),

education_levels as (
    select * from {{ ref('seed_education_level') }}
),

rating_scale as (
    select * from {{ ref('seed_rating_scale') }}
),

job_levels as (
    select * from {{ ref('seed_job_level') }}
),

salary_slabs as (
    select * from {{ ref('seed_salary_slab') }}
),

stock_options as (
    select * from {{ ref('seed_stock_option_level') }}
),

business_travel as (
    select * from {{ ref('seed_business_travel') }}
),

employment_types as (
    select * from {{ ref('seed_employment_type') }}
),

recruitment_sources as (
    select * from {{ ref('seed_recruitment_source') }}
),

termination_reasons as (
    select * from {{ ref('seed_termination_reason') }}
),

locations as (
    select * from {{ ref('seed_location') }}
),

-- ============================================================
-- base — apply same cleaning as hr_cleaned
-- raw values kept separately for error messages
-- ============================================================
base as (

    select
        -- cleaned values for seed joins
        UPPER(TRIM(emp_id))                                 AS emp_id,
        TRY_CAST(employee_number AS INT)                    AS employee_number,
        UPPER(TRIM(manager_id))                             AS manager_id,
        INITCAP(TRIM(first_name))                           AS first_name,
        INITCAP(TRIM(last_name))                            AS last_name,
        LOWER(TRIM(email))                                  AS email,
        TRY_CAST(age AS INT)                                AS age,
        TRIM(age_group)                                     AS age_group,
        INITCAP(TRIM(gender))                               AS gender,
        INITCAP(TRIM(marital_status))                       AS marital_status,
        TRY_CAST(education AS INT)                          AS education_level,
        TRIM(education_field)                               AS education_field,
        TRIM(department)                                    AS department,
        TRIM(job_role)                                      AS job_role,
        TRIM(job_title)                                     AS job_title,
        TRY_CAST(job_level AS INT)                          AS job_level,

        CASE
            WHEN UPPER(REPLACE(business_travel, '_', '')) = 'TRAVELRARELY'
                THEN 'Travel_Rarely'
            WHEN UPPER(REPLACE(business_travel, '_', '')) = 'TRAVELFREQUENTLY'
                THEN 'Travel_Frequently'
            WHEN UPPER(REPLACE(business_travel, '_', '')) = 'NONTRAVEL'
                THEN 'Non-Travel'
            ELSE TRIM(business_travel)
        END                                                 AS business_travel,

        business_travel                                     AS business_travel_raw,
        TRIM(employment_type)                               AS employment_type,
        TRIM(location)                                      AS location,
        TRIM(cost_center)                                   AS cost_center,
        TRIM(recruitment_source)                            AS recruitment_source,
        TRY_TO_DATE(join_date,           'DD-MM-YYYY')      AS join_date,
        TRY_TO_DATE(last_promotion_date, 'DD-MM-YYYY')      AS last_promotion_date,
        TRY_TO_DATE(exit_date,           'DD-MM-YYYY')      AS exit_date,
        TRY_TO_DATE(snapshot_date,       'DD-MM-YYYY')      AS snapshot_date,

        CASE WHEN UPPER(TRIM(attrition)) = 'YES'
             THEN TRUE ELSE FALSE END                       AS attrition_flag,
        CASE WHEN UPPER(TRIM(overtime))  = 'YES'
             THEN TRUE ELSE FALSE END                       AS overtime_flag,

        TRIM(termination_reason)                            AS termination_reason,
        TRY_CAST(monthly_income      AS INT)                AS monthly_income,
        TRIM(salary_slab)                                   AS salary_slab,
        TRY_CAST(daily_rate          AS INT)                AS daily_rate,
        TRY_CAST(hourly_rate         AS INT)                AS hourly_rate,
        TRY_CAST(monthly_rate        AS INT)                AS monthly_rate,
        TRY_CAST(percent_salary_hike AS INT)                AS percent_salary_hike,
        TRY_CAST(stock_option_level  AS INT)                AS stock_option_level,
        TRY_CAST(performance_rating        AS INT)          AS performance_rating,
        TRY_CAST(environment_satisfaction  AS INT)          AS environment_satisfaction,
        TRY_CAST(job_satisfaction          AS INT)          AS job_satisfaction,
        TRY_CAST(relationship_satisfaction AS INT)          AS relationship_satisfaction,
        TRY_CAST(work_life_balance         AS INT)          AS work_life_balance,
        TRY_CAST(job_involvement           AS INT)          AS job_involvement,
        TRY_CAST(distance_from_home          AS INT)        AS distance_from_home,
        TRY_CAST(num_companies_worked        AS INT)        AS num_companies_worked,
        TRY_CAST(total_working_years         AS INT)        AS total_working_years,
        TRY_CAST(years_at_company            AS INT)        AS years_at_company,
        TRY_CAST(years_in_current_role       AS INT)        AS years_in_current_role,
        TRY_CAST(years_since_last_promotion  AS INT)        AS years_since_last_promotion,
        TRY_CAST(years_with_curr_manager     AS INT)        AS years_with_curr_manager,
        TRY_CAST(training_times_last_year    AS INT)        AS training_times_last_year,

        -- raw values for meaningful error messages
        emp_id                                              AS raw_emp_id,
        age                                                 AS raw_age,
        education                                           AS raw_education,
        job_level                                           AS raw_job_level,
        monthly_income                                      AS raw_monthly_income,
        join_date                                           AS raw_join_date,
        snapshot_date                                       AS raw_snapshot_date,
        employment_type                                     AS raw_employment_type,
        recruitment_source                                  AS raw_recruitment_source,
        termination_reason                                  AS raw_termination_reason,
        salary_slab                                         AS raw_salary_slab,
        stock_option_level                                  AS raw_stock_option_level,
        performance_rating                                  AS raw_performance_rating,
        environment_satisfaction                            AS raw_environment_satisfaction,
        job_satisfaction                                    AS raw_job_satisfaction,
        relationship_satisfaction                           AS raw_relationship_satisfaction,
        work_life_balance                                   AS raw_work_life_balance,
        job_involvement                                     AS raw_job_involvement,
        location                                            AS raw_location,

        _source_file_name,
        _load_timestamp

    from bronze

),

-- ============================================================
-- tagged — LEFT JOIN all seeds
-- NULL on right side of LEFT JOIN = validation failure
-- Build failure_reason string capturing all failures
-- ============================================================
tagged as (

    select
        b.*,

    ARRAY_TO_STRING(
    ARRAY_CONSTRUCT_COMPACT(

                CASE WHEN b.emp_id IS NULL
                     THEN 'emp_id is null'
                END,

                CASE WHEN b.join_date IS NULL
                     THEN 'join_date is null or unparseable - raw value: '
                          || COALESCE(b.raw_join_date, 'NULL')
                END,

                CASE WHEN b.snapshot_date IS NULL
                     THEN 'snapshot_date is null or unparseable - raw value: '
                          || COALESCE(b.raw_snapshot_date, 'NULL')
                END,

                CASE WHEN b.age IS NULL
                     THEN 'age is null or not numeric - raw value: '
                          || COALESCE(b.raw_age, 'NULL')
                END,

                CASE WHEN b.monthly_income IS NULL
                     THEN 'monthly_income is null or not numeric - raw value: '
                          || COALESCE(b.raw_monthly_income, 'NULL')
                END,

                CASE WHEN b.monthly_income IS NOT NULL
                      AND b.monthly_income <= 0
                     THEN 'monthly_income is zero or negative - value: '
                          || COALESCE(b.raw_monthly_income, 'NULL')
                END,

                CASE WHEN b.job_level IS NULL
                     THEN 'job_level is null or not numeric - raw value: '
                          || COALESCE(b.raw_job_level, 'NULL')
                END,

                CASE WHEN b.department IS NULL
                     THEN 'department is null'
                END,

                CASE WHEN b.job_role IS NULL
                     THEN 'job_role is null'
                END,

               
                CASE WHEN el.education_level IS NULL
                     THEN 'education_level not in allowed values - raw value: '
                          || COALESCE(b.raw_education, 'NULL')
                END,

                CASE WHEN jl.job_level IS NULL
                     THEN 'job_level not in seed_job_level - raw value: '
                          || COALESCE(b.raw_job_level, 'NULL')
                END,

                CASE WHEN bt.business_travel IS NULL
                     THEN 'business_travel not in allowed values - raw value: '
                          || COALESCE(b.business_travel_raw, 'NULL')
                END,

                CASE WHEN et.employment_type IS NULL
                     THEN 'employment_type not in allowed values - raw value: '
                          || COALESCE(b.raw_employment_type, 'NULL')
                END,

                CASE WHEN ss.salary_slab IS NULL
                     THEN 'salary_slab not in allowed values - raw value: '
                          || COALESCE(b.raw_salary_slab, 'NULL')
                END,

                CASE WHEN so.stock_option_level IS NULL
                     THEN 'stock_option_level not in allowed values - raw value: '
                          || COALESCE(b.raw_stock_option_level, 'NULL')
                END,

                CASE WHEN lc.location IS NULL
                     THEN 'location not in allowed values - raw value: '
                          || COALESCE(b.raw_location, 'NULL')
                END,

                CASE WHEN rs.recruitment_source IS NULL
                     THEN 'recruitment_source not in allowed values - raw value: '
                          || COALESCE(b.raw_recruitment_source, 'NULL')
                END,

                CASE WHEN pr.rating_value IS NULL
                     THEN 'performance_rating not in allowed values - raw value: '
                          || COALESCE(b.raw_performance_rating, 'NULL')
                END,

                CASE WHEN es.rating_value IS NULL
                     THEN 'environment_satisfaction not in allowed values - raw value: '
                          || COALESCE(b.raw_environment_satisfaction, 'NULL')
                END,

                CASE WHEN js.rating_value IS NULL
                     THEN 'job_satisfaction not in allowed values - raw value: '
                          || COALESCE(b.raw_job_satisfaction, 'NULL')
                END,

                CASE WHEN rs2.rating_value IS NULL
                     THEN 'relationship_satisfaction not in allowed values - raw value: '
                          || COALESCE(b.raw_relationship_satisfaction, 'NULL')
                END,

                CASE WHEN wl.rating_value IS NULL
                     THEN 'work_life_balance not in allowed values - raw value: '
                          || COALESCE(b.raw_work_life_balance, 'NULL')
                END,

                CASE WHEN ji.rating_value IS NULL
                     THEN 'job_involvement not in allowed values - raw value: '
                          || COALESCE(b.raw_job_involvement, 'NULL')
                END,

             
                CASE WHEN b.attrition_flag = TRUE
                      AND b.termination_reason IS NOT NULL
                      AND tr.termination_reason IS NULL
                     THEN 'termination_reason not in allowed values - raw value: '
                          || COALESCE(b.raw_termination_reason, 'NULL')
                END

            ),'|'
        )                                                   AS failure_reason

    from base b

    -- ALL LEFT JOINs — NULL on right = validation failed
    left join education_levels el
        on b.education_level            = el.education_level

    left join job_levels jl
        on b.job_level                  = jl.job_level

    left join business_travel bt
        on b.business_travel            = bt.business_travel

    left join employment_types et
        on b.employment_type            = et.employment_type

    left join salary_slabs ss
        on b.salary_slab                = ss.salary_slab

    left join stock_options so
        on b.stock_option_level         = so.stock_option_level

    left join locations lc
        on b.location                   = lc.location

    left join recruitment_sources rs
        on b.recruitment_source         = rs.recruitment_source

    left join termination_reasons tr
        on b.termination_reason         = tr.termination_reason

    left join rating_scale pr
        on b.performance_rating         = pr.rating_value

    left join rating_scale es
        on b.environment_satisfaction   = es.rating_value

    left join rating_scale js
        on b.job_satisfaction           = js.rating_value

    left join rating_scale rs2
        on b.relationship_satisfaction  = rs2.rating_value

    left join rating_scale wl
        on b.work_life_balance          = wl.rating_value

    left join rating_scale ji
        on b.job_involvement            = ji.rating_value

),

-- ============================================================
-- final — only rows that failed at least one condition
-- ============================================================
final as (

    select
        emp_id,
        employee_number,
        manager_id,
        first_name,
        last_name,
        email,
        age,
        age_group,
        gender,
        marital_status,
        education_level,
        education_field,
        department,
        job_role,
        job_title,
        job_level,
        business_travel,
        employment_type,
        location,
        cost_center,
        recruitment_source,
        join_date,
        last_promotion_date,
        exit_date,
        snapshot_date,
        attrition_flag,
        overtime_flag,
        termination_reason,
        monthly_income,
        salary_slab,
        daily_rate,
        hourly_rate,
        monthly_rate,
        percent_salary_hike,
        stock_option_level,
        performance_rating,
        environment_satisfaction,
        job_satisfaction,
        relationship_satisfaction,
        work_life_balance,
        job_involvement,
        distance_from_home,
        num_companies_worked,
        total_working_years,
        years_at_company,
        years_in_current_role,
        years_since_last_promotion,
        years_with_curr_manager,
        training_times_last_year,

        -- quarantine metadata
        failure_reason,
        _source_file_name,
        _load_timestamp,
        CURRENT_TIMESTAMP()                                 AS _quarantine_created_at

    from tagged

    -- only rows with at least one failure
    where failure_reason is not null
      and failure_reason != ''

)

select * from final