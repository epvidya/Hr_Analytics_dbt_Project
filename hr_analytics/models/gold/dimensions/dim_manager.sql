{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with source as (

    select * from {{ ref('silver_hr_cleaned') }}

),

managers as (

    select distinct manager_id
    from source
    where manager_id is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['emp_id']) }}    as manager_sk,
        m.emp_id                                                as manager_id,
        m.first_name                                            as manager_first_name,
        m.last_name                                             as manager_last_name,
        m.full_name                                             as manager_full_name,
        m.email                                                 as manager_email,
        m.department,
        m.job_role,
        m.job_level,
        m.job_level_label,
        m.employment_type,
        m.years_at_company,
        m.years_with_curr_manager,
        m.attrition_flag,
        m.exit_date,
        case
            when m.attrition_flag = false and m.exit_date is null
            then true
            else false
        end                                                     as is_active_manager,
        current_timestamp()                                     as dbt_loaded_at

    from managers mgr
    inner join source m on mgr.manager_id = m.emp_id

)

select * from final