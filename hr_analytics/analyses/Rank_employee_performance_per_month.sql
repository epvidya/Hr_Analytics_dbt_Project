with joined as (

    select
        f.employee_sk,
        e.emp_id,
        e.full_name,
        o.department,
        f.performance_rating,
        f.performance_rating_label,
        f.snapshot_date_sk,
        d.calendar_year,
        d.month_number,
        d.month_name

    from gold.fact_employee_snapshot f
    join gold.dim_employee e
        on f.employee_sk        = e.employee_sk
    join gold.dim_org o
        on f.org_sk             = o.org_sk
    join gold.dim_date d
        on f.snapshot_date_sk   = d.date_sk

),

ranked as (

    select
        emp_id,
        full_name,
        department,
        calendar_year,
        month_number,
        month_name,
        performance_rating,
        performance_rating_label,
        dense_rank() OVER (
            PARTITION BY calendar_year, month_number
            ORDER BY performance_rating DESC
        )                                   AS performance_rank

    from joined

)

select *
from ranked
where performance_rank = 1
order by
    calendar_year,
    month_number;