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
        d.calendar_year,
        d.month_name

    from gold.fact_employee_snapshot f
    join gold.dim_employee e
        on f.employee_sk        = e.employee_sk
    join gold.dim_org o
        on f.org_sk             = o.org_sk
    join gold.dim_date d
        on f.snapshot_date_sk   = d.date_sk

    where performance_rating    = 4
      and attrition_flag        = false

),

-- calculate each flag once as individual columns
flags as (

    select
        emp_id,
        full_name,
        department,
        calendar_year,
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

        -- individual flag scores — calculated once
        case when job_satisfaction <= 2                         then 3 else 0 end   as score_low_satisfaction,
        case when work_life_balance <= 2                        then 2 else 0 end   as score_poor_wlb,
        case when years_since_last_promotion >= 3               then 2 else 0 end   as score_no_promotion,
        case when overtime_flag = true                          then 1 else 0 end   as score_overtime,
        case when tenure_years >= 5
             and years_since_last_promotion >= 3                then 2 else 0 end   as score_long_tenure,
        case when overall_engagement_score <= 2                 then 2 else 0 end   as score_low_engagement

    from joined

),

-- sum the flags into a total score — reference column names not repeat CASE
scored as (

    select
        emp_id,
        full_name,
        department,
        calendar_year,
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

        -- individual flags visible for explainability
        score_low_satisfaction,
        score_poor_wlb,
        score_no_promotion,
        score_overtime,
        score_long_tenure,
        score_low_engagement,

        -- total score — simple addition, no repeated CASE
        score_low_satisfaction +
        score_poor_wlb +
        score_no_promotion +
        score_overtime +
        score_long_tenure +
        score_low_engagement                                    as flight_risk_score

    from flags

),

-- apply risk label — reference flight_risk_score column not repeat calculation
labeled as (

    select
        emp_id,
        full_name,
        department,
        calendar_year,
        month_name,
        performance_rating_label,
        job_satisfaction,
        work_life_balance_label,
        overall_engagement_score,
        overtime_flag,
        tenure_years,
        years_since_last_promotion,
        flight_risk_score,

        -- single CASE referencing pre-calculated score
        case
            when flight_risk_score >= 7     then 'Critical'
            when flight_risk_score >= 4     then 'High'
            when flight_risk_score >= 2     then 'Medium'
            else                                 'Low'
        end                                                     as flight_risk_label

    from scored

)

select *
from labeled
order by
    flight_risk_score desc,
    overall_engagement_score asc;