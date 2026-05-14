{{ config(
    materialized = 'table',
    schema       = 'gold'
) }}

with source as (

    select * from {{ ref('silver_hr_cleaned') }}

),

final as (

    select distinct

        {{ dbt_utils.generate_surrogate_key(['location']) }}    AS location_sk,

        location,
        state,
        region,
        department,
        cost_center

    from source

)

select * from final