{{ config(materialized='table', schema='gold') }}

select

    employee_sk,
    emp_id,
    employee_number,
    first_name,
    last_name,
    full_name,
    email,
    age,
    age_group,
    gender,
    marital_status,
    education_level,
    education_label,
    education_description,
    education_field,
    job_title,
    employment_type,
    employment_type_code,
    is_full_time,
    attrition_flag,
    exit_date,
    is_active_employee,
    termination_reason,
    termination_category,
    is_voluntary,
    recruitment_source,
    recruitment_category,
    recruitment_cost,
    join_date,
    join_date_sk,

    -- expose dbt snapshot SCD2 cols with your preferred names
    dbt_valid_from                                          AS valid_from,
    dbt_valid_to                                            AS valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current,

    dw_created_at

from {{ ref('scd_employee') }}