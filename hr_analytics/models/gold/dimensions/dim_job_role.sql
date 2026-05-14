{{ config(
    materialized = 'table',
    schema       = 'gold'
) }}

with source as (

    select * from {{ ref('silver_hr_cleaned') }}

),

final as (

    select distinct

        {{ dbt_utils.generate_surrogate_key(['job_role', 'job_level']) }}  AS job_role_sk,

        job_role,
        job_level,
        job_level_label,
        job_role_level

    from source

)

select * from final