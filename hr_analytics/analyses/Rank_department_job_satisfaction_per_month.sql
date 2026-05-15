--Which department has the most engaged employees and when were they most satisfied?
with joined as (

    select
        f.employee_sk,
        f.job_satisfaction,
        f.snapshot_date_sk,
        o.department,
        d.calendar_year,
        d.month_number,
        d.month_name

    from gold.fact_employee_snapshot f
    join gold.dim_org o
        on f.org_sk             = o.org_sk
    join gold.dim_date d
        on f.snapshot_date_sk   = d.date_sk

),

-- CTE 2 — aggregate per department per month
aggregated as (

    select
        department,
        calendar_year,
        month_number,
        month_name,
        ROUND(AVG(job_satisfaction), 2)     AS avg_job_satisfaction,
        MIN(job_satisfaction)               AS min_job_satisfaction,
        MAX(job_satisfaction)               AS max_job_satisfaction,
        COUNT(employee_sk)                  AS headcount

    from joined
    group by
        department,
        calendar_year,
        month_number,
        month_name

),

-- CTE 3 — rank within each department
ranked as (

    select
        department,
        calendar_year,
        month_number,
        month_name,
        avg_job_satisfaction,
        min_job_satisfaction,
        max_job_satisfaction,
        headcount,

        RANK() OVER (
            PARTITION BY department
            ORDER BY avg_job_satisfaction DESC
        )                                   AS satisfaction_rank

    from aggregated

)

select * from ranked
order by
    department,
    satisfaction_rank;