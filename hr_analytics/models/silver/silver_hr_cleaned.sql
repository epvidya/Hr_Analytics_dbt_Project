{{ config(materialized='table') }}

with

-- ============================================================
-- source
-- ============================================================
bronze as (
    select *
    from {{ ref('bronze_hr_data_raw') }}
),

-- ============================================================
-- seed lookups
-- ============================================================
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
-- base — cast all columns, clean dirty values, derive new ones
-- ============================================================
base as (

    select

        -- identity
        UPPER(TRIM(emp_id))                                 AS emp_id,
        TRY_CAST(employee_number AS INT)                    AS employee_number,
        UPPER(TRIM(manager_id))                             AS manager_id,

        -- personal details
        INITCAP(TRIM(first_name))                           AS first_name,
        INITCAP(TRIM(last_name))                            AS last_name,
        LOWER(TRIM(email))                                  AS email,

        -- demographics
        TRY_CAST(age AS INT)                                AS age,
        TRIM(age_group)                                     AS age_group,
        INITCAP(TRIM(gender))                               AS gender,
        INITCAP(TRIM(marital_status))                       AS marital_status,

        -- education
        TRY_CAST(education AS INT)                          AS education_level,
        TRIM(education_field)                               AS education_field,

        -- organisation
        TRIM(department)                                    AS department,
        TRIM(job_role)                                      AS job_role,
        TRIM(job_title)                                     AS job_title,
        TRY_CAST(job_level AS INT)                          AS job_level,

        -- business_travel — CASE cleans known dirty values
        CASE
            WHEN UPPER(REPLACE(business_travel, '_', '')) = 'TRAVELRARELY'
                THEN 'Travel_Rarely'
            WHEN UPPER(REPLACE(business_travel, '_', '')) = 'TRAVELFREQUENTLY'
                THEN 'Travel_Frequently'
            WHEN UPPER(REPLACE(business_travel, '_', '')) = 'NONTRAVEL'
                THEN 'Non-Travel'
            ELSE TRIM(business_travel)
        END                                                 AS business_travel,

        TRIM(employment_type)                               AS employment_type,
        TRIM(location)                                      AS location,
        TRIM(cost_center)                                   AS cost_center,
        TRIM(recruitment_source)                            AS recruitment_source,

        -- dates — cast from VARCHAR DD-MM-YYYY to DATE
        TRY_TO_DATE(join_date,           'DD-MM-YYYY')      AS join_date,
        TRY_TO_DATE(last_promotion_date, 'DD-MM-YYYY')      AS last_promotion_date,
        TRY_TO_DATE(exit_date,           'DD-MM-YYYY')      AS exit_date,
        TRY_TO_DATE(snapshot_date,       'DD-MM-YYYY')      AS snapshot_date,

        -- derived date measures
        DATEDIFF('year',
            TRY_TO_DATE(join_date,     'DD-MM-YYYY'),
            TRY_TO_DATE(snapshot_date, 'DD-MM-YYYY'))       AS tenure_years,

        DATEDIFF('month',
            TRY_TO_DATE(join_date,     'DD-MM-YYYY'),
            TRY_TO_DATE(snapshot_date, 'DD-MM-YYYY'))       AS tenure_months,

        -- NULL for active employees
        DATEDIFF('month',
            TRY_TO_DATE(join_date, 'DD-MM-YYYY'),
            TRY_TO_DATE(exit_date, 'DD-MM-YYYY'))           AS months_before_exit,

        -- promotion cycle
        DATEDIFF('month',
            TRY_TO_DATE(last_promotion_date, 'DD-MM-YYYY'),
            TRY_TO_DATE(snapshot_date,       'DD-MM-YYYY')) AS months_since_last_promotion,

        -- flags — Yes/No to boolean
        CASE WHEN UPPER(TRIM(attrition)) = 'YES'
             THEN TRUE ELSE FALSE END                       AS attrition_flag,

        CASE WHEN UPPER(TRIM(overtime)) = 'YES'
             THEN TRUE ELSE FALSE END                       AS overtime_flag,

        -- termination reason — keep VARCHAR for LEFT JOIN below
        TRIM(termination_reason)                            AS termination_reason,

        -- compensation
        TRY_CAST(monthly_income      AS INT)                AS monthly_income,
        TRIM(salary_slab)                                   AS salary_slab,
        TRY_CAST(daily_rate          AS INT)                AS daily_rate,
        TRY_CAST(hourly_rate         AS INT)                AS hourly_rate,
        TRY_CAST(monthly_rate        AS INT)                AS monthly_rate,
        TRY_CAST(percent_salary_hike AS INT)                AS percent_salary_hike,
        TRY_CAST(stock_option_level  AS INT)                AS stock_option_level,

        -- performance and survey scores
        TRY_CAST(performance_rating        AS INT)          AS performance_rating,
        TRY_CAST(environment_satisfaction  AS INT)          AS environment_satisfaction,
        TRY_CAST(job_satisfaction          AS INT)          AS job_satisfaction,
        TRY_CAST(relationship_satisfaction AS INT)          AS relationship_satisfaction,
        TRY_CAST(work_life_balance         AS INT)          AS work_life_balance,
        TRY_CAST(job_involvement           AS INT)          AS job_involvement,

        -- tenure source measures
        TRY_CAST(distance_from_home          AS INT)        AS distance_from_home,
        TRY_CAST(num_companies_worked        AS INT)        AS num_companies_worked,
        TRY_CAST(total_working_years         AS INT)        AS total_working_years,
        TRY_CAST(years_at_company            AS INT)        AS years_at_company,
        TRY_CAST(years_in_current_role       AS INT)        AS years_in_current_role,
        TRY_CAST(years_since_last_promotion  AS INT)        AS years_since_last_promotion,
        TRY_CAST(years_with_curr_manager     AS INT)        AS years_with_curr_manager,
        TRY_CAST(training_times_last_year    AS INT)        AS training_times_last_year,

        -- pipeline metadata
        -- employee_count, over_18, standard_hours dropped here
        _source_file_name,
        _load_timestamp

    from bronze

    -- null checks — reject rows that break downstream
    where UPPER(TRIM(emp_id))                               is not null
      and TRY_TO_DATE(join_date,     'DD-MM-YYYY')          is not null
      and TRY_TO_DATE(snapshot_date, 'DD-MM-YYYY')          is not null
      and TRY_CAST(age AS INT)                              is not null
      and TRY_CAST(monthly_income AS INT)                   is not null
      and TRY_CAST(monthly_income AS INT)                   > 0
      and TRY_CAST(job_level AS INT)                        is not null
      and TRIM(department)                                  is not null
      and TRIM(job_role)                                    is not null

),

