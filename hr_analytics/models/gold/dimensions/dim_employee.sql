{{ config(
    materialized = 'table',
    schema       = 'gold'
) }}

with source as (

    select * from {{ ref('silver_hr_cleaned') }}

),

final as (

    select

        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['emp_id']) }}  AS employee_sk,

        -- natural key
        emp_id,
        employee_number,

        -- personal details
        first_name,
        last_name,
        full_name,
        email,

        -- demographics
        age,
        age_group,
        gender,
        marital_status,

        -- education
        education_level,
        education_label,
        education_description,
        education_field,

        -- job details — what the person does
        job_title,

        -- employment
        employment_type,
        employment_type_code,
        is_full_time,

        -- attrition and exit status
        attrition_flag,
        exit_date,

        case
            when attrition_flag = false and exit_date is null
            then true
            else false
        end                                        as is_active_employee,

        -- termination context (only populated if they left)
        termination_reason,
        termination_category,
        is_voluntary,

        -- recruitment
        recruitment_source,
        recruitment_category,
        recruitment_cost,

        -- join date and its date_sk for joining dim_date
        join_date,
        CAST(TO_CHAR(join_date, 'YYYYMMDD') AS INT)         AS join_date_sk,

        -- SCD2 columns
        -- valid_from and valid_to track when this version of the record is active
        -- valid_to NULL means currently active record
        -- is_current TRUE means this is the latest version
        CURRENT_DATE()                                       AS valid_from,
        NULL::DATE                                           AS valid_to,
        TRUE                                                 AS is_current,

        -- pipeline metadata
        CURRENT_TIMESTAMP()                                  AS dw_created_at

    from source

)

select * from final