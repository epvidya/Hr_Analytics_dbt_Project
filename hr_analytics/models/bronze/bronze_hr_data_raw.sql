with base as (

    select
        emp_id,
        age,
        age_group,
        gender,
        marital_status,
        education,
        education_field,
        department,
        job_role,
        job_level,
        business_travel,
        join_date,
        exit_date,
        snapshot_date,
        attrition,
        overtime,
        monthly_income,
        salary_slab,
        daily_rate,
        hourly_rate,
        monthly_rate,
        percent_salary_hike,
        stock_option_level,
        performance_rating,
        environment_satisfaction,
        job_satisfaction,
        relationship_satisfaction,
        work_life_balance,
        job_involvement,
        distance_from_home,
        num_companies_worked,
        total_working_years,
        years_at_company,
        years_in_current_role,
        years_since_last_promotion,
        years_with_curr_manager,
        training_times_last_year,
        employee_count,
        employee_number,
        over_18,
        standard_hours,
        _source_file_name,
        _load_timestamp

    from {{ source('staging', 'hr_data_raw') }}

)

select * from base