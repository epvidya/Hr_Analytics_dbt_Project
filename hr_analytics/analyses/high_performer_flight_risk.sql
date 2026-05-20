-- analyses/high_performer_flight_risk.sql
-- Business question: Which high performing employees show multiple warning signs?
-- Red flags: low satisfaction + no recent promotion + poor work life balance
--            + long tenure with no growth + overtime burden
-- Use: Priority intervention list for HR business partners

with joined as (

    select
        e.emp_id,
        e.full_name,
        o.department,
        j.job_role,
        j.job_level,
        j.job_level_label,
        f.performance_rating,
        f.performance_rating_label,
        f.job_satisfaction,
        f.work_life_balance,
        f.work_life_balance_label,
        f.overall_engagement_score,
        f.overtime_flag,
        f.tenure_years,
        f.years_since_last_promotion,
        f.months_since_last_promotion,
        f.years_with_curr_manager,
        f.attrition_flag,
        d.snapshot_date_sk,
        d.month_year,
        d.calendar_year,
        d.month_number,
        d.month_name

    from gold.fact_employee_snapshot f
    join gold.dim_employee e
        on f.employee_sk        = e.employee_sk
    join gold.dim_org o
        on f.org_sk             = o.org_sk
    join gold.dim_job_role j
        on f.job_role_sk        = j.job_role_sk
    join gold.dim_date d
        on f.snapshot_date_sk   = d.date_sk

    where f.performance_rating  = 4
      and f.attrition_flag      = false

),

flags as (

    select
        emp_id,
        full_name,
        department,
        job_role,
        job_level,
        job_level_label,
        snapshot_date_sk,
        month_year,
        calendar_year,
        month_number,
        month_name,
        performance_rating,
        performance_rating_label,
        job_satisfaction,
        work_life_balance,
        work_life_balance_label,
        overall_engagement_score,
        overtime_flag,
        tenure_years,
        years_since_last_promotion,
        months_since_last_promotion,
        years_with_curr_manager,

        case when job_satisfaction <= 2                     then 3 else 0 end   as score_low_satisfaction,
        case when work_life_balance <= 2                    then 2 else 0 end   as score_poor_wlb,
        case when years_since_last_promotion >= 3           then 2 else 0 end   as score_no_promotion,
        case when overtime_flag = true                      then 1 else 0 end   as score_overtime,
        case when tenure_years >= 5
             and years_since_last_promotion >= 3            then 2 else 0 end   as score_long_tenure,
        case when overall_engagement_score <= 2             then 2 else 0 end   as score_low_engagement

    from joined

),

scored as (

    select
        emp_id,
        full_name,
        department,
        job_role,
        job_level,
        job_level_label,
        snapshot_date_sk,
        month_year,
        calendar_year,
        month_number,
        month_name,
        performance_rating,
        performance_rating_label,
        job_satisfaction,
        work_life_balance,
        work_life_balance_label,
        overall_engagement_score,
        overtime_flag,
        tenure_years,
        years_since_last_promotion,
        months_since_last_promotion,
        years_with_curr_manager,
        score_low_satisfaction,
        score_poor_wlb,
        score_no_promotion,
        score_overtime,
        score_long_tenure,
        score_low_engagement,

        score_low_satisfaction +
        score_poor_wlb +
        score_no_promotion +
        score_overtime +
        score_long_tenure +
        score_low_engagement                                as flight_risk_score

    from flags

),

labeled as (

    select
        emp_id,
        full_name,
        department,
        job_role,
        job_level,
        job_level_label,
        snapshot_date_sk,
        month_year,
        calendar_year,
        month_number,
        month_name,
        performance_rating_label,
        job_satisfaction,
        work_life_balance_label,
        overall_engagement_score,
        overtime_flag,
        tenure_years,
        years_since_last_promotion,
        years_with_curr_manager,

        -- individual flag scores kept for Tableau explainability
        score_low_satisfaction,
        score_poor_wlb,
        score_no_promotion,
        score_overtime,
        score_long_tenure,
        score_low_engagement,
        flight_risk_score,

        case
            when flight_risk_score >= 7     then 'Critical'
            when flight_risk_score >= 4     then 'High'
            when flight_risk_score >= 2     then 'Medium'
            else                                 'Low'
        end                                                 as flight_risk_label

    from scored

)

select *
from labeled
order by
    calendar_year,
    month_number,
    flight_risk_score desc,
    overall_engagement_score asc;