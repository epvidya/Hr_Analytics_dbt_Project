-- tests/assert_managers_are_senior.sql
-- Anyone who appears as a manager_id must be Level 4 or 5
-- Level 1, 2, 3 employees should never be someone's manager

SELECT
    m.emp_id                                            AS manager_emp_id,
    m.job_role                                          AS manager_role,
    m.job_level                                         AS manager_level,
    m.job_level_label                                   AS manager_level_label,
    COUNT(e.emp_id)                                     AS direct_reports,
    'Manager is below Level 4 — should not have direct reports'
                                                        AS violation_reason
FROM {{ ref('silver_hr_cleaned') }} e
JOIN {{ ref('silver_hr_cleaned') }} m
    ON e.manager_id = m.emp_id
WHERE m.job_level < 4
GROUP BY
    m.emp_id,
    m.job_role,
    m.job_level,
    m.job_level_label