-- ============================================================
-- final — seed joins to validate and enrich
-- INNER JOIN = required, invalid rows excluded → quarantine
-- LEFT JOIN  = optional, NULLs allowed (active employees)
-- ============================================================
final as (

    select

        -- identity
        b.emp_id,
        b.employee_number,
        b.manager_id,

        -- personal details
        b.first_name,
        b.last_name,
        b.email,
        b.first_name || ' ' || b.last_name                 AS full_name,

        -- demographics
        b.age,
        b.age_group,
        b.gender,
        b.marital_status,

        -- education — code + decoded label + description from seed
        b.education_level,
        el.education_label,
        el.education_description,
        b.education_field,

        -- organisation
        b.department,
        b.job_role,
        b.job_title,
        b.job_level,
        jl.job_level_label,
        b.job_role || ' L' || b.job_level                  AS job_role_level,

        -- business travel — cleaned value + label + description from seed
        b.business_travel,
        bt.travel_label,
        bt.travel_description,

        -- employment type — type + code + fte flag from seed
        b.employment_type,
        et.employment_type_code,
        et.is_full_time,

        -- location — city + state + region from seed
        b.location,
        lc.state,
        lc.region,
        b.cost_center,

        -- recruitment source — source + category + cost from seed
        b.recruitment_source,
        rs.source_category                                  AS recruitment_category,
        rs.source_cost                                      AS recruitment_cost,

        -- dates
        b.join_date,
        b.last_promotion_date,
        b.exit_date,
        b.snapshot_date,
        b.tenure_years,
        b.tenure_months,
        b.months_before_exit,
        b.months_since_last_promotion,

        -- flags
        b.attrition_flag,
        b.overtime_flag,

        -- termination — LEFT JOIN so active employees pass through with NULLs
      
        b.termination_reason,
        COALESCE(tr.reason_category, 'Active')          AS termination_category,
        COALESCE(tr.is_voluntary, FALSE)                AS is_voluntary,

        -- compensation — measures + slab range from seed
        b.monthly_income,
        b.salary_slab,
        ss.salary_slab_min,
        ss.salary_slab_max,
        b.daily_rate,
        b.hourly_rate,
        b.monthly_rate,
        b.percent_salary_hike,
        b.stock_option_level,
        so.stock_option_label,
        so.stock_option_description,

        -- survey scores — numeric + label from seed
        b.performance_rating,
        pr.rating_label                                     AS performance_rating_label,

        b.environment_satisfaction,
        es.rating_label                                     AS environment_satisfaction_label,

        b.job_satisfaction,
        js.rating_label                                     AS job_satisfaction_label,

        b.relationship_satisfaction,
        rs2.rating_label                                    AS relationship_satisfaction_label,

        b.work_life_balance,
        wl.rating_label                                     AS work_life_balance_label,

        b.job_involvement,
        ji.rating_label                                     AS job_involvement_label,

        -- overall engagement score — average of all 5 survey measures
        ROUND(
            (b.job_satisfaction         +
             b.environment_satisfaction +
             b.relationship_satisfaction +
             b.work_life_balance        +
             b.job_involvement) / 5.0
        , 2)                                                AS overall_engagement_score,

        -- tenure source measures
        b.distance_from_home,
        b.num_companies_worked,
        b.total_working_years,
        b.years_at_company,
        b.years_in_current_role,
        b.years_since_last_promotion,
        b.years_with_curr_manager,
        b.training_times_last_year,

        -- pipeline metadata
        b._source_file_name,
        b._load_timestamp,
        CURRENT_TIMESTAMP()                                 AS _silver_created_at

    from base b

    -- education level — INNER JOIN
    inner join education_levels el
        on b.education_level    = el.education_level

    -- job level — INNER JOIN
    inner join job_levels jl
        on b.job_level          = jl.job_level

    -- business travel — INNER JOIN
    -- CASE statement already cleaned dirty values in base
    inner join business_travel bt
        on b.business_travel    = bt.business_travel

    -- employment type — INNER JOIN
    inner join employment_types et
        on b.employment_type    = et.employment_type

    -- salary slab — INNER JOIN
    inner join salary_slabs ss
        on b.salary_slab        = ss.salary_slab

    -- stock option level — INNER JOIN
    inner join stock_options so
        on b.stock_option_level = so.stock_option_level

    -- location — INNER JOIN
    inner join locations lc
        on b.location           = lc.location

    -- recruitment source — INNER JOIN
    inner join recruitment_sources rs
        on b.recruitment_source = rs.recruitment_source

    -- termination reason — LEFT JOIN
    -- active employees have NULL termination_reason
    -- LEFT JOIN lets them pass through with NULL labels
    left join termination_reasons tr
        on b.termination_reason = tr.termination_reason

    -- rating scale joined 6 times with different aliases
    inner join rating_scale pr
        on b.performance_rating         = pr.rating_value

    inner join rating_scale es
        on b.environment_satisfaction   = es.rating_value

    inner join rating_scale js
        on b.job_satisfaction           = js.rating_value

    inner join rating_scale rs2
        on b.relationship_satisfaction  = rs2.rating_value

    inner join rating_scale wl
        on b.work_life_balance          = wl.rating_value

    inner join rating_scale ji
        on b.job_involvement            = ji.rating_value

)

select * from final