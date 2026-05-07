-- tests/assert_manager_id_rule.sql
-- Singular test — returns rows that VIOLATE the manager rule
-- dbt expects 0 rows returned for a passing test
-- Any rows returned = test failure

-- Rule 1: Level 5 employees must have NULL manager_id
SELECT
    emp_id,
    job_level,
    manager_id,
    'Level 5 employee should have NULL manager_id'  AS violation_reason
FROM {{ ref('silver_hr_cleaned') }}
WHERE job_level = 5
  AND manager_id IS NOT NULL

UNION ALL

-- Rule 2: All other employees must have a manager_id
SELECT
    emp_id,
    job_level,
    manager_id,
    'Non Level 5 employee should not have NULL manager_id' AS violation_reason
FROM {{ ref('silver_hr_cleaned') }}
WHERE job_level != 5
  AND manager_id IS NULL