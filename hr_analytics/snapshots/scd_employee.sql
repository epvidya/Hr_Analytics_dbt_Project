{% snapshot scd_employee %}

{{
    config(
        target_schema = 'gold',
        target_table  = 'dim_employee',
        unique_key    = 'emp_id',
        strategy      = 'check',
        check_cols    = [
            'first_name', 'last_name', 'email',
            'job_title', 'employment_type', 'is_full_time',
            'attrition_flag', 'exit_date',
            'termination_reason', 'termination_category', 'is_voluntary',
            'recruitment_source', 'recruitment_category', 'recruitment_cost',
            'education_level', 'education_label', 'education_field',
            'age', 'age_group', 'gender', 'marital_status'
        ]
    )
}}

select

    {{ dbt_utils.generate_surrogate_key(['emp_id']) }}      AS employee_sk,

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
    case
        when attrition_flag = false and exit_date is null
        then true else false
    end                                                     AS is_active_employee,
    termination_reason,
    termination_category,
    is_voluntary,
    recruitment_source,
    recruitment_category,
    recruitment_cost,
    join_date,
    CAST(TO_CHAR(join_date, 'YYYYMMDD') AS INT)             AS join_date_sk,
    CURRENT_TIMESTAMP()                                     AS dw_created_at

from {{ ref('silver_hr_cleaned') }}

-- snapshot must see only the LATEST snapshot per employee
-- otherwise dbt sees 3 rows and treats them all as "current"
qualify row_number() over (
    partition by emp_id
    order by snapshot_date desc
) = 1

{% endsnapshot %}