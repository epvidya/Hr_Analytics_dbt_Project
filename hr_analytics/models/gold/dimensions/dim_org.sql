{{ config(
    materialized = 'table',
    schema       = 'gold'
) }}

with source as (

    select * from {{ ref('silver_hr_cleaned') }}

),

final as (

    select distinct

        {{ dbt_utils.generate_surrogate_key(['department', 'business_travel']) }}   AS org_sk,

        department,
        business_travel,
        travel_label,
        travel_description,
        cost_center

    from source

)

select * from final