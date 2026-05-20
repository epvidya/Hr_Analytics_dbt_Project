--analysis: employee_satisfaction_trend
-- This analysis tracks employee job satisfaction and overall engagement scores over time, 
-- calculating month-over-month changes and trends for each employee.
    select
        e.emp_id,
        e.full_name,
        o.department,
        d.calendar_year,
        d.month_number,
        d.month_name,
        d.month_short,
        f.job_satisfaction,
        f.environment_satisfaction,
        f.work_life_balance,
        f.job_involvement,
        f.relationship_satisfaction,
        f.overall_engagement_score,
        f.snapshot_date_sk

    from {{ ref('fact_employee_snapshot') }} f
    join {{ ref('dim_employee') }} e
        on f.employee_sk        = e.employee_sk
    join {{ ref('dim_org') }} o
        on f.org_sk             = o.org_sk
    join {{ ref('dim_date') }} d
        on f.snapshot_date_sk   = d.date_sk

),

-- calculate LAG values once here
lagged as (

    select
        emp_id,
        full_name,
        department,
        calendar_year,
        month_number,
        month_name,
        month_short,
        job_satisfaction,
        environment_satisfaction,
        work_life_balance,
        overall_engagement_score,

        -- calculate LAG once per column
        LAG(job_satisfaction) OVER (
            PARTITION BY emp_id
            ORDER BY snapshot_date_sk
        )                                               AS prev_job_satisfaction,

        LAG(overall_engagement_score) OVER (
            PARTITION BY emp_id
            ORDER BY snapshot_date_sk
        )                                               AS prev_engagement_score

    from monthly_scores

),

-- now reference prev values — no repeated LAG calls
trend as (

    select
        emp_id,
        full_name,
        department,
        calendar_year,
        month_number,
        month_name,
        month_short,

        -- current month scores
        job_satisfaction,
        environment_satisfaction,
        work_life_balance,
        overall_engagement_score,

        -- previous month scores
        prev_job_satisfaction,
        prev_engagement_score,

        -- month over month change — simple subtraction, no LAG repeat
        job_satisfaction - prev_job_satisfaction        AS job_satisfaction_change,
        overall_engagement_score - prev_engagement_score AS engagement_change,

        -- trend direction — simple comparison, no LAG repeat
        CASE
            WHEN job_satisfaction > prev_job_satisfaction THEN 'Improved'
            WHEN job_satisfaction < prev_job_satisfaction THEN 'Declined'
            ELSE 'No Change'
        END                                             AS satisfaction_trend

    from lagged

)

select * from trend
order by emp_id, month_number