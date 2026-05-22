{{ config(materialized='table', schema='gold') }}

with source as (
    select * from {{ ref('silver_hr_cleaned') }}
),

-- latest snapshot per employee only
latest as (
    select *
    from source
    qualify row_number() over (
        partition by emp_id
        order by snapshot_date desc
    ) = 1
),

managers as (
    select distinct manager_id
    from source
    where manager_id is not null
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['l.emp_id']) }}    AS manager_sk,
        l.emp_id                                                AS manager_id,
        l.first_name                                            AS manager_first_name,
        l.last_name                                             AS manager_last_name,
        l.full_name                                             AS manager_full_name,
        l.email                                                 AS manager_email,
        l.department,
        l.job_role,
        l.job_level,
        l.job_level_label,
        l.employment_type,
        l.years_at_company,
        l.years_with_curr_manager,
        l.attrition_flag,
        l.exit_date,
        case
            when l.attrition_flag = false and l.exit_date is null
            then true else false
        end                                                     AS is_active_manager,
        current_timestamp()                                     AS dbt_loaded_at

    from managers mgr
    inner join latest l on mgr.manager_id = l.emp_id
)

select * from